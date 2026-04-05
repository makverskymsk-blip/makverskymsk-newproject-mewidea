import 'package:flutter/material.dart';
import '../models/match_stats.dart';
import '../theme/app_colors.dart';
import 'radar_chart.dart';

class PlayerFifaCard extends StatefulWidget {
  final String playerName;
  final String position;
  final String positionFull;
  final PlayerOverallStats stats;
  final bool isPremium;
  final VoidCallback? onTap;

  const PlayerFifaCard({
    super.key,
    required this.playerName,
    required this.position,
    this.positionFull = '',
    required this.stats,
    this.isPremium = false,
    this.onTap,
  });

  @override
  State<PlayerFifaCard> createState() => _PlayerFifaCardState();
}

class _PlayerFifaCardState extends State<PlayerFifaCard> {
  bool _pressed = false;

  CardTier get _tier {
    final o = widget.stats.overallRating;
    if (widget.isPremium) return CardTier.legendary;
    if (o >= 85) return CardTier.top;
    if (o >= 70) return CardTier.strong;
    if (o >= 40) return CardTier.medium;
    return CardTier.weak;
  }

  @override
  Widget build(BuildContext context) {
    final tier = _tier;
    final overall = widget.stats.overallRating;
    final stats = widget.stats;

    // Position-based main stat
    final mainStat = _mainStatForPosition(widget.position);

    final radarEntries = [
      RadarEntry(label: 'ATK', value: stats.attackRating),
      RadarEntry(label: 'PAS', value: stats.passRating),
      RadarEntry(label: 'DEF', value: stats.defenseRating),
      RadarEntry(label: 'SPD', value: stats.staminaRating),
      RadarEntry(label: 'SKL', value: stats.skillRating),
    ];

    // Mock deltas for visual demo
    final deltas = {
      'ATK': 2,
      'PAS': -1,
      'DEF': 3,
      'SPD': 0,
      'SKL': 1,
    };

    // Progress to next tier
    final nextTier = tier.nextTier;
    final tierProgress = nextTier != null
        ? ((overall - tier.minRating) / (nextTier.minRating - tier.minRating)).clamp(0.0, 1.0)
        : 1.0;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.of(context).cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: tier.borderColor, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: tier.accentColor.withValues(alpha: 0.1),
                blurRadius: 24,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              // ─── Top section: Overall + Radar ───
              Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 12, 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      tier.accentColor.withValues(alpha: 0.04),
                      tier.accentColor.withValues(alpha: 0.01),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Overall + tier + position
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Overall number
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                overall.toString(),
                                style: TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.w900,
                                  color: tier.accentColor,
                                  height: 1,
                                ),
                              ),
                              // MVP fire icon
                              if (stats.totalMotm > 0)
                                Padding(
                                  padding: const EdgeInsets.only(
                                      left: 6, bottom: 6),
                                  child: Icon(
                                    Icons.local_fire_department_rounded,
                                    color: const Color(0xFFFF6D00),
                                    size: 22,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),

                          // Tier badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  tier.accentColor.withValues(alpha: 0.15),
                                  tier.accentColor.withValues(alpha: 0.05),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color:
                                      tier.accentColor.withValues(alpha: 0.2)),
                            ),
                            child: Text(
                              tier.label,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.5,
                                color: tier.accentColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Progress to next tier
                          if (nextTier != null)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: tierProgress,
                                          minHeight: 5,
                                          backgroundColor: tier.accentColor.withValues(alpha: 0.1),
                                          valueColor: AlwaysStoppedAnimation(tier.accentColor),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${nextTier.minRating - overall}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: tier.accentColor,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'до ${nextTier.label}',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: AppColors.textHint,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 10),

                          // Position tag
                          if (widget.position.isNotEmpty)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _positionIcon(widget.position),
                                  size: 14,
                                  color: tier.accentColor
                                      .withValues(alpha: 0.6),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  widget.positionFull.isNotEmpty
                                      ? widget.positionFull
                                      : widget.position,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: tier.accentColor.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),

                    // Radar chart (bigger)
                    RadarChart(
                      entries: radarEntries,
                      color: tier.accentColor,
                      size: 170,
                    ),
                  ],
                ),
              ),

              // ─── Divider ───
              Container(
                height: 1,
                color: tier.borderColor.withValues(alpha: 0.5),
              ),

              // ─── Bottom section: Key metrics ───
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Column(
                  children: [
                    // Key metrics row (no duplicate of radar stats)
                    Row(
                      children: [
                        _metricChip(
                          Icons.sports_soccer_rounded,
                          'Игры',
                          stats.totalGames.toString(),
                          tier,
                        ),
                        const SizedBox(width: 8),
                        _metricChip(
                          Icons.star_half_rounded,
                          'Средняя',
                          stats.avgRating.toStringAsFixed(1),
                          tier,
                        ),
                        const SizedBox(width: 8),
                        _metricChip(
                          Icons.emoji_events_rounded,
                          'MVP',
                          stats.totalMotm.toString(),
                          tier,
                          highlight: stats.totalMotm > 0,
                        ),
                        const SizedBox(width: 8),
                        _metricChip(
                          Icons.trending_up_rounded,
                          'Винрейт',
                          '${stats.winRate.toInt()}%',
                          tier,
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Stat deltas row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: radarEntries.map((e) {
                        final delta = deltas[e.label] ?? 0;
                        final isMain = e.label == mainStat;
                        return _statWithDelta(
                            e.label, e.value, delta, tier, isMain: isMain);
                      }).toList(),
                    ),

                    const SizedBox(height: 10),

                    // Tap hint
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.open_in_new_rounded,
                            size: 11,
                            color: tier.accentColor.withValues(alpha: 0.3)),
                        const SizedBox(width: 4),
                        Text(
                          'Подробная статистика',
                          style: TextStyle(
                            fontSize: 11,
                            color: tier.accentColor.withValues(alpha: 0.3),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metricChip(
      IconData icon, String label, String value, CardTier tier,
      {bool highlight = false}) {
    final t = AppColors.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: highlight
              ? const Color(0xFFFF6D00).withValues(alpha: 0.06)
              : tier.accentColor.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: highlight
                ? const Color(0xFFFF6D00).withValues(alpha: 0.15)
                : t.borderLight.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          children: [
            Icon(icon,
                size: 14,
                color: highlight
                    ? const Color(0xFFFF6D00)
                    : tier.accentColor.withValues(alpha: 0.6)),
            const SizedBox(height: 3),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: highlight
                    ? const Color(0xFFFF6D00)
                    : tier.accentColor,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                color: t.textHint,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statWithDelta(
      String label, int value, int delta, CardTier tier,
      {bool isMain = false}) {
    return Container(
      padding: isMain
          ? const EdgeInsets.symmetric(horizontal: 6, vertical: 4)
          : EdgeInsets.zero,
      decoration: isMain
          ? BoxDecoration(
              color: tier.accentColor.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: tier.accentColor.withValues(alpha: 0.15)),
            )
          : null,
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value.toString(),
                style: TextStyle(
                  fontSize: isMain ? 17 : 15,
                  fontWeight: FontWeight.w800,
                  color: tier.accentColor,
                ),
              ),
              if (delta != 0) ...[
                const SizedBox(width: 2),
                Icon(
                  delta > 0
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  size: 10,
                  color: delta > 0
                      ? const Color(0xFF43A047)
                      : const Color(0xFFE53935),
                ),
                Text(
                  delta.abs().toString(),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: delta > 0
                        ? const Color(0xFF43A047)
                        : const Color(0xFFE53935),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: TextStyle(
              fontSize: isMain ? 10 : 9,
              fontWeight: isMain ? FontWeight.w800 : FontWeight.w600,
              letterSpacing: 0.5,
              color: isMain ? tier.accentColor : tier.accentColor.withValues(alpha: 0.5),
            ),
          ),
          if (isMain)
            Text('★',
                style: TextStyle(
                    fontSize: 8, color: tier.accentColor)),
        ],
      ),
    );
  }

  IconData _positionIcon(String pos) {
    switch (pos) {
      case 'ST':
        return Icons.sports_soccer;
      case 'DF':
        return Icons.shield_rounded;
      case 'MF':
        return Icons.swap_horiz_rounded;
      case 'GK':
        return Icons.sports_handball_rounded;
      default:
        return Icons.person_rounded;
    }
  }

  /// Returns the primary stat label for a position
  String _mainStatForPosition(String pos) {
    switch (pos) {
      case 'ST': return 'ATK';
      case 'DF': return 'DEF';
      case 'MF': return 'PAS';
      case 'GK': return 'DEF';
      default:   return 'SKL';
    }
  }
}

enum CardTier {
  weak(
    label: 'НОВИЧОК',
    accentColor: Color(0xFF9E9E9E),
    borderColor: Color(0xFFE0E0E0),
    minRating: 0,
  ),
  medium(
    label: 'БРОНЗА',
    accentColor: Color(0xFF8D6E63),
    borderColor: Color(0xFFD7CCC8),
    minRating: 40,
  ),
  strong(
    label: 'СЕРЕБРО',
    accentColor: Color(0xFF546E7A),
    borderColor: Color(0xFFB0BEC5),
    minRating: 70,
  ),
  top(
    label: 'ЗОЛОТО',
    accentColor: Color(0xFFE6A817),
    borderColor: Color(0xFFFFE082),
    minRating: 85,
  ),
  legendary(
    label: 'ЛЕГЕНДА',
    accentColor: Color(0xFF7B1FA2),
    borderColor: Color(0xFFCE93D8),
    minRating: 99,
  );

  final String label;
  final Color accentColor;
  final Color borderColor;
  final int minRating;

  const CardTier({
    required this.label,
    required this.accentColor,
    required this.borderColor,
    required this.minRating,
  });

  /// Next tier after this one, null if already max
  CardTier? get nextTier {
    final vals = CardTier.values;
    final idx = vals.indexOf(this);
    return idx < vals.length - 1 ? vals[idx + 1] : null;
  }
}
