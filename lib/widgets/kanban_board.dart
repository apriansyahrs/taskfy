import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class KanbanBoard<T> extends StatelessWidget {
  final List<T> items;
  final String Function(T) getTitle;
  final String Function(T) getStatus;
  final Function(T, String) onStatusChange;
  final List<String> statuses;
  final bool Function(T) canEdit;
  final Widget Function(T)? buildItemDetails;
  final Map<String, String>? statusLabels;
  final Map<String, Color>? statusColors;

  const KanbanBoard({
    super.key,
    required this.items,
    required this.getTitle,
    required this.getStatus,
    required this.onStatusChange,
    required this.statuses,
    required this.canEdit,
    this.buildItemDetails,
    this.statusLabels,
    this.statusColors,
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
                statusLabel: statusLabels?[status] ?? _getDefaultStatusLabel(context, status),
                statusColor: statusColors?[status] ?? _getDefaultStatusColor(status),
                items: columnItems,
                getTitle: getTitle,
                onStatusChange: onStatusChange,
                canEdit: canEdit,
                buildItemDetails: buildItemDetails,
                allStatuses: statuses,
                statusLabels: statusLabels,
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  String _getDefaultStatusLabel(BuildContext context, String status) {
    final l10n = AppLocalizations.of(context);
    switch (status) {
      case 'not_started':
        return l10n?.statusNotStarted ?? 'Not Started';
      case 'in_progress':
        return l10n?.inProgressTitle ?? 'In Progress';
      case 'completed':
        return l10n?.completedTitle ?? 'Completed';
      case 'on_hold':
        return l10n?.statusOnHold ?? 'On Hold';
      case 'cancelled':
        return l10n?.statusCancelled ?? 'Cancelled';
      default:
        return status;
    }
  }

  Color _getDefaultStatusColor(String status) {
    switch (status) {
      case 'not_started':
        return Colors.grey.shade200;
      case 'in_progress':
        return Colors.blue.shade100;
      case 'completed':
        return Colors.green.shade100;
      case 'on_hold':
        return Colors.orange.shade100;
      case 'cancelled':
        return Colors.red.shade100;
      default:
        return Colors.grey.shade100;
    }
  }
}

class _KanbanColumn<T> extends StatelessWidget {
  final String status;
  final String statusLabel;
  final Color statusColor;
  final List<T> items;
  final String Function(T) getTitle;
  final Function(T, String) onStatusChange;
  final bool Function(T) canEdit;
  final Widget Function(T)? buildItemDetails;
  final List<String> allStatuses;
  final Map<String, String>? statusLabels;

  const _KanbanColumn({
    required this.status,
    required this.statusLabel,
    required this.statusColor,
    required this.items,
    required this.getTitle,
    required this.onStatusChange,
    required this.canEdit,
    required this.allStatuses,
    this.statusLabels,
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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.3),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  statusLabel,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
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
            child: items.isEmpty
                ? Center(
                    child: Text(
                      'No items',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                    ),
                  )
                : ListView.builder(
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
                        allStatuses: allStatuses,
                        statusLabels: statusLabels,
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
  final List<String> allStatuses;
  final Map<String, String>? statusLabels;

  const _KanbanCard({
    required this.item,
    required this.getTitle,
    required this.onStatusChange,
    required this.canEdit,
    required this.allStatuses,
    this.statusLabels,
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
      itemBuilder: (context) => allStatuses
          .map((status) => PopupMenuItem(
                value: status,
                child: Text(statusLabels?[status] ?? _getStatusLabel(context, status)),
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
              Icons.swap_horiz,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Move',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusLabel(BuildContext context, String status) {
    final l10n = AppLocalizations.of(context);
    switch (status) {
      case 'not_started':
        return l10n?.statusNotStarted ?? 'Not Started';
      case 'in_progress':
        return l10n?.inProgressTitle ?? 'In Progress';
      case 'completed':
        return l10n?.completedTitle ?? 'Completed';
      case 'on_hold':
        return l10n?.statusOnHold ?? 'On Hold';
      case 'cancelled':
        return l10n?.statusCancelled ?? 'Cancelled';
      default:
        return status;
    }
  }
}

