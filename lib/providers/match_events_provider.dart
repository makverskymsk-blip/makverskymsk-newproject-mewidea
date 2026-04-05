import 'package:flutter/material.dart';
import '../models/match_event.dart';
import '../services/supabase_service.dart';

class MatchEventsProvider extends ChangeNotifier {
  final SupabaseService _db = SupabaseService();
  final List<MatchEvent> _events = [];
  String? _currentMatchId;
  dynamic _realtimeSubscription;

  List<MatchEvent> get events => _events;

  /// All events for a specific inner match
  List<MatchEvent> eventsForInnerMatch(String innerMatchId) =>
      _events.where((e) => e.innerMatchId == innerMatchId).toList();

  /// Calculate score for a specific inner match from events
  Map<int, int> getScoreForInnerMatch(String innerMatchId) {
    final scores = <int, int>{};
    for (final e in _events) {
      if (e.innerMatchId != innerMatchId) continue;
      if (e.teamIndex == null) continue;

      if (e.eventType == MatchEventType.goal) {
        scores[e.teamIndex!] = (scores[e.teamIndex!] ?? 0) + 1;
      } else if (e.eventType == MatchEventType.ownGoal) {
        // Own goal counts for the opposite team — we need to figure out
        // which teams are in this inner match. For simplicity, we add +1
        // to *all other* team indices present in this match.
        // In practice with 2 teams, we just don't add to own team.
        // We'll handle this in the UI by passing the opponent's teamIndex.
        scores[e.teamIndex!] = (scores[e.teamIndex!] ?? 0) + 1;
      }
    }
    return scores;
  }

  /// Aggregate stats for a player across all events in this match
  Map<String, int> getPlayerEventStats(String playerId) {
    int goals = 0, assists = 0, saves = 0, fouls = 0, ownGoals = 0;
    for (final e in _events) {
      if (e.playerId != playerId) continue;
      switch (e.eventType) {
        case MatchEventType.goal:
          goals++;
        case MatchEventType.assist:
          assists++;
        case MatchEventType.save:
          saves++;
        case MatchEventType.foul:
          fouls++;
        case MatchEventType.ownGoal:
          ownGoals++;
      }
    }
    return {
      'goals': goals,
      'assists': assists,
      'saves': saves,
      'fouls': fouls,
      'ownGoals': ownGoals,
    };
  }

  /// Load events from DB and subscribe to realtime
  Future<void> loadEvents(String matchId) async {
    _currentMatchId = matchId;
    try {
      final data = await _db.getMatchEvents(matchId);
      _events.clear();
      for (final json in data) {
        _events.add(MatchEvent.fromJson(json));
      }
      notifyListeners();
      _subscribeToRealtime(matchId);
    } catch (e) {
      debugPrint('EVENTS ERROR: $e');
    }
  }

  void _subscribeToRealtime(String matchId) {
    _realtimeSubscription?.unsubscribe();
    _realtimeSubscription = _db.watchMatchEventsChannel(
      matchId,
      onChanged: () => _fetchEvents(matchId),
    );
  }

  Future<void> _fetchEvents(String matchId) async {
    try {
      final data = await _db.getMatchEvents(matchId);
      _events.clear();
      for (final json in data) {
        _events.add(MatchEvent.fromJson(json));
      }
      notifyListeners();
    } catch (e) {
      debugPrint('EVENTS FETCH ERROR: $e');
    }
  }

  /// Add a new event
  Future<void> addEvent(MatchEvent event) async {
    try {
      await _db.addMatchEvent(event.toJson());
      // Realtime will refresh, but add locally for instant feedback
      _events.add(event);
      notifyListeners();
    } catch (e) {
      debugPrint('EVENTS ADD ERROR: $e');
      rethrow;
    }
  }

  /// Delete an event (own or admin)
  Future<void> deleteEvent(String eventId) async {
    try {
      await _db.deleteMatchEvent(eventId);
      _events.removeWhere((e) => e.id == eventId);
      notifyListeners();
    } catch (e) {
      debugPrint('EVENTS DELETE ERROR: $e');
      rethrow;
    }
  }

  /// Cleanup
  void clearEvents() {
    _realtimeSubscription?.unsubscribe();
    _events.clear();
    _currentMatchId = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _realtimeSubscription?.unsubscribe();
    super.dispose();
  }
}
