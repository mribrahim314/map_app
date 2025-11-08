import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Database configuration loaded from environment variables
class DbConfig {
  // Load configuration from .env file
  static String get host => dotenv.env['DB_HOST'] ?? 'localhost';
  static int get port => int.tryParse(dotenv.env['DB_PORT'] ?? '5432') ?? 5432;
  static String get databaseName => dotenv.env['DB_NAME'] ?? 'map_app';
  static String get username => dotenv.env['DB_USER'] ?? 'postgres';
  static String get password => dotenv.env['DB_PASSWORD'] ?? 'postgres';

  // Supabase configuration
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  // Security
  static String get jwtSecret => dotenv.env['JWT_SECRET'] ?? 'change_this_in_production';

  // Connection pool settings
  static const int maxConnections = 10;
  static const Duration connectionTimeout = Duration(seconds: 10);
  static const Duration queryTimeout = Duration(seconds: 30);

  /// Initialize and load environment variables
  static Future<void> initialize() async {
    try {
      await dotenv.load(fileName: '.env');
      print('Environment variables loaded successfully');
    } catch (e) {
      print('Warning: Could not load .env file. Using default values. Error: $e');
    }
  }

  /// Validate configuration
  static bool validate() {
    if (host.isEmpty || databaseName.isEmpty || username.isEmpty) {
      print('Error: Database configuration is incomplete');
      return false;
    }
    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      print('Warning: Supabase configuration is missing');
    }
    return true;
  }
}
