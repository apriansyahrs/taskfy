import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taskfy/models/task.dart';
import 'package:taskfy/providers/task_providers.dart';
import 'package:taskfy/widgets/app_layout.dart';
import 'package:taskfy/widgets/stat_card.dart';
import 'package:intl/intl.dart';
import 'package:taskfy/widgets/error_widget.dart';
import 'package:taskfy/config/constants.dart';
import 'package:taskfy/providers/permission_provider.dart';
import 'package:taskfy/providers/auth_provider.dart';
import 'package:taskfy/models/user.dart' as taskfy_user;
import 'package:taskfy/config/style_guide.dart';

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
          SizedBox(height: StyleGuide.spacingLarge),
          _buildTaskList(context, tasksAsyncValue, permissions),
        ],
      ),
    );
  }

  Widget _buildStatCards(AsyncValue<List<Task>> tasksAsyncValue) {
    return tasksAsyncValue.when(
      data: (tasks) => LayoutBuilder(
        builder: (context, constraints) {
          final cardWidth = (constraints.maxWidth - (3 * StyleGuide.spacingMedium)) / 4;
          return Wrap(
            spacing: StyleGuide.spacingMedium,
            runSpacing: StyleGuide.spacingMedium,
            children: [
              SizedBox(
                width: cardWidth,
                child: StatCard(
                  title: 'Total Tasks',
                  value: tasks.length.toString(),
                  icon: Icons.assignment,
                  color: Colors.blue,
                ),
              ),
              SizedBox(
                width: cardWidth,
                child: StatCard(
                  title: 'In Progress',
                  value: tasks.where((t) => t.status == AppConstants.taskStatusInProgress).length.toString(),
                  icon: Icons.trending_up,
                  color: Colors.orange,
                ),
              ),
              SizedBox(
                width: cardWidth,
                child: StatCard(
                  title: 'Completed',
                  value: tasks.where((t) => t.status == AppConstants.taskStatusCompleted).length.toString(),
                  icon: Icons.check_circle,
                  color: Colors.green,
                ),
              ),
              SizedBox(
                width: cardWidth,
                child: StatCard(
                  title: 'Overdue',
                  value: tasks.where((t) => t.deadline.isBefore(DateTime.now()) && t.status != AppConstants.taskStatusCompleted).length.toString(),
                  icon: Icons.warning,
                  color: Colors.red,
                ),
              ),
            ],
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => CustomErrorWidget(message: err.toString()),
    );
  }

  Widget _buildTaskList(BuildContext context, AsyncValue<List<Task>> tasksAsyncValue, Set<String> permissions) {
    final user = ref.watch(authProvider);
    return Card(
      child: Padding(
        padding: EdgeInsets.all(StyleGuide.paddingLarge),
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
                    decoration: StyleGuide.inputDecoration(
                      labelText: 'Search tasks...',
                      prefixIcon: Icons.search,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: StyleGuide.spacingMedium),
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
              horizontal: StyleGuide.paddingSmall,
              vertical: StyleGuide.paddingSmall / 2,
            ),
            decoration: BoxDecoration(
              color: _getStatusColor(task.status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(StyleGuide.borderRadiusMedium),
            ),
            child: Text(
              task.status,
              style: TextStyle(color: _getStatusColor(task.status)),
            ),
          ),
        ),
        DataCell(Text(task.priority)),
        DataCell(Text(task.assignedTo.join(', '))),
        DataCell(Text(DateFormat('MMM dd, yyyy').format(task.deadline))),
        DataCell(_buildActionButtons(context, task)),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, Task task) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () => context.go('/tasks/${task.id}/edit'),
          tooltip: 'Edit Task',
        ),
        IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () => task.id != null ? onDelete(task.id!) : null,
          tooltip: 'Delete Task',
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'in_progress':
        return Colors.blue;
      case 'not_started':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }


}

