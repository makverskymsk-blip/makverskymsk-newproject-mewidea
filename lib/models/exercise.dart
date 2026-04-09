/// A single exercise in the user's library.
class Exercise {
  final String id;
  final String userId;
  String name;
  String muscleGroup;
  List<String> secondaryMuscles;
  String progressionType; // 'linear', 'double_progression', 'wave'
  String notes;
  final DateTime createdAt;

  /// True for cardio exercises where duration/distance matter, not weight/reps
  bool get isCardio => muscleGroup == 'Кардио';

  /// True for bodyweight / isometric exercises (Планка, etc.)
  bool get isTimeBased {
    final n = name.toLowerCase();
    return n.contains('планка') || n.contains('plank');
  }

  Exercise({
    required this.id,
    required this.userId,
    required this.name,
    required this.muscleGroup,
    List<String>? secondaryMuscles,
    this.progressionType = 'linear',
    this.notes = '',
    DateTime? createdAt,
  })  : secondaryMuscles = secondaryMuscles ?? [],
        createdAt = createdAt ?? DateTime.now();

  factory Exercise.fromMap(Map<String, dynamic> d) {
    return Exercise(
      id: d['id'].toString(),
      userId: d['user_id'] ?? '',
      name: d['name'] ?? '',
      muscleGroup: d['muscle_group'] ?? 'other',
      secondaryMuscles: d['secondary_muscles'] != null
          ? List<String>.from(d['secondary_muscles'])
          : [],
      progressionType: d['progression_type'] ?? 'linear',
      notes: d['notes'] ?? '',
      createdAt: d['created_at'] != null
          ? DateTime.parse(d['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toInsertMap() => {
        'user_id': userId,
        'name': name,
        'muscle_group': muscleGroup,
        'secondary_muscles': secondaryMuscles,
        'progression_type': progressionType,
        'notes': notes,
      };
}
