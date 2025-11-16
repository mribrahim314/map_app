import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import '../repositories/user_repository.dart';
import '../models/user_model.dart';

/// Authentication service to replace Firebase Auth
class AuthService extends ChangeNotifier {
  final UserRepository _userRepo = UserRepository();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  UserModel? _currentUser;
  static const String _userIdKey = 'user_id';
  static const String _userDataKey = 'user_data';

  /// Get current authenticated user
  UserModel? get currentUser => _currentUser;

  /// Check if user is authenticated
  bool get isAuthenticated => _currentUser != null;

  /// Get current user ID
  String? get currentUserId => _currentUser?.id;

  /// Sign up with email and password
  Future<UserModel> signUp({
    required String email,
    required String password,
    String role = 'normal',
  }) async {
    try {
      // Check if email already exists
      final exists = await _userRepo.emailExists(email);
      if (exists) {
        throw Exception('Email already exists');
      }

      // Create user
      final user = await _userRepo.createUser(
        email: email,
        password: password,
        role: role,
      );

      // Set current user and save session
      _currentUser = user;
      await _saveSession(user);
      notifyListeners();

      return user;
    } catch (e) {
      throw Exception('Sign up failed: $e');
    }
  }

  /// Sign in with email and password
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final user = await _userRepo.authenticateUser(
        email: email,
        password: password,
      );

      if (user == null) {
        throw Exception('Invalid email or password');
      }

      _currentUser = user;
      await _saveSession(user);
      notifyListeners();

      return user;
    } catch (e) {
      throw Exception('Sign in failed: $e');
    }
  }

  /// Sign out
  Future<void> signOut() async {
    _currentUser = null;
    await _clearSession();
    notifyListeners();
  }

  /// Change password
  Future<void> changePassword(String newPassword) async {
    if (_currentUser == null) {
      throw Exception('No user signed in');
    }

    try {
      await _userRepo.changePassword(_currentUser!.id, newPassword);
    } catch (e) {
      throw Exception('Password change failed: $e');
    }
  }

  /// Reload current user data
  Future<void> reloadUser() async {
    if (_currentUser == null) {
      return;
    }

    try {
      final user = await _userRepo.getUserById(_currentUser!.id);
      if (user != null) {
        _currentUser = user;
        notifyListeners();
      }
    } catch (e) {
      print('Failed to reload user: $e');
    }
  }

  /// Get user by ID (admin function)
  Future<UserModel?> getUserById(String userId) async {
    return await _userRepo.getUserById(userId);
  }

  /// Update user role (admin function)
  Future<void> updateUserRole(String userId, String role) async {
    if (_currentUser == null || _currentUser!.role != 'admin') {
      throw Exception('Only admins can update user roles');
    }

    try {
      await _userRepo.updateUserRole(userId, role);
    } catch (e) {
      throw Exception('Failed to update user role: $e');
    }
  }

  /// Send contribution request
  Future<void> sendContributionRequest() async {
    if (_currentUser == null) {
      throw Exception('No user signed in');
    }

    try {
      await _userRepo.updateContributionRequest(_currentUser!.id, true);
      await reloadUser(); // Reload to get updated data
    } catch (e) {
      throw Exception('Failed to send contribution request: $e');
    }
  }

  /// Increment contribution count (called when user submits data)
  Future<void> incrementContribution() async {
    if (_currentUser == null) {
      throw Exception('No user signed in');
    }

    try {
      await _userRepo.incrementContributionCount(_currentUser!.id);
      await reloadUser(); // Reload to get updated count
    } catch (e) {
      throw Exception('Failed to increment contribution: $e');
    }
  }

  /// Initialize session from stored credentials
  Future<void> initializeSession() async {
    try {
      final userId = await _secureStorage.read(key: _userIdKey);
      if (userId != null) {
        final user = await _userRepo.getUserById(userId);
        if (user != null) {
          _currentUser = user;
          notifyListeners();
        } else {
          // User not found, clear session
          await _clearSession();
        }
      }
    } catch (e) {
      print('Failed to initialize session: $e');
      await _clearSession();
    }
  }

  /// Save user session to secure storage
  Future<void> _saveSession(UserModel user) async {
    try {
      await _secureStorage.write(key: _userIdKey, value: user.id);
      await _secureStorage.write(
        key: _userDataKey,
        value: jsonEncode(user.toMap()),
      );
    } catch (e) {
      print('Failed to save session: $e');
    }
  }

  /// Clear user session from secure storage
  Future<void> _clearSession() async {
    try {
      await _secureStorage.delete(key: _userIdKey);
      await _secureStorage.delete(key: _userDataKey);
    } catch (e) {
      print('Failed to clear session: $e');
    }
  }
}
