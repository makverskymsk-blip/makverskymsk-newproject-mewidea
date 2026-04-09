import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/training_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/body_heatmap.dart';

/// Analytics tab content — charts & stats.
class TrainingAnalyticsTab extends StatefulWidget {
  const TrainingAnalyticsTab({super.key});

  @override
  State<TrainingAnalyticsTab> createState() => _TrainingAnalyticsTabState();
}

class _TrainingAnalyticsTabState extends State<TrainingAnalyticsTab> {
  bool _heatmapShowFront = true;

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

  @override
  Widget build(BuildContext context) {
    final t = AppColors.of(context);
    final training = context.watch<TrainingProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── 1. Summary Cards ───
          _buildSummaryRow(t, training),
          const SizedBox(height: 20),

          // ─── 2. Cardio Comparison Chart ───
          _sectionTitle(t, '🏃 Кардио — сравнение'),
          const SizedBox(height: 10),
          _buildCardioComparisonChart(t, training),
          const SizedBox(height: 24),

          // ─── 3. Tonnage Chart ───
          _sectionTitle(t, '📈 Тоннаж по тренировкам'),
          const SizedBox(height: 10),
          _buildTonnageChart(t, training),
          const SizedBox(height: 24),

          // ─── 4. Weekly Activity ───
          _sectionTitle(t, '📅 Активность по дням'),
          const SizedBox(height: 10),
          _buildWeekdayChart(t, training),
          const SizedBox(height: 24),

          // ─── 5. Muscle Groups + Duration (side by side) ───
          _sectionTitle(t, '💪 Нагрузка & Длительность'),
          const SizedBox(height: 10),
          _buildMuscleAndDurationRow(t, training),
          const SizedBox(height: 24),

          // ─── 6. Best Session ───
          _buildBestSession(t, training),
          const SizedBox(height: 24),

          // ─── 7. Heatmap (bottom) ───
          _sectionTitle(t, '🔥 Тепловая карта нагрузки'),
          const SizedBox(height: 10),
          _buildHeatmapSection(t, training),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  //  1. SUMMARY CARDS
  // ═══════════════════════════════════════════════

  Widget _buildSummaryRow(AppThemeColors t, TrainingProvider training) {
    return Row(
      children: [
        _summaryCard(t, 'Тренировки', '${training.completedSessionCount}',
            Icons.fitness_center_rounded, const Color(0xFFFF6B35)),
        const SizedBox(width: 8),
        _summaryCard(
            t,
            'Тоннаж',
            '${(training.lifetimeTonnage / 1000).toStringAsFixed(1)}т',
            Icons.monitor_weight_outlined,
            const Color(0xFF4A90D9)),
        const SizedBox(width: 8),
        _summaryCard(t, 'Время', _formatTotalTime(training.lifetimeMinutes),
            Icons.timer_rounded, const Color(0xFF00C853)),
        const SizedBox(width: 8),
        _summaryCard(
            t,
            'Дистанция',
            '${training.totalCardioDistance.toStringAsFixed(1)} км',
            Icons.directions_run_rounded,
            const Color(0xFFFF4081)),
      ],
    );
  }

  String _formatTotalTime(int mins) {
    if (mins < 60) return '$mins м';
    final h = mins ~/ 60;
    final m = mins % 60;
    return '${h}ч ${m}м';
  }

  Widget _summaryCard(AppThemeColors t, String label, String value,
      IconData icon, Color accent) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              t.cardBg,
              t.isDark
                  ? t.cardBg.withValues(alpha: 0.9)
                  : t.surfaceBg.withValues(alpha: 0.3),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: t.borderLight.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: t.isDark
                  ? Colors.black.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
              spreadRadius: -2,
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: accent, size: 16),
            ),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: t.textPrimary)),
            Text(label,
                style: TextStyle(color: t.textHint, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  //  2. CARDIO COMPARISON LINE CHART
  // ═══════════════════════════════════════════════

  Widget _buildCardioComparisonChart(
      AppThemeColors t, TrainingProvider training) {
    final data = training.cardioComparisonData();
    if (data.isEmpty) {
      return _emptyChart(t, 'Завершите кардио-тренировку для графика');
    }

    const Color currentColor = Color(0xFF00E676); // Green - current
    const Color previousColor = Color(0xFF42A5F5); // Blue - previous

    // Build FlSpots from data
    final currentSpots = data[0]
        .map((e) => FlSpot(e.key, e.value))
        .toList();

    final previousSpots = data.length > 1
        ? data[1].map((e) => FlSpot(e.key, e.value)).toList()
        : <FlSpot>[];

    // Calculate max values for axes
    final allSpots = [...currentSpots, ...previousSpots];
    final maxX = allSpots.fold(0.0, (m, s) => s.x > m ? s.x : m);
    final maxY = allSpots.fold(0.0, (m, s) => s.y > m ? s.y : m);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _deepDecoration(t),
      child: Column(
        children: [
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendItem('Последняя', currentColor),
              const SizedBox(width: 20),
              if (previousSpots.isNotEmpty)
                _legendItem('Предыдущая', previousColor),
            ],
          ),
          const SizedBox(height: 12),
          // Chart
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY > 0 ? (maxY / 4).clamp(0.5, 100) : 1,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: t.borderLight,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    axisNameWidget: Text('км',
                        style: TextStyle(color: t.textHint, fontSize: 10)),
                    axisNameSize: 16,
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      getTitlesWidget: (v, _) => Text(
                        v.toStringAsFixed(1),
                        style: TextStyle(color: t.textHint, fontSize: 9),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    axisNameWidget: Text('мин',
                        style: TextStyle(color: t.textHint, fontSize: 10)),
                    axisNameSize: 16,
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: maxX > 0 ? (maxX / 5).clamp(1, 60) : 5,
                      getTitlesWidget: (v, _) => Text(
                        '${v.toInt()}',
                        style: TextStyle(color: t.textHint, fontSize: 9),
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: maxX > 0 ? maxX * 1.05 : 10,
                minY: 0,
                maxY: maxY > 0 ? maxY * 1.1 : 5,
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) =>
                        t.cardBg.withValues(alpha: 0.95),
                    getTooltipItems: (spots) {
                      return spots.map((spot) {
                        final isGreen = spot.barIndex == 0;
                        return LineTooltipItem(
                          '${spot.y.toStringAsFixed(1)} км\n${spot.x.toStringAsFixed(0)} мин',
                          TextStyle(
                            color: isGreen ? currentColor : previousColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                lineBarsData: [
                  // Current session — green, bright, thick
                  LineChartBarData(
                    spots: currentSpots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: currentColor,
                    barWidth: 3.5,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (s, d, bar, idx) => FlDotCirclePainter(
                        radius: 4,
                        color: currentColor,
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
                          currentColor.withValues(alpha: 0.25),
                          currentColor.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                  // Previous session — blue, dimmer, thinner
                  if (previousSpots.isNotEmpty)
                    LineChartBarData(
                      spots: previousSpots,
                      isCurved: true,
                      curveSmoothness: 0.35,
                      color: previousColor.withValues(alpha: 0.6),
                      barWidth: 2,
                      dashArray: [8, 4],
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (s, d, bar, idx) => FlDotCirclePainter(
                          radius: 3,
                          color: previousColor,
                          strokeWidth: 1.5,
                          strokeColor: Colors.white,
                        ),
                      ),
                      belowBarData: BarAreaData(show: false),
                    ),
                ],
              ),
            ),
          ),
          // Summary under chart
          const SizedBox(height: 12),
          _buildCardioSummary(t, data, currentColor, previousColor),
        ],
      ),
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            )),
      ],
    );
  }

  Widget _buildCardioSummary(AppThemeColors t,
      List<List<MapEntry<double, double>>> data, Color current, Color previous) {
    final curLast = data[0].last;
    final prevLast = data.length > 1 ? data[1].last : null;

    return Row(
      children: [
        Expanded(
          child: _cardioStatBlock(
            t,
            'Последняя',
            '${curLast.value.toStringAsFixed(1)} км',
            '${curLast.key.toStringAsFixed(0)} мин',
            current,
          ),
        ),
        if (prevLast != null) ...[
          const SizedBox(width: 8),
          Expanded(
            child: _cardioStatBlock(
              t,
              'Предыдущая',
              '${prevLast.value.toStringAsFixed(1)} км',
              '${prevLast.key.toStringAsFixed(0)} мин',
              previous,
            ),
          ),
        ],
        if (prevLast != null) ...[
          const SizedBox(width: 8),
          Expanded(
            child: _cardioStatBlock(
              t,
              'Разница',
              _diffLabel(curLast.value - prevLast.value, 'км'),
              _diffLabel(curLast.key - prevLast.key, 'мин'),
              curLast.value >= prevLast.value
                  ? const Color(0xFF00E676)
                  : Colors.red,
            ),
          ),
        ],
      ],
    );
  }

  String _diffLabel(double diff, String unit) {
    final sign = diff >= 0 ? '+' : '';
    return '$sign${diff.toStringAsFixed(1)} $unit';
  }

  Widget _cardioStatBlock(
      AppThemeColors t, String title, String line1, String line2, Color accent) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Text(title,
              style: TextStyle(
                  color: accent, fontSize: 10, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(line1,
              style: TextStyle(
                  color: t.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w800)),
          Text(line2,
              style: TextStyle(color: t.textHint, fontSize: 10)),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  //  3. TONNAGE LINE CHART
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
      decoration: _deepDecoration(t),
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
                        '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}',
                        style: TextStyle(
                            color: t.textHint,
                            fontSize: 9,
                            fontWeight: FontWeight.w600)),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
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
                getDotPainter: (s, d, bar, idx) => FlDotCirclePainter(
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
  //  4. WEEKDAY BAR CHART
  // ═══════════════════════════════════════════════

  Widget _buildWeekdayChart(AppThemeColors t, TrainingProvider training) {
    final data = training.sessionsPerWeekday();
    final maxY = data.values.fold(0, (m, v) => v > m ? v : m).toDouble();
    const days = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

    return Container(
      height: 160,
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
      decoration: _deepDecoration(t),
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
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
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
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(6)),
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
  //  5. MUSCLE GROUPS + DURATION (side by side)
  // ═══════════════════════════════════════════════

  Widget _buildMuscleAndDurationRow(
      AppThemeColors t, TrainingProvider training) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 3,
            child: _buildModernMuscleChart(t, training),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: _buildDurationChart(t, training),
          ),
        ],
      ),
    );
  }

  /// Modern horizontal bar chart for muscle groups
  Widget _buildModernMuscleChart(AppThemeColors t, TrainingProvider training) {
    final data = training.muscleGroupTonnageSorted();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _deepDecoration(t),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.fitness_center_rounded,
                  color: t.textHint, size: 14),
              const SizedBox(width: 6),
              Text('Мышцы (тоннаж)',
                  style: TextStyle(
                      color: t.textHint,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          if (data.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text('Нет данных',
                    style: TextStyle(color: t.textHint, fontSize: 12)),
              ),
            )
          else
            ...data.take(6).map((entry) {
              final maxVal = data.first.value;
              final ratio = maxVal > 0 ? entry.value / maxVal : 0.0;
              final color = _muscleColors[entry.key] ?? Colors.grey;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(entry.key,
                            style: TextStyle(
                                color: t.textPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                        Text('${entry.value.toStringAsFixed(0)} кг',
                            style: TextStyle(
                                color: t.textHint,
                                fontSize: 11,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Stack(
                        children: [
                          Container(
                            height: 8,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: ratio.clamp(0.05, 1.0),
                            child: Container(
                              height: 8,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    color.withValues(alpha: 0.7),
                                    color,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  /// Session duration mini chart
  Widget _buildDurationChart(AppThemeColors t, TrainingProvider training) {
    final data = training.sessionDurations(last: 8);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _deepDecoration(t),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timer_rounded, color: t.textHint, size: 14),
              const SizedBox(width: 6),
              Text('Время (мин)',
                  style: TextStyle(
                      color: t.textHint,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          if (data.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: Center(
                child: Text('Нет данных',
                    style: TextStyle(color: t.textHint, fontSize: 12)),
              ),
            )
          else
            Expanded(
              child: BarChart(
                BarChartData(
                  maxY: data
                              .map((e) => e.value)
                              .reduce((a, b) => a > b ? a : b)
                              .toDouble() +
                          10,
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (v, _) => Text(
                          '${v.toInt()}',
                          style: TextStyle(color: t.textHint, fontSize: 9),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, _) {
                          final i = v.toInt();
                          if (i < 0 || i >= data.length)
                            return const SizedBox();
                          return Text('#${i + 1}',
                              style: TextStyle(
                                  color: t.textHint, fontSize: 8));
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: data.asMap().entries.map((e) {
                    return BarChartGroupData(
                      x: e.key,
                      barRods: [
                        BarChartRodData(
                          toY: e.value.value.toDouble(),
                          width: 12,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4)),
                          gradient: const LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [Color(0xFF00BCD4), Color(0xFF00897B)],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  //  6. BEST SESSION
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
            t.cardBg,
            const Color(0xFFFFAB00).withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFAB00).withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFAB00).withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
            spreadRadius: -2,
          ),
          BoxShadow(
            color: t.isDark
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFAB00).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.emoji_events_rounded,
                color: Color(0xFFFFAB00), size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Лучшая тренировка',
                    style: TextStyle(
                      color: Color(0xFFFFAB00),
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    )),
                const SizedBox(height: 2),
                Text(
                  best.name.isEmpty ? 'Тренировка' : best.name,
                  style: TextStyle(
                    color: t.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${best.totalTonnage.toStringAsFixed(0)} кг • '
                  '${best.totalSets} подходов • '
                  '${best.durationMin.abs()} мин',
                  style: TextStyle(color: t.textHint, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B35).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${best.totalTonnage.toStringAsFixed(0)} кг',
              style: const TextStyle(
                color: Color(0xFFFF6B35),
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
  //  7. BODY HEATMAP (at the bottom)
  // ═══════════════════════════════════════════════

  Widget _buildHeatmapSection(AppThemeColors t, TrainingProvider training) {
    final data = training.muscleGroupTonnage();
    if (data.isEmpty) {
      return _emptyChart(t, 'Завершите тренировку для тепловой карты');
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _deepDecoration(t),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _heatmapToggle(t, 'Спереди', _heatmapShowFront, () {
                setState(() => _heatmapShowFront = true);
              }),
              const SizedBox(width: 8),
              _heatmapToggle(t, 'Сзади', !_heatmapShowFront, () {
                setState(() => _heatmapShowFront = false);
              }),
            ],
          ),
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            transitionBuilder: (child, animation) =>
                FadeTransition(opacity: animation, child: child),
            child: BodyHeatmap(
              key: ValueKey(_heatmapShowFront),
              muscleData: data,
              showFront: _heatmapShowFront,
            ),
          ),
        ],
      ),
    );
  }

  Widget _heatmapToggle(
      AppThemeColors t, String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? const Color(0xFFFF6B35).withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active
                ? const Color(0xFFFF6B35).withValues(alpha: 0.5)
                : t.borderLight,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? const Color(0xFFFF6B35) : t.textHint,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
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

  /// Shared elevated card decoration with depth
  BoxDecoration _deepDecoration(AppThemeColors t, {double radius = 16}) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          t.cardBg,
          t.isDark
              ? t.cardBg.withValues(alpha: 0.92)
              : t.surfaceBg.withValues(alpha: 0.3),
        ],
      ),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: t.borderLight.withValues(alpha: 0.5)),
      boxShadow: [
        BoxShadow(
          color: t.isDark
              ? Colors.black.withValues(alpha: 0.22)
              : Colors.black.withValues(alpha: 0.06),
          blurRadius: 16,
          offset: const Offset(0, 6),
          spreadRadius: -4,
        ),
        BoxShadow(
          color: t.isDark
              ? Colors.black.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.02),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ],
    );
  }

  Widget _emptyChart(AppThemeColors t, String text) {
    return Container(
      height: 140,
      decoration: _deepDecoration(t),
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
