import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/enums.dart';
import '../../providers/sport_prefs_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/stats_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/player_fifa_card.dart';
import '../../widgets/achievement_badge.dart';

class PlayerStatsScreen extends StatefulWidget {
  const PlayerStatsScreen({super.key});

  @override
  State<PlayerStatsScreen> createState() => _PlayerStatsScreenState();
}

class _PlayerStatsScreenState extends State<PlayerStatsScreen> {
  SportCategory _selectedSport = SportCategory.football;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final statsProv = context.watch<StatsProvider>();
    final user = auth.currentUser;
    final userId = user?.id ?? '';
    final overall = statsProv.getPlayerStatsForSport(userId, _selectedSport);
    final achievements =
        statsProv.getAchievementsForSport(userId, _selectedSport);
    final matchHistory = statsProv.getMatchHistoryRecords(userId);
    final unlockedCount =
        statsProv.getUnlockedCount(userId, _selectedSport);
    final totalCount = statsProv.getTotalCount(_selectedSport);

    return Scaffold(
      body: Stack(
        children: [
          Container(color: AppColors.of(context).scaffoldBg),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  // Header
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.borderLight.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 18),
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Text(
                          'Спортивная карточка',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Sport selector
                  _sportSelector(),
                  const SizedBox(height: 28),

                  // FIFA Card centered — sport-specific!
                  Center(
                    child: PlayerFifaCard(
                      playerName: user?.name ?? 'Игрок',
                      position: user?.position ?? 'НАП',
                      stats: overall,
                      sport: _selectedSport,
                      isPremium: user?.isPremium ?? false,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Quick stats
                  Row(
                    children: [
                      Expanded(
                          child: _quickStat(
                              'Матчи', '${overall.totalGames}')),
                      const SizedBox(width: 10),
                      Expanded(
                          child: _quickStat(
                              _goalLabel(_selectedSport),
                              '${overall.totalGoals}')),
                      const SizedBox(width: 10),
                      Expanded(
                          child: _quickStat(
                              _assistLabel(_selectedSport),
                              '${overall.totalAssists}')),
                      const SizedBox(width: 10),
                      Expanded(
                          child:
                              _quickStat('MVP', '${overall.totalMotm}')),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Win rate card
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Статистика побед',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15)),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _winLossStat(
                                'Победы', overall.winCount,
                                AppColors.success),
                            const SizedBox(width: 16),
                            _winLossStat(
                                'Ничьи', overall.drawCount,
                                AppColors.warning),
                            const SizedBox(width: 16),
                            _winLossStat(
                                'Поражения', overall.lossCount,
                                AppColors.error),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Text('Винрейт',
                                style: TextStyle(
                                    color: AppColors.textSecondary)),
                            const Spacer(),
                            Text(
                              '${overall.winRate.toStringAsFixed(1)}%',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: AppColors.accent,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: overall.winRate / 100,
                            backgroundColor: AppColors.borderLight,
                            valueColor: const AlwaysStoppedAnimation(
                                AppColors.accent),
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Achievements header
                  Row(
                    children: [
                      Icon(_selectedSport.icon,
                          size: 22, color: AppColors.primaryLight),
                      const SizedBox(width: 8),
                      Text(
                        'Достижения • ${_selectedSport.displayName}',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color:
                              AppColors.primaryLight.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          '$unlockedCount / $totalCount',
                          style: const TextStyle(
                            color: AppColors.primaryLight,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Achievements grid
                  Wrap(
                    spacing: 14,
                    runSpacing: 18,
                    children: achievements
                        .map((a) => AchievementBadge(achievement: a))
                        .toList(),
                  ),
                  const SizedBox(height: 28),

                  // Match history header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Icon(Icons.history_rounded,
                            size: 16, color: AppColors.primary),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Последние матчи',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.of(context)
                              .surfaceBg
                              .withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                              color: AppColors.of(context).borderLight),
                        ),
                        child: Text(
                          '${matchHistory.length} игр',
                          style: TextStyle(
                            color: AppColors.of(context).textHint,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  if (matchHistory.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 24),
                        child: Column(
                          children: [
                            Icon(Icons.sports_score_rounded,
                                size: 48,
                                color: AppColors.of(context)
                                    .textHint
                                    .withValues(alpha: 0.2)),
                            const SizedBox(height: 10),
                            Text('Пока нет статистики',
                                style: TextStyle(
                                    color: AppColors.of(context).textHint,
                                    fontSize: 14)),
                          ],
                        ),
                      ),
                    )
                  else
                    ...matchHistory.reversed
                        .take(5)
                        .map((ms) => _matchTile(ms)),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============ SPORT SELECTOR ============

  Widget _sportSelector() {
    final t = AppColors.of(context);
    return SizedBox(
      height: 32,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: context.watch<SportPrefsProvider>().visibleSports.map((sport) {
          final isSelected = _selectedSport == sport;
          return GestureDetector(
            onTap: () {
              setState(() => _selectedSport = sport);
              final uid = context.read<AuthProvider>().uid;
              if (uid != null) {
                context.read<StatsProvider>().loadPlayerStatsForSport(uid, sport);
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient:
                    isSelected ? AppColors.primaryGradient : null,
                color: isSelected ? null : t.cardBg,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : t.borderLight,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 1),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: t.isDark
                              ? Colors.black.withValues(alpha: 0.15)
                              : Colors.black.withValues(alpha: 0.04),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
              ),
              child: Row(
                children: [
                  Icon(
                    sport.icon,
                    size: 13,
                    color: isSelected
                        ? Colors.white
                        : t.textHint,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    sport.displayName,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      color: isSelected
                          ? Colors.white
                          : t.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ============ HELPERS ============

  String _goalLabel(SportCategory sport) {
    return switch (sport) {
      SportCategory.football => 'Голы',
      SportCategory.hockey => 'Шайбы',
      SportCategory.tennis || SportCategory.padel => 'Эйсы',
      SportCategory.esports => 'Убийства',
    };
  }

  String _assistLabel(SportCategory sport) {
    return switch (sport) {
      SportCategory.football => 'Ассисты',
      SportCategory.hockey => 'Передачи',
      SportCategory.tennis || SportCategory.padel => 'Виннеры',
      SportCategory.esports => 'Ассисты',
    };
  }

  Widget _matchTile(Map<String, dynamic> ms) {
    final t = AppColors.of(context);
    final rating = (ms['overall_rating'] as num?)?.toDouble() ?? 6.0;
    final goals = ms['goals'] ?? 0;
    final assists = ms['assists'] ?? 0;
    final isMvp = ms['is_mvp'] == true;
    final isWin = ms['is_win'] == true;
    final isDraw = ms['is_draw'] == true;
    final createdAt = ms['created_at'] != null
        ? DateTime.tryParse(ms['created_at'].toString())
        : null;

    // Result color & label
    final Color resultColor;
    final String resultLabel;
    final IconData resultIcon;
    if (isWin) {
      resultColor = const Color(0xFF00E676);
      resultLabel = 'Победа';
      resultIcon = Icons.emoji_events_rounded;
    } else if (isDraw) {
      resultColor = const Color(0xFFFFB300);
      resultLabel = 'Ничья';
      resultIcon = Icons.handshake_rounded;
    } else {
      resultColor = const Color(0xFFFF5252);
      resultLabel = 'Поражение';
      resultIcon = Icons.trending_down_rounded;
    }

    // Rating color
    final Color ratingColor = rating >= 8.0
        ? const Color(0xFF00E676)
        : rating >= 6.5
            ? const Color(0xFF66BB6A)
            : rating >= 5.0
                ? const Color(0xFFFFB300)
                : const Color(0xFFFF5252);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Stack(
        children: [
          // Main card body
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: t.cardBg.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: t.isDark
                      ? Colors.black.withValues(alpha: 0.15)
                      : Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // ── Left neon edge ──
                Container(
                  width: 3,
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        resultColor.withValues(alpha: 0.8),
                        resultColor.withValues(alpha: 0.2),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: resultColor.withValues(alpha: 0.4),
                        blurRadius: 6,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // ── Date column ──
                SizedBox(
                  width: 40,
                  child: Column(
                    children: [
                      Text(
                        createdAt != null
                            ? _relativeDate(createdAt)
                            : '—',
                        style: TextStyle(
                          color: t.textHint,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // ── Center: Stats ──
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stats row
                      Row(
                        children: [
                          // Goals badge
                          _statBadge(
                            icon: _goalIcon(_selectedSport),
                            value: goals.toString(),
                            color: goals > 0
                                ? const Color(0xFF00E676)
                                : t.textHint,
                          ),
                          const SizedBox(width: 6),
                          // Assists badge
                          _statBadge(
                            icon: Icons.sports_rounded,
                            value: assists.toString(),
                            color: assists > 0
                                ? const Color(0xFF42A5F5)
                                : t.textHint,
                          ),
                          const SizedBox(width: 6),
                          // MVP badge
                          if (isMvp) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFFD54F),
                                    Color(0xFFFFA726),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFFD54F)
                                        .withValues(alpha: 0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.star_rounded,
                                      size: 10, color: Colors.white),
                                  SizedBox(width: 2),
                                  Text('MVP',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                      )),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 5),
                      // Result label with sport icon
                      Row(
                        children: [
                          Icon(resultIcon, size: 12, color: resultColor.withValues(alpha: 0.7)),
                          const SizedBox(width: 4),
                          Text(
                            resultLabel,
                            style: TextStyle(
                              color: resultColor.withValues(alpha: 0.85),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'monospace',
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Right: Rating capsule — flat ──
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: ratingColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Center(
                    child: Text(
                      rating.toStringAsFixed(1),
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: ratingColor,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Subtle win gradient overlay
          if (isWin)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: RadialGradient(
                    center: Alignment.topLeft,
                    radius: 1.5,
                    colors: [
                      resultColor.withValues(alpha: 0.04),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _statBadge({
    required IconData icon,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: color,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  IconData _goalIcon(SportCategory sport) {
    return switch (sport) {
      SportCategory.football => Icons.sports_soccer_rounded,
      SportCategory.hockey => Icons.sports_hockey_rounded,
      SportCategory.tennis || SportCategory.padel => Icons.sports_tennis_rounded,
      SportCategory.esports => Icons.sports_esports_rounded,
    };
  }

  String _relativeDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} мин';
    if (diff.inHours < 24) return '${diff.inHours} ч';
    if (diff.inDays == 0) return 'Сегодня';
    if (diff.inDays == 1) return 'Вчера';
    if (diff.inDays < 7) return '${diff.inDays} дн';
    final months = [
      '', 'янв', 'фев', 'мар', 'апр', 'мая', 'июн',
      'июл', 'авг', 'сен', 'окт', 'ноя', 'дек',
    ];
    return '${dt.day}\n${months[dt.month]}';
  }

  String _goalEmoji(SportCategory sport) {
    return switch (sport) {
      SportCategory.football => '⚽',
      SportCategory.hockey => '🏒',
      SportCategory.tennis || SportCategory.padel => '🎾',
      SportCategory.esports => '🎮',
    };
  }


  Widget _quickStat(String label, String value) {
    return GlassCard(
      padding:
          const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      borderRadius: 16,
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textHint, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _winLossStat(String label, int count, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text('$count',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: color)),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }
}
