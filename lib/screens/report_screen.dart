import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskfy/config/style_guide.dart';
import 'package:taskfy/widgets/app_layout.dart';
import 'package:taskfy/widgets/stat_card.dart';
import 'package:taskfy/widgets/project_chart.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ReportScreen extends ConsumerWidget {
  const ReportScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppLayout(
      title: AppLocalizations.of(context)!.appTitle,
      pageTitle: AppLocalizations.of(context)!.reportsTitle,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final cardWidth = (constraints.maxWidth - StyleGuide.spacingMedium) / 2;
                return Wrap(
                  spacing: StyleGuide.spacingMedium,
                  runSpacing: StyleGuide.spacingMedium,
                  children: [
                    SizedBox(
                      width: cardWidth,
                      child: StatCard(
                        title: AppLocalizations.of(context)!.reportsTitle,
                        value: '8',
                        icon: Icons.assessment,
                        color: Colors.purple,
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: StatCard(
                        title: AppLocalizations.of(context)!.todayRoutinesTitle,
                        value: '3',
                        icon: Icons.today,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                );
              },
            ),
            SizedBox(height: StyleGuide.spacingLarge),
            Card(
              child: Padding(
                padding: EdgeInsets.all(StyleGuide.paddingLarge),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.projectsTitle,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    SizedBox(height: StyleGuide.spacingMedium),
                    SizedBox(
                      height: 300,
                      child: const ProjectChart(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

