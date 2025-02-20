import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taskfy/models/task.dart';
import 'package:taskfy/providers/task_providers.dart';
  import 'package:taskfy/services/service_locator.dart';
  import 'package:taskfy/services/supabase_client.dart';

class TaskListScreen extends ConsumerWidget {
  final int? limit;

  const TaskListScreen({super.key, this.limit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsyncValue = ref.watch(taskListStreamProvider(null));

    return tasksAsyncValue.when(
      data: (tasks) {
        if (limit != null && tasks.length > limit!) {
          tasks = tasks.sublist(0, limit);
        }
        return ListView.builder(
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];
            return ListTile(
              title: Text(task.name),
              subtitle: Text('Status: ${task.status}'),
              trailing: Text('Due: ${task.deadline.toString()}'),
              onTap: () => context.go('/tasks/${task.id}'),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }
}

