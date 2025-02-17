import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskfy/widgets/app_layout.dart';
import 'package:taskfy/widgets/project_chart.dart';

class ReportScreen extends ConsumerWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOverviewStats(),
          const SizedBox(height: 32),
          _buildCharts(),
          const SizedBox(height: 32),
          _buildPerformanceTable(),
        ],
      ),
    );
  }

  Widget _buildOverviewStats() {
    return GridView.count(
      crossAxisCount: 4,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      children: [
        _buildStatCard(
          'Project Completion Rate',
          '85%',
          Icons.trending_up,
          Colors.green,
          '+5% vs last month',
        ),
        _buildStatCard(
          'Task Completion Rate',
          '92%',
          Icons.check_circle,
          Colors.blue,
          '+3% vs last month',
        ),
        _buildStatCard(
          'Average Project Duration',
          '45 days',
          Icons.timer,
          Colors.orange,
          '-2 days vs last month',
        ),
        _buildStatCard(
          'Team Utilization',
          '78%',
          Icons.groups,
          Colors.purple,
          '+8% vs last month',
        ),
      ],
    );
  }

  Widget _buildCharts() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Card(
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
                    child: ProjectChart(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceTable() {
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
                rows: [
                  _buildPerformanceRow('John Doe', 45, 92, 2.5, 95),
                  _buildPerformanceRow('Jane Smith', 38, 88, 3.0, 90),
                  _buildPerformanceRow('Bob Johnson', 42, 95, 2.3, 97),
                  _buildPerformanceRow('Alice Brown', 36, 85, 3.2, 88),
                ],
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
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
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
    );
  }

  DataRow _buildPerformanceRow(
    String name,
    int tasksCompleted,
    int onTimePercentage,
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
        DataCell(Text('$onTimePercentage%')),
        DataCell(Text('$avgDuration days')),
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

