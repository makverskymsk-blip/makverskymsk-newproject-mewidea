import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/training_provider.dart';
import '../../theme/app_colors.dart';

/// Exercise library — create, view, delete exercises.
class ExerciseLibraryScreen extends StatefulWidget {
  const ExerciseLibraryScreen({super.key});

  @override
  State<ExerciseLibraryScreen> createState() => _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends State<ExerciseLibraryScreen> {
  static const _muscleGroups = [
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

  String _selectedGroup = 'Все';

  void _addExercise() async {
    final nameController = TextEditingController();
    String selectedMuscle = 'Грудь';
    final t = AppColors.of(context);

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setModalState) {
          return AlertDialog(
            backgroundColor: t.dialogBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text('Новое упражнение',
                style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w800)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  autofocus: true,
                  style: TextStyle(color: t.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Название',
                    hintText: 'Жим лёжа',
                    labelStyle: TextStyle(color: t.textHint),
                    hintStyle: TextStyle(color: t.textHint.withValues(alpha: 0.5)),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _muscleGroups
                      .where((m) => m.$1 != 'Все')
                      .map((m) {
                    final isSelected = selectedMuscle == m.$1;
                    return GestureDetector(
                      onTap: () => setModalState(() => selectedMuscle = m.$1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFFF6B35).withValues(alpha: 0.15)
                              : t.surfaceBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFFFF6B35)
                                : t.borderLight,
                          ),
                        ),
                        child: Text(
                          m.$1,
                          style: TextStyle(
                            color: isSelected
                                ? const Color(0xFFFF6B35)
                                : t.textSecondary,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Отмена', style: TextStyle(color: t.textHint)),
              ),
              TextButton(
                onPressed: () {
                  if (nameController.text.trim().isEmpty) return;
                  Navigator.pop(ctx, {
                    'name': nameController.text.trim(),
                    'muscle': selectedMuscle,
                  });
                },
                child: const Text('Добавить',
                    style: TextStyle(
                        color: Color(0xFFFF6B35), fontWeight: FontWeight.w700)),
              ),
            ],
          );
        });
      },
    );

    if (result != null && mounted) {
      await context.read<TrainingProvider>().addExercise(
            name: result['name']!,
            muscleGroup: result['muscle']!,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppColors.of(context);
    final training = context.watch<TrainingProvider>();
    final filtered = _selectedGroup == 'Все'
        ? training.exercises
        : training.exercisesByMuscle(_selectedGroup);

    return Scaffold(
      backgroundColor: t.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: t.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Библиотека упражнений',
            style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w800)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: Color(0xFFFF6B35)),
            onPressed: _addExercise,
          ),
        ],
      ),
      body: Column(
        children: [
          // Muscle group filter
          SizedBox(
            height: 46,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _muscleGroups.length,
              itemBuilder: (ctx, i) {
                final group = _muscleGroups[i];
                final isSelected = _selectedGroup == group.$1;
                return GestureDetector(
                  onTap: () => setState(() => _selectedGroup = group.$1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? const LinearGradient(
                              colors: [Color(0xFFFF6B35), Color(0xFFFF3D00)])
                          : null,
                      color: isSelected ? null : t.cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? Colors.transparent : t.borderLight,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(group.$2,
                            size: 14,
                            color: isSelected ? Colors.white : t.textHint),
                        const SizedBox(width: 6),
                        Text(
                          group.$1,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: isSelected ? Colors.white : t.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // Exercise list
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.fitness_center_rounded,
                            size: 48, color: t.textHint.withValues(alpha: 0.3)),
                        const SizedBox(height: 12),
                        Text(
                          _selectedGroup == 'Все'
                              ? 'Добавьте первое упражнение'
                              : 'Нет упражнений в "$_selectedGroup"',
                          style: TextStyle(color: t.textHint),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      final ex = filtered[i];
                      return Dismissible(
                        key: Key(ex.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 16),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child:
                              const Icon(Icons.delete_rounded, color: Colors.red, size: 18),
                        ),
                        onDismissed: (_) =>
                            training.removeExercise(ex.id),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 5),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: t.cardBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: t.borderLight),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF6B35)
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(7),
                                ),
                                child: const Icon(
                                    Icons.fitness_center_rounded,
                                    color: Color(0xFFFF6B35),
                                    size: 14),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  ex.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: t.textPrimary,
                                  ),
                                ),
                              ),
                              Text(
                                ex.muscleGroup,
                                style: TextStyle(
                                  color: t.textHint,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(Icons.chevron_right_rounded,
                                  color: t.textHint, size: 16),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addExercise,
        backgroundColor: const Color(0xFFFF6B35),
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }
}
