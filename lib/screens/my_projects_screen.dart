import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskfy/models/project.dart';
import 'package:taskfy/providers/project_providers.dart';
import 'package:taskfy/widgets/app_layout.dart';
import 'package:taskfy/widgets/kanban_board.dart';
import 'package:taskfy/providers/auth_provider.dart';
import 'package:intl/intl.dart';

class MyProjectsScreen extends ConsumerWidget {
  const MyProjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    final projectsAsyncValue = ref.watch(projectListStreamProvider(user?.email?.trim().toLowerCase()));

    return AppLayout(
      title: 'Task Manager',
      pageTitle: 'My Projects',
      child: projectsAsyncValue.when(
        data: (projects) {
          final userProjects = projects.where((project) => isUserTeamMember(project, user?.email)).toList();
          final activeProjects = userProjects.where((project) => project.status != 'completed').toList();
          final completedProjects = userProjects.where((project) => project.status == 'completed').toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(context, "Active Projects", Icons.work),
              Expanded(
                flex: 2,
                child: KanbanBoard<Project>(
                  items: activeProjects,
                  getTitle: (project) => project.name,
                  getStatus: (project) => project.status,
                  onStatusChange: (project, newStatus) {
                    ref.read(projectNotifierProvider.notifier).updateProject(project.copyWith(status: newStatus));
                  },
                  statuses: ['not_started', 'in_progress', 'on_hold'],
                  canEdit: (project) => true,
                  buildItemDetails: (project) => _buildProjectDetails(project),
                ),
              ),
              SizedBox(height: 24),
              _buildSectionHeader(context, "Completed Projects", Icons.check_circle),
              Expanded(
                flex: 1,
                child: _buildCompletedProjectsList(completedProjects, context, ref),
              ),
            ],
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
          Icon(icon, size: 28, color: Theme.of(context).primaryColor),
          SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  bool isUserTeamMember(Project project, String? userEmail) {
    return project.teamMembers.any((email) => email.trim().toLowerCase() == userEmail?.trim().toLowerCase());
  }

  Widget _buildProjectDetails(Project project) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Description: ${project.description}'),
        SizedBox(height: 8),
        _buildPriorityChip(project.priority),
        SizedBox(height: 8),
        Text('Start: ${DateFormat('MMM d, y').format(project.startDate)}'),
        Text('End: ${DateFormat('MMM d, y').format(project.endDate)}'),
        SizedBox(height: 8),
        _buildProgressBar(project.completion),
      ],
    );
  }

  Widget _buildPriorityChip(String priority) {
    Color chipColor;
    switch (priority.toLowerCase()) {
      case 'high':
        chipColor = Colors.red;
        break;
      case 'medium':
        chipColor = Colors.orange;
        break;
      case 'low':
        chipColor = Colors.green;
        break;
      default:
        chipColor = Colors.grey;
    }

    return Chip(
      label: Text(
        priority,
        style: TextStyle(color: Colors.white),
      ),
      backgroundColor: chipColor,
    );
  }

  Widget _buildProgressBar(double completion) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Completion: ${completion.toStringAsFixed(1)}%'),
        SizedBox(height: 4),
        LinearProgressIndicator(
          value: completion / 100,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
        ),
      ],
    );
  }

  Widget _buildCompletedProjectsList(List<Project> projects, BuildContext context, WidgetRef ref) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Completed Projects',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
                ),
                Text(
                  '${projects.length}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: projects.length,
              itemBuilder: (context, index) {
                final project = projects[index];
                return ListTile(
                  title: Text(project.name, style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Completed on: ${DateFormat('MMM d, y').format(project.endDate)}'),
                  trailing: IconButton(
                    icon: Icon(Icons.info_outline),
                    onPressed: () {
                      // Implement project details view
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

