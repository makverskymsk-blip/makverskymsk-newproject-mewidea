import 'package:flutter/material.dart';
import '../models/achievement.dart';
import '../models/enums.dart';
import '../models/match_stats.dart';
import '../services/supabase_service.dart';

class StatsProvider extends ChangeNotifier {
  final SupabaseService _db = SupabaseService();
  final Map<String, PlayerOverallStats> _playerStats = {};
  final Map<String, List<Map<String, dynamic>>> _matchHistory = {};
  final Map<String, List<Achievement>> _achievements = {};

  PlayerOverallStats getPlayerStats(String userId) {
    return _playerStats[userId] ?? PlayerOverallStats(
      // Mock demo data — overall = 90 (shown until real data loads)
      totalGames: 50,
      totalGoals: 78,
      totalAssists: 62,
      totalSaves: 90,
      totalMotm: 12,
      avgRating: 9.0,
      winCount: 38,
      lossCount: 8,
      drawCount: 4,
    );
  }

  /// Match history for profile (real data from Supabase)
  List<Map<String, dynamic>> getMatchHistoryRecords(String userId) {
    return _matchHistory[userId] ?? [];
  }

  /// Load real player stats from Supabase
  Future<void> loadPlayerStatsFromDb(String userId) async {
    try {
      final data = await _db.getPlayerAggregateStats(userId);
      if (data != null) {
        final totalDist = await _db.getPlayerTotalDistance(userId);
        _playerStats[userId] = PlayerOverallStats(
          totalGames: data['total_games'] ?? 0,
          totalGoals: data['total_goals'] ?? 0,
          totalAssists: data['total_assists'] ?? 0,
          totalSaves: data['total_saves'] ?? 0,
          totalMotm: data['total_mvp'] ?? 0,
          avgRating: (data['avg_rating'] ?? 0.0).toDouble(),
          winCount: data['win_count'] ?? 0,
          lossCount: data['loss_count'] ?? 0,
          drawCount: data['draw_count'] ?? 0,
          totalDistanceKm: totalDist,
        );
        // Also check achievements
        _checkAchievementsFromStats(userId, _playerStats[userId]!);
        debugPrint('STATS: Loaded real stats for $userId: overall=${_playerStats[userId]!.overallRating}, distance=${totalDist}km');
      }

      // Load match history
      final history = await _db.getPlayerMatchHistory(userId, limit: 10);
      if (history.isNotEmpty) {
        _matchHistory[userId] = history;
      }

      notifyListeners();
    } catch (e) {
      debugPrint('STATS ERROR: Failed to load from DB: $e');
    }
  }

  /// Получить достижения пользователя для конкретного спорта
  List<Achievement> getAchievementsForSport(String userId, SportCategory sport) {
    final all = getAchievements(userId);
    final sportAchievements = Achievements.forSport(sport);
    final sportIds = sportAchievements.map((a) => a.id).toSet();
    return all.where((a) => sportIds.contains(a.id)).toList();
  }

  /// Получить все достижения пользователя
  List<Achievement> getAchievements(String userId) {
    if (!_achievements.containsKey(userId)) {
      _achievements[userId] = List.from(Achievements.all);
    }
    return _achievements[userId]!;
  }

  /// Количество разблокированных достижений по виду спорта
  int getUnlockedCount(String userId, SportCategory sport) {
    return getAchievementsForSport(userId, sport)
        .where((a) => a.isUnlocked)
        .length;
  }

  /// Общее количество достижений по виду спорта
  int getTotalCount(SportCategory sport) {
    return Achievements.forSport(sport).length;
  }

  void recordMatchStats(MatchStats stats) {
    final overall = _playerStats.putIfAbsent(
        stats.userId, () => PlayerOverallStats());
    overall.totalGames++;
    overall.totalGoals += stats.goals;
    overall.totalAssists += stats.assists;
    overall.totalSaves += stats.saves;
    if (stats.isManOfTheMatch) overall.totalMotm++;
    overall.avgRating = ((overall.avgRating * (overall.totalGames - 1)) +
            stats.rating) / overall.totalGames;

    _checkAchievementsFromOverall(stats.userId, overall, stats);
    notifyListeners();
  }

  void _checkAchievementsFromStats(String userId, PlayerOverallStats overall) {
    final achievements = getAchievements(userId);

    void unlock(String id) {
      final idx = achievements.indexWhere((a) => a.id == id && !a.isUnlocked);
      if (idx != -1) {
        achievements[idx] = achievements[idx]
            .copyWith(isUnlocked: true, unlockedAt: DateTime.now());
      }
    }

    if (overall.totalGames >= 10) unlock('ten_games');
    if (overall.totalGames >= 50) unlock('fifty_games');
    if (overall.totalMotm >= 1) unlock('motm');
    if (overall.totalMotm >= 5) unlock('five_motm');
    if (overall.totalGoals >= 1) unlock('fb_first_goal');
    if (overall.totalGoals >= 10) unlock('fb_ten_goals');
    if (overall.totalGoals >= 50) unlock('fb_fifty_goals');
  }

  void _checkAchievementsFromOverall(
      String userId, PlayerOverallStats overall, MatchStats latest) {
    _checkAchievementsFromStats(userId, overall);
    final achievements = getAchievements(userId);

    void unlock(String id) {
      final idx = achievements.indexWhere((a) => a.id == id && !a.isUnlocked);
      if (idx != -1) {
        achievements[idx] = achievements[idx]
            .copyWith(isUnlocked: true, unlockedAt: DateTime.now());
      }
    }

    if (latest.goals >= 3) unlock('fb_hat_trick');
    if (latest.assists >= 5) unlock('fb_assist_king');
  }
}
