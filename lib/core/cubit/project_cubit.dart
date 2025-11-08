import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:map_app/core/models/project_model.dart';
import 'package:map_app/core/networking/project_repository.dart';

// States
abstract class ProjectState {}

class ProjectInitial extends ProjectState {}

class ProjectLoading extends ProjectState {}

class ProjectLoaded extends ProjectState {
  final List<Project> projects;
  final Project? selectedProject;

  ProjectLoaded({
    required this.projects,
    this.selectedProject,
  });

  ProjectLoaded copyWith({
    List<Project>? projects,
    Project? selectedProject,
  }) {
    return ProjectLoaded(
      projects: projects ?? this.projects,
      selectedProject: selectedProject ?? this.selectedProject,
    );
  }
}

class ProjectError extends ProjectState {
  final String message;

  ProjectError(this.message);
}

// Cubit
class ProjectCubit extends Cubit<ProjectState> {
  final ProjectRepository _repository;
  Project? _selectedProject;

  ProjectCubit(this._repository) : super(ProjectInitial());

  // Get selected project
  Project? get selectedProject => _selectedProject;

  // Load projects for user
  Future<void> loadUserProjects(String userId, {bool isAdmin = false}) async {
    emit(ProjectLoading());
    try {
      final projects = isAdmin
          ? await _repository.getAllProjects()
          : await _repository.getUserProjects(userId);

      emit(ProjectLoaded(
        projects: projects,
        selectedProject: _selectedProject,
      ));
    } catch (e) {
      emit(ProjectError(e.toString()));
    }
  }

  // Load active projects
  Future<void> loadActiveProjects() async {
    emit(ProjectLoading());
    try {
      final projects = await _repository.getActiveProjects();
      emit(ProjectLoaded(
        projects: projects,
        selectedProject: _selectedProject,
      ));
    } catch (e) {
      emit(ProjectError(e.toString()));
    }
  }

  // Select a project
  void selectProject(Project project) {
    _selectedProject = project;
    if (state is ProjectLoaded) {
      emit((state as ProjectLoaded).copyWith(selectedProject: project));
    }
  }

  // Clear selection
  void clearSelection() {
    _selectedProject = null;
    if (state is ProjectLoaded) {
      emit((state as ProjectLoaded).copyWith(selectedProject: null));
    }
  }

  // Create project
  Future<void> createProject(Project project) async {
    try {
      await _repository.createProject(project);
      // Reload projects after creation
      if (state is ProjectLoaded) {
        final projects = await _repository.getAllProjects();
        emit(ProjectLoaded(
          projects: projects,
          selectedProject: _selectedProject,
        ));
      }
    } catch (e) {
      emit(ProjectError(e.toString()));
    }
  }

  // Update project
  Future<void> updateProject(Project project) async {
    try {
      await _repository.updateProject(project);
      // Reload projects after update
      if (state is ProjectLoaded) {
        final projects = await _repository.getAllProjects();
        emit(ProjectLoaded(
          projects: projects,
          selectedProject: _selectedProject,
        ));
      }
    } catch (e) {
      emit(ProjectError(e.toString()));
    }
  }

  // Delete project
  Future<void> deleteProject(String projectId) async {
    try {
      await _repository.deleteProject(projectId);
      // Reload projects after deletion
      if (state is ProjectLoaded) {
        final projects = await _repository.getAllProjects();
        emit(ProjectLoaded(
          projects: projects,
          selectedProject: _selectedProject,
        ));
      }
    } catch (e) {
      emit(ProjectError(e.toString()));
    }
  }

  // Add contributor
  Future<void> addContributor(String projectId, String userId) async {
    try {
      await _repository.addContributor(projectId, userId);
      // Reload projects after adding contributor
      if (state is ProjectLoaded) {
        final projects = await _repository.getAllProjects();
        emit(ProjectLoaded(
          projects: projects,
          selectedProject: _selectedProject,
        ));
      }
    } catch (e) {
      emit(ProjectError(e.toString()));
    }
  }

  // Remove contributor
  Future<void> removeContributor(String projectId, String userId) async {
    try {
      await _repository.removeContributor(projectId, userId);
      // Reload projects after removing contributor
      if (state is ProjectLoaded) {
        final projects = await _repository.getAllProjects();
        emit(ProjectLoaded(
          projects: projects,
          selectedProject: _selectedProject,
        ));
      }
    } catch (e) {
      emit(ProjectError(e.toString()));
    }
  }
}
