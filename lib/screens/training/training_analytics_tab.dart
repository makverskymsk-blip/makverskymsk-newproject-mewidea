import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/training_provider.dart';
import '../../theme/app_colors.dart';

/// Analytics tab content — charts & stats.
class TrainingAnalyticsTab extends StatelessWidget {
  const TrainingAnalyticsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppColors.of(context);
    final training = context.watch<TrainingProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Summary Cards ───
          _buildSummaryRow(t, training),
          const SizedBox(height: 20),

          // ─── Tonnage Chart ───
          _sectionTitle(t, '📈 Тоннаж по тренировкам'),
          const SizedBox(height: 10),
          _buildTonnageChart(t, training),
          const SizedBox(height: 24),

          // ─── Weekly Distribution ───
          _sectionTitle(t, '📅 Тренировки по дням'),
          const SizedBox(height: 10),
          _buildWeekdayChart(t, training),
          const SizedBox(height: 24),

          // ─── Muscle Pie ───
          _sectionTitle(t, '💪 Группы мышц'),
          const SizedBox(height: 10),
          _buildMusclePie(t, training),
          const SizedBox(height: 24),

          // ─── XP Chart ───
          _sectionTitle(t, '⭐ XP за тренировки'),
          const SizedBox(height: 10),
          _buildXpChart(t, training),
          const SizedBox(height: 24),

          // ─── Best Session ───
          _buildBestSession(t, training),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  //  SUMMARY ROW
  // ═══════════════════════════════════════════════

  Widget _buildSummaryRow(AppThemeColors t, TrainingProvider training) {
    return Row(
      children: [
        _summaryCard(t, 'Ср. время', '${training.avgDurationMin.toStringAsFixed(0)} мин',
            Icons.timer_rounded, const Color(0xFF4A90D9)),
        const SizedBox(width: 10),
        _summaryCard(t, 'Ср. тоннаж', '${training.avgTonnage.toStringAsFixed(0)} кг',
            Icons.fitness_center_rounded, const Color(0xFFFF6B35)),
        const SizedBox(width: 10),
        _summaryCard(t, 'Всего XP', '${training.xp + (training.xpForNextLevel * (training.level - 1))}',
            Icons.star_rounded, const Color(0xFFFFAB00)),
      ],
    );
  }

  Widget _summaryCard(
      AppThemeColors t, String label, String value, IconData icon, Color accent) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: t.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: t.borderLight),
        ),
        child: Column(
          children: [
            Icon(icon, color: accent, size: 20),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: t.textPrimary)),
            Text(label,
                style: TextStyle(color: t.textHint, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  //  TONNAGE LINE CHART
  // ═══════════════════════════════════════════════

  Widget _buildTonnageChart(AppThemeColors t, TrainingProvider training) {
    final data = training.tonnageHistory();
    if (data.isEmpty) return _emptyChart(t, 'Завершите тренировку для графика');

    final spots = data.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.value);
    }).toList();

    final maxY = spots.fold(0.0, (m, s) => s.y > m ? s.y : m);

    return Container(
      height: 200,
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
      decoration: BoxDecoration(
        color: t.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.borderLight),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY > 0 ? maxY / 4 : 1,
            getDrawingHorizontalLine: (v) => FlLine(
              color: t.borderLight,
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 46,
                getTitlesWidget: (v, _) => Text(
                  '${v.toInt()}',
                  style: TextStyle(color: t.textHint, fontSize: 10),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i < 0 || i >= data.length) return const SizedBox();
                  final d = data[i].key;
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${(d.year % 100).toString().padLeft(2, '0')}',
                        style: TextStyle(color: t.textHint, fontSize: 8,
                            fontWeight: FontWeight.w600)),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: const Color(0xFFFF6B35),
              barWidth: 3,
              dotData: FlDotData(
                show: true,
                getDotPainter: (s, _, __, ___) => FlDotCirclePainter(
                  radius: 4,
                  color: const Color(0xFFFF6B35),
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFFFF6B35).withValues(alpha: 0.3),
                    const Color(0xFFFF6B35).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  //  WEEKDAY BAR CHART
  // ═══════════════════════════════════════════════

  Widget _buildWeekdayChart(AppThemeColors t, TrainingProvider training) {
    final data = training.sessionsPerWeekday();
    final maxY = data.values.fold(0, (m, v) => v > m ? v : m).toDouble();

    const days = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

    return Container(
      height: 180,
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
      decoration: BoxDecoration(
        color: t.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.borderLight),
      ),
      child: BarChart(
        BarChartData(
          maxY: maxY > 0 ? maxY + 1 : 5,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 1,
            getDrawingHorizontalLine: (v) => FlLine(
              color: t.borderLight,
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (v, _) => Text(
                  '${v.toInt()}',
                  style: TextStyle(color: t.textHint, fontSize: 10),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) => Text(
                  days[v.toInt().clamp(0, 6)],
                  style: TextStyle(
                    color: t.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(7, (i) {
            final count = data[i + 1] ?? 0;
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: count.toDouble(),
                  width: 20,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                  gradient: count > 0
                      ? const LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Color(0xFFFF6B35), Color(0xFFFF3D00)],
                        )
                      : null,
                  color: count == 0 ? t.borderLight : null,
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  //  MUSCLE PIE CHART
  // ═══════════════════════════════════════════════

  static const _muscleColors = <String, Color>{
    'Грудь': Color(0xFFFF6B35),
    'Спина': Color(0xFF4A90D9),
    'Плечи': Color(0xFFFFAB00),
    'Бицепс': Color(0xFF00C853),
    'Трицепс': Color(0xFF9C27B0),
    'Ноги': Color(0xFFE53935),
    'Пресс': Color(0xFF00BCD4),
    'Кардио': Color(0xFFFF4081),
  };

  Widget _buildMusclePie(AppThemeColors t, TrainingProvider training) {
    final data = training.muscleGroupDistribution();
    if (data.isEmpty) return _emptyChart(t, 'Добавьте упражнения в библиотеку');

    final total = data.values.fold(0, (s, v) => s + v);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.borderLight),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            height: 140,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 30,
                sections: data.entries.map((e) {
                  final pct = (e.value / total * 100).round();
                  return PieChartSectionData(
                    value: e.value.toDouble(),
                    color: _muscleColors[e.key] ?? Colors.grey,
                    title: '$pct%',
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                    radius: 36,
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: data.entries.map((e) {
                final color = _muscleColors[e.key] ?? Colors.grey;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(e.key,
                            style: TextStyle(
                                color: t.textPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ),
                      Text('${e.value}',
                          style: TextStyle(
                              color: t.textHint,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  //  XP LINE CHART
  // ═══════════════════════════════════════════════

  Widget _buildXpChart(AppThemeColors t, TrainingProvider training) {
    final data = training.xpHistory();
    if (data.isEmpty) return _emptyChart(t, 'Завершите тренировку для графика');

    final spots = data.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.value.toDouble());
    }).toList();

    return Container(
      height: 180,
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
      decoration: BoxDecoration(
        color: t.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.borderLight),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (v) => FlLine(
              color: t.borderLight,
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (v, _) => Text(
                  '${v.toInt()}',
                  style: TextStyle(color: t.textHint, fontSize: 10),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) {
                  if (v.toInt() >= data.length) return const SizedBox();
                  return Text('#${v.toInt() + 1}',
                      style: TextStyle(color: t.textHint, fontSize: 9));
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: const Color(0xFF00FF88),
              barWidth: 3,
              dotData: FlDotData(
                show: true,
                getDotPainter: (s, _, __, ___) => FlDotCirclePainter(
                  radius: 4,
                  color: const Color(0xFF00C853),
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF00FF88).withValues(alpha: 0.25),
                    const Color(0xFF00FF88).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  //  BEST SESSION
  // ═══════════════════════════════════════════════

  Widget _buildBestSession(AppThemeColors t, TrainingProvider training) {
    final best = training.bestSession;
    if (best == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A1A2E),
            const Color(0xFF16213E),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFAB00).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFAB00).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.emoji_events_rounded,
                color: Color(0xFFFFAB00), size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🏆 Лучшая тренировка',
                    style: TextStyle(
                      color: Color(0xFFFFAB00),
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    )),
                const SizedBox(height: 4),
                Text(
                  best.name.isEmpty ? 'Тренировка' : best.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                Text(
                  '${best.totalTonnage.toStringAsFixed(0)} кг • '
                  '${best.totalSets} подходов • '
                  '${best.durationMin} мин',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF00FF88).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '+${best.xpEarned} XP',
              style: const TextStyle(
                color: Color(0xFF00C853),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  //  HELPERS
  // ═══════════════════════════════════════════════

  Widget _sectionTitle(AppThemeColors t, String title) {
    return Text(title,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 16,
          color: t.textPrimary,
        ));
  }

  Widget _emptyChart(AppThemeColors t, String text) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: t.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.borderLight),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.analytics_rounded,
                size: 36, color: t.textHint.withValues(alpha: 0.3)),
            const SizedBox(height: 8),
            Text(text, style: TextStyle(color: t.textHint, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
