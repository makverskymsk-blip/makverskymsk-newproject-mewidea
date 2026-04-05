import 'enums.dart';

class SubscriptionEntry {
  final String userId;
  final String userName;
  double? calculatedAmount;
  SubscriptionPaymentStatus paymentStatus;

  SubscriptionEntry({
    required this.userId,
    required this.userName,
    this.calculatedAmount,
    this.paymentStatus = SubscriptionPaymentStatus.notPaid,
  });

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'userName': userName,
        'calculatedAmount': calculatedAmount,
        'paymentStatus': paymentStatus.index,
      };

  factory SubscriptionEntry.fromMap(Map<String, dynamic> map) =>
      SubscriptionEntry(
        userId: map['userId'] ?? '',
        userName: map['userName'] ?? '',
        calculatedAmount: (map['calculatedAmount'] as num?)?.toDouble(),
        paymentStatus: SubscriptionPaymentStatus
            .values[map['paymentStatus'] ?? 0],
      );
}

class MonthlySubscription {
  final String id;
  final String communityId;
  final int month; // 1-12
  final int year;
  final double totalRent;
  double compensationAmount; // Компенсация из банка сообщества
  final List<SubscriptionEntry> entries;
  bool isCalculated;
  DateTime? calculationDate;
  DateTime? paymentDeadline;

  MonthlySubscription({
    required this.id,
    required this.communityId,
    required this.month,
    required this.year,
    required this.totalRent,
    this.compensationAmount = 0,
    List<SubscriptionEntry>? entries,
    this.isCalculated = false,
    this.calculationDate,
    this.paymentDeadline,
  }) : entries = entries ?? [];

  /// Эффективная аренда после компенсации из банка
  double get effectiveRent => (totalRent - compensationAmount).clamp(0, totalRent);

  /// Стоимость на одного человека = (аренда - компенсация) / кол-во записавшихся
  double get perPlayerAmount {
    if (!isCalculated || entries.isEmpty) return 0;
    return effectiveRent / entries.length;
  }

  /// Предварительная стоимость (до расчёта 25го числа)
  double get estimatedPerPlayerAmount {
    if (entries.isEmpty) return 0;
    return effectiveRent / entries.length;
  }

  /// Предварительная стоимость без компенсации
  double get estimatedPerPlayerWithoutCompensation {
    if (entries.isEmpty) return 0;
    return totalRent / entries.length;
  }

  /// Регистрация открыта до 25го числа текущего месяца
  bool get isRegistrationOpen {
    final now = DateTime.now();
    // Можно записаться до 25 числа месяца абонемента
    if (now.year < year) return true;
    if (now.year > year) return false;
    if (now.month < month) return true;
    if (now.month > month) return false;
    return now.day < 25;
  }

  /// Проверяет, действует ли абонемент (строго на месяц+год)
  bool isActiveForDate(DateTime date) {
    return date.month == month && date.year == year;
  }

  /// Проверяет, действует ли абонемент прямо сейчас
  bool get isCurrentlyActive {
    final now = DateTime.now();
    return now.month == month && now.year == year;
  }

  /// Подписан ли пользователь на этот абонемент
  bool hasUser(String userId) {
    return entries.any((e) => e.userId == userId);
  }

  /// Количество подписчиков
  int get subscriberCount => entries.length;

  /// Список имён подписчиков
  List<String> get subscriberNames =>
      entries.map((e) => e.userName).toList();

  Map<String, dynamic> toMap() => {
        'communityId': communityId,
        'month': month,
        'year': year,
        'totalRent': totalRent,
        'compensationAmount': compensationAmount,
        'entries': entries.map((e) => e.toMap()).toList(),
        'isCalculated': isCalculated,
        'calculationDate': calculationDate?.millisecondsSinceEpoch,
        'paymentDeadline': paymentDeadline?.millisecondsSinceEpoch,
      };

  factory MonthlySubscription.fromMap(String id, Map<String, dynamic> map) =>
      MonthlySubscription(
        id: id,
        communityId: map['communityId'] ?? '',
        month: map['month'] ?? 1,
        year: map['year'] ?? 2026,
        totalRent: (map['totalRent'] ?? 0).toDouble(),
        compensationAmount: (map['compensationAmount'] ?? 0).toDouble(),
        entries: (map['entries'] as List<dynamic>?)
                ?.map((e) =>
                    SubscriptionEntry.fromMap(e as Map<String, dynamic>))
                .toList() ??
            [],
        isCalculated: map['isCalculated'] ?? false,
        calculationDate: map['calculationDate'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['calculationDate'])
            : null,
        paymentDeadline: map['paymentDeadline'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['paymentDeadline'])
            : null,
      );
}
