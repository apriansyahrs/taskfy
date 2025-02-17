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
    this.id = '',  // Changed to optional with a default empty string
    required this.name,
    required this.description,
    required this.status,
    required this.priority,
    required this.teamMembers,
    required this.startDate,
    required this.endDate,
    this.completion = 0.0,
    this.attachments = const [],
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] as String? ?? '',  // Handle potentially null id
      name: json['name'] as String,
      description: json['description'] as String,
      status: json['status'] as String,
      priority: json['priority'] as String,
      teamMembers: List<String>.from(json['team_members'] as List),
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      completion: (json['completion'] as num).toDouble(),
      attachments: List<String>.from(json['attachments'] as List? ?? []),
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
}

