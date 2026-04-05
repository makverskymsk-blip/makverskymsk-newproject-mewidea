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
    DateTime? createdAt,
  })  : communityIds = communityIds ?? [],
        createdAt = createdAt ?? DateTime.now();
}
