import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:map_app/core/models/project_model.dart';

class ProjectRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _projectsCollection = 'projects';

  // Get all active projects
  Future<List<Project>> getActiveProjects() async {
    try {
      final snapshot = await _firestore
          .collection(_projectsCollection)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => Project.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch projects: $e');
    }
  }

  // Get all projects (for admin)
  Future<List<Project>> getAllProjects() async {
    try {
      final snapshot = await _firestore
          .collection(_projectsCollection)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => Project.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch all projects: $e');
    }
  }

  // Get projects where user is a contributor
  Future<List<Project>> getUserProjects(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_projectsCollection)
          .where('contributors', arrayContains: userId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => Project.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch user projects: $e');
    }
  }

  // Create a new project
  Future<String> createProject(Project project) async {
    try {
      final docRef =
          await _firestore.collection(_projectsCollection).add(project.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create project: $e');
    }
  }

  // Update project
  Future<void> updateProject(Project project) async {
    try {
      await _firestore
          .collection(_projectsCollection)
          .doc(project.id)
          .update(project.toFirestore());
    } catch (e) {
      throw Exception('Failed to update project: $e');
    }
  }

  // Delete project (soft delete by setting isActive to false)
  Future<void> deleteProject(String projectId) async {
    try {
      await _firestore
          .collection(_projectsCollection)
          .doc(projectId)
          .update({'isActive': false});
    } catch (e) {
      throw Exception('Failed to delete project: $e');
    }
  }

  // Add contributor to project
  Future<void> addContributor(String projectId, String userId) async {
    try {
      await _firestore.collection(_projectsCollection).doc(projectId).update({
        'contributors': FieldValue.arrayUnion([userId])
      });
    } catch (e) {
      throw Exception('Failed to add contributor: $e');
    }
  }

  // Remove contributor from project
  Future<void> removeContributor(String projectId, String userId) async {
    try {
      await _firestore.collection(_projectsCollection).doc(projectId).update({
        'contributors': FieldValue.arrayRemove([userId])
      });
    } catch (e) {
      throw Exception('Failed to remove contributor: $e');
    }
  }

  // Get project by ID
  Future<Project?> getProjectById(String projectId) async {
    try {
      final doc = await _firestore.collection(_projectsCollection).doc(projectId).get();

      if (!doc.exists) return null;

      return Project.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to fetch project: $e');
    }
  }

  // Stream for real-time project updates
  Stream<List<Project>> streamActiveProjects() {
    return _firestore
        .collection(_projectsCollection)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Project.fromFirestore(doc)).toList());
  }

  // Stream user projects
  Stream<List<Project>> streamUserProjects(String userId) {
    return _firestore
        .collection(_projectsCollection)
        .where('contributors', arrayContains: userId)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Project.fromFirestore(doc)).toList());
  }
}
