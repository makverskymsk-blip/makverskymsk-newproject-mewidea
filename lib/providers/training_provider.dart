import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/exercise.dart';
import '../models/workout_session.dart';
import '../services/supabase_service.dart';

/// Manages workout sessions, exercises, XP, and training state.
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

  // ─── XP state (synced from user profile) ───
  int _xp = 0;
  int _level = 1;
  int get xp => _xp;
  int get level => _level;
  int get xpForNextLevel => (500 * math.pow(_level, 1.5)).round();
  double get xpProgress => xpForNextLevel > 0 ? (_xp / xpForNextLevel).clamp(0.0, 1.0) : 0.0;

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
    _xp = initialXp;
    _level = initialLevel;
    await Future.wait([
      loadExercises(userId),
      loadSessions(userId),
    ]);
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
        'started_at': DateTime.now().toIso8601String(),
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
      final setOrder = _activeSession!.sets.length + 1;
      final result = await _db.createWorkoutSet({
        'session_id': _activeSession!.id,
        'exercise_id': exerciseId,
        'exercise_name': exerciseName,
        'set_order': setOrder,
        'weight_kg': weightKg,
        'reps': reps,
        'rpe_score': rpeScore,
        'is_completed': true,
      });
      final newSet = WorkoutSet.fromMap(result);
      _activeSession!.sets.add(newSet);
      notifyListeners();
      debugPrint('TRAINING: Added set #$setOrder — $exerciseName ${weightKg}kg × $reps');
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
      final now = DateTime.now();

      // Calculate stats
      final durationMin = now.difference(session.startedAt).inMinutes;
      double totalTonnage = 0;
      for (final s in session.sets) {
        totalTonnage += s.tonnage;
      }
      final totalSets = session.sets.length;

      // Calculate XP
      final xpEarned = _calculateXp(
        durationMin: durationMin,
        totalSets: totalSets,
        totalTonnage: totalTonnage,
      );

      // Update session in DB
      await _db.updateWorkoutSession(session.id, {
        'finished_at': now.toIso8601String(),
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

      // Award XP and check level-up
      _awardXp(xpEarned);

      // Save XP to DB
      if (userId != null) {
        await _db.updateTrainingXpAndLevel(userId!, _xp, _level);
      }

      _activeSession = null;
      notifyListeners();

      debugPrint('TRAINING: Finished! Duration=${durationMin}m, '
          'Sets=$totalSets, Tonnage=${totalTonnage.toStringAsFixed(0)}kg, '
          'XP=$xpEarned');
      return xpEarned;
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
        'finished_at': DateTime.now().toIso8601String(),
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

  // ═══════════════════════════════════════════════
  //  XP & LEVELING
  // ═══════════════════════════════════════════════

  /// Calculate XP for a workout
  int _calculateXp({
    required int durationMin,
    required int totalSets,
    required double totalTonnage,
  }) {
    // Base XP: 10 per set completed
    int baseXp = totalSets * 10;

    // Duration bonus: 1 XP per minute (capped at 120)
    int durationBonus = durationMin.clamp(0, 120);

    // Tonnage bonus: 1 XP per 100kg total
    int tonnageBonus = (totalTonnage / 100).round();

    // Consistency bonus: +25% if 3+ sets
    double multiplier = totalSets >= 3 ? 1.25 : 1.0;

    return ((baseXp + durationBonus + tonnageBonus) * multiplier).round();
  }

  /// Award XP and handle level-up
  void _awardXp(int amount) {
    _xp += amount;
    // Check for level-up(s)
    while (_xp >= xpForNextLevel) {
      _xp -= xpForNextLevel;
      _level++;
      debugPrint('TRAINING: 🎉 LEVEL UP! Now level $_level');
    }
  }

  // ═══════════════════════════════════════════════
  //  STATS HELPERS
  // ═══════════════════════════════════════════════

  /// Total completed sessions
  int get completedSessionCount =>
      _sessions.where((s) => !s.isActive && s.xpEarned > 0).length;

  /// Total tonnage across all sessions
  double get lifetimeTonnage =>
      _sessions.fold(0.0, (sum, s) => sum + s.totalTonnage);

  /// Total training time in minutes
  int get lifetimeMinutes =>
      _sessions.fold(0, (sum, s) => sum + s.durationMin);

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
        .where((s) => !s.isActive && s.xpEarned > 0)
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
    for (final s in _sessions.where((s) => !s.isActive && s.xpEarned > 0)) {
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

  /// XP history per session
  List<MapEntry<DateTime, int>> xpHistory({int last = 14}) {
    final completed = _sessions
        .where((s) => !s.isActive && s.xpEarned > 0)
        .toList()
      ..sort((a, b) => a.startedAt.compareTo(b.startedAt));
    final slice =
        completed.length > last ? completed.sublist(completed.length - last) : completed;
    return slice.map((s) => MapEntry(s.startedAt, s.xpEarned)).toList();
  }

  /// Average session duration (minutes)
  double get avgDurationMin {
    final completed = _sessions.where((s) => !s.isActive && s.durationMin > 0).toList();
    if (completed.isEmpty) return 0;
    return completed.fold(0, (sum, s) => sum + s.durationMin) / completed.length;
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
}
