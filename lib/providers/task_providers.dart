import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskfy/models/task.dart';
import 'package:taskfy/services/service_locator.dart';
import 'package:taskfy/services/supabase_client.dart';
import 'package:taskfy/utils/error_handler.dart';
import 'package:taskfy/providers/auth_provider.dart';

/// Provider for a list of tasks, optionally filtered by user email.
final taskListStreamProvider = StreamProvider.family<List<Task>, String?>((ref, userEmail) async* {
  final supabase = getIt<SupabaseClientWrapper>().client;
  
  Stream<List<Map<String, dynamic>>> stream;
  if (userEmail != null) {
    final user = ref.watch(authProvider);
    if (user?.role == 'admin' || user?.role == 'manager') {
      // For admin and manager, return all tasks
      stream = supabase.from('tasks').stream(primaryKey: ['id']);
    } else {
      // For other roles, return only assigned tasks
      stream = supabase
        .from('tasks')
        .select()
        .filter('assigned_to', 'cs', '{$userEmail}')
        .order('deadline')
        .then((data) => data.map((json) => json as Map<String, dynamic>).toList())
        .asStream();
    }
  } else {
    // If no userEmail is provided, return all tasks (useful for admin views)
    stream = supabase.from('tasks').stream(primaryKey: ['id']);
  }

  await for (final data in stream) {
    final tasks = data.map((json) => Task.fromJson(json)).toList();
    tasks.sort((a, b) => a.deadline.compareTo(b.deadline));
    yield tasks;
  }
});

/// Provider for a single task, identified by its ID.
final taskProvider = StreamProvider.family<Task?, String>((ref, taskId) async* {
  final stream = getIt<SupabaseClientWrapper>().client
      .from('tasks')
      .stream(primaryKey: ['id'])
      .eq('id', taskId);

  await for (final data in stream) {
    if (data.isNotEmpty) {
      yield Task.fromJson(data.first);
    } else {
      yield null;
    }
  }
});

/// Notifier for managing task state and operations.
class TaskNotifier extends StateNotifier<AsyncValue<Task?>> {
  TaskNotifier() : super(const AsyncValue.loading());

  final _supabase = getIt<SupabaseClientWrapper>().client;

  /// Creates a new task.
  Future<void> createTask(Task task) async {
    state = const AsyncValue.loading();
    try {
      final response =
          await _supabase.from('tasks').insert(task.toJson()).select().single();
      final createdTask = Task.fromJson(response);
      state = AsyncValue.data(createdTask);
      log.info('Task created successfully: ${createdTask.name}');
    } catch (e, stack) {
      log.severe('Failed to create task', e, stack);
      state = AsyncValue.error(getErrorMessage(e), stack);
    }
  }

  /// Updates an existing task.
  Future<void> updateTask(Task task) async {
    state = const AsyncValue.loading();
    try {
      final updatedTask = task.toJson();
      log.info('Updating task with data: $updatedTask');
      await _supabase.from('tasks').update(updatedTask).eq('id', task.id ?? '');
      state = AsyncValue.data(task);
      log.info('Task updated successfully: ${task.name}');

      final updatedData = await _supabase
          .from('tasks')
          .select()
          .eq('id', task.id ?? '')
          .single();
      log.info('Updated task in database: $updatedData');
    } catch (e, stack) {
      log.severe('Failed to update task', e, stack);
      state = AsyncValue.error(getErrorMessage(e), stack);
    }
  }

  /// Deletes a task by its ID.
  Future<void> deleteTask(String taskId) async {
    state = const AsyncValue.loading();
    try {
      await _supabase.from('tasks').delete().eq('id', taskId);
      state = const AsyncValue.data(null);
      log.info('Task deleted successfully: $taskId');
    } catch (e, stack) {
      log.severe('Failed to delete task', e, stack);
      state = AsyncValue.error(getErrorMessage(e), stack);
    }
  }
}

/// Provider for the TaskNotifier.
final taskNotifierProvider =
    StateNotifierProvider<TaskNotifier, AsyncValue<Task?>>((ref) {
  return TaskNotifier();
});

