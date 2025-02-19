import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taskfy/providers/permission_provider.dart';
import 'package:taskfy/providers/task_providers.dart';
import 'package:taskfy/providers/project_providers.dart';
import 'package:taskfy/providers/auth_provider.dart'; // Import auth provider
import 'package:taskfy/widgets/project_chart.dart';
import 'package:taskfy/widgets/stat_card.dart';
import 'package:taskfy/widgets/app_layout.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissions = ref.watch(permissionProvider);
    final user = ref.watch(authProvider);
    final userEmail = user?.email;
    final userRole = user?.role ?? '';
    final tasksAsyncValue = ref.watch(taskListProvider(userRole == 'pegawai' ? userEmail : null));
    final projectsAsyncValue = ref.watch(projectListProvider(userRole == 'pegawai' ? userEmail : null));

    return AppLayout(
      title: 'Task Manager',
      pageTitle: 'Dashboard',
      subtitle: 'Welcome back! Here\'s an overview of your tasks and projects.',
      actions: [
        if (permissions.contains('create_task'))
          ElevatedButton.icon(
            icon: Icon(Icons.add),
            label: Text('New Task'),
            onPressed: () => context.go('/tasks/create'),
          ),
      ],
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatCards(tasksAsyncValue, projectsAsyncValue),
            SizedBox(height: 24),
            if (permissions.contains('view_reports')) ...[
              _buildProjectProgress(context),
              SizedBox(height: 24),
            ],
            _buildTasksAndProjects(context, permissions, tasksAsyncValue, projectsAsyncValue),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCards(AsyncValue<List<dynamic>> tasksAsyncValue, AsyncValue<List<dynamic>> projectsAsyncValue) {
    return tasksAsyncValue.when(
      data: (tasks) {
        return projectsAsyncValue.when(
          data: (projects) {
            final completedTasks = tasks.where((task) => task.status == 'completed').length;
            final activeProjects = projects.where((project) => project.status == 'in_progress').length;

            return LayoutBuilder(
              builder: (context, constraints) {
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _buildStatCard(constraints, 'Total Tasks', tasks.length.toString(), Icons.task_alt, Colors.blue),
                    _buildStatCard(constraints, 'Completed Tasks', completedTasks.toString(), Icons.check_circle, Colors.green),
                    _buildStatCard(constraints, 'Active Projects', activeProjects.toString(), Icons.work, Colors.orange),
                    _buildStatCard(constraints, 'Total Projects', projects.length.toString(), Icons.folder, Colors.purple),
                  ],
                );
              },
            );
          },
          loading: () => Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
        );
      },
      loading: () => Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildStatCard(BoxConstraints constraints, String title, String value, IconData icon, Color color) {
    final cardWidth = (constraints.maxWidth - (3 * 16)) / 4;
    return SizedBox(
      width: cardWidth,
      child: StatCard(
        title: title,
        value: value,
        icon: icon,
        color: color,
      ),
    );
  }

  Widget _buildProjectProgress(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Project Progress',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: ProjectChart(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTasksAndProjects(BuildContext context, Set<String> permissions, AsyncValue<List<dynamic>> tasksAsyncValue, AsyncValue<List<dynamic>> projectsAsyncValue) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (permissions.contains('update_task'))
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recent Tasks',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 16),
                    tasksAsyncValue.when(
                      data: (tasks) {
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: tasks.take(5).length,
                          itemBuilder: (context, index) {
                            final task = tasks[index];
                            return ListTile(
                              title: Text(task.name),
                              subtitle: Text('Status: ${task.status}'),
                              trailing: Text('Due: ${DateFormat('MMM d, y').format(task.deadline)}'),
                              onTap: () => context.go('/tasks/${task.id}'),
                            );
                          },
                        );
                      },
                      loading: () => Center(child: CircularProgressIndicator()),
                      error: (err, stack) => Center(child: Text('Error: $err')),
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (permissions.contains('create_project') || permissions.contains('update_project')) ...[
          if (permissions.contains('update_task'))
            SizedBox(width: 16),
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Active Projects',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 16),
                    projectsAsyncValue.when(
                      data: (projects) {
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: projects.take(5).length,
                          itemBuilder: (context, index) {
                            final project = projects[index];
                            return ListTile(
                              title: Text(project.name),
                              subtitle: Text('Status: ${project.status}'),
                              trailing: Text('${project.completion.toStringAsFixed(0)}%'),
                              onTap: () => context.go('/projects/${project.id}'),
                            );
                          },
                        );
                      },
                      loading: () => Center(child: CircularProgressIndicator()),
                      error: (err, stack) => Center(child: Text('Error: $err')),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

