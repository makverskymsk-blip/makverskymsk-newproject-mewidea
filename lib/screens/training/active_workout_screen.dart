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
  Exercise? _selectedExercise;

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  void _addSet() async {
    final training = context.read<TrainingProvider>();
    if (_selectedExercise == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите упражнение'), backgroundColor: Colors.orange),
      );
      return;
    }
    final weight = double.tryParse(_weightController.text.replaceAll(',', '.')) ?? 0;
    final reps = int.tryParse(_repsController.text) ?? 0;
    if (reps <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Укажите повторения'), backgroundColor: Colors.orange),
      );
      return;
    }

    await training.addSet(
      exerciseId: _selectedExercise!.id,
      exerciseName: _selectedExercise!.name,
      weightKg: weight,
      reps: reps,
    );

    _weightController.clear();
    _repsController.clear();
  }

  void _finishWorkout() async {
    final training = context.read<TrainingProvider>();
    final xpEarned = await training.finishWorkout();
    if (mounted) {
      showDialog(
        context: context,
        builder: (ctx) {
          final t = AppColors.of(ctx);
          return AlertDialog(
            backgroundColor: t.dialogBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('🎉 Тренировка завершена!',
                style: TextStyle(fontWeight: FontWeight.w800)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00C853), Color(0xFF00E676)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Text('Получено XP',
                          style: TextStyle(color: Colors.white70, fontSize: 12)),
                      Text('+$xpEarned',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 32,
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
          content: Text('Прогресс не будет сохранён, XP не начислятся.',
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

    final elapsed = DateTime.now().difference(session.startedAt);
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
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF1A1A2E),
                    const Color(0xFF16213E),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _runStat(Icons.timer_rounded, elapsedStr, 'Время'),
                  _runStat(Icons.fitness_center_rounded,
                      '${session.sets.length}', 'Подходы'),
                  _runStat(Icons.monitor_weight_outlined,
                      '${runningTonnage.toStringAsFixed(0)} кг', 'Тоннаж'),
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
                          Icon(Icons.fitness_center_rounded,
                              color: _selectedExercise != null
                                  ? const Color(0xFFFF6B35)
                                  : t.textHint,
                              size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _selectedExercise?.name ?? 'Выберите упражнение',
                              style: TextStyle(
                                color: _selectedExercise != null
                                    ? t.textPrimary
                                    : t.textHint,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded,
                              color: t.textHint, size: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Weight + Reps row
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _weightController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          style: TextStyle(color: t.textPrimary),
                          decoration: InputDecoration(
                            labelText: 'Вес (кг)',
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
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _repsController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(color: t.textPrimary),
                          decoration: InputDecoration(
                            labelText: 'Повторения',
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
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: _addSet,
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF6B35), Color(0xFFFF3D00)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.add_rounded,
                              color: Colors.white, size: 24),
                        ),
                      ),
                    ],
                  ),
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
                                        '${s.weightKg.toStringAsFixed(1)} кг × ${s.reps}',
                                        style: TextStyle(
                                          color: t.textHint,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
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
                    color: session.sets.isEmpty
                        ? t.borderLight
                        : null,
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

  Widget _runStat(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF00FF88), size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  void _showExercisePicker(TrainingProvider training) {
    final t = AppColors.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: t.dialogBg,
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
                Icon(Icons.fitness_center_rounded,
                    size: 48, color: t.textHint),
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
        return ListView.builder(
          shrinkWrap: true,
          padding: const EdgeInsets.all(20),
          itemCount: training.exercises.length,
          itemBuilder: (ctx, i) {
            final ex = training.exercises[i];
            final isSelected = _selectedExercise?.id == ex.id;
            return ListTile(
              leading: Icon(
                Icons.fitness_center_rounded,
                color: isSelected ? const Color(0xFFFF6B35) : t.textHint,
              ),
              title: Text(ex.name,
                  style: TextStyle(
                    color: t.textPrimary,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                  )),
              subtitle: Text(ex.muscleGroup,
                  style: TextStyle(color: t.textHint, fontSize: 12)),
              trailing: isSelected
                  ? const Icon(Icons.check_circle_rounded,
                      color: Color(0xFFFF6B35))
                  : null,
              onTap: () {
                setState(() => _selectedExercise = ex);
                Navigator.pop(ctx);
              },
            );
          },
        );
      },
    );
  }
}
