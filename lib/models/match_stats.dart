import '../widgets/radar_chart.dart';
import 'enums.dart';

class MatchStats {
  final String id;
  final String matchId;
  final String userId;
  final String userName;
  int goals;
  int assists;
  int saves;
  int fouls;
  double rating; // 1-10
  bool isManOfTheMatch;
  double distanceKm; // пробег в км (с трекера)

  MatchStats({
    required this.id,
    required this.matchId,
    required this.userId,
    required this.userName,
    this.goals = 0,
    this.assists = 0,
    this.saves = 0,
    this.fouls = 0,
    this.rating = 6.0,
    this.isManOfTheMatch = false,
    this.distanceKm = 0.0,
  });

  int get kda => goals + assists;
}

// ============================================================
// Abstract Sport Metrics — each sport has its own radar + rating
// ============================================================

abstract class SportMetrics {
  /// Radar chart entries (5 stats, 0-99 each)
  List<RadarEntry> get radarEntries;

  /// Labels for radar stats (e.g. ['ATK', 'PAS', 'DEF', 'SPD', 'SKL'])
  List<String> get statLabels;

  /// List of individual stat values (0-99) matching statLabels order
  List<int> get statValues;

  /// The primary stat label for a given position
  String mainStatForPosition(String position);

  /// Overall rating (0-99)
  int get overallRating;

  /// Sport category this metrics belongs to
  SportCategory get sport;
}

// ============================================================
// ⚽ Football Metrics
// ============================================================

class FootballMetrics extends SportMetrics {
  final int atk; // Attack
  final int pas; // Passing
  final int def; // Defense
  final int spd; // Speed / Stamina
  final int skl; // Skill

  FootballMetrics({
    required this.atk,
    required this.pas,
    required this.def,
    required this.spd,
    required this.skl,
  });

  @override
  SportCategory get sport => SportCategory.football;

  @override
  List<String> get statLabels => ['ATK', 'PAS', 'DEF', 'SPD', 'SKL'];

  @override
  List<int> get statValues => [atk, pas, def, spd, skl];

  @override
  List<RadarEntry> get radarEntries => [
        RadarEntry(label: 'ATK', value: atk),
        RadarEntry(label: 'PAS', value: pas),
        RadarEntry(label: 'DEF', value: def),
        RadarEntry(label: 'SPD', value: spd),
        RadarEntry(label: 'SKL', value: skl),
      ];

  @override
  String mainStatForPosition(String pos) {
    switch (pos) {
      case 'ST': return 'ATK';
      case 'DF': return 'DEF';
      case 'MF': return 'PAS';
      case 'GK': return 'DEF';
      default:   return 'SKL';
    }
  }

  @override
  int get overallRating =>
      ((atk + pas + def + spd + skl) / 5).clamp(0, 99).toInt();

  /// Create from PlayerOverallStats (backward compat)
  factory FootballMetrics.fromOverall(PlayerOverallStats s) {
    return FootballMetrics(
      atk: s.totalGames == 0 ? 50 : (50 + (s.totalGoals / s.totalGames * 25)).clamp(0, 99).toInt(),
      pas: s.totalGames == 0 ? 50 : (50 + (s.totalAssists / s.totalGames * 30)).clamp(0, 99).toInt(),
      def: s.totalGames == 0 ? 50 : (50 + (s.totalSaves / s.totalGames * 20)).clamp(0, 99).toInt(),
      spd: (s.totalGames * 2).clamp(0, 99),
      skl: s.totalGames == 0 ? 50 : ((s.avgRating / 10) * 99).clamp(0, 99).toInt(),
    );
  }
}

// ============================================================
// 🏒 Hockey Metrics
// ============================================================

class HockeyMetrics extends SportMetrics {
  final int sht; // Shooting
  final int pas; // Passing
  final int def; // Defense
  final int skt; // Skating
  final int sav; // Saves

  HockeyMetrics({
    required this.sht,
    required this.pas,
    required this.def,
    required this.skt,
    required this.sav,
  });

  @override
  SportCategory get sport => SportCategory.hockey;

  @override
  List<String> get statLabels => ['SHT', 'PAS', 'DEF', 'SKT', 'SAV'];

  @override
  List<int> get statValues => [sht, pas, def, skt, sav];

  @override
  List<RadarEntry> get radarEntries => [
        RadarEntry(label: 'SHT', value: sht),
        RadarEntry(label: 'PAS', value: pas),
        RadarEntry(label: 'DEF', value: def),
        RadarEntry(label: 'SKT', value: skt),
        RadarEntry(label: 'SAV', value: sav),
      ];

  @override
  String mainStatForPosition(String pos) {
    switch (pos) {
      case 'ST': return 'SHT';
      case 'DF': return 'DEF';
      case 'GK': return 'SAV';
      default:   return 'PAS';
    }
  }

  @override
  int get overallRating =>
      ((sht + pas + def + skt + sav) / 5).clamp(0, 99).toInt();

  factory HockeyMetrics.fromOverall(PlayerOverallStats s) {
    return HockeyMetrics(
      sht: s.totalGames == 0 ? 40 : (40 + s.totalGoals / s.totalGames * 30).clamp(0, 99).toInt(),
      pas: s.totalGames == 0 ? 40 : (40 + s.totalAssists / s.totalGames * 25).clamp(0, 99).toInt(),
      def: s.totalGames == 0 ? 40 : (40 + s.totalSaves / s.totalGames * 20).clamp(0, 99).toInt(),
      skt: (40 + s.totalGames * 1.5).clamp(0, 99).toInt(),
      sav: s.totalGames == 0 ? 40 : (40 + s.totalSaves / s.totalGames * 25).clamp(0, 99).toInt(),
    );
  }
}

// ============================================================
// 🎾 Tennis Metrics
// ============================================================

class TennisMetrics extends SportMetrics {
  final int srv; // Serve
  final int rtn; // Return
  final int net; // Net play
  final int end; // Endurance
  final int mnt; // Mental

  TennisMetrics({
    required this.srv,
    required this.rtn,
    required this.net,
    required this.end,
    required this.mnt,
  });

  @override
  SportCategory get sport => SportCategory.tennis;

  @override
  List<String> get statLabels => ['SRV', 'RTN', 'NET', 'END', 'MNT'];

  @override
  List<int> get statValues => [srv, rtn, net, end, mnt];

  @override
  List<RadarEntry> get radarEntries => [
        RadarEntry(label: 'SRV', value: srv),
        RadarEntry(label: 'RTN', value: rtn),
        RadarEntry(label: 'NET', value: net),
        RadarEntry(label: 'END', value: end),
        RadarEntry(label: 'MNT', value: mnt),
      ];

  @override
  String mainStatForPosition(String pos) => 'SRV'; // Tennis is individual

  @override
  int get overallRating =>
      ((srv + rtn + net + end + mnt) / 5).clamp(0, 99).toInt();

  factory TennisMetrics.fromOverall(PlayerOverallStats s) {
    return TennisMetrics(
      srv: s.totalGames == 0 ? 40 : (40 + s.totalGoals / s.totalGames * 20).clamp(0, 99).toInt(),     // aces mapped to goals
      rtn: s.totalGames == 0 ? 40 : (40 + s.totalAssists / s.totalGames * 25).clamp(0, 99).toInt(),    // winners mapped to assists
      net: s.totalGames == 0 ? 40 : (40 + s.totalSaves / s.totalGames * 20).clamp(0, 99).toInt(),
      end: (40 + s.totalGames * 1.2).clamp(0, 99).toInt(),
      mnt: s.totalGames == 0 ? 40 : (40 + s.winRate * 0.4).clamp(0, 99).toInt(),
    );
  }
}

// ============================================================
// 🎮 Esports Metrics
// ============================================================

class EsportsMetrics extends SportMetrics {
  final int aim; // Aim / Mechanics
  final int igl; // Game sense
  final int clt; // Clutch
  final int utl; // Utility
  final int com; // Communication / Teamwork

  EsportsMetrics({
    required this.aim,
    required this.igl,
    required this.clt,
    required this.utl,
    required this.com,
  });

  @override
  SportCategory get sport => SportCategory.esports;

  @override
  List<String> get statLabels => ['AIM', 'IGL', 'CLT', 'UTL', 'COM'];

  @override
  List<int> get statValues => [aim, igl, clt, utl, com];

  @override
  List<RadarEntry> get radarEntries => [
        RadarEntry(label: 'AIM', value: aim),
        RadarEntry(label: 'IGL', value: igl),
        RadarEntry(label: 'CLT', value: clt),
        RadarEntry(label: 'UTL', value: utl),
        RadarEntry(label: 'COM', value: com),
      ];

  @override
  String mainStatForPosition(String pos) => 'AIM'; // Esports default

  @override
  int get overallRating =>
      ((aim + igl + clt + utl + com) / 5).clamp(0, 99).toInt();

  factory EsportsMetrics.fromOverall(PlayerOverallStats s) {
    return EsportsMetrics(
      aim: s.totalGames == 0 ? 40 : (40 + s.totalGoals / s.totalGames * 15).clamp(0, 99).toInt(),     // kills mapped to goals
      igl: s.totalGames == 0 ? 40 : (40 + s.winRate * 0.4).clamp(0, 99).toInt(),
      clt: s.totalGames == 0 ? 40 : (40 + s.totalMotm * 10).clamp(0, 99).toInt(),
      utl: s.totalGames == 0 ? 40 : (40 + s.avgRating * 5).clamp(0, 99).toInt(),
      com: s.totalGames == 0 ? 40 : (40 + s.totalAssists / s.totalGames * 20).clamp(0, 99).toInt(),
    );
  }
}

// ============================================================
// Factory: build sport metrics from overall stats
// ============================================================

SportMetrics buildSportMetrics(PlayerOverallStats stats, SportCategory sport) {
  switch (sport) {
    case SportCategory.football:
      return FootballMetrics.fromOverall(stats);
    case SportCategory.hockey:
      return HockeyMetrics.fromOverall(stats);
    case SportCategory.tennis:
    case SportCategory.padel:
      return TennisMetrics.fromOverall(stats);
    case SportCategory.esports:
      return EsportsMetrics.fromOverall(stats);
  }
}

// ============================================================
// PlayerOverallStats (unchanged, but with sport-aware helper)
// ============================================================

class PlayerOverallStats {
  int totalGames;
  int totalGoals;
  int totalAssists;
  int totalSaves;
  int totalMotm; // Man of the Match count
  double avgRating;
  int winCount;
  int lossCount;
  int drawCount;
  double totalDistanceKm; // суммарный пробег

  PlayerOverallStats({
    this.totalGames = 0,
    this.totalGoals = 0,
    this.totalAssists = 0,
    this.totalSaves = 0,
    this.totalMotm = 0,
    this.avgRating = 0,
    this.winCount = 0,
    this.lossCount = 0,
    this.drawCount = 0,
    this.totalDistanceKm = 0,
  });

  // Legacy FIFA-style stats (football, backward compat)
  int get attackRating =>
      totalGames == 0 ? 50 : (50 + (totalGoals / totalGames * 25)).clamp(0, 99).toInt();
  int get passRating =>
      totalGames == 0 ? 50 : (50 + (totalAssists / totalGames * 30)).clamp(0, 99).toInt();
  int get defenseRating =>
      totalGames == 0 ? 50 : (50 + (totalSaves / totalGames * 20)).clamp(0, 99).toInt();
  int get staminaRating => (totalGames * 2).clamp(0, 99);
  int get skillRating =>
      totalGames == 0 ? 50 : ((avgRating / 10) * 99).clamp(0, 99).toInt();
  int get overallRating {
    if (totalGames == 0) return 50;
    return ((attackRating + passRating + defenseRating + staminaRating + skillRating) / 5)
        .clamp(0, 99)
        .toInt();
  }

  double get winRate =>
      totalGames == 0 ? 0 : (winCount / totalGames * 100);

  /// Get sport-specific metrics
  SportMetrics getMetrics(SportCategory sport) => buildSportMetrics(this, sport);
}
