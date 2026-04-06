import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/enums.dart';
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
                            borderRadius: BorderRadius.circular(12),
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
                          borderRadius: BorderRadius.circular(8),
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

                  // Match history
                  const Text(
                    'Последние матчи',
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 16),

                  if (matchHistory.isEmpty)
                    const Center(
                      child: Text('Пока нет статистики',
                          style:
                              TextStyle(color: AppColors.textHint)),
                    )
                  else
                    ...matchHistory.reversed.take(5).map(
                        (ms) => _matchTile(ms)),

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
    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: SportCategory.values.map((sport) {
          final isSelected = _selectedSport == sport;
          return GestureDetector(
            onTap: () {
              setState(() => _selectedSport = sport);
              // Load sport-specific stats
              final uid = context.read<AuthProvider>().uid;
              if (uid != null) {
                context.read<StatsProvider>().loadPlayerStatsForSport(uid, sport);
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(
                  horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                gradient:
                    isSelected ? AppColors.primaryGradient : null,
                color: isSelected
                    ? null
                    : AppColors.borderLight.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : AppColors.borderLight,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary
                              .withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  Icon(
                    sport.icon,
                    size: 18,
                    color: isSelected
                        ? Colors.white
                        : AppColors.textHint,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    sport.displayName,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: isSelected
                          ? Colors.white
                          : AppColors.textSecondary,
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
      SportCategory.tennis => 'Эйсы',
      SportCategory.esports => 'Убийства',
    };
  }

  String _assistLabel(SportCategory sport) {
    return switch (sport) {
      SportCategory.football => 'Ассисты',
      SportCategory.hockey => 'Передачи',
      SportCategory.tennis => 'Виннеры',
      SportCategory.esports => 'Ассисты',
    };
  }

  Widget _matchTile(Map<String, dynamic> ms) {
    final rating = (ms['overall_rating'] as num?)?.toDouble() ?? 6.0;
    final goals = ms['goals'] ?? 0;
    final assists = ms['assists'] ?? 0;
    final isMvp = ms['is_mvp'] == true;
    final matchId = (ms['match_id'] ?? '').toString();
    final shortId = matchId.length > 6 ? matchId.substring(0, 6) : matchId;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.borderLight.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isMvp
                  ? AppColors.primaryLight.withValues(alpha: 0.15)
                  : AppColors.borderLight.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                rating.toStringAsFixed(1),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: rating >= 7
                      ? AppColors.success
                      : (rating >= 5
                          ? AppColors.primaryLight
                          : AppColors.error),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${_goalEmoji(_selectedSport)} $goals  🅰️ $assists',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    if (isMvp) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('MVP',
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryLight)),
                      ),
                    ],
                  ],
                ),
                Text(
                  'Матч #$shortId',
                  style: const TextStyle(
                    color: AppColors.textHint,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _goalEmoji(SportCategory sport) {
    return switch (sport) {
      SportCategory.football => '⚽',
      SportCategory.hockey => '🏒',
      SportCategory.tennis => '🎾',
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
