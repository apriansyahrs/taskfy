import 'package:logging/logging.dart';
import 'dart:convert';

class Project {
  final String id;
  final String name;
  final String description;
  final String status;
  final String priority;
  final List<String> teamMembers;
  final DateTime startDate;
  final DateTime endDate;
  final double completion;
  final List<dynamic> attachments;
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

  Project({
    required this.id,
    required this.name,
    required this.description,
    required this.status,
    required this.priority,
    required this.teamMembers,
    required this.startDate,
    required this.endDate,
    required this.createdBy,
    required this.updatedBy,
    required this.createdAt,
    required this.updatedAt,
    this.completion = 0.0,
    this.attachments = const [],
  }) : assert(teamMembers.length <= 6, 'A project can have a maximum of 6 team members'),
       assert(startDate.isBefore(endDate) || startDate.isAtSameMomentAs(endDate), 'Start date must be before or equal to end date'),
       assert(validStatuses.contains(status), 'Invalid status value'),
       assert(validPriorities.contains(priority), 'Invalid priority value'),
       assert(completion >= 0 && completion <= 100, 'Completion must be between 0 and 100');

  factory Project.fromJson(Map<String, dynamic> json) {
    final log = Logger('Project');
    
    // Safely parse team_members field which might be causing the JSON syntax error
    List<String> teamMembers = [];
    try {
      final teamMembersRaw = json['team_members'];
      if (teamMembersRaw is List) {
        // If it's already a List, convert each element to String
        teamMembers = teamMembersRaw.map((e) => e.toString()).toList();
      } else if (teamMembersRaw is String) {
        // If it's a String, try to parse it as JSON
        try {
          // Clean up the string if it has newlines or extra spaces
          String cleanedString = teamMembersRaw
              .replaceAll('\n', '')
              .replaceAll('\r', '')
              .trim();
          
          // Parse the JSON string to a List
          final parsed = jsonDecode(cleanedString);
          if (parsed is List) {
            teamMembers = parsed.map((e) => e.toString()).toList();
          } else {
            // If parsing succeeds but result is not a List
            teamMembers = [teamMembersRaw];
          }
        } catch (e) {
          // If parsing fails, just use the string as a single member
          log.warning('Error parsing team_members string: $e', e, StackTrace.current);
          teamMembers = [teamMembersRaw];
        }
      }
    } catch (e) {
      log.warning('Error parsing team_members: $e', e, StackTrace.current);
      // Continue with empty list if parsing fails
    }
    
    // Safely parse attachments field
    List<dynamic> attachments = [];
    try {
      final attachmentsRaw = json['attachments'];
      if (attachmentsRaw is List) {
        // If it's already a List, use it directly
        attachments = attachmentsRaw;
      } else if (attachmentsRaw is String) {
        // If it's a String, try to parse it as JSON
        try {
          // Clean up the string if it has newlines or extra spaces
          String cleanedString = attachmentsRaw
              .replaceAll('\n', '')
              .replaceAll('\r', '')
              .trim();
          
          // Parse the JSON string to a List
          final parsed = jsonDecode(cleanedString);
          if (parsed is List) {
            attachments = parsed;
          } else {
            // If parsing succeeds but result is not a List
            attachments = [];
          }
        } catch (e) {
          // If parsing fails, use an empty list
          log.warning('Error parsing attachments string: $e', e, StackTrace.current);
          attachments = [];
        }
      }
    } catch (e) {
      log.warning('Error parsing attachments: $e', e, StackTrace.current);
      // Continue with empty list if parsing fails
    }
    
    return Project(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      status: json['status'] as String? ?? 'not_started',
      priority: json['priority'] as String? ?? 'low',
      teamMembers: teamMembers,
      startDate: json['start_date'] != null ? DateTime.parse(json['start_date'] as String) : DateTime.now(),
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date'] as String) : DateTime.now(),
      completion: (json['completion'] as num?)?.toDouble() ?? 0.0,
      // Use the safely parsed attachments
      attachments: attachments,
      createdBy: json['created_by'] as String? ?? '',
      updatedBy: json['updated_by'] as String? ?? '',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    // Ensure we're using the exact field names expected by the database
    return {
      'id': id,
      'name': name,
      'description': description,
      'status': status,
      'priority': priority,
      'team_members': teamMembers, // Make sure this matches the database column name
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'completion': completion,
      'created_by': createdBy,
      'updated_by': updatedBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      // Only include attachments if not empty
      if (attachments.isNotEmpty) 'attachments': attachments,
    };
  }

  Project copyWith({
    String? id,
    String? name,
    String? description,
    String? status,
    String? priority,
    List<String>? teamMembers,
    DateTime? startDate,
    DateTime? endDate,
    double? completion,
    List<dynamic>? attachments,
    String? createdBy,
    String? updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      teamMembers: teamMembers ?? this.teamMembers,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      completion: completion ?? this.completion,
      attachments: attachments ?? this.attachments,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

