/// PostgreSQL User Model
/// Represents a user in the PostgreSQL database
class UserModel {
  final String id;
  final String email;
  final String role;
  final int contributionCount;
  final bool contributionRequestSent;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    required this.email,
    required this.role,
    required this.contributionCount,
    required this.contributionRequestSent,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create UserModel from database map
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      email: map['email'] as String,
      role: map['role'] as String? ?? 'normal',
      contributionCount: map['contribution_count'] as int? ?? 0,
      contributionRequestSent: map['contribution_request_sent'] as bool? ?? false,
      createdAt: map['created_at'] is DateTime
          ? map['created_at']
          : DateTime.parse(map['created_at'].toString()),
      updatedAt: map['updated_at'] is DateTime
          ? map['updated_at']
          : DateTime.parse(map['updated_at'].toString()),
    );
  }

  /// Convert UserModel to map for database operations
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'role': role,
      'contribution_count': contributionCount,
      'contribution_request_sent': contributionRequestSent,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  UserModel copyWith({
    String? id,
    String? email,
    String? role,
    int? contributionCount,
    bool? contributionRequestSent,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      role: role ?? this.role,
      contributionCount: contributionCount ?? this.contributionCount,
      contributionRequestSent: contributionRequestSent ?? this.contributionRequestSent,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if user is admin
  bool get isAdmin => role == 'admin';

  /// Check if user is contributor (moderator or admin)
  bool get isContributor => role == 'moderator' || role == 'admin';

  /// Check if user is normal (viewer)
  bool get isNormal => role == 'normal';

  @override
  String toString() {
    return 'UserModel(id: $id, email: $email, role: $role, contributionCount: $contributionCount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
