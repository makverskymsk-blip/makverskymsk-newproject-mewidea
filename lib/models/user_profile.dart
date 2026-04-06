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
  })  : communityIds = communityIds ?? [],
        sportPositions = sportPositions ?? {},
        createdAt = createdAt ?? DateTime.now();

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
