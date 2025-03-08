import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskfy/models/project.dart';
import 'package:taskfy/services/service_locator.dart';
import 'package:taskfy/services/supabase_client.dart';
import 'package:logging/logging.dart';
import 'package:taskfy/providers/auth_provider.dart';
import 'package:taskfy/config/constants.dart';

final _log = Logger('ProjectNotifier');

/// Provider for a list of projects, optionally filtered by user email.
final projectListStreamProvider =
    StreamProvider.family<List<Project>, String?>((ref, userEmail) {
  final supabase = getIt<SupabaseClientWrapper>().client;
  final user = ref.watch(authProvider).value;

  // Create a stream based on user role and email
  Stream<List<Map<String, dynamic>>> stream;
  if (userEmail != null) {
    if (user != null &&
        (user.role == AppConstants.roleAdmin ||
            user.role == AppConstants.roleManager)) {
      // For admin and manager, return all projects
      stream = supabase.from('projects').stream(primaryKey: ['id']);
    } else {
      // For other roles, return only projects they're part of
      // Use a different approach to avoid potential stream controller issues
      return supabase
          .from('projects')
          .select()
          .filter('team_members', 'cs', '["${userEmail}"]')
          .order('end_date', ascending: false)
          .then((data) {
            final projects = data.map((json) => Project.fromJson(json)).toList();
            projects.sort((a, b) => a.endDate.compareTo(b.endDate));
            return projects;
          })
          .asStream();
    }
  } else {
    // If no userEmail is provided, return all projects (useful for admin views)
    stream = supabase.from('projects').stream(primaryKey: ['id']);
  }

  // Transform the stream to return Project objects
  return stream.map((data) {
    final projects = data.map((json) => Project.fromJson(json)).toList();
    projects.sort((a, b) => a.endDate.compareTo(b.endDate));
    return projects;
  });
});

/// Provider for a single project, identified by its ID.
final projectProvider =
    StreamProvider.family<Project?, String>((ref, projectId) async* {
  final stream = getIt<SupabaseClientWrapper>()
      .client
      .from('projects')
      .stream(primaryKey: ['id']).eq('id', projectId);

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
      await _supabase
          .from('projects')
          .update(project.toJson())
          .eq('id', project.id);
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
      _log.info('Attempting to delete project with ID: $projectId');

      // First check if the project exists
      final projectExists = await _supabase
          .from('projects')
          .select('id')
          .eq('id', projectId)
          .maybeSingle();

      if (projectExists == null) {
        _log.warning('Project with ID $projectId not found');
        state = AsyncValue.error('Project not found', StackTrace.current);
        return;
      }

      // Use explicit delete with await
      await _supabase.from('projects').delete().eq('id', projectId);

      // Verify deletion was successful
      final checkDeleted = await _supabase
          .from('projects')
          .select('id')
          .eq('id', projectId)
          .maybeSingle();

      if (checkDeleted != null) {
        throw Exception('Failed to delete project: Record still exists');
      }

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
final projectNotifierProvider =
    StateNotifierProvider<ProjectNotifier, AsyncValue<Project?>>((ref) {
  return ProjectNotifier();
});
