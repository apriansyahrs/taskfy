/// Represents a task in the application.
class Task {
  final String? id;
  final String name;
  final String description;
  final String status;
  final String priority;
  final List<String> assignedTo;
  final DateTime deadline;
  final List<String> attachments;

  /// Creates a new [Task] instance.
  Task({
    this.id,
    required this.name,
    required this.description,
    required this.status,
    required this.priority,
    required this.assignedTo,
    required this.deadline,
    this.attachments = const [],
  }) : assert(assignedTo.length <= 3, 'A task can be assigned to a maximum of 3 people');

  /// Creates a [Task] instance from a JSON map.
  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String?,
      name: json['name'] as String,
      description: json['description'] as String,
      status: json['status'] as String,
      priority: json['priority'] as String,
      assignedTo: (json['assigned_to'] as List).cast<String>(),
      deadline: DateTime.parse(json['deadline'] as String),
      attachments: (json['attachments'] as List?)?.cast<String>() ?? [],
    );
  }

  /// Converts the [Task] instance to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'description': description,
      'status': status,
      'priority': priority,
      'assigned_to': assignedTo,
      'deadline': deadline.toIso8601String(),
      'attachments': attachments,
    };
  }

  /// Creates a copy of this [Task] instance with the given fields replaced with new values.
  Task copyWith({
    String? id,
    String? name,
    String? description,
    String? status,
    String? priority,
    List<String>? assignedTo,
    DateTime? deadline,
    List<String>? attachments,
  }) {
    return Task(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      assignedTo: assignedTo ?? this.assignedTo,
      deadline: deadline ?? this.deadline,
      attachments: attachments ?? this.attachments,
    );
  }
}

