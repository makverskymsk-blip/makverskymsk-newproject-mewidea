import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/training_provider.dart';
import '../../models/exercise.dart';
import '../../theme/app_colors.dart';

/// Active workout screen — add sets, see running stats, finish/cancel.
class ActiveWorkoutScreen extends StatefulWidget {
  const ActiveWorkoutScreen({super.key});

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen> {
  final _weightController = TextEditingController();
  final _repsController = TextEditingController();
  final _durationController = TextEditingController();
  final _distanceController = TextEditingController();
  Exercise? _selectedExercise;

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    _durationController.dispose();
    _distanceController.dispose();
    super.dispose();
  }

  /// Determine input mode based on selected exercise
  _InputMode get _inputMode {
    if (_selectedExercise == null) return _InputMode.weightReps;
    if (_selectedExercise!.isCardio) return _InputMode.cardio;
    if (_selectedExercise!.isTimeBased) return _InputMode.timed;
    return _InputMode.weightReps;
  }

  void _addSet() async {
    final training = context.read<TrainingProvider>();
    if (_selectedExercise == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите упражнение'), backgroundColor: Colors.orange),
      );
      return;
    }

    double weight = 0;
    int reps = 0;

    switch (_inputMode) {
      case _InputMode.weightReps:
        weight = double.tryParse(_weightController.text.replaceAll(',', '.')) ?? 0;
        reps = int.tryParse(_repsController.text) ?? 0;
        if (reps <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Укажите повторения'), backgroundColor: Colors.orange),
          );
          return;
        }
        if (weight > 500) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Максимальный вес — 500 кг'), backgroundColor: Colors.orange),
          );
          return;
        }
        break;

      case _InputMode.cardio:
        // Duration in minutes → store as "reps", distance in km → store as "weight"
        final duration = int.tryParse(_durationController.text) ?? 0;
        final distance = double.tryParse(_distanceController.text.replaceAll(',', '.')) ?? 0;
        if (duration <= 0 && distance <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Укажите время или дистанцию'), backgroundColor: Colors.orange),
          );
          return;
        }
        // Encode: weight = distance (km), reps = duration (min)
        weight = distance;
        reps = duration > 0 ? duration : 1;
        break;

      case _InputMode.timed:
        // Duration in seconds → store as reps
        final seconds = int.tryParse(_durationController.text) ?? 0;
        if (seconds <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Укажите время (сек)'), backgroundColor: Colors.orange),
          );
          return;
        }
        weight = 0;
        reps = seconds;
        break;
    }

    await training.addSet(
      exerciseId: _selectedExercise!.id,
      exerciseName: _selectedExercise!.name,
      weightKg: weight.clamp(0, 500),
      reps: reps.clamp(1, 9999),
    );

    _weightController.clear();
    _repsController.clear();
    _durationController.clear();
    _distanceController.clear();
  }

  void _finishWorkout() async {
    final t = AppColors.of(context);
    final training = context.read<TrainingProvider>();
    final score = await training.finishWorkout();
    if (mounted) {
      showDialog(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            backgroundColor: t.dialogBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            title: Text('Тренировка завершена!',
                style: TextStyle(fontWeight: FontWeight.w800, color: t.textPrimary)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B35).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFFF6B35).withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text('Training Score',
                          style: TextStyle(color: t.textHint, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text('${training.trainingScore.round()}',
                          style: const TextStyle(
                            color: Color(0xFFFF6B35),
                            fontWeight: FontWeight.w900,
                            fontSize: 42,
                          )),
                      Text(training.scoreCategory,
                          style: TextStyle(
                            color: t.textHint,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          )),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                child: const Text('Отлично!',
                    style: TextStyle(
                        color: Color(0xFFFF6B35), fontWeight: FontWeight.w700)),
              ),
            ],
          );
        },
      );
    }
  }

  void _cancelWorkout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final t = AppColors.of(ctx);
        return AlertDialog(
          backgroundColor: t.dialogBg,
          title: Text('Отменить тренировку?', style: TextStyle(color: t.textPrimary)),
          content: Text('Прогресс не будет сохранён.',
              style: TextStyle(color: t.textSecondary)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Нет', style: TextStyle(color: t.textHint)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Отменить',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
            ),
          ],
        );
      },
    );
    if (confirm == true) {
      if (!mounted) return;
      await context.read<TrainingProvider>().cancelWorkout();
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppColors.of(context);
    final training = context.watch<TrainingProvider>();
    final session = training.activeSession;

    if (session == null) {
      return Scaffold(
        backgroundColor: t.scaffoldBg,
        body: const Center(child: Text('Нет активной тренировки')),
      );
    }

    final elapsed = DateTime.now().toUtc().difference(session.startedAt.toUtc());
    final elapsedStr =
        '${elapsed.inMinutes}:${(elapsed.inSeconds % 60).toString().padLeft(2, '0')}';

    double runningTonnage = 0;
    for (final s in session.sets) {
      runningTonnage += s.tonnage;
    }

    return Scaffold(
      backgroundColor: t.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: t.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          session.name.isEmpty ? 'Тренировка' : session.name,
          style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.red),
            onPressed: _cancelWorkout,
            tooltip: 'Отменить',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ─── Running stats bar ───
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: t.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: t.borderLight),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _runStat(Icons.timer_rounded, elapsedStr, 'Время', t),
                  _runStat(Icons.fitness_center_rounded,
                      '${session.sets.length}', 'Подходы', t),
                  _runStat(Icons.monitor_weight_outlined,
                      '${runningTonnage.toStringAsFixed(0)} кг', 'Тоннаж', t),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ─── Add set form ───
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: t.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: t.borderLight),
              ),
              child: Column(
                children: [
                  // Exercise selector
                  GestureDetector(
                    onTap: () => _showExercisePicker(training),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: t.surfaceBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: t.borderLight),
                      ),
                      child: Row(
                        children: [
                          Icon(_exerciseIcon,
                              color: _selectedExercise != null
                                  ? const Color(0xFFFF6B35)
                                  : t.textHint,
                              size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedExercise?.name ?? 'Выберите упражнение',
                                  style: TextStyle(
                                    color: _selectedExercise != null
                                        ? t.textPrimary
                                        : t.textHint,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (_selectedExercise != null)
                                  Text(
                                    _inputModeLabel,
                                    style: TextStyle(
                                      color: t.textHint,
                                      fontSize: 11,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded,
                              color: t.textHint, size: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Dynamic input fields
                  _buildInputFields(t),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ─── Sets list ───
            Expanded(
              child: session.sets.isEmpty
                  ? Center(
                      child: Text('Добавьте первый подход',
                          style: TextStyle(color: t.textHint)),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: session.sets.length,
                      itemBuilder: (ctx, i) {
                        final s = session.sets[session.sets.length - 1 - i];
                        final ex = training.exercises
                            .where((e) => e.id == s.exerciseId)
                            .firstOrNull;
                        final isCardio = ex?.isCardio ?? false;
                        final isTimed = ex?.isTimeBased ?? false;

                        return Dismissible(
                          key: Key(s.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child: const Icon(Icons.delete_rounded,
                                color: Colors.red),
                          ),
                          onDismissed: (_) => training.removeSet(s.id),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: t.cardBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: t.borderLight),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF6B35)
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${s.setOrder}',
                                      style: const TextStyle(
                                        color: Color(0xFFFF6B35),
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        s.exerciseName,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: t.textPrimary,
                                          fontSize: 13,
                                        ),
                                      ),
                                      Text(
                                        _formatSetInfo(s, isCardio, isTimed),
                                        style: TextStyle(
                                          color: t.textHint,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (!isCardio && !isTimed)
                                  Text(
                                    '${s.tonnage.toStringAsFixed(0)} кг',
                                    style: TextStyle(
                                      color: t.textSecondary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // ─── Finish button ───
            Padding(
              padding: const EdgeInsets.all(20),
              child: GestureDetector(
                onTap: session.sets.isEmpty ? null : _finishWorkout,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: session.sets.isNotEmpty
                        ? const LinearGradient(
                            colors: [Color(0xFF00C853), Color(0xFF00E676)])
                        : null,
                    color: session.sets.isEmpty ? t.borderLight : null,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: session.sets.isNotEmpty
                        ? [
                            BoxShadow(
                              color: const Color(0xFF00C853)
                                  .withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: const Center(
                    child: Text(
                      '✅ Завершить тренировку',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Dynamic input fields based on exercise type ───

  Widget _buildInputFields(AppThemeColors t) {
    switch (_inputMode) {
      case _InputMode.cardio:
        return Row(
          children: [
            Expanded(
              child: _inputField(
                controller: _durationController,
                label: 'Время (мин)',
                icon: Icons.timer_outlined,
                isDecimal: false,
                t: t,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _inputField(
                controller: _distanceController,
                label: 'Дистанция (км)',
                icon: Icons.straighten_rounded,
                isDecimal: true,
                t: t,
              ),
            ),
            const SizedBox(width: 12),
            _addButton(),
          ],
        );

      case _InputMode.timed:
        return Row(
          children: [
            Expanded(
              flex: 2,
              child: _inputField(
                controller: _durationController,
                label: 'Время (сек)',
                icon: Icons.timer_outlined,
                isDecimal: false,
                t: t,
              ),
            ),
            const SizedBox(width: 12),
            _addButton(),
          ],
        );

      case _InputMode.weightReps:
        return Row(
          children: [
            Expanded(
              child: _inputField(
                controller: _weightController,
                label: 'Вес (кг)',
                icon: Icons.monitor_weight_outlined,
                isDecimal: true,
                t: t,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _inputField(
                controller: _repsController,
                label: 'Повторения',
                icon: Icons.repeat_rounded,
                isDecimal: false,
                t: t,
              ),
            ),
            const SizedBox(width: 12),
            _addButton(),
          ],
        );
    }
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDecimal,
    required AppThemeColors t,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: isDecimal),
      style: TextStyle(color: t.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: t.textHint, fontSize: 13),
        filled: true,
        fillColor: t.surfaceBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: t.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: t.borderLight),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
    );
  }

  Widget _addButton() {
    return GestureDetector(
      onTap: _addSet,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF6B35), Color(0xFFFF3D00)],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
      ),
    );
  }

  IconData get _exerciseIcon {
    if (_selectedExercise == null) return Icons.fitness_center_rounded;
    if (_selectedExercise!.isCardio) return Icons.directions_run_rounded;
    if (_selectedExercise!.isTimeBased) return Icons.timer_rounded;
    return Icons.fitness_center_rounded;
  }

  String get _inputModeLabel {
    switch (_inputMode) {
      case _InputMode.cardio:
        return '🏃 Кардио — время и дистанция';
      case _InputMode.timed:
        return '⏱ На время — длительность';
      case _InputMode.weightReps:
        return '🏋️ Силовое — вес и повторения';
    }
  }

  String _formatSetInfo(dynamic s, bool isCardio, bool isTimed) {
    if (isCardio) {
      final dist = s.weightKg;
      final dur = s.reps;
      final parts = <String>[];
      if (dur > 0) parts.add('$dur мин');
      if (dist > 0) parts.add('${dist.toStringAsFixed(1)} км');
      return parts.isEmpty ? '—' : parts.join(' • ');
    }
    if (isTimed) {
      return '${s.reps} сек';
    }
    return '${s.weightKg.toStringAsFixed(1)} кг × ${s.reps}';
  }

  Widget _runStat(IconData icon, String value, String label, AppThemeColors t) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFFFF6B35), size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: t.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 15,
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
    );
  }

  // ─── Exercise picker with muscle group filter ───

  void _showExercisePicker(TrainingProvider training) {
    final t = AppColors.of(context);
    String pickerGroup = 'Все';

    const muscleGroups = [
      ('Все', Icons.grid_view_rounded),
      ('Грудь', Icons.fitness_center_rounded),
      ('Спина', Icons.accessibility_new_rounded),
      ('Плечи', Icons.person_rounded),
      ('Бицепс', Icons.front_hand_rounded),
      ('Трицепс', Icons.back_hand_rounded),
      ('Ноги', Icons.directions_walk_rounded),
      ('Пресс', Icons.self_improvement_rounded),
      ('Кардио', Icons.favorite_rounded),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: t.dialogBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        if (training.exercises.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.fitness_center_rounded, size: 48, color: t.textHint),
                const SizedBox(height: 12),
                Text('Нет упражнений',
                    style: TextStyle(
                        color: t.textPrimary, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                    'Добавьте упражнения в библиотеку на главном экране тренировок',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: t.textHint, fontSize: 13)),
                const SizedBox(height: 20),
              ],
            ),
          );
        }

        return StatefulBuilder(
          builder: (ctx, setPickerState) {
            final filtered = pickerGroup == 'Все'
                ? training.exercises
                : training.exercises
                    .where((e) => e.muscleGroup == pickerGroup)
                    .toList();

            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              expand: false,
              builder: (ctx, scrollController) {
                return Column(
                  children: [
                    // Handle bar
                    Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: t.textHint.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // Title
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text('Выберите упражнение',
                          style: TextStyle(
                            color: t.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          )),
                    ),
                    const SizedBox(height: 12),
                    // Muscle group filter bar
                    SizedBox(
                      height: 38,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: muscleGroups.length,
                        itemBuilder: (ctx, i) {
                          final group = muscleGroups[i];
                          final isSelected = pickerGroup == group.$1;
                          return GestureDetector(
                            onTap: () =>
                                setPickerState(() => pickerGroup = group.$1),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.only(right: 6),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                gradient: isSelected
                                    ? const LinearGradient(colors: [
                                        Color(0xFFFF6B35),
                                        Color(0xFFFF3D00)
                                      ])
                                    : null,
                                color: isSelected ? null : t.surfaceBg,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.transparent
                                      : t.borderLight,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(group.$2,
                                      size: 12,
                                      color: isSelected
                                          ? Colors.white
                                          : t.textHint),
                                  const SizedBox(width: 4),
                                  Text(
                                    group.$1,
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
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Exercise list
                    Expanded(
                      child: filtered.isEmpty
                          ? Center(
                              child: Text('Нет упражнений в "$pickerGroup"',
                                  style: TextStyle(color: t.textHint)))
                          : ListView.builder(
                              controller: scrollController,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: filtered.length,
                              itemBuilder: (ctx, i) {
                                final ex = filtered[i];
                                final isSelected =
                                    _selectedExercise?.id == ex.id;
                                return GestureDetector(
                                  onTap: () {
                                    setState(() => _selectedExercise = ex);
                                    // Clear old input fields when switching type
                                    _weightController.clear();
                                    _repsController.clear();
                                    _durationController.clear();
                                    _distanceController.clear();
                                    Navigator.pop(ctx);
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 4),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFFFF6B35)
                                              .withValues(alpha: 0.08)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(10),
                                      border: isSelected
                                          ? Border.all(
                                              color: const Color(0xFFFF6B35)
                                                  .withValues(alpha: 0.3))
                                          : null,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          ex.isCardio
                                              ? Icons
                                                  .directions_run_rounded
                                              : ex.isTimeBased
                                                  ? Icons.timer_rounded
                                                  : Icons
                                                      .fitness_center_rounded,
                                          color: isSelected
                                              ? const Color(0xFFFF6B35)
                                              : t.textHint,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            ex.name,
                                            style: TextStyle(
                                              color: t.textPrimary,
                                              fontWeight: isSelected
                                                  ? FontWeight.w700
                                                  : FontWeight.w500,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                        if (isSelected)
                                          const Icon(
                                              Icons.check_circle_rounded,
                                              color: Color(0xFFFF6B35),
                                              size: 18),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}

enum _InputMode { weightReps, cardio, timed }
