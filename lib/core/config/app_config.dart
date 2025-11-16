import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Application configuration loaded from .env file
class AppConfig {
  static Future<void> initialize() async {
    await dotenv.load(fileName: ".env");
  }

  /// Backend API base URL
  static String get apiBaseUrl {
    return dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000/api';
  }

  /// Supabase URL for image storage
  static String get supabaseUrl {
    return dotenv.env['SUPABASE_URL'] ?? '';
  }

  /// Supabase anonymous key
  static String get supabaseAnonKey {
    return dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  }

  /// Validate that all required configuration values are present
  static bool validate() {
    final hasApiUrl = apiBaseUrl.isNotEmpty;
    final hasSupabaseUrl = supabaseUrl.isNotEmpty;
    final hasSupabaseKey = supabaseAnonKey.isNotEmpty;

    if (!hasApiUrl) {
      print('Warning: API_BASE_URL is missing from .env file');
    }
    if (!hasSupabaseUrl || !hasSupabaseKey) {
      print('Warning: Supabase configuration is incomplete');
    }

    return hasApiUrl;
  }
}
