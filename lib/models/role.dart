class Role {
  final String id;
  final String organizationId;
  final String? roleNo;
  final String name;
  final String description;
  final bool isFullAccess;
  final List<String> permissions;
  final bool isActive;
  final String? createdBy;
  final String? updatedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Role({
    required this.id,
    required this.organizationId,
    this.roleNo,
    required this.name,
    this.description = '',
    this.isFullAccess = false,
    this.permissions = const [],
    this.isActive = true,
    this.createdBy,
    this.updatedBy,
    this.createdAt,
    this.updatedAt,
  });

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      id: json['_id'] ?? json['id'] ?? '',
      organizationId: json['organizationId'] is Map
          ? (json['organizationId']['_id'] ?? '')
          : (json['organizationId'] ?? ''),
      roleNo: json['roleNo'],
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      isFullAccess: json['isFullAccess'] ?? false,
      permissions:
          (json['permissions'] as List?)?.map((e) => e.toString()).toList() ??
          [],
      isActive: json['isActive'] ?? true,
      createdBy: json['createdBy'] is Map
          ? json['createdBy']['_id']
          : json['createdBy'],
      updatedBy: json['updatedBy'] is Map
          ? json['updatedBy']['_id']
          : json['updatedBy'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (roleNo != null) 'roleNo': roleNo,
      'name': name,
      'description': description,
      'isFullAccess': isFullAccess,
      'permissions': permissions,
      'isActive': isActive,
    };
  }

  Role copyWith({
    String? id,
    String? organizationId,
    String? roleNo,
    String? name,
    String? description,
    bool? isFullAccess,
    List<String>? permissions,
    bool? isActive,
    String? createdBy,
    String? updatedBy,
  }) {
    return Role(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      roleNo: roleNo ?? this.roleNo,
      name: name ?? this.name,
      description: description ?? this.description,
      isFullAccess: isFullAccess ?? this.isFullAccess,
      permissions: permissions ?? this.permissions,
      isActive: isActive ?? this.isActive,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
