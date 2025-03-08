import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskfy/widgets/app_layout.dart';
import 'package:taskfy/widgets/stat_card.dart';
import 'package:taskfy/widgets/project_list.dart';
import 'package:taskfy/config/style_guide.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:taskfy/providers/project_providers.dart';
import 'package:taskfy/providers/report_providers.dart';
import 'package:taskfy/providers/auth_provider.dart';
import 'package:logging/logging.dart';

final _log = Logger('DashboardScreen');

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    _log.info('Building DashboardScreen');
    final authState = ref.watch(authProvider);
    final userEmail = authState.value?.email;
    _log.info('Current user email: $userEmail, role: ${authState.value?.role}');
    
    final projectsAsyncValue = ref.watch(projectListStreamProvider(userEmail));
    final projectStatsAsyncValue = ref.watch(projectStatsProvider);

    // Log any errors from async values
    if (projectsAsyncValue.hasError) {
      _log.severe('Error loading projects: ${projectsAsyncValue.error}', projectsAsyncValue.error, StackTrace.current);
    }
    
    if (projectStatsAsyncValue.hasError) {
      _log.severe('Error loading project stats: ${projectStatsAsyncValue.error}', projectStatsAsyncValue.error, StackTrace.current);
    }

    return AppLayout(
      title: AppLocalizations.of(context)!.appTitle,
      pageTitle: AppLocalizations.of(context)!.dashboardTitle,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final cardWidth = (constraints.maxWidth - (3 * StyleGuide.spacingMedium)) / 4;
                return Wrap(
                  spacing: StyleGuide.spacingMedium,
                  runSpacing: StyleGuide.spacingMedium,
                  children: [
                    SizedBox(
                      width: cardWidth,
                      child: projectsAsyncValue.when(
                        data: (projects) => StatCard(
                          title: AppLocalizations.of(context)!.projectsTitle,
                          value: projects.length.toString(),
                          icon: Icons.folder,
                          color: Colors.blue,
                        ),
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (_, __) => const StatCard(
                          title: 'Projects',
                          value: '-',
                          icon: Icons.folder,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: projectStatsAsyncValue.when(
                        data: (stats) => StatCard(
                          title: AppLocalizations.of(context)!.myTasksTitle,
                          value: stats['totalTasks']?.toString() ?? '0',
                          icon: Icons.task,
                          color: Colors.green,
                        ),
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (_, __) => const StatCard(
                          title: 'Tasks',
                          value: '-',
                          icon: Icons.task,
                          color: Colors.green,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: projectStatsAsyncValue.when(
                        data: (stats) => StatCard(
                          title: AppLocalizations.of(context)!.completionLabel,
                          value: '${stats['projectCompletionRate']?.toStringAsFixed(1)}%',
                          icon: Icons.check_circle,
                          color: Colors.orange,
                        ),
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (_, __) => const StatCard(
                          title: 'Completion',
                          value: '-',
                          icon: Icons.check_circle,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: projectStatsAsyncValue.when(
                        data: (stats) => StatCard(
                          title: AppLocalizations.of(context)!.pastDueTitle,
                          value: stats['overdueTasks']?.toString() ?? '0',
                          icon: Icons.warning,
                          color: Colors.red,
                        ),
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (_, __) => const StatCard(
                          title: 'Past Due',
                          value: '-',
                          icon: Icons.warning,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            SizedBox(height: StyleGuide.spacingLarge),
            Text(
              AppLocalizations.of(context)!.statusLabel,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: StyleGuide.spacingMedium),
            SizedBox(height: StyleGuide.spacingLarge),
            Text(
              AppLocalizations.of(context)!.projectListTitle,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: StyleGuide.spacingMedium),
            const SizedBox(
              height: 300,
              child: ProjectList(limit: 5),
            ),
          ],
        ),
      ),
    );
  }
}