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
  });

  int get kda => goals + assists;
}

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
  });

  // FIFA-style stats (0-99 scale)
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
}
