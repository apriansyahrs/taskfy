import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskfy/services/supabase_client.dart';
import 'package:taskfy/models/project.dart';

final projectStatsProvider = StreamProvider((ref) {
  return supabaseClient.client
      .from('projects')
      .stream(primaryKey: ['id'])
      .map((data) => data.map((json) => Project.fromJson(json)).toList());
});

class ProjectChart extends ConsumerWidget {
  const ProjectChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectStatsAsyncValue = ref.watch(projectStatsProvider);

    return SizedBox(
      height: 200,
      child: projectStatsAsyncValue.when(
        data: (projects) {
          if (projects.isEmpty) {
            return const Center(child: Text('No projects data available'));
          }

          final Map<String, int> statusCount = {
            'not_started': 0,
            'in_progress': 0,
            'completed': 0,
          };

          for (var project in projects) {
            final status = project.status;
            statusCount[status] = (statusCount[status] ?? 0) + 1;
          }

          return Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: statusCount.entries.map((entry) {
                    final percentage = (entry.value / projects.length) * 100;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: _getColorForStatus(entry.key),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: Text(
                              _formatStatus(entry.key),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: entry.value / projects.length,
                                backgroundColor: Colors.grey.withOpacity(0.2),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _getColorForStatus(entry.key),
                                ),
                                minHeight: 8,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 60,
                            child: Text(
                              ' ${percentage.toStringAsFixed(1)}%',
                              textAlign: TextAlign.end,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Color _getColorForStatus(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'in_progress':
        return Colors.blue;
      case 'not_started':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatStatus(String status) {
    return status.split('_').map((word) => 
      word[0].toUpperCase() + word.substring(1)
    ).join(' ');
  }
}

