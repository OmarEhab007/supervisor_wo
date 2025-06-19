// lib/core/network/supabase_client.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseClientWrapper {
  static Future<void> initialize({
    required String url,
    required String anonKey,
  }) async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
