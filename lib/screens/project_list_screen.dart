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
import 'package:taskfy/config/theme_config.dart';
import 'package:taskfy/widgets/error_widget.dart';
import 'package:taskfy/widgets/data_table_widget.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:logging/logging.dart';
import 'package:flutter_animate/flutter_animate.dart';

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
      floatingActionButton: permissions.contains(AppConstants.permissionCreateProject)
        ? FloatingActionButton.extended(
            icon: const Icon(Icons.add),
            label: Text(AppLocalizations.of(context)!.createProjectButton),
            onPressed: () => context.go('${AppConstants.projectsRoute}/create'),
            backgroundColor: ThemeConfig.accentColor,
            foregroundColor: Colors.white,
          )
        : null,
      child: Padding(
        padding: EdgeInsets.all(0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatCards(projectsAsyncValue),
            SizedBox(height: StyleGuide.spacingLarge),
            _buildProjectList(context, projectsAsyncValue, permissions),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCards(AsyncValue<List<Project>> projectsAsyncValue) {
    return projectsAsyncValue.when(
      data: (projects) => _StatCards(projects: projects),
      loading: () => const Center(
        child: CircularProgressIndicator(color: ThemeConfig.accentColor)
      ),
      error: (err, stack) => CustomErrorWidget(message: err.toString()),
    );
  }

  Widget _buildProjectList(BuildContext context, AsyncValue<List<Project>> projectsAsyncValue, Set<String> permissions) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(StyleGuide.borderRadiusLarge),
        side: const BorderSide(color: ThemeConfig.border),
      ),
      child: Padding(
        padding: EdgeInsets.all(StyleGuide.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  AppLocalizations.of(context)!.projectListTitle,
                  style: StyleGuide.titleStyle,
                ),
                const Spacer(),
                SizedBox(
                  width: 240,
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
            ).animate().fadeIn(duration: 400.ms).moveX(begin: -20, end: 0),
            SizedBox(height: StyleGuide.spacingMedium),
            projectsAsyncValue.when(
              data: (projects) {
                final filteredProjects = projects.where((project) =>
                    project.name.toLowerCase().contains(_searchQuery) ||
                    project.description.toLowerCase().contains(_searchQuery) ||
                    project.status.toLowerCase().contains(_searchQuery)
                ).toList();

                return filteredProjects.isEmpty
                    ? Center(
                        child: Padding(
                          padding: EdgeInsets.all(StyleGuide.paddingLarge),
                          child: Column(
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 48, 
                                color: ThemeConfig.labelTextColor.withOpacity(0.5),
                              ),
                              SizedBox(height: StyleGuide.spacingMedium),
                              Text(
                                AppLocalizations.of(context)!.noDataFound,
                                style: StyleGuide.subtitleStyle,
                              ),
                            ],
                          ),
                        ),
                      ).animate().fade(duration: 400.ms)
                    : _ProjectTable(
                        projects: filteredProjects,
                        permissions: permissions,
                        onDelete: (String projectId) async {
                          return await ref.read(projectNotifierProvider.notifier).deleteProject(projectId);
                        },
                      );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(80.0),
                  child: CircularProgressIndicator(color: ThemeConfig.accentColor),
                ),
              ),
              error: (err, stack) => CustomErrorWidget(message: err.toString()),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 600.ms).moveY(begin: 20, end: 0);
  }
}

class _StatCards extends StatelessWidget {
  final List<Project> projects;

  const _StatCards({required this.projects});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < StyleGuide.breakpointTablet;
        final cardWidth = isSmallScreen
            ? constraints.maxWidth
            : (constraints.maxWidth - (3 * StyleGuide.spacingMedium)) / 4;
            
        return Wrap(
          spacing: StyleGuide.spacingMedium,
          runSpacing: StyleGuide.spacingMedium,
          children: [
            _buildStatCard('Total Projects', projects.length.toString(), Icons.work, ThemeConfig.infoColor, cardWidth, 0),
            _buildStatCard('In Progress', 
              projects.where((p) => p.status == AppConstants.projectStatusInProgress).length.toString(), 
              Icons.pending_actions, ThemeConfig.warningColor, cardWidth, 1),
            _buildStatCard('Completed', 
              projects.where((p) => p.status == AppConstants.projectStatusCompleted).length.toString(), 
              Icons.check_circle, ThemeConfig.successColor, cardWidth, 2),
            _buildStatCard('On Hold', 
              projects.where((p) => p.status == AppConstants.projectStatusOnHold).length.toString(), 
              Icons.pause_circle, ThemeConfig.errorColor, cardWidth, 3),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, double cardWidth, int index) {
    return SizedBox(
      width: cardWidth,
      child: StatCard(
        title: title,
        value: value,
        icon: icon,
        color: color,
      ),
    ).animate()
     .fadeIn(duration: 400.ms, delay: Duration(milliseconds: 100 * index))
     .moveY(begin: 20, end: 0, delay: Duration(milliseconds: 100 * index));
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
    return SizedBox(
      width: double.infinity, // Make the table stretch to full width
      child: DataTableWidget(
        columns: [
          const DataColumn(label: Text('Name')),
          const DataColumn(label: Text('Status')),
          const DataColumn(label: Text('Team')),
          const DataColumn(label: Text('Start Date')),
          const DataColumn(label: Text('End Date')),
          const DataColumn(label: Text('Progress')),
          const DataColumn(label: Text('Actions')),
        ],
        rows: List.generate(
          projects.length,
          (index) => _buildProjectRow(context, projects[index], index),
        ),
        emptyMessage: AppLocalizations.of(context)!.noDataFound,
      ),
    );
  }

  DataRow _buildProjectRow(BuildContext context, Project project, int index) {
    return DataRow(
      cells: [
        DataCell(
          Container(
            constraints: const BoxConstraints(maxWidth: 200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  project.name,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: StyleGuide.subtitleStyle,
                ),
                Text(
                  project.description,
                  style: StyleGuide.smallLabelStyle,
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
              vertical: StyleGuide.paddingTiny,
            ),
            decoration: BoxDecoration(
              color: _getStatusColor(project.status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(StyleGuide.borderRadiusMedium),
            ),
            child: Text(
              project.status,
              style: TextStyle(
                color: _getStatusColor(project.status),
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
        ),
        DataCell(
          Wrap(
            spacing: StyleGuide.spacingTiny,
            children: project.teamMembers
                .take(3)
                .map((member) => StyleGuide.userAvatar(member))
                .toList(),
          ),
        ),
        DataCell(Text(
          DateFormat('MMM d, y').format(project.startDate),
          style: const TextStyle(fontSize: 13),
        )),
        DataCell(Text(
          DateFormat('MMM d, y').format(project.endDate),
          style: const TextStyle(fontSize: 13),
        )),
        DataCell(
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${project.completion.round()}%',
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Stack(
                children: [
                  Container(
                    width: 100,
                    height: 6,
                    decoration: BoxDecoration(
                      color: ThemeConfig.dividerColor,
                      borderRadius: BorderRadius.circular(StyleGuide.borderRadiusSmall),
                    ),
                  ),
                  Container(
                    width: project.completion,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _getProgressColor(project.completion),
                      borderRadius: BorderRadius.circular(StyleGuide.borderRadiusSmall),
                    ),
                  ),
                ],
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
                icon: const Icon(Icons.visibility_outlined, size: 20),
                tooltip: 'View Project Details',
                onPressed: () => context.go('${AppConstants.projectsRoute}/${project.id}'),
                style: IconButton.styleFrom(
                  backgroundColor: ThemeConfig.selectedBgColor,
                  foregroundColor: ThemeConfig.accentColor,
                ),
              ),
              // Edit button - visible for users with edit permission
              if (permissions.contains(AppConstants.permissionUpdateProject))
                Padding(
                  padding: EdgeInsets.only(left: StyleGuide.spacingSmall),
                  child: IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    tooltip: 'Edit Project',
                    onPressed: () => context.go('${AppConstants.projectsRoute}/${project.id}/edit'),
                    style: IconButton.styleFrom(
                      backgroundColor: ThemeConfig.infoColor.withOpacity(0.1),
                      foregroundColor: ThemeConfig.infoColor,
                    ),
                  ),
                ),
              if (permissions.contains(AppConstants.permissionDeleteProject))
                Padding(
                  padding: EdgeInsets.only(left: StyleGuide.spacingSmall),
                  child: IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    tooltip: 'Delete Project',
                    onPressed: () {
                      if (project.id.isNotEmpty) {
                        _showDeleteProjectDialog(context, project.id);
                      }
                    },
                    style: IconButton.styleFrom(
                      backgroundColor: ThemeConfig.errorColor.withOpacity(0.1),
                      foregroundColor: ThemeConfig.errorColor,
                    ),
                  ),
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
        return ThemeConfig.successColor;
      case AppConstants.projectStatusInProgress:
        return ThemeConfig.infoColor;
      case AppConstants.projectStatusOnHold:
        return ThemeConfig.warningColor;
      case AppConstants.projectStatusCancelled:
        return ThemeConfig.errorColor;
      default:
        return ThemeConfig.accentColor;
    }
  }

  Color _getProgressColor(double progress) {
    if (progress >= 75) return ThemeConfig.successColor;
    if (progress >= 50) return ThemeConfig.infoColor;
    if (progress >= 25) return ThemeConfig.warningColor;
    return ThemeConfig.errorColor;
  }
  
  void _showDeleteProjectDialog(BuildContext context, String projectId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(StyleGuide.borderRadiusXLarge),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: ThemeConfig.errorColor),
            SizedBox(width: StyleGuide.spacingSmall),
            const Text('Delete Project'),
          ],
        ),
        content: const Text('Are you sure you want to delete this project? This action cannot be undone.'),
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
                  const SnackBar(
                    content: Text('Project deleted successfully'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } catch (e) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text('Error: ${e.toString()}'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: ThemeConfig.errorColor,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ThemeConfig.errorColor,
              foregroundColor: ThemeConfig.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(StyleGuide.borderRadiusMedium),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

