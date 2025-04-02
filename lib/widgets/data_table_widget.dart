import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:taskfy/config/style_guide.dart';
import 'package:taskfy/config/theme_config.dart';

class DataTableWidget extends StatelessWidget {
  final List<DataColumn> columns;
  final List<DataRow> rows;
  final bool showBorder;
  final String? emptyMessage;

  const DataTableWidget({
    super.key,
    required this.columns,
    required this.rows,
    this.showBorder = true,
    this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < StyleGuide.breakpointMobile;

    if (rows.isEmpty && emptyMessage != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(StyleGuide.paddingLarge),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.table_rows,
                size: 48,
                color: ThemeConfig.labelTextColor.withOpacity(0.5),
              ),
              SizedBox(height: StyleGuide.spacingMedium),
              Text(
                emptyMessage!,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ).animate().fade(duration: 400.ms);
    }

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(StyleGuide.borderRadiusLarge),
        side: showBorder ? const BorderSide(color: ThemeConfig.border) : BorderSide.none,
      ),
      child: Padding(
        padding: EdgeInsets.all(
          isSmallScreen ? StyleGuide.paddingSmall : StyleGuide.paddingMedium
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Theme(
            // Override theme for DataTable to match our style guide
            data: Theme.of(context).copyWith(
              dividerColor: ThemeConfig.dividerColor,
              dataTableTheme: DataTableThemeData(
                headingTextStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: ThemeConfig.textPrimary,
                ),
                dataTextStyle: const TextStyle(
                  color: ThemeConfig.titleTextColor,
                ),
                headingRowHeight: isSmallScreen ? 48.0 : 56.0,
                dataRowMinHeight: isSmallScreen ? 48.0 : 56.0,
                dataRowMaxHeight: isSmallScreen ? 56.0 : 72.0,
                columnSpacing: isSmallScreen 
                    ? StyleGuide.spacingLarge 
                    : StyleGuide.spacingLarge * 1.5,
                horizontalMargin: isSmallScreen 
                    ? StyleGuide.paddingSmall 
                    : StyleGuide.paddingMedium,
                dividerThickness: 1,
              ),
            ),
            child: DataTable(
              columns: columns,
              rows: rows,
              border: TableBorder(
                horizontalInside: BorderSide(
                  color: ThemeConfig.dividerColor.withOpacity(0.5),
                  width: 1,
                ),
              ),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0);
  }
}

