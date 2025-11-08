import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../database/database_service.dart';
import '../models/user_model.dart';

/// Repository for user database operations
class UserRepository {
  final DatabaseService _db = DatabaseService.instance;
  final _uuid = Uuid();

  /// Create a new user with email and password
  Future<UserModel> createUser({
    required String email,
    required String password,
    String role = 'normal',
  }) async {
    // Hash password
    final passwordHash = _hashPassword(password);

    // Generate user ID
    final userId = _uuid.v4();

    final result = await _db.query(
      '''
      INSERT INTO users (id, email, password_hash, role, contribution_count, contribution_request_sent, created_at, updated_at)
      VALUES (@id, @email, @password_hash, @role, 0, FALSE, NOW(), NOW())
      RETURNING id, email, role, contribution_count, contribution_request_sent, created_at, updated_at
      ''',
      parameters: {
        'id': userId,
        'email': email,
        'password_hash': passwordHash,
        'role': role,
      },
    );

    if (result.isEmpty) {
      throw Exception('Failed to create user');
    }

    return UserModel.fromMap(result.first.toColumnMap());
  }

  /// Authenticate user with email and password
  Future<UserModel?> authenticateUser({
    required String email,
    required String password,
  }) async {
    final passwordHash = _hashPassword(password);

    final result = await _db.query(
      '''
      SELECT id, email, role, contribution_count, contribution_request_sent, created_at, updated_at
      FROM users
      WHERE email = @email AND password_hash = @password_hash
      ''',
      parameters: {
        'email': email,
        'password_hash': passwordHash,
      },
    );

    if (result.isEmpty) {
      return null;
    }

    return UserModel.fromMap(result.first.toColumnMap());
  }

  /// Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    final result = await _db.query(
      '''
      SELECT id, email, role, contribution_count, contribution_request_sent, created_at, updated_at
      FROM users
      WHERE id = @userId
      ''',
      parameters: {'userId': userId},
    );

    if (result.isEmpty) {
      return null;
    }

    return UserModel.fromMap(result.first.toColumnMap());
  }

  /// Get user by email
  Future<UserModel?> getUserByEmail(String email) async {
    final result = await _db.query(
      '''
      SELECT id, email, role, contribution_count, contribution_request_sent, created_at, updated_at
      FROM users
      WHERE email = @email
      ''',
      parameters: {'email': email},
    );

    if (result.isEmpty) {
      return null;
    }

    return UserModel.fromMap(result.first.toColumnMap());
  }

  /// Get all users (for admin)
  Future<List<UserModel>> getAllUsers() async {
    final result = await _db.query(
      '''
      SELECT id, email, role, contribution_count, contribution_request_sent, created_at, updated_at
      FROM users
      ORDER BY created_at DESC
      ''',
    );

    return result.map((row) => UserModel.fromMap(row.toColumnMap())).toList();
  }

  /// Update user role
  Future<void> updateUserRole(String userId, String role) async {
    await _db.query(
      '''
      UPDATE users
      SET role = @role, updated_at = NOW()
      WHERE id = @userId
      ''',
      parameters: {
        'userId': userId,
        'role': role,
      },
    );
  }

  /// Update contribution request status
  Future<void> updateContributionRequest(String userId, bool sent) async {
    await _db.query(
      '''
      UPDATE users
      SET contribution_request_sent = @sent, updated_at = NOW()
      WHERE id = @userId
      ''',
      parameters: {
        'userId': userId,
        'sent': sent,
      },
    );
  }

  /// Increment user contribution count
  Future<void> incrementContributionCount(String userId) async {
    await _db.query(
      '''
      SELECT increment_contribution_count(@userId)
      ''',
      parameters: {'userId': userId},
    );
  }

  /// Change user password
  Future<void> changePassword(String userId, String newPassword) async {
    final passwordHash = _hashPassword(newPassword);

    await _db.query(
      '''
      UPDATE users
      SET password_hash = @password_hash, updated_at = NOW()
      WHERE id = @userId
      ''',
      parameters: {
        'userId': userId,
        'password_hash': passwordHash,
      },
    );
  }

  /// Delete user (admin operation)
  Future<void> deleteUser(String userId) async {
    await _db.query(
      'DELETE FROM users WHERE id = @userId',
      parameters: {'userId': userId},
    );
  }

  /// Hash password using SHA256
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  /// Check if email exists
  Future<bool> emailExists(String email) async {
    final result = await _db.query(
      'SELECT COUNT(*) as count FROM users WHERE email = @email',
      parameters: {'email': email},
    );

    final count = result.first.toColumnMap()['count'] as int;
    return count > 0;
  }

  /// Stream all users (for real-time updates in admin screen)
  /// Note: PostgreSQL doesn't have built-in real-time like Firestore
  /// Consider using PostgreSQL LISTEN/NOTIFY or polling
  Future<List<UserModel>> streamUsers() async {
    return getAllUsers();
  }
}
