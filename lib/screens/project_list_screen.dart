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

class ProjectListScreen extends ConsumerStatefulWidget {
  const ProjectListScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends ConsumerState<ProjectListScreen> {
  String _searchQuery = '';
  bool _isKanbanView = false;

  Widget _buildStatCards(AsyncValue<List<Project>> projectsAsyncValue) {
    return projectsAsyncValue.when(
      data: (projects) {
        return LayoutBuilder(
          builder: (context, constraints) {
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildStatCard('Total Projects', projects.length.toString(), Icons.work, Colors.blue, constraints),
                _buildStatCard('In Progress', projects.where((p) => p.status == 'in_progress').length.toString(), Icons.pending_actions, Colors.orange, constraints),
                _buildStatCard('Completed', projects.where((p) => p.status == 'completed').length.toString(), Icons.check_circle, Colors.green, constraints),
                _buildStatCard('On Hold', projects.where((p) => p.status == 'on_hold').length.toString(), Icons.pause_circle, Colors.red, constraints),
              ],
            );
          },
        );
      },
      loading: () => Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error loading projects: $err')),
    );
  }

  Widget _buildKanbanView(AsyncValue<List<Project>> projectsAsyncValue, Set<String> permissions, User? currentUser) {
    return projectsAsyncValue.when(
      data: (projects) => KanbanBoard<Project>(
        items: projects,
        getTitle: (project) => project.name,
        getStatus: (project) => project.status,
        onStatusChange: (project, newStatus) {
          if (permissions.contains('update_project_status') && project.teamMembers.contains(currentUser?.email)) {
            ref.read(projectNotifierProvider.notifier).updateProject(project.copyWith(status: newStatus));
          }
        },
        statuses: ['not_started', 'in_progress', 'completed', 'on_hold'],
        canEdit: (project) => permissions.contains('update_project_status') && project.teamMembers.contains(currentUser?.email),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
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
                
                    project.name.toLowerCase().contains(_searchQuery) ||
                    project.description.toLowerCase().contains(_searchQuery) ||
                    project.status.toLowerCase().contains(_searchQuery)
                ).toList();

                return filteredProjects.isEmpty
                    ? Center(child: Text('No projects found'))
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
                            DataColumn(label: Text('Team')),
                            DataColumn(label: Text('Start Date')),
                            DataColumn(label: Text('End Date')),
                            DataColumn(label: Text('Progress')),
                            DataColumn(label: Text('Actions')),
                          ],
                          rows: filteredProjects.map((project) => _buildProjectRow(context, project, permissions)).toList(),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ],
        ),
      ),
    );
  }

  DataRow _buildProjectRow(BuildContext context, Project project, Set<String> permissions) {
    final user = ref.watch(authProvider);
    final isAssignedToProject = project.teamMembers.contains(user?.email);

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
            padding: EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: _getStatusColor(project.status)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              project.status,
              style: TextStyle(
                color: _getStatusColor(project.status),
              ),
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
        DataCell(Text(DateFormat('MMM d, y')
            .format(project.startDate))),
        DataCell(Text(
            DateFormat('MMM d, y').format(project.endDate))),
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
              if (permissions.contains('edit_project') || (permissions.contains('update_project_status') && isAssignedToProject))
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () => context
                      .go('/projects/${project.id}/edit'),
                ),
              if (permissions.contains('delete_project'))
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () async {
                    if (project.id.isNotEmpty) {
                      try {
                        await ref.read(projectNotifierProvider.notifier).deleteProject(project.id);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Project deleted successfully')),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error deleting project: $e')),
                          );
                        }
                      }
                    } else {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Cannot delete project: Invalid project ID')),
                        );
                      }
                    }
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    final userEmail = user?.email;
    final userRole = user?.role ?? '';
    final projectsAsyncValue = ref.watch(projectListProvider(userRole == 'pegawai' ? userEmail : null));
    final permissions = ref.watch(permissionProvider);

    return AppLayout(
      title: 'Task Manager',
      pageTitle: 'Projects',
      actions: [
        if (permissions.contains('create_project'))
          ElevatedButton.icon(
            icon: Icon(Icons.add),
            label: Text('New Project'),
            onPressed: () => context.go('/projects/create'),
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

  Widget _buildStatCard(String title, String value, IconData icon, Color color, BoxConstraints constraints) {
    final cardWidth = (constraints.maxWidth - (3 * 16)) / 4; // 64 is the total spacing between cards (16 * 4)
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'in_progress':
        return Colors.blue;
      case 'on_hold':
        return Colors.orange;
      case 'cancelled':
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

