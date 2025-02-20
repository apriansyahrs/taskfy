import 'package:flutter/material.dart';

class KanbanBoard<T> extends StatelessWidget {
  final List<T> items;
  final String Function(T) getTitle;
  final String Function(T) getStatus;
  final Function(T, String) onStatusChange;
  final List<String> statuses;
  final bool Function(T) canEdit;
  final Widget Function(T)? buildItemDetails;

  const KanbanBoard({
    super.key,
    required this.items,
    required this.getTitle,
    required this.getStatus,
    required this.onStatusChange,
    required this.statuses,
    required this.canEdit,
    this.buildItemDetails,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: statuses.map((status) {
                  final columnItems = items.where((item) => getStatus(item) == status).toList();
                  return KanbanColumn<T>(
                    status: status,
                    items: columnItems,
                    getTitle: getTitle,
                    onStatusChange: onStatusChange,
                    canEdit: canEdit,
                    width: constraints.maxWidth / statuses.length,
                    buildItemDetails: buildItemDetails,
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }
}

class KanbanColumn<T> extends StatelessWidget {
  final String status;
  final List<T> items;
  final String Function(T) getTitle;
  final Function(T, String) onStatusChange;
  final bool Function(T) canEdit;
  final double width;
  final Widget Function(T)? buildItemDetails;

  const KanbanColumn({
    super.key,
    required this.status,
    required this.items,
    required this.getTitle,
    required this.onStatusChange,
    required this.canEdit,
    required this.width,
    this.buildItemDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      margin: const EdgeInsets.all(8),
      child: Card(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                status,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return KanbanCard<T>(
                    item: item,
                    getTitle: getTitle,
                    onStatusChange: onStatusChange,
                    canEdit: canEdit(item),
                    buildItemDetails: buildItemDetails,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class KanbanCard<T> extends StatelessWidget {
  final T item;
  final String Function(T) getTitle;
  final Function(T, String) onStatusChange;
  final bool canEdit;
  final Widget Function(T)? buildItemDetails;

  const KanbanCard({
    super.key,
    required this.item,
    required this.getTitle,
    required this.onStatusChange,
    required this.canEdit,
    this.buildItemDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: ExpansionTile(
        title: Text(getTitle(item)),
        children: [
          if (buildItemDetails != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: buildItemDetails!(item),
            ),
          if (canEdit)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  PopupMenuButton<String>(
                    onSelected: (String newStatus) {
                      onStatusChange(item, newStatus);
                    },
                    itemBuilder: (BuildContext context) {
                      return ['not_started', 'in_progress', 'completed']
                          .map((String status) {
                        return PopupMenuItem<String>(
                          value: status,
                          child: Text(status),
                        );
                      }).toList();
                    },
                    child: const Chip(
                      label: Text('Change Status'),
                      avatar: Icon(Icons.edit),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

