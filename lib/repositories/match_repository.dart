import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:new_idea_works/utils/app_logger.dart';
import '../models/enums.dart';
import '../models/sport_match.dart';
import 'base_repository.dart';

/// Repository for matches CRUD, realtime, registration.
class MatchRepository extends BaseRepository {
  static final MatchRepository _instance = MatchRepository._internal();
  factory MatchRepository() => _instance;
  MatchRepository._internal();

  // ───── Matches CRUD ─────

  Future<void> createMatch(String communityId, SportMatch match) async {
    await supabase.from('matches').insert({
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

  Future<Map<String, dynamic>> createMatchAndReturn(
      String? communityId, SportMatch match) async {
    final response = await supabase.from('matches').insert({
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

  Future<List<SportMatch>> getMatches(String communityId) async {
    final response = await supabase
        .from('matches')
        .select()
        .eq('community_id', communityId)
        .order('date_time', ascending: true);
    return (response as List).map((d) => parseMatch(d)).toList();
  }

  Future<List<SportMatch>> getAllActiveMatches() async {
    final response = await supabase
        .from('matches')
        .select()
        .eq('is_completed', false)
        .order('date_time', ascending: true);
    return (response as List).map((d) => parseMatch(d)).toList();
  }

  Future<List<SportMatch>> getAllMatches() async {
    final response = await supabase
        .from('matches')
        .select()
        .order('date_time', ascending: true);
    return (response as List).map((d) => parseMatch(d)).toList();
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

    await supabase.from('matches').update(mappedData).eq('id', matchId);
  }

  /// RPC: Add amount to user's balance atomically.
  Future<void> addToUserBalance(String userId, double amount, {String? communityId}) async {
    await supabase.rpc('add_to_user_balance', params: {
      'target_user_id': userId,
      'amount': amount,
      'p_community_id': communityId,
    });
  }

  // ───── Realtime ─────

  Stream<List<SportMatch>> watchMatches(String communityId) {
    return supabase
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

  dynamic watchAllMatchesChannel({required VoidCallback onChanged}) {
    final channel = supabase.channel('matches_global')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'matches',
        callback: (payload) {
          appLog('REALTIME: matches changed — ${payload.eventType}');
          onChanged();
        },
      )
      .subscribe();
    return channel;
  }

  dynamic watchMatchesChannel(String communityId, {required VoidCallback onChanged}) {
    final channel = supabase.channel('matches_$communityId')
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
          appLog('REALTIME: matches changed — ${payload.eventType}');
          onChanged();
        },
      )
      .subscribe();
    return channel;
  }

  // ───── Helpers ─────

  SportMatch parseMatch(Map<String, dynamic> d) {
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

  List<EventTeam> _parseEventTeams(dynamic json) {
    if (json == null) return [];
    try {
      final list = json is List ? json : [];
      return list.map((e) => EventTeam.fromJson(Map<String, dynamic>.from(e))).toList();
    } catch (e) {
      appLog('PARSE: Failed to parse event_teams: $e');
      return [];
    }
  }

  List<InnerMatch> _parseInnerMatches(dynamic json) {
    if (json == null) return [];
    try {
      final list = json is List ? json : [];
      return list.map((e) => InnerMatch.fromJson(Map<String, dynamic>.from(e))).toList();
    } catch (e) {
      appLog('PARSE: Failed to parse inner_matches: $e');
      return [];
    }
  }
}
