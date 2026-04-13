import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/chat_message.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/community_provider.dart';
import '../../theme/app_colors.dart';

class CommunityChatScreen extends StatefulWidget {
  const CommunityChatScreen({super.key});

  @override
  State<CommunityChatScreen> createState() => _CommunityChatScreenState();
}

class _CommunityChatScreenState extends State<CommunityChatScreen> {
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  late ChatProvider _chatProv;
  bool _atBottom = true;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _chatProv = context.read<ChatProvider>();
      final auth = context.read<AuthProvider>();
      final community = context.read<CommunityProvider>().activeCommunity;
      if (auth.uid != null && community != null) {
        _chatProv.openChat(
              chatId: community.id,
              chatType: 'community',
              myUserId: auth.uid!,
            );
      }
    });
  }

  void _onScroll() {
    // Load more when scrolled to top
    if (_scrollCtrl.position.pixels <= 50) {
      _chatProv.loadMore();
    }
    // Track if at bottom for auto-scroll
    _atBottom = _scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 100;
  }

  void _scrollToBottom() {
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    _msgCtrl.clear();
    await context.read<ChatProvider>().sendMessage(text);
    // Scroll to bottom after sending
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    _chatProv.closeChat();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppColors.of(context);
    final community = context.watch<CommunityProvider>().activeCommunity;
    final chatProv = context.watch<ChatProvider>();
    final myUid = context.read<AuthProvider>().uid ?? '';

    // Auto-scroll when new message arrives
    if (_atBottom && chatProv.messages.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }

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
        title: Column(
          children: [
            Text(
              community?.name ?? 'Чат',
              style: TextStyle(
                color: t.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            Text(
              '${community?.totalMembers ?? 0} участников',
              style: TextStyle(
                color: t.textHint,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: chatProv.isLoading && chatProv.messages.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : chatProv.messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.chat_bubble_outline_rounded,
                                size: 56,
                                color: t.textHint.withValues(alpha: 0.2)),
                            const SizedBox(height: 12),
                            Text('Начните общение!',
                                style: TextStyle(
                                    color: t.textHint, fontSize: 15)),
                            const SizedBox(height: 4),
                            Text('Напишите первое сообщение',
                                style: TextStyle(
                                    color: t.textHint.withValues(alpha: 0.5),
                                    fontSize: 13)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                        itemCount: chatProv.messages.length,
                        itemBuilder: (ctx, i) {
                          final msg = chatProv.messages[i];
                          final prev = i > 0 ? chatProv.messages[i - 1] : null;
                          final showDate = prev == null ||
                              !_sameDay(prev.createdAt, msg.createdAt);
                          final showSender = prev == null ||
                              prev.senderId != msg.senderId ||
                              showDate;

                          return Column(
                            children: [
                              if (showDate) _dateDivider(msg.createdAt, t),
                              if (msg.messageType == 'system')
                                _systemMessage(msg, t)
                              else
                                _messageBubble(msg, showSender, myUid, t),
                            ],
                          );
                        },
                      ),
          ),

          // Input bar
          _buildInputBar(t),
        ],
      ),
    );
  }

  // ═══ Message Bubble ═══

  Widget _messageBubble(
      ChatMessage msg, bool showSender, String myUid, dynamic t) {
    final isMine = msg.isMine;

    return Padding(
      padding: EdgeInsets.only(
        top: showSender ? 10 : 2,
        left: isMine ? 48 : 0,
        right: isMine ? 0 : 48,
      ),
      child: Row(
        mainAxisAlignment:
            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar (other users only)
          if (!isMine && showSender) ...[
            _avatar(msg.senderName, msg.senderAvatar, 28),
            const SizedBox(width: 6),
          ] else if (!isMine) ...[
            const SizedBox(width: 34),
          ],

          // Bubble
          Flexible(
            child: GestureDetector(
              onLongPress: isMine && !msg.isDeleted
                  ? () => _showDeleteDialog(msg)
                  : null,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: isMine ? AppColors.primaryGradient : null,
                  color: isMine ? null : AppColors.of(context).surfaceBg,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft:
                        Radius.circular(isMine ? 16 : 4),
                    bottomRight:
                        Radius.circular(isMine ? 4 : 16),
                  ),
                  border: isMine
                      ? null
                      : Border.all(
                          color: AppColors.of(context)
                              .borderLight
                              .withValues(alpha: 0.5)),
                ),
                child: Column(
                  crossAxisAlignment: isMine
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    // Sender name
                    if (!isMine && showSender)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Text(
                          msg.senderName,
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    // Content
                    Text(
                      msg.isDeleted ? 'Сообщение удалено' : msg.content,
                      style: TextStyle(
                        color: msg.isDeleted
                            ? (isMine
                                ? Colors.white.withValues(alpha: 0.5)
                                : AppColors.of(context).textHint)
                            : (isMine
                                ? Colors.white
                                : AppColors.of(context).textPrimary),
                        fontSize: 14,
                        fontStyle:
                            msg.isDeleted ? FontStyle.italic : FontStyle.normal,
                      ),
                    ),
                    // Time
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _formatTime(msg.createdAt),
                        style: TextStyle(
                          color: isMine
                              ? Colors.white.withValues(alpha: 0.5)
                              : AppColors.of(context).textHint,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _systemMessage(ChatMessage msg, dynamic t) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.of(context).cardBg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            msg.content,
            style: TextStyle(
              color: AppColors.of(context).textHint,
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ),
    );
  }

  Widget _dateDivider(DateTime date, dynamic t) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Expanded(
              child: Divider(
                  color: AppColors.of(context).borderLight, thickness: 0.5)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              _formatDate(date),
              style: TextStyle(
                color: AppColors.of(context).textHint,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
              child: Divider(
                  color: AppColors.of(context).borderLight, thickness: 0.5)),
        ],
      ),
    );
  }

  Widget _avatar(String name, String? url, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary.withValues(alpha: 0.1),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: url != null && url.isNotEmpty
          ? ClipOval(
              child: Image.network(
                url,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Center(
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: size * 0.45,
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
                style: TextStyle(
                  fontSize: size * 0.45,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ),
    );
  }

  // ═══ Input Bar ═══

  Widget _buildInputBar(dynamic t) {
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 8,
        top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 10,
      ),
      decoration: BoxDecoration(
        color: AppColors.of(context).scaffoldBg,
        border: Border(
          top: BorderSide(
              color: AppColors.of(context).borderLight.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        children: [
          // Future: media attachment button
          // IconButton(
          //   icon: Icon(Icons.attach_file_rounded, color: t.textHint, size: 22),
          //   onPressed: () {},
          // ),

          // Text field
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.of(context).surfaceBg,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                    color: AppColors.of(context)
                        .borderLight
                        .withValues(alpha: 0.5)),
              ),
              child: TextField(
                controller: _msgCtrl,
                maxLines: 4,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                style: TextStyle(
                  color: AppColors.of(context).textPrimary,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: 'Сообщение...',
                  hintStyle: TextStyle(
                    color: AppColors.of(context).textHint,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),

          // Send button
          GestureDetector(
            onTap: _send,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.send_rounded,
                  color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  // ═══ Delete dialog ═══

  void _showDeleteDialog(ChatMessage msg) {
    final t = AppColors.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: t.dialogBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Удалить сообщение?',
            style: TextStyle(color: t.textPrimary, fontSize: 16)),
        content: Text(
          msg.content.length > 60
              ? '${msg.content.substring(0, 60)}...'
              : msg.content,
          style: TextStyle(color: t.textHint, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Отмена', style: TextStyle(color: t.textHint)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<ChatProvider>().deleteMessage(msg.id);
            },
            child: const Text('Удалить',
                style: TextStyle(
                    color: AppColors.error, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ═══ Helpers ═══

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    if (_sameDay(dt, now)) return 'Сегодня';
    if (_sameDay(dt, now.subtract(const Duration(days: 1)))) return 'Вчера';
    const months = [
      '', 'янв', 'фев', 'мар', 'апр', 'мая', 'июн',
      'июл', 'авг', 'сен', 'окт', 'ноя', 'дек',
    ];
    return '${dt.day} ${months[dt.month]}';
  }
}
