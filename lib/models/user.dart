class User {
  final String id;
  final String email;
  final String role;
  final List<String> permissions;
  final bool isActive;

  User({
    required this.id,
    required this.email,
    required this.role,
    this.permissions = const [],
    this.isActive = true,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'pegawai',
      permissions: json['permissions'] != null
          ? List<String>.from(json['permissions'] as List)
          : [],
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'role': role,
      'permissions': permissions,
      'is_active': isActive,
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? role,
    List<String>? permissions,
    bool? isActive,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      role: role ?? this.role,
      permissions: permissions ?? this.permissions,
      isActive: isActive ?? this.isActive,
    );
  }

  bool hasPermission(String permission) {
    return permissions.contains(permission);
  }
}

