import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/friends_provider.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../community/direct_chat_screen.dart';
import 'public_profile_screen.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final TextEditingController _searchCtrl = TextEditingController();
  final SupabaseService _db = SupabaseService();
  Timer? _debounce;
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<AuthProvider>().uid;
      if (uid != null) {
        context.read<FriendsProvider>().loadAll(uid);
      }
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      setState(() => _isSearching = true);
      try {
        final results = await _db.searchUsers(query);
        // Filter out current user
        final myUid = context.read<AuthProvider>().uid;
        if (mounted) {
          setState(() {
            _searchResults =
                results.where((u) => u['id'] != myUid).toList();
            _isSearching = false;
          });
        }
      } catch (e) {
        debugPrint('SEARCH: error $e');
        if (mounted) setState(() => _isSearching = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppColors.of(context);
    final friendsProv = context.watch<FriendsProvider>();
    final pendingCount = friendsProv.pendingCount;

    return Scaffold(
      backgroundColor: t.scaffoldBg,
      appBar: AppBar(
        backgroundColor: t.scaffoldBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded,
              color: t.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Друзья и подписки',
            style: TextStyle(
              color: t.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            )),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _showSearch ? Icons.close_rounded : Icons.search_rounded,
              color: t.textPrimary,
              size: 22,
            ),
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchCtrl.clear();
                  _searchResults = [];
                }
              });
            },
          ),
        ],
        bottom: _showSearch
            ? null
            : TabBar(
                controller: _tabCtrl,
                labelColor: AppColors.primary,
                unselectedLabelColor: t.textHint,
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                labelStyle:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                tabs: [
                  Tab(text: 'Друзья (${friendsProv.mutualFriends.length})'),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Подписчики'),
                        Text(' ${friendsProv.followersCount}',
                            style: TextStyle(
                              color: t.textHint,
                              fontWeight: FontWeight.w500,
                            )),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Подписки'),
                        Text(' ${friendsProv.followingCount}',
                            style: TextStyle(
                              color: t.textHint,
                              fontWeight: FontWeight.w500,
                            )),
                      ],
                    ),
                  ),
                ],
              ),
      ),
      body: _showSearch
          ? _buildSearchView(t)
          : Column(
              children: [
                // Pending requests banner
                if (pendingCount > 0)
                  GestureDetector(
                    onTap: () => _showPendingRequests(context, friendsProv),
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: AppColors.warning.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.person_add_rounded,
                              color: AppColors.warning, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '$pendingCount ${_pluralRequests(pendingCount)}',
                              style: const TextStyle(
                                color: AppColors.warning,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded,
                              color: AppColors.warning, size: 20),
                        ],
                      ),
                    ),
                  ),

                // Tab views
                Expanded(
                  child: friendsProv.isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primary))
                      : TabBarView(
                          controller: _tabCtrl,
                          children: [
                            _buildList(friendsProv.mutualFriends,
                                'Нет взаимных подписок', Icons.people_rounded),
                            _buildList(friendsProv.followers,
                                'Нет подписчиков', Icons.person_rounded),
                            _buildList(friendsProv.following, 'Нет подписок',
                                Icons.person_outline_rounded),
                          ],
                        ),
                ),
              ],
            ),
    );
  }

  // ═══ Search View ═══

  Widget _buildSearchView(dynamic t) {
    return Column(
      children: [
        // Search field
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.of(context).surfaceBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: AppColors.of(context).borderLight),
            ),
            child: TextField(
              controller: _searchCtrl,
              autofocus: true,
              onChanged: _onSearchChanged,
              style: TextStyle(
                color: AppColors.of(context).textPrimary,
                fontSize: 15,
              ),
              decoration: InputDecoration(
                hintText: 'Поиск по имени...',
                hintStyle: TextStyle(
                  color: AppColors.of(context).textHint,
                  fontSize: 14,
                ),
                prefixIcon: Icon(Icons.search_rounded,
                    color: AppColors.of(context).textHint, size: 20),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear_rounded,
                            color: AppColors.of(context).textHint, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
        ),

        // Results
        Expanded(
          child: _isSearching
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary))
              : _searchCtrl.text.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.person_search_rounded,
                              size: 48,
                              color: AppColors.of(context)
                                  .textHint
                                  .withValues(alpha: 0.3)),
                          const SizedBox(height: 12),
                          Text('Введите имя для поиска',
                              style: TextStyle(
                                  color: AppColors.of(context).textHint,
                                  fontSize: 14)),
                        ],
                      ),
                    )
                  : _searchResults.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.search_off_rounded,
                                  size: 48,
                                  color: AppColors.of(context)
                                      .textHint
                                      .withValues(alpha: 0.3)),
                              const SizedBox(height: 12),
                              Text('Никого не найдено',
                                  style: TextStyle(
                                      color:
                                          AppColors.of(context).textHint,
                                      fontSize: 14)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          itemCount: _searchResults.length,
                          itemBuilder: (ctx, i) =>
                              _searchResultTile(_searchResults[i]),
                        ),
        ),
      ],
    );
  }

  Widget _searchResultTile(Map<String, dynamic> user) {
    final t = AppColors.of(context);
    final name = user['name'] ?? '';
    final avatarUrl = user['avatar_url'];
    final position = user['position'];
    final userId = user['id'];
    final isPublic = user['is_public_profile'] ?? true;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PublicProfileScreen(userId: userId),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        child: GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          borderRadius: 14,
          child: Row(
            children: [
              // Avatar
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.1),
                  border:
                      Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: avatarUrl != null && avatarUrl.toString().isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          avatarUrl,
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Center(
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              // Name + position + privacy
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: t.textPrimary,
                        )),
                    Row(
                      children: [
                        if (position != null && position != 'Не указана')
                          Text(position,
                              style: TextStyle(
                                color: t.textHint,
                                fontSize: 12,
                              )),
                        if (position != null && position != 'Не указана')
                          const SizedBox(width: 6),
                        Icon(
                          isPublic
                              ? Icons.public_rounded
                              : Icons.lock_rounded,
                          size: 12,
                          color: t.textHint.withValues(alpha: 0.5),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: t.borderLight, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ═══ Follow List ═══

  Widget _buildList(
      List<FollowEntry> entries, String emptyText, IconData emptyIcon) {
    final t = AppColors.of(context);
    if (entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(emptyIcon, size: 48, color: t.textHint.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            Text(emptyText, style: TextStyle(color: t.textHint, fontSize: 14)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: entries.length,
      itemBuilder: (context, index) => _userTile(entries[index]),
    );
  }

  Widget _userTile(FollowEntry entry) {
    final t = AppColors.of(context);
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PublicProfileScreen(userId: entry.userId),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        child: GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          borderRadius: 14,
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.1),
                  border:
                      Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: entry.avatarUrl != null && entry.avatarUrl!.isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          entry.avatarUrl!,
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Center(
                            child: Text(
                              entry.name.isNotEmpty
                                  ? entry.name[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          entry.name.isNotEmpty
                              ? entry.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: t.textPrimary,
                        )),
                    if (entry.position != null &&
                        entry.position != 'Не указана')
                      Text(entry.position!,
                          style: TextStyle(
                            color: t.textHint,
                            fontSize: 12,
                          )),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DirectChatScreen(
                      targetUserId: entry.userId,
                      targetUserName: entry.name,
                      targetUserAvatar: entry.avatarUrl,
                    ),
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.chat_bubble_outline_rounded,
                      color: AppColors.primary.withValues(alpha: 0.6), size: 18),
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, color: t.borderLight, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ═══ Pending Requests ═══

  void _showPendingRequests(BuildContext context, FriendsProvider prov) {
    final t = AppColors.of(context);
    final uid = context.read<AuthProvider>().uid!;

    showModalBottomSheet(
      context: context,
      backgroundColor: t.dialogBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        maxChildSize: 0.8,
        minChildSize: 0.3,
        expand: false,
        builder: (ctx, scrollCtrl) => Column(
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: t.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.person_add_rounded,
                        color: AppColors.warning, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text('Запросы на подписку',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: t.textPrimary,
                      )),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: prov.pendingRequests.map((req) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: t.surfaceBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: t.borderLight),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary.withValues(alpha: 0.1),
                          ),
                          child: Center(
                            child: Text(
                              req.name.isNotEmpty
                                  ? req.name[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(req.name,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: t.textPrimary,
                              )),
                        ),
                        IconButton(
                          onPressed: () =>
                              prov.acceptRequest(uid, req.followId),
                          icon: const Icon(Icons.check_circle_rounded,
                              color: AppColors.success, size: 28),
                          tooltip: 'Принять',
                        ),
                        IconButton(
                          onPressed: () =>
                              prov.rejectRequest(uid, req.followId),
                          icon: const Icon(Icons.cancel_rounded,
                              color: AppColors.error, size: 28),
                          tooltip: 'Отклонить',
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _pluralRequests(int n) {
    if (n == 1) return 'запрос на подписку';
    if (n >= 2 && n <= 4) return 'запроса на подписку';
    return 'запросов на подписку';
  }
}
