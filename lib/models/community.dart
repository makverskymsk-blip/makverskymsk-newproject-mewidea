import 'enums.dart';

class Community {
  final String id;
  final String name;
  final SportCategory sport;
  final String inviteCode;
  final String ownerId;
  final List<String> adminIds;
  final List<String> memberIds;
  final double monthlyRent;
  final double singleGamePrice;
  double bankBalance;
  String? logoUrl;
  final DateTime createdAt;

  Community({
    required this.id,
    required this.name,
    required this.sport,
    required this.inviteCode,
    required this.ownerId,
    List<String>? adminIds,
    List<String>? memberIds,
    this.monthlyRent = 100000,
    this.singleGamePrice = 1200,
    this.bankBalance = 0,
    this.logoUrl,
    DateTime? createdAt,
  })  : adminIds = adminIds ?? [],
        memberIds = memberIds ?? [],
        createdAt = createdAt ?? DateTime.now();

  bool isOwner(String userId) => ownerId == userId;
  bool isAdmin(String userId) => adminIds.contains(userId) || isOwner(userId);
  bool isMember(String userId) =>
      memberIds.contains(userId) || isAdmin(userId);
  int get totalMembers => allMemberIds.length;

  /// Проверяет, может ли пользователь управлять балансом (владелец или админ)
  bool canManageBalance(String userId) => isAdmin(userId);

  /// Проверяет, может ли пользователь назначать администраторов (только владелец)
  bool canManageAdmins(String userId) => isOwner(userId);

  /// Получить роль пользователя в сообществе
  UserRole getUserRole(String userId) {
    if (isOwner(userId)) return UserRole.owner;
    if (adminIds.contains(userId)) return UserRole.admin;
    return UserRole.player;
  }

  /// Список всех участников (без дублей)
  List<String> get allMemberIds => <String>{ownerId, ...adminIds, ...memberIds}.toList();
}
