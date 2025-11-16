import 'package:map_app/core/networking/api_client.dart';

/// Service for managing projects via the backend API
/// Projects represent data collection campaigns
class ProjectService {
  final ApiClient _apiClient = ApiClient();

  /// Create a new project
  ///
  /// Parameters:
  /// - name: Project name
  /// - description: Optional project description
  /// - projectType: Type of project (e.g., 'survey', 'research')
  /// - startDate: Project start date
  /// - endDate: Optional project end date
  ///
  /// Returns the created project data
  Future<Map<String, dynamic>> createProject({
    required String name,
    String? description,
    required String projectType,
    required DateTime startDate,
    DateTime? endDate,
  }) async {
    try {
      final response = await _apiClient.post(
        '/projects',
        body: {
          'name': name,
          if (description != null) 'description': description,
          'projectType': projectType,
          'startDate': startDate.toIso8601String(),
          if (endDate != null) 'endDate': endDate.toIso8601String(),
        },
      );

      return response['data'] as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  /// Get all projects
  ///
  /// Returns list of all projects
  Future<List<Map<String, dynamic>>> getAllProjects() async {
    try {
      final response = await _apiClient.get('/projects');
      final data = response['data'] as List;
      return data.map((item) => item as Map<String, dynamic>).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get a specific project by ID
  ///
  /// Parameters:
  /// - id: The project ID
  ///
  /// Returns the project data with statistics
  Future<Map<String, dynamic>> getProjectById(int id) async {
    try {
      final response = await _apiClient.get('/projects/$id');
      return response['data'] as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  /// Update an existing project
  ///
  /// Parameters:
  /// - id: The project ID to update
  /// - name: Updated project name
  /// - description: Updated description
  /// - projectType: Updated project type
  /// - isActive: Updated active status
  /// - startDate: Updated start date
  /// - endDate: Updated end date
  ///
  /// Returns the updated project data
  Future<Map<String, dynamic>> updateProject({
    required int id,
    String? name,
    String? description,
    String? projectType,
    bool? isActive,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (description != null) body['description'] = description;
      if (projectType != null) body['projectType'] = projectType;
      if (isActive != null) body['isActive'] = isActive;
      if (startDate != null) body['startDate'] = startDate.toIso8601String();
      if (endDate != null) body['endDate'] = endDate.toIso8601String();

      final response = await _apiClient.put(
        '/projects/$id',
        body: body,
      );

      return response['data'] as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a project
  ///
  /// Parameters:
  /// - id: The project ID to delete
  ///
  /// Returns success status
  Future<bool> deleteProject(int id) async {
    try {
      final response = await _apiClient.delete('/projects/$id');
      return response['success'] == true;
    } catch (e) {
      rethrow;
    }
  }

  /// Add a contributor to a project
  ///
  /// Parameters:
  /// - projectId: The project ID
  /// - userId: The user ID to add as contributor
  ///
  /// Returns success status
  Future<bool> addContributor({
    required int projectId,
    required int userId,
  }) async {
    try {
      final response = await _apiClient.post(
        '/projects/$projectId/contributors',
        body: {
          'userId': userId,
        },
      );

      return response['success'] == true;
    } catch (e) {
      rethrow;
    }
  }

  /// Remove a contributor from a project
  ///
  /// Parameters:
  /// - projectId: The project ID
  /// - userId: The user ID to remove
  ///
  /// Returns success status
  Future<bool> removeContributor({
    required int projectId,
    required int userId,
  }) async {
    try {
      final response = await _apiClient.delete(
        '/projects/$projectId/contributors/$userId',
      );

      return response['success'] == true;
    } catch (e) {
      rethrow;
    }
  }
}
