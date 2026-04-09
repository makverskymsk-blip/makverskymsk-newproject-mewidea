import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/default_exercises.dart';
import '../models/exercise.dart';
import '../models/workout_session.dart';
import '../services/supabase_service.dart';

/// Manages workout sessions, exercises, Training Score, and training state.
class TrainingProvider extends ChangeNotifier {
  final SupabaseService _db = SupabaseService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // ─── Exercises ───
  List<Exercise> _exercises = [];
  List<Exercise> get exercises => _exercises;

  // ─── Sessions ───
  List<WorkoutSession> _sessions = [];
  List<WorkoutSession> get sessions => _sessions;

  WorkoutSession? _activeSession;
  WorkoutSession? get activeSession => _activeSession;
  bool get hasActiveSession => _activeSession != null;

  String? _userId;

  /// Reliable userId: uses cached value or falls back to Supabase auth
  String? get userId {
    _userId ??= Supabase.instance.client.auth.currentUser?.id;
    return _userId;
  }


  // ═══════════════════════════════════════════════
  //  INIT — call once after login
  // ═══════════════════════════════════════════════

  Future<void> init(String userId, {int initialXp = 0, int initialLevel = 1}) async {
    _userId = userId;
    await Future.wait([
      loadExercises(userId),
      loadSessions(userId),
    ]);

    // Seed default exercises if user has none (first-time user)
    if (_exercises.isEmpty) {
      await seedDefaultExercises(userId);
    }
  }

  /// Seed the default exercise library for a new user.
  /// Skips exercises that already exist by name.
  Future<void> seedDefaultExercises(String userId) async {
    try {
      final existingNames = _exercises.map((e) => e.name.toLowerCase()).toSet();
      final toAdd = kDefaultExercises
          .where((ex) => !existingNames.contains((ex['name'] as String).toLowerCase()))
          .toList();

      if (toAdd.isEmpty) {
        debugPrint('TRAINING: All default exercises already exist, skipping seed');
        return;
      }

      debugPrint('TRAINING: Seeding ${toAdd.length} default exercises…');
      for (final ex in toAdd) {
        await _db.createExercise({
          'user_id': userId,
          'name': ex['name'],
          'muscle_group': ex['muscle_group'],
          'secondary_muscles': ex['secondary_muscles'] ?? <String>[],
          'notes': '',
        });
      }
      // Reload exercises from DB to get proper IDs
      await loadExercises(userId);
      debugPrint('TRAINING: Seeding complete — ${_exercises.length} exercises loaded');
    } catch (e) {
      debugPrint('TRAINING: seedDefaultExercises error: $e');
    }
  }

  // ═══════════════════════════════════════════════
  //  EXERCISES
  // ═══════════════════════════════════════════════

  Future<void> loadExercises(String userId) async {
    try {
      final data = await _db.getExercises(userId);
      _exercises = data.map((d) => Exercise.fromMap(d)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('TRAINING: loadExercises error: $e');
    }
  }

  Future<Exercise?> addExercise({
    required String name,
    required String muscleGroup,
    List<String>? secondaryMuscles,
    String notes = '',
  }) async {
    if (userId == null) {
      debugPrint('TRAINING: addExercise FAILED — userId is null!');
      return null;
    }
    try {
      debugPrint('TRAINING: addExercise "$name" for user $userId');
      final result = await _db.createExercise({
        'user_id': userId,
        'name': name,
        'muscle_group': muscleGroup,
        'secondary_muscles': secondaryMuscles ?? <String>[],
        'notes': notes,
      });
      debugPrint('TRAINING: addExercise SUCCESS — id=${result['id']}');
      final exercise = Exercise.fromMap(result);
      _exercises.insert(0, exercise);
      notifyListeners();
      return exercise;
    } catch (e, stack) {
      debugPrint('TRAINING: addExercise ERROR: $e');
      debugPrint('TRAINING: stack: $stack');
      return null;
    }
  }


  Future<void> removeExercise(String exerciseId) async {
    try {
      await _db.deleteExercise(exerciseId);
      _exercises.removeWhere((e) => e.id == exerciseId);
      notifyListeners();
    } catch (e) {
      debugPrint('TRAINING: removeExercise error: $e');
    }
  }

  /// Get exercises filtered by muscle group
  List<Exercise> exercisesByMuscle(String muscleGroup) {
    return _exercises.where((e) => e.muscleGroup == muscleGroup).toList();
  }

  // ═══════════════════════════════════════════════
  //  WORKOUT SESSIONS
  // ═══════════════════════════════════════════════

  Future<void> loadSessions(String userId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final data = await _db.getWorkoutSessions(userId);
      _sessions = data.map((d) => WorkoutSession.fromMap(d)).toList();

      // Restore active session if last one is unfinished
      final active = _sessions.where((s) => s.isActive).toList();
      _activeSession = active.isNotEmpty ? active.first : null;

      // Load sets for active session
      if (_activeSession != null) {
        await _loadSetsForSession(_activeSession!);
      }

      // Load sets for all completed sessions (needed for heatmap/analytics)
      final completed = _sessions.where((s) => !s.isActive && s.finishedAt != null).toList();
      for (final session in completed) {
        await _loadSetsForSession(session);
      }

      // Auto-fix old sessions with missing xpEarned
      for (final session in completed) {
        if (session.xpEarned <= 0 && session.sets.isNotEmpty) {
          final xp = (session.totalSets * 10 + session.totalTonnage ~/ 100).clamp(0, 9999).toInt();
          session.xpEarned = xp;
          try {
            await _db.updateWorkoutSession(session.id, {'xp_earned': xp});
            debugPrint('TRAINING: Auto-fixed xpEarned=$xp for session ${session.id}');
          } catch (_) {}
        }
      }
    } catch (e) {
      debugPrint('TRAINING: loadSessions error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadSetsForSession(WorkoutSession session) async {
    try {
      final data = await _db.getWorkoutSets(session.id);
      session.sets = data.map((d) => WorkoutSet.fromMap(d)).toList();
    } catch (e) {
      debugPrint('TRAINING: _loadSetsForSession error: $e');
    }
  }

  /// Start a new workout session
  Future<bool> startWorkout(String userId, String name) async {
    if (_activeSession != null) {
      debugPrint('TRAINING: Cannot start — session already active');
      return false;
    }
    try {
      final result = await _db.createWorkoutSession({
        'user_id': userId,
        'name': name.isEmpty ? 'Тренировка' : name,
        'started_at': DateTime.now().toUtc().toIso8601String(),
      });
      _activeSession = WorkoutSession.fromMap(result);
      _sessions.insert(0, _activeSession!);
      notifyListeners();
      debugPrint('TRAINING: Started session ${_activeSession!.id}');
      return true;
    } catch (e) {
      debugPrint('TRAINING: startWorkout error: $e');
      return false;
    }
  }

  /// Add a set to the active workout
  Future<WorkoutSet?> addSet({
    required String exerciseId,
    required String exerciseName,
    required double weightKg,
    required int reps,
    double? rpeScore,
  }) async {
    if (_activeSession == null) return null;
    try {
      // Validate & clamp input
      final clampedWeight = weightKg.clamp(0.0, 500.0);
      final clampedReps = reps.clamp(1, 9999);

      final setOrder = _activeSession!.sets.length + 1;
      final result = await _db.createWorkoutSet({
        'session_id': _activeSession!.id,
        'exercise_id': exerciseId,
        'exercise_name': exerciseName,
        'set_order': setOrder,
        'weight_kg': clampedWeight,
        'reps': clampedReps,
        'rpe_score': rpeScore,
        'is_completed': true,
      });
      final newSet = WorkoutSet.fromMap(result);
      _activeSession!.sets.add(newSet);
      notifyListeners();
      debugPrint('TRAINING: Added set #$setOrder — $exerciseName ${clampedWeight}kg × $clampedReps');
      return newSet;
    } catch (e) {
      debugPrint('TRAINING: addSet error: $e');
      return null;
    }
  }

  /// Remove a set from the active workout
  Future<void> removeSet(String setId) async {
    if (_activeSession == null) return;
    try {
      await _db.deleteWorkoutSet(setId);
      _activeSession!.sets.removeWhere((s) => s.id == setId);
      notifyListeners();
    } catch (e) {
      debugPrint('TRAINING: removeSet error: $e');
    }
  }

  /// Finish the active workout, calculate stats, award XP
  Future<int> finishWorkout() async {
    if (_activeSession == null) return 0;
    try {
      final session = _activeSession!;
      final now = DateTime.now().toUtc();

      // Calculate stats (both in UTC for correct diff)
      final startUtc = session.startedAt.toUtc();
      final durationMin = now.difference(startUtc).inMinutes.abs();
      double totalTonnage = 0;
      for (final s in session.sets) {
        totalTonnage += s.tonnage;
      }
      final totalSets = session.sets.length;

      // Calculate XP (base: 10 per set + 1 per 100kg tonnage)
      final xpEarned = (totalSets * 10 + totalTonnage ~/ 100).clamp(0, 9999).toInt();

      // Update session in DB
      await _db.updateWorkoutSession(session.id, {
        'finished_at': now.toUtc().toIso8601String(),
        'duration_min': durationMin,
        'total_tonnage': totalTonnage,
        'total_sets': totalSets,
        'xp_earned': xpEarned,
      });

      // Update local session
      session.finishedAt = now;
      session.durationMin = durationMin;
      session.totalTonnage = totalTonnage;
      session.totalSets = totalSets;
      session.xpEarned = xpEarned;

      _activeSession = null;
      notifyListeners();

      final score = trainingScore.round();
      debugPrint('TRAINING: Finished! Duration=${durationMin}m, '
          'Sets=$totalSets, Tonnage=${totalTonnage.toStringAsFixed(0)}kg, '
          'Score=$score');
      return score;
    } catch (e) {
      debugPrint('TRAINING: finishWorkout error: $e');
      return 0;
    }
  }

  /// Cancel / discard the active workout (no XP)
  Future<void> cancelWorkout() async {
    if (_activeSession == null) return;
    try {
      // Mark as finished with 0 XP
      await _db.updateWorkoutSession(_activeSession!.id, {
        'finished_at': DateTime.now().toUtc().toIso8601String(),
        'duration_min': 0,
        'total_tonnage': 0,
        'total_sets': 0,
        'xp_earned': 0,
        'notes': 'Отменена',
      });
      _activeSession = null;
      notifyListeners();
    } catch (e) {
      debugPrint('TRAINING: cancelWorkout error: $e');
    }
  }

  /// Delete a workout session permanently
  Future<void> deleteSession(String sessionId) async {
    try {
      await _db.deleteWorkoutSession(sessionId);
      _sessions.removeWhere((s) => s.id == sessionId);
      notifyListeners();
      debugPrint('TRAINING: Deleted session $sessionId');
    } catch (e) {
      debugPrint('TRAINING: deleteSession error: $e');
    }
  }

  // ═══════════════════════════════════════════════
  //  TRAINING SCORE (0-100)
  // ═══════════════════════════════════════════════

  /// Dynamic Training Score — computed from recent activity
  double get trainingScore {
    final reg = regularityScore;
    final vol = volumeScore;
    final prog = progressScore;
    final variety = varietyScore;
    return (reg * 0.35 + vol * 0.30 + prog * 0.20 + variety * 0.15)
        .clamp(0.0, 100.0);
  }

  /// Score category label
  String get scoreCategory {
    final s = trainingScore;
    if (s >= 86) return 'Про';
    if (s >= 61) return 'Атлет';
    if (s >= 31) return 'Любитель';
    return 'Новичок';
  }

  /// Regularity (0-100): based on training streak
  double get regularityScore {
    final streak = currentStreak;
    if (streak >= 7) return 100;
    if (streak >= 5) return 80;
    if (streak >= 3) return 50;
    if (streak >= 1) return 20;
    return 0;
  }

  /// Volume (0-100): weekly tonnage vs target (5000kg)
  double get volumeScore {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    double weeklyTonnage = 0;
    for (final s in _sessions) {
      if (!s.isActive && s.startedAt.isAfter(weekAgo)) {
        weeklyTonnage += s.totalTonnage;
      }
    }
    return (weeklyTonnage / 5000 * 100).clamp(0.0, 100.0);
  }

  /// Progress (0-100): this week tonnage vs last week
  double get progressScore {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final twoWeeksAgo = now.subtract(const Duration(days: 14));
    double thisWeek = 0, lastWeek = 0;
    for (final s in _sessions) {
      if (s.isActive) continue;
      if (s.startedAt.isAfter(weekAgo)) {
        thisWeek += s.totalTonnage;
      } else if (s.startedAt.isAfter(twoWeeksAgo)) {
        lastWeek += s.totalTonnage;
      }
    }
    if (lastWeek <= 0 && thisWeek <= 0) return 0;
    if (lastWeek <= 0) return 80; // first week training
    final ratio = thisWeek / lastWeek;
    if (ratio >= 1.1) return 100; // growing 10%+
    if (ratio >= 0.95) return 70; // stable
    if (ratio >= 0.8) return 40; // slight decline
    return 20; // significant decline
  }

  /// Variety (0-100): unique muscle groups trained this week
  double get varietyScore {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    final exerciseMuscle = <String, String>{};
    for (final ex in _exercises) {
      exerciseMuscle[ex.id] = ex.muscleGroup;
    }
    final muscleGroups = <String>{};
    for (final s in _sessions) {
      if (s.isActive || s.startedAt.isBefore(weekAgo)) continue;
      for (final set in s.sets) {
        final muscle = exerciseMuscle[set.exerciseId];
        if (muscle != null) muscleGroups.add(muscle);
      }
    }
    final count = muscleGroups.length;
    if (count >= 5) return 100;
    if (count >= 4) return 80;
    if (count >= 3) return 60;
    if (count >= 2) return 40;
    if (count >= 1) return 20;
    return 0;
  }

  // ═══════════════════════════════════════════════
  //  STATS HELPERS
  // ═══════════════════════════════════════════════

  /// Total completed sessions
  int get completedSessionCount =>
      _sessions.where((s) => !s.isActive && s.finishedAt != null).length;

  /// Total tonnage across all sessions
  double get lifetimeTonnage =>
      _sessions.fold(0.0, (sum, s) => sum + s.totalTonnage);

  /// Total training time in minutes
  int get lifetimeMinutes =>
      _sessions.fold(0, (sum, s) => sum + s.durationMin.abs());

  /// Recent sessions (last 7 days)
  List<WorkoutSession> get recentSessions {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    return _sessions.where((s) => s.startedAt.isAfter(cutoff)).toList();
  }

  /// Training streak (consecutive days with workouts)
  int get currentStreak {
    if (_sessions.isEmpty) return 0;
    final completed = _sessions
        .where((s) => !s.isActive && s.xpEarned > 0)
        .toList()
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    if (completed.isEmpty) return 0;

    int streak = 0;
    DateTime checkDay = DateTime.now();

    for (final session in completed) {
      final sessionDay = DateTime(
          session.startedAt.year, session.startedAt.month, session.startedAt.day);
      final expectedDay =
          DateTime(checkDay.year, checkDay.month, checkDay.day);
      final diff = expectedDay.difference(sessionDay).inDays;

      if (diff == 0 || diff == 1) {
        streak++;
        checkDay = sessionDay;
      } else {
        break;
      }
    }
    return streak;
  }

  // ═══════════════════════════════════════════════
  //  ANALYTICS DATA
  // ═══════════════════════════════════════════════

  /// Tonnage per session (last N sessions, oldest first)
  List<MapEntry<DateTime, double>> tonnageHistory({int last = 14}) {
    final completed = _sessions
        .where((s) => !s.isActive && s.finishedAt != null && s.totalTonnage > 0)
        .toList()
      ..sort((a, b) => a.startedAt.compareTo(b.startedAt));
    final slice =
        completed.length > last ? completed.sublist(completed.length - last) : completed;
    return slice.map((s) => MapEntry(s.startedAt, s.totalTonnage)).toList();
  }

  /// Sessions per day-of-week (Mon=1 .. Sun=7)
  Map<int, int> sessionsPerWeekday() {
    final map = <int, int>{};
    for (int d = 1; d <= 7; d++) {
      map[d] = 0;
    }
    for (final s in _sessions.where((s) => !s.isActive && s.finishedAt != null)) {
      final wd = s.startedAt.weekday; // 1=Mon .. 7=Sun
      map[wd] = (map[wd] ?? 0) + 1;
    }
    return map;
  }

  /// Muscle group distribution from exercise library
  Map<String, int> muscleGroupDistribution() {
    final map = <String, int>{};
    for (final ex in _exercises) {
      map[ex.muscleGroup] = (map[ex.muscleGroup] ?? 0) + 1;
    }
    return map;
  }

  /// Muscle group tonnage from actual completed workouts (kg)
  Map<String, double> muscleGroupTonnage() {
    final map = <String, double>{};
    // Build exerciseId → muscleGroup lookup
    final exerciseMuscle = <String, String>{};
    for (final ex in _exercises) {
      exerciseMuscle[ex.id] = ex.muscleGroup;
    }

    for (final session in _sessions) {
      if (session.isActive || session.finishedAt == null) continue;
      for (final s in session.sets) {
        final muscle = exerciseMuscle[s.exerciseId] ?? 'Другое';
        map[muscle] = (map[muscle] ?? 0) + s.tonnage;
      }
    }
    return map;
  }

  /// XP history per session
  List<MapEntry<DateTime, int>> xpHistory({int last = 14}) {
    final completed = _sessions
        .where((s) => !s.isActive && s.finishedAt != null)
        .toList()
      ..sort((a, b) => a.startedAt.compareTo(b.startedAt));
    final slice =
        completed.length > last ? completed.sublist(completed.length - last) : completed;
    return slice.map((s) => MapEntry(s.startedAt, s.xpEarned)).toList();
  }

  /// Average session duration (minutes)
  double get avgDurationMin {
    final completed = _sessions.where((s) => !s.isActive && s.durationMin.abs() > 0).toList();
    if (completed.isEmpty) return 0;
    return completed.fold(0, (sum, s) => sum + s.durationMin.abs()) / completed.length;
  }

  /// Average tonnage per session
  double get avgTonnage {
    final completed = _sessions.where((s) => !s.isActive && s.totalTonnage > 0).toList();
    if (completed.isEmpty) return 0;
    return completed.fold(0.0, (sum, s) => sum + s.totalTonnage) / completed.length;
  }

  /// Best session (highest tonnage)
  WorkoutSession? get bestSession {
    final completed = _sessions.where((s) => !s.isActive && s.totalTonnage > 0).toList();
    if (completed.isEmpty) return null;
    completed.sort((a, b) => b.totalTonnage.compareTo(a.totalTonnage));
    return completed.first;
  }

  /// Total cardio distance (km) — stored as weightKg for cardio exercises
  double get totalCardioDistance {
    final cardioIds = _exercises.where((e) => e.isCardio).map((e) => e.id).toSet();
    double total = 0;
    for (final session in _sessions) {
      if (session.isActive) continue;
      for (final s in session.sets) {
        if (cardioIds.contains(s.exerciseId) && s.weightKg > 0) {
          total += s.weightKg; // weightKg = distance (km) for cardio
        }
      }
    }
    return total;
  }

  /// Duration of last N sessions (minutes), oldest first
  List<MapEntry<DateTime, int>> sessionDurations({int last = 10}) {
    final completed = _sessions
        .where((s) => !s.isActive && s.durationMin.abs() > 0)
        .toList()
      ..sort((a, b) => a.startedAt.compareTo(b.startedAt));
    final slice =
        completed.length > last ? completed.sublist(completed.length - last) : completed;
    return slice.map((s) => MapEntry(s.startedAt, s.durationMin.abs())).toList();
  }

  /// Muscle group tonnage distribution from actual workouts (for modern chart)
  List<MapEntry<String, double>> muscleGroupTonnageSorted() {
    final map = muscleGroupTonnage();
    final entries = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }

  /// Total cardio time in minutes
  int get totalCardioMinutes {
    final cardioIds = _exercises.where((e) => e.isCardio).map((e) => e.id).toSet();
    int total = 0;
    for (final session in _sessions) {
      if (session.isActive) continue;
      for (final s in session.sets) {
        if (cardioIds.contains(s.exerciseId)) {
          total += s.reps; // reps = duration (min) for cardio
        }
      }
    }
    return total;
  }

  /// Returns data for cardio comparison chart: last 2 sessions with cardio sets.
  /// Each session → list of FlSpot(cumulativeMinutes, cumulativeKm).
  /// Returns [current, previous] or [current] or empty.
  List<List<MapEntry<double, double>>> cardioComparisonData() {
    final cardioIds = _exercises.where((e) => e.isCardio).map((e) => e.id).toSet();
    if (cardioIds.isEmpty) return [];

    // Find sessions that have cardio sets, newest first
    final sessionsWithCardio = <WorkoutSession>[];
    for (final session in _sessions
        .where((s) => !s.isActive && s.finishedAt != null)
        .toList()
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt))) {
      final hasCardio = session.sets.any((s) => cardioIds.contains(s.exerciseId));
      if (hasCardio) {
        sessionsWithCardio.add(session);
      }
      if (sessionsWithCardio.length >= 2) break;
    }

    if (sessionsWithCardio.isEmpty) return [];

    // Build cumulative points for each session
    final result = <List<MapEntry<double, double>>>[];
    for (final session in sessionsWithCardio) {
      final cardioSets = session.sets
          .where((s) => cardioIds.contains(s.exerciseId))
          .toList();

      double cumTime = 0;
      double cumDist = 0;
      final points = <MapEntry<double, double>>[
        MapEntry(0, 0), // start at origin
      ];
      for (final s in cardioSets) {
        cumTime += s.reps;     // reps = minutes
        cumDist += s.weightKg; // weightKg = km
        points.add(MapEntry(cumTime, cumDist));
      }
      result.add(points);
    }

    return result; // [0] = latest, [1] = previous (if exists)
  }
}
