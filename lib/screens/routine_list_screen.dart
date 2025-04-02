import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taskfy/widgets/app_layout.dart';
import 'package:taskfy/widgets/stat_card.dart';
import 'package:intl/intl.dart';
import 'package:taskfy/widgets/error_widget.dart';
import 'package:taskfy/config/constants.dart';
import 'package:taskfy/providers/permission_provider.dart';
import 'package:taskfy/providers/auth_provider.dart';
import 'package:taskfy/models/user.dart' as taskfy_user;
import 'package:taskfy/config/style_guide.dart';
import 'package:taskfy/models/routine.dart';
import 'package:taskfy/providers/routine_providers.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:logging/logging.dart';

final _log = Logger('RoutineListScreen');

/// Screen for displaying and managing the list of routines.
class RoutineListScreen extends ConsumerStatefulWidget {
  const RoutineListScreen({super.key});

  @override
  ConsumerState<RoutineListScreen> createState() => _RoutineListScreenState();
}

class _RoutineListScreenState extends ConsumerState<RoutineListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _log.info('Building RoutineListScreen');
    final userState = ref.watch(authProvider);
    final userEmail = userState.value?.email;
    _log.info('Current user email: $userEmail, role: ${userState.value?.role}');
    
    final routinesAsyncValue = ref.watch(routineListStreamProvider(userEmail));
    final permissions = ref.watch(permissionProvider);
    _log.info('User permissions: $permissions');
    
    final l10n = AppLocalizations.of(context)!;

    // Log any errors from async values
    if (routinesAsyncValue.hasError) {
      _log.severe('Error loading routines: ${routinesAsyncValue.error}', routinesAsyncValue.error, StackTrace.current);
    }

    return AppLayout(
      title: l10n.appTitle,
      pageTitle: l10n.routinesTitle,
      floatingActionButton: permissions.contains(AppConstants.permissionCreateRoutine)
        ? FloatingActionButton.extended(
            icon: const Icon(Icons.add),
            label: Text(l10n.createRoutineButton),
            onPressed: () => context.go('${AppConstants.routinesRoute}/create'),
          )
        : null,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatCards(routinesAsyncValue),
            SizedBox(height: StyleGuide.spacingLarge),
            _buildRoutineList(context, routinesAsyncValue, permissions),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCards(AsyncValue<List<Routine>> routinesAsyncValue) {
    final l10n = AppLocalizations.of(context)!;
    return routinesAsyncValue.when(
      data: (routines) => LayoutBuilder(
        builder: (context, constraints) {
          final cardWidth = (constraints.maxWidth - (3 * StyleGuide.spacingMedium)) / 4;
          return Wrap(
            spacing: StyleGuide.spacingMedium,
            runSpacing: StyleGuide.spacingMedium,
            children: [
              SizedBox(
                width: cardWidth,
                child: StatCard(
                  title: l10n.totalRoutinesTitle,
                  value: routines.length.toString(),
                  icon: Icons.assignment,
                  color: Colors.blue,
                ),
              ),
              SizedBox(
                width: cardWidth,
                child: StatCard(
                  title: l10n.inProgressTitle,
                  value: routines.where((r) => r.status == AppConstants.routineStatusInProgress).length.toString(),
                  icon: Icons.trending_up,
                  color: Colors.orange,
                ),
              ),
              SizedBox(
                width: cardWidth,
                child: StatCard(
                  title: l10n.completedTitle,
                  value: routines.where((r) => r.status == AppConstants.routineStatusCompleted).length.toString(),
                  icon: Icons.check_circle,
                  color: Colors.green,
                ),
              ),
              SizedBox(
                width: cardWidth,
                child: StatCard(
                  title: l10n.overdueTitle,
                  value: routines.where((r) => r.dueDate.isBefore(DateTime.now()) && r.status != AppConstants.routineStatusCompleted).length.toString(),
                  icon: Icons.warning,
                  color: Colors.red,
                ),
              ),
            ],
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => CustomErrorWidget(message: err.toString()),
    );
  }

  Widget _buildRoutineList(BuildContext context, AsyncValue<List<Routine>> routinesAsyncValue, Set<String> permissions) {
    final user = ref.watch(authProvider);
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: EdgeInsets.all(StyleGuide.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  l10n.routineListTitle,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const Spacer(),
                SizedBox(
                  width: 200,
                  child: TextField(
                    controller: _searchController,
                    decoration: StyleGuide.inputDecoration(
                      labelText: l10n.searchRoutinesPlaceholder,
                      prefixIcon: Icons.search,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: StyleGuide.spacingMedium),
            routinesAsyncValue.when(
              data: (routines) => _TaskTable(
                routines: routines,
                searchQuery: _searchController.text.toLowerCase(),
                onDelete: (String routineId) async {
                  return await ref.read(routineNotifierProvider.notifier).deleteRoutine(routineId);
                },
                permissions: permissions,
                currentUser: user.value,
                routineNotifierProvider: routineNotifierProvider,
                l10n: l10n,
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => CustomErrorWidget(message: err.toString()),
            ),
          ],
        ),
      ),
    );
  }
}



class _TaskTable extends StatelessWidget {
  final List<Routine>? routines;
  final String searchQuery;
  final Function(String) onDelete;
  final Set<String> permissions;
  final taskfy_user.User? currentUser;
  final StateNotifierProvider<RoutineNotifier, AsyncValue<Routine?>> routineNotifierProvider;
  final AppLocalizations l10n;

  const _TaskTable({
    required this.routines,
    required this.searchQuery,
    required this.onDelete,
    required this.permissions,
    required this.currentUser,
    required this.routineNotifierProvider,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final filteredRoutines = (routines ?? []).where((routine) =>
      routine.title.toLowerCase().contains(searchQuery) ||
      routine.description.toLowerCase().contains(searchQuery) ||
      routine.status.toLowerCase().contains(searchQuery)
    ).toList();

    return filteredRoutines.isEmpty
      ? const Center(child: Text('No routines found'))
      : LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: DataTable(
                  columns: [
                    DataColumn(label: Text(l10n.titleLabel)),
                    DataColumn(label: Text(l10n.statusLabel)),
                    DataColumn(label: Text(l10n.priorityLabel)),
                    DataColumn(label: Text(l10n.assigneesLabel)),
                    DataColumn(label: Text(l10n.dueDateLabel)),
                    DataColumn(label: Text(l10n.actionsLabel)),
                  ],
                  rows: filteredRoutines.map((routine) => _buildRoutineRow(context, routine)).toList(),
                ),
              ),
            );
          },
        );
  }

  DataRow _buildRoutineRow(BuildContext context, Routine routine) {
    return DataRow(
      cells: [
        DataCell(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(routine.title),
              Text(
                routine.description,
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
              horizontal: StyleGuide.paddingSmall,
              vertical: StyleGuide.paddingSmall / 2,
            ),
            decoration: BoxDecoration(
              color: _getStatusColor(routine.status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(StyleGuide.borderRadiusMedium),
            ),
            child: Text(
              routine.status,
              style: TextStyle(color: _getStatusColor(routine.status)),
            ),
          ),
        ),
        DataCell(Text(routine.priority)),
        DataCell(Text(routine.assignees.join(', '))),
        DataCell(Text(DateFormat('MMM dd, yyyy').format(routine.dueDate))),
        DataCell(_buildActionButtons(context, routine)),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, Routine routine) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () => context.go('/routines/${routine.id}/edit'),
          tooltip: 'Edit Routine',
        ),
        IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () => routine.id != null ? _showDeleteRoutineDialog(context, routine.id!) : null,
          tooltip: 'Delete Routine',
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'in_progress':
        return Colors.blue;
      case 'not_started':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
  
  void _showDeleteRoutineDialog(BuildContext context, String routineId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Routine'),
        content: const Text('Are you sure you want to delete this routine?'),
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
                await onDelete(routineId);
                scaffoldMessenger.showSnackBar(
                  const SnackBar(content: Text('Routine deleted successfully')),
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

