import 'package:postgres/postgres.dart';
import 'dart:async';

/// PostgreSQL database service for managing connections and queries
class DatabaseService {
  static DatabaseService? _instance;
  Connection? _connection;

  // Database configuration
  final String host;
  final int port;
  final String databaseName;
  final String username;
  final String password;

  DatabaseService._({
    required this.host,
    required this.port,
    required this.databaseName,
    required this.username,
    required this.password,
  });

  /// Get singleton instance
  static DatabaseService get instance {
    if (_instance == null) {
      throw Exception('DatabaseService not initialized. Call DatabaseService.initialize() first.');
    }
    return _instance!;
  }

  /// Initialize database service with configuration
  static void initialize({
    required String host,
    required int port,
    required String databaseName,
    required String username,
    required String password,
  }) {
    _instance = DatabaseService._(
      host: host,
      port: port,
      databaseName: databaseName,
      username: username,
      password: password,
    );
  }

  /// Get database connection (creates if doesn't exist)
  Future<Connection> getConnection() async {
    if (_connection != null && !_connection!.isOpen) {
      await _connection!.close();
      _connection = null;
    }

    if (_connection == null) {
      _connection = await Connection.open(
        Endpoint(
          host: host,
          port: port,
          database: databaseName,
          username: username,
          password: password,
        ),
        settings: ConnectionSettings(
          sslMode: SslMode.disable, // Change to require/verifyFull for production
          connectTimeout: Duration(seconds: 10),
        ),
      );
    }

    return _connection!;
  }

  /// Execute a query and return results
  Future<Result> query(
    String query, {
    Map<String, dynamic>? parameters,
  }) async {
    final conn = await getConnection();
    return await conn.execute(
      Sql.named(query),
      parameters: parameters ?? {},
    );
  }

  /// Execute a query with positional parameters
  Future<Result> execute(
    String query, {
    List<dynamic>? parameters,
  }) async {
    final conn = await getConnection();
    return await conn.execute(
      query,
      parameters: parameters,
    );
  }

  /// Close database connection
  Future<void> close() async {
    if (_connection != null) {
      await _connection!.close();
      _connection = null;
    }
  }

  /// Test database connection
  Future<bool> testConnection() async {
    try {
      final conn = await getConnection();
      final result = await conn.execute('SELECT 1');
      return result.isNotEmpty;
    } catch (e) {
      print('Database connection test failed: $e');
      return false;
    }
  }

  /// Execute transaction
  Future<T> transaction<T>(Future<T> Function(Connection) action) async {
    final conn = await getConnection();

    await conn.execute('BEGIN');

    try {
      final result = await action(conn);
      await conn.execute('COMMIT');
      return result;
    } catch (e) {
      await conn.execute('ROLLBACK');
      rethrow;
    }
  }
}
