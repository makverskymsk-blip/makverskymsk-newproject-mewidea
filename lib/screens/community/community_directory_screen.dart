import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/community.dart';
import '../../providers/auth_provider.dart';
import '../../providers/community_provider.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_colors.dart';

class CommunityDirectoryScreen extends StatefulWidget {
  const CommunityDirectoryScreen({super.key});

  @override
  State<CommunityDirectoryScreen> createState() => _CommunityDirectoryScreenState();
}

class _CommunityDirectoryScreenState extends State<CommunityDirectoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final cp = context.read<CommunityProvider>();
    final uid = context.read<AuthProvider>().uid ?? '';
    await Future.wait([
      cp.loadAllCommunities(),
      cp.loadUserJoinRequests(uid),
      if (cp.activeCommunity != null)
        cp.loadPendingRequests(cp.activeCommunity!.id),
    ]);
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppColors.of(context);
    final cp = context.watch<CommunityProvider>();
    final uid = context.read<AuthProvider>().uid ?? '';
    final isAdmin = cp.activeCommunity?.isAdmin(uid) ?? false;

    return Scaffold(
      backgroundColor: t.scaffoldBg,
      appBar: AppBar(
        backgroundColor: t.scaffoldBg,
        elevation: 0,
        title: Text('Сообщества',
            style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w700)),
        iconTheme: IconThemeData(color: t.textPrimary),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: t.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 2.5,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: [
            const Tab(text: 'Все сообщества'),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Запросы'),
                  if (isAdmin && cp.pendingRequestCount > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text('${cp.pendingRequestCount}',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildDirectoryTab(cp, uid, t),
                _buildRequestsTab(cp, uid, t),
              ],
            ),
    );
  }

  // ===== TAB 1: All communities =====
  Widget _buildDirectoryTab(CommunityProvider cp, String uid, AppThemeColors t) {
    final userCommunityIds =
        context.read<AuthProvider>().currentUser?.communityIds ?? [];
    final communities = cp.allCommunities;

    if (communities.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.groups_outlined, size: 48, color: t.textHint),
            const SizedBox(height: 12),
            Text('Нет сообществ', style: TextStyle(color: t.textSecondary)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadData,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: communities.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final c = communities[i];
          final isMember = userCommunityIds.contains(c.id);
          final requestStatus = cp.getRequestStatus(c.id);

          return _buildCommunityCard(c, isMember, requestStatus, uid, t);
        },
      ),
    );
  }

  Widget _buildCommunityCard(
      Community c, bool isMember, String? requestStatus, String uid, AppThemeColors t) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: t.cardBg,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: t.borderLight.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          // Logo
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: c.logoUrl != null && c.logoUrl!.isNotEmpty
                ? Image.network(c.logoUrl!, width: 44, height: 44, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildPlaceholderLogo(c, t))
                : _buildPlaceholderLogo(c, t),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.name,
                    style: TextStyle(
                        color: t.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 15)),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(c.sport.icon, size: 14, color: t.textHint),
                    const SizedBox(width: 4),
                    Text(c.sport.displayName,
                        style: TextStyle(color: t.textSecondary, fontSize: 12)),
                    const SizedBox(width: 10),
                    Icon(Icons.people_outline_rounded, size: 14, color: t.textHint),
                    const SizedBox(width: 3),
                    Text('${c.totalMembers}',
                        style: TextStyle(color: t.textSecondary, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          // Action button
          _buildActionButton(c, isMember, requestStatus, uid, t),
        ],
      ),
    );
  }

  Widget _buildPlaceholderLogo(Community c, AppThemeColors t) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Center(
        child: Text(
          c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
      Community c, bool isMember, String? requestStatus, String uid, AppThemeColors t) {
    if (isMember) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(100),
        ),
        child: const Text('Участник',
            style: TextStyle(
                color: AppColors.success, fontSize: 12, fontWeight: FontWeight.w600)),
      );
    }

    if (requestStatus == 'pending') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
        ),
        child: const Text('Ожидает',
            style: TextStyle(
                color: Colors.amber, fontSize: 12, fontWeight: FontWeight.w600)),
      );
    }

    if (requestStatus == 'rejected') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(100),
        ),
        child: const Text('Отклонён',
            style: TextStyle(
                color: AppColors.error, fontSize: 12, fontWeight: FontWeight.w600)),
      );
    }

    // Can send request
    return GestureDetector(
      onTap: () async {
        final cp = context.read<CommunityProvider>();
        await cp.sendJoinRequest(c.id, uid);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Запрос отправлен в ${c.name}'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(100),
        ),
        child: const Text('Вступить',
            style: TextStyle(
                color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
      ),
    );
  }

  // ===== TAB 2: Pending join requests (for admins) =====
  Widget _buildRequestsTab(CommunityProvider cp, String uid, AppThemeColors t) {
    final isAdmin = cp.activeCommunity?.isAdmin(uid) ?? false;

    if (!isAdmin) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.admin_panel_settings_outlined, size: 48, color: t.textHint),
              const SizedBox(height: 12),
              Text('Только администраторы',
                  style: TextStyle(color: t.textSecondary, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text('Вы увидите запросы на вступление,\nкогда станете админом сообщества',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: t.textHint, fontSize: 13)),
            ],
          ),
        ),
      );
    }

    final requests = cp.pendingRequests;
    if (requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline, size: 48, color: t.textHint),
            const SizedBox(height: 12),
            Text('Нет новых запросов',
                style: TextStyle(color: t.textSecondary)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        if (cp.activeCommunity != null) {
          await cp.loadPendingRequests(cp.activeCommunity!.id);
        }
      },
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: requests.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final req = requests[i];
          return _buildRequestCard(req, cp, t);
        },
      ),
    );
  }

  Widget _buildRequestCard(
      Map<String, dynamic> req, CommunityProvider cp, AppThemeColors t) {
    final userId = req['user_id'] as String;
    final requestId = req['id'] as String;
    final communityId = req['community_id'] as String;
    final createdAt = DateTime.tryParse(req['created_at'] ?? '');

    return FutureBuilder<List>(
      future: SupabaseService().getUsersByIds([userId]),
      builder: (context, snap) {
        final userName = snap.hasData && snap.data!.isNotEmpty
            ? snap.data!.first.name
            : userId.substring(0, 8);
        final avatarUrl = snap.hasData && snap.data!.isNotEmpty
            ? snap.data!.first.avatarUrl
            : null;

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: t.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: t.borderLight.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                backgroundImage:
                    avatarUrl != null ? NetworkImage(avatarUrl) : null,
                child: avatarUrl == null
                    ? Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 16),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              // Name + date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(userName,
                        style: TextStyle(
                            color: t.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14)),
                    if (createdAt != null)
                      Text(
                        '${createdAt.day}.${createdAt.month.toString().padLeft(2, '0')}.${createdAt.year}',
                        style: TextStyle(color: t.textHint, fontSize: 12),
                      ),
                  ],
                ),
              ),
              // Reject
              IconButton(
                onPressed: () async {
                  await cp.rejectJoinRequest(requestId);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Запрос отклонён'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.close_rounded, color: AppColors.error, size: 22),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.error.withValues(alpha: 0.1),
                  minimumSize: const Size(36, 36),
                ),
              ),
              const SizedBox(width: 6),
              // Accept
              IconButton(
                onPressed: () async {
                  await cp.acceptJoinRequest(requestId, userId, communityId);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Пользователь принят!'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.check_rounded, color: AppColors.success, size: 22),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.success.withValues(alpha: 0.1),
                  minimumSize: const Size(36, 36),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
