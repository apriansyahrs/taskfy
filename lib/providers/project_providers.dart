import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskfy/models/project.dart';
import 'package:taskfy/services/service_locator.dart';
import 'package:taskfy/services/supabase_client.dart';
import 'package:logging/logging.dart';
import 'package:taskfy/providers/auth_provider.dart';

final _log = Logger('ProjectNotifier');

/// Provider for a list of projects, optionally filtered by user email.
final projectListStreamProvider = StreamProvider.family<List<Project>, String?>((ref, userEmail) async* {
  final supabase = getIt<SupabaseClientWrapper>().client;
  
  Stream<List<Map<String, dynamic>>> stream;
  if (userEmail != null) {
    final user = ref.watch(authProvider);
    if (user?.role == 'admin' || user?.role == 'manager') {
      // For admin and manager, return all projects
      stream = supabase.from('projects').stream(primaryKey: ['id']);
    } else {
      // For other roles, return only projects they're part of
      stream = supabase
        .from('projects')
        .select()
        .filter('team_members', 'cs', '{$userEmail}')
        .order('end_date')
        .then((data) => data.map((json) => json as Map<String, dynamic>).toList())
        .asStream();
    }
  } else {
    // If no userEmail is provided, return all projects (useful for admin views)
    stream = supabase.from('projects').stream(primaryKey: ['id']);
  }

  await for (final data in stream) {
    final projects = data.map((json) => Project.fromJson(json)).toList();
    projects.sort((a, b) => a.endDate.compareTo(b.endDate));
    yield projects;
  }
});

/// Provider for a single project, identified by its ID.
final projectProvider = StreamProvider.family<Project?, String>((ref, projectId) async* {
  final stream = getIt<SupabaseClientWrapper>().client
      .from('projects')
      .stream(primaryKey: ['id'])
      .eq('id', projectId);

  await for (final data in stream) {
    if (data.isNotEmpty) {
      yield Project.fromJson(data.first);
    } else {
      yield null;
    }
  }
});

/// Notifier for managing project state and operations.
class ProjectNotifier extends StateNotifier<AsyncValue<Project?>> {
  ProjectNotifier() : super(const AsyncValue.loading());

  final _supabase = getIt<SupabaseClientWrapper>().client;

  /// Creates a new project.
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

  /// Updates an existing project.
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

  /// Deletes a project by its ID.
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

/// Provider for the ProjectNotifier.
final projectNotifierProvider = StateNotifierProvider<ProjectNotifier, AsyncValue<Project?>>((ref) {
  return ProjectNotifier();
});

