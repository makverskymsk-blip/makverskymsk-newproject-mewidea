import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_colors.dart';
import '../community/direct_chat_screen.dart';

/// DM inbox — Telegram-style chat list.
class DirectMessagesScreen extends StatefulWidget {
  const DirectMessagesScreen({super.key});

  @override
  State<DirectMessagesScreen> createState() => _DirectMessagesScreenState();
}

class _DirectMessagesScreenState extends State<DirectMessagesScreen> {
  final SupabaseService _db = SupabaseService();
  List<Map<String, dynamic>> _conversations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    setState(() => _isLoading = true);
    final myUid = context.read<AuthProvider>().uid;
    if (myUid != null) {
      _conversations = await _db.getDirectConversations(myUid);
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppColors.of(context);

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
        title: Text(
          'Сообщения',
          style: TextStyle(
            color: t.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : _conversations.isEmpty
              ? _buildEmpty(t)
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: _loadConversations,
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: _conversations.length,
                    separatorBuilder: (_, __) => Padding(
                      padding: const EdgeInsets.only(left: 76),
                      child: Divider(
                        height: 0.5,
                        thickness: 0.5,
                        color: t.borderLight.withValues(alpha: 0.5),
                      ),
                    ),
                    itemBuilder: (ctx, i) =>
                        _buildConversationTile(_conversations[i], t),
                  ),
                ),
    );
  }

  Widget _buildEmpty(dynamic t) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.chat_bubble_outline_rounded,
              size: 64, color: t.textHint.withValues(alpha: 0.15)),
          const SizedBox(height: 16),
          Text('Нет сообщений',
              style: TextStyle(
                color: t.textHint,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              )),
          const SizedBox(height: 6),
          Text(
            'Начните диалог из профиля друга',
            style: TextStyle(
              color: t.textHint.withValues(alpha: 0.6),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationTile(Map<String, dynamic> conversation, dynamic t) {
    final otherUser = conversation['other_user'] as Map<String, dynamic>;
    final lastMsg = conversation['last_message'] as Map<String, dynamic>;
    final name = otherUser['name'] ?? 'Пользователь';
    final avatarUrl = otherUser['avatar_url'] as String?;
    final content = lastMsg['is_deleted'] == true
        ? 'Сообщение удалено'
        : (lastMsg['content'] ?? '');
    final createdAt = DateTime.tryParse(lastMsg['created_at'] ?? '');
    final myUid = context.read<AuthProvider>().uid;
    final isMine = lastMsg['sender_id'] == myUid;

    return InkWell(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DirectChatScreen(
              targetUserId: otherUser['id'],
              targetUserName: name,
              targetUserAvatar: avatarUrl,
            ),
          ),
        );
        _loadConversations();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // ── Avatar (круглый, 54px — как в TG) ──
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.8),
                    AppColors.primary,
                  ],
                ),
              ),
              child: avatarUrl != null && avatarUrl.isNotEmpty
                  ? ClipOval(
                      child: Image.network(
                        avatarUrl,
                        width: 54,
                        height: 54,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Center(
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: 14),
            // ── Name + message preview ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: name + time
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: t.textPrimary,
                          ),
                        ),
                      ),
                      if (createdAt != null)
                        Text(
                          _formatTime(createdAt),
                          style: TextStyle(
                            color: t.textHint,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Bottom row: message preview
                  Text(
                    isMine ? 'Вы: $content' : content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: t.textHint,
                      fontSize: 14,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'сейчас';
    if (_sameDay(dt, now)) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    if (_sameDay(dt, now.subtract(const Duration(days: 1)))) return 'вчера';
    if (diff.inDays < 7) {
      const days = ['пн', 'вт', 'ср', 'чт', 'пт', 'сб', 'вс'];
      return days[dt.weekday - 1];
    }
    const months = [
      '', 'янв', 'фев', 'мар', 'апр', 'мая', 'июн',
      'июл', 'авг', 'сен', 'окт', 'ноя', 'дек',
    ];
    return '${dt.day} ${months[dt.month]}';
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
