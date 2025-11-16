import 'package:map_app/core/networking/api_client.dart';

/// Service for managing users via the backend API
/// Provides user management functionality for admin users
class UserService {
  final ApiClient _apiClient = ApiClient();

  /// Get all users (admin only)
  ///
  /// Returns list of all users
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final response = await _apiClient.get('/users');
      final data = response['data'] as List;
      return data.map((item) => item as Map<String, dynamic>).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get a specific user by ID
  ///
  /// Parameters:
  /// - id: The user ID
  ///
  /// Returns the user data
  Future<Map<String, dynamic>> getUserById(int id) async {
    try {
      final response = await _apiClient.get('/users/$id');
      return response['data'] as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  /// Update an existing user
  ///
  /// Parameters:
  /// - id: The user ID to update
  /// - firstName: Updated first name
  /// - lastName: Updated last name
  /// - email: Updated email
  /// - phone: Updated phone number
  /// - organization: Updated organization
  /// - role: Updated role ('user' or 'admin')
  ///
  /// Returns the updated user data
  Future<Map<String, dynamic>> updateUser({
    required int id,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? organization,
    String? role,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (firstName != null) body['firstName'] = firstName;
      if (lastName != null) body['lastName'] = lastName;
      if (email != null) body['email'] = email;
      if (phone != null) body['phone'] = phone;
      if (organization != null) body['organization'] = organization;
      if (role != null) body['role'] = role;

      final response = await _apiClient.put(
        '/users/$id',
        body: body,
      );

      return response['data'] as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a user (admin only)
  ///
  /// Parameters:
  /// - id: The user ID to delete
  ///
  /// Returns success status
  Future<bool> deleteUser(int id) async {
    try {
      final response = await _apiClient.delete('/users/$id');
      return response['success'] == true;
    } catch (e) {
      rethrow;
    }
  }

  /// Get user statistics
  ///
  /// Parameters:
  /// - id: The user ID
  ///
  /// Returns user statistics including contribution counts
  Future<Map<String, dynamic>> getUserStats(int id) async {
    try {
      final response = await _apiClient.get('/users/$id/stats');
      return response['data'] as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }
}
