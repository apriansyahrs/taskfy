import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:taskfy/models/project.dart';
import 'package:taskfy/models/project_task.dart';
import 'package:taskfy/providers/project_providers.dart';
import 'package:taskfy/providers/project_task_providers.dart';
import 'package:taskfy/providers/permission_provider.dart';
import 'package:taskfy/widgets/app_layout.dart';
import 'package:taskfy/widgets/kanban_board.dart';
import 'package:taskfy/services/service_locator.dart';
import 'package:taskfy/services/supabase_client.dart';
import 'package:taskfy/config/style_guide.dart';
import 'package:taskfy/config/theme_config.dart';
import 'package:intl/intl.dart';

class ProjectDetailScreen extends ConsumerWidget {
  final String projectId;

  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectAsyncValue = ref.watch(projectProvider(projectId));
    final tasksAsyncValue = ref.watch(projectTaskListStreamProvider(projectId));
    final permissions = ref.watch(permissionProvider);
    final canCreateTask = permissions.contains('create_task');
    final canEditTask = permissions.contains('edit_task');
    final canDeleteTask = permissions.contains('delete_task');
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    // Define status labels and colors for the kanban board
    final Map<String, String> statusLabels = {
      'not_started': l10n.statusNotStarted,
      'in_progress': l10n.statusInProgress,
      'completed': l10n.statusCompleted,
    };

    final Map<String, Color> statusColors = {
      'not_started': ThemeConfig.labelTextColor.withOpacity(0.2),
      'in_progress': ThemeConfig.warningColor.withOpacity(0.2),
      'completed': ThemeConfig.successColor.withOpacity(0.2),
    };

    return AppLayout(
      title: l10n.appTitle,
      pageTitle: l10n.projectsTitle,
      actions: [
        if (canCreateTask)
          ElevatedButton.icon(
            onPressed: () => _showCreateTaskDialog(context, ref, l10n),
            icon: const Icon(Icons.add),
            label: Text(l10n.addTaskButton),
            style: StyleGuide.buttonStyle(context),
          ),
      ],
      child: projectAsyncValue.when(
        data: (project) {
          if (project == null) {
            return Center(child: Text(l10n.noDataFound));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Project Info Card
                _buildSectionCard(
                  context,
                  title: 'Project Details',
                  icon: Icons.info_outline,
                  children: [
                    _buildProjectInfoSection(context, project, l10n, ref),
                  ],
                ),
                
                const SizedBox(height: 38.0), // Golden ratio spacing
                
                // Team Members Card
                _buildSectionCard(
                  context,
                  title: 'Team Members',
                  icon: Icons.people,
                  children: [
                    _buildTeamSection(context, project, ref, l10n),
                  ],
                ),
                
                const SizedBox(height: 38.0), // Golden ratio spacing
                
                // Tasks Card
                _buildSectionCard(
                  context,
                  title: l10n.projectTasksTitle,
                  icon: Icons.task_alt,
                  children: [
                    const SizedBox(height: StyleGuide.spacingMedium),
                    SizedBox(
                      height: 500, // Increased height for better usability
                      child: tasksAsyncValue.when(
                        data: (tasks) {
                          return KanbanBoard<ProjectTask>(
                            items: tasks,
                            getTitle: (task) => task.title,
                            getStatus: (task) => task.status,
                            onStatusChange: (task, newStatus) {
                              if (canEditTask) {
                                ref
                                    .read(projectTaskNotifierProvider.notifier)
                                    .updateTask(
                                      task.copyWith(status: newStatus),
                                    );
                              }
                            },
                            canEdit: (_) => canEditTask,
                            statuses: ['not_started', 'in_progress', 'completed'],
                            statusLabels: statusLabels,
                            statusColors: statusColors,
                            buildItemDetails: (task) => _buildTaskDetails(
                                context, task, canDeleteTask, ref, l10n),
                          );
                        },
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (error, stack) => Center(
                          child: Text(
                            l10n.errorOccurred,
                            style: TextStyle(color: theme.colorScheme.error),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text(
            l10n.errorOccurred,
            style: TextStyle(color: ThemeConfig.errorColor),
          ),
        ),
      ),
    );
  }

  // Helper method to build section cards (consistent with other screens)
  Widget _buildSectionCard(BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: StyleGuide.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(StyleGuide.borderRadiusMedium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(StyleGuide.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary),
                const SizedBox(width: StyleGuide.spacingSmall),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: StyleGuide.spacingLarge),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: StyleGuide.spacingSmall),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:', 
              style: StyleGuide.subtitleStyle.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: ThemeConfig.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectInfoSection(BuildContext context, Project project, AppLocalizations l10n, WidgetRef ref) {
    final theme = Theme.of(context);
    final permissions = ref.read(permissionProvider);
    final canEditProject = permissions.contains('edit_project');

    // Format dates nicely
    final dateFormat = DateFormat('MMM d, y');
    final startDate = dateFormat.format(project.startDate);
    final endDate = dateFormat.format(project.endDate);
    
    // Progress indicator
    final progress = project.completion / 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Add edit button for project details
        if (canEditProject)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.edit, size: 18),
                label: Text(l10n.editProjectButton),
                onPressed: () => _showUpdateProjectDialog(context, project, ref, l10n),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        
        _buildInfoRow(l10n.projectNameLabel, project.name, context),
        _buildInfoRow(l10n.descriptionLabel, project.description.isNotEmpty 
            ? project.description 
            : 'No description provided', context),
        
        // Status with colored indicator
        Padding(
          padding: const EdgeInsets.symmetric(vertical: StyleGuide.spacingSmall),
          child: Row(
            children: [
              SizedBox(
                width: 120,
                child: Text(
                  '${l10n.statusLabel}:', 
                  style: StyleGuide.subtitleStyle.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: StyleGuide.paddingSmall,
                  vertical: StyleGuide.paddingTiny,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(project.status),
                  borderRadius: BorderRadius.circular(StyleGuide.borderRadiusSmall),
                ),
                child: Text(
                  _getStatusText(project.status, l10n),
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: _getStatusTextColor(project.status),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Priority with colored indicator
        Padding(
          padding: const EdgeInsets.symmetric(vertical: StyleGuide.spacingSmall),
          child: Row(
            children: [
              SizedBox(
                width: 120,
                child: Text(
                  '${l10n.priorityLabel}:', 
                  style: StyleGuide.subtitleStyle.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: _getPriorityColor(project.priority),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    project.priority.toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Completion progress bar
        Padding(
          padding: const EdgeInsets.symmetric(vertical: StyleGuide.spacingSmall),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 120,
                    child: Text(
                      '${l10n.completionLabel}:', 
                      style: StyleGuide.subtitleStyle.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Text(
                    '${project.completion.toStringAsFixed(0)}%',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: StyleGuide.spacingSmall),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                color: progress == 1.0 
                    ? ThemeConfig.successColor 
                    : theme.colorScheme.primary,
                minHeight: 8,
                borderRadius: BorderRadius.circular(StyleGuide.borderRadiusSmall),
              ),
            ],
          ),
        ),
        
        // Dates in a nicer format
        _buildInfoRow(l10n.startDateLabel, startDate, context),
        _buildInfoRow(l10n.endDateLabel, endDate, context),
      ],
    );
  }

  Widget _buildTeamSection(BuildContext context, Project project, WidgetRef ref, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final permissions = ref.read(permissionProvider);
    final canEditProject = permissions.contains('edit_project');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Add edit button for team members
        if (canEditProject)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.person_add, size: 18),
                label: Text('Manage Team Members'),
                onPressed: () => _showManageTeamDialog(context, project, ref, l10n),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        
        if (project.teamMembers.isEmpty)
          Padding(
            padding: const EdgeInsets.all(StyleGuide.paddingMedium),
            child: Text(
              'No team members assigned to this project.',
              style: StyleGuide.smallLabelStyle,
            ),
          )
        else
          Wrap(
            spacing: StyleGuide.spacingSmall,
            runSpacing: StyleGuide.spacingSmall,
            children: project.teamMembers.map((member) {
              return Card(
                elevation: 0,
                color: theme.colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(StyleGuide.borderRadiusLarge),
                  side: BorderSide(color: theme.dividerColor),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: StyleGuide.paddingSmall,
                    vertical: StyleGuide.paddingTiny,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      StyleGuide.userAvatar(member[0]),
                      const SizedBox(width: StyleGuide.spacingSmall),
                      Text(
                        member,
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(width: StyleGuide.spacingSmall),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Future<void> _showManageTeamDialog(BuildContext context, Project project, WidgetRef ref, AppLocalizations l10n) async {
    final teamMembersController = TextEditingController(
      text: project.teamMembers.join(', ')
    );
    final formKey = GlobalKey<FormState>();
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Manage Team Members'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: teamMembersController,
                  decoration: StyleGuide.inputDecoration(
                    labelText: 'Team Members (comma separated)',
                    prefixIcon: Icons.people,
                  ).copyWith(
                    helperText: 'Enter team members separated by commas',
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancelButton),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final List<String> teamMembers = teamMembersController.text
                    .split(',')
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .toList();
                    
                final updatedProject = project.copyWith(
                  teamMembers: teamMembers,
                  updatedAt: DateTime.now(),
                );
                ref.read(projectNotifierProvider.notifier).updateProject(updatedProject);
                Navigator.pop(context);
              }
            },
            style: StyleGuide.buttonStyle(context),
            child: Text(l10n.saveButton),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskDetails(BuildContext context, ProjectTask task, bool canDelete, WidgetRef ref, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final canEditTask = ref.read(permissionProvider).contains('edit_task');
    
    return Card(
      elevation: StyleGuide.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(StyleGuide.borderRadiusMedium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(StyleGuide.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (canEditTask)
                      IconButton(
                        icon: Icon(Icons.edit, color: theme.colorScheme.primary, size: 20),
                        tooltip: 'Edit Task',
                        onPressed: () => _showEditTaskDialog(context, task, ref, l10n),
                      ),
                    if (canDelete)
                      IconButton(
                        icon: Icon(Icons.delete, color: theme.colorScheme.error, size: 20),
                        tooltip: l10n.confirmDeleteTitle,
                        onPressed: () => _showDeleteTaskDialog(context, task, ref, l10n),
                      ),
                  ],
                ),
              ],
            ),
            if (task.description.isNotEmpty) ...[
              const Divider(height: StyleGuide.spacingLarge),
              Text(
                task.description,
                style: theme.textTheme.bodyMedium,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: StyleGuide.spacingMedium),
            Wrap(
              spacing: StyleGuide.spacingSmall,
              runSpacing: StyleGuide.spacingSmall,
              children: [
                _buildTaskChip(
                  label: _getPriorityText(task.priority, l10n),
                  icon: Icons.flag,
                  backgroundColor: _getPriorityColor(task.priority).withOpacity(0.2),
                  textColor: _getPriorityColor(task.priority),
                  context: context,
                ),
                if (task.dueDate != null)
                  _buildTaskChip(
                    label: DateFormat('MMM d, y').format(task.dueDate!),
                    icon: Icons.calendar_today,
                    backgroundColor: _getDueDateColor(task.dueDate!).withOpacity(0.2),
                    textColor: _getDueDateColor(task.dueDate!),
                    context: context,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTaskChip({
    required String label,
    required IconData icon,
    required Color backgroundColor,
    required Color textColor,
    required BuildContext context,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: StyleGuide.paddingSmall,
        vertical: StyleGuide.paddingTiny,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(StyleGuide.borderRadiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: textColor,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Color _getDueDateColor(DateTime dueDate) {
    final now = DateTime.now();
    if (dueDate.isBefore(now)) {
      return ThemeConfig.errorColor; // Overdue
    } else if (dueDate.difference(now).inDays <= 2) {
      return ThemeConfig.warningColor; // Due soon
    } else {
      return ThemeConfig.infoColor; // Due later
    }
  }

  void _showDeleteTaskDialog(BuildContext context, ProjectTask task, WidgetRef ref, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmDeleteTitle),
        content: Text(l10n.confirmDeleteMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancelButton),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(projectTaskNotifierProvider.notifier).deleteTask(task.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ThemeConfig.errorColor,
              foregroundColor: ThemeConfig.primary,
            ),
            child: Text(l10n.yesButton),
          ),
        ],
      ),
    );
  }

  void _showEditTaskDialog(BuildContext context, ProjectTask task, WidgetRef ref, AppLocalizations l10n) {
    final titleController = TextEditingController(text: task.title);
    final descriptionController = TextEditingController(text: task.description);
    String priority = task.priority;
    DateTime dueDate = task.dueDate ?? DateTime.now().add(const Duration(days: 7));
    final formKey = GlobalKey<FormState>();
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Task'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: titleController,
                  decoration: StyleGuide.inputDecoration(
                    labelText: l10n.titleLabel,
                    prefixIcon: Icons.title,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a task title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: StyleGuide.spacingMedium),
                TextFormField(
                  controller: descriptionController,
                  decoration: StyleGuide.inputDecoration(
                    labelText: l10n.descriptionLabel,
                    prefixIcon: Icons.description,
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: StyleGuide.spacingMedium),
                DropdownButtonFormField<String>(
                  decoration: StyleGuide.inputDecoration(
                    labelText: l10n.priorityLabel,
                    prefixIcon: Icons.flag,
                  ),
                  value: priority,
                  items: [
                    _buildDropdownMenuItem('low', theme.colorScheme.primary.withOpacity(0.5), l10n.lowPriorityLabel),
                    _buildDropdownMenuItem('medium', theme.colorScheme.primary, l10n.mediumPriorityLabel),
                    _buildDropdownMenuItem('high', theme.colorScheme.error, l10n.highPriorityLabel),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      priority = value;
                    }
                  },
                ),
                const SizedBox(height: StyleGuide.spacingMedium),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: dueDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      dueDate = date;
                    }
                  },
                  child: InputDecorator(
                    decoration: StyleGuide.inputDecoration(
                      labelText: l10n.dueDateLabel,
                      prefixIcon: Icons.calendar_today,
                    ),
                    child: Text(DateFormat('MMM d, y').format(dueDate)),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancelButton),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final currentUser = getIt<SupabaseClientWrapper>()
                    .client
                    .auth
                    .currentUser;
                if (currentUser == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Error: User not authenticated')),
                  );
                  return;
                }

                final updatedTask = task.copyWith(
                  title: titleController.text,
                  description: descriptionController.text,
                  priority: priority,
                  dueDate: dueDate,
                  updatedBy: currentUser.id,
                  updatedAt: DateTime.now(),
                );
                ref.read(projectTaskNotifierProvider.notifier).updateTask(updatedTask);
                Navigator.pop(context);
              }
            },
            style: StyleGuide.buttonStyle(context),
            child: Text(l10n.saveButton),
          ),
        ],
      ),
    );
  }

  String _getStatusText(String status, AppLocalizations l10n) {
    switch (status) {
      case 'not_started':
        return l10n.statusNotStarted;
      case 'in_progress':
        return l10n.statusInProgress;
      case 'completed':
        return l10n.statusCompleted;
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'not_started':
        return ThemeConfig.labelTextColor.withOpacity(0.2);
      case 'in_progress':
        return ThemeConfig.warningColor.withOpacity(0.2);
      case 'completed':
        return ThemeConfig.successColor.withOpacity(0.2);
      default:
        return ThemeConfig.labelTextColor.withOpacity(0.2);
    }
  }
  
  Color _getStatusTextColor(String status) {
    switch (status) {
      case 'not_started':
        return ThemeConfig.labelTextColor;
      case 'in_progress':
        return ThemeConfig.warningColor;
      case 'completed':
        return ThemeConfig.successColor;
      default:
        return ThemeConfig.labelTextColor;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return ThemeConfig.errorColor;
      case 'medium':
        return ThemeConfig.accentColor;
      case 'low':
        return ThemeConfig.accentColor.withOpacity(0.5);
      default:
        return ThemeConfig.labelTextColor;
    }
  }

  String _getPriorityText(String priority, AppLocalizations l10n) {
    switch (priority) {
      case 'high':
        return l10n.highPriorityLabel;
      case 'medium':
        return l10n.mediumPriorityLabel;
      case 'low':
        return l10n.lowPriorityLabel;
      default:
        return priority;
    }
  }

  DropdownMenuItem<String> _buildDropdownMenuItem(String value, Color color, String label) {
    return DropdownMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  Future<void> _showUpdateProjectDialog(BuildContext context, Project project, WidgetRef ref, AppLocalizations l10n) async {
    final nameController = TextEditingController(text: project.name);
    final descriptionController = TextEditingController(text: project.description);
    final formKey = GlobalKey<FormState>();
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.editProjectButton),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: StyleGuide.inputDecoration(
                    labelText: l10n.projectNameLabel,
                    prefixIcon: Icons.title,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a project name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: StyleGuide.spacingMedium),
                TextFormField(
                  controller: descriptionController,
                  decoration: StyleGuide.inputDecoration(
                    labelText: l10n.descriptionLabel,
                    prefixIcon: Icons.description,
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancelButton),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final updatedProject = project.copyWith(
                  name: nameController.text,
                  description: descriptionController.text,
                  updatedAt: DateTime.now(),
                );
                ref.read(projectNotifierProvider.notifier).updateProject(updatedProject);
                Navigator.pop(context);
              }
            },
            style: StyleGuide.buttonStyle(context),
            child: Text(l10n.saveButton),
          ),
        ],
      ),
    );
  }

  void _showCreateTaskDialog(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    String priority = 'medium';
    DateTime dueDate = DateTime.now().add(const Duration(days: 7));
    final formKey = GlobalKey<FormState>();
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.createTaskTitle),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: titleController,
                  decoration: StyleGuide.inputDecoration(
                    labelText: l10n.titleLabel,
                    prefixIcon: Icons.title,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a task title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: StyleGuide.spacingMedium),
                TextFormField(
                  controller: descriptionController,
                  decoration: StyleGuide.inputDecoration(
                    labelText: l10n.descriptionLabel,
                    prefixIcon: Icons.description,
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: StyleGuide.spacingMedium),
                DropdownButtonFormField<String>(
                  decoration: StyleGuide.inputDecoration(
                    labelText: l10n.priorityLabel,
                    prefixIcon: Icons.flag,
                  ),
                  value: priority,
                  items: [
                    _buildDropdownMenuItem('low', theme.colorScheme.primary.withOpacity(0.5), l10n.lowPriorityLabel),
                    _buildDropdownMenuItem('medium', theme.colorScheme.primary, l10n.mediumPriorityLabel),
                    _buildDropdownMenuItem('high', theme.colorScheme.error, l10n.highPriorityLabel),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      priority = value;
                    }
                  },
                ),
                const SizedBox(height: StyleGuide.spacingMedium),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: dueDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      dueDate = date;
                    }
                  },
                  child: InputDecorator(
                    decoration: StyleGuide.inputDecoration(
                      labelText: l10n.dueDateLabel,
                      prefixIcon: Icons.calendar_today,
                    ),
                    child: Text(DateFormat('MMM d, y').format(dueDate)),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancelButton),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final currentUser = getIt<SupabaseClientWrapper>()
                    .client
                    .auth
                    .currentUser;
                if (currentUser == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Error: User not authenticated')),
                  );
                  return;
                }

                final now = DateTime.now();
                final task = ProjectTask(
                  id: '',
                  projectId: projectId,
                  title: titleController.text,
                  description: descriptionController.text,
                  status: 'not_started',
                  priority: priority,
                  attachments: [],
                  dueDate: dueDate,
                  createdBy: currentUser.id,
                  updatedBy: currentUser.id,
                  createdAt: now,
                  updatedAt: now,
                );
                ref.read(projectTaskNotifierProvider.notifier).createTask(task);
                Navigator.pop(context);
              }
            },
            style: StyleGuide.buttonStyle(context),
            child: Text(l10n.saveButton),
          ),
        ],
      ),
    );
  }
}