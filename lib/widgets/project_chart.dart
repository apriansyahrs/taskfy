import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskfy/models/project.dart';
import 'package:taskfy/services/service_locator.dart';
import 'package:taskfy/services/supabase_client.dart';
import 'package:taskfy/config/style_guide.dart';
import 'package:taskfy/config/theme_config.dart';
// import 'package:taskfy/providers/project_progress_provider.dart';

final projectStatsProvider = StreamProvider((ref) {
  return getIt<SupabaseClientWrapper>().client
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
            return Center(
              child: Text(
                'No projects data available',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            );
          }

          final Map<String, int> statusCount = {
            'not_started': 0,
            'in_progress': 0,
            'on_hold': 0,
            'completed': 0,
          };

          for (var project in projects) {
            statusCount[project.status] = (statusCount[project.status] ?? 0) + 1;
          }

          return Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: statusCount.entries.map((entry) {
                    final percentage = (entry.value / projects.length) * 100;
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: StyleGuide.paddingSmall),
                      child: Row(
                        children: [
                          Container(
                            width: StyleGuide.spacingMedium,
                            height: StyleGuide.spacingMedium,
                            decoration: BoxDecoration(
                              color: _getColorForStatus(entry.key),
                              borderRadius: BorderRadius.circular(StyleGuide.borderRadiusSmall),
                            ),
                          ),
                          SizedBox(width: StyleGuide.spacingSmall),
                          Expanded(
                            flex: 2,
                            child: Text(
                              _formatStatus(entry.key),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                          SizedBox(width: StyleGuide.spacingMedium),
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(StyleGuide.borderRadiusSmall),
                                  child: LinearProgressIndicator(
                                    value: entry.value / projects.length,
                                    backgroundColor: ThemeConfig.dividerColor,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      _getColorForStatus(entry.key),
                                    ),
                                    minHeight: 8,
                                  ),
                                ),
                                Text(
                                  '${percentage.toStringAsFixed(1)}%',
                                  style: StyleGuide.smallLabelStyle,
                                ),
                              ],
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
        error: (error, stack) => Center(
          child: Text(
            'Error: $error',
            style: StyleGuide.errorTextStyle(context),
          ),
        ),
      ),
    );
  }

  Color _getColorForStatus(String status) {
    switch (status) {
      case 'not_started':
        return ThemeConfig.textSecondary;
      case 'in_progress':
        return ThemeConfig.infoColor;
      case 'on_hold':
        return ThemeConfig.warningColor;
      case 'completed':
        return ThemeConfig.successColor;
      default:
        return ThemeConfig.textSecondary;
    }
  }

  String _formatStatus(String status) {
    return status.split('_').map((word) => word[0].toUpperCase() + word.substring(1)).join(' ');
  }
}

