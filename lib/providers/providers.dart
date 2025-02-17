import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskfy/models/task.dart';
import 'package:taskfy/models/project.dart';
import 'package:taskfy/services/supabase_client.dart';

final taskListProvider = StreamProvider<List<Task>>((ref) {
  return supabaseClient.client
      .from('tasks')
      .stream(primaryKey: ['id'])
      .map((data) => data.map((json) => Task.fromJson(json)).toList());
});

final projectListProvider = StreamProvider<List<Project>>((ref) {
  return supabaseClient.client
      .from('projects')
      .stream(primaryKey: ['id'])
      .map((data) => data.map((json) => Project.fromJson(json)).toList());
});
