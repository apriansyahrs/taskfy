import 'package:flutter/material.dart';
import 'package:taskfy/config/style_guide.dart';

class DataTableWidget extends StatelessWidget {
  final List<DataColumn> columns;
  final List<DataRow> rows;

  const DataTableWidget({
    super.key,
    required this.columns,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < StyleGuide.breakpointMobile;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? StyleGuide.paddingSmall : StyleGuide.paddingMedium),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            horizontalMargin: isSmallScreen ? StyleGuide.paddingSmall : StyleGuide.paddingLarge,
            columnSpacing: isSmallScreen ? StyleGuide.spacingLarge : StyleGuide.spacingLarge * 2,
            headingRowHeight: isSmallScreen ? 48.0 : 56.0,
            dataRowMinHeight: isSmallScreen ? 48.0 : 56.0,
            columns: columns,
            rows: rows,
          ),
        ),
      ),
    );
  }
}

