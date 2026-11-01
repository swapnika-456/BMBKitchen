class Role {
  final String id;
  final String name;
  final String desc;
  final List<String> perms;

  const Role({
    required this.id,
    required this.name,
    required this.desc,
    required this.perms,
  });

  bool get hasAll => perms.contains('all');

  bool hasPermission(String perm) => hasAll || perms.contains(perm);

  Role copyWith({String? id, String? name, String? desc, List<String>? perms}) {
    return Role(
      id: id ?? this.id,
      name: name ?? this.name,
      desc: desc ?? this.desc,
      perms: perms ?? this.perms,
    );
  }
}

class Staff {
  final String id;
  final String name;
  final String role; // role ID
  final String phone;
  final String pin;
  final String outlet; // outlet ID
  final bool active;
  final String joined;

  const Staff({
    required this.id,
    required this.name,
    required this.role,
    required this.phone,
    required this.pin,
    required this.outlet,
    this.active = true,
    required this.joined,
  });

  Staff copyWith({
    String? id,
    String? name,
    String? role,
    String? phone,
    String? pin,
    String? outlet,
    bool? active,
    String? joined,
  }) {
    return Staff(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      pin: pin ?? this.pin,
      outlet: outlet ?? this.outlet,
      active: active ?? this.active,
      joined: joined ?? this.joined,
    );
  }
}
