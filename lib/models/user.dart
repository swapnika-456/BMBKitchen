class User {
  final String id;
  final String name;
  final String email;
  final String role;
  final String organizationId;
  final bool isActive;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.organizationId,
    required this.isActive,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // organizationId can be a string (from signup) or a map (from login)
    final orgData = json['organizationId'];
    final orgId = orgData is Map
        ? orgData['_id'] as String?
        : orgData as String?;

    return User(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['userName'] ?? json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      organizationId: orgId ?? '',
      isActive: json['isActive'] ?? true,
    );
  }
}
