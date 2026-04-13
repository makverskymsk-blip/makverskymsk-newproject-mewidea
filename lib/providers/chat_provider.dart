import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat_message.dart';
import '../services/supabase_service.dart';

/// Manages chat state and Supabase Realtime subscriptions.
/// Supports both community group chats and direct 1-on-1 messages.
class ChatProvider extends ChangeNotifier {
  final SupabaseService _db = SupabaseService();

  List<ChatMessage> _messages = [];
  String? _currentChatId;
  String? _currentChatType;
  String? _myUserId;
  bool _isLoading = false;
  bool _hasMore = true;
  RealtimeChannel? _channel;

  static const int _pageSize = 50;

  List<ChatMessage> get messages => _messages;
  String? get currentChatId => _currentChatId;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;

  /// Open a chat: load messages + subscribe to realtime
  Future<void> openChat({
    required String chatId,
    required String chatType,
    required String myUserId,
  }) async {
    // If already open, skip
    if (_currentChatId == chatId) return;

    // Close previous
    closeChat();

    _currentChatId = chatId;
    _currentChatType = chatType;
    _myUserId = myUserId;
    _messages = [];
    _hasMore = true;
    _isLoading = true;
    notifyListeners();

    try {
      // Load initial messages
      final raw = await _db.getMessages(chatId, limit: _pageSize);
      _messages = raw
          .map((m) => ChatMessage.fromMap(m, myUserId))
          .toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

      _hasMore = raw.length >= _pageSize;

      // Subscribe to realtime
      _subscribeToRealtime(chatId, myUserId);
    } catch (e) {
      debugPrint('CHAT: Error loading messages: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Load older messages (pagination)
  Future<void> loadMore() async {
    if (_isLoading || !_hasMore || _messages.isEmpty || _currentChatId == null) {
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final oldest = _messages.first.createdAt;
      final raw = await _db.getMessages(
        _currentChatId!,
        limit: _pageSize,
        before: oldest,
      );

      final older = raw
          .map((m) => ChatMessage.fromMap(m, _myUserId!))
          .toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

      _hasMore = raw.length >= _pageSize;
      _messages = [...older, ..._messages];
    } catch (e) {
      debugPrint('CHAT: Error loading more: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Send a text message
  Future<void> sendMessage(String content) async {
    if (_currentChatId == null || _myUserId == null || content.trim().isEmpty) {
      return;
    }

    try {
      await _db.sendMessage(
        chatType: _currentChatType ?? 'community',
        chatId: _currentChatId!,
        senderId: _myUserId!,
        content: content.trim(),
      );
      // Message will arrive via realtime subscription
    } catch (e) {
      debugPrint('CHAT: Error sending message: $e');
    }
  }

  /// Delete a message (soft delete)
  Future<void> deleteMessage(String messageId) async {
    try {
      await _db.deleteMessage(messageId);
      // Update will arrive via realtime
      final idx = _messages.indexWhere((m) => m.id == messageId);
      if (idx >= 0) {
        _messages[idx] = ChatMessage(
          id: _messages[idx].id,
          chatType: _messages[idx].chatType,
          chatId: _messages[idx].chatId,
          senderId: _messages[idx].senderId,
          senderName: _messages[idx].senderName,
          senderAvatar: _messages[idx].senderAvatar,
          content: 'Сообщение удалено',
          messageType: _messages[idx].messageType,
          createdAt: _messages[idx].createdAt,
          isDeleted: true,
          isMine: _messages[idx].isMine,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('CHAT: Error deleting message: $e');
    }
  }

  /// Close current chat and unsubscribe from realtime
  void closeChat() {
    if (_channel != null) {
      _db.client.removeChannel(_channel!);
      _channel = null;
    }
    _currentChatId = null;
    _currentChatType = null;
    _messages = [];
  }

  // ═══ Realtime ═══

  void _subscribeToRealtime(String chatId, String myUserId) {
    _channel = _db.client
        .channel('chat:$chatId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'chat_id',
            value: chatId,
          ),
          callback: (payload) async {
            final newRow = payload.newRecord;
            if (newRow.isEmpty) return;

            // Don't add duplicates
            if (_messages.any((m) => m.id == newRow['id'])) return;

            // Fetch sender info
            Map<String, dynamic>? senderData;
            try {
              final profiles = await _db.client
                  .from('users')
                  .select('id, name, avatar_url')
                  .eq('id', newRow['sender_id'])
                  .maybeSingle();
              senderData = profiles;
            } catch (_) {}

            final msg = ChatMessage.fromMap({
              ...newRow,
              'sender': senderData,
            }, myUserId);

            _messages.add(msg);
            notifyListeners();
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    closeChat();
    super.dispose();
  }
}
