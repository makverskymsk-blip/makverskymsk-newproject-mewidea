import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

/// Manages follow/friends relationships.
/// - Open profiles → instant follow (status='accepted')
/// - Closed profiles → follow request (status='pending'), owner must accept
class FriendsProvider extends ChangeNotifier {
  final SupabaseService _db = SupabaseService();

  // Cached data
  List<FollowEntry> _followers = [];
  List<FollowEntry> _following = [];
  List<FollowEntry> _pendingRequests = [];
  int _followersCount = 0;
  int _followingCount = 0;
  int _pendingCount = 0;
  bool _isLoading = false;

  List<FollowEntry> get followers => _followers;
  List<FollowEntry> get following => _following;
  List<FollowEntry> get pendingRequests => _pendingRequests;
  int get followersCount => _followersCount;
  int get followingCount => _followingCount;
  int get pendingCount => _pendingCount;
  bool get isLoading => _isLoading;

  /// Mutual friends = intersection of followers and following
  List<FollowEntry> get mutualFriends {
    final followingIds = _following.map((f) => f.userId).toSet();
    return _followers.where((f) => followingIds.contains(f.userId)).toList();
  }

  /// Load all data for current user
  Future<void> loadAll(String myUserId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await Future.wait([
        _loadFollowers(myUserId),
        _loadFollowing(myUserId),
        _loadPendingRequests(myUserId),
        _loadCounts(myUserId),
      ]);
    } catch (e) {
      debugPrint('FRIENDS: Error loading: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Load just counts (lightweight, for profile header)
  Future<void> loadCounts(String myUserId) async {
    await _loadCounts(myUserId);
    notifyListeners();
  }

  // ═══ Actions ═══

  /// Follow a user (checks if target is public/closed)
  Future<void> followUser(String myUserId, String targetUserId) async {
    try {
      final isPublic = await _db.isUserPublic(targetUserId);
      await _db.followUser(myUserId, targetUserId, targetIsPublic: isPublic);
      debugPrint('FRIENDS: followed $targetUserId (public=$isPublic)');
      await loadAll(myUserId);
    } catch (e) {
      debugPrint('FRIENDS: follow error: $e');
    }
  }

  /// Unfollow / cancel request
  Future<void> unfollowUser(String myUserId, String targetUserId) async {
    try {
      await _db.unfollowUser(myUserId, targetUserId);
      debugPrint('FRIENDS: unfollowed $targetUserId');
      await loadAll(myUserId);
    } catch (e) {
      debugPrint('FRIENDS: unfollow error: $e');
    }
  }

  /// Accept incoming follow request
  Future<void> acceptRequest(String myUserId, String followId) async {
    try {
      await _db.acceptFollowRequest(followId);
      debugPrint('FRIENDS: accepted request $followId');
      await loadAll(myUserId);
    } catch (e) {
      debugPrint('FRIENDS: accept error: $e');
    }
  }

  /// Reject incoming follow request
  Future<void> rejectRequest(String myUserId, String followId) async {
    try {
      await _db.rejectFollowRequest(followId);
      debugPrint('FRIENDS: rejected request $followId');
      await loadAll(myUserId);
    } catch (e) {
      debugPrint('FRIENDS: reject error: $e');
    }
  }

  /// Check my relationship with a specific user
  /// Returns: null (no relation), 'pending', 'accepted'
  Future<String?> getMyFollowStatus(String myUserId, String targetUserId) async {
    return await _db.getFollowStatus(myUserId, targetUserId);
  }

  /// Check if we're mutual followers
  Future<bool> areFriends(String myUserId, String targetUserId) async {
    return await _db.areMutualFollowers(myUserId, targetUserId);
  }

  // ═══ Private loaders ═══

  Future<void> _loadFollowers(String userId) async {
    try {
      final raw = await _db.getFollowers(userId);
      _followers = raw.map((d) {
        final user = d['follower'] as Map<String, dynamic>?;
        return FollowEntry(
          followId: d['id'].toString(),
          userId: user?['id'] ?? d['follower_id'] ?? '',
          name: user?['name'] ?? '',
          avatarUrl: user?['avatar_url'],
          position: user?['position'],
        );
      }).toList();
    } catch (e) {
      debugPrint('FRIENDS: _loadFollowers error: $e');
    }
  }

  Future<void> _loadFollowing(String userId) async {
    try {
      final raw = await _db.getFollowing(userId);
      _following = raw.map((d) {
        final user = d['following'] as Map<String, dynamic>?;
        return FollowEntry(
          followId: d['id'].toString(),
          userId: user?['id'] ?? d['following_id'] ?? '',
          name: user?['name'] ?? '',
          avatarUrl: user?['avatar_url'],
          position: user?['position'],
        );
      }).toList();
    } catch (e) {
      debugPrint('FRIENDS: _loadFollowing error: $e');
    }
  }

  Future<void> _loadPendingRequests(String userId) async {
    try {
      final raw = await _db.getPendingFollowRequests(userId);
      _pendingRequests = raw.map((d) {
        final user = d['follower'] as Map<String, dynamic>?;
        return FollowEntry(
          followId: d['id'].toString(),
          userId: user?['id'] ?? d['follower_id'] ?? '',
          name: user?['name'] ?? '',
          avatarUrl: user?['avatar_url'],
          position: user?['position'],
        );
      }).toList();
    } catch (e) {
      debugPrint('FRIENDS: _loadPendingRequests error: $e');
    }
  }

  Future<void> _loadCounts(String userId) async {
    try {
      final counts = await _db.getFollowCounts(userId);
      _followersCount = counts['followers'] ?? 0;
      _followingCount = counts['following'] ?? 0;
      _pendingCount = counts['pending'] ?? 0;
    } catch (e) {
      debugPrint('FRIENDS: _loadCounts error: $e');
    }
  }
}

/// Lightweight struct for displaying a follower/following entry
class FollowEntry {
  final String followId;
  final String userId;
  final String name;
  final String? avatarUrl;
  final String? position;

  FollowEntry({
    required this.followId,
    required this.userId,
    required this.name,
    this.avatarUrl,
    this.position,
  });
}
