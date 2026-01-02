/// Environment variable helper for Supabase configuration
/// 
/// Usage:
/// - For development: Use --dart-define flags
/// - For production: Set environment variables or use .env file
class EnvHelper {
  // Supabase configuration
  static String get supabaseUrl {
    const url = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
    if (url.isEmpty) {
      throw Exception(
        'SUPABASE_URL not set. Use --dart-define=SUPABASE_URL=your_url or set environment variable.',
      );
    }
    return url;
  }

  static String get supabaseAnonKey {
    const key = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');
    if (key.isEmpty) {
      throw Exception(
        'SUPABASE_ANON_KEY not set. Use --dart-define=SUPABASE_ANON_KEY=your_key or set environment variable.',
      );
    }
    return key;
  }

  /// Validate that required environment variables are set
  static void validate() {
    supabaseUrl;
    supabaseAnonKey;
  }
}

