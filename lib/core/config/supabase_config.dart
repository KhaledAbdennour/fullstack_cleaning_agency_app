import 'package:supabase_flutter/supabase_flutter.dart';
import '../env/env_helper.dart';

/// Supabase client singleton
class SupabaseConfig {
  static SupabaseClient? _client;

  /// Initialize Supabase with environment variables
  static Future<void> initialize() async {
    try {
      EnvHelper.validate();
      
      await Supabase.initialize(
        url: EnvHelper.supabaseUrl,
        anonKey: EnvHelper.supabaseAnonKey,
      );
      
      _client = Supabase.instance.client;
    } catch (e) {
      throw Exception('Failed to initialize Supabase: $e');
    }
  }

  /// Get the Supabase client instance
  static SupabaseClient get client {
    if (_client == null) {
      throw Exception('Supabase not initialized. Call SupabaseConfig.initialize() first.');
    }
    return _client!;
  }

  /// Get the current authenticated user
  static User? get currentUser => client.auth.currentUser;

  /// Check if user is authenticated
  static bool get isAuthenticated => currentUser != null;
}

