import 'base_repository.dart';

/// Repository for exercises, workout sessions, sets, XP.
class TrainingRepository extends BaseRepository {
  static final TrainingRepository _instance = TrainingRepository._internal();
  factory TrainingRepository() => _instance;
  TrainingRepository._internal();

  // ───── Exercises ─────

  Future<List<Map<String, dynamic>>> getExercises(String userId) async {
    final data = await supabase
        .from('exercises')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<Map<String, dynamic>> createExercise(Map<String, dynamic> exercise) async {
    final result = await supabase
        .from('exercises')
        .insert(exercise)
        .select()
        .single();
    return result;
  }

  Future<void> updateExercise(String id, Map<String, dynamic> data) async {
    await supabase.from('exercises').update(data).eq('id', id);
  }

  Future<void> deleteExercise(String id) async {
    await supabase.from('exercises').delete().eq('id', id);
  }

  // ───── Workout Sessions ─────

  Future<Map<String, dynamic>> createWorkoutSession(Map<String, dynamic> session) async {
    final result = await supabase
        .from('workout_sessions')
        .insert(session)
        .select()
        .single();
    return result;
  }

  Future<List<Map<String, dynamic>>> getWorkoutSessions(String userId, {int limit = 50}) async {
    final data = await supabase
        .from('workout_sessions')
        .select()
        .eq('user_id', userId)
        .order('started_at', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> updateWorkoutSession(String id, Map<String, dynamic> data) async {
    await supabase.from('workout_sessions').update(data).eq('id', id);
  }

  Future<void> deleteWorkoutSession(String sessionId) async {
    await supabase.from('workout_sets').delete().eq('session_id', sessionId);
    await supabase.from('workout_sessions').delete().eq('id', sessionId);
  }

  // ───── Workout Sets ─────

  Future<Map<String, dynamic>> createWorkoutSet(Map<String, dynamic> setData) async {
    final result = await supabase
        .from('workout_sets')
        .insert(setData)
        .select()
        .single();
    return result;
  }

  Future<List<Map<String, dynamic>>> getWorkoutSets(String sessionId) async {
    final data = await supabase
        .from('workout_sets')
        .select()
        .eq('session_id', sessionId)
        .order('set_order', ascending: true);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> updateWorkoutSet(String id, Map<String, dynamic> data) async {
    await supabase.from('workout_sets').update(data).eq('id', id);
  }

  Future<void> deleteWorkoutSet(String id) async {
    await supabase.from('workout_sets').delete().eq('id', id);
  }

  // ───── Training XP ─────

  Future<void> updateTrainingXpAndLevel(String userId, int xp, int level) async {
    await supabase.from('users').update({
      'training_xp': xp,
      'training_level': level,
    }).eq('id', userId);
  }
}
