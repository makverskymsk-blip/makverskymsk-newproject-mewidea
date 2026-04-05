import 'package:flutter/material.dart';

enum SportCategory {
  football(
    displayName: 'Футбол',
    icon: Icons.sports_soccer,
    backgroundImage: 'assets/images/back2.jpg',
  ),
  hockey(
    displayName: 'Хоккей',
    icon: Icons.sports_hockey,
    backgroundImage: 'assets/images/hockey_back.jpg',
  ),
  tennis(
    displayName: 'Теннис',
    icon: Icons.sports_tennis,
    backgroundImage: 'assets/images/tennis_back.jpg',
  ),
  esports(
    displayName: 'Киберспорт',
    icon: Icons.sports_esports,
    backgroundImage: 'assets/images/esports_back.jpg',
  );

  final String displayName;
  final IconData icon;
  final String backgroundImage;

  const SportCategory({
    required this.displayName,
    required this.icon,
    required this.backgroundImage,
  });
}

enum UserRole { owner, admin, player }

enum MatchType { subscription, single }

enum TransactionType {
  topUp('Пополнение'),
  gamePayment('Оплата игры'),
  subscriptionPayment('Абонемент'),
  withdrawal('Вывод средств'),
  rentPayment('Оплата аренды'),
  refund('Возврат');

  final String displayName;
  const TransactionType(this.displayName);
}

enum TransactionStatus {
  pending('Ожидает'),
  confirmed('Подтверждена'),
  rejected('Отклонена');

  final String displayName;
  const TransactionStatus(this.displayName);
}

enum SubscriptionPaymentStatus { notPaid, pending, paid, overdue }
