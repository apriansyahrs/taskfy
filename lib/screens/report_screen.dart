import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskfy/widgets/app_layout.dart';
import 'package:taskfy/widgets/project_chart.dart';
import 'package:taskfy/providers/task_providers.dart';
import 'package:taskfy/providers/project_providers.dart';
import 'package:taskfy/models/task.dart';
import 'package:taskfy/models/project.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class ReportScreen extends ConsumerWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsyncValue = ref.watch(taskListProvider(null));
    final projectsAsyncValue = ref.watch(projectListProvider(null));

    return AppLayout(
      title: 'Task Manager',
      pageTitle: 'Reports',
      actions: [
        ElevatedButton.icon(
          icon: Icon(Icons.download),
          label: Text('Export'),
          onPressed: () {
            // Implement export functionality
          },
        ),
      ],
      child: tasksAsyncValue.when(
        data: (tasks) => projectsAsyncValue.when(
          data: (projects) => _buildReportContent(context, tasks, projects),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildReportContent(BuildContext context, List<Task> tasks, List<Project> projects) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverviewStats(tasks, projects),
            const SizedBox(height: 32),
            _buildProjectProgress(context, projects),
            const SizedBox(height: 32),
            _buildTaskCompletionChart(tasks),
            const SizedBox(height: 32),
            _buildPerformanceTable(tasks, projects),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewStats(List<Task> tasks, List<Project> projects) {
    final completedTasks = tasks.where((task) => task.status == 'completed').length;
    final completedProjects = projects.where((project) => project.status == 'completed').length;
    final ongoingProjects = projects.where((project) => project.status == 'in_progress').length;
    final overdueTasks = tasks.where((task) => task.deadline.isBefore(DateTime.now()) && task.status != 'completed').length;

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _buildStatCard('Total Tasks', tasks.length.toString(), Icons.task_alt, Colors.blue),
        _buildStatCard('Completed Tasks', completedTasks.toString(), Icons.check_circle, Colors.green),
        _buildStatCard('Ongoing Projects', ongoingProjects.toString(), Icons.work, Colors.orange),
        _buildStatCard('Completed Projects', completedProjects.toString(), Icons.done_all, Colors.purple),
        _buildStatCard('Overdue Tasks', overdueTasks.toString(), Icons.warning, Colors.red),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Icon(icon, color: color),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectProgress(BuildContext context, List<Project> projects) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Project Progress',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: ProjectChart(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCompletionChart(List<Task> tasks) {
    final taskStatusCounts = {
      'Not Started': tasks.where((task) => task.status == 'not_started').length,
      'In Progress': tasks.where((task) => task.status == 'in_progress').length,
      'Completed': tasks.where((task) => task.status == 'completed').length,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Task Completion Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: taskStatusCounts.entries.map((entry) {
                    return PieChartSectionData(
                      color: _getColorForStatus(entry.key),
                      value: entry.value.toDouble(),
                      title: '${entry.key}\n${entry.value}',
                      radius: 100,
                      titleStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                  sectionsSpace: 0,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceTable(List<Task> tasks, List<Project> projects) {
    final teamPerformance = _calculateTeamPerformance(tasks, projects);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Team Performance',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Team Member')),
                  DataColumn(label: Text('Tasks Completed')),
                  DataColumn(label: Text('Projects Completed')),
                  DataColumn(label: Text('On-Time Completion')),
                  DataColumn(label: Text('Performance Score')),
                ],
                rows: teamPerformance.entries.map((entry) {
                  final performance = entry.value;
                  return DataRow(
                    cells: [
                      DataCell(Text(entry.key)),
                      DataCell(Text(performance['tasksCompleted'].toString())),
                      DataCell(Text(performance['projectsCompleted'].toString())),
                      DataCell(Text('${performance['onTimeCompletion']}%')),
                      DataCell(
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getScoreColor(performance['performanceScore']).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${performance['performanceScore']}',
                            style: TextStyle(
                              color: _getScoreColor(performance['performanceScore']),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorForStatus(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'in progress':
        return Colors.blue;
      case 'not started':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getScoreColor(int score) {
    if (score >= 90) return Colors.green;
    if (score >= 80) return Colors.blue;
    if (score >= 70) return Colors.orange;
    return Colors.red;
  }

  Map<String, Map<String, dynamic>> _calculateTeamPerformance(List<Task> tasks, List<Project> projects) {
    final teamPerformance = <String, Map<String, dynamic>>{};

    for (final task in tasks) {
      for (final member in task.assignedTo) {
        if (!teamPerformance.containsKey(member)) {
          teamPerformance[member] = {
            'tasksCompleted': 0,
            'projectsCompleted': 0,
            'onTimeCompletion': 0,
            'totalTasks': 0,
          };
        }

        teamPerformance[member]!['totalTasks'] = (teamPerformance[member]!['totalTasks'] as int) + 1;

        if (task.status == 'completed') {
          teamPerformance[member]!['tasksCompleted'] = (teamPerformance[member]!['tasksCompleted'] as int) + 1;
          if (task.deadline.isAfter(DateTime.now())) {
            teamPerformance[member]!['onTimeCompletion'] = (teamPerformance[member]!['onTimeCompletion'] as int) + 1;
          }
        }
      }
    }

    for (final project in projects) {
      for (final member in project.teamMembers) {
        if (!teamPerformance.containsKey(member)) {
          teamPerformance[member] = {
            'tasksCompleted': 0,
            'projectsCompleted': 0,
            'onTimeCompletion': 0,
            'totalTasks': 0,
          };
        }

        if (project.status == 'completed') {
          teamPerformance[member]!['projectsCompleted'] = (teamPerformance[member]!['projectsCompleted'] as int) + 1;
        }
      }
    }

    for (final member in teamPerformance.keys) {
      final performance = teamPerformance[member]!;
      final totalTasks = performance['totalTasks'] as int;
      final tasksCompleted = performance['tasksCompleted'] as int;
      final projectsCompleted = performance['projectsCompleted'] as int;
      final onTimeCompletion = performance['onTimeCompletion'] as int;

      final onTimePercentage = totalTasks > 0 ? (onTimeCompletion / totalTasks * 100).round() : 0;
      final performanceScore = ((tasksCompleted * 0.4 + projectsCompleted * 0.4 + onTimePercentage * 0.2) * 100).round();

      performance['onTimeCompletion'] = onTimePercentage;
      performance['performanceScore'] = performanceScore;
    }

    return teamPerformance;
  }
}

