import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:new_idea_works/utils/app_logger.dart';
import '../models/user_profile.dart';
import 'base_repository.dart';

/// Repository for user CRUD, avatars, balance operations.
class UserRepository extends BaseRepository {
  static final UserRepository _instance = UserRepository._internal();
  factory UserRepository() => _instance;
  UserRepository._internal();

  // ───── Avatar Upload ─────

  /// Upload avatar image and return public URL
  Future<String?> uploadAvatar(String userId, Uint8List bytes, String ext) async {
    try {
      final path = 'avatars/$userId.$ext';
      await supabase.storage.from('avatars').uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(
          contentType: 'image/$ext',
          upsert: true,
        ),
      );
      final url = supabase.storage.from('avatars').getPublicUrl(path);
      final publicUrl = '$url?t=${DateTime.now().millisecondsSinceEpoch}';
      appLog('AVATAR: Uploaded to $publicUrl');
      return publicUrl;
    } catch (e) {
      appLog('AVATAR ERROR: $e');
      return null;
    }
  }

  /// Upload community logo and return public URL
  Future<String?> uploadCommunityLogo(String communityId, Uint8List bytes, String ext) async {
    try {
      final path = 'community_logos/$communityId.$ext';
      await supabase.storage.from('avatars').uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(
          contentType: 'image/$ext',
          upsert: true,
        ),
      );
      final url = supabase.storage.from('avatars').getPublicUrl(path);
      final publicUrl = '$url?t=${DateTime.now().millisecondsSinceEpoch}';
      appLog('LOGO: Uploaded to $publicUrl');
      return publicUrl;
    } catch (e) {
      appLog('LOGO ERROR: $e');
      return null;
    }
  }

  Future<void> updateCommunityLogoUrl(String communityId, String logoUrl) async {
    await supabase.from('communities').update({
      'logo_url': logoUrl,
    }).eq('id', communityId);
  }

  // ───── Users CRUD ─────

  Future<void> createUser(UserProfile user) async {
    await supabase.from('users').insert({
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
    final response = await supabase
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

    await supabase.from('users').update(mappedData).eq('id', uid);
  }

  /// Update user balance via RPC (atomic).
  Future<void> updateUserBalance(String uid, double amount, {String? communityId}) async {
    try {
      appLog('BALANCE: calling RPC for $uid amount=$amount communityId=$communityId');
      await supabase.rpc('increment_user_balance', params: {
        'user_id_param': uid,
        'amount_param': amount,
        'p_community_id': communityId,
      });
      appLog('BALANCE: RPC success for $uid');
    } catch (e) {
      appLog('BALANCE: RPC FAILED for $uid: $e');
      rethrow;
    }
  }

  /// Get list of users by IDs
  Future<List<UserProfile>> getUsersByIds(List<String> userIds) async {
    if (userIds.isEmpty) return [];
    final response = await supabase
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

  /// Subscribe to Realtime changes on a specific user row
  dynamic watchUserChannel(String userId, {required VoidCallback onChanged}) {
    final channel = supabase.channel('user_$userId')
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
          appLog('REALTIME: user profile changed — ${payload.eventType}');
          onChanged();
        },
      )
      .subscribe();
    return channel;
  }
}
