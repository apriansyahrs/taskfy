import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taskfy/models/project.dart';
import 'package:taskfy/models/user.dart';
import 'package:taskfy/widgets/app_layout.dart';
import 'package:taskfy/widgets/kanban_board.dart';
import 'package:intl/intl.dart';
import 'package:taskfy/providers/project_providers.dart';
import 'package:taskfy/providers/permission_provider.dart';
import 'package:taskfy/providers/auth_provider.dart';
import 'package:taskfy/config/constants.dart';
import 'package:taskfy/widgets/error_widget.dart';

/// Screen for displaying and managing the list of projects.
class ProjectListScreen extends ConsumerStatefulWidget {
  const ProjectListScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends ConsumerState<ProjectListScreen> {
  String _searchQuery = '';
  bool _isKanbanView = false;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    final userEmail = user?.email;
    final projectsAsyncValue = ref.watch(projectListStreamProvider(userEmail));
    final permissions = ref.watch(permissionProvider);

    return AppLayout(
      title: 'Task Manager',
      pageTitle: 'Projects',
      actions: [
        if (permissions.contains(AppConstants.permissionCreateProject))
          ElevatedButton.icon(
            icon: Icon(Icons.add),
            label: Text('New Project'),
            onPressed: () => context.go('${AppConstants.projectsRoute}/create'),
          ),
        IconButton(
          icon: Icon(_isKanbanView ? Icons.view_list : Icons.view_column),
          onPressed: () {
            setState(() {
              _isKanbanView = !_isKanbanView;
            });
          },
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatCards(projectsAsyncValue),
          const SizedBox(height: 32),
          _isKanbanView
              ? _buildKanbanView(projectsAsyncValue, permissions, user)
              : _buildProjectList(context, projectsAsyncValue, permissions),
        ],
      ),
    );
  }

  Widget _buildStatCards(AsyncValue<List<Project>> projectsAsyncValue) {
    return projectsAsyncValue.when(
      data: (projects) => _StatCards(projects: projects),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => CustomErrorWidget(message: err.toString()),
    );
  }

  Widget _buildKanbanView(AsyncValue<List<Project>> projectsAsyncValue, Set<String> permissions, User? currentUser) {
    return projectsAsyncValue.when(
      data: (projects) => KanbanBoard<Project>(
        items: projects,
        getTitle: (project) => project.name,
        getStatus: (project) => project.status,
        onStatusChange: (project, newStatus) {
          if (permissions.contains(AppConstants.permissionUpdateProjectStatus) && project.teamMembers.any((email) => email.trim().toLowerCase() == currentUser?.email?.trim().toLowerCase())) {
            ref.read(projectNotifierProvider.notifier).updateProject(project.copyWith(status: newStatus));
          }
        },
        statuses: AppConstants.projectStatuses,
        canEdit: (project) => permissions.contains(AppConstants.permissionUpdateProjectStatus) && project.teamMembers.contains(currentUser?.email),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => CustomErrorWidget(message: err.toString()),
    );
  }

  Widget _buildProjectList(BuildContext context, AsyncValue<List<Project>> projectsAsyncValue, Set<String> permissions) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Project List',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Spacer(),
                SizedBox(
                  width: 200,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search projects...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            projectsAsyncValue.when(
              data: (projects) {
                final filteredProjects = projects.where((project) =>
                    project.name.toLowerCase().contains(_searchQuery) ||
                    project.description.toLowerCase().contains(_searchQuery) ||
                    project.status.toLowerCase().contains(_searchQuery)
                ).toList();

                return filteredProjects.isEmpty
                    ? Center(child: Text('No projects found'))
                    : _ProjectTable(
                        projects: filteredProjects,
                        permissions: permissions,
                        onDelete: (String projectId) {
                          ref.read(projectNotifierProvider.notifier).deleteProject(projectId);
                        },
                      );
              },
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
  final List<Project> projects;

  const _StatCards({super.key, required this.projects});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildStatCard('Total Projects', projects.length.toString(), Icons.work, Colors.blue, constraints),
            _buildStatCard('In Progress', projects.where((p) => p.status == AppConstants.projectStatusInProgress).length.toString(), Icons.pending_actions, Colors.orange, constraints),
            _buildStatCard('Completed', projects.where((p) => p.status == AppConstants.projectStatusCompleted).length.toString(), Icons.check_circle, Colors.green, constraints),
            _buildStatCard('On Hold', projects.where((p) => p.status == AppConstants.projectStatusOnHold).length.toString(), Icons.pause_circle, Colors.red, constraints),
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

class _ProjectTable extends StatelessWidget {
  final List<Project> projects;
  final Set<String> permissions;
  final Function(String) onDelete;

  const _ProjectTable({
    super.key,
    required this.projects,
    required this.permissions,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Name')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Team')),
                DataColumn(label: Text('Start Date')),
                DataColumn(label: Text('End Date')),
                DataColumn(label: Text('Progress')),
                DataColumn(label: Text('Actions')),
              ],
              rows: projects.map((project) => _buildProjectRow(context, project)).toList(),
            ),
          ),
        );
      },
    );
  }

  DataRow _buildProjectRow(BuildContext context, Project project) {
    return DataRow(
      cells: [
        DataCell(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(project.name),
              Text(
                project.description,
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
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getStatusColor(project.status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              project.status,
              style: TextStyle(color: _getStatusColor(project.status)),
            ),
          ),
        ),
        DataCell(
          Wrap(
            spacing: 4,
            children: project.teamMembers
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
        DataCell(Text(DateFormat('MMM d, y').format(project.startDate))),
        DataCell(Text(DateFormat('MMM d, y').format(project.endDate))),
        DataCell(
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${project.completion.round()}%'),
              SizedBox(height: 4),
              LinearProgressIndicator(
                value: project.completion / 100,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation(
                  _getProgressColor(project.completion),
                ),
              ),
            ],
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (permissions.contains(AppConstants.permissionEditProject))
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () => context.go('${AppConstants.projectsRoute}/${project.id}/edit'),
                ),
              if (permissions.contains(AppConstants.permissionDeleteProject))
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () {
                    if (project.id.isNotEmpty) {
                      onDelete(project.id);
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
      case AppConstants.projectStatusCompleted:
        return Colors.green;
      case AppConstants.projectStatusInProgress:
        return Colors.blue;
      case AppConstants.projectStatusOnHold:
        return Colors.orange;
      case AppConstants.projectStatusCancelled:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getProgressColor(double progress) {
    if (progress >= 75) return Colors.green;
    if (progress >= 50) return Colors.blue;
    if (progress >= 25) return Colors.orange;
    return Colors.red;
  }
}

