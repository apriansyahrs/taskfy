import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskfy/widgets/app_layout.dart';
import 'package:taskfy/widgets/kanban_board.dart';
import 'package:taskfy/providers/auth_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:taskfy/config/theme_config.dart';
import 'package:taskfy/models/routine.dart';
import 'package:taskfy/providers/routine_providers.dart';
import 'package:logging/logging.dart';

final _log = Logger('MyRoutinesScreen');

class MyRoutinesScreen extends ConsumerWidget {
  const MyRoutinesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    _log.info('Building MyRoutinesScreen');
    final userState = ref.watch(authProvider);
    final userEmail = userState.value?.email.trim().toLowerCase();
    _log.info('Current user email: $userEmail, role: ${userState.value?.role}');
    
    final routinesAsyncValue = ref.watch(routineListStreamProvider(userEmail));
    final l10n = AppLocalizations.of(context)!;

    // Log any errors from async values
    if (routinesAsyncValue.hasError) {
      _log.severe('Error loading routines: ${routinesAsyncValue.error}', routinesAsyncValue.error, StackTrace.current);
    }

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
      pageTitle: l10n.myRoutinesTitle,
      actions: [], // Removed create button for my_routines screen
      child: routinesAsyncValue.when(
        data: (routines) {
          // Routines are already filtered by the provider based on user email in assignees
          final todayRoutines = routines.where((routine) => isToday(routine.dueDate)).toList();
          final upcomingRoutines = routines.where((routine) => isFuture(routine.dueDate)).toList();
          final pastDueRoutines = routines.where((routine) => isPastDue(routine.dueDate)).toList();

          return LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: SizedBox(
                  width: constraints.maxWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader(context, l10n.todayRoutinesTitle, Icons.today),
                      SizedBox(
                        height: 400, // Fixed height for Kanban board
                        child: KanbanBoard<Routine>(
                          items: todayRoutines,
                          getTitle: (routine) => routine.title,
                          getStatus: (routine) => routine.status,
                          onStatusChange: (routine, newStatus) async {
                            final notifier = ref.read(routineNotifierProvider.notifier);
                            await notifier.updateRoutine(
                              routine.copyWith(status: newStatus),
                            );
                          },
                          statuses: ['not_started', 'in_progress', 'completed'],
                          statusLabels: statusLabels,
                          statusColors: statusColors,
                          canEdit: (routine) => true,
                          buildItemDetails: (routine) => _buildRoutineDetails(context, routine, ref),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildSectionHeader(context, l10n.routineOverviewTitle, Icons.assessment),
                      SizedBox(
                        height: 300, // Fixed height for overview section
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildRoutineOverview(
                                context,
                                l10n.upcomingTitle,
                                upcomingRoutines,
                                ref,
                                ThemeConfig.infoColor,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildRoutineOverview(
                                context,
                                l10n.pastDueTitle,
                                pastDueRoutines,
                                ref,
                                ThemeConfig.errorColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(l10n.loading),
            ],
          ),
        ),
        error: (error, stack) => Center(
          child: Text('${l10n.errorOccurred}: $error'),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoutineDetails(BuildContext context, Routine routine, WidgetRef ref) {
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
                    routine.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                // Delete button removed for my_routines screen
              ],
            ),
            const SizedBox(height: 8),
            Text(routine.description),
            const SizedBox(height: 12),
            Row(
              children: [
                Chip(
                  label: Text('${l10n.priorityLabel}: ${_getPriorityText(routine.priority, l10n)}'),
                  backgroundColor: _getPriorityColor(routine.priority),
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text('${l10n.dueDateLabel}: ${_formatDate(routine.dueDate)}'),
                  backgroundColor: _getDueDateColor(routine.dueDate, context),
                ),
              ],
            ),
            if (routine.assignees.isNotEmpty) ...[  
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: routine.assignees.map((email) => Chip(
                  label: Text(email.split('@').first),
                  avatar: const CircleAvatar(
                    child: Icon(Icons.person, size: 16),
                  ),
                )).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRoutineOverview(BuildContext context, String title, List<Routine> routines, WidgetRef ref, Color color) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    routines.length.toString(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color.withOpacity(0.8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: routines.length,
              itemBuilder: (context, index) {
                final routine = routines[index];
                return Card(
                  elevation: 1,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    title: Text(
                      routine.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${_formatDate(routine.dueDate)} - ${_getPriorityText(routine.priority, l10n)}',
                      style: TextStyle(
                        color: _getPriorityColor(routine.priority).withOpacity(0.8),
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.arrow_forward_ios, size: 16),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(routine.title),
                            content: _buildRoutineDetails(context, routine, ref),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(l10n.cancelButton),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    onTap: () {
                      // Update status if tapped
                      if (routine.status != 'completed') {
                        ref.read(routineNotifierProvider.notifier).updateRoutine(
                          routine.copyWith(status: 'in_progress'),
                        );
                      }
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
  
  // Helper methods
  String _formatDate(DateTime date) {
    return DateFormat.yMMMd().format(date);
  }
  
  String _getPriorityText(String priority, AppLocalizations l10n) {
    switch (priority) {
      case 'low':
        return l10n.lowPriorityLabel;
      case 'medium':
        return l10n.mediumPriorityLabel;
      case 'high':
        return l10n.highPriorityLabel;
      default:
        return l10n.mediumPriorityLabel;
    }
  }
  
  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'low':
        return Colors.green.shade100;
      case 'medium':
        return Colors.orange.shade100;
      case 'high':
        return Colors.red.shade100;
      default:
        return Colors.orange.shade100;
    }
  }
  
  Color _getDueDateColor(DateTime dueDate, BuildContext context) {
    if (isPastDue(dueDate)) {
      return Colors.red.shade100;
    } else if (isToday(dueDate)) {
      return Colors.orange.shade100;
    } else {
      return Colors.blue.shade100;
    }
  }
  
  bool isUserAssigned(Routine routine, String? userEmail) {
    if (userEmail == null) return false;
    return routine.assignees.contains(userEmail);
  }
  
  bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }
  
  bool isFuture(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final compareDate = DateTime(date.year, date.month, date.day);
    return compareDate.isAfter(today);
  }
  
  bool isPastDue(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final compareDate = DateTime(date.year, date.month, date.day);
    return compareDate.isBefore(today);
  }
}