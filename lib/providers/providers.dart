import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskfy/models/project.dart';
import 'package:taskfy/models/routine.dart';
import 'package:taskfy/services/service_locator.dart';
import 'package:taskfy/services/supabase_client.dart';

final routineListProvider = StreamProvider<List<Routine>>((ref) {
  return getIt<SupabaseClientWrapper>().client
      .from('routines')
      .stream(primaryKey: ['id'])
      .map((data) => data.map((json) => Routine.fromJson(json)).toList());
});

final projectListProvider = StreamProvider<List<Project>>((ref) {
  return getIt<SupabaseClientWrapper>().client
      .from('projects')
      .stream(primaryKey: ['id'])
      .map((data) => data.map((json) => Project.fromJson(json)).toList());
});

