enum PrinterType {
  bill('Bill'),
  kot('KOT');

  final String label;
  const PrinterType(this.label);
}

/// Printer model matching PrinterSchema from BMB_KITCHEN_BACKEND_API_8 (Endpoints #129-#136).
class Printer {
  final String id;
  final String organizationId;
  final String outletId;
  final String? outletName;
  final String name;
  final String type; // "Bill" | "KOT"
  final String? printerModel;
  final String? conn; // "USB" or "LAN 192.168.1.44"
  final String size; // "80mm" | "58mm"
  final int copies; // 1 to 4
  final List<String> categories; // Category names or IDs
  final bool isActive;
  final String? createdBy;
  final String? updatedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Printer({
    required this.id,
    this.organizationId = '',
    this.outletId = '',
    this.outletName,
    required this.name,
    this.type = 'KOT',
    this.printerModel,
    this.conn,
    this.size = '80mm',
    this.copies = 1,
    this.categories = const [],
    this.isActive = true,
    this.createdBy,
    this.updatedBy,
    this.createdAt,
    this.updatedAt,
  });

  // Backwards compatibility getters
  List<String> get cats => categories;
  String get model => printerModel ?? '';
  bool get active => isActive;
  bool get isBill => type.toLowerCase() == 'bill';
  bool get isKot => type.toLowerCase() == 'kot';
  PrinterType get printerType => isBill ? PrinterType.bill : PrinterType.kot;

  factory Printer.fromJson(Map<String, dynamic> json) {
    String outId = '';
    String? outName;
    final rawOutlet = json['outletId'];
    if (rawOutlet is Map) {
      outId = (rawOutlet['_id'] ?? rawOutlet['id'] ?? '').toString();
      outName = rawOutlet['name']?.toString();
    } else if (rawOutlet != null) {
      outId = rawOutlet.toString();
    }

    // Tolerant parsing for categories
    List<String> parsedCats = [];
    final rawCats = json['categories'] ?? json['cats'];
    if (rawCats is List) {
      for (final item in rawCats) {
        if (item is Map) {
          parsedCats.add((item['name'] ?? item['_id'] ?? item['id'] ?? '').toString());
        } else if (item != null) {
          parsedCats.add(item.toString());
        }
      }
    }

    String parseUser(dynamic val) {
      if (val == null) return '';
      if (val is Map) return (val['name'] ?? val['email'] ?? val['_id'] ?? '').toString();
      return val.toString();
    }

    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is DateTime) return val;
      return DateTime.tryParse(val.toString());
    }

    // Type parsing: ensure "Bill" or "KOT" format
    String rawType = (json['type'] ?? 'KOT').toString();
    if (rawType.toLowerCase() == 'bill') {
      rawType = 'Bill';
    } else {
      rawType = 'KOT';
    }

    // Size parsing: default "80mm"
    String rawSize = (json['size'] ?? '80mm').toString();
    if (rawSize != '58mm' && rawSize != '80mm') {
      rawSize = '80mm';
    }

    // Copies parsing: 1 to 4, default 1
    int parsedCopies = (json['copies'] as num?)?.toInt() ?? 1;
    if (parsedCopies < 1 || parsedCopies > 4) {
      parsedCopies = 1;
    }

    return Printer(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      organizationId: (json['organizationId'] ?? '').toString(),
      outletId: outId,
      outletName: outName,
      name: (json['name'] ?? '').toString(),
      type: rawType,
      printerModel: json['printerModel'] as String? ?? json['model'] as String?,
      conn: json['conn'] as String?,
      size: rawSize,
      copies: parsedCopies,
      categories: parsedCats,
      isActive: json['isActive'] as bool? ?? json['active'] as bool? ?? true,
      createdBy: parseUser(json['createdBy']),
      updatedBy: parseUser(json['updatedBy']),
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'outletId': outletId,
      'name': name,
      'type': type,
      if (printerModel != null && printerModel!.isNotEmpty) 'printerModel': printerModel,
      if (conn != null && conn!.isNotEmpty) 'conn': conn,
      'size': size,
      'copies': copies,
      'categories': categories,
    };
  }

  Printer copyWith({
    String? id,
    String? organizationId,
    String? outletId,
    String? outletName,
    String? name,
    String? type,
    String? printerModel,
    String? conn,
    String? size,
    int? copies,
    List<String>? categories,
    bool? isActive,
    String? createdBy,
    String? updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Printer(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      outletId: outletId ?? this.outletId,
      outletName: outletName ?? this.outletName,
      name: name ?? this.name,
      type: type ?? this.type,
      printerModel: printerModel ?? this.printerModel,
      conn: conn ?? this.conn,
      size: size ?? this.size,
      copies: copies ?? this.copies,
      categories: categories ?? this.categories,
      isActive: isActive ?? this.isActive,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
