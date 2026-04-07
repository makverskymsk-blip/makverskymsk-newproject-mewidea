/// A workout session — from "Start" to "Finish".
class WorkoutSession {
  final String id;
  final String userId;
  String name;
  final DateTime startedAt;
  DateTime? finishedAt;
  int durationMin;
  double totalTonnage;
  int totalSets;
  int xpEarned;
  String notes;
  final DateTime createdAt;

  /// In-memory sets (loaded separately)
  List<WorkoutSet> sets;

  WorkoutSession({
    required this.id,
    required this.userId,
    this.name = '',
    required this.startedAt,
    this.finishedAt,
    this.durationMin = 0,
    this.totalTonnage = 0,
    this.totalSets = 0,
    this.xpEarned = 0,
    this.notes = '',
    DateTime? createdAt,
    List<WorkoutSet>? sets,
  })  : createdAt = createdAt ?? DateTime.now(),
        sets = sets ?? [];

  bool get isActive => finishedAt == null;

  factory WorkoutSession.fromMap(Map<String, dynamic> d) {
    return WorkoutSession(
      id: d['id'].toString(),
      userId: d['user_id'] ?? '',
      name: d['name'] ?? '',
      startedAt: DateTime.parse(d['started_at']),
      finishedAt:
          d['finished_at'] != null ? DateTime.parse(d['finished_at']) : null,
      durationMin: d['duration_min'] ?? 0,
      totalTonnage: (d['total_tonnage'] as num?)?.toDouble() ?? 0,
      totalSets: d['total_sets'] ?? 0,
      xpEarned: d['xp_earned'] ?? 0,
      notes: d['notes'] ?? '',
      createdAt: d['created_at'] != null
          ? DateTime.parse(d['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toInsertMap() => {
        'user_id': userId,
        'name': name,
        'started_at': startedAt.toIso8601String(),
        'finished_at': finishedAt?.toIso8601String(),
        'duration_min': durationMin,
        'total_tonnage': totalTonnage,
        'total_sets': totalSets,
        'xp_earned': xpEarned,
        'notes': notes,
      };
}

/// A single set within a workout session.
class WorkoutSet {
  final String id;
  final String sessionId;
  final String exerciseId;
  String exerciseName;
  int setOrder;
  double weightKg;
  int reps;
  double? rpeScore;
  int restTimeSec;
  bool isPr;
  bool isCompleted;
  final DateTime createdAt;

  WorkoutSet({
    required this.id,
    required this.sessionId,
    required this.exerciseId,
    required this.exerciseName,
    required this.setOrder,
    this.weightKg = 0,
    this.reps = 0,
    this.rpeScore,
    this.restTimeSec = 90,
    this.isPr = false,
    this.isCompleted = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Tonnage = weight × reps  (in kg)
  double get tonnage => weightKg * reps;

  factory WorkoutSet.fromMap(Map<String, dynamic> d) {
    return WorkoutSet(
      id: d['id'].toString(),
      sessionId: d['session_id'] ?? '',
      exerciseId: d['exercise_id'] ?? '',
      exerciseName: d['exercise_name'] ?? '',
      setOrder: d['set_order'] ?? 0,
      weightKg: (d['weight_kg'] as num?)?.toDouble() ?? 0,
      reps: d['reps'] ?? 0,
      rpeScore: (d['rpe_score'] as num?)?.toDouble(),
      restTimeSec: d['rest_time_sec'] ?? 90,
      isPr: d['is_pr'] ?? false,
      isCompleted: d['is_completed'] ?? false,
      createdAt: d['created_at'] != null
          ? DateTime.parse(d['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toInsertMap() => {
        'session_id': sessionId,
        'exercise_id': exerciseId,
        'exercise_name': exerciseName,
        'set_order': setOrder,
        'weight_kg': weightKg,
        'reps': reps,
        'rpe_score': rpeScore,
        'rest_time_sec': restTimeSec,
        'is_pr': isPr,
        'is_completed': isCompleted,
      };
}
