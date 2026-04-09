import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/training_provider.dart';
import '../../theme/app_colors.dart';
import 'active_workout_screen.dart';
import 'exercise_library_screen.dart';
import 'training_analytics_tab.dart';

class TrainingHubScreen extends StatefulWidget {
  const TrainingHubScreen({super.key});

  @override
  State<TrainingHubScreen> createState() => _TrainingHubScreenState();
}

class _TrainingHubScreenState extends State<TrainingHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _tabs = [
    _TabInfo('Dashboard', Icons.grid_view_rounded),
    _TabInfo('Lab', Icons.science_outlined),
    _TabInfo('Журнал', Icons.menu_book_outlined),
    _TabInfo('Аналитика', Icons.insights_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _startWorkout() async {
    final t = AppColors.of(context);
    final auth = context.read<AuthProvider>();
    final training = context.read<TrainingProvider>();
    final uid = auth.uid;
    if (uid == null) return;

    if (training.hasActiveSession) {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const ActiveWorkoutScreen()));
      return;
    }

    final name = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController();
        return AlertDialog(
          backgroundColor: t.dialogBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Новая тренировка',
              style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w700)),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: TextStyle(color: t.textPrimary),
            decoration: InputDecoration(
              hintText: 'Название (необязательно)',
              hintStyle: TextStyle(color: t.textHint),
              filled: true,
              fillColor: t.surfaceBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: t.borderLight),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: t.borderLight),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Отмена', style: TextStyle(color: t.textHint)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, controller.text),
              child: const Text('Старт',
                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
            ),
          ],
        );
      },
    );

    if (name == null) return;

    final ok = await training.startWorkout(uid, name);
    if (ok && mounted) {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const ActiveWorkoutScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppColors.of(context);
    final training = context.watch<TrainingProvider>();

    return Scaffold(
      backgroundColor: t.scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            // ─── Header ───
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                          spreadRadius: -2,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.fitness_center_rounded,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'ТРЕНИРОВКА',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      color: t.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _startWorkout,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 9),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                              training.hasActiveSession
                                  ? Icons.play_circle_outline_rounded
                                  : Icons.play_arrow_rounded,
                              color: AppColors.primary,
                              size: 18),
                          const SizedBox(width: 6),
                          Text(
                            training.hasActiveSession ? 'Продолжить' : 'Старт',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ─── Tab Selector ───
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: AnimatedBuilder(
                animation: _tabController,
                builder: (context, _) {
                  return Row(
                    children: List.generate(_tabs.length, (i) {
                      final isActive = _tabController.index == i;
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: i == 0 ? 0 : 4,
                            right: i == _tabs.length - 1 ? 0 : 4,
                          ),
                          child: GestureDetector(
                            onTap: () => _tabController.animateTo(i),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOutCubic,
                              height: 44,
                              decoration: BoxDecoration(
                                color: isActive
                                    ? AppColors.primary.withValues(alpha: 0.12)
                                    : t.surfaceBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isActive
                                      ? AppColors.primary.withValues(alpha: 0.3)
                                      : t.borderLight.withValues(alpha: 0.5),
                                ),
                                boxShadow: isActive
                                    ? [
                                        BoxShadow(
                                          color: AppColors.primary.withValues(alpha: 0.12),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : [
                                        BoxShadow(
                                          color: t.shadowColor,
                                          blurRadius: 4,
                                          offset: const Offset(0, 1),
                                        ),
                                      ],
                                ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _tabs[i].icon,
                                    size: 15,
                                    color: isActive
                                        ? AppColors.primary
                                        : t.textHint,
                                  ),
                                  const SizedBox(width: 5),
                                  Flexible(
                                    child: Text(
                                      _tabs[i].label,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: isActive
                                            ? AppColors.primary
                                            : t.textSecondary,
                                        fontWeight: isActive
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // ─── Tab Content ───
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildDashboardTab(t, training),
                  _buildPlaceholderTab(t, 'AI Lab',
                      Icons.science_outlined, 'AI-конструктор тренировок'),
                  _buildLedgerTab(t, training),
                  const TrainingAnalyticsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  //  DASHBOARD TAB
  // ═══════════════════════════════════════════════

  Widget _buildDashboardTab(AppThemeColors t, TrainingProvider training) {
    final score = training.trainingScore;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Training Score card ──
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  t.cardBg,
                  t.isDark
                      ? t.cardBg.withValues(alpha: 0.95)
                      : t.surfaceBg.withValues(alpha: 0.5),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: t.borderLight.withValues(alpha: 0.6),
              ),
              boxShadow: [
                // Main soft shadow
                BoxShadow(
                  color: t.isDark
                      ? Colors.black.withValues(alpha: 0.25)
                      : Colors.black.withValues(alpha: 0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                  spreadRadius: -4,
                ),
                // Tight ambient shadow
                BoxShadow(
                  color: t.isDark
                      ? Colors.black.withValues(alpha: 0.15)
                      : Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Training Score',
                        style: TextStyle(
                          color: t.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        )),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: _scoreColor(score).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(
                          color: _scoreColor(score).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        training.scoreCategory,
                        style: TextStyle(
                          color: _scoreColor(score),
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Circular score indicator with inset backdrop
                Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: t.isDark
                        ? Colors.black.withValues(alpha: 0.15)
                        : t.surfaceBg.withValues(alpha: 0.8),
                    boxShadow: [
                      // Inner shadow effect via dark inset
                      BoxShadow(
                        color: t.isDark
                            ? Colors.black.withValues(alpha: 0.3)
                            : Colors.black.withValues(alpha: 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                        spreadRadius: -1,
                      ),
                    ],
                  ),
                  child: Center(
                    child: SizedBox(
                      width: 130,
                      height: 130,
                      child: CustomPaint(
                        painter: _ScoreRingPainter(score / 100, _scoreColor(score)),
                        child: Center(
                          child: Text(
                            '${score.round()}',
                            style: TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.w800,
                              color: t.textPrimary,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                // Score breakdown bars
                _scoreBar(t, 'Регулярность', training.regularityScore, AppColors.primary),
                const SizedBox(height: 10),
                _scoreBar(t, 'Объём', training.volumeScore, const Color(0xFF22C55E)),
                const SizedBox(height: 10),
                _scoreBar(t, 'Прогресс', training.progressScore, const Color(0xFF3B82F6)),
                const SizedBox(height: 10),
                _scoreBar(t, 'Разнообразие', training.varietyScore, const Color(0xFF8B5CF6)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Quick stats row ──
          Row(
            children: [
              _statTile(t, Icons.bolt_rounded, '${training.completedSessionCount}',
                  'Тренировки'),
              const SizedBox(width: 10),
              _statTile(t, Icons.local_fire_department_outlined,
                  '${training.currentStreak}', 'Стрик'),
              const SizedBox(width: 10),
              _statTile(t, Icons.fitness_center_outlined,
                  '${(training.lifetimeTonnage / 1000).toStringAsFixed(1)}т',
                  'Тоннаж'),
            ],
          ),
          const SizedBox(height: 16),

          // ── Exercise Library shortcut ──
          GestureDetector(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ExerciseLibraryScreen())),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: t.cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: t.borderLight.withValues(alpha: 0.6),
                ),
                boxShadow: [
                  BoxShadow(
                    color: t.isDark
                        ? Colors.black.withValues(alpha: 0.2)
                        : Colors.black.withValues(alpha: 0.05),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                    spreadRadius: -3,
                  ),
                  BoxShadow(
                    color: t.isDark
                        ? Colors.black.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.library_books_outlined,
                        color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Библиотека упражнений',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: t.textPrimary,
                              fontSize: 14,
                            )),
                        Text('${training.exercises.length} упражнений',
                            style: TextStyle(
                              color: t.textHint,
                              fontSize: 12,
                            )),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      color: t.textHint, size: 22),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Active session banner ──
          if (training.hasActiveSession)
            GestureDetector(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ActiveWorkoutScreen())),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.play_circle_filled_rounded,
                        color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            training.activeSession!.name.isEmpty
                                ? 'Тренировка'
                                : training.activeSession!.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            '${training.activeSession!.sets.length} подходов • в процессе',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  //  SCORE HELPERS
  // ═══════════════════════════════════════════════

  Color _scoreColor(double score) {
    if (score >= 86) return const Color(0xFF8B5CF6); // purple - Pro
    if (score >= 61) return const Color(0xFF22C55E); // green - Athlete
    if (score >= 31) return const Color(0xFFF59E0B); // amber - Amateur
    return const Color(0xFFEF4444); // red - Beginner
  }

  Widget _scoreBar(AppThemeColors t, String label, double value, Color color) {
    final ratio = (value / 100).clamp(0.0, 1.0);
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(label,
              style: TextStyle(color: t.textSecondary, fontSize: 12)),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final fill = constraints.maxWidth * ratio;
              return Container(
                height: 8,
                decoration: BoxDecoration(
                  color: t.isDark
                      ? Colors.black.withValues(alpha: 0.2)
                      : const Color(0xFFEEEEF0),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: fill,
                    height: 8,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color.lerp(color, Colors.white, 0.15)!,
                          color,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 36,
          child: Text('${value.round()}%',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              )),
        ),
      ],
    );
  }

  Widget _statTile(AppThemeColors t, IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              t.cardBg,
              t.isDark
                  ? t.cardBg.withValues(alpha: 0.9)
                  : t.surfaceBg.withValues(alpha: 0.4),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: t.borderLight.withValues(alpha: 0.6),
          ),
          boxShadow: [
            BoxShadow(
              color: t.isDark
                  ? Colors.black.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
              spreadRadius: -2,
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primary, size: 18),
            ),
            const SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: t.textPrimary,
                )),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(color: t.textHint, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  //  LEDGER TAB (session history)
  // ═══════════════════════════════════════════════

  Widget _buildLedgerTab(AppThemeColors t, TrainingProvider training) {
    final sessions = training.sessions.where((s) => !s.isActive).toList();
    if (sessions.isEmpty) {
      return _buildPlaceholderTab(t,
          'Журнал', Icons.menu_book_outlined, 'Здесь появится история тренировок');
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: sessions.length,
      itemBuilder: (ctx, i) {
        final session = sessions[i];
        final date = session.startedAt.toLocal();
        return Dismissible(
          key: Key(session.id),
          direction: DismissDirection.endToStart,
          background: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.only(right: 24),
            alignment: Alignment.centerRight,
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.delete_outline_rounded,
                color: AppColors.error),
          ),
          confirmDismiss: (direction) async {
            return await showDialog<bool>(
              context: context,
              builder: (ctx) {
                return AlertDialog(
                  backgroundColor: t.dialogBg,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  title: Text('Удалить тренировку?',
                      style: TextStyle(color: t.textPrimary)),
                  content: Text(
                    '${session.name.isEmpty ? "Тренировка" : session.name}\n'
                    '${session.totalSets} подходов • ${session.totalTonnage.toStringAsFixed(0)} кг',
                    style: TextStyle(color: t.textSecondary),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text('Отмена',
                          style: TextStyle(color: t.textHint)),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Удалить',
                          style: TextStyle(
                              color: AppColors.error,
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                );
              },
            ) ?? false;
          },
          onDismissed: (_) {
            training.deleteSession(session.id);
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: t.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: t.borderLight.withValues(alpha: 0.5)),
              boxShadow: [
                BoxShadow(
                  color: t.isDark
                      ? Colors.black.withValues(alpha: 0.18)
                      : Colors.black.withValues(alpha: 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                  spreadRadius: -3,
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${date.day}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                          color: AppColors.primary,
                          height: 1.1,
                        ),
                      ),
                      Text(
                        _monthShort(date.month),
                        style: TextStyle(
                          fontSize: 9,
                          color: AppColors.primary.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.name.isEmpty ? 'Тренировка' : session.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: t.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${session.totalSets} подходов • ${session.durationMin.abs()} мин • '
                        '${session.totalTonnage.toStringAsFixed(0)} кг',
                        style: TextStyle(
                          color: t.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _monthShort(int month) {
    const months = [
      '', 'янв', 'фев', 'мар', 'апр', 'май', 'июн',
      'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'
    ];
    return months[month.clamp(1, 12)];
  }

  // ═══════════════════════════════════════════════
  //  PLACEHOLDER TAB
  // ═══════════════════════════════════════════════

  Widget _buildPlaceholderTab(AppThemeColors t, String title, IconData icon, String description) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.15),
                ),
              ),
              child: Icon(icon,
                  size: 44, color: AppColors.primary.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 24),
            Text(title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: t.textPrimary,
                )),
            const SizedBox(height: 8),
            Text(description,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: t.textSecondary)),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 11),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(50),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: const Text('🚀 Скоро',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  )),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabInfo {
  final String label;
  final IconData icon;
  const _TabInfo(this.label, this.icon);
}

// ═══════════════════════════════════════════════
//  CIRCULAR SCORE PAINTER
// ═══════════════════════════════════════════════

class _ScoreRingPainter extends CustomPainter {
  final double progress; // 0.0 - 1.0
  final Color color;

  _ScoreRingPainter(this.progress, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    const strokeWidth = 10.0;

    // Outer subtle glow (creates depth illusion)
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 8
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(center, radius, glowPaint);

    // Background ring (inset groove effect)
    final bgPaint = Paint()
      ..color = const Color(0xFFE8E8EC)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    // Inner shadow on ring track (3D inset)
    final innerShadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth - 2
      ..maskFilter = const MaskFilter.blur(BlurStyle.inner, 3);
    canvas.drawCircle(center, radius, innerShadowPaint);

    if (progress > 0) {
      final sweepAngle = 2 * math.pi * progress;
      const startAngle = -math.pi / 2;
      final rect = Rect.fromCircle(center: center, radius: radius);

      // Progress arc glow (color bleed)
      final arcGlowPaint = Paint()
        ..color = color.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 6
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawArc(rect, startAngle, sweepAngle, false, arcGlowPaint);

      // Progress arc (solid, web-safe)
      final progressPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, startAngle, sweepAngle, false, progressPaint);

      // Bright dot at the end of the arc
      final endAngle = startAngle + sweepAngle;
      final dotX = center.dx + radius * math.cos(endAngle);
      final dotY = center.dy + radius * math.sin(endAngle);
      canvas.drawCircle(
        Offset(dotX, dotY),
        5,
        Paint()..color = Colors.white,
      );
      canvas.drawCircle(
        Offset(dotX, dotY),
        5,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ScoreRingPainter old) =>
      old.progress != progress || old.color != color;
}
