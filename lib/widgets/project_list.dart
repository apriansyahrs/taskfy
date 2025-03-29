import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taskfy/providers/project_providers.dart';
import 'package:taskfy/providers/auth_provider.dart';
import 'package:taskfy/providers/permission_provider.dart';
import 'package:taskfy/config/constants.dart';

class ProjectList extends ConsumerWidget {
  final int? limit;

  const ProjectList({super.key, this.limit});

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, String? projectId) {
    if (projectId == null) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Project'),
        content: const Text('Are you sure you want to delete this project?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              try {
                await ref.read(projectNotifierProvider.notifier).deleteProject(projectId);
                scaffoldMessenger.showSnackBar(
                  const SnackBar(content: Text('Project deleted successfully')),
                );
              } catch (e) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(content: Text('Error: ${e.toString()}')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.value;
    final userEmail = user?.email;
    final projectsAsyncValue = ref.watch(projectListStreamProvider(userEmail));
    
    // Check permissions using the permission provider
    final permissions = ref.watch(permissionProvider);
    final bool canEdit = permissions.contains(AppConstants.permissionUpdateProject);
    final bool canDelete = permissions.contains(AppConstants.permissionDeleteProject);

    return projectsAsyncValue.when(
      data: (projects) {
        if (limit != null && projects.length > limit!) {
          projects = projects.sublist(0, limit);
        }
        return ListView.builder(
          itemCount: projects.length,
          itemBuilder: (context, index) {
            final project = projects[index];
            return ListTile(
              title: Text(project.name),
              subtitle: Text('Status: ${project.status}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${project.completion.toStringAsFixed(1)}%'),
                  const SizedBox(width: 8),
                  if (canEdit) IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => context.go('/projects/${project.id}/edit'),
                    tooltip: 'Edit Project',
                  ),
                  if (canDelete) IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _showDeleteConfirmation(context, ref, project.id),
                    tooltip: 'Delete Project',
                  ),
                ],
              ),
              onTap: () => context.go('/projects/${project.id}'),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }
}

