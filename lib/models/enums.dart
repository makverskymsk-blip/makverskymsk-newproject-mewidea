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
  padel(
    displayName: 'Падл',
    icon: Icons.sports_tennis,
    backgroundImage: 'assets/images/padel_back.jpg',
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

// ─── Training Module Enums ───

enum Gender {
  male('Мужской'),
  female('Женский');

  final String displayName;
  const Gender(this.displayName);
}

enum TrainingGoal {
  strength('Сила', Icons.fitness_center_rounded),
  hypertrophy('Гипертрофия', Icons.trending_up_rounded),
  endurance('Выносливость', Icons.timer_rounded),
  fatLoss('Жиросжигание', Icons.local_fire_department_rounded),
  fullBody('Фулбоди', Icons.accessibility_new_rounded);

  final String displayName;
  final IconData icon;
  const TrainingGoal(this.displayName, this.icon);
}

enum MuscleGroup {
  chest('Грудь', 'chest'),
  back('Спина', 'back'),
  shoulders('Плечи', 'shoulders'),
  biceps('Бицепс', 'biceps'),
  triceps('Трицепс', 'triceps'),
  forearms('Предплечья', 'forearms'),
  abs('Пресс', 'abs'),
  quads('Квадрицепс', 'quads'),
  hamstrings('Бицепс бедра', 'hamstrings'),
  glutes('Ягодицы', 'glutes'),
  calves('Икры', 'calves'),
  traps('Трапеция', 'traps');

  final String displayName;
  final String key;
  const MuscleGroup(this.displayName, this.key);
}
