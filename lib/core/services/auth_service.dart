import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import '../models/user_model.dart';
import '../networking/api_client.dart';

/// Authentication service using JWT and REST API
class AuthService extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  UserModel? _currentUser;
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
    required String firstName,
    required String lastName,
    String role = 'user',
  }) async {
    try {
      final response = await _apiClient.post(
        '/auth/signup',
        body: {
          'email': email,
          'password': password,
          'firstName': firstName,
          'lastName': lastName,
          'role': role,
        },
        requiresAuth: false,
      );

      // Extract token and user data
      final token = response['data']['token'];
      final userData = response['data']['user'];

      // Save token
      await _apiClient.saveToken(token);

      // Create user model
      _currentUser = UserModel(
        id: userData['id'],
        email: userData['email'],
        firstName: userData['firstName'],
        lastName: userData['lastName'],
        role: userData['role'],
        pointsContributed: userData['pointsContributed'] ?? 0,
        polygonesContributed: userData['polygonesContributed'] ?? 0,
        createdAt: DateTime.parse(userData['createdAt']),
      );

      // Save user data
      await _saveUserData(_currentUser!);
      notifyListeners();

      return _currentUser!;
    } on ApiException catch (e) {
      throw Exception(e.message);
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
      final response = await _apiClient.post(
        '/auth/login',
        body: {
          'email': email,
          'password': password,
        },
        requiresAuth: false,
      );

      // Extract token and user data
      final token = response['data']['token'];
      final userData = response['data']['user'];

      // Save token
      await _apiClient.saveToken(token);

      // Create user model
      _currentUser = UserModel(
        id: userData['id'],
        email: userData['email'],
        firstName: userData['firstName'],
        lastName: userData['lastName'],
        role: userData['role'],
        pointsContributed: userData['pointsContributed'] ?? 0,
        polygonesContributed: userData['polygonesContributed'] ?? 0,
      );

      // Save user data
      await _saveUserData(_currentUser!);
      notifyListeners();

      return _currentUser!;
    } on ApiException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Sign in failed: $e');
    }
  }

  /// Sign out
  Future<void> signOut() async {
    _currentUser = null;
    await _apiClient.deleteToken();
    await _clearUserData();
    notifyListeners();
  }

  /// Change password
  Future<void> changePassword(String userId, String newPassword) async {
    if (_currentUser == null) {
      throw Exception('No user signed in');
    }

    try {
      await _apiClient.put(
        '/users/$userId',
        body: {
          'password': newPassword,
        },
      );
    } on ApiException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Password change failed: $e');
    }
  }

  /// Reload current user data from API
  Future<void> reloadUser() async {
    if (_currentUser == null) {
      return;
    }

    try {
      final response = await _apiClient.get('/auth/me');
      final userData = response['data'];

      _currentUser = UserModel(
        id: userData['id'],
        email: userData['email'],
        firstName: userData['firstName'],
        lastName: userData['lastName'],
        role: userData['role'],
        pointsContributed: userData['pointsContributed'] ?? 0,
        polygonesContributed: userData['polygonesContributed'] ?? 0,
        createdAt: DateTime.parse(userData['createdAt']),
        lastLogin: userData['lastLogin'] != null
            ? DateTime.parse(userData['lastLogin'])
            : null,
      );

      await _saveUserData(_currentUser!);
      notifyListeners();
    } on ApiException catch (e) {
      print('Failed to reload user: ${e.message}');
    } catch (e) {
      print('Failed to reload user: $e');
    }
  }

  /// Get user by ID (admin function)
  Future<UserModel?> getUserById(String userId) async {
    try {
      final response = await _apiClient.get('/users/$userId');
      final userData = response['data'];

      return UserModel(
        id: userData['id'],
        email: userData['email'],
        firstName: userData['firstName'],
        lastName: userData['lastName'],
        role: userData['role'],
        pointsContributed: userData['pointsContributed'] ?? 0,
        polygonesContributed: userData['polygonesContributed'] ?? 0,
        createdAt: DateTime.parse(userData['createdAt']),
        lastLogin: userData['lastLogin'] != null
            ? DateTime.parse(userData['lastLogin'])
            : null,
      );
    } on ApiException catch (e) {
      print('Failed to get user: ${e.message}');
      return null;
    } catch (e) {
      print('Failed to get user: $e');
      return null;
    }
  }

  /// Update user role (admin function)
  Future<void> updateUserRole(String userId, String role) async {
    if (_currentUser == null || _currentUser!.role != 'admin') {
      throw Exception('Only admins can update user roles');
    }

    try {
      await _apiClient.put(
        '/users/$userId',
        body: {
          'role': role,
        },
      );
    } on ApiException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Failed to update user role: $e');
    }
  }

  /// Initialize session from stored credentials
  Future<void> initializeSession() async {
    try {
      // Check if we have a token
      final token = await _apiClient.getToken();
      if (token != null) {
        // Verify token and get user data from API
        final response = await _apiClient.get('/auth/verify');

        if (response['success'] == true) {
          // Token is valid, reload user data
          await reloadUser();
        } else {
          // Token is invalid, clear session
          await _clearSession();
        }
      } else {
        // Try to restore from local storage
        final userDataStr = await _secureStorage.read(key: _userDataKey);
        if (userDataStr != null) {
          final userData = jsonDecode(userDataStr);
          _currentUser = UserModel.fromMap(userData);
          notifyListeners();
        }
      }
    } catch (e) {
      print('Failed to initialize session: $e');
      await _clearSession();
    }
  }

  /// Save user data to secure storage
  Future<void> _saveUserData(UserModel user) async {
    try {
      await _secureStorage.write(
        key: _userDataKey,
        value: jsonEncode(user.toMap()),
      );
    } catch (e) {
      print('Failed to save user data: $e');
    }
  }

  /// Clear user data from secure storage
  Future<void> _clearUserData() async {
    try {
      await _secureStorage.delete(key: _userDataKey);
    } catch (e) {
      print('Failed to clear user data: $e');
    }
  }

  /// Clear entire session
  Future<void> _clearSession() async {
    _currentUser = null;
    await _apiClient.deleteToken();
    await _clearUserData();
    notifyListeners();
  }

  /// Verify if current token is still valid
  Future<bool> verifyToken() async {
    try {
      final response = await _apiClient.get('/auth/verify');
      return response['success'] == true;
    } catch (e) {
      return false;
    }
  }
}
