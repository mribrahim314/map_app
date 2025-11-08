import 'package:cloud_firestore/cloud_firestore.dart';

class Project {
  final String id;
  final String name;
  final String description;
  final String purpose;
  final String createdBy;
  final DateTime createdAt;
  final List<String> contributors;
  final bool isActive;
  final List<String> allowedCategories;

  Project({
    required this.id,
    required this.name,
    required this.description,
    required this.purpose,
    required this.createdBy,
    required this.createdAt,
    required this.contributors,
    this.isActive = true,
    required this.allowedCategories,
  });

  factory Project.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Project(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      purpose: data['purpose'] ?? '',
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      contributors: List<String>.from(data['contributors'] ?? []),
      isActive: data['isActive'] ?? true,
      allowedCategories: List<String>.from(data['allowedCategories'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'purpose': purpose,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'contributors': contributors,
      'isActive': isActive,
      'allowedCategories': allowedCategories,
    };
  }

  Project copyWith({
    String? id,
    String? name,
    String? description,
    String? purpose,
    String? createdBy,
    DateTime? createdAt,
    List<String>? contributors,
    bool? isActive,
    List<String>? allowedCategories,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      purpose: purpose ?? this.purpose,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      contributors: contributors ?? this.contributors,
      isActive: isActive ?? this.isActive,
      allowedCategories: allowedCategories ?? this.allowedCategories,
    );
  }
}
