import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:new_idea_works/utils/app_logger.dart';
import 'base_repository.dart';

/// Repository for live match events and realtime.
class MatchEventsRepository extends BaseRepository {
  static final MatchEventsRepository _instance = MatchEventsRepository._internal();
  factory MatchEventsRepository() => _instance;
  MatchEventsRepository._internal();

  Future<void> addMatchEvent(Map<String, dynamic> eventData) async {
    await supabase.from('match_events').insert(eventData);
  }

  Future<void> deleteMatchEvent(String eventId) async {
    await supabase.from('match_events').delete().eq('id', eventId);
  }

  Future<List<Map<String, dynamic>>> getMatchEvents(String matchId) async {
    final data = await supabase
        .from('match_events')
        .select()
        .eq('match_id', matchId)
        .order('created_at', ascending: true);
    return List<Map<String, dynamic>>.from(data);
  }

  dynamic watchMatchEventsChannel(String matchId, {required VoidCallback onChanged}) {
    return supabase
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
            appLog('REALTIME: match_events changed — ${payload.eventType}');
            onChanged();
          },
        )
        .subscribe();
  }
}
