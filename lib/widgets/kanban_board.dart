import 'package:flutter/material.dart';
import 'package:taskfy/config/theme_config.dart';

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
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: statuses.map((status) {
              final columnItems = items.where((item) => getStatus(item) == status).toList();
              return _KanbanColumn<T>(
                status: status,
                items: columnItems,
                getTitle: getTitle,
                onStatusChange: onStatusChange,
                canEdit: canEdit,
                buildItemDetails: buildItemDetails,
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _KanbanColumn<T> extends StatelessWidget {
  final String status;
  final List<T> items;
  final String Function(T) getTitle;
  final Function(T, String) onStatusChange;
  final bool Function(T) canEdit;
  final Widget Function(T)? buildItemDetails;

  const _KanbanColumn({
    required this.status,
    required this.items,
    required this.getTitle,
    required this.onStatusChange,
    required this.canEdit,
    this.buildItemDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  status,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    items.length.toString(),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return _KanbanCard<T>(
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
    );
  }
}

class _KanbanCard<T> extends StatelessWidget {
  final T item;
  final String Function(T) getTitle;
  final Function(T, String) onStatusChange;
  final bool canEdit;
  final Widget Function(T)? buildItemDetails;

  const _KanbanCard({
    required this.item,
    required this.getTitle,
    required this.onStatusChange,
    required this.canEdit,
    this.buildItemDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            getTitle(item),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
          children: [
            if (buildItemDetails != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: buildItemDetails!(item),
              ),
            if (canEdit)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildStatusButton(context),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusButton(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (newStatus) => onStatusChange(item, newStatus),
      itemBuilder: (context) => ['not_started', 'in_progress', 'completed']
          .map((status) => PopupMenuItem(
                value: status,
                child: Text(status),
              ))
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.edit,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Change Status',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

