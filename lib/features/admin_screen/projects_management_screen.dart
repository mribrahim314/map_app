import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:map_app/core/cubit/project_cubit.dart';
import 'package:map_app/core/helpers/data.dart';
import 'package:map_app/core/helpers/spacing.dart';
import 'package:map_app/core/models/project_model.dart';
import 'package:map_app/core/networking/project_repository.dart';
import 'package:map_app/core/theming/styles.dart';
import 'package:map_app/core/widgets/app_text_button.dart';
import 'package:map_app/core/widgets/customized_text_field.dart';

class ProjectsManagementScreen extends StatelessWidget {
  const ProjectsManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          ProjectCubit(ProjectRepository())..loadActiveProjects(),
      child: const _ProjectsManagementView(),
    );
  }
}

class _ProjectsManagementView extends StatelessWidget {
  const _ProjectsManagementView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Projects'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateProjectDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('New Project'),
        backgroundColor: Colors.green,
      ),
      body: BlocBuilder<ProjectCubit, ProjectState>(
        builder: (context, state) {
          if (state is ProjectLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ProjectError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  VerticalSpacing(20),
                  Text('Error: ${state.message}'),
                  VerticalSpacing(20),
                  ElevatedButton(
                    onPressed: () =>
                        context.read<ProjectCubit>().loadActiveProjects(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is ProjectLoaded) {
            final projects = state.projects;

            if (projects.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.folder_open, size: 64, color: Colors.grey),
                    VerticalSpacing(20),
                    Text(
                      'No projects yet',
                      style: TextStyles.font14grey400Weight,
                    ),
                    VerticalSpacing(10),
                    Text(
                      'Create your first project using the + button',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: projects.length,
              itemBuilder: (context, index) {
                final project = projects[index];
                return _ProjectCard(project: project);
              },
            );
          }

          return const SizedBox();
        },
      ),
    );
  }

  void _showCreateProjectDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<ProjectCubit>(),
        child: const _CreateProjectDialog(),
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final Project project;

  const _ProjectCard({required this.project});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        project.purpose,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () => _showEditProjectDialog(context, project),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                  onPressed: () => _confirmDelete(context, project),
                ),
              ],
            ),
            VerticalSpacing(12),
            Text(
              project.description,
              style: const TextStyle(fontSize: 14),
            ),
            VerticalSpacing(12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip(
                  icon: Icons.people,
                  label: '${project.contributors.length} Contributors',
                ),
                _InfoChip(
                  icon: Icons.category,
                  label: '${project.allowedCategories.length} Categories',
                ),
                _InfoChip(
                  icon: Icons.circle,
                  label: project.isActive ? 'Active' : 'Inactive',
                  color: project.isActive ? Colors.green : Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProjectDialog(BuildContext context, Project project) {
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<ProjectCubit>(),
        child: _EditProjectDialog(project: project),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Project project) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Project'),
        content: Text(
            'Are you sure you want to delete "${project.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await context.read<ProjectCubit>().deleteProject(project.id);
              Navigator.pop(dialogContext);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Project deleted')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _InfoChip({
    required this.icon,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: (color ?? Colors.blue).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color ?? Colors.blue),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color ?? Colors.blue),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color ?? Colors.blue,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateProjectDialog extends StatefulWidget {
  const _CreateProjectDialog();

  @override
  State<_CreateProjectDialog> createState() => _CreateProjectDialogState();
}

class _CreateProjectDialogState extends State<_CreateProjectDialog> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _purposeController = TextEditingController();
  final List<String> _selectedCategories = [];
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create New Project'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomizedTextField(
              controller: _nameController,
              hint: 'Project Name',
            ),
            VerticalSpacing(12),
            CustomizedTextField(
              controller: _purposeController,
              hint: 'Purpose (e.g., Fruit Trees, Solar Panels)',
            ),
            VerticalSpacing(12),
            CustomizedTextField(
              controller: _descriptionController,
              hint: 'Description',
              maxLines: 3,
            ),
            VerticalSpacing(12),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Allowed Categories:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            VerticalSpacing(8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: Data.Categories.map((category) {
                final isSelected = _selectedCategories.contains(category);
                return FilterChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedCategories.add(category);
                      } else {
                        _selectedCategories.remove(category);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _createProject,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create'),
        ),
      ],
    );
  }

  Future<void> _createProject() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a project name')),
      );
      return;
    }

    if (_selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one category')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      final project = Project(
        id: '',
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        purpose: _purposeController.text.trim(),
        createdBy: user.uid,
        createdAt: DateTime.now(),
        contributors: [],
        isActive: true,
        allowedCategories: _selectedCategories,
      );

      await context.read<ProjectCubit>().createProject(project);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Project created successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create project: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _purposeController.dispose();
    super.dispose();
  }
}

class _EditProjectDialog extends StatefulWidget {
  final Project project;

  const _EditProjectDialog({required this.project});

  @override
  State<_EditProjectDialog> createState() => _EditProjectDialogState();
}

class _EditProjectDialogState extends State<_EditProjectDialog> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _purposeController;
  late List<String> _selectedCategories;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.project.name);
    _descriptionController =
        TextEditingController(text: widget.project.description);
    _purposeController = TextEditingController(text: widget.project.purpose);
    _selectedCategories = List.from(widget.project.allowedCategories);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Project'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomizedTextField(
              controller: _nameController,
              hint: 'Project Name',
            ),
            VerticalSpacing(12),
            CustomizedTextField(
              controller: _purposeController,
              hint: 'Purpose',
            ),
            VerticalSpacing(12),
            CustomizedTextField(
              controller: _descriptionController,
              hint: 'Description',
              maxLines: 3,
            ),
            VerticalSpacing(12),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Allowed Categories:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            VerticalSpacing(8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: Data.Categories.map((category) {
                final isSelected = _selectedCategories.contains(category);
                return FilterChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedCategories.add(category);
                      } else {
                        _selectedCategories.remove(category);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _updateProject,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Update'),
        ),
      ],
    );
  }

  Future<void> _updateProject() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a project name')),
      );
      return;
    }

    if (_selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one category')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final updatedProject = widget.project.copyWith(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        purpose: _purposeController.text.trim(),
        allowedCategories: _selectedCategories,
      );

      await context.read<ProjectCubit>().updateProject(updatedProject);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Project updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update project: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _purposeController.dispose();
    super.dispose();
  }
}
