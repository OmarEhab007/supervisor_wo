import 'package:supabase_flutter/supabase_flutter.dart';

/// A wrapper class for the Supabase client to provide centralized access
class SupabaseClientWrapper {
  /// The Supabase client instance
  static late final SupabaseClient _client;

  /// Get the Supabase client instance
  static SupabaseClient get client => _client;

  /// Initialize the Supabase client
  static Future<void> initialize({
    required String url,
    required String anonKey,
  }) async {
    try {
      await Supabase.initialize(
        url: url,
        anonKey: anonKey,
      );
      _client = Supabase.instance.client;
    } catch (e) {
      throw Exception('Failed to initialize Supabase: $e');
    }
  }
}
