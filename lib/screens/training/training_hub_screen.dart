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
    _TabInfo('Dashboard', Icons.dashboard_rounded),
    _TabInfo('Lab', Icons.science_rounded),
    _TabInfo('Журнал', Icons.menu_book_rounded),
    _TabInfo('Аналитика', Icons.analytics_rounded),
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
    final auth = context.read<AuthProvider>();
    final training = context.read<TrainingProvider>();
    final uid = auth.uid;
    if (uid == null) return;

    if (training.hasActiveSession) {
      // Resume existing workout
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const ActiveWorkoutScreen()));
      return;
    }

    // Show name dialog
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController();
        final t = AppColors.of(ctx);
        return AlertDialog(
          backgroundColor: t.dialogBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Новая тренировка', style: TextStyle(color: t.textPrimary)),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: TextStyle(color: t.textPrimary),
            decoration: InputDecoration(
              hintText: 'Название (необязательно)',
              hintStyle: TextStyle(color: t.textHint),
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
                  style: TextStyle(
                      color: Color(0xFFFF6B35), fontWeight: FontWeight.w700)),
            ),
          ],
        );
      },
    );

    if (name == null) return; // cancelled

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
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF6B35), Color(0xFFFF3D00)],
                      ),
                      borderRadius: BorderRadius.circular(14),
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
                  // Quick start button
                  GestureDetector(
                    onTap: _startWorkout,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: training.hasActiveSession
                              ? [const Color(0xFF00C853), const Color(0xFF00E676)]
                              : [const Color(0xFFFF6B35), const Color(0xFFFF3D00)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: (training.hasActiveSession
                                    ? const Color(0xFF00C853)
                                    : const Color(0xFFFF6B35))
                                .withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                              training.hasActiveSession
                                  ? Icons.play_circle_outline_rounded
                                  : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 18),
                          const SizedBox(width: 4),
                          Text(
                            training.hasActiveSession ? 'Продолжить' : 'Старт',
                            style: const TextStyle(
                              color: Colors.white,
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

            // ─── Tab Bar ───
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: t.cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: t.borderLight),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B35), Color(0xFFFF3D00)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                indicatorPadding: const EdgeInsets.all(3),
                dividerHeight: 0,
                labelColor: Colors.white,
                unselectedLabelColor: t.textHint,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 11,
                ),
                tabs: _tabs
                    .map((tab) => Tab(
                          height: 42,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(tab.icon, size: 16),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  tab.label,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
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
                      Icons.science_rounded, 'AI-конструктор тренировок'),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // XP & Level card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF1A1A2E),
                  const Color(0xFF16213E),
                  const Color(0xFF0F3460).withValues(alpha: 0.9),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFFF6B35).withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF6B35), Color(0xFFFF3D00)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'LVL ${training.level}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Spacer(),
                    Text(
                      'XP ${training.xp} / ${training.xpForNextLevel}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: training.xpProgress,
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF00FF88)),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Quick stats row
          Row(
            children: [
              _statCard(t, Icons.bolt_rounded, '${training.completedSessionCount}',
                  'Тренировки', const Color(0xFFFF6B35)),
              const SizedBox(width: 10),
              _statCard(t, Icons.local_fire_department_rounded,
                  '${training.currentStreak}', 'Стрик', const Color(0xFFFF3D00)),
              const SizedBox(width: 10),
              _statCard(
                  t,
                  Icons.fitness_center_rounded,
                  '${(training.lifetimeTonnage / 1000).toStringAsFixed(1)}т',
                  'Тоннаж',
                  const Color(0xFF4A90D9)),
              const SizedBox(width: 10),
              _statCard(t, Icons.timer_rounded,
                  '${training.lifetimeMinutes}м', 'Время', const Color(0xFF00C853)),
            ],
          ),
          const SizedBox(height: 20),

          // Exercise Library shortcut
          GestureDetector(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ExerciseLibraryScreen())),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: t.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: t.borderLight),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B35).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.library_books_rounded,
                        color: Color(0xFFFF6B35), size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Библиотека упражнений',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: t.textPrimary,
                          ),
                        ),
                        Text(
                          '${training.exercises.length} упражнений',
                          style: TextStyle(
                            color: t.textHint,
                            fontSize: 12,
                          ),
                        ),
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

          // Active session banner
          if (training.hasActiveSession)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00C853), Color(0xFF00E676)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00C853).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: GestureDetector(
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => const ActiveWorkoutScreen())),
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
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_rounded,
                        color: Colors.white),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _statCard(AppThemeColors t, IconData icon, String value,
      String label, Color accent) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: t.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: t.borderLight),
        ),
        child: Column(
          children: [
            Icon(icon, color: accent, size: 20),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: t.textPrimary,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: t.textHint,
                fontSize: 10,
              ),
            ),
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
      return _buildPlaceholderTab(
          t, 'Журнал', Icons.menu_book_rounded, 'Здесь появится история тренировок');
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: sessions.length,
      itemBuilder: (ctx, i) {
        final session = sessions[i];
        final date = session.startedAt;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: t.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: t.borderLight),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B35).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${date.day}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: Color(0xFFFF6B35),
                      ),
                    ),
                    Text(
                      _monthShort(date.month),
                      style: const TextStyle(
                        fontSize: 9,
                        color: Color(0xFFFF6B35),
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
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${session.totalSets} подходов • ${session.durationMin} мин • '
                      '${session.totalTonnage.toStringAsFixed(0)} кг',
                      style: TextStyle(
                        color: t.textHint,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF00FF88).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '+${session.xpEarned} XP',
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

  Widget _buildPlaceholderTab(
      AppThemeColors t, String title, IconData icon, String description) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFF6B35).withValues(alpha: 0.15),
                    const Color(0xFFFF3D00).withValues(alpha: 0.05),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFFF6B35).withValues(alpha: 0.3),
                ),
              ),
              child: Icon(icon,
                  size: 48,
                  color: const Color(0xFFFF6B35).withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: t.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: t.textHint),
            ),
            const SizedBox(height: 24),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B35).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFF6B35).withValues(alpha: 0.2),
                ),
              ),
              child: const Text(
                '🚀 Скоро',
                style: TextStyle(
                  color: Color(0xFFFF6B35),
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
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
