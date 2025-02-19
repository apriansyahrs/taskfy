import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskfy/models/project.dart';
import 'package:taskfy/providers/project_providers.dart';
import 'package:taskfy/widgets/app_layout.dart';
import 'package:taskfy/widgets/kanban_board.dart';
import 'package:taskfy/providers/auth_provider.dart';

class MyProjectsScreen extends ConsumerWidget {
  const MyProjectsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    final projectsAsyncValue = ref.watch(projectListProvider(user?.email));

    return AppLayout(
      title: 'Task Manager',
      pageTitle: 'My Projects',
      child: projectsAsyncValue.when(
        data: (projects) => KanbanBoard<Project>(
          items: projects,
          getTitle: (project) => project.name,
          getStatus: (project) => project.status,
          onStatusChange: (project, newStatus) {
            ref.read(projectNotifierProvider.notifier).updateProject(project.copyWith(status: newStatus));
          },
          statuses: ['not_started', 'in_progress', 'completed', 'on_hold'],
          canEdit: (project) => true, // Pegawai selalu dapat mengubah status proyek mereka sendiri
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

