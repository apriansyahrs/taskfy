import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taskfy/widgets/app_layout.dart';
import 'package:taskfy/providers/task_providers.dart';

class TaskListScreen extends ConsumerWidget {
  final String? userId;
  final String userRole;
  const TaskListScreen({super.key, required this.userId, required this.userRole});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsyncValue = ref.watch(taskListProvider(userRole == 'pegawai' ? userId : null));

    return AppLayout(
      title: 'Task Manager',
      pageTitle: 'Tasks',
      actions: [
        ElevatedButton.icon(
          icon: Icon(Icons.add),
          label: Text('New Task'),
          onPressed: () => context.go('/tasks/create'),
        ),
      ],
      child: Card(
        child: tasksAsyncValue.when(
          data: (tasks) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Name')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Priority')),
                  DataColumn(label: Text('Assigned To')),
                  DataColumn(label: Text('Deadline')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: tasks.map((task) {
                  return DataRow(
                    cells: [
                      DataCell(Text(task.name)),
                      DataCell(
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(task.status).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            task.status,
                            style: TextStyle(
                              color: _getStatusColor(task.status),
                            ),
                          ),
                        ),
                      ),
                      DataCell(Text(task.priority)),
                      DataCell(Text(task.assignedTo.join(', '))),
                      DataCell(Text(task.deadline.toString())),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit),
                              onPressed: () => context.go('/tasks/${task.id ?? ''}/edit'),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () {
                                // ref.read(taskNotifierProvider.notifier).deleteTask(task.id);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'in_progress':
        return Colors.blue;
      case 'not_started':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

