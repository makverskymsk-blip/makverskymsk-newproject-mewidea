import 'base_repository.dart';

/// Repository for follows, search, public profiles.
class SocialRepository extends BaseRepository {
  static final SocialRepository _instance = SocialRepository._internal();
  factory SocialRepository() => _instance;
  SocialRepository._internal();

  // ───── Follow System ─────

  Future<void> followUser(String followerId, String followingId, {required bool targetIsPublic}) async {
    await supabase.from('follows').upsert({
      'follower_id': followerId,
      'following_id': followingId,
      'status': targetIsPublic ? 'accepted' : 'pending',
    }, onConflict: 'follower_id,following_id');
  }

  Future<void> unfollowUser(String followerId, String followingId) async {
    await supabase.from('follows')
        .delete()
        .eq('follower_id', followerId)
        .eq('following_id', followingId);
  }

  Future<void> acceptFollowRequest(String followId) async {
    await supabase.from('follows').update({
      'status': 'accepted',
    }).eq('id', followId);
  }

  Future<void> rejectFollowRequest(String followId) async {
    await supabase.from('follows').delete().eq('id', followId);
  }

  /// Get my followers (accepted only), enriched with user data
  Future<List<Map<String, dynamic>>> getFollowers(String userId) async {
    final response = await supabase
        .from('follows')
        .select()
        .eq('following_id', userId)
        .eq('status', 'accepted')
        .order('created_at', ascending: false);
    final results = <Map<String, dynamic>>[];
    for (final row in response) {
      final userResp = await supabase
          .from('users')
          .select('id, name, avatar_url, position, sport_positions, is_public_profile')
          .eq('id', row['follower_id'])
          .maybeSingle();
      results.add({...row, 'follower': userResp});
    }
    return results;
  }

  /// Get people I'm following (accepted only)
  Future<List<Map<String, dynamic>>> getFollowing(String userId) async {
    final response = await supabase
        .from('follows')
        .select()
        .eq('follower_id', userId)
        .eq('status', 'accepted')
        .order('created_at', ascending: false);
    final results = <Map<String, dynamic>>[];
    for (final row in response) {
      final userResp = await supabase
          .from('users')
          .select('id, name, avatar_url, position, sport_positions, is_public_profile')
          .eq('id', row['following_id'])
          .maybeSingle();
      results.add({...row, 'following': userResp});
    }
    return results;
  }

  /// Get pending follow requests to me
  Future<List<Map<String, dynamic>>> getPendingFollowRequests(String userId) async {
    final response = await supabase
        .from('follows')
        .select()
        .eq('following_id', userId)
        .eq('status', 'pending')
        .order('created_at', ascending: false);
    final results = <Map<String, dynamic>>[];
    for (final row in response) {
      final userResp = await supabase
          .from('users')
          .select('id, name, avatar_url, position')
          .eq('id', row['follower_id'])
          .maybeSingle();
      results.add({...row, 'follower': userResp});
    }
    return results;
  }

  Future<Map<String, int>> getFollowCounts(String userId) async {
    final followers = await supabase
        .from('follows')
        .select()
        .eq('following_id', userId)
        .eq('status', 'accepted');
    final following = await supabase
        .from('follows')
        .select()
        .eq('follower_id', userId)
        .eq('status', 'accepted');
    final pending = await supabase
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

  /// Returns: null, 'pending', 'accepted'
  Future<String?> getFollowStatus(String followerId, String followingId) async {
    final response = await supabase
        .from('follows')
        .select('status')
        .eq('follower_id', followerId)
        .eq('following_id', followingId)
        .maybeSingle();
    return response?['status'];
  }

  Future<bool> areMutualFollowers(String userId1, String userId2) async {
    final f1 = await getFollowStatus(userId1, userId2);
    final f2 = await getFollowStatus(userId2, userId1);
    return f1 == 'accepted' && f2 == 'accepted';
  }

  Future<bool> isUserPublic(String userId) async {
    final response = await supabase
        .from('users')
        .select('is_public_profile')
        .eq('id', userId)
        .maybeSingle();
    return response?['is_public_profile'] ?? true;
  }

  /// Search users by name
  Future<List<Map<String, dynamic>>> searchUsers(String query, {int limit = 20}) async {
    if (query.trim().isEmpty) return [];
    final response = await supabase
        .from('users')
        .select('id, name, avatar_url, position, is_public_profile')
        .ilike('name', '%${query.trim()}%')
        .limit(limit);
    return List<Map<String, dynamic>>.from(response);
  }
}
