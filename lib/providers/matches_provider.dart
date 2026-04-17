import 'package:flutter/material.dart';
import '../models/sport_match.dart';
import '../models/enums.dart';
import '../models/app_notification.dart';
import '../services/supabase_service.dart';
import 'notification_provider.dart';

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
  List<String> _userCommunityIds = [];
  dynamic _realtimeSubscription;
  NotificationProvider? _notifProv;

  void setNotificationProvider(NotificationProvider prov) {
    _notifProv = prov;
  }

  List<SportMatch> get matches => _matches;
  List<SportMatch> get completedEvents => _completedEvents;

  /// Load matches: community events only for user's communities + personal events for all
  Future<void> loadMatches([String? communityId, List<String>? userCommunityIds]) async {
    _currentCommunityId = communityId;
    _userCommunityIds = userCommunityIds ?? (communityId != null ? [communityId] : []);
    try {
      await _fetchAllMatches();
      _subscribeToGlobalRealtime();
    } catch (e) {
      debugPrint('MATCHES ERROR: Failed to load matches: $e');
    }
  }

  Future<void> _fetchAllMatches() async {
    final data = await _db.getAllMatches();
    _matches.clear();
    _completedEvents.clear();
    int skipped = 0;
    for (final match in data) {
      // Filter: show only personal events (no community) + user's own community events
      final cid = match.communityId;
      final isPersonal = cid == null || cid.isEmpty || cid == 'null';
      final isOwnCommunity = !isPersonal && _userCommunityIds.contains(cid);
      if (!isPersonal && !isOwnCommunity) {
        skipped++;
        if (skipped <= 3) {
          debugPrint('MATCHES SKIP: id=${match.id} communityId="$cid" isPersonal=$isPersonal isOwn=$isOwnCommunity');
        }
        continue; // skip other communities' events
      }

      if (match.isCompleted) {
        _completedEvents.add(match);
      } else {
        _matches.add(match);
      }
    }
    notifyListeners();
    debugPrint('MATCHES: Fetched ${data.length} total, kept ${_matches.length} active + ${_completedEvents.length} completed, skipped $skipped (userCommunities=$_userCommunityIds)');
  }

  /// Subscribe to Supabase Realtime — auto-refresh on any DB change (all matches)
  void _subscribeToGlobalRealtime() {
    _realtimeSubscription?.unsubscribe();
    _realtimeSubscription = _db.watchAllMatchesChannel(
      onChanged: () => _fetchAllMatches(),
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

  /// Returns true if registration was toggled successfully
  Future<bool> toggleRegistration(SportMatch match,
      {String? userId, String? userName, bool isSubscriber = false}) async {
    // Use registeredPlayerIds as the source of truth, not the local isUserRegistered flag
    final isCurrentlyRegistered = userId != null && match.registeredPlayerIds.contains(userId);

    // Save snapshot for rollback
    final prevPlayers = match.currentPlayers;
    final prevRegistered = match.isUserRegistered;
    final prevIds = List<String>.from(match.registeredPlayerIds);
    final prevNames = List<String>.from(match.registeredPlayerNames);

    if (isCurrentlyRegistered) {
      match.currentPlayers--;
      match.isUserRegistered = false;
      if (userId != null) { // ignore: unnecessary_null_comparison
        final idx = match.registeredPlayerIds.indexOf(userId);
        if (idx != -1) {
          match.registeredPlayerIds.removeAt(idx);
          if (idx < match.registeredPlayerNames.length) {
            match.registeredPlayerNames.removeAt(idx);
          }
        }
      }
    } else {
      if (match.currentPlayers >= match.totalCapacity) return false;
      match.currentPlayers++;
      match.isUserRegistered = true;
      if (userId != null &&
          !match.registeredPlayerIds.contains(userId)) {
        match.registeredPlayerIds.add(userId);
        match.registeredPlayerNames.add(userName ?? 'Игрок');
      }
    }

    // Update in DB
    try {
      await _db.updateMatch(match.communityId ?? _currentCommunityId ?? '', match.id, {
        'current_players': match.currentPlayers,
        'registered_player_ids': match.registeredPlayerIds,
        'registered_player_names': match.registeredPlayerNames,
      });
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('MATCHES ERROR: toggleRegistration failed: $e');
      // Rollback local state
      match.currentPlayers = prevPlayers;
      match.isUserRegistered = prevRegistered;
      match.registeredPlayerIds
        ..clear()
        ..addAll(prevIds);
      match.registeredPlayerNames
        ..clear()
        ..addAll(prevNames);
      notifyListeners();
      return false;
    }
  }

  List<String> getRegisteredPlayers(String matchId) {
    final match = _matches.where((m) => m.id == matchId).firstOrNull;
    return match?.registeredPlayerIds ?? [];
  }

  bool isUserRegistered(String matchId, String userId) {
    final match = _matches.where((m) => m.id == matchId).firstOrNull;
    return match?.registeredPlayerIds.contains(userId) ?? false;
  }

  /// Route payment to event creator (for external/personal events)
  Future<void> routePaymentToCreator(String creatorId, double amount, {String? communityId}) async {
    try {
      await _db.addToUserBalance(creatorId, amount, communityId: communityId);
      debugPrint('PAYMENT: Routed ${amount.toInt()}₽ to creator $creatorId');
    } catch (e) {
      debugPrint('PAYMENT ERROR: Failed to route to creator: $e');
    }
  }

  /// Add a match — saves to Supabase and adds to local list
  Future<void> addMatch(SportMatch match) async {
    final communityId = match.communityId ?? _currentCommunityId;
    try {
      // Insert into Supabase and get back the generated UUID
      final response = await _db.createMatchAndReturn(communityId, match);
      final savedMatch = SportMatch(
        id: response['id'].toString(),
        communityId: communityId,
        creatorId: match.creatorId,
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
    _notifProv?.add(
      type: NotificationType.eventCreated,
      title: 'Новое событие',
      body: '${match.category.displayName} ${match.format} — ${match.location}',
      payload: {'matchId': match.id},
    );
  }

  // ============================================================
  // УПРАВЛЕНИЕ КОМАНДАМИ
  // ============================================================

  /// Добавить команду в событие (макс 5)
  bool addEventTeam(String matchId, {String? name}) {
    final match = getById(matchId);
    if (match == null || match.eventTeams.length >= 5) return false;

    final idx = match.eventTeams.length;
    final teamName = (name != null && name.trim().isNotEmpty)
        ? name.trim()
        : teamColorNames[idx];
    match.eventTeams.add(EventTeam(
      id: 'team_${DateTime.now().millisecondsSinceEpoch}_$idx',
      name: teamName,
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

  /// Авто-разделение: случайно распределить всех по командам
  void autoDistributePlayers(String matchId) {
    final match = getById(matchId);
    if (match == null || match.eventTeams.isEmpty) return;

    // Очищаем все команды
    for (final team in match.eventTeams) {
      team.playerIds.clear();
      team.playerNames.clear();
    }

    // Создаём список индексов и перемешиваем случайно
    final indices = List<int>.generate(match.registeredPlayerIds.length, (i) => i);
    indices.shuffle();

    // Распределяем round-robin по перемешанному порядку
    for (int i = 0; i < indices.length; i++) {
      final playerIdx = indices[i];
      final teamIdx = i % match.eventTeams.length;
      final name = playerIdx < match.registeredPlayerNames.length
          ? match.registeredPlayerNames[playerIdx]
          : 'Игрок';
      match.eventTeams[teamIdx]
          .addPlayer(match.registeredPlayerIds[playerIdx], name);
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
  // КАПИТАНЫ
  // ============================================================

  /// Назначить капитана команды (макс 2)
  bool setCaptain(String matchId, String teamId, String playerId, String playerName) {
    final match = getById(matchId);
    if (match == null) return false;
    final team = match.eventTeams.where((t) => t.id == teamId).firstOrNull;
    if (team == null) return false;
    final ok = team.addCaptain(playerId, playerName);
    if (ok) {
      _syncEventTeams(match);
      notifyListeners();
    }
    return ok;
  }

  /// Убрать капитана
  void removeCaptainFromTeam(String matchId, String teamId, String playerId) {
    final match = getById(matchId);
    if (match == null) return;
    final team = match.eventTeams.where((t) => t.id == teamId).firstOrNull;
    if (team == null) return;
    team.removeCaptain(playerId);
    _syncEventTeams(match);
    notifyListeners();
  }

  /// Пометить команду как оценённую капитаном
  void markTeamRated(String matchId, String teamId) {
    final match = getById(matchId);
    if (match == null) return;
    final team = match.eventTeams.where((t) => t.id == teamId).firstOrNull;
    if (team == null) return;
    team.ratingsSubmitted = true;
    _syncEventTeams(match);
    notifyListeners();
    debugPrint('CAPTAIN: Team ${team.name} rated. allCaptainsRated=${match.allCaptainsRated}');
    // Auto-complete if all teams rated
    if (match.allCaptainsRated) {
      completeEvent(matchId);
    }
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
    _notifProv?.add(
      type: NotificationType.eventCompleted,
      title: 'Событие завершено',
      body: '${match.category.displayName} ${match.format} — результаты записаны',
      payload: {'matchId': matchId},
    );
    debugPrint('EVENT: Completed event $matchId');
  }
}
