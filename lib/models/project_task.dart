import 'dart:convert';
import 'package:logging/logging.dart';

class ProjectTask {
  static final log = Logger('ProjectTask');
  
  static List<Map<String, dynamic>> _parseAttachments(dynamic attachmentsData) {
    if (attachmentsData == null) return [];
    
    try {
      if (attachmentsData is List) {
        return attachmentsData.map((item) {
          if (item is Map) {
            return Map<String, dynamic>.from(item);
          } else {
            // Handle non-map items by creating a simple map with the item as a value
            return {'value': item.toString()};
          }
        }).toList();
      } else if (attachmentsData is String) {
        // If it's a String, try to parse it as JSON
        try {
          // Clean up the string if it has newlines or extra spaces
          String cleanedString = attachmentsData
              .replaceAll('\n', '')
              .replaceAll('\r', '')
              .trim();
          
          // Parse the JSON string to a List
          final parsed = jsonDecode(cleanedString);
          if (parsed is List) {
            return parsed.map((item) {
              if (item is Map) {
                return Map<String, dynamic>.from(item);
              } else {
                return {'value': item.toString()};
              }
            }).toList().cast<Map<String, dynamic>>();
          }
        } catch (e) {
          // If parsing fails, log and return an empty list
          log.warning('Error parsing attachments string: $e', e, StackTrace.current);
        }
      }
    } catch (e) {
      // If any error occurs during parsing, log and return an empty list
      log.warning('Error parsing attachments: $e', e, StackTrace.current);
    }
    
    return [];
  }
  
  final String id;
  final String projectId;
  final String title;
  final String description;
  final String status;
  final String priority;
  final DateTime? dueDate;
  final List<Map<String, dynamic>> attachments;
  final String createdBy;
  final String updatedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  static const List<String> validStatuses = [
    'not_started',
    'in_progress',
    'completed',
    'on_hold',
    'cancelled'
  ];

  static const List<String> validPriorities = [
    'low',
    'medium',
    'high',
    'urgent'
  ];

  ProjectTask({
    required this.id,
    required this.projectId,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.createdBy,
    required this.updatedBy,
    required this.createdAt,
    required this.updatedAt,
    this.dueDate,
    this.attachments = const [],
  }) : assert(validStatuses.contains(status), 'Invalid status value'),
       assert(validPriorities.contains(priority), 'Invalid priority value'),
       assert(title.isNotEmpty, 'Title cannot be empty'),
       assert(projectId.isNotEmpty, 'Project ID cannot be empty');

  factory ProjectTask.fromJson(Map<String, dynamic> json) {
    return ProjectTask(
      id: json['id'] as String? ?? '',
      projectId: json['project_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      status: json['status'] as String? ?? 'not_started',
      priority: json['priority'] as String? ?? 'low',
      dueDate: json['due_date'] != null ? DateTime.parse(json['due_date'] as String) : null,
      attachments: _parseAttachments(json['attachments']),
      createdBy: json['created_by'] as String? ?? '',
      updatedBy: json['updated_by'] as String? ?? '',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'project_id': projectId,
      'title': title,
      'description': description,
      'status': status,
      'priority': priority,
      'due_date': dueDate?.toIso8601String(),
      'attachments': attachments,
      'created_by': createdBy,
      'updated_by': updatedBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ProjectTask copyWith({
    String? id,
    String? projectId,
    String? title,
    String? description,
    String? status,
    String? priority,
    DateTime? dueDate,
    List<Map<String, dynamic>>? attachments,
    String? createdBy,
    String? updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProjectTask(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      attachments: attachments ?? this.attachments,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}