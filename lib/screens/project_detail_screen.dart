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

    // Define status labels and colors for the kanban board
    final Map<String, String> statusLabels = {
      'not_started': l10n.statusNotStarted,
      'in_progress': l10n.statusInProgress,
      'completed': l10n.statusCompleted,
    };

    final Map<String, Color> statusColors = {
      'not_started': Colors.grey.shade200,
      'in_progress': Colors.blue.shade100,
      'completed': Colors.green.shade100,
    };

    return AppLayout(
      title: l10n.appTitle,
      pageTitle: l10n.projectsTitle,
      actions: [
        if (canCreateTask)
          ElevatedButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(l10n.createTaskTitle),
                  content: Builder(
                    builder: (context) {
                      String title = '';
                      String description = '';
                      String priority = 'medium';
                      DateTime dueDate =
                          DateTime.now().add(const Duration(days: 7));

                      return SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: MediaQuery.of(context).size.height * 0.7,
                            maxWidth: MediaQuery.of(context).size.width * 0.8,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextField(
                                decoration:
                                    InputDecoration(labelText: l10n.titleLabel),
                                onChanged: (value) => title = value,
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                decoration: InputDecoration(
                                    labelText: l10n.descriptionLabel),
                                maxLines: 3,
                                onChanged: (value) => description = value,
                              ),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<String>(
                                decoration: InputDecoration(
                                    labelText: l10n.priorityLabel),
                                value: priority,
                                items: [
                                  DropdownMenuItem(
                                      value: 'low',
                                      child: Text(l10n.lowPriorityLabel)),
                                  DropdownMenuItem(
                                      value: 'medium',
                                      child: Text(l10n.mediumPriorityLabel)),
                                  DropdownMenuItem(
                                      value: 'high',
                                      child: Text(l10n.highPriorityLabel)),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    priority = value;
                                  }
                                },
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Text('${l10n.dueDateLabel}: '),
                                  TextButton(
                                    onPressed: () async {
                                      final selectedDate = await showDatePicker(
                                        context: context,
                                        initialDate: dueDate,
                                        firstDate: DateTime.now(),
                                        lastDate: DateTime.now()
                                            .add(const Duration(days: 365)),
                                      );
                                      if (selectedDate != null) {
                                        dueDate = selectedDate;
                                      }
                                    },
                                    child: Text(_formatDate(dueDate)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text(l10n.cancelButton),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      if (title.isNotEmpty) {
                                        final currentUser =
                                            getIt<SupabaseClientWrapper>()
                                                .client
                                                .auth
                                                .currentUser;
                                        if (currentUser == null) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                                content: Text(
                                                    'Error: User not authenticated')),
                                          );
                                          return;
                                        }

                                        final now = DateTime.now();
                                        final task = ProjectTask(
                                          id: '',
                                          projectId: projectId,
                                          title: title,
                                          description: description,
                                          status: 'not_started',
                                          priority: priority,
                                          attachments: [],
                                          dueDate: dueDate,
                                          createdBy: currentUser.id,
                                          updatedBy: currentUser.id,
                                          createdAt: now,
                                          updatedAt: now,
                                        );
                                        ref
                                            .read(projectTaskNotifierProvider
                                                .notifier)
                                            .createTask(task);
                                        Navigator.pop(context);
                                      }
                                    },
                                    child: Text(l10n.saveButton),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: Text(l10n.addTaskButton),
          ),
      ],
      child: projectAsyncValue.when(
        data: (project) {
          if (project == null) {
            return Center(child: Text(l10n.noDataFound));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoSection(context, project, l10n),
                const SizedBox(height: 24),
                Text(l10n.projectsTitle,
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 16),
                _buildTeamSection(context, project, ref, l10n),
                const SizedBox(height: 24),
                Text(l10n.projectTasksTitle,
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 16),
                SizedBox(
                  height: 400, // Fixed height for Kanban board
                  child: tasksAsyncValue.when(
                    data: (tasks) {
                      return ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: 100, // Ensure minimum height
                          minWidth: 300, // Ensure minimum width
                        ),
                        child: KanbanBoard<ProjectTask>(
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
                              context, task, canDeleteTask, ref),
                        ),
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, stack) =>
                        Center(child: Text(l10n.errorOccurred)),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text(l10n.errorOccurred)),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildInfoSection(
      BuildContext context, Project project, AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(l10n.projectNameLabel, project.name, context),
            _buildInfoRow(l10n.descriptionLabel, project.description, context),
            _buildInfoRow(l10n.statusLabel, project.status, context),
            _buildInfoRow(l10n.completionLabel,
                '${project.completion.toStringAsFixed(1)}%', context),
            _buildInfoRow(
                l10n.startDateLabel, project.startDate.toString(), context),
            _buildInfoRow(
                l10n.endDateLabel, project.endDate.toString(), context),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamSection(BuildContext context, Project project, WidgetRef ref,
      AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.projectsTitle),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () =>
                      _showUpdateProjectDialog(context, project, ref, l10n),
                ),
              ],
            ),
            const Divider(),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: project.teamMembers.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: CircleAvatar(
                    child: Text(project.teamMembers[index][0].toUpperCase()),
                  ),
                  title: Text(project.teamMembers[index]),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showUpdateProjectDialog(BuildContext context, Project project,
      WidgetRef ref, AppLocalizations l10n) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.editProjectButton),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(labelText: l10n.projectNameLabel),
                controller: TextEditingController(text: project.name),
                onChanged: (value) => project = project.copyWith(name: value),
              ),
              TextField(
                decoration: InputDecoration(labelText: l10n.descriptionLabel),
                controller: TextEditingController(text: project.description),
                onChanged: (value) =>
                    project = project.copyWith(description: value),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancelButton),
          ),
          TextButton(
            onPressed: () {
              ref.read(projectNotifierProvider.notifier).updateProject(project);
              Navigator.pop(context);
            },
            child: Text(l10n.saveButton),
          ),
        ],
      ),
    );
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

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return Colors.red.shade100;
      case 'medium':
        return Colors.orange.shade100;
      case 'low':
        return Colors.green.shade100;
      default:
        return Colors.grey.shade100;
    }
  }

  Color _getDueDateColor(DateTime dueDate) {
    final now = DateTime.now();
    if (dueDate.isBefore(now)) {
      return Colors.red.shade100; // Overdue
    } else if (dueDate.difference(now).inDays <= 2) {
      return Colors.orange.shade100; // Due soon
    } else {
      return Colors.blue.shade100; // Due later
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Widget _buildTaskDetails(
      BuildContext context, ProjectTask task, bool canDelete, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                if (canDelete)
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
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
                            TextButton(
                              onPressed: () {
                                ref
                                    .read(projectTaskNotifierProvider.notifier)
                                    .deleteTask(task.id);
                                Navigator.pop(context);
                              },
                              child: Text(l10n.yesButton),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(task.description),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  label: Text(
                      '${l10n.priorityLabel}: ${_getPriorityText(task.priority, l10n)}'),
                  backgroundColor: _getPriorityColor(task.priority),
                ),
                if (task.dueDate != null)
                  Chip(
                    label: Text(
                        '${l10n.dueDateLabel}: ${_formatDate(task.dueDate!)}'),
                    backgroundColor: _getDueDateColor(task.dueDate!),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _showUpdateProjectDialog(BuildContext context, Project project,
    WidgetRef ref, AppLocalizations l10n) async {
  await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.editProjectButton),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(labelText: l10n.projectNameLabel),
              controller: TextEditingController(text: project.name),
              onChanged: (value) => project = project.copyWith(name: value),
            ),
            TextField(
              decoration: InputDecoration(labelText: l10n.descriptionLabel),
              controller: TextEditingController(text: project.description),
              onChanged: (value) =>
                  project = project.copyWith(description: value),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancelButton),
        ),
        TextButton(
          onPressed: () {
            ref.read(projectNotifierProvider.notifier).updateProject(project);
            Navigator.pop(context);
          },
          child: Text(l10n.saveButton),
        ),
      ],
    ),
  );
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

Color _getPriorityColor(String priority) {
  switch (priority) {
    case 'high':
      return Colors.red.shade100;
    case 'medium':
      return Colors.orange.shade100;
    case 'low':
      return Colors.green.shade100;
    default:
      return Colors.grey.shade100;
  }
}

Color _getDueDateColor(DateTime dueDate) {
  final now = DateTime.now();
  if (dueDate.isBefore(now)) {
    return Colors.red.shade100; // Overdue
  } else if (dueDate.difference(now).inDays <= 2) {
    return Colors.orange.shade100; // Due soon
  } else {
    return Colors.blue.shade100; // Due later
  }
}

String _formatDate(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

Widget _buildTaskDetails(
    BuildContext context, ProjectTask task, bool canDelete, WidgetRef ref) {
  final l10n = AppLocalizations.of(context)!;
  return Card(
    elevation: 2,
    margin: const EdgeInsets.only(bottom: 8),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  task.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              if (canDelete)
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
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
                          TextButton(
                            onPressed: () {
                              ref
                                  .read(projectTaskNotifierProvider.notifier)
                                  .deleteTask(task.id);
                              Navigator.pop(context);
                            },
                            child: Text(l10n.yesButton),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(task.description),
          const SizedBox(height: 12),
          Row(
            children: [
              Chip(
                label: Text(
                    '${l10n.priorityLabel}: ${_getPriorityText(task.priority, l10n)}'),
                backgroundColor: _getPriorityColor(task.priority),
              ),
              const SizedBox(width: 8),
              if (task.dueDate != null)
                Chip(
                  label: Text(
                      '${l10n.dueDateLabel}: ${_formatDate(task.dueDate!)}'),
                  backgroundColor: _getDueDateColor(task.dueDate!),
                ),
            ],
          ),
        ],
      ),
    ),
  );
}
