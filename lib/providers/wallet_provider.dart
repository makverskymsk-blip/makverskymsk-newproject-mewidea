import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../models/enums.dart';

class WalletProvider extends ChangeNotifier {
  final List<Transaction> _transactions = [];

  List<Transaction> get transactions => _transactions;

  List<Transaction> get pendingTransactions =>
      _transactions.where((t) => t.status == TransactionStatus.pending).toList();



  void requestTopUp(String userId, double amount) {
    _transactions.add(Transaction(
      id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      type: TransactionType.topUp,
      amount: amount,
      description: 'Запрос на пополнение',
    ));
    notifyListeners();
  }

  void confirmTransaction(String txId) {
    final tx = _transactions.where((t) => t.id == txId).firstOrNull;
    if (tx != null) {
      tx.status = TransactionStatus.confirmed;
      notifyListeners();
    }
  }

  void rejectTransaction(String txId) {
    final tx = _transactions.where((t) => t.id == txId).firstOrNull;
    if (tx != null) {
      tx.status = TransactionStatus.rejected;
      notifyListeners();
    }
  }

  void addGamePayment(String userId, String? communityId, double amount, String desc) {
    _transactions.add(Transaction(
      id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      communityId: communityId,
      type: TransactionType.gamePayment,
      amount: amount,
      description: desc,
      status: TransactionStatus.confirmed,
    ));
    notifyListeners();
  }

  /// Добавить запись об оплате абонемента
  void addSubscriptionPayment(
      String userId, String communityId, double amount, String monthLabel) {
    _transactions.add(Transaction(
      id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      communityId: communityId,
      type: TransactionType.subscriptionPayment,
      amount: amount,
      description: 'Абонемент: $monthLabel',
      status: TransactionStatus.confirmed,
    ));
    notifyListeners();
  }

  List<Transaction> getUserTransactions(String userId) {
    return _transactions.where((t) => t.userId == userId).toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
  }

  /// Получить транзакции по сообществу
  List<Transaction> getCommunityTransactions(String communityId) {
    return _transactions.where((t) => t.communityId == communityId).toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
  }

  /// Получить сумму всех подтверждённых транзакций пользователя
  double getUserBalance(String userId) {
    double balance = 0;
    for (final tx in _transactions.where(
        (t) => t.userId == userId && t.status == TransactionStatus.confirmed)) {
      if (tx.isIncome) {
        balance += tx.amount;
      } else {
        balance -= tx.amount;
      }
    }
    return balance;
  }
}
