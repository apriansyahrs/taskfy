import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taskfy/models/task.dart';
import 'package:taskfy/providers/task_providers.dart';
import 'package:taskfy/widgets/app_layout.dart';
import 'package:taskfy/widgets/kanban_board.dart';
import 'package:intl/intl.dart';
import 'package:taskfy/widgets/error_widget.dart';
import 'package:taskfy/config/constants.dart';
import 'package:taskfy/providers/permission_provider.dart';
import 'package:taskfy/providers/auth_provider.dart';
import 'package:taskfy/models/user.dart' as taskfy_user;

/// Screen for displaying and managing the list of tasks.
class TaskListScreen extends ConsumerStatefulWidget {
  const TaskListScreen({super.key});

  @override
  ConsumerState<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends ConsumerState<TaskListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    final userEmail = user?.email;
    final tasksAsyncValue = ref.watch(taskListStreamProvider(userEmail));
    final permissions = ref.watch(permissionProvider);

    return AppLayout(
      title: 'Task Manager',
      pageTitle: 'Tasks',
      actions: [
        if (permissions.contains(AppConstants.permissionCreateTask))
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('New Task'),
            onPressed: () => context.go('${AppConstants.tasksRoute}/create'),
          ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatCards(tasksAsyncValue),
          const SizedBox(height: 32),
          _buildTaskList(context, tasksAsyncValue, permissions),
        ],
      ),
    );
  }

  Widget _buildStatCards(AsyncValue<List<Task>> tasksAsyncValue) {
    return tasksAsyncValue.when(
      data: (tasks) => _StatCards(tasks: tasks),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => CustomErrorWidget(message: err.toString()),
    );
  }

  Widget _buildKanbanView(AsyncValue<List<Task>> tasksAsyncValue, Set<String> permissions, taskfy_user.User? currentUser) {
    return tasksAsyncValue.when(
      data: (tasks) => KanbanBoard<Task>(
        items: tasks,
        getTitle: (task) => task.name,
        getStatus: (task) => task.status,
        onStatusChange: (task, newStatus) {
          if (permissions.contains(AppConstants.permissionUpdateTaskStatus) && task.assignedTo.contains(currentUser?.email)) {
            ref.read(taskNotifierProvider.notifier).updateTask(task.copyWith(status: newStatus));
          }
        },
        statuses: [AppConstants.taskStatusNotStarted, AppConstants.taskStatusInProgress, AppConstants.taskStatusCompleted],
        canEdit: (task) => permissions.contains(AppConstants.permissionUpdateTaskStatus) && task.assignedTo.contains(currentUser?.email),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => CustomErrorWidget(message: err.toString()),
    );
  }

  Widget _buildTaskList(BuildContext context, AsyncValue<List<Task>> tasksAsyncValue, Set<String> permissions) {
    final user = ref.watch(authProvider);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Task List',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const Spacer(),
                SizedBox(
                  width: 200,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search tasks...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            tasksAsyncValue.when(
              data: (tasks) => _TaskTable(
                tasks: tasks,
                searchQuery: _searchController.text.toLowerCase(),
                onDelete: (String taskId) {
                  ref.read(taskNotifierProvider.notifier).deleteTask(taskId);
                },
                permissions: permissions,
                currentUser: user,
                taskNotifierProvider: taskNotifierProvider,
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => CustomErrorWidget(message: err.toString()),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCards extends StatelessWidget {
  final List<Task> tasks;

  const _StatCards({super.key, required this.tasks});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildStatCard('Total Tasks', tasks.length.toString(), Icons.assignment, Colors.blue, constraints),
            _buildStatCard('In Progress', tasks.where((t) => t.status == AppConstants.taskStatusInProgress).length.toString(), Icons.trending_up, Colors.orange, constraints),
            _buildStatCard('Completed', tasks.where((t) => t.status == AppConstants.taskStatusCompleted).length.toString(), Icons.check_circle, Colors.green, constraints),
            _buildStatCard('Overdue', tasks.where((t) => t.deadline.isBefore(DateTime.now()) && t.status != AppConstants.taskStatusCompleted).length.toString(), Icons.warning, Colors.red, constraints),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, BoxConstraints constraints) {
    final cardWidth = (constraints.maxWidth - (3 * 16)) / 4;
    return SizedBox(
      width: cardWidth,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  Icon(icon, color: color, size: 24),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskTable extends StatelessWidget {
  final List<Task> tasks;
  final String searchQuery;
  final Function(String) onDelete;
  final Set<String> permissions;
  final taskfy_user.User? currentUser;
  final StateNotifierProvider<TaskNotifier, AsyncValue<Task?>> taskNotifierProvider;

  const _TaskTable({
    required this.tasks,
    required this.searchQuery,
    required this.onDelete,
    required this.permissions,
    required this.currentUser,
    required this.taskNotifierProvider,
  });

  @override
  Widget build(BuildContext context) {
    final filteredTasks = tasks.where((task) =>
      task.name.toLowerCase().contains(searchQuery) ||
      task.description.toLowerCase().contains(searchQuery) ||
      task.status.toLowerCase().contains(searchQuery)
    ).toList();

    return filteredTasks.isEmpty
      ? const Center(child: Text('No tasks found'))
      : LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Name')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Priority')),
                    DataColumn(label: Text('Assigned To')),
                    DataColumn(label: Text('Deadline')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: filteredTasks.map((task) => _buildTaskRow(context, task)).toList(),
                ),
              ),
            );
          },
        );
  }

  DataRow _buildTaskRow(BuildContext context, Task task) {
    final isAssignedToTask = task.assignedTo.any((email) => email.trim().toLowerCase() == currentUser?.email?.trim().toLowerCase());

    return DataRow(
      cells: [
        DataCell(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(task.name),
              Text(
                task.description,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        DataCell(
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: _getStatusColor(task.status)
                  .withOpacity(0.1),
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
        DataCell(
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: _getPriorityColor(task.priority)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              task.priority,
              style: TextStyle(
                color: _getPriorityColor(task.priority),
              ),
            ),
          ),
        ),
        DataCell(
          Wrap(
            spacing: 4,
            children: task.assignedTo
                .take(3)
                .map((member) => CircleAvatar(
                      radius: 12,
                      child: Text(
                        member[0].toUpperCase(),
                        style: TextStyle(fontSize: 10),
                      ),
                    ))
                .toList(),
          ),
        ),
        DataCell(Text(DateFormat('MMM d, y').format(task.deadline))),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (permissions.contains(AppConstants.permissionEditTask) || (permissions.contains(AppConstants.permissionUpdateTaskStatus) && isAssignedToTask))
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () => context.go('/tasks/${task.id}/edit'),
                ),
              if (permissions.contains(AppConstants.permissionDeleteTask))
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () {
                    if (task.id != null) {
                      onDelete(task.id!);
                    }
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case AppConstants.taskStatusCompleted:
        return Colors.green;
      case AppConstants.taskStatusInProgress:
        return Colors.blue;
      case AppConstants.taskStatusNotStarted:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case AppConstants.taskPriorityHigh:
        return Colors.red;
      case AppConstants.taskPriorityMedium:
        return Colors.orange;
      case AppConstants.taskPriorityLow:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}

