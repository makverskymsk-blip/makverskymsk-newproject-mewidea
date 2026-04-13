import 'package:flutter/material.dart';

enum NotificationType {
  eventCreated(
    'Новое событие', Icons.sports_soccer, Color(0xFF43A047)),
  eventReminder(
    'Напоминание', Icons.access_time_rounded, Color(0xFFFF9800)),
  eventCompleted(
    'Событие завершено', Icons.emoji_events_rounded, Color(0xFFFFB300)),
  balanceTopUp(
    'Пополнение', Icons.account_balance_wallet_rounded, Color(0xFF43A047)),
  balanceCharge(
    'Списание', Icons.payment_rounded, Color(0xFFE53935)),
  subscriptionCalc(
    'Абонемент', Icons.card_membership_rounded, Color(0xFF42A5F5)),
  achievementUnlock(
    'Достижение', Icons.military_tech_rounded, Color(0xFFFFB300)),
  memberJoined(
    'Новый участник', Icons.person_add_rounded, Color(0xFF7E57C2));

  final String label;
  final IconData icon;
  final Color color;
  const NotificationType(this.label, this.icon, this.color);
}

class AppNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final DateTime createdAt;
  bool isRead;
  final Map<String, dynamic>? payload;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    DateTime? createdAt,
    this.isRead = false,
    this.payload,
  }) : createdAt = createdAt ?? DateTime.now();

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'сейчас';
    if (diff.inMinutes < 60) return '${diff.inMinutes} мин.';
    if (diff.inHours < 24) return '${diff.inHours} ч.';
    if (diff.inDays < 7) return '${diff.inDays} дн.';
    return '${createdAt.day}.${createdAt.month.toString().padLeft(2, '0')}';
  }
}
