/// Database configuration constants
/// In production, load these from environment variables or secure storage
class DbConfig {
  // Default development configuration
  // TODO: Replace with environment variables in production
  static const String host = 'localhost';
  static const int port = 5432;
  static const String databaseName = 'map_app';
  static const String username = 'postgres';
  static const String password = 'postgres';

  // Connection pool settings
  static const int maxConnections = 10;
  static const Duration connectionTimeout = Duration(seconds: 10);
  static const Duration queryTimeout = Duration(seconds: 30);

  /// Initialize database service with configuration
  static Future<void> initialize() async {
    // TODO: Load from environment variables or secure storage
    // For now, using hardcoded values for development
    // In production, you might load from .env file or platform-specific secure storage
  }
}
