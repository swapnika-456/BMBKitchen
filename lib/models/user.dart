/// User profile and authentication model matching BMB API PDF specs.
/// Password hash is strictly stripped and never retained or stored.

class ProfileImage {
  final String? type;
  final String? key;
  final String? url;
  final String? originalName;
  final DateTime? uploadedAt;
  final String? id;

  const ProfileImage({
    this.type,
    this.key,
    this.url,
    this.originalName,
    this.uploadedAt,
    this.id,
  });

  factory ProfileImage.fromJson(Map<String, dynamic> json) {
    return ProfileImage(
      type: json['type'] as String?,
      key: json['key'] as String?,
      url: json['url'] as String?,
      originalName: json['originalName'] as String?,
      uploadedAt: json['uploadedAt'] != null
          ? DateTime.tryParse(json['uploadedAt'].toString())
          : null,
      id: (json['_id'] ?? json['id']) as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    if (type != null) 'type': type,
    if (key != null) 'key': key,
    if (url != null) 'url': url,
    if (originalName != null) 'originalName': originalName,
    if (uploadedAt != null) 'uploadedAt': uploadedAt!.toIso8601String(),
    if (id != null) '_id': id,
  };
}

class ModulePermissions {
  final bool create;
  final bool get;
  final bool update;
  final bool delete;

  const ModulePermissions({
    this.create = false,
    this.get = false,
    this.update = false,
    this.delete = false,
  });

  factory ModulePermissions.fromJson(Map<String, dynamic> json) {
    return ModulePermissions(
      create: json['create'] == true,
      get: json['get'] == true,
      update: json['update'] == true,
      delete: json['delete'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'create': create,
    'get': get,
    'update': update,
    'delete': delete,
  };
}

class User {
  final String id;
  final String userName;
  final String email;
  final String phoneNo;
  final String role;
  final String? specificRole;
  final String organizationId;
  final String? organizationName;
  final bool isActive;
  final ProfileImage? profileImage;
  final Map<String, ModulePermissions> permissions;

  User({
    required this.id,
    String? userName,
    String? name,
    required this.email,
    this.phoneNo = '',
    required this.role,
    this.specificRole,
    required this.organizationId,
    this.organizationName,
    required this.isActive,
    this.profileImage,
    this.permissions = const {},
  }) : userName = userName ?? name ?? '';

  /// Backward-compatible alias for existing callers expecting `user.name`
  String get name => userName;


  factory User.fromJson(Map<String, dynamic> rawJson) {
    // IMPORTANT: Strip password/passwordHash before parsing
    final json = Map<String, dynamic>.from(rawJson);
    json.remove('password');
    json.remove('passwordHash');
    json.remove('hash');

    // organizationId can be a string (from signup) or a map (from login/me)
    final orgData = json['organizationId'];
    String? orgId;
    String? orgName;

    if (orgData is Map) {
      orgId = orgData['_id'] as String? ?? orgData['id'] as String?;
      orgName = orgData['name'] as String?;
    } else if (orgData is String) {
      orgId = orgData;
    }

    // Parse profileImage
    ProfileImage? img;
    if (json['profileImage'] is Map<String, dynamic>) {
      img = ProfileImage.fromJson(json['profileImage'] as Map<String, dynamic>);
    } else if (json['profileImage'] is Map) {
      img = ProfileImage.fromJson(Map<String, dynamic>.from(json['profileImage'] as Map));
    }

    // Parse permissions map
    final perms = <String, ModulePermissions>{};
    if (json['permissions'] is Map) {
      final pMap = json['permissions'] as Map;
      pMap.forEach((key, val) {
        if (val is Map) {
          perms[key.toString()] = ModulePermissions.fromJson(Map<String, dynamic>.from(val));
        }
      });
    }

    return User(
      id: (json['_id'] ?? json['id'] ?? '') as String,
      userName: (json['userName'] ?? json['name'] ?? '') as String,
      email: (json['email'] ?? '') as String,
      phoneNo: (json['phoneNo'] ?? json['phone'] ?? '') as String,
      role: (json['role'] ?? 'staff') as String,
      specificRole: json['specificRole'] as String?,
      organizationId: orgId ?? '',
      organizationName: orgName,
      isActive: json['isActive'] ?? true,
      profileImage: img,
      permissions: perms,
    );
  }

  User copyWith({
    String? id,
    String? userName,
    String? email,
    String? phoneNo,
    String? role,
    String? specificRole,
    String? organizationId,
    String? organizationName,
    bool? isActive,
    ProfileImage? profileImage,
    Map<String, ModulePermissions>? permissions,
  }) {
    return User(
      id: id ?? this.id,
      userName: userName ?? this.userName,
      email: email ?? this.email,
      phoneNo: phoneNo ?? this.phoneNo,
      role: role ?? this.role,
      specificRole: specificRole ?? this.specificRole,
      organizationId: organizationId ?? this.organizationId,
      organizationName: organizationName ?? this.organizationName,
      isActive: isActive ?? this.isActive,
      profileImage: profileImage ?? this.profileImage,
      permissions: permissions ?? this.permissions,
    );
  }
}
