/// Project Model for PostgreSQL
/// Represents a data collection project in the database
class ProjectModel {
  final int id;
  final String name;
  final String? description;
  final String projectType;
  final String createdBy;
  final bool isActive;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProjectModel({
    required this.id,
    required this.name,
    this.description,
    required this.projectType,
    required this.createdBy,
    required this.isActive,
    required this.startDate,
    this.endDate,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create ProjectModel from database map
  factory ProjectModel.fromMap(Map<String, dynamic> map) {
    return ProjectModel(
      id: map['id'] as int,
      name: map['name'] as String,
      description: map['description'] as String?,
      projectType: map['project_type'] as String,
      createdBy: map['created_by'] as String,
      isActive: map['is_active'] as bool? ?? true,
      startDate: map['start_date'] is DateTime
          ? map['start_date']
          : DateTime.parse(map['start_date'].toString()),
      endDate: map['end_date'] != null
          ? (map['end_date'] is DateTime
              ? map['end_date']
              : DateTime.parse(map['end_date'].toString()))
          : null,
      createdAt: map['created_at'] is DateTime
          ? map['created_at']
          : DateTime.parse(map['created_at'].toString()),
      updatedAt: map['updated_at'] is DateTime
          ? map['updated_at']
          : DateTime.parse(map['updated_at'].toString()),
    );
  }

  /// Convert ProjectModel to map for database operations
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'project_type': projectType,
      'created_by': createdBy,
      'is_active': isActive,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  ProjectModel copyWith({
    int? id,
    String? name,
    String? description,
    String? projectType,
    String? createdBy,
    bool? isActive,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProjectModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      projectType: projectType ?? this.projectType,
      createdBy: createdBy ?? this.createdBy,
      isActive: isActive ?? this.isActive,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'ProjectModel(id: $id, name: $name, type: $projectType, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProjectModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Project Statistics Model
class ProjectStats {
  final int id;
  final String name;
  final String? description;
  final String projectType;
  final bool isActive;
  final DateTime startDate;
  final DateTime? endDate;
  final String creatorEmail;
  final int contributorCount;
  final int polygonCount;
  final int pointCount;
  final int totalFeatures;

  ProjectStats({
    required this.id,
    required this.name,
    this.description,
    required this.projectType,
    required this.isActive,
    required this.startDate,
    this.endDate,
    required this.creatorEmail,
    required this.contributorCount,
    required this.polygonCount,
    required this.pointCount,
    required this.totalFeatures,
  });

  factory ProjectStats.fromMap(Map<String, dynamic> map) {
    return ProjectStats(
      id: map['id'] as int,
      name: map['name'] as String,
      description: map['description'] as String?,
      projectType: map['project_type'] as String,
      isActive: map['is_active'] as bool,
      startDate: map['start_date'] is DateTime
          ? map['start_date']
          : DateTime.parse(map['start_date'].toString()),
      endDate: map['end_date'] != null
          ? (map['end_date'] is DateTime
              ? map['end_date']
              : DateTime.parse(map['end_date'].toString()))
          : null,
      creatorEmail: map['creator_email'] as String,
      contributorCount: map['contributor_count'] as int? ?? 0,
      polygonCount: map['polygon_count'] as int? ?? 0,
      pointCount: map['point_count'] as int? ?? 0,
      totalFeatures: map['total_features'] as int? ?? 0,
    );
  }
}
