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
  final List<String> attachments;

  Project({
    required this.id,
    required this.name,
    required this.description,
    required this.status,
    required this.priority,
    required this.teamMembers,
    required this.startDate,
    required this.endDate,
    this.completion = 0.0,
    this.attachments = const [],
  }) : assert(teamMembers.length <= 6, 'A project can have a maximum of 6 team members');

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      status: json['status'] as String,
      priority: json['priority'] as String,
      teamMembers: (json['team_members'] as List).cast<String>(),
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      completion: (json['completion'] as num).toDouble(),
      attachments: (json['attachments'] as List?)?.cast<String>() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'status': status,
      'priority': priority,
      'team_members': teamMembers,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'completion': completion,
      'attachments': attachments,
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
    List<String>? attachments,
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
    );
  }
}

