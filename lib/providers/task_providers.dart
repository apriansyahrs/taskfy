import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase/src/supabase_stream_builder.dart';
import 'package:taskfy/models/task.dart';
import 'package:taskfy/services/service_locator.dart';
import 'package:taskfy/services/supabase_client.dart';
import 'package:taskfy/utils/error_handler.dart';

/// Provider for a list of tasks, optionally filtered by user email.
final taskListProvider =
    StreamProvider.family<List<Task>, String?>((ref, userEmail) {
  final supabase = getIt<SupabaseClientWrapper>().client;
  final query = supabase.from('tasks').stream(primaryKey: ['id']);

  if (userEmail != null) {
    return query
        .eq('assigned_to', [userEmail])
        .order('deadline')
        .map((data) => data.map((json) => Task.fromJson(json)).toList());
  } else {
    return query
        .order('deadline')
        .map((data) => data.map((json) => Task.fromJson(json)).toList());
  }
});

/// Provider for a single task, identified by its ID.
final taskProvider = StreamProvider.family<Task?, String>((ref, taskId) {
  return getIt<SupabaseClientWrapper>()
      .client
      .from('tasks')
      .stream(primaryKey: ['id'])
      .eq('id', taskId)
      .map((data) => data.isNotEmpty ? Task.fromJson(data.first) : null);
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

