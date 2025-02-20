import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskfy/widgets/app_layout.dart';
import 'package:taskfy/widgets/project_chart.dart' as chart;
import 'package:taskfy/providers/report_providers.dart';

class ReportScreen extends ConsumerWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectStats = ref.watch(projectStatsProvider);
    final teamPerformance = ref.watch(teamPerformanceProvider);

    return AppLayout(
      title: 'Task Manager',
      pageTitle: 'Reports',
      actions: [
        DropdownButton<String>(
          value: 'This Month',
          items: [
            'This Week',
            'This Month',
            'This Quarter',
            'This Year',
          ].map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (_) {},
        ),
        SizedBox(width: 16),
        ElevatedButton.icon(
          icon: Icon(Icons.download),
          label: Text('Export'),
          onPressed: () {},
        ),
      ],
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              projectStats.when(
                data: (stats) => _buildOverviewStats(stats),
                loading: () => CircularProgressIndicator(),
                error: (err, stack) => Text('Error loading project stats: $err'),
              ),
              const SizedBox(height: 32),
              _buildCharts(),
              const SizedBox(height: 32),
              teamPerformance.when(
                data: (performance) => _buildPerformanceTable(performance),
                loading: () => CircularProgressIndicator(),
                error: (err, stack) => Text('Error loading team performance: $err'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewStats(Map<String, dynamic> stats) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildStatCard(
              'Project Completion Rate',
              '${stats['projectCompletionRate'].toStringAsFixed(1)}%',
              Icons.trending_up,
              Colors.green,
              '',
              constraints,
            ),
            _buildStatCard(
              'Task Completion Rate',
              '${stats['taskCompletionRate'].toStringAsFixed(1)}%',
              Icons.check_circle,
              Colors.blue,
              '',
              constraints,
            ),
            _buildStatCard(
              'Average Project Duration',
              '${stats['averageProjectDuration'].toStringAsFixed(1)} days',
              Icons.timer,
              Colors.orange,
              '',
              constraints,
            ),
            _buildStatCard(
              'Team Utilization',
              '${stats['teamUtilization'].toStringAsFixed(1)}%',
              Icons.groups,
              Colors.purple,
              '',
              constraints,
            ),
          ],
        );
      },
    );
  }

  Widget _buildCharts() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Project Progress',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: chart.ProjectChart(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceTable(List<Map<String, dynamic>> performance) {
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
                  DataColumn(label: Text('On-Time Completion')),
                  DataColumn(label: Text('Average Duration')),
                  DataColumn(label: Text('Performance Score')),
                ],
                rows: performance.map((p) => _buildPerformanceRow(
                  p['name'],
                  p['tasksCompleted'],
                  p['onTimeCompletion'],
                  p['averageDuration'],
                  p['performanceScore'],
                )).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String trend,
    BoxConstraints constraints,
  ) {
    final cardWidth = (constraints.maxWidth - (3 * 16)) / 4;
    return SizedBox(
      width: cardWidth,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
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
              const SizedBox(height: 4),
              Text(
                trend,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  DataRow _buildPerformanceRow(
    String name,
    int tasksCompleted,
    double onTimePercentage,
    double avgDuration,
    int performanceScore,
  ) {
    return DataRow(
      cells: [
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 16,
                child: Text(name[0]),
              ),
              SizedBox(width: 8),
              Text(name),
            ],
          ),
        ),
        DataCell(Text('$tasksCompleted')),
        DataCell(Text('${onTimePercentage.toStringAsFixed(1)}%')),
        DataCell(Text('${avgDuration.toStringAsFixed(1)} days')),
        DataCell(
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getScoreColor(performanceScore).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$performanceScore',
              style: TextStyle(
                color: _getScoreColor(performanceScore),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 90) return Colors.green;
    if (score >= 80) return Colors.blue;
    if (score >= 70) return Colors.orange;
    return Colors.red;
  }
}

