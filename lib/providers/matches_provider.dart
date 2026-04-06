import 'package:flutter/material.dart';
import '../models/sport_match.dart';
import '../models/enums.dart';
import '../services/supabase_service.dart';

/// Предопределённые цвета для команд
const teamColors = [
  0xFFE53935, // Красные
  0xFF1E88E5, // Синие
  0xFF43A047, // Зелёные
  0xFFFFB300, // Жёлтые
  0xFFAB47BC, // Фиолетовые
];

const teamColorNames = [
  'Красные', 'Синие', 'Зелёные', 'Жёлтые', 'Фиолетовые',
];

class MatchesProvider extends ChangeNotifier {
  final SupabaseService _db = SupabaseService();
  final List<SportMatch> _matches = [];
  final List<SportMatch> _completedEvents = []; // архив завершённых
  String? _currentCommunityId;
  dynamic _realtimeSubscription;

  List<SportMatch> get matches => _matches;
  List<SportMatch> get completedEvents => _completedEvents;

  /// Load matches from Supabase for a given community + subscribe to realtime
  Future<void> loadMatches(String communityId) async {
    _currentCommunityId = communityId;
    try {
      await _fetchMatches(communityId);
      _subscribeToRealtime(communityId);
    } catch (e) {
      debugPrint('MATCHES ERROR: Failed to load matches: $e');
    }
  }

  Future<void> _fetchMatches(String communityId) async {
    final data = await _db.getMatches(communityId);
    _matches.clear();
    _completedEvents.clear();
    for (final match in data) {
      if (match.isCompleted) {
        _completedEvents.add(match);
      } else {
        _matches.add(match);
      }
    }
    notifyListeners();
    debugPrint('MATCHES: Loaded ${_matches.length} active, ${_completedEvents.length} completed for $communityId');
  }

  /// Subscribe to Supabase Realtime — auto-refresh on any DB change
  void _subscribeToRealtime(String communityId) {
    // Cancel previous subscription if any
    _realtimeSubscription?.unsubscribe();
    _realtimeSubscription = _db.watchMatchesChannel(
      communityId,
      onChanged: () => _fetchMatches(communityId),
    );
  }

  @override
  void dispose() {
    _realtimeSubscription?.unsubscribe();
    super.dispose();
  }

  // ============================================================
  // БАЗОВЫЕ МЕТОДЫ
  // ============================================================

  SportMatch? getById(String id) =>
      _matches.where((m) => m.id == id).firstOrNull ??
      _completedEvents.where((m) => m.id == id).firstOrNull;

  List<SportMatch> getByCategory(SportCategory cat) =>
      _matches.where((m) => m.category == cat).toList();

  List<SportMatch> getByDate(DateTime date) => _matches
      .where((m) =>
          m.dateTime.year == date.year &&
          m.dateTime.month == date.month &&
          m.dateTime.day == date.day)
      .toList();

  List<SportMatch> getByCommunity(String communityId) =>
      _matches.where((m) => m.communityId == communityId).toList();

  /// Завершённые события сообщества (архив)
  List<SportMatch> getCompletedByCommunity(String communityId) =>
      _completedEvents
          .where((m) => m.communityId == communityId)
          .toList();

  // ============================================================
  // РЕГИСТРАЦИЯ
  // ============================================================

  void toggleRegistration(SportMatch match,
      {String? userId, String? userName, bool isSubscriber = false}) {
    // Use registeredPlayerIds as the source of truth, not the local isUserRegistered flag
    final isCurrentlyRegistered = userId != null && match.registeredPlayerIds.contains(userId);

    if (isCurrentlyRegistered) {
      match.currentPlayers--;
      match.isUserRegistered = false;
      if (userId != null) {
        final idx = match.registeredPlayerIds.indexOf(userId);
        if (idx != -1) {
          match.registeredPlayerIds.removeAt(idx);
          if (idx < match.registeredPlayerNames.length) {
            match.registeredPlayerNames.removeAt(idx);
          }
        }
      }
    } else {
      if (match.currentPlayers >= match.totalCapacity) return;
      match.currentPlayers++;
      match.isUserRegistered = true;
      if (userId != null &&
          !match.registeredPlayerIds.contains(userId)) {
        match.registeredPlayerIds.add(userId);
        match.registeredPlayerNames.add(userName ?? 'Игрок');
      }
    }
    // Update in DB
    _db.updateMatch(match.communityId ?? _currentCommunityId ?? '', match.id, {
      'current_players': match.currentPlayers,
      'registered_player_ids': match.registeredPlayerIds,
      'registered_player_names': match.registeredPlayerNames,
    });
    notifyListeners();
  }

  List<String> getRegisteredPlayers(String matchId) {
    final match = _matches.where((m) => m.id == matchId).firstOrNull;
    return match?.registeredPlayerIds ?? [];
  }

  bool isUserRegistered(String matchId, String userId) {
    final match = _matches.where((m) => m.id == matchId).firstOrNull;
    return match?.registeredPlayerIds.contains(userId) ?? false;
  }

  /// Add a match — saves to Supabase and adds to local list
  Future<void> addMatch(SportMatch match) async {
    final communityId = match.communityId ?? _currentCommunityId ?? '';
    try {
      // Insert into Supabase and get back the generated UUID
      final response = await _db.createMatchAndReturn(communityId, match);
      final savedMatch = SportMatch(
        id: response['id'].toString(),
        communityId: communityId,
        category: match.category,
        format: match.format,
        dateTime: match.dateTime,
        location: match.location,
        price: match.price,
        totalCapacity: match.totalCapacity,
        currentPlayers: match.currentPlayers,
        registeredPlayerIds: match.registeredPlayerIds,
        registeredPlayerNames: match.registeredPlayerNames,
      );
      _matches.add(savedMatch);
      debugPrint('MATCHES: Created match ${savedMatch.id}');
    } catch (e) {
      debugPrint('MATCHES ERROR: Failed to create match: $e');
      // Fallback: add locally
      _matches.add(match);
    }
    notifyListeners();
  }

  // ============================================================
  // УПРАВЛЕНИЕ КОМАНДАМИ
  // ============================================================

  /// Добавить команду в событие (макс 5)
  bool addEventTeam(String matchId) {
    final match = getById(matchId);
    if (match == null || match.eventTeams.length >= 5) return false;

    final idx = match.eventTeams.length;
    match.eventTeams.add(EventTeam(
      id: 'team_${DateTime.now().millisecondsSinceEpoch}_$idx',
      name: teamColorNames[idx],
      colorValue: teamColors[idx],
    ));
    _syncEventTeams(match);
    notifyListeners();
    return true;
  }

  /// Удалить команду (убирает игроков обратно в нераспределённые)
  void removeEventTeam(String matchId, String teamId) {
    final match = getById(matchId);
    if (match == null) return;

    // Удаляем связанные матчи
    final teamIdx =
        match.eventTeams.indexWhere((t) => t.id == teamId);
    if (teamIdx == -1) return;
    match.innerMatches.removeWhere(
        (m) => m.team1Index == teamIdx || m.team2Index == teamIdx);
    // При удалении команды безопаснее удалить все матчи (индексы сбиваются)
    match.innerMatches.clear();
    match.eventTeams.removeAt(teamIdx);
    _syncEventTeams(match);
    _syncInnerMatches(match);
    notifyListeners();
  }

  /// Назначить игрока в команду
  void assignPlayerToTeam(
      String matchId, String teamId, String playerId, String playerName) {
    final match = getById(matchId);
    if (match == null) return;

    // Сначала убираем из других команд
    for (final team in match.eventTeams) {
      team.removePlayer(playerId);
    }
    // Добавляем в нужную
    final team =
        match.eventTeams.where((t) => t.id == teamId).firstOrNull;
    team?.addPlayer(playerId, playerName);
    _syncEventTeams(match);
    notifyListeners();
  }

  /// Убрать игрока из команды
  void removePlayerFromTeam(
      String matchId, String teamId, String playerId) {
    final match = getById(matchId);
    if (match == null) return;
    final team =
        match.eventTeams.where((t) => t.id == teamId).firstOrNull;
    team?.removePlayer(playerId);
    _syncEventTeams(match);
    notifyListeners();
  }

  /// Авто-разделение: равномерно распределить всех по командам
  void autoDistributePlayers(String matchId) {
    final match = getById(matchId);
    if (match == null || match.eventTeams.isEmpty) return;

    // Очищаем все команды
    for (final team in match.eventTeams) {
      team.playerIds.clear();
      team.playerNames.clear();
    }

    // Распределяем round-robin
    for (int i = 0; i < match.registeredPlayerIds.length; i++) {
      final teamIdx = i % match.eventTeams.length;
      final name = i < match.registeredPlayerNames.length
          ? match.registeredPlayerNames[i]
          : 'Игрок';
      match.eventTeams[teamIdx]
          .addPlayer(match.registeredPlayerIds[i], name);
    }
    _syncEventTeams(match);
    notifyListeners();
  }

  // ============================================================
  // УПРАВЛЕНИЕ МАТЧАМИ (InnerMatch)
  // ============================================================

  /// Добавить матч между двумя командами
  bool addInnerMatch(String matchId, int team1Index, int team2Index) {
    final match = getById(matchId);
    if (match == null) return false;
    if (team1Index == team2Index) return false;
    if (match.innerMatches.length >= 45) return false;

    match.innerMatches.add(InnerMatch(
      id: 'im_${DateTime.now().millisecondsSinceEpoch}',
      team1Index: team1Index,
      team2Index: team2Index,
    ));
    _syncInnerMatches(match);
    notifyListeners();
    return true;
  }

  /// Обновить счёт матча
  void updateInnerMatchScore(
      String matchId, String innerMatchId, int score1, int score2) {
    final match = getById(matchId);
    if (match == null) return;
    final im = match.innerMatches
        .where((m) => m.id == innerMatchId)
        .firstOrNull;
    if (im == null) return;
    im.team1Score = score1;
    im.team2Score = score2;
    _syncInnerMatches(match);
    notifyListeners();
  }

  /// Завершить матч (зафиксировать счёт)
  void completeInnerMatch(String matchId, String innerMatchId) {
    final match = getById(matchId);
    if (match == null) return;
    final im = match.innerMatches
        .where((m) => m.id == innerMatchId)
        .firstOrNull;
    if (im == null) return;
    im.isCompleted = true;
    _syncInnerMatches(match);
    notifyListeners();
  }

  /// Удалить матч
  void removeInnerMatch(String matchId, String innerMatchId) {
    final match = getById(matchId);
    if (match == null) return;
    match.innerMatches.removeWhere((m) => m.id == innerMatchId);
    _syncInnerMatches(match);
    notifyListeners();
  }

  // ============================================================
  // СИНХРОНИЗАЦИЯ С БД
  // ============================================================

  /// Сохранить event_teams в БД
  void _syncEventTeams(SportMatch match) {
    final communityId = match.communityId ?? _currentCommunityId ?? '';
    _db.updateMatch(communityId, match.id, {
      'eventTeams': match.eventTeams.map((t) => t.toJson()).toList(),
    });
  }

  /// Сохранить inner_matches в БД
  void _syncInnerMatches(SportMatch match) {
    final communityId = match.communityId ?? _currentCommunityId ?? '';
    _db.updateMatch(communityId, match.id, {
      'innerMatches': match.innerMatches.map((m) => m.toJson()).toList(),
    });
  }

  // ============================================================
  // ЗАВЕРШЕНИЕ СОБЫТИЯ
  // ============================================================

  /// Завершить событие → перенести в архив сообщества
  void completeEvent(String matchId) {
    final match = getById(matchId);
    if (match == null) return;
    match.isCompleted = true;
    _completedEvents.add(match);
    _matches.remove(match);
    // Update in DB
    _db.updateMatch(match.communityId ?? _currentCommunityId ?? '', match.id, {
      'is_completed': true,
    });
    notifyListeners();
  }
}
