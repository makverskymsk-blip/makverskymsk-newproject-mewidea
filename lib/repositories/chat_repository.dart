import 'package:new_idea_works/utils/app_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'base_repository.dart';

/// Repository for messages, conversations, cleanup.
class ChatRepository extends BaseRepository {
  static final ChatRepository _instance = ChatRepository._internal();
  factory ChatRepository() => _instance;
  ChatRepository._internal();

  /// Expose supabase client for realtime subscriptions
  SupabaseClient get client => supabase;

  /// Generate consistent direct chat ID from two user IDs
  static String getDirectChatId(String userId1, String userId2) {
    final sorted = [userId1, userId2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  // ───── Messages ─────

  Future<Map<String, dynamic>?> sendMessage({
    required String chatType,
    required String chatId,
    required String senderId,
    required String content,
    String messageType = 'text',
    String? mediaUrl,
  }) async {
    final response = await supabase.from('messages').insert({
      'chat_type': chatType,
      'chat_id': chatId,
      'sender_id': senderId,
      'content': content,
      'message_type': messageType,
      ?'media_url': mediaUrl,
    }).select().single();
    return response;
  }

  Future<List<Map<String, dynamic>>> getMessages(
    String chatId, {
    int limit = 50,
    DateTime? before,
  }) async {
    var query = supabase
        .from('messages')
        .select()
        .eq('chat_id', chatId)
        .eq('is_deleted', false)
        .order('created_at', ascending: false)
        .limit(limit);

    if (before != null) {
      query = supabase
          .from('messages')
          .select()
          .eq('chat_id', chatId)
          .eq('is_deleted', false)
          .lt('created_at', before.toIso8601String())
          .order('created_at', ascending: false)
          .limit(limit);
    }

    final response = await query;
    // Enrich with sender data
    final results = <Map<String, dynamic>>[];
    final senderIds = <String>{};
    for (final row in response) {
      senderIds.add(row['sender_id'] ?? '');
    }
    final senderProfiles = <String, Map<String, dynamic>>{};
    if (senderIds.isNotEmpty) {
      final profiles = await supabase
          .from('users')
          .select('id, name, avatar_url')
          .inFilter('id', senderIds.toList());
      for (final p in profiles) {
        senderProfiles[p['id']] = p;
      }
    }
    for (final row in response) {
      results.add({
        ...row,
        'sender': senderProfiles[row['sender_id']],
      });
    }
    return results;
  }

  /// Get all direct conversations for a user
  Future<List<Map<String, dynamic>>> getDirectConversations(String userId) async {
    try {
      final response = await supabase
          .from('messages')
          .select()
          .eq('chat_type', 'direct')
          .or('chat_id.ilike.%$userId%')
          .order('created_at', ascending: false);

      final Map<String, Map<String, dynamic>> chatMap = {};
      for (final msg in response) {
        final chatId = msg['chat_id'] as String;
        if (!chatMap.containsKey(chatId)) {
          chatMap[chatId] = msg;
        }
      }

      final results = <Map<String, dynamic>>[];
      for (final entry in chatMap.entries) {
        final chatId = entry.key;
        final lastMsg = entry.value;

        final parts = chatId.split('_');
        if (parts.length < 2) continue;

        String? otherUserId;
        if (chatId.startsWith(userId)) {
          otherUserId = chatId.substring(userId.length + 1);
        } else if (chatId.endsWith(userId)) {
          otherUserId = chatId.substring(0, chatId.length - userId.length - 1);
        } else {
          continue;
        }

        final otherUser = await supabase
            .from('users')
            .select('id, name, avatar_url')
            .eq('id', otherUserId)
            .maybeSingle();

        if (otherUser == null) continue;

        results.add({
          'chat_id': chatId,
          'last_message': lastMsg,
          'other_user': otherUser,
        });
      }

      results.sort((a, b) {
        final aTime = DateTime.parse(a['last_message']['created_at']);
        final bTime = DateTime.parse(b['last_message']['created_at']);
        return bTime.compareTo(aTime);
      });

      return results;
    } catch (e) {
      appLog('CHAT: Error loading direct conversations: $e');
      return [];
    }
  }

  /// Soft-delete a message
  Future<void> deleteMessage(String messageId) async {
    await supabase.from('messages').update({
      'is_deleted': true,
      'content': 'Сообщение удалено',
    }).eq('id', messageId);
  }

  /// Auto-cleanup old community messages
  Future<int> cleanupOldCommunityMessages(String chatId, {int daysToKeep = 3}) async {
    final cutoff = DateTime.now().subtract(Duration(days: daysToKeep));
    try {
      final deleted = await supabase
          .from('messages')
          .delete()
          .eq('chat_id', chatId)
          .eq('chat_type', 'community')
          .lt('created_at', cutoff.toIso8601String())
          .select('id');
      appLog('CHAT CLEANUP: Deleted ${deleted.length} old messages from community $chatId (older than $daysToKeep days)');
      return deleted.length;
    } catch (e) {
      appLog('CHAT CLEANUP ERROR: $e');
      return 0;
    }
  }

  /// Clear all messages in a direct chat
  Future<int> clearDirectChat(String chatId) async {
    try {
      final deleted = await supabase
          .from('messages')
          .delete()
          .eq('chat_id', chatId)
          .eq('chat_type', 'direct')
          .select('id');
      appLog('CHAT CLEAR: Deleted ${deleted.length} messages from DM $chatId');
      return deleted.length;
    } catch (e) {
      appLog('CHAT CLEAR ERROR: $e');
      return 0;
    }
  }
}
