import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskfy/models/task.dart';
import 'package:taskfy/services/supabase_client.dart';
import 'package:logging/logging.dart';

final _log = Logger('TaskNotifier');

final taskListProvider = StreamProvider<List<Task>>((ref) {
  return supabaseClient.client
      .from('tasks')
      .stream(primaryKey: ['id'])
      .order('deadline', ascending: true)
      .map((data) => data.map((json) => Task.fromJson(json)).toList());
});

final taskProvider = StreamProvider.family<Task?, String>((ref, taskId) {
  return supabaseClient.client
      .from('tasks')
      .stream(primaryKey: ['id'])
      .eq('id', taskId)
      .map((data) => data.isNotEmpty ? Task.fromJson(data.first) : null);
});

class TaskNotifier extends StateNotifier<AsyncValue<Task?>> {
  TaskNotifier() : super(const AsyncValue.loading());

  final _supabase = supabaseClient.client;

  Future<void> createTask(Task task) async {
    state = const AsyncValue.loading();
    try {
      final response = await _supabase.from('tasks').insert(task.toJson()).select().single();
      final createdTask = Task.fromJson(response);
      state = AsyncValue.data(createdTask);
      _log.info('Task created successfully: ${createdTask.name}');
    } catch (e, stack) {
      _log.warning('Failed to create task: $e');
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> updateTask(Task task) async {
    state = const AsyncValue.loading();
    try {
      final updatedTask = task.toJson();
      _log.info('Updating task with data: $updatedTask');
      await _supabase.from('tasks').update(updatedTask).eq('id', task.id ?? '');
      state = AsyncValue.data(task);
      _log.info('Task updated successfully: ${task.name}');

      // Fetch the updated task from the database to verify the changes
      final updatedData = await _supabase
          .from('tasks')
          .select()
          .eq('id', task.id ?? '')
          .single();
      _log.info('Updated task in database: $updatedData');
    } catch (e, stack) {
      _log.warning('Failed to update task: $e');
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> deleteTask(String taskId) async {
    state = const AsyncValue.loading();
    try {
      await _supabase.from('tasks').delete().eq('id', taskId);
      state = const AsyncValue.data(null);
      _log.info('Task deleted successfully: $taskId');
    } catch (e, stack) {
      _log.warning('Failed to delete task: $e');
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }
}

final taskNotifierProvider = StateNotifierProvider<TaskNotifier, AsyncValue<Task?>>((ref) {
  return TaskNotifier();
});

