import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taskfy/models/project.dart';
import 'package:taskfy/services/service_locator.dart';
import 'package:taskfy/services/supabase_client.dart';

final projectsProvider = StreamProvider((ref) {
  return getIt<SupabaseClientWrapper>().client
      .from('projects')
      .stream(primaryKey: ['id'])
      .map((data) => data.map((json) => Project.fromJson(json)).toList());
});

class ProjectList extends ConsumerWidget {
  final int? limit;

  const ProjectList({super.key, this.limit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsyncValue = ref.watch(projectsProvider);

    return projectsAsyncValue.when(
      data: (projects) {
        if (limit != null && projects.length > limit!) {
          projects = projects.sublist(0, limit);
        }
        return ListView.builder(
          itemCount: projects.length,
          itemBuilder: (context, index) {
            final project = projects[index];
            return ListTile(
              title: Text(project.name),
              subtitle: Text('Status: ${project.status}'),
              trailing: Text('Completion: ${project.completion.toStringAsFixed(1)}%'),
              onTap: () => context.go('/projects/${project.id}'),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }
}

