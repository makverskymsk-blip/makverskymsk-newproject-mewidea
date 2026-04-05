import 'enums.dart';

class Transaction {
  final String id;
  final String userId;
  final String? communityId;
  final TransactionType type;
  final double amount;
  final DateTime dateTime;
  TransactionStatus status;
  final String description;

  Transaction({
    required this.id,
    required this.userId,
    this.communityId,
    required this.type,
    required this.amount,
    DateTime? dateTime,
    this.status = TransactionStatus.pending,
    required this.description,
  }) : dateTime = dateTime ?? DateTime.now();

  bool get isIncome =>
      type == TransactionType.topUp || type == TransactionType.refund;

  String get formattedAmount =>
      isIncome ? '+ ${amount.toInt()} ₽' : '- ${amount.toInt()} ₽';
}
