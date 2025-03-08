import 'dart:convert';
import 'package:logging/logging.dart';

class Routine {
  static final log = Logger('Routine');

  static List<dynamic> _parseAttachments(dynamic attachmentsData) {
    if (attachmentsData == null) return [];

    try {
      if (attachmentsData is List) {
        return attachmentsData;
      } else if (attachmentsData is String) {
        // If it's a String, try to parse it as JSON
        try {
          // Clean up the string if it has newlines or extra spaces
          String cleanedString =
              attachmentsData.replaceAll('\n', '').replaceAll('\r', '').trim();

          // Parse the JSON string to a List
          final parsed = jsonDecode(cleanedString);
          if (parsed is List) {
            return parsed;
          }
        } catch (e) {
          // If parsing fails, log and return an empty list
          log.warning(
              'Error parsing attachments string: $e', e, StackTrace.current);
        }
      }
    } catch (e) {
      // If any error occurs during parsing, log and return an empty list
      log.warning('Error parsing attachments: $e', e, StackTrace.current);
    }

    return [];
  }

  final String? id;
  final String title;
  final String description;
  final String status;
  final String priority;
  final List<String> assignees;
  final DateTime dueDate;
  final List<dynamic> attachments;
  final String createdBy;
  final String updatedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  Routine({
    this.id,
    required this.title,
    required this.description,
    this.status = 'not_started',
    required this.priority,
    required this.assignees,
    required this.dueDate,
    this.attachments = const [],
    required this.createdBy,
    required this.updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : assert(assignees.length <= 3,
            'A routine can be assigned to a maximum of 3 people'),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory Routine.fromJson(Map<String, dynamic> json) {
    // Safely parse assignees field
    List<String> assignees = [];
    try {
      final assigneesRaw = json['assignees'];
      if (assigneesRaw is List) {
        // If it's already a List, convert each element to String
        assignees = assigneesRaw.map((e) => e.toString()).toList();
      } else if (assigneesRaw is String) {
        // If it's a String, try to parse it as JSON
        try {
          // Clean up the string if it has newlines or extra spaces
          String cleanedString =
              assigneesRaw.replaceAll('\n', '').replaceAll('\r', '').trim();

          // Parse the JSON string to a List
          final parsed = jsonDecode(cleanedString);
          if (parsed is List) {
            assignees = parsed.map((e) => e.toString()).toList();
          } else {
            // If parsing succeeds but result is not a List
            assignees = [assigneesRaw];
          }
        } catch (e) {
          // If parsing fails, just use the string as a single member
          log.warning(
              'Error parsing assignees string: $e', e, StackTrace.current);
          assignees = [assigneesRaw];
        }
      }
    } catch (e) {
      log.warning('Error parsing assignees: $e', e, StackTrace.current);
      // Continue with empty list if parsing fails
    }

    return Routine(
      id: json['id'] as String?,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      status: json['status'] as String? ?? 'not_started',
      priority: json['priority'] as String? ?? 'low',
      assignees: assignees,
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String)
          : DateTime.now(),
      attachments: _parseAttachments(json['attachments']),
      createdBy: json['created_by'] as String? ?? '',
      updatedBy: json['updated_by'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status,
      'priority': priority,
      'assignees': assignees,
      'due_date': dueDate.toIso8601String(),
      'attachments': attachments,
      'created_by': createdBy,
      'updated_by': updatedBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Routine copyWith({
    String? id,
    String? title,
    String? description,
    String? status,
    String? priority,
    List<String>? assignees,
    DateTime? dueDate,
    List<dynamic>? attachments,
    String? createdBy,
    String? updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Routine(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      assignees: assignees ?? this.assignees,
      dueDate: dueDate ?? this.dueDate,
      attachments: attachments ?? this.attachments,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
