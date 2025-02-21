import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskfy/widgets/app_layout.dart';
import 'package:taskfy/widgets/stat_card.dart';
import 'package:taskfy/widgets/project_chart.dart';
import 'package:taskfy/widgets/project_list.dart';
import 'package:taskfy/config/style_guide.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppLayout(
      title: 'Task Manager',
      pageTitle: 'Dashboard',
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
                      child: StatCard(
                        title: 'Total Projects',
                        value: '12',
                        icon: Icons.folder,
                        color: Colors.blue,
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: StatCard(
                        title: 'Active Tasks',
                        value: '45',
                        icon: Icons.task,
                        color: Colors.green,
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: StatCard(
                        title: 'Completed Tasks',
                        value: '23',
                        icon: Icons.check_circle,
                        color: Colors.orange,
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: StatCard(
                        title: 'Overdue Tasks',
                        value: '5',
                        icon: Icons.warning,
                        color: Colors.red,
                      ),
                    ),
                  ],
                );
              },
            ),
            SizedBox(height: StyleGuide.spacingLarge),
            Text(
              'Project Status',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: StyleGuide.spacingMedium),
            const ProjectChart(),
            SizedBox(height: StyleGuide.spacingLarge),
            Text(
              'Recent Projects',
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