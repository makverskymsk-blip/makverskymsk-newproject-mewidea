import 'package:new_idea_works/utils/app_logger.dart';
import 'base_repository.dart';

/// Repository for player stats, distance, aggregates.
class StatsRepository extends BaseRepository {
  static final StatsRepository _instance = StatsRepository._internal();
  factory StatsRepository() => _instance;
  StatsRepository._internal();

  // ───── Player Stats ─────

  Future<void> saveMatchPlayerStats(List<Map<String, dynamic>> statsList) async {
    if (statsList.isEmpty) return;
    await supabase.from('match_player_stats').insert(statsList);
    appLog('STATS: Saved ${statsList.length} player stats records');
  }

  /// Get aggregated stats for a player (client-side)
  Future<Map<String, dynamic>?> getPlayerAggregateStats(
    String userId, {
    String? sportCategory,
  }) async {
    try {
      var query = supabase
          .from('match_player_stats')
          .select()
          .eq('user_id', userId);

      if (sportCategory != null) {
        query = query.eq('sport_category', sportCategory);
      }

      final data = await query.order('created_at', ascending: false);

      if (data.isEmpty) return null;

      int totalGames = data.length;
      int totalGoals = 0;
      int totalAssists = 0;
      int totalSaves = 0;
      int totalMvp = 0;
      int winCount = 0;
      int drawCount = 0;
      int lossCount = 0;
      double totalRating = 0;

      for (final row in data) {
        totalGoals += (row['goals'] as int?) ?? 0;
        totalAssists += (row['assists'] as int?) ?? 0;
        totalSaves += (row['saves'] as int?) ?? 0;
        if (row['is_mvp'] == true) totalMvp++;
        if (row['is_win'] == true) {
          winCount++;
        } else if (row['is_draw'] == true) {
          drawCount++;
        } else {
          lossCount++;
        }
        totalRating += (row['overall_rating'] as num?)?.toDouble() ?? 6.0;
      }

      return {
        'total_games': totalGames,
        'total_goals': totalGoals,
        'total_assists': totalAssists,
        'total_saves': totalSaves,
        'total_mvp': totalMvp,
        'avg_rating': totalGames > 0 ? totalRating / totalGames : 0.0,
        'win_count': winCount,
        'draw_count': drawCount,
        'loss_count': lossCount,
      };
    } catch (e) {
      appLog('STATS ERROR: Failed to get aggregate stats: $e');
      return null;
    }
  }

  /// Get aggregated stats via RPC (server-side, faster)
  Future<Map<String, dynamic>?> getPlayerStatsBySportRpc(
    String userId, {
    String? sportCategory,
  }) async {
    try {
      final result = await supabase.rpc('get_player_stats_by_sport', params: {
        'p_user_id': userId,
        'p_sport_category': sportCategory,
      });

      if (result == null || (result is List && result.isEmpty)) return null;

      final row = result is List ? result.first : result;
      return {
        'total_games': row['total_games'] ?? 0,
        'total_goals': row['total_goals'] ?? 0,
        'total_assists': row['total_assists'] ?? 0,
        'total_saves': row['total_saves'] ?? 0,
        'total_mvp': row['total_mvp'] ?? 0,
        'avg_rating': (row['avg_rating'] ?? 0.0).toDouble(),
        'win_count': row['win_count'] ?? 0,
        'draw_count': row['draw_count'] ?? 0,
        'loss_count': row['loss_count'] ?? 0,
        'total_distance': (row['total_distance'] ?? 0.0).toDouble(),
      };
    } catch (e) {
      appLog('STATS RPC ERROR: $e');
      return getPlayerAggregateStats(userId, sportCategory: sportCategory);
    }
  }

  /// Get recent match history
  Future<List<Map<String, dynamic>>> getPlayerMatchHistory(
      String userId, {int limit = 10, String? sportCategory}) async {
    try {
      var query = supabase
          .from('match_player_stats')
          .select()
          .eq('user_id', userId);

      if (sportCategory != null) {
        query = query.eq('sport_category', sportCategory);
      }

      final data = await query
          .order('created_at', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      appLog('STATS ERROR: Failed to get match history: $e');
      return [];
    }
  }

  // ───── Player Distance ─────

  Future<void> savePlayerDistance(
    String matchId,
    String userId,
    double km, {
    String sportCategory = 'football',
  }) async {
    final existing = await supabase
        .from('match_player_stats')
        .select('id')
        .eq('match_id', matchId)
        .eq('user_id', userId)
        .maybeSingle();

    if (existing != null) {
      await supabase
          .from('match_player_stats')
          .update({
            'distance_km': km,
            'sport_category': sportCategory,
          })
          .eq('match_id', matchId)
          .eq('user_id', userId);
    } else {
      await supabase.from('match_player_stats').insert({
        'match_id': matchId,
        'user_id': userId,
        'distance_km': km,
        'sport_category': sportCategory,
      });
    }
  }

  Future<double> getPlayerDistance(String matchId, String userId) async {
    try {
      final data = await supabase
          .from('match_player_stats')
          .select('distance_km')
          .eq('match_id', matchId)
          .eq('user_id', userId)
          .maybeSingle();
      return (data?['distance_km'] ?? 0.0).toDouble();
    } catch (_) {
      return 0.0;
    }
  }

  Future<double> getPlayerTotalDistance(String userId, {String? sportCategory}) async {
    try {
      var query = supabase
          .from('match_player_stats')
          .select('distance_km')
          .eq('user_id', userId);

      if (sportCategory != null) {
        query = query.eq('sport_category', sportCategory);
      }

      final data = await query;
      double total = 0;
      for (final row in data) {
        total += (row['distance_km'] ?? 0.0).toDouble();
      }
      return total;
    } catch (_) {
      return 0.0;
    }
  }
}
