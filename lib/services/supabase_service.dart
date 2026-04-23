import 'package:new_idea_works/utils/app_logger.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/community.dart';
import '../models/enums.dart';
import '../models/user_profile.dart';
import '../models/sport_match.dart';
import '../models/subscription.dart';
import '../models/transaction.dart' as app_tx;
import '../repositories/user_repository.dart';
import '../repositories/community_repository.dart';
import '../repositories/match_repository.dart';
import '../repositories/finance_repository.dart';
import '../repositories/stats_repository.dart';
import '../repositories/training_repository.dart';
import '../repositories/social_repository.dart';
import '../repositories/chat_repository.dart';
import '../repositories/match_events_repository.dart';

/// Thin facade over domain repositories.
/// All methods delegate to the appropriate repository.
/// Consumers can gradually migrate to using repositories directly.
class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  // ─── Repository instances (accessible for direct use) ───
  final userRepo = UserRepository();
  final communityRepo = CommunityRepository();
  final matchRepo = MatchRepository();
  final financeRepo = FinanceRepository();
  final statsRepo = StatsRepository();
  final trainingRepo = TrainingRepository();
  final socialRepo = SocialRepository();
  final chatRepo = ChatRepository();
  final matchEventsRepo = MatchEventsRepository();

  // Legacy: expose supabase client for realtime subscriptions
  SupabaseClient get client => chatRepo.client;

  // ═══════════════════════════════════════════════════════════════
  // USER REPOSITORY DELEGATES
  // ═══════════════════════════════════════════════════════════════

  Future<String?> uploadAvatar(String userId, Uint8List bytes, String ext) =>
      userRepo.uploadAvatar(userId, bytes, ext);

  Future<String?> uploadCommunityLogo(String communityId, Uint8List bytes, String ext) =>
      userRepo.uploadCommunityLogo(communityId, bytes, ext);

  Future<void> updateCommunityLogoUrl(String communityId, String logoUrl) =>
      userRepo.updateCommunityLogoUrl(communityId, logoUrl);

  Future<void> createUser(UserProfile user) =>
      userRepo.createUser(user);

  Future<UserProfile?> getUser(String uid) =>
      userRepo.getUser(uid);

  Future<void> updateUser(String uid, Map<String, dynamic> data) =>
      userRepo.updateUser(uid, data);

  Future<void> updateUserBalance(String uid, double amount, {String? communityId}) =>
      userRepo.updateUserBalance(uid, amount, communityId: communityId);

  Future<List<UserProfile>> getUsersByIds(List<String> userIds) =>
      userRepo.getUsersByIds(userIds);

  dynamic watchUserChannel(String userId, {required VoidCallback onChanged}) =>
      userRepo.watchUserChannel(userId, onChanged: onChanged);

  // ═══════════════════════════════════════════════════════════════
  // COMMUNITY REPOSITORY DELEGATES
  // ═══════════════════════════════════════════════════════════════

  Future<void> createCommunity(Community community) =>
      communityRepo.createCommunity(community);

  Future<Map<String, dynamic>> createCommunityAndReturn({
    required String name,
    required SportCategory sport,
    required String inviteCode,
    required String ownerId,
    double monthlyRent = 100000,
    double singleGamePrice = 1200,
  }) => communityRepo.createCommunityAndReturn(
        name: name,
        sport: sport,
        inviteCode: inviteCode,
        ownerId: ownerId,
        monthlyRent: monthlyRent,
        singleGamePrice: singleGamePrice,
      );

  Future<Community?> getCommunityByInviteCode(String code) =>
      communityRepo.getCommunityByInviteCode(code);

  Future<List<Community>> getUserCommunities(List<String> communityIds) =>
      communityRepo.getUserCommunities(communityIds);

  Future<void> joinCommunity(String communityId, String userId) =>
      communityRepo.joinCommunity(communityId, userId);

  Future<void> leaveCommunity(String communityId, String userId) =>
      communityRepo.leaveCommunity(communityId, userId);

  Future<void> updateCommunityAdmins(
    String communityId,
    List<String> adminIds,
    List<String> memberIds,
  ) => communityRepo.updateCommunityAdmins(communityId, adminIds, memberIds);

  Future<void> updateCommunityBank(String communityId, double newBalance) =>
      communityRepo.updateCommunityBank(communityId, newBalance);

  Future<List<Community>> getAllCommunities() =>
      communityRepo.getAllCommunities();

  Future<void> createJoinRequest(String communityId, String userId) =>
      communityRepo.createJoinRequest(communityId, userId);

  Future<List<Map<String, dynamic>>> getJoinRequestsForCommunity(String communityId) =>
      communityRepo.getJoinRequestsForCommunity(communityId);

  Future<List<Map<String, dynamic>>> getUserJoinRequests(String userId) =>
      communityRepo.getUserJoinRequests(userId);

  Future<void> updateJoinRequestStatus(String requestId, String status) =>
      communityRepo.updateJoinRequestStatus(requestId, status);

  Future<void> deleteJoinRequest(String requestId) =>
      communityRepo.deleteJoinRequest(requestId);

  Future<void> adminAcceptJoinRequest(String requestId, String userId, String communityId) =>
      communityRepo.adminAcceptJoinRequest(requestId, userId, communityId);

  dynamic watchCommunityChannel(String communityId, {required VoidCallback onChanged}) =>
      communityRepo.watchCommunityChannel(communityId, onChanged: onChanged);

  // ═══════════════════════════════════════════════════════════════
  // MATCH REPOSITORY DELEGATES
  // ═══════════════════════════════════════════════════════════════

  Future<void> createMatch(String communityId, SportMatch match) =>
      matchRepo.createMatch(communityId, match);

  Future<Map<String, dynamic>> createMatchAndReturn(
      String? communityId, SportMatch match) =>
      matchRepo.createMatchAndReturn(communityId, match);

  Future<List<SportMatch>> getMatches(String communityId) =>
      matchRepo.getMatches(communityId);

  Future<List<SportMatch>> getAllActiveMatches() =>
      matchRepo.getAllActiveMatches();

  Future<List<SportMatch>> getAllMatches() =>
      matchRepo.getAllMatches();

  Stream<List<SportMatch>> watchMatches(String communityId) =>
      matchRepo.watchMatches(communityId);

  dynamic watchAllMatchesChannel({required VoidCallback onChanged}) =>
      matchRepo.watchAllMatchesChannel(onChanged: onChanged);

  dynamic watchMatchesChannel(String communityId, {required VoidCallback onChanged}) =>
      matchRepo.watchMatchesChannel(communityId, onChanged: onChanged);

  Future<void> addToUserBalance(String userId, double amount, {String? communityId}) =>
      matchRepo.addToUserBalance(userId, amount, communityId: communityId);

  Future<void> updateMatch(
      String communityId, String matchId, Map<String, dynamic> data) =>
      matchRepo.updateMatch(communityId, matchId, data);

  // ═══════════════════════════════════════════════════════════════
  // FINANCE REPOSITORY DELEGATES
  // ═══════════════════════════════════════════════════════════════

  Future<String> saveSubscription(String communityId, MonthlySubscription sub) =>
      financeRepo.saveSubscription(communityId, sub);

  Future<List<MonthlySubscription>> getSubscriptions(String communityId) =>
      financeRepo.getSubscriptions(communityId);

  Future<MonthlySubscription?> getSubscriptionForMonth(
    String communityId,
    int month,
    int year,
  ) => financeRepo.getSubscriptionForMonth(communityId, month, year);

  Stream<MonthlySubscription?> watchSubscription(
    String communityId,
    int month,
    int year,
  ) => financeRepo.watchSubscription(communityId, month, year);

  Future<void> deleteSubscription(String subscriptionId) =>
      financeRepo.deleteSubscription(subscriptionId);

  dynamic watchSubscriptionsChannel(String communityId, {required VoidCallback onChanged}) =>
      financeRepo.watchSubscriptionsChannel(communityId, onChanged: onChanged);

  Future<void> addTransaction(String communityId, app_tx.Transaction tx) =>
      financeRepo.addTransaction(communityId, tx);

  Stream<List<app_tx.Transaction>> watchTransactions(
      String communityId, String userId) =>
      financeRepo.watchTransactions(communityId, userId);

  // ═══════════════════════════════════════════════════════════════
  // STATS REPOSITORY DELEGATES
  // ═══════════════════════════════════════════════════════════════

  Future<void> saveMatchPlayerStats(List<Map<String, dynamic>> statsList) =>
      statsRepo.saveMatchPlayerStats(statsList);

  Future<Map<String, dynamic>?> getPlayerAggregateStats(
    String userId, {
    String? sportCategory,
  }) => statsRepo.getPlayerAggregateStats(userId, sportCategory: sportCategory);

  Future<Map<String, dynamic>?> getPlayerStatsBySportRpc(
    String userId, {
    String? sportCategory,
  }) => statsRepo.getPlayerStatsBySportRpc(userId, sportCategory: sportCategory);

  Future<List<Map<String, dynamic>>> getPlayerMatchHistory(
      String userId, {int limit = 10, String? sportCategory}) =>
      statsRepo.getPlayerMatchHistory(userId, limit: limit, sportCategory: sportCategory);

  Future<void> savePlayerDistance(
    String matchId,
    String userId,
    double km, {
    String sportCategory = 'football',
  }) => statsRepo.savePlayerDistance(matchId, userId, km, sportCategory: sportCategory);

  Future<double> getPlayerDistance(String matchId, String userId) =>
      statsRepo.getPlayerDistance(matchId, userId);

  Future<double> getPlayerTotalDistance(String userId, {String? sportCategory}) =>
      statsRepo.getPlayerTotalDistance(userId, sportCategory: sportCategory);

  // ═══════════════════════════════════════════════════════════════
  // TRAINING REPOSITORY DELEGATES
  // ═══════════════════════════════════════════════════════════════

  Future<List<Map<String, dynamic>>> getExercises(String userId) =>
      trainingRepo.getExercises(userId);

  Future<Map<String, dynamic>> createExercise(Map<String, dynamic> exercise) =>
      trainingRepo.createExercise(exercise);

  Future<void> updateExercise(String id, Map<String, dynamic> data) =>
      trainingRepo.updateExercise(id, data);

  Future<void> deleteExercise(String id) =>
      trainingRepo.deleteExercise(id);

  Future<Map<String, dynamic>> createWorkoutSession(Map<String, dynamic> session) =>
      trainingRepo.createWorkoutSession(session);

  Future<List<Map<String, dynamic>>> getWorkoutSessions(String userId, {int limit = 50}) =>
      trainingRepo.getWorkoutSessions(userId, limit: limit);

  Future<void> updateWorkoutSession(String id, Map<String, dynamic> data) =>
      trainingRepo.updateWorkoutSession(id, data);

  Future<Map<String, dynamic>> createWorkoutSet(Map<String, dynamic> setData) =>
      trainingRepo.createWorkoutSet(setData);

  Future<List<Map<String, dynamic>>> getWorkoutSets(String sessionId) =>
      trainingRepo.getWorkoutSets(sessionId);

  Future<void> updateWorkoutSet(String id, Map<String, dynamic> data) =>
      trainingRepo.updateWorkoutSet(id, data);

  Future<void> deleteWorkoutSet(String id) =>
      trainingRepo.deleteWorkoutSet(id);

  Future<void> deleteWorkoutSession(String sessionId) =>
      trainingRepo.deleteWorkoutSession(sessionId);

  Future<void> updateTrainingXpAndLevel(String userId, int xp, int level) =>
      trainingRepo.updateTrainingXpAndLevel(userId, xp, level);

  // ═══════════════════════════════════════════════════════════════
  // SOCIAL REPOSITORY DELEGATES
  // ═══════════════════════════════════════════════════════════════

  Future<void> followUser(String followerId, String followingId, {required bool targetIsPublic}) =>
      socialRepo.followUser(followerId, followingId, targetIsPublic: targetIsPublic);

  Future<void> unfollowUser(String followerId, String followingId) =>
      socialRepo.unfollowUser(followerId, followingId);

  Future<void> acceptFollowRequest(String followId) =>
      socialRepo.acceptFollowRequest(followId);

  Future<void> rejectFollowRequest(String followId) =>
      socialRepo.rejectFollowRequest(followId);

  Future<List<Map<String, dynamic>>> getFollowers(String userId) =>
      socialRepo.getFollowers(userId);

  Future<List<Map<String, dynamic>>> getFollowing(String userId) =>
      socialRepo.getFollowing(userId);

  Future<List<Map<String, dynamic>>> getPendingFollowRequests(String userId) =>
      socialRepo.getPendingFollowRequests(userId);

  Future<Map<String, int>> getFollowCounts(String userId) =>
      socialRepo.getFollowCounts(userId);

  Future<String?> getFollowStatus(String followerId, String followingId) =>
      socialRepo.getFollowStatus(followerId, followingId);

  Future<bool> areMutualFollowers(String userId1, String userId2) =>
      socialRepo.areMutualFollowers(userId1, userId2);

  Future<bool> isUserPublic(String userId) =>
      socialRepo.isUserPublic(userId);

  Future<List<Map<String, dynamic>>> searchUsers(String query, {int limit = 20}) =>
      socialRepo.searchUsers(query, limit: limit);

  // ═══════════════════════════════════════════════════════════════
  // CHAT REPOSITORY DELEGATES
  // ═══════════════════════════════════════════════════════════════

  static String getDirectChatId(String userId1, String userId2) =>
      ChatRepository.getDirectChatId(userId1, userId2);

  Future<Map<String, dynamic>?> sendMessage({
    required String chatType,
    required String chatId,
    required String senderId,
    required String content,
    String messageType = 'text',
    String? mediaUrl,
  }) => chatRepo.sendMessage(
        chatType: chatType,
        chatId: chatId,
        senderId: senderId,
        content: content,
        messageType: messageType,
        mediaUrl: mediaUrl,
      );

  Future<List<Map<String, dynamic>>> getMessages(
    String chatId, {
    int limit = 50,
    DateTime? before,
  }) => chatRepo.getMessages(chatId, limit: limit, before: before);

  Future<List<Map<String, dynamic>>> getDirectConversations(String userId) =>
      chatRepo.getDirectConversations(userId);

  Future<void> deleteMessage(String messageId) =>
      chatRepo.deleteMessage(messageId);

  Future<int> cleanupOldCommunityMessages(String chatId, {int daysToKeep = 3}) =>
      chatRepo.cleanupOldCommunityMessages(chatId, daysToKeep: daysToKeep);

  Future<int> clearDirectChat(String chatId) =>
      chatRepo.clearDirectChat(chatId);

  // ═══════════════════════════════════════════════════════════════
  // MATCH EVENTS REPOSITORY DELEGATES
  // ═══════════════════════════════════════════════════════════════

  Future<void> addMatchEvent(Map<String, dynamic> eventData) =>
      matchEventsRepo.addMatchEvent(eventData);

  Future<void> deleteMatchEvent(String eventId) =>
      matchEventsRepo.deleteMatchEvent(eventId);

  Future<List<Map<String, dynamic>>> getMatchEvents(String matchId) =>
      matchEventsRepo.getMatchEvents(matchId);

  dynamic watchMatchEventsChannel(String matchId, {required VoidCallback onChanged}) =>
      matchEventsRepo.watchMatchEventsChannel(matchId, onChanged: onChanged);

  // ═══════════════════════════════════════════════════════════════
  // MIGRATION (one-time, kept in facade for backward compat)
  // ═══════════════════════════════════════════════════════════════

  Future<Map<String, int>> migrateStatsToPerInnerMatch() async {
    // This is a one-time migration helper — kept here for simplicity
    final db = Supabase.instance.client;
    int deleted = 0;
    int inserted = 0;
    int skipped = 0;

    try {
      final allStats = await db
          .from('match_player_stats')
          .select()
          .order('created_at', ascending: true);

      appLog('MIGRATION: Found ${allStats.length} existing records');

      final byMatch = <String, List<Map<String, dynamic>>>{};
      for (final row in allStats) {
        final matchId = row['match_id'] as String? ?? '';
        byMatch.putIfAbsent(matchId, () => []).add(Map<String, dynamic>.from(row));
      }

      appLog('MIGRATION: ${byMatch.length} unique matches');

      for (final matchId in byMatch.keys) {
        final records = byMatch[matchId]!;

        SportMatch? match;
        try {
          final matchData = await db
              .from('matches')
              .select()
              .eq('id', matchId)
              .maybeSingle();
          if (matchData != null) {
            match = matchRepo.parseMatch(matchData);
          }
        } catch (e) {
          appLog('MIGRATION: Could not load match $matchId: $e');
        }

        if (match == null || match.innerMatches.isEmpty || match.eventTeams.length < 2) {
          skipped += records.length;
          appLog('MIGRATION: Skipping match $matchId (no inner matches)');
          continue;
        }

        List<Map<String, dynamic>> liveEvents = [];
        try {
          liveEvents = await matchEventsRepo.getMatchEvents(matchId);
        } catch (_) {}

        Map<String, int> getImStats(String playerId, String innerMatchId) {
          int goals = 0, assists = 0, saves = 0;
          for (final e in liveEvents) {
            if (e['player_id'] != playerId) continue;
            if (e['inner_match_id'] != innerMatchId) continue;
            final type = e['event_type'] as String? ?? '';
            if (type == 'goal' || type == 'kill' || type == 'ace') goals++;
            if (type == 'assist' || type == 'winner') assists++;
            if (type == 'save' || type == 'block') saves++;
          }
          return {'goals': goals, 'assists': assists, 'saves': saves};
        }

        for (final record in records) {
          final pid = record['user_id'] as String? ?? '';

          int playerTeamIdx = -1;
          for (int ti = 0; ti < match.eventTeams.length; ti++) {
            if (match.eventTeams[ti].hasPlayer(pid)) {
              playerTeamIdx = ti;
              break;
            }
          }

          if (playerTeamIdx < 0) {
            skipped++;
            continue;
          }

          final playerInnerMatches = match.innerMatches.where((im) {
            if (!im.isCompleted) return false;
            return im.team1Index == playerTeamIdx || im.team2Index == playerTeamIdx;
          }).toList();

          if (playerInnerMatches.length <= 1) {
            if (playerInnerMatches.length == 1) {
              final im = playerInnerMatches.first;
              final isTeam1 = im.team1Index == playerTeamIdx;
              final myScore = isTeam1 ? im.team1Score : im.team2Score;
              final oppScore = isTeam1 ? im.team2Score : im.team1Score;
              await db.from('match_player_stats').update({
                'is_win': myScore > oppScore,
                'is_draw': myScore == oppScore,
              }).eq('id', record['id']);
            }
            skipped++;
            continue;
          }

          final oldId = record['id'];
          await db.from('match_player_stats').delete().eq('id', oldId);
          deleted++;

          final newRecords = <Map<String, dynamic>>[];
          for (final im in playerInnerMatches) {
            final isTeam1 = im.team1Index == playerTeamIdx;
            final myScore = isTeam1 ? im.team1Score : im.team2Score;
            final oppScore = isTeam1 ? im.team2Score : im.team1Score;
            final imStats = getImStats(pid, im.id);

            newRecords.add({
              'community_id': record['community_id'],
              'match_id': matchId,
              'user_id': pid,
              'user_name': record['user_name'],
              'goals': imStats['goals'] ?? 0,
              'assists': imStats['assists'] ?? 0,
              'saves': imStats['saves'] ?? 0,
              'attack_rating': record['attack_rating'] ?? 6.0,
              'defense_rating': record['defense_rating'] ?? 6.0,
              'speed_rating': record['speed_rating'] ?? 6.0,
              'overall_rating': record['overall_rating'] ?? 6.0,
              'is_win': myScore > oppScore,
              'is_draw': myScore == oppScore,
              'is_mvp': record['is_mvp'] ?? false,
              'sport_category': record['sport_category'] ?? 'football',
            });
          }

          if (newRecords.isNotEmpty) {
            await db.from('match_player_stats').insert(newRecords);
            inserted += newRecords.length;
          }

          appLog('MIGRATION: Player $pid in match $matchId: 1 → ${newRecords.length} records');
        }
      }

      appLog('MIGRATION DONE: deleted=$deleted, inserted=$inserted, skipped=$skipped');
      return {'deleted': deleted, 'inserted': inserted, 'skipped': skipped};
    } catch (e) {
      appLog('MIGRATION ERROR: $e');
      rethrow;
    }
  }
}
