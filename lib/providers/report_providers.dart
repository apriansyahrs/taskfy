import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:postgrest/src/types.dart';
import 'package:taskfy/services/service_locator.dart';
import 'package:taskfy/services/supabase_client.dart';

final projectStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final supabase = getIt<SupabaseClientWrapper>().client;
  final projects = await supabase.from('projects').select();
  final tasks = await supabase.from('tasks').select();

  final projectsData = projects.data as List<dynamic>? ?? [];
  final tasksData = tasks.data as List<dynamic>? ?? [];

  final totalProjects = projectsData.length;
  final completedProjects = projectsData.where((p) => p['status'] == 'completed').length;
  final totalTasks = tasksData.length;
  final completedTasks = tasksData.where((t) => t['status'] == 'completed').length;

  final projectCompletionRate = totalProjects > 0 ? (completedProjects / totalProjects) * 100 : 0;
  final taskCompletionRate = totalTasks > 0 ? (completedTasks / totalTasks) * 100 : 0;

  return {
    'projectCompletionRate': projectCompletionRate,
    'taskCompletionRate': taskCompletionRate,
    'averageProjectDuration': _calculateAverageProjectDuration(projectsData),
    'teamUtilization': _calculateTeamUtilization(projectsData, tasksData),
  };
});

extension on PostgrestList {
  get data => null;
}

final teamPerformanceProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final supabase = getIt<SupabaseClientWrapper>().client;
  final tasks = await supabase.from('tasks').select();
  final users = await supabase.from('users').select();

  final tasksData = tasks.data as List<dynamic>? ?? [];
  final usersData = users.data as List<dynamic>? ?? [];

  final performance = <Map<String, dynamic>>[];

  for (final user in usersData) {
    final userTasks = tasksData.where((t) => (t['assigned_to'] as List?)?.contains(user['email']) ?? false).toList();
    final completedTasks = userTasks.where((t) => t['status'] == 'completed').length;
    final onTimeTasks = userTasks.where((t) => 
      t['status'] == 'completed' && 
      DateTime.parse(t['deadline']).isAfter(DateTime.now())
    ).length;

    performance.add({
      'name': user['email'] ?? 'Unknown',
      'tasksCompleted': completedTasks,
      'onTimeCompletion': userTasks.isNotEmpty ? (onTimeTasks / userTasks.length) * 100 : 0,
      'averageDuration': _calculateAverageTaskDuration(userTasks),
      'performanceScore': _calculatePerformanceScore(completedTasks, onTimeTasks, userTasks.length),
    });
  }

  return performance;
});

double _calculateAverageProjectDuration(List<dynamic> projects) {
  if (projects.isEmpty) return 0;
  final totalDuration = projects.fold(0, (sum, project) {
    final start = DateTime.tryParse(project['start_date'] ?? '') ?? DateTime.now();
    final end = DateTime.tryParse(project['end_date'] ?? '') ?? DateTime.now();
    return sum + end.difference(start).inDays;
  });
  return totalDuration / projects.length;
}

double _calculateTeamUtilization(List<dynamic> projects, List<dynamic> tasks) {
  if (projects.isEmpty || tasks.isEmpty) return 0;
  final totalAssignments = tasks.fold(0, (sum, task) => sum + ((task['assigned_to'] as List?)?.length ?? 0));
  final totalPossibleAssignments = projects.length * 3; // Assuming max 3 team members per project
  return (totalAssignments / totalPossibleAssignments) * 100;
}

double _calculateAverageTaskDuration(List<dynamic> tasks) {
  if (tasks.isEmpty) return 0;
  final totalDuration = tasks.fold(0, (sum, task) {
    final deadline = DateTime.tryParse(task['deadline'] ?? '') ?? DateTime.now();
    final now = DateTime.now();
    return sum + (task['status'] == 'completed' ? deadline.difference(now).inDays : 0);
  });
  return totalDuration / tasks.length;
}

int _calculatePerformanceScore(int completed, int onTime, int total) {
  if (total == 0) return 0;
  final completionRate = completed / total;
  final onTimeRate = onTime / total;
  return ((completionRate * 0.6 + onTimeRate * 0.4) * 100).round();
}

