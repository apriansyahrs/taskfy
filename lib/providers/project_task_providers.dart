import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskfy/models/project_task.dart';
import 'package:taskfy/services/service_locator.dart';
import 'package:taskfy/services/supabase_client.dart';
import 'package:taskfy/providers/auth_provider.dart';
import 'package:logging/logging.dart';

final _log = Logger('ProjectTaskNotifier');

/// Provider for managing project task state
final projectTaskNotifierProvider = StateNotifierProvider<ProjectTaskNotifier, AsyncValue<ProjectTask?>>((ref) => ProjectTaskNotifier());

/// Provider for a list of project tasks, filtered by project ID
final projectTaskListStreamProvider = StreamProvider.family<List<ProjectTask>, String>((ref, projectId) async* {
  final supabase = getIt<SupabaseClientWrapper>().client;
  final authState = ref.watch(authProvider);
  final user = authState.value;
  
  if (user == null) {
    throw Exception('User not authenticated');
  }

  Stream<List<Map<String, dynamic>>> stream;
  if (user.role == 'admin' || user.role == 'manager') {
    // For admin and manager, return all tasks for the project
    stream = supabase
      .from('project_tasks')
      .stream(primaryKey: ['id'])
      .eq('project_id', projectId)
      .order('due_date');
  } else {
    // For other roles, return only tasks from projects they're part of
    final project = await supabase
      .from('projects')
      .select()
      .eq('id', projectId)
      .single();
    
    final teamMembers = (project['team_members'] as List?)?.cast<String>() ?? [];
    if (!teamMembers.contains(user.email)) {
      throw Exception('User not authorized to view these tasks');
    }
    
    stream = supabase
      .from('project_tasks')
      .stream(primaryKey: ['id'])
      .eq('project_id', projectId)
      .order('due_date');
  }

  await for (final data in stream) {
    yield data.map((json) => ProjectTask.fromJson(json)).toList();
  }
});

class ProjectTaskNotifier extends StateNotifier<AsyncValue<ProjectTask?>> {
  ProjectTaskNotifier() : super(const AsyncValue.data(null));

  final _supabase = getIt<SupabaseClientWrapper>().client;

  Future<void> createTask(ProjectTask task) async {
    try {
      state = const AsyncValue.loading();
      final taskData = task.toJson()..remove('id');
      final response = await _supabase
          .from('project_tasks')
          .insert(taskData)
          .select()
          .single();
      final createdTask = ProjectTask.fromJson(response);
      state = AsyncValue.data(createdTask);
      _log.info('Task created successfully: ${createdTask.title}');
    } catch (error, stackTrace) {
      _log.severe('Error creating task: $error');
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> updateTask(ProjectTask task) async {
    try {
      state = const AsyncValue.loading();
      final response = await _supabase
          .from('project_tasks')
          .update(task.toJson())
          .eq('id', task.id)
          .select()
          .single();
      final updatedTask = ProjectTask.fromJson(response);
      state = AsyncValue.data(updatedTask);
      _log.info('Task updated successfully: ${updatedTask.title}');
    } catch (error, stackTrace) {
      _log.severe('Error updating task: $error');
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      state = const AsyncValue.loading();
      await _supabase.from('project_tasks').delete().eq('id', taskId);
      state = const AsyncValue.data(null);
      _log.info('Task deleted successfully: $taskId');
    } catch (error, stackTrace) {
      _log.severe('Error deleting task: $error');
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<ProjectTask?> getTask(String taskId) async {
    try {
      state = const AsyncValue.loading();
      final response = await _supabase
          .from('project_tasks')
          .select()
          .eq('id', taskId)
          .single();
      final task = ProjectTask.fromJson(response);
      state = AsyncValue.data(task);
      return task;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      _log.severe('Error getting task: $error');
      rethrow;
    }
  }
}