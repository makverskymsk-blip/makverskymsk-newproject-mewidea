class ChatMessage {
  final String id;
  final String chatType; // 'community' | 'direct'
  final String chatId;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final String content;
  final String messageType; // 'text' | 'image' | 'system'
  final String? mediaUrl;
  final DateTime createdAt;
  final bool isDeleted;
  final bool isMine;

  const ChatMessage({
    required this.id,
    required this.chatType,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.content,
    this.messageType = 'text',
    this.mediaUrl,
    required this.createdAt,
    this.isDeleted = false,
    this.isMine = false,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map, String myUserId) {
    final sender = map['sender'] as Map<String, dynamic>?;
    return ChatMessage(
      id: map['id'],
      chatType: map['chat_type'] ?? 'community',
      chatId: map['chat_id'] ?? '',
      senderId: map['sender_id'] ?? '',
      senderName: sender?['name'] ?? 'Участник',
      senderAvatar: sender?['avatar_url'],
      content: map['content'] ?? '',
      messageType: map['message_type'] ?? 'text',
      mediaUrl: map['media_url'],
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
      isDeleted: map['is_deleted'] ?? false,
      isMine: map['sender_id'] == myUserId,
    );
  }

  /// System message (join, leave, etc.)
  factory ChatMessage.system(String chatId, String text) {
    return ChatMessage(
      id: 'sys_${DateTime.now().millisecondsSinceEpoch}',
      chatType: 'community',
      chatId: chatId,
      senderId: '',
      senderName: '',
      content: text,
      messageType: 'system',
      createdAt: DateTime.now(),
    );
  }
}
