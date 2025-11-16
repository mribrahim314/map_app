import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:map_app/core/config/app_config.dart';

/// API Client for making HTTP requests to the backend
/// Handles authentication, request/response formatting, and error handling
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  final _storage = const FlutterSecureStorage();
  String get baseUrl => AppConfig.apiBaseUrl;

  // Token management
  Future<void> saveToken(String token) async {
    await _storage.write(key: 'jwt_token', value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: 'jwt_token');
  }

  /// Get authorization headers with JWT token
  Future<Map<String, String>> _getHeaders({bool includeAuth = true}) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (includeAuth) {
      final token = await getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  /// Handle API response and errors
  dynamic _handleResponse(http.Response response) {
    final Map<String, dynamic> data = json.decode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    } else {
      // Extract error message
      final message = data['message'] ?? 'An error occurred';
      throw ApiException(
        message: message,
        statusCode: response.statusCode,
        errors: data['errors'],
      );
    }
  }

  /// GET request
  Future<dynamic> get(
    String endpoint, {
    Map<String, String>? queryParams,
    bool requiresAuth = true,
  }) async {
    try {
      var uri = Uri.parse('$baseUrl$endpoint');
      if (queryParams != null && queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }

      final headers = await _getHeaders(includeAuth: requiresAuth);
      final response = await http.get(uri, headers: headers);

      return _handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  /// POST request
  Future<dynamic> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final headers = await _getHeaders(includeAuth: requiresAuth);

      final response = await http.post(
        uri,
        headers: headers,
        body: body != null ? json.encode(body) : null,
      );

      return _handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  /// PUT request
  Future<dynamic> put(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final headers = await _getHeaders(includeAuth: requiresAuth);

      final response = await http.put(
        uri,
        headers: headers,
        body: body != null ? json.encode(body) : null,
      );

      return _handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  /// DELETE request
  Future<dynamic> delete(
    String endpoint, {
    bool requiresAuth = true,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final headers = await _getHeaders(includeAuth: requiresAuth);

      final response = await http.delete(uri, headers: headers);

      return _handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }
}

/// Custom exception for API errors
class ApiException implements Exception {
  final String message;
  final int statusCode;
  final List<dynamic>? errors;

  ApiException({
    required this.message,
    required this.statusCode,
    this.errors,
  });

  @override
  String toString() {
    if (errors != null && errors!.isNotEmpty) {
      final errorMessages = errors!.map((e) => e['message']).join(', ');
      return 'ApiException ($statusCode): $message - $errorMessages';
    }
    return 'ApiException ($statusCode): $message';
  }
}
