import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taskfy/providers/routine_providers.dart';
import 'package:taskfy/providers/auth_provider.dart';

class RoutineListWidget extends ConsumerWidget {
  final int? limit;

  const RoutineListWidget({super.key, this.limit});

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, String? routineId) {
    if (routineId == null) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Routine'),
        content: const Text('Are you sure you want to delete this routine?'),
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
                await ref.read(routineNotifierProvider.notifier).deleteRoutine(routineId);
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
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userEmail = ref.watch(authProvider).value?.email;
    final routinesAsyncValue = ref.watch(routineListStreamProvider(userEmail));

    return routinesAsyncValue.when(
      data: (routines) {
        if (limit != null && routines.length > limit!) {
          routines = routines.sublist(0, limit);
        }
        return ListView.builder(
          itemCount: routines.length,
          itemBuilder: (context, index) {
            final routine = routines[index];
            return ListTile(
              title: Text(routine.title),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Status: ${routine.status}'),
                  Text('Due: ${routine.dueDate.toString()}'),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => context.go('/routines/${routine.id}/edit'),
                    tooltip: 'Edit Routine',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _showDeleteConfirmation(context, ref, routine.id),
                    tooltip: 'Delete Routine',
                  ),
                ],
              ),
              onTap: () => context.go('/routines/${routine.id}'),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }
}

