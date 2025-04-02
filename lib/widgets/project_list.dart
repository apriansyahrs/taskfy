import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taskfy/providers/project_providers.dart';
import 'package:taskfy/providers/auth_provider.dart';
import 'package:taskfy/providers/permission_provider.dart';
import 'package:taskfy/config/constants.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:taskfy/config/style_guide.dart';
import 'package:taskfy/config/theme_config.dart';

class ProjectList extends ConsumerWidget {
  final int? limit;

  const ProjectList({super.key, this.limit});

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, String? projectId) {
    if (projectId == null) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              try {
                await ref.read(projectNotifierProvider.notifier).deleteProject(projectId);
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return ThemeConfig.successColor;
      case 'in progress':
        return ThemeConfig.infoColor;
      case 'on hold':
        return ThemeConfig.warningColor;
      case 'cancelled':
        return ThemeConfig.errorColor;
      default:
        return ThemeConfig.accentColor;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.value;
    final userEmail = user?.email;
    final projectsAsyncValue = ref.watch(projectListStreamProvider(userEmail));
    
    final permissions = ref.watch(permissionProvider);
    final bool canEdit = permissions.contains(AppConstants.permissionUpdateProject);
    final bool canDelete = permissions.contains(AppConstants.permissionDeleteProject);

    return projectsAsyncValue.when(
      data: (projects) {
        if (projects.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.folder_open,
                  size: 64,
                  color: ThemeConfig.labelTextColor.withOpacity(0.5),
                ),
                SizedBox(height: StyleGuide.spacingMedium),
                Text(
                  'No projects yet',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                SizedBox(height: StyleGuide.spacingSmall),
                Text(
                  'Create your first project to get started',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          );
        }

        if (limit != null && projects.length > limit!) {
          projects = projects.sublist(0, limit);
        }
        
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWideScreen = constraints.maxWidth > StyleGuide.breakpointTablet;
              
              return ListView.builder(
                itemCount: projects.length,
                itemBuilder: (context, index) {
                  final project = projects[index];
                  
                  return Padding(
                    padding: EdgeInsets.only(bottom: StyleGuide.paddingSmall),
                    child: InkWell(
                      onTap: () => context.go('/projects/${project.id}'),
                      borderRadius: BorderRadius.circular(StyleGuide.borderRadiusLarge),
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(StyleGuide.borderRadiusLarge),
                          side: const BorderSide(color: ThemeConfig.border),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(StyleGuide.paddingMedium),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      project.name,
                                      style: StyleGuide.subtitleStyle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: StyleGuide.paddingSmall, 
                                      vertical: StyleGuide.paddingTiny
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(project.status).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(StyleGuide.borderRadiusXLarge),
                                    ),
                                    child: Text(
                                      project.status,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: _getStatusColor(project.status),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: StyleGuide.spacingMedium),
                              Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Progress',
                                          style: StyleGuide.smallLabelStyle,
                                        ),
                                        SizedBox(height: StyleGuide.spacingTiny),
                                        Stack(
                                          children: [
                                            Container(
                                              height: 8,
                                              width: double.infinity,
                                              decoration: BoxDecoration(
                                                color: ThemeConfig.dividerColor,
                                                borderRadius: BorderRadius.circular(StyleGuide.borderRadiusSmall),
                                              ),
                                            ),
                                            FractionallySizedBox(
                                              widthFactor: project.completion / 100,
                                              child: Container(
                                                height: 8,
                                                decoration: BoxDecoration(
                                                  color: _getStatusColor(project.status),
                                                  borderRadius: BorderRadius.circular(StyleGuide.borderRadiusSmall),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: StyleGuide.spacingTiny),
                                        Text(
                                          '${project.completion.toStringAsFixed(1)}% Complete',
                                          style: StyleGuide.smallLabelStyle,
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isWideScreen) SizedBox(width: StyleGuide.spacingLarge),
                                  if (canEdit || canDelete) Expanded(
                                    flex: isWideScreen ? 1 : 2,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        if (canEdit) IconButton(
                                          icon: const Icon(Icons.edit_outlined),
                                          onPressed: () => context.go('/projects/${project.id}/edit'),
                                          tooltip: 'Edit Project',
                                          style: IconButton.styleFrom(
                                            backgroundColor: ThemeConfig.selectedBgColor,
                                            foregroundColor: ThemeConfig.accentColor,
                                          ),
                                        ),
                                        if (canEdit && canDelete) SizedBox(width: StyleGuide.spacingSmall),
                                        if (canDelete) IconButton(
                                          icon: const Icon(Icons.delete_outline),
                                          onPressed: () => _showDeleteConfirmation(context, ref, project.id),
                                          tooltip: 'Delete Project',
                                          style: IconButton.styleFrom(
                                            backgroundColor: ThemeConfig.errorColor.withOpacity(0.1),
                                            foregroundColor: ThemeConfig.errorColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ).animate()
                   .fadeIn(duration: 300.ms, delay: (50 * index).ms)
                   .slideY(begin: 0.2, end: 0);
                },
              );
            },
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: ThemeConfig.accentColor),
      ),
      error: (err, stack) => Center(
        child: Padding(
          padding: EdgeInsets.all(StyleGuide.paddingMedium),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                color: ThemeConfig.errorColor,
                size: 48,
              ),
              SizedBox(height: StyleGuide.spacingMedium),
              Text(
                'Something went wrong',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              SizedBox(height: StyleGuide.spacingSmall),
              Text(
                err.toString(),
                style: StyleGuide.errorTextStyle(context),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: StyleGuide.spacingMedium),
              ElevatedButton.icon(
                onPressed: () => ref.refresh(projectListStreamProvider(userEmail)),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: StyleGuide.buttonStyle(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

