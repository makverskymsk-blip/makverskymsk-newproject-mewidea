import 'package:supabase_flutter/supabase_flutter.dart';

/// Base class for all domain repositories.
/// Provides shared access to the Supabase client.
abstract class BaseRepository {
  final SupabaseClient supabase = Supabase.instance.client;
}
