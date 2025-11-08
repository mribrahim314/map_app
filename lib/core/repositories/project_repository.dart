import '../database/database_service.dart';
import '../models/project_model.dart';

/// Repository for project database operations
class ProjectRepository {
  final DatabaseService _db = DatabaseService.instance;

  /// Create a new project (admin only)
  Future<ProjectModel> createProject({
    required String name,
    String? description,
    required String projectType,
    required String createdBy,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final result = await _db.query(
      '''
      INSERT INTO projects (name, description, project_type, created_by, start_date, end_date, is_active)
      VALUES (@name, @description, @project_type, @created_by, @start_date, @end_date, TRUE)
      RETURNING id, name, description, project_type, created_by, is_active, start_date, end_date, created_at, updated_at
      ''',
      parameters: {
        'name': name,
        'description': description,
        'project_type': projectType,
        'created_by': createdBy,
        'start_date': startDate ?? DateTime.now(),
        'end_date': endDate,
      },
    );

    if (result.isEmpty) {
      throw Exception('Failed to create project');
    }

    return ProjectModel.fromMap(result.first.toColumnMap());
  }

  /// Get project by ID
  Future<ProjectModel?> getProjectById(int projectId) async {
    final result = await _db.query(
      '''
      SELECT id, name, description, project_type, created_by, is_active, start_date, end_date, created_at, updated_at
      FROM projects
      WHERE id = @project_id
      ''',
      parameters: {'project_id': projectId},
    );

    if (result.isEmpty) {
      return null;
    }

    return ProjectModel.fromMap(result.first.toColumnMap());
  }

  /// Get all projects
  Future<List<ProjectModel>> getAllProjects({bool? isActive}) async {
    final query = isActive != null
        ? '''
          SELECT id, name, description, project_type, created_by, is_active, start_date, end_date, created_at, updated_at
          FROM projects
          WHERE is_active = @is_active
          ORDER BY created_at DESC
          '''
        : '''
          SELECT id, name, description, project_type, created_by, is_active, start_date, end_date, created_at, updated_at
          FROM projects
          ORDER BY created_at DESC
          ''';

    final result = await _db.query(
      query,
      parameters: isActive != null ? {'is_active': isActive} : {},
    );

    return result.map((row) => ProjectModel.fromMap(row.toColumnMap())).toList();
  }

  /// Get projects accessible to a user
  Future<List<ProjectModel>> getUserProjects(String userId) async {
    final result = await _db.query(
      '''
      SELECT DISTINCT p.id, p.name, p.description, p.project_type, p.created_by, p.is_active,
             p.start_date, p.end_date, p.created_at, p.updated_at
      FROM projects p
      LEFT JOIN project_contributors pc ON p.id = pc.project_id
      WHERE p.created_by = @user_id OR pc.user_id = @user_id
      ORDER BY p.created_at DESC
      ''',
      parameters: {'user_id': userId},
    );

    return result.map((row) => ProjectModel.fromMap(row.toColumnMap())).toList();
  }

  /// Get project statistics
  Future<ProjectStats?> getProjectStats(int projectId) async {
    final result = await _db.query(
      '''
      SELECT * FROM project_stats WHERE id = @project_id
      ''',
      parameters: {'project_id': projectId},
    );

    if (result.isEmpty) {
      return null;
    }

    return ProjectStats.fromMap(result.first.toColumnMap());
  }

  /// Get all project statistics
  Future<List<ProjectStats>> getAllProjectStats() async {
    final result = await _db.query('SELECT * FROM project_stats ORDER BY created_at DESC');
    return result.map((row) => ProjectStats.fromMap(row.toColumnMap())).toList();
  }

  /// Update project
  Future<void> updateProject({
    required int projectId,
    String? name,
    String? description,
    String? projectType,
    bool? isActive,
    DateTime? endDate,
  }) async {
    final updates = <String>[];
    final parameters = <String, dynamic>{'project_id': projectId};

    if (name != null) {
      updates.add('name = @name');
      parameters['name'] = name;
    }
    if (description != null) {
      updates.add('description = @description');
      parameters['description'] = description;
    }
    if (projectType != null) {
      updates.add('project_type = @project_type');
      parameters['project_type'] = projectType;
    }
    if (isActive != null) {
      updates.add('is_active = @is_active');
      parameters['is_active'] = isActive;
    }
    if (endDate != null) {
      updates.add('end_date = @end_date');
      parameters['end_date'] = endDate;
    }

    if (updates.isEmpty) return;

    await _db.query(
      '''
      UPDATE projects
      SET ${updates.join(', ')}, updated_at = NOW()
      WHERE id = @project_id
      ''',
      parameters: parameters,
    );
  }

  /// Delete project (admin only)
  Future<void> deleteProject(int projectId) async {
    await _db.query(
      'DELETE FROM projects WHERE id = @project_id',
      parameters: {'project_id': projectId},
    );
  }

  /// Add contributor to project
  Future<void> addContributor(int projectId, String userId) async {
    await _db.query(
      'SELECT add_user_to_project(@project_id, @user_id)',
      parameters: {
        'project_id': projectId,
        'user_id': userId,
      },
    );
  }

  /// Remove contributor from project
  Future<void> removeContributor(int projectId, String userId) async {
    await _db.query(
      'SELECT remove_user_from_project(@project_id, @user_id)',
      parameters: {
        'project_id': projectId,
        'user_id': userId,
      },
    );
  }

  /// Get contributors for a project
  Future<List<String>> getProjectContributors(int projectId) async {
    final result = await _db.query(
      '''
      SELECT user_id FROM project_contributors WHERE project_id = @project_id
      ''',
      parameters: {'project_id': projectId},
    );

    return result.map((row) => row.toColumnMap()['user_id'] as String).toList();
  }

  /// Check if user has access to project
  Future<bool> userHasAccess(int projectId, String userId) async {
    final result = await _db.query(
      'SELECT user_has_project_access(@project_id, @user_id) as has_access',
      parameters: {
        'project_id': projectId,
        'user_id': userId,
      },
    );

    return result.first.toColumnMap()['has_access'] as bool;
  }

  /// Activate/deactivate project
  Future<void> setProjectActive(int projectId, bool isActive) async {
    await updateProject(projectId: projectId, isActive: isActive);
  }
}
