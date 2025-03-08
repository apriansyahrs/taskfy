class User {
  final String id;
  final String email;
  final String role;
  final List<String> permissions;
  final bool isActive;
  final String? lastActive;

  User({
    required this.id,
    required this.email,
    required this.role,
    this.permissions = const [],
    this.isActive = true,
    this.lastActive,
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
      lastActive: json['last_active'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'role': role,
      'permissions': permissions,
      'is_active': isActive,
      'last_active': lastActive,
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? role,
    List<String>? permissions,
    bool? isActive,
    String? lastActive,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      role: role ?? this.role,
      permissions: permissions ?? this.permissions,
      isActive: isActive ?? this.isActive,
      lastActive: lastActive ?? this.lastActive,
    );
  }

  bool hasPermission(String permission) {
    return permissions.contains(permission);
  }
}

