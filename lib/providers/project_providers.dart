import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskfy/models/project.dart';
import 'package:taskfy/services/service_locator.dart';
import 'package:taskfy/services/supabase_client.dart';
import 'package:logging/logging.dart';

final _log = Logger('ProjectNotifier');

final projectListProvider = StreamProvider.family<List<Project>, String?>((ref, userEmail) {
  final supabase = getIt<SupabaseClientWrapper>().client;
  final query = supabase.from('projects').stream(primaryKey: ['id']);
  
  if (userEmail != null) {
    return query
      .eq('team_members', [userEmail])
      .order('end_date')
      .map((data) => data.map((json) => Project.fromJson(json)).toList());
  } else {
    return query
      .order('end_date')
      .map((data) => data.map((json) => Project.fromJson(json)).toList());
  }
});


final projectProvider = StreamProvider.family<Project?, String>((ref, projectId) {
  return getIt<SupabaseClientWrapper>().client
      .from('projects')
      .stream(primaryKey: ['id'])
      .eq('id', projectId)
      .map((data) => data.isNotEmpty ? Project.fromJson(data.first) : null);
});

class ProjectNotifier extends StateNotifier<AsyncValue<Project?>> {
  ProjectNotifier() : super(const AsyncValue.loading());

  final _supabase = getIt<SupabaseClientWrapper>().client;

  Future<void> createProject(Project project) async {
    state = const AsyncValue.loading();
    try {
      final projectData = project.toJson()..remove('id');
      final response = await _supabase
          .from('projects')
          .insert(projectData)
          .select()
          .single();
      final createdProject = Project.fromJson(response);
      state = AsyncValue.data(createdProject);
      _log.info('Project created successfully: ${createdProject.name}');
    } catch (e, stack) {
      _log.warning('Failed to create project: $e');
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> updateProject(Project project) async {
    state = const AsyncValue.loading();
    try {
      await _supabase.from('projects').update(project.toJson()).eq('id', project.id);
      state = AsyncValue.data(project);
      _log.info('Project updated successfully: ${project.name}');
    } catch (e, stack) {
      _log.warning('Failed to update project: $e');
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> deleteProject(String projectId) async {
    state = const AsyncValue.loading();
    try {
      await _supabase.from('projects').delete().eq('id', projectId);
      state = const AsyncValue.data(null);
      _log.info('Project deleted successfully: $projectId');
    } catch (e, stack) {
      _log.warning('Failed to delete project: $e');
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }
}

final projectNotifierProvider = StateNotifierProvider<ProjectNotifier, AsyncValue<Project?>>((ref) {
  return ProjectNotifier();
});

