import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskfy/models/task.dart';
import 'package:taskfy/providers/task_providers.dart';
import 'package:taskfy/widgets/app_layout.dart';
import 'package:taskfy/widgets/kanban_board.dart';
import 'package:taskfy/providers/auth_provider.dart';

class MyTasksScreen extends ConsumerWidget {
  const MyTasksScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    final tasksAsyncValue = ref.watch(taskListProvider(user?.email));

    return AppLayout(
      title: 'Task Manager',
      pageTitle: 'My Tasks',
      child: tasksAsyncValue.when(
        data: (tasks) => KanbanBoard<Task>(
          items: tasks,
          getTitle: (task) => task.name,
          getStatus: (task) => task.status,
          onStatusChange: (task, newStatus) {
            ref.read(taskNotifierProvider.notifier).updateTask(task.copyWith(status: newStatus));
          },
          statuses: ['not_started', 'in_progress', 'completed'],
          canEdit: (task) => true, // Pegawai selalu dapat mengubah status tugas mereka sendiri
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

