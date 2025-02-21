import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskfy/models/task.dart';
import 'package:taskfy/providers/task_providers.dart';
import 'package:taskfy/widgets/app_layout.dart';
import 'package:taskfy/widgets/kanban_board.dart';
import 'package:taskfy/providers/auth_provider.dart';
import 'package:intl/intl.dart';
import 'package:taskfy/config/theme_config.dart';

class MyTasksScreen extends ConsumerWidget {
  const MyTasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    final userEmail = user?.email.trim().toLowerCase();
    final tasksAsyncValue = ref.watch(taskListStreamProvider(userEmail));

    return AppLayout(
      title: 'Task Manager',
      pageTitle: 'My Tasks',
      child: tasksAsyncValue.when(
        data: (tasks) {
          final userTasks = tasks.where((task) => isUserAssigned(task, userEmail)).toList();
          final todayTasks = userTasks.where((task) => isToday(task.deadline)).toList();
          final upcomingTasks = userTasks.where((task) => isFuture(task.deadline)).toList();
          final pastDueTasks = userTasks.where((task) => isPastDue(task.deadline)).toList();

          return LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: SizedBox(
                  width: constraints.maxWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader(context, "Today's Tasks", Icons.today),
                      SizedBox(
                        height: 400, // Fixed height for Kanban board
                        child: KanbanBoard<Task>(
                          items: todayTasks,
                          getTitle: (task) => task.name,
                          getStatus: (task) => task.status,
                          onStatusChange: (task, newStatus) {
                            ref.read(taskNotifierProvider.notifier).updateTask(
                                  task.copyWith(status: newStatus),
                                );
                          },
                          statuses: ['not_started', 'in_progress', 'completed'],
                          canEdit: (task) => true,
                          buildItemDetails: (task) => _buildTaskDetails(context, task),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildSectionHeader(context, "Task Overview", Icons.assessment),
                      SizedBox(
                        height: 300, // Fixed height for overview section
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildTaskOverview(
                                context,
                                "Upcoming",
                                upcomingTasks,
                                ref,
                                ThemeConfig.infoColor,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTaskOverview(
                                context,
                                "Past Due",
                                pastDueTasks,
                                ref,
                                ThemeConfig.errorColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        children: [
          Icon(icon, size: 28, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  bool isUserAssigned(Task task, String? userEmail) {
    return task.assignedTo.any((email) => email.trim().toLowerCase() == userEmail?.trim().toLowerCase());
  }

  bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  bool isFuture(DateTime date) {
    return date.isAfter(DateTime.now());
  }

  bool isPastDue(DateTime date) {
    return date.isBefore(DateTime.now());
  }

  Widget _buildTaskDetails(BuildContext context, Task task) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Description: ${task.description}'),
        const SizedBox(height: 8),
        _buildPriorityChip(context, task.priority),
        const SizedBox(height: 8),
        Text('Deadline: ${DateFormat('MMM d, y').format(task.deadline)}'),
      ],
    );
  }

  Widget _buildPriorityChip(BuildContext context, String priority) {
    Color chipColor;
    switch (priority.toLowerCase()) {
      case 'high':
        chipColor = ThemeConfig.errorColor;
        break;
      case 'medium':
        chipColor = ThemeConfig.warningColor;
        break;
      case 'low':
        chipColor = ThemeConfig.successColor;
        break;
      default:
        chipColor = Theme.of(context).disabledColor;
    }

    return Chip(
      label: Text(
        priority,
        style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
      ),
      backgroundColor: chipColor,
    );
  }

  Widget _buildTaskOverview(BuildContext context, String title, List<Task> tasks, WidgetRef ref, Color color) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
                ),
                Text(
                  '${tasks.length}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                return ListTile(
                  title: Text(task.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(DateFormat('MMM d, y').format(task.deadline)),
                  trailing: IconButton(
                    icon: const Icon(Icons.arrow_forward_ios, size: 16),
                    onPressed: () {
                      // Implement task details view
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

