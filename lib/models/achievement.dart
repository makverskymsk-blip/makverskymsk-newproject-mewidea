import 'package:flutter/material.dart';
import 'enums.dart';

class Achievement {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final AchievementRarity rarity;
  final SportCategory? sport; // null = общее достижение для всех видов
  final bool isUnlocked;
  final DateTime? unlockedAt;

  const Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    this.rarity = AchievementRarity.common,
    this.sport,
    this.isUnlocked = false,
    this.unlockedAt,
  });

  Achievement copyWith({bool? isUnlocked, DateTime? unlockedAt}) {
    return Achievement(
      id: id,
      name: name,
      description: description,
      icon: icon,
      rarity: rarity,
      sport: sport,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }
}

enum AchievementRarity {
  common('Обычная', Color(0xFF9E9E9E)),
  rare('Редкая', Color(0xFF42A5F5)),
  epic('Эпическая', Color(0xFFAB47BC)),
  legendary('Легендарная', Color(0xFFFFB300));

  final String displayName;
  final Color color;
  const AchievementRarity(this.displayName, this.color);
}

/// Достижения сгруппированы по видам спорта
class Achievements {
  // ========== ОБЩИЕ (для всех видов) ==========
  static const List<Achievement> general = [
    Achievement(
      id: 'ten_games',
      name: 'Железный человек',
      description: 'Сыграйте 10 матчей',
      icon: Icons.fitness_center_rounded,
      rarity: AchievementRarity.common,
    ),
    Achievement(
      id: 'fifty_games',
      name: 'Ветеран',
      description: 'Сыграйте 50 матчей',
      icon: Icons.military_tech_rounded,
      rarity: AchievementRarity.rare,
    ),
    Achievement(
      id: 'community_creator',
      name: 'Основатель',
      description: 'Создайте собственное сообщество',
      icon: Icons.groups_rounded,
      rarity: AchievementRarity.common,
    ),
    Achievement(
      id: 'winning_streak',
      name: 'Непобедимый',
      description: 'Выиграйте 5 матчей подряд',
      icon: Icons.bolt_rounded,
      rarity: AchievementRarity.epic,
    ),
    Achievement(
      id: 'motm',
      name: 'MVP',
      description: 'Получите звание лучшего игрока матча',
      icon: Icons.star_rounded,
      rarity: AchievementRarity.rare,
    ),
    Achievement(
      id: 'five_motm',
      name: 'Золотой игрок',
      description: 'Получите MVP 5 раз',
      icon: Icons.emoji_events_rounded,
      rarity: AchievementRarity.legendary,
    ),
  ];

  // ========== ФУТБОЛ ==========
  static const List<Achievement> football = [
    Achievement(
      id: 'fb_first_goal',
      name: 'Первый гол',
      description: 'Забейте свой первый гол',
      icon: Icons.sports_soccer,
      rarity: AchievementRarity.common,
      sport: SportCategory.football,
    ),
    Achievement(
      id: 'fb_hat_trick',
      name: 'Хет-трик',
      description: 'Забейте 3 гола в одном матче',
      icon: Icons.looks_3_rounded,
      rarity: AchievementRarity.rare,
      sport: SportCategory.football,
    ),
    Achievement(
      id: 'fb_assist_king',
      name: 'Ассист-Король',
      description: 'Сделайте 5 голевых передач за один матч',
      icon: Icons.handshake_rounded,
      rarity: AchievementRarity.epic,
      sport: SportCategory.football,
    ),
    Achievement(
      id: 'fb_ten_goals',
      name: 'Снайпер',
      description: 'Забейте 10 голов всего',
      icon: Icons.gps_fixed_rounded,
      rarity: AchievementRarity.common,
      sport: SportCategory.football,
    ),
    Achievement(
      id: 'fb_fifty_goals',
      name: 'Легенда поля',
      description: 'Забейте 50 голов',
      icon: Icons.local_fire_department_rounded,
      rarity: AchievementRarity.legendary,
      sport: SportCategory.football,
    ),
    Achievement(
      id: 'fb_clean_sheet',
      name: 'Сухарь',
      description: 'Не пропустите ни одного гола (вратарь)',
      icon: Icons.shield_rounded,
      rarity: AchievementRarity.epic,
      sport: SportCategory.football,
    ),
    Achievement(
      id: 'fb_golden_ball',
      name: 'Золотой мяч',
      description: 'Получите MVP 5 раз в футболе',
      icon: Icons.sports_soccer,
      rarity: AchievementRarity.legendary,
      sport: SportCategory.football,
    ),
  ];

  // ========== ХОККЕЙ ==========
  static const List<Achievement> hockey = [
    Achievement(
      id: 'hk_first_goal',
      name: 'Первая шайба',
      description: 'Забросьте свою первую шайбу',
      icon: Icons.sports_hockey,
      rarity: AchievementRarity.common,
      sport: SportCategory.hockey,
    ),
    Achievement(
      id: 'hk_hat_trick',
      name: 'Хет-трик на льду',
      description: 'Забросьте 3 шайбы в одном матче',
      icon: Icons.looks_3_rounded,
      rarity: AchievementRarity.rare,
      sport: SportCategory.hockey,
    ),
    Achievement(
      id: 'hk_enforcer',
      name: 'Тафгай',
      description: 'Проведите 10 силовых приёмов',
      icon: Icons.sports_mma,
      rarity: AchievementRarity.rare,
      sport: SportCategory.hockey,
    ),
    Achievement(
      id: 'hk_shutout',
      name: 'Стена',
      description: 'Отстойте на ноль (вратарь)',
      icon: Icons.security_rounded,
      rarity: AchievementRarity.epic,
      sport: SportCategory.hockey,
    ),
    Achievement(
      id: 'hk_playmaker',
      name: 'Плеймейкер',
      description: 'Сделайте 20 голевых передач',
      icon: Icons.swap_calls_rounded,
      rarity: AchievementRarity.epic,
      sport: SportCategory.hockey,
    ),
    Achievement(
      id: 'hk_legend',
      name: 'Легенда льда',
      description: 'Забросьте 50 шайб',
      icon: Icons.ac_unit_rounded,
      rarity: AchievementRarity.legendary,
      sport: SportCategory.hockey,
    ),
  ];

  // ========== ТЕННИС ==========
  static const List<Achievement> tennis = [
    Achievement(
      id: 'tn_first_ace',
      name: 'Первый эйс',
      description: 'Выполните свой первый эйс',
      icon: Icons.sports_tennis,
      rarity: AchievementRarity.common,
      sport: SportCategory.tennis,
    ),
    Achievement(
      id: 'tn_straight_sets',
      name: 'Чистая победа',
      description: 'Выиграйте матч без потери сета',
      icon: Icons.auto_awesome_rounded,
      rarity: AchievementRarity.rare,
      sport: SportCategory.tennis,
    ),
    Achievement(
      id: 'tn_comeback_king',
      name: 'Камбэк',
      description: 'Выиграйте матч проигрывая 0-1 по сетам',
      icon: Icons.trending_up_rounded,
      rarity: AchievementRarity.epic,
      sport: SportCategory.tennis,
    ),
    Achievement(
      id: 'tn_ten_aces',
      name: 'Сервис-бомба',
      description: 'Выполните 10 эйсов за карьеру',
      icon: Icons.flash_on_rounded,
      rarity: AchievementRarity.common,
      sport: SportCategory.tennis,
    ),
    Achievement(
      id: 'tn_grand_slam',
      name: 'Шлем',
      description: 'Выиграйте 20 матчей',
      icon: Icons.emoji_events_rounded,
      rarity: AchievementRarity.legendary,
      sport: SportCategory.tennis,
    ),
  ];

  // ========== ПАДЛ ==========
  static const List<Achievement> padel = [
    Achievement(
      id: 'pd_first_serve',
      name: 'Первая подача',
      description: 'Сыграйте свой первый матч по падлу',
      icon: Icons.sports_tennis,
      rarity: AchievementRarity.common,
      sport: SportCategory.padel,
    ),
    Achievement(
      id: 'pd_smash_king',
      name: 'Смэш-король',
      description: 'Выполните 10 смэшей за матч',
      icon: Icons.flash_on_rounded,
      rarity: AchievementRarity.rare,
      sport: SportCategory.padel,
    ),
    Achievement(
      id: 'pd_wall_master',
      name: 'Мастер стенки',
      description: 'Выиграйте розыгрыш от стеклянной стены 5 раз',
      icon: Icons.dashboard_rounded,
      rarity: AchievementRarity.rare,
      sport: SportCategory.padel,
    ),
    Achievement(
      id: 'pd_golden_point',
      name: 'Золотой пойнт',
      description: 'Выиграйте решающий гейм с 0-40',
      icon: Icons.emoji_events_rounded,
      rarity: AchievementRarity.epic,
      sport: SportCategory.padel,
    ),
    Achievement(
      id: 'pd_duo_master',
      name: 'Идеальный дуэт',
      description: 'Выиграйте 10 матчей с одним и тем же партнером',
      icon: Icons.handshake_rounded,
      rarity: AchievementRarity.epic,
      sport: SportCategory.padel,
    ),
    Achievement(
      id: 'pd_padel_legend',
      name: 'Легенда падла',
      description: 'Выиграйте 50 матчей по падлу',
      icon: Icons.diamond_rounded,
      rarity: AchievementRarity.legendary,
      sport: SportCategory.padel,
    ),
  ];

  // ========== КИБЕРСПОРТ ==========
  static const List<Achievement> esports = [
    Achievement(
      id: 'es_first_kill',
      name: 'Первая кровь',
      description: 'Получите первое убийство в матче',
      icon: Icons.sports_esports,
      rarity: AchievementRarity.common,
      sport: SportCategory.esports,
    ),
    Achievement(
      id: 'es_clutch',
      name: 'Клатч',
      description: 'Выиграйте раунд 1v3 или сложнее',
      icon: Icons.psychology_rounded,
      rarity: AchievementRarity.epic,
      sport: SportCategory.esports,
    ),
    Achievement(
      id: 'es_ace',
      name: 'Эйс',
      description: 'Убейте всю команду противника в одном раунде',
      icon: Icons.whatshot_rounded,
      rarity: AchievementRarity.rare,
      sport: SportCategory.esports,
    ),
    Achievement(
      id: 'es_headshot_king',
      name: 'Хедшот-машина',
      description: 'Достигните 60%+ хедшотов за матч',
      icon: Icons.adjust_rounded,
      rarity: AchievementRarity.rare,
      sport: SportCategory.esports,
    ),
    Achievement(
      id: 'es_streak_master',
      name: 'Стрик-мастер',
      description: 'Выиграйте 10 матчей подряд',
      icon: Icons.trending_up_rounded,
      rarity: AchievementRarity.epic,
      sport: SportCategory.esports,
    ),
    Achievement(
      id: 'es_cyber_legend',
      name: 'Кибер-легенда',
      description: 'Достигните 100 побед',
      icon: Icons.diamond_rounded,
      rarity: AchievementRarity.legendary,
      sport: SportCategory.esports,
    ),
  ];

  /// Все достижения для конкретного вида спорта (включая общие)
  static List<Achievement> forSport(SportCategory sport) {
    final sportSpecific = switch (sport) {
      SportCategory.football => football,
      SportCategory.hockey => hockey,
      SportCategory.tennis => tennis,
      SportCategory.padel => padel,
      SportCategory.esports => esports,
    };
    return [...general, ...sportSpecific];
  }

  /// Только общие достижения
  static List<Achievement> get allGeneral => general;

  /// Все достижения вообще
  static List<Achievement> get all =>
      [...general, ...football, ...hockey, ...tennis, ...padel, ...esports];
}
