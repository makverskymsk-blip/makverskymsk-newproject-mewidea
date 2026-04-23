import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:new_idea_works/utils/app_logger.dart';
import '../models/community.dart';
import '../models/enums.dart';
import 'base_repository.dart';

/// Repository for communities, invites, join requests, realtime.
class CommunityRepository extends BaseRepository {
  static final CommunityRepository _instance = CommunityRepository._internal();
  factory CommunityRepository() => _instance;
  CommunityRepository._internal();

  // ───── Communities CRUD ─────

  Future<void> createCommunity(Community community) async {
    await supabase.from('communities').insert({
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

  Future<Map<String, dynamic>> createCommunityAndReturn({
    required String name,
    required SportCategory sport,
    required String inviteCode,
    required String ownerId,
    double monthlyRent = 100000,
    double singleGamePrice = 1200,
  }) async {
    final response = await supabase.from('communities').insert({
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
    final response = await supabase
        .from('communities')
        .select()
        .eq('invite_code', code.toUpperCase())
        .maybeSingle();

    if (response == null) return null;
    return communityFromMap(response);
  }

  Future<List<Community>> getUserCommunities(List<String> communityIds) async {
    if (communityIds.isEmpty) return [];
    final response = await supabase
        .from('communities')
        .select()
        .inFilter('id', communityIds);

    return (response as List).map((d) => communityFromMap(d)).toList();
  }

  /// Atomic join via RPC
  Future<void> joinCommunity(String communityId, String userId) async {
    await supabase.rpc('join_community', params: {
      'p_community_id': communityId,
      'p_user_id': userId,
    });
  }

  /// Atomic leave via RPC
  Future<void> leaveCommunity(String communityId, String userId) async {
    await supabase.rpc('leave_community', params: {
      'p_community_id': communityId,
      'p_user_id': userId,
    });
  }

  Future<void> updateCommunityAdmins(
    String communityId,
    List<String> adminIds,
    List<String> memberIds,
  ) async {
    await supabase.from('communities').update({
      'admin_ids': adminIds,
      'member_ids': memberIds,
    }).eq('id', communityId);
  }

  Future<void> updateCommunityBank(
      String communityId, double newBalance) async {
    await supabase.from('communities').update({
      'bank_balance': newBalance,
    }).eq('id', communityId);
  }

  /// Get ALL communities for the directory
  Future<List<Community>> getAllCommunities() async {
    final response = await supabase
        .from('communities')
        .select()
        .order('name');
    return (response as List).map((d) => communityFromMap(d)).toList();
  }

  // ───── Join Requests ─────

  Future<void> createJoinRequest(String communityId, String userId) async {
    await supabase.from('join_requests').upsert({
      'user_id': userId,
      'community_id': communityId,
      'status': 'pending',
    }, onConflict: 'user_id,community_id');
  }

  Future<List<Map<String, dynamic>>> getJoinRequestsForCommunity(String communityId) async {
    final response = await supabase
        .from('join_requests')
        .select()
        .eq('community_id', communityId)
        .eq('status', 'pending')
        .order('created_at');
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getUserJoinRequests(String userId) async {
    final response = await supabase
        .from('join_requests')
        .select()
        .eq('user_id', userId)
        .order('created_at');
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> updateJoinRequestStatus(String requestId, String status) async {
    await supabase.from('join_requests').update({
      'status': status,
    }).eq('id', requestId);
  }

  Future<void> deleteJoinRequest(String requestId) async {
    await supabase.from('join_requests').delete().eq('id', requestId);
  }

  Future<void> adminAcceptJoinRequest(String requestId, String userId, String communityId) async {
    await supabase.rpc('admin_accept_join_request', params: {
      'p_request_id': requestId,
      'p_user_id': userId,
      'p_community_id': communityId,
    });
  }

  // ───── Realtime ─────

  dynamic watchCommunityChannel(String communityId, {required VoidCallback onChanged}) {
    final channel = supabase.channel('community_$communityId')
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
          appLog('REALTIME: community changed — ${payload.eventType}');
          onChanged();
        },
      )
      .subscribe();
    return channel;
  }

  // ───── Helpers ─────

  Community communityFromMap(Map<String, dynamic> d) {
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
}
