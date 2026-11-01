class Outlet {
  final String id;
  final String organizationId;
  final String? outletNo;
  final String name;
  final String code;
  final String? address;
  final String? phone;
  final bool isActive;
  final String? createdBy;
  final String? updatedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Outlet({
    required this.id,
    required this.organizationId,
    this.outletNo,
    required this.name,
    required this.code,
    this.address,
    this.phone,
    required this.isActive,
    this.createdBy,
    this.updatedBy,
    this.createdAt,
    this.updatedAt,
  });

  factory Outlet.fromJson(Map<String, dynamic> json) {
    return Outlet(
      id: json['_id'] as String? ?? '',
      organizationId: _parseObjectId(json['organizationId']),
      outletNo: json['outletNo'] as String?,
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? 'OUT',
      address: json['address'] as String?,
      phone: json['phone'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      createdBy: _parseObjectId(json['createdBy']),
      updatedBy: _parseObjectId(json['updatedBy']),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
    );
  }

  static String _parseObjectId(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is Map<String, dynamic> && value['_id'] != null) {
      return value['_id'].toString();
    }
    return value.toString();
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'code': code,
      if (address != null) 'address': address,
      if (phone != null) 'phone': phone,
    };
  }

  Outlet copyWith({
    String? id,
    String? organizationId,
    String? outletNo,
    String? name,
    String? code,
    String? address,
    String? phone,
    bool? isActive,
    String? createdBy,
    String? updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Outlet(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      outletNo: outletNo ?? this.outletNo,
      name: name ?? this.name,
      code: code ?? this.code,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      isActive: isActive ?? this.isActive,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
