import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taskfy/models/project.dart';
import 'package:taskfy/widgets/app_layout.dart';
import 'package:intl/intl.dart';
import 'package:taskfy/providers/project_providers.dart';
import 'package:taskfy/providers/permission_provider.dart';
import 'package:taskfy/providers/auth_provider.dart';
import 'package:taskfy/config/constants.dart';
import 'package:taskfy/config/style_guide.dart';
import 'package:taskfy/widgets/error_widget.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:logging/logging.dart';

import '../widgets/stat_card.dart';

final _log = Logger('ProjectListScreen');

/// Screen for displaying and managing the list of projects.
class ProjectListScreen extends ConsumerStatefulWidget {
  const ProjectListScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends ConsumerState<ProjectListScreen> {
  AppLocalizations get l10n => AppLocalizations.of(context)!;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    _log.info('Building ProjectListScreen');
    final userState = ref.watch(authProvider);
    final userEmail = userState.value?.email;
    _log.info('Current user email: $userEmail, role: ${userState.value?.role}');
    
    final projectsAsyncValue = ref.watch(projectListStreamProvider(userEmail));
    final permissions = ref.watch(permissionProvider);
    
    _log.info('User permissions: $permissions');
    
    // Log any errors from async values
    if (projectsAsyncValue.hasError) {
      _log.severe('Error loading projects: ${projectsAsyncValue.error}', projectsAsyncValue.error, StackTrace.current);
    }

    return AppLayout(
      title: AppLocalizations.of(context)!.appTitle,
      pageTitle: AppLocalizations.of(context)!.projectsTitle,
      actions: [
        if (permissions.contains(AppConstants.permissionCreateProject))
          ElevatedButton.icon(
            icon: Icon(Icons.add),
            label: Text(AppLocalizations.of(context)!.createProjectButton),
            onPressed: () => context.go('${AppConstants.projectsRoute}/create'),
          ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatCards(projectsAsyncValue),
          SizedBox(height: StyleGuide.spacingLarge),
          _buildProjectList(context, projectsAsyncValue, permissions),
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

  Widget _buildProjectList(BuildContext context, AsyncValue<List<Project>> projectsAsyncValue, Set<String> permissions) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(StyleGuide.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  AppLocalizations.of(context)!.projectListTitle,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Spacer(),
                SizedBox(
                  width: 200,
                  child: TextField(
                    decoration: StyleGuide.inputDecoration(
                      labelText: AppLocalizations.of(context)!.searchProjectsPlaceholder,
                      prefixIcon: Icons.search,
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
            SizedBox(height: StyleGuide.spacingMedium),
            projectsAsyncValue.when(
              data: (projects) {
                final filteredProjects = projects.where((project) =>
                    project.name.toLowerCase().contains(_searchQuery) ||
                    project.description.toLowerCase().contains(_searchQuery) ||
                    project.status.toLowerCase().contains(_searchQuery)
                ).toList();

                return filteredProjects.isEmpty
                    ? Center(child: Text(AppLocalizations.of(context)!.noDataFound))
                    : _ProjectTable(
                        projects: filteredProjects,
                        permissions: permissions,
                        onDelete: (String projectId) async {
                          return await ref.read(projectNotifierProvider.notifier).deleteProject(projectId);
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

  const _StatCards({required this.projects});

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
      child: StatCard(
        title: title,
        value: value,
        icon: icon,
        color: color,
      ),
    );
  }
}

class _ProjectTable extends StatelessWidget {
  final List<Project> projects;
  final Set<String> permissions;
  final Function(String) onDelete;

  const _ProjectTable({
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
          Container(
            constraints: BoxConstraints(maxWidth: 200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  project.name,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                Text(
                  project.description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
        DataCell(
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: StyleGuide.paddingSmall,
              vertical: StyleGuide.paddingSmall / 2,
            ),
            decoration: BoxDecoration(
              color: _getStatusColor(project.status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(StyleGuide.borderRadiusMedium),
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
              // View button - always visible for all users
              IconButton(
                icon: Icon(Icons.visibility),
                tooltip: 'View Project Details',
                onPressed: () => context.go('${AppConstants.projectsRoute}/${project.id}'),
              ),
              if (permissions.contains(AppConstants.permissionDeleteProject))
                IconButton(
                  icon: Icon(Icons.delete),
                  tooltip: 'Delete Project',
                  onPressed: () {
                    if (project.id.isNotEmpty) {
                      _showDeleteProjectDialog(context, project.id);
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
  
  void _showDeleteProjectDialog(BuildContext context, String projectId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Project'),
        content: const Text('Are you sure you want to delete this project?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              try {
                await onDelete(projectId);
                scaffoldMessenger.showSnackBar(
                  const SnackBar(content: Text('Project deleted successfully')),
                );
              } catch (e) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(content: Text('Error: ${e.toString()}')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

