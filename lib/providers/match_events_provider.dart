import 'package:new_idea_works/utils/app_logger.dart';
import 'package:flutter/material.dart';
import '../models/match_event.dart';
import '../repositories/match_events_repository.dart';

class MatchEventsProvider extends ChangeNotifier {
  final MatchEventsRepository _db = MatchEventsRepository();
  final List<MatchEvent> _events = [];
  String? _currentMatchId; // ignore: unused_field
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

      // Universal scoring: goal, own_goal, ace (tennis), kill (esports)
      if (e.eventType == MatchEventType.goal ||
          e.eventType == MatchEventType.ownGoal ||
          e.eventType == MatchEventType.ace ||
          e.eventType == MatchEventType.kill) {
        scores[e.teamIndex!] = (scores[e.teamIndex!] ?? 0) + 1;
      }
    }
    return scores;
  }

  /// Aggregate stats for a player across all events in this match
  Map<String, int> getPlayerEventStats(String playerId) {
    final counts = <String, int>{};
    for (final e in _events) {
      if (e.playerId != playerId) continue;
      final key = e.eventType.value;
      counts[key] = (counts[key] ?? 0) + 1;
    }
    // Always include legacy keys for backward compat
    return {
      'goals': (counts['goal'] ?? 0) + (counts['kill'] ?? 0) + (counts['ace'] ?? 0),
      'assists': (counts['assist'] ?? 0) + (counts['winner'] ?? 0),
      'saves': (counts['save'] ?? 0) + (counts['block'] ?? 0),
      'fouls': (counts['foul'] ?? 0) + (counts['penalty_min'] ?? 0) + (counts['double_fault'] ?? 0),
      'ownGoals': counts['own_goal'] ?? 0,
      // Sport-specific raw counts
      ...counts,
    };
  }

  /// Stats for a player in a specific inner match only
  Map<String, int> getPlayerStatsForInnerMatch(String playerId, String innerMatchId) {
    final counts = <String, int>{};
    for (final e in _events) {
      if (e.playerId != playerId || e.innerMatchId != innerMatchId) continue;
      final key = e.eventType.value;
      counts[key] = (counts[key] ?? 0) + 1;
    }
    return {
      'goals': (counts['goal'] ?? 0) + (counts['kill'] ?? 0) + (counts['ace'] ?? 0),
      'assists': (counts['assist'] ?? 0) + (counts['winner'] ?? 0),
      'saves': (counts['save'] ?? 0) + (counts['block'] ?? 0),
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
      appLog('EVENTS ERROR: $e');
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
      appLog('EVENTS FETCH ERROR: $e');
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
      appLog('EVENTS ADD ERROR: $e');
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
      appLog('EVENTS DELETE ERROR: $e');
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
