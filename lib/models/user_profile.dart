import 'dart:math' as math;

class UserProfile {
  final String id;
  String name;
  String? email;
  String position;
  String? avatarUrl;
  double balance;
  double debt;
  List<String> communityIds;
  bool isPremium;
  int gamesPlayed;
  int goalsScored;
  final DateTime createdAt;

  /// Per-sport positions: {'football': 'Нападающий', 'esports': 'Снайпер', ...}
  Map<String, String> sportPositions;

  // ─── Training Module Fields ───
  String? gender;       // 'male' / 'female'
  int? heightCm;
  double? weightKg;
  int? age;
  int trainingXp;
  int trainingLevel;

  UserProfile({
    required this.id,
    required this.name,
    this.email,
    this.position = 'Не указана',
    this.avatarUrl,
    this.balance = 0,
    this.debt = 0,
    List<String>? communityIds,
    this.isPremium = false,
    this.gamesPlayed = 0,
    this.goalsScored = 0,
    Map<String, String>? sportPositions,
    DateTime? createdAt,
    this.gender,
    this.heightCm,
    this.weightKg,
    this.age,
    this.trainingXp = 0,
    this.trainingLevel = 1,
  })  : communityIds = communityIds ?? [],
        sportPositions = sportPositions ?? {},
        createdAt = createdAt ?? DateTime.now();

  /// XP needed for next level: 500 × L^1.5
  int get xpForNextLevel => (500 * math.pow(trainingLevel, 1.5)).round();

  /// XP progress fraction (0.0 – 1.0)
  double get xpProgress {
    final needed = xpForNextLevel;
    return needed > 0 ? (trainingXp / needed).clamp(0.0, 1.0) : 0.0;
  }

  /// Training rank title based on level
  String get trainingRank {
    if (trainingLevel >= 80) return 'Легенда';
    if (trainingLevel >= 60) return 'Элита';
    if (trainingLevel >= 40) return 'Ветеран';
    if (trainingLevel >= 25) return 'Продвинутый';
    if (trainingLevel >= 10) return 'Любитель';
    return 'Новичок';
  }

  /// Get position for specific sport (fallback to general position)
  String getPositionForSport(String sportName) {
    return sportPositions[sportName] ?? position;
  }

  /// Set position for specific sport
  void setPositionForSport(String sportName, String pos) {
    sportPositions[sportName] = pos;
    // Keep legacy 'position' in sync with football
    if (sportName == 'football') {
      position = pos;
    }
  }
}
