import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/community.dart';
import '../models/enums.dart';
import '../models/user_profile.dart';
import '../models/sport_match.dart';
import '../models/subscription.dart';
import '../models/transaction.dart' as app_tx;

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  // ===== AVATAR UPLOAD =====

  /// Upload avatar image and return public URL
  Future<String?> uploadAvatar(String userId, Uint8List bytes, String ext) async {
    try {
      final path = 'avatars/$userId.$ext';
      await _supabase.storage.from('avatars').uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(
          contentType: 'image/$ext',
          upsert: true,
        ),
      );
      final url = _supabase.storage.from('avatars').getPublicUrl(path);
      // Add cache buster to force reload
      final publicUrl = '$url?t=${DateTime.now().millisecondsSinceEpoch}';
      debugPrint('AVATAR: Uploaded to $publicUrl');
      return publicUrl;
    } catch (e) {
      debugPrint('AVATAR ERROR: $e');
      return null;
    }
  }

  Future<String?> uploadCommunityLogo(String communityId, Uint8List bytes, String ext) async {
    try {
      final path = 'community_logos/$communityId.$ext';
      await _supabase.storage.from('avatars').uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(
          contentType: 'image/$ext',
          upsert: true,
        ),
      );
      final url = _supabase.storage.from('avatars').getPublicUrl(path);
      final publicUrl = '$url?t=${DateTime.now().millisecondsSinceEpoch}';
      debugPrint('LOGO: Uploaded to $publicUrl');
      return publicUrl;
    } catch (e) {
      debugPrint('LOGO ERROR: $e');
      return null;
    }
  }

  Future<void> updateCommunityLogoUrl(String communityId, String logoUrl) async {
    await _supabase.from('communities').update({
      'logo_url': logoUrl,
    }).eq('id', communityId);
  }

  // ===== USERS =====

  Future<void> createUser(UserProfile user) async {
    await _supabase.from('users').insert({
      'id': user.id,
      'name': user.name,
      'email': user.email,
      'position': user.position,
      'balance': user.balance,
      'debt': user.debt,
      'community_ids': user.communityIds,
      'is_premium': user.isPremium,
      'games_played': user.gamesPlayed,
      'goals_scored': user.goalsScored,
      'sport_positions': user.sportPositions,
      'gender': user.gender,
      'height_cm': user.heightCm,
      'weight_kg': user.weightKg,
      'age': user.age,
      'training_xp': user.trainingXp,
      'training_level': user.trainingLevel,
      'is_public_profile': user.isPublicProfile,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<UserProfile?> getUser(String uid) async {
    final response = await _supabase
        .from('users')
        .select()
        .eq('id', uid)
        .maybeSingle();

    if (response == null) return null;
    
    return UserProfile(
      id: response['id'],
      name: response['name'] ?? '',
      email: response['email'],
      position: response['position'] ?? 'Не указана',
      avatarUrl: response['avatar_url'],
      balance: (response['balance'] ?? 0).toDouble(),
      debt: (response['debt'] ?? 0).toDouble(),
      communityIds: List<String>.from(response['community_ids'] ?? []),
      isPremium: response['is_premium'] ?? false,
      gamesPlayed: response['games_played'] ?? 0,
      goalsScored: response['goals_scored'] ?? 0,
      sportPositions: response['sport_positions'] != null
          ? Map<String, String>.from(response['sport_positions'])
          : {},
      gender: response['gender'],
      heightCm: response['height_cm'],
      weightKg: (response['weight_kg'] as num?)?.toDouble(),
      age: response['age'],
      trainingXp: response['training_xp'] ?? 0,
      trainingLevel: response['training_level'] ?? 1,
      isPublicProfile: response['is_public_profile'] ?? true,
    );
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    // Map Firestore names to Supabase names (camelCase to snake_case)
    final mappedData = <String, dynamic>{};
    const keyMap = {
      'communityIds': 'community_ids',
      'isPremium': 'is_premium',
      'gamesPlayed': 'games_played',
      'goalsScored': 'goals_scored',
      'avatarUrl': 'avatar_url',
      'sportPositions': 'sport_positions',
      'heightCm': 'height_cm',
      'weightKg': 'weight_kg',
      'trainingXp': 'training_xp',
      'trainingLevel': 'training_level',
      'isPublicProfile': 'is_public_profile',
    };
    data.forEach((key, value) {
      mappedData[keyMap[key] ?? key] = value;
    });

    await _supabase.from('users').update(mappedData).eq('id', uid);
  }

  /// Обновить баланс пользователя (прибавить или вычесть amount)
  /// Требует SQL-функцию с SECURITY DEFINER:
  /// CREATE OR REPLACE FUNCTION increment_user_balance(user_id_param UUID, amount_param DECIMAL)
  /// RETURNS void AS $$ BEGIN UPDATE users SET balance = balance + amount_param WHERE id = user_id_param; END; $$ LANGUAGE plpgsql SECURITY DEFINER;
  Future<void> updateUserBalance(String uid, double amount) async {
    try {
      debugPrint('BALANCE: calling RPC for $uid amount=$amount');
      await _supabase.rpc('increment_user_balance', params: {
        'user_id_param': uid,
        'amount_param': amount,
      });
      debugPrint('BALANCE: RPC success for $uid');
    } catch (e) {
      debugPrint('BALANCE: RPC FAILED for $uid: $e');
      // Fallback: direct update (works only if RLS allows)
      try {
        final current = await _supabase
            .from('users')
            .select('balance')
            .eq('id', uid)
            .maybeSingle();
        if (current != null) {
          final newBalance = (current['balance'] as num).toDouble() + amount;
          await _supabase
              .from('users')
              .update({'balance': newBalance})
              .eq('id', uid);
          debugPrint('BALANCE: fallback OK — $uid -> $newBalance');
        } else {
          debugPrint('BALANCE: user $uid not found in DB!');
        }
      } catch (e2) {
        debugPrint('BALANCE: FALLBACK ALSO FAILED for $uid: $e2');
      }
    }
  }

  /// Получить список пользователей по ID
  Future<List<UserProfile>> getUsersByIds(List<String> userIds) async {
    if (userIds.isEmpty) return [];
    final response = await _supabase
        .from('users')
        .select()
        .inFilter('id', userIds);

    return (response as List).map((d) => UserProfile(
      id: d['id'],
      name: d['name'] ?? '',
      email: d['email'],
      position: d['position'] ?? 'Не указана',
      avatarUrl: d['avatar_url'],
      balance: (d['balance'] ?? 0).toDouble(),
      debt: (d['debt'] ?? 0).toDouble(),
      communityIds: List<String>.from(d['community_ids'] ?? []),
      isPremium: d['is_premium'] ?? false,
      gamesPlayed: d['games_played'] ?? 0,
      goalsScored: d['goals_scored'] ?? 0,
    )).toList();
  }

  // ===== COMMUNITIES =====

  Future<void> createCommunity(Community community) async {
    await _supabase.from('communities').insert({
      'name': community.name,
      'sport': community.sport.index,
      'invite_code': community.inviteCode,
      'owner_id': community.ownerId,
      'admin_ids': community.adminIds,
      'member_ids': community.memberIds,
      'monthly_rent': community.monthlyRent,
      'single_game_price': community.singleGamePrice,
      'bank_balance': community.bankBalance,
    });
  }

  /// Insert community and return the generated row (with UUID id)
  Future<Map<String, dynamic>> createCommunityAndReturn({
    required String name,
    required SportCategory sport,
    required String inviteCode,
    required String ownerId,
    double monthlyRent = 100000,
    double singleGamePrice = 1200,
  }) async {
    final response = await _supabase.from('communities').insert({
      'name': name,
      'sport': sport.index,
      'invite_code': inviteCode,
      'owner_id': ownerId,
      'admin_ids': [ownerId],
      'member_ids': [],
      'monthly_rent': monthlyRent,
      'single_game_price': singleGamePrice,
      'bank_balance': 0,
    }).select().single();
    return response;
  }

  Future<Community?> getCommunityByInviteCode(String code) async {
    final response = await _supabase
        .from('communities')
        .select()
        .eq('invite_code', code.toUpperCase())
        .maybeSingle();

    if (response == null) return null;
    return _communityFromMap(response);
  }

  Future<List<Community>> getUserCommunities(List<String> communityIds) async {
    if (communityIds.isEmpty) return [];
    final response = await _supabase
        .from('communities')
        .select()
        .inFilter('id', communityIds);

    return (response as List).map((d) => _communityFromMap(d)).toList();
  }

  /// Атомарное вступление в сообщество через RPC (без race conditions)
  Future<void> joinCommunity(String communityId, String userId) async {
    await _supabase.rpc('join_community', params: {
      'p_community_id': communityId,
      'p_user_id': userId,
    });
  }

  /// Атомарный выход из сообщества через RPC (без race conditions)
  Future<void> leaveCommunity(String communityId, String userId) async {
    await _supabase.rpc('leave_community', params: {
      'p_community_id': communityId,
      'p_user_id': userId,
    });
  }

  Future<void> updateCommunityAdmins(
    String communityId,
    List<String> adminIds,
    List<String> memberIds,
  ) async {
    await _supabase.from('communities').update({
      'admin_ids': adminIds,
      'member_ids': memberIds,
    }).eq('id', communityId);
  }

  Future<void> updateCommunityBank(
      String communityId, double newBalance) async {
    await _supabase.from('communities').update({
      'bank_balance': newBalance,
    }).eq('id', communityId);
  }

  Community _communityFromMap(Map<String, dynamic> d) {
    return Community(
      id: d['id'].toString(),
      name: d['name'] ?? '',
      sport: SportCategory.values[d['sport'] ?? 0],
      inviteCode: d['invite_code'] ?? '',
      ownerId: d['owner_id'] ?? '',
      adminIds: List<String>.from(d['admin_ids'] ?? []),
      memberIds: List<String>.from(d['member_ids'] ?? []),
      monthlyRent: (d['monthly_rent'] ?? 100000).toDouble(),
      singleGamePrice: (d['single_game_price'] ?? 1200).toDouble(),
      bankBalance: (d['bank_balance'] ?? 0).toDouble(),
      logoUrl: d['logo_url']?.toString(),
    );
  }

  // ===== COMMUNITY DIRECTORY =====

  /// Get ALL communities for the directory
  Future<List<Community>> getAllCommunities() async {
    final response = await _supabase
        .from('communities')
        .select()
        .order('name');
    return (response as List).map((d) => _communityFromMap(d)).toList();
  }

  // ===== JOIN REQUESTS =====

  /// Create a join request
  Future<void> createJoinRequest(String communityId, String userId) async {
    await _supabase.from('join_requests').upsert({
      'user_id': userId,
      'community_id': communityId,
      'status': 'pending',
    }, onConflict: 'user_id,community_id');
  }

  /// Get join requests for a community (for admins)
  Future<List<Map<String, dynamic>>> getJoinRequestsForCommunity(String communityId) async {
    final response = await _supabase
        .from('join_requests')
        .select()
        .eq('community_id', communityId)
        .eq('status', 'pending')
        .order('created_at');
    return List<Map<String, dynamic>>.from(response);
  }

  /// Get user's own join requests
  Future<List<Map<String, dynamic>>> getUserJoinRequests(String userId) async {
    final response = await _supabase
        .from('join_requests')
        .select()
        .eq('user_id', userId)
        .order('created_at');
    return List<Map<String, dynamic>>.from(response);
  }

  /// Update join request status (accept/reject)
  Future<void> updateJoinRequestStatus(String requestId, String status) async {
    await _supabase.from('join_requests').update({
      'status': status,
    }).eq('id', requestId);
  }

  /// Delete a join request
  Future<void> deleteJoinRequest(String requestId) async {
    await _supabase.from('join_requests').delete().eq('id', requestId);
  }

  // ===== SUBSCRIPTIONS =====

  Future<String> saveSubscription(
      String communityId, MonthlySubscription sub) async {
    // Map to snake_case DB columns
    final map = <String, dynamic>{
      'community_id': communityId,
      'month': sub.month,
      'year': sub.year,
      'total_rent': sub.totalRent,
      'compensation_amount': sub.compensationAmount,
      'entries': sub.entries.map((e) => e.toMap()).toList(),
      'is_calculated': sub.isCalculated,
      'calculation_date': sub.calculationDate?.millisecondsSinceEpoch,
      'payment_deadline': sub.paymentDeadline?.millisecondsSinceEpoch,
    };

    // If sub.id is a real UUID, the row already exists → use UPDATE
    // (UPDATE policy allows all community members, INSERT only admins)
    final isRealUuid = sub.id.length == 36 && sub.id.contains('-');
    if (isRealUuid) {
      final result = await _supabase
          .from('subscriptions')
          .update(map)
          .eq('id', sub.id)
          .select()
          .single();
      return result['id'].toString();
    }

    // New subscription → use upsert (requires admin INSERT policy)
    final result = await _supabase
        .from('subscriptions')
        .upsert(map, onConflict: 'community_id,month,year')
        .select()
        .single();
    return result['id'].toString();
  }

  Future<List<MonthlySubscription>> getSubscriptions(
      String communityId) async {
    final response = await _supabase
        .from('subscriptions')
        .select()
        .eq('community_id', communityId)
        .order('year', ascending: false)
        .order('month', ascending: false);
    
    return (response as List).map((d) => MonthlySubscription.fromMap(
      d['id'].toString(),
      {
        'communityId': d['community_id'] ?? '',
        'month': d['month'] ?? 1,
        'year': d['year'] ?? 2026,
        'totalRent': d['total_rent'] ?? 0,
        'compensationAmount': d['compensation_amount'] ?? 0,
        'entries': d['entries'] ?? [],
        'isCalculated': d['is_calculated'] ?? false,
        'calculationDate': d['calculation_date'],
        'paymentDeadline': d['payment_deadline'],
      },
    )).toList();
  }

  Future<MonthlySubscription?> getSubscriptionForMonth(
    String communityId,
    int month,
    int year,
  ) async {
    final response = await _supabase
        .from('subscriptions')
        .select()
        .eq('community_id', communityId)
        .eq('month', month)
        .eq('year', year)
        .maybeSingle();

    if (response == null) return null;
    return MonthlySubscription.fromMap(response['id'].toString(), response);
  }

  Stream<MonthlySubscription?> watchSubscription(
    String communityId,
    int month,
    int year,
  ) {
    return _supabase
        .from('subscriptions')
        .stream(primaryKey: ['id'])
        .eq('community_id', communityId)
        .map((list) {
      if (list.isEmpty) return null;
      final filtered = list.where((d) => d['month'] == month && d['year'] == year);
      if (filtered.isEmpty) return null;
      return MonthlySubscription.fromMap(filtered.first['id'].toString(), filtered.first);
    });
  }

  Future<void> deleteSubscription(String subscriptionId) async {
    await _supabase.from('subscriptions').delete().eq('id', subscriptionId);
  }

  // ===== MATCHES =====

  Future<void> createMatch(String communityId, SportMatch match) async {
    await _supabase.from('matches').insert({
      'community_id': communityId,
      'category': match.category.index,
      'format': match.format,
      'date_time': match.dateTime.toIso8601String(),
      'location': match.location,
      'price': match.price,
      'total_capacity': match.totalCapacity,
      'current_players': match.currentPlayers,
      'registered_player_ids': match.registeredPlayerIds,
      'registered_player_names': match.registeredPlayerNames,
      'is_completed': match.isCompleted,
    });
  }

  /// Insert match and return the generated row (with UUID id)
  Future<Map<String, dynamic>> createMatchAndReturn(
      String? communityId, SportMatch match) async {
    final response = await _supabase.from('matches').insert({
      'community_id': (communityId != null && communityId.isNotEmpty) ? communityId : null,
      if (match.creatorId != null) 'creator_id': match.creatorId,
      'category': match.category.index,
      'format': match.format,
      'date_time': match.dateTime.toIso8601String(),
      'location': match.location,
      'price': match.price,
      'total_capacity': match.totalCapacity,
      'current_players': match.currentPlayers,
      'registered_player_ids': match.registeredPlayerIds,
      'registered_player_names': match.registeredPlayerNames,
      'is_completed': match.isCompleted,
    }).select().single();
    return response;
  }

  /// Get all matches for a community
  Future<List<SportMatch>> getMatches(String communityId) async {
    final response = await _supabase
        .from('matches')
        .select()
        .eq('community_id', communityId)
        .order('date_time', ascending: true);
    return (response as List).map((d) => _parseMatch(d)).toList();
  }

  /// Get ALL active (non-completed) matches globally
  Future<List<SportMatch>> getAllActiveMatches() async {
    final response = await _supabase
        .from('matches')
        .select()
        .eq('is_completed', false)
        .order('date_time', ascending: true);
    return (response as List).map((d) => _parseMatch(d)).toList();
  }

  /// Get ALL matches (active + completed) globally
  Future<List<SportMatch>> getAllMatches() async {
    final response = await _supabase
        .from('matches')
        .select()
        .order('date_time', ascending: true);
    return (response as List).map((d) => _parseMatch(d)).toList();
  }

  /// Parse a single match row into SportMatch
  SportMatch _parseMatch(Map<String, dynamic> d) {
    final playerIds = List<String>.from(d['registered_player_ids'] ?? []);
    return SportMatch(
      id: d['id'].toString(),
      communityId: d['community_id']?.toString(),
      creatorId: d['creator_id']?.toString(),
      category: SportCategory.values[d['category'] ?? 0],
      format: d['format'] ?? '',
      dateTime: DateTime.parse(d['date_time']),
      location: d['location'] ?? '',
      price: (d['price'] ?? 0).toDouble(),
      totalCapacity: d['total_capacity'] ?? 20,
      currentPlayers: playerIds.length,
      registeredPlayerIds: playerIds,
      registeredPlayerNames:
          List<String>.from(d['registered_player_names'] ?? []),
      isCompleted: d['is_completed'] ?? false,
      eventTeams: _parseEventTeams(d['event_teams']),
      innerMatches: _parseInnerMatches(d['inner_matches']),
    );
  }

  Stream<List<SportMatch>> watchMatches(String communityId) {
    return _supabase
        .from('matches')
        .stream(primaryKey: ['id'])
        .eq('community_id', communityId)
        .map((list) => list
            .map((d) {
                  final playerIds = List<String>.from(d['registered_player_ids'] ?? []);
                  return SportMatch(
                    id: d['id'].toString(),
                    communityId: communityId,
                    category: SportCategory.values[d['category'] ?? 0],
                    format: d['format'] ?? '',
                    dateTime: DateTime.parse(d['date_time']),
                    location: d['location'] ?? '',
                    price: (d['price'] ?? 0).toDouble(),
                    totalCapacity: d['total_capacity'] ?? 20,
                    currentPlayers: playerIds.length,
                    registeredPlayerIds: playerIds,
                    registeredPlayerNames:
                        List<String>.from(d['registered_player_names'] ?? []),
                    isCompleted: d['is_completed'] ?? false,
                    eventTeams: _parseEventTeams(d['event_teams']),
                    innerMatches: _parseInnerMatches(d['inner_matches']),
                  );
                })
            .toList()
          ..sort((a, b) => a.dateTime.compareTo(b.dateTime)));
  }

  /// Subscribe to Realtime changes on matches table (all matches globally)
  dynamic watchAllMatchesChannel({required VoidCallback onChanged}) {
    final channel = _supabase.channel('matches_global')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'matches',
        callback: (payload) {
          debugPrint('REALTIME: matches changed — ${payload.eventType}');
          onChanged();
        },
      )
      .subscribe();
    return channel;
  }

  /// Subscribe to Realtime changes on matches table (community-specific, kept for backward compat)
  dynamic watchMatchesChannel(String communityId, {required VoidCallback onChanged}) {
    final channel = _supabase.channel('matches_$communityId')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'matches',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'community_id',
          value: communityId,
        ),
        callback: (payload) {
          debugPrint('REALTIME: matches changed — ${payload.eventType}');
          onChanged();
        },
      )
      .subscribe();
    return channel;
  }

  /// RPC: Add amount to any user's balance atomically
  Future<void> addToUserBalance(String userId, double amount) async {
    await _supabase.rpc('add_to_user_balance', params: {
      'target_user_id': userId,
      'amount': amount,
    });
  }

  /// Subscribe to Realtime changes on subscriptions table
  dynamic watchSubscriptionsChannel(String communityId, {required VoidCallback onChanged}) {
    final channel = _supabase.channel('subs_$communityId')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'subscriptions',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'community_id',
          value: communityId,
        ),
        callback: (payload) {
          debugPrint('REALTIME: subscriptions changed — ${payload.eventType}');
          onChanged();
        },
      )
      .subscribe();
    return channel;
  }

  /// Subscribe to Realtime changes on a specific community row
  dynamic watchCommunityChannel(String communityId, {required VoidCallback onChanged}) {
    final channel = _supabase.channel('community_$communityId')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'communities',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'id',
          value: communityId,
        ),
        callback: (payload) {
          debugPrint('REALTIME: community changed — ${payload.eventType}');
          onChanged();
        },
      )
      .subscribe();
    return channel;
  }

  /// Subscribe to Realtime changes on a specific user row
  dynamic watchUserChannel(String userId, {required VoidCallback onChanged}) {
    final channel = _supabase.channel('user_$userId')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'users',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'id',
          value: userId,
        ),
        callback: (payload) {
          debugPrint('REALTIME: user profile changed — ${payload.eventType}');
          onChanged();
        },
      )
      .subscribe();
    return channel;
  }

  Future<void> updateMatch(
      String communityId, String matchId, Map<String, dynamic> data) async {
    final mappedData = <String, dynamic>{};
    const keyMap = {
      'dateTime': 'date_time',
      'totalCapacity': 'total_capacity',
      'currentPlayers': 'current_players',
      'registeredPlayerIds': 'registered_player_ids',
      'registeredPlayerNames': 'registered_player_names',
      'isCompleted': 'is_completed',
      'eventTeams': 'event_teams',
      'innerMatches': 'inner_matches',
    };
    data.forEach((key, value) {
      if (key == 'dateTime') {
        mappedData['date_time'] = (value as DateTime).toIso8601String();
      } else {
        mappedData[keyMap[key] ?? key] = value;
      }
    });

    await _supabase.from('matches').update(mappedData).eq('id', matchId);
  }

  // ===== HELPERS =====

  List<EventTeam> _parseEventTeams(dynamic json) {
    if (json == null) return [];
    try {
      final list = json is List ? json : [];
      return list.map((e) => EventTeam.fromJson(Map<String, dynamic>.from(e))).toList();
    } catch (e) {
      debugPrint('PARSE: Failed to parse event_teams: $e');
      return [];
    }
  }

  List<InnerMatch> _parseInnerMatches(dynamic json) {
    if (json == null) return [];
    try {
      final list = json is List ? json : [];
      return list.map((e) => InnerMatch.fromJson(Map<String, dynamic>.from(e))).toList();
    } catch (e) {
      debugPrint('PARSE: Failed to parse inner_matches: $e');
      return [];
    }
  }

  // ===== TRANSACTIONS =====

  Future<void> addTransaction(
      String communityId, app_tx.Transaction tx) async {
    await _supabase.from('transactions').insert({
      'community_id': communityId,
      'user_id': tx.userId,
      'type': tx.type.index,
      'amount': tx.amount,
      'status': tx.status.index,
      'description': tx.description,
      'date_time': tx.dateTime.toIso8601String(),
    });
  }

  Stream<List<app_tx.Transaction>> watchTransactions(
      String communityId, String userId) {
    return _supabase
        .from('transactions')
        .stream(primaryKey: ['id'])
        .eq('community_id', communityId)
        .map((list) => list
            .where((d) => d['user_id'] == userId)
            .map((d) => app_tx.Transaction(
                  id: d['id'].toString(),
                  userId: d['user_id'] ?? '',
                  communityId: communityId,
                  type: TransactionType.values[d['type'] ?? 0],
                  amount: (d['amount'] ?? 0).toDouble(),
                  status: TransactionStatus.values[d['status'] ?? 0],
                  description: d['description'] ?? '',
                  dateTime: DateTime.parse(d['date_time']),
                ))
            .toList()
          ..sort((a, b) => b.dateTime.compareTo(a.dateTime)));
  }

  // ===== PLAYER STATS =====

  /// Save player stats for a completed match
  Future<void> saveMatchPlayerStats(List<Map<String, dynamic>> statsList) async {
    if (statsList.isEmpty) return;
    await _supabase.from('match_player_stats').insert(statsList);
    debugPrint('STATS: Saved ${statsList.length} player stats records');
  }

  /// Get aggregated stats for a player (all-time or filtered by sport)
  Future<Map<String, dynamic>?> getPlayerAggregateStats(
    String userId, {
    String? sportCategory,
  }) async {
    try {
      var query = _supabase
          .from('match_player_stats')
          .select()
          .eq('user_id', userId);

      if (sportCategory != null) {
        query = query.eq('sport_category', sportCategory);
      }

      final data = await query.order('created_at', ascending: false);

      if (data.isEmpty) return null;

      int totalGames = data.length;
      int totalGoals = 0;
      int totalAssists = 0;
      int totalSaves = 0;
      int totalMvp = 0;
      int winCount = 0;
      int drawCount = 0;
      int lossCount = 0;
      double totalRating = 0;

      for (final row in data) {
        totalGoals += (row['goals'] as int?) ?? 0;
        totalAssists += (row['assists'] as int?) ?? 0;
        totalSaves += (row['saves'] as int?) ?? 0;
        if (row['is_mvp'] == true) totalMvp++;
        if (row['is_win'] == true) {
          winCount++;
        } else if (row['is_draw'] == true) {
          drawCount++;
        } else {
          lossCount++;
        }
        totalRating += (row['overall_rating'] as num?)?.toDouble() ?? 6.0;
      }

      return {
        'total_games': totalGames,
        'total_goals': totalGoals,
        'total_assists': totalAssists,
        'total_saves': totalSaves,
        'total_mvp': totalMvp,
        'avg_rating': totalGames > 0 ? totalRating / totalGames : 0.0,
        'win_count': winCount,
        'draw_count': drawCount,
        'loss_count': lossCount,
      };
    } catch (e) {
      debugPrint('STATS ERROR: Failed to get aggregate stats: $e');
      return null;
    }
  }

  /// Get aggregated stats via RPC (server-side, faster)
  Future<Map<String, dynamic>?> getPlayerStatsBySportRpc(
    String userId, {
    String? sportCategory,
  }) async {
    try {
      final result = await _supabase.rpc('get_player_stats_by_sport', params: {
        'p_user_id': userId,
        'p_sport_category': sportCategory,
      });

      if (result == null || (result is List && result.isEmpty)) return null;

      final row = result is List ? result.first : result;
      return {
        'total_games': row['total_games'] ?? 0,
        'total_goals': row['total_goals'] ?? 0,
        'total_assists': row['total_assists'] ?? 0,
        'total_saves': row['total_saves'] ?? 0,
        'total_mvp': row['total_mvp'] ?? 0,
        'avg_rating': (row['avg_rating'] ?? 0.0).toDouble(),
        'win_count': row['win_count'] ?? 0,
        'draw_count': row['draw_count'] ?? 0,
        'loss_count': row['loss_count'] ?? 0,
        'total_distance': (row['total_distance'] ?? 0.0).toDouble(),
      };
    } catch (e) {
      debugPrint('STATS RPC ERROR: $e');
      // Fallback to client-side aggregation
      return getPlayerAggregateStats(userId, sportCategory: sportCategory);
    }
  }

  /// Get recent match history for a player (optionally filtered by sport)
  Future<List<Map<String, dynamic>>> getPlayerMatchHistory(
      String userId, {int limit = 10, String? sportCategory}) async {
    try {
      var query = _supabase
          .from('match_player_stats')
          .select()
          .eq('user_id', userId);

      if (sportCategory != null) {
        query = query.eq('sport_category', sportCategory);
      }

      final data = await query
          .order('created_at', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('STATS ERROR: Failed to get match history: $e');
      return [];
    }
  }

  // ===== MATCH EVENTS (LIVE) =====

  /// Add a live match event (goal, assist, save, foul, own_goal, etc.)
  Future<void> addMatchEvent(Map<String, dynamic> eventData) async {
    await _supabase.from('match_events').insert(eventData);
  }

  /// Delete a match event by ID
  Future<void> deleteMatchEvent(String eventId) async {
    await _supabase.from('match_events').delete().eq('id', eventId);
  }

  /// Get all events for a match, ordered chronologically
  Future<List<Map<String, dynamic>>> getMatchEvents(String matchId) async {
    final data = await _supabase
        .from('match_events')
        .select()
        .eq('match_id', matchId)
        .order('created_at', ascending: true);
    return List<Map<String, dynamic>>.from(data);
  }

  /// Subscribe to realtime changes on match_events for a specific match
  dynamic watchMatchEventsChannel(String matchId, {required VoidCallback onChanged}) {
    return _supabase
        .channel('match_events_$matchId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'match_events',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'match_id',
            value: matchId,
          ),
          callback: (payload) {
            debugPrint('REALTIME: match_events changed — ${payload.eventType}');
            onChanged();
          },
        )
        .subscribe();
  }

  // ===== PLAYER DISTANCE =====

  /// Save distance for a specific match+player
  Future<void> savePlayerDistance(
    String matchId,
    String userId,
    double km, {
    String sportCategory = 'football',
  }) async {
    // Check if record exists
    final existing = await _supabase
        .from('match_player_stats')
        .select('id')
        .eq('match_id', matchId)
        .eq('user_id', userId)
        .maybeSingle();

    if (existing != null) {
      // Update existing
      await _supabase
          .from('match_player_stats')
          .update({
            'distance_km': km,
            'sport_category': sportCategory,
          })
          .eq('match_id', matchId)
          .eq('user_id', userId);
    } else {
      // Insert new
      await _supabase.from('match_player_stats').insert({
        'match_id': matchId,
        'user_id': userId,
        'distance_km': km,
        'sport_category': sportCategory,
      });
    }
  }

  /// Get distance for a player in a specific match
  Future<double> getPlayerDistance(String matchId, String userId) async {
    try {
      final data = await _supabase
          .from('match_player_stats')
          .select('distance_km')
          .eq('match_id', matchId)
          .eq('user_id', userId)
          .maybeSingle();
      return (data?['distance_km'] ?? 0.0).toDouble();
    } catch (_) {
      return 0.0;
    }
  }

  /// Get total distance across all matches for a player (optionally by sport)
  Future<double> getPlayerTotalDistance(String userId, {String? sportCategory}) async {
    try {
      var query = _supabase
          .from('match_player_stats')
          .select('distance_km')
          .eq('user_id', userId);

      if (sportCategory != null) {
        query = query.eq('sport_category', sportCategory);
      }

      final data = await query;
      double total = 0;
      for (final row in data) {
        total += (row['distance_km'] ?? 0.0).toDouble();
      }
      return total;
    } catch (_) {
      return 0.0;
    }
  }

  // ===== TRAINING MODULE =====

  // --- Exercises ---

  Future<List<Map<String, dynamic>>> getExercises(String userId) async {
    final data = await _supabase
        .from('exercises')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<Map<String, dynamic>> createExercise(Map<String, dynamic> exercise) async {
    final result = await _supabase
        .from('exercises')
        .insert(exercise)
        .select()
        .single();
    return result;
  }

  Future<void> updateExercise(String id, Map<String, dynamic> data) async {
    await _supabase.from('exercises').update(data).eq('id', id);
  }

  Future<void> deleteExercise(String id) async {
    await _supabase.from('exercises').delete().eq('id', id);
  }

  // --- Workout Sessions ---

  Future<Map<String, dynamic>> createWorkoutSession(Map<String, dynamic> session) async {
    final result = await _supabase
        .from('workout_sessions')
        .insert(session)
        .select()
        .single();
    return result;
  }

  Future<List<Map<String, dynamic>>> getWorkoutSessions(String userId, {int limit = 50}) async {
    final data = await _supabase
        .from('workout_sessions')
        .select()
        .eq('user_id', userId)
        .order('started_at', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> updateWorkoutSession(String id, Map<String, dynamic> data) async {
    await _supabase.from('workout_sessions').update(data).eq('id', id);
  }

  // --- Workout Sets ---

  Future<Map<String, dynamic>> createWorkoutSet(Map<String, dynamic> setData) async {
    final result = await _supabase
        .from('workout_sets')
        .insert(setData)
        .select()
        .single();
    return result;
  }

  Future<List<Map<String, dynamic>>> getWorkoutSets(String sessionId) async {
    final data = await _supabase
        .from('workout_sets')
        .select()
        .eq('session_id', sessionId)
        .order('set_order', ascending: true);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> updateWorkoutSet(String id, Map<String, dynamic> data) async {
    await _supabase.from('workout_sets').update(data).eq('id', id);
  }

  Future<void> deleteWorkoutSet(String id) async {
    await _supabase.from('workout_sets').delete().eq('id', id);
  }

  /// Delete a workout session and all its sets
  Future<void> deleteWorkoutSession(String sessionId) async {
    // Delete sets first (cascade)
    await _supabase.from('workout_sets').delete().eq('session_id', sessionId);
    await _supabase.from('workout_sessions').delete().eq('id', sessionId);
  }

  /// Update user training XP and level
  Future<void> updateTrainingXpAndLevel(String userId, int xp, int level) async {
    await _supabase.from('users').update({
      'training_xp': xp,
      'training_level': level,
    }).eq('id', userId);
  }

  // ===== FOLLOWS =====

  /// Follow a user. If target has public profile → status='accepted', else 'pending'.
  Future<void> followUser(String followerId, String followingId, {required bool targetIsPublic}) async {
    await _supabase.from('follows').upsert({
      'follower_id': followerId,
      'following_id': followingId,
      'status': targetIsPublic ? 'accepted' : 'pending',
    }, onConflict: 'follower_id,following_id');
  }

  /// Unfollow / cancel request
  Future<void> unfollowUser(String followerId, String followingId) async {
    await _supabase.from('follows')
        .delete()
        .eq('follower_id', followerId)
        .eq('following_id', followingId);
  }

  /// Accept a follow request (for closed profiles)
  Future<void> acceptFollowRequest(String followId) async {
    await _supabase.from('follows').update({
      'status': 'accepted',
    }).eq('id', followId);
  }

  /// Reject a follow request
  Future<void> rejectFollowRequest(String followId) async {
    await _supabase.from('follows').delete().eq('id', followId);
  }

  /// Get my followers (people who follow me) — accepted only
  Future<List<Map<String, dynamic>>> getFollowers(String userId) async {
    final response = await _supabase
        .from('follows')
        .select()
        .eq('following_id', userId)
        .eq('status', 'accepted')
        .order('created_at', ascending: false);
    // Enrich with user data
    final results = <Map<String, dynamic>>[];
    for (final row in response) {
      final userResp = await _supabase
          .from('users')
          .select('id, name, avatar_url, position, sport_positions, is_public_profile')
          .eq('id', row['follower_id'])
          .maybeSingle();
      results.add({...row, 'follower': userResp});
    }
    return results;
  }

  /// Get people I'm following — accepted only
  Future<List<Map<String, dynamic>>> getFollowing(String userId) async {
    final response = await _supabase
        .from('follows')
        .select()
        .eq('follower_id', userId)
        .eq('status', 'accepted')
        .order('created_at', ascending: false);
    final results = <Map<String, dynamic>>[];
    for (final row in response) {
      final userResp = await _supabase
          .from('users')
          .select('id, name, avatar_url, position, sport_positions, is_public_profile')
          .eq('id', row['following_id'])
          .maybeSingle();
      results.add({...row, 'following': userResp});
    }
    return results;
  }

  /// Get pending follow requests to me (for closed profiles)
  Future<List<Map<String, dynamic>>> getPendingFollowRequests(String userId) async {
    final response = await _supabase
        .from('follows')
        .select()
        .eq('following_id', userId)
        .eq('status', 'pending')
        .order('created_at', ascending: false);
    final results = <Map<String, dynamic>>[];
    for (final row in response) {
      final userResp = await _supabase
          .from('users')
          .select('id, name, avatar_url, position')
          .eq('id', row['follower_id'])
          .maybeSingle();
      results.add({...row, 'follower': userResp});
    }
    return results;
  }

  /// Get follow counts for a user
  Future<Map<String, int>> getFollowCounts(String userId) async {
    final followers = await _supabase
        .from('follows')
        .select()
        .eq('following_id', userId)
        .eq('status', 'accepted');
    final following = await _supabase
        .from('follows')
        .select()
        .eq('follower_id', userId)
        .eq('status', 'accepted');
    final pending = await _supabase
        .from('follows')
        .select()
        .eq('following_id', userId)
        .eq('status', 'pending');
    return {
      'followers': (followers as List).length,
      'following': (following as List).length,
      'pending': (pending as List).length,
    };
  }

  /// Check relationship status between two users
  /// Returns: null, 'pending', 'accepted'
  Future<String?> getFollowStatus(String followerId, String followingId) async {
    final response = await _supabase
        .from('follows')
        .select('status')
        .eq('follower_id', followerId)
        .eq('following_id', followingId)
        .maybeSingle();
    return response?['status'];
  }

  /// Check if two users are mutual followers (friends)
  Future<bool> areMutualFollowers(String userId1, String userId2) async {
    final f1 = await getFollowStatus(userId1, userId2);
    final f2 = await getFollowStatus(userId2, userId1);
    return f1 == 'accepted' && f2 == 'accepted';
  }

  /// Check if target user has public profile
  Future<bool> isUserPublic(String userId) async {
    final response = await _supabase
        .from('users')
        .select('is_public_profile')
        .eq('id', userId)
        .maybeSingle();
    return response?['is_public_profile'] ?? true;
  }

  /// Search users by name (for follow search)
  Future<List<Map<String, dynamic>>> searchUsers(String query, {int limit = 20}) async {
    if (query.trim().isEmpty) return [];
    final response = await _supabase
        .from('users')
        .select('id, name, avatar_url, position, is_public_profile')
        .ilike('name', '%${query.trim()}%')
        .limit(limit);
    return List<Map<String, dynamic>>.from(response);
  }

  // ═══════════ CHAT / MESSAGES ═══════════

  /// Expose supabase client for realtime subscriptions
  SupabaseClient get client => _supabase;

  /// Generate consistent direct chat ID from two user IDs
  static String getDirectChatId(String userId1, String userId2) {
    final sorted = [userId1, userId2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  /// Send a message
  Future<Map<String, dynamic>?> sendMessage({
    required String chatType,
    required String chatId,
    required String senderId,
    required String content,
    String messageType = 'text',
    String? mediaUrl,
  }) async {
    final response = await _supabase.from('messages').insert({
      'chat_type': chatType,
      'chat_id': chatId,
      'sender_id': senderId,
      'content': content,
      'message_type': messageType,
      if (mediaUrl != null) 'media_url': mediaUrl,
    }).select().single();
    return response;
  }

  /// Get messages for a chat with pagination
  Future<List<Map<String, dynamic>>> getMessages(
    String chatId, {
    int limit = 50,
    DateTime? before,
  }) async {
    var query = _supabase
        .from('messages')
        .select()
        .eq('chat_id', chatId)
        .eq('is_deleted', false)
        .order('created_at', ascending: false)
        .limit(limit);

    if (before != null) {
      query = _supabase
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
    // Collect unique sender IDs
    final senderIds = <String>{};
    for (final row in response) {
      senderIds.add(row['sender_id'] ?? '');
    }
    // Batch fetch sender profiles
    final senderProfiles = <String, Map<String, dynamic>>{};
    if (senderIds.isNotEmpty) {
      final profiles = await _supabase
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

  /// Get all direct conversations for a user (for DM inbox)
  /// Returns list of conversations with last message and other user info.
  Future<List<Map<String, dynamic>>> getDirectConversations(String userId) async {
    try {
      // Get all direct messages where userId is either sender or part of chat_id
      final response = await _supabase
          .from('messages')
          .select()
          .eq('chat_type', 'direct')
          .or('chat_id.ilike.%$userId%')
          .order('created_at', ascending: false);

      // Group by chat_id, keep only last message
      final Map<String, Map<String, dynamic>> chatMap = {};
      for (final msg in response) {
        final chatId = msg['chat_id'] as String;
        if (!chatMap.containsKey(chatId)) {
          chatMap[chatId] = msg;
        }
      }

      // Enrich with other user's profile
      final results = <Map<String, dynamic>>[];
      for (final entry in chatMap.entries) {
        final chatId = entry.key;
        final lastMsg = entry.value;

        // Extract the other user's ID from chat_id (format: id1_id2, sorted)
        final parts = chatId.split('_');
        if (parts.length < 2) continue;

        // Reconstruct both UUIDs (they may contain hyphens so we join on underscore boundaries)
        // The chat ID format is: sortedId1_sortedId2, where IDs are UUIDs
        String? otherUserId;
        // Try splitting by finding the userId in the chatId
        if (chatId.startsWith(userId)) {
          otherUserId = chatId.substring(userId.length + 1);
        } else if (chatId.endsWith(userId)) {
          otherUserId = chatId.substring(0, chatId.length - userId.length - 1);
        } else {
          continue;
        }

        // Get the other user's profile
        final otherUser = await _supabase
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

      // Sort by last message time (newest first)
      results.sort((a, b) {
        final aTime = DateTime.parse(a['last_message']['created_at']);
        final bTime = DateTime.parse(b['last_message']['created_at']);
        return bTime.compareTo(aTime);
      });

      return results;
    } catch (e) {
      debugPrint('CHAT: Error loading direct conversations: $e');
      return [];
    }
  }

  /// Soft-delete a message
  Future<void> deleteMessage(String messageId) async {
    await _supabase.from('messages').update({
      'is_deleted': true,
      'content': 'Сообщение удалено',
    }).eq('id', messageId);
  }

  /// Auto-cleanup: hard-delete community messages older than [daysToKeep] days.
  /// Called automatically when opening a community chat.
  Future<int> cleanupOldCommunityMessages(String chatId, {int daysToKeep = 3}) async {
    final cutoff = DateTime.now().subtract(Duration(days: daysToKeep));
    try {
      final deleted = await _supabase
          .from('messages')
          .delete()
          .eq('chat_id', chatId)
          .eq('chat_type', 'community')
          .lt('created_at', cutoff.toIso8601String())
          .select('id');
      debugPrint('CHAT CLEANUP: Deleted ${deleted.length} old messages from community $chatId (older than $daysToKeep days)');
      return deleted.length;
    } catch (e) {
      debugPrint('CHAT CLEANUP ERROR: $e');
      return 0;
    }
  }

  /// Clear all messages in a direct chat (hard-delete).
  Future<int> clearDirectChat(String chatId) async {
    try {
      final deleted = await _supabase
          .from('messages')
          .delete()
          .eq('chat_id', chatId)
          .eq('chat_type', 'direct')
          .select('id');
      debugPrint('CHAT CLEAR: Deleted ${deleted.length} messages from DM $chatId');
      return deleted.length;
    } catch (e) {
      debugPrint('CHAT CLEAR ERROR: $e');
      return 0;
    }
  }
}
