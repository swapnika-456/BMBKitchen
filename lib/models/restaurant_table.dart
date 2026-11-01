enum TableStatus { available, occupied, reserved }

class RestaurantTable {
  final String id;
  final String name; // maps to tableName in API
  final int cap; // maps to capacity in API
  final String area; // maps to location in API
  final TableStatus status;
  final String? resName;
  final String? orderId;
  final String outlet; // maps to outletId in API

  // API specific fields
  final double? taxPercent;
  final bool isActive;
  final String? organizationId;
  final dynamic createdBy;
  final dynamic updatedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const RestaurantTable({
    required this.id,
    required this.name,
    required this.cap,
    required this.area,
    this.status = TableStatus.available,
    this.resName,
    this.orderId,
    required this.outlet,
    this.taxPercent,
    this.isActive = true,
    this.organizationId,
    this.createdBy,
    this.updatedBy,
    this.createdAt,
    this.updatedAt,
  });

  factory RestaurantTable.fromJson(Map<String, dynamic> json) {
    TableStatus s = TableStatus.available;
    final statusStr = json['status']?.toString().toLowerCase();
    if (statusStr == 'occupied') s = TableStatus.occupied;
    if (statusStr == 'reserved') s = TableStatus.reserved;

    return RestaurantTable(
      id: _parseId(json['_id'] ?? json['id']),
      name: json['tableName']?.toString() ?? json['name']?.toString() ?? '',
      cap:
          int.tryParse(
            json['capacity']?.toString() ?? json['cap']?.toString() ?? '',
          ) ??
          4,
      area:
          json['location']?.toString() ??
          json['area']?.toString() ??
          'Main Area',
      status: s,
      outlet: _parseId(json['outletId'] ?? json['outlet']),
      taxPercent: double.tryParse(json['taxPercent']?.toString() ?? ''),
      isActive: json['isActive'] as bool? ?? true,
      organizationId: _parseId(json['organizationId']),
      createdBy: json['createdBy'],
      updatedBy: json['updatedBy'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  static String _parseId(dynamic idVal) {
    if (idVal == null) return '';
    if (idVal is String) return idVal;
    if (idVal is Map && idVal.containsKey('_id'))
      return idVal['_id'].toString();
    if (idVal is Map && idVal.containsKey('\$oid'))
      return idVal['\$oid'].toString();
    return idVal.toString();
  }

  bool get isAvailable => status == TableStatus.available;
  bool get isOccupied => status == TableStatus.occupied;
  bool get isReserved => status == TableStatus.reserved;

  RestaurantTable copyWith({
    String? id,
    String? name,
    int? cap,
    String? area,
    TableStatus? status,
    String? resName,
    bool clearResName = false,
    String? orderId,
    bool clearOrderId = false,
    String? outlet,
    double? taxPercent,
    bool? isActive,
    String? organizationId,
  }) {
    return RestaurantTable(
      id: id ?? this.id,
      name: name ?? this.name,
      cap: cap ?? this.cap,
      area: area ?? this.area,
      status: status ?? this.status,
      resName: clearResName ? null : (resName ?? this.resName),
      orderId: clearOrderId ? null : (orderId ?? this.orderId),
      outlet: outlet ?? this.outlet,
      taxPercent: taxPercent ?? this.taxPercent,
      isActive: isActive ?? this.isActive,
      organizationId: organizationId ?? this.organizationId,
      createdBy: createdBy,
      updatedBy: updatedBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
