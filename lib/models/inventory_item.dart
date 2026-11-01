class InventoryItem {
  final String id;
  final String organizationId;
  final String? inventoryNo;
  final String material;
  final String? category;
  final String? unit;
  final double inStock;
  final double minLevel;
  final double rate;
  final String? vendorId; // Could be an object, but we parse out the ID.
  final String? vendorName; // If populated
  final bool isActive;
  final bool isLowStock;
  final Map<String, dynamic>? image;

  const InventoryItem({
    required this.id,
    required this.organizationId,
    this.inventoryNo,
    required this.material,
    this.category,
    this.unit,
    required this.inStock,
    required this.minLevel,
    required this.rate,
    this.vendorId,
    this.vendorName,
    required this.isActive,
    this.isLowStock = false,
    this.image,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    // Parse vendorId which might be an object if populated
    String? vId;
    String? vName;
    if (json['vendorId'] != null) {
      if (json['vendorId'] is Map) {
        vId = json['vendorId']['_id'] as String?;
        vName = json['vendorId']['vendorName'] as String?;
      } else {
        vId = json['vendorId'] as String?;
      }
    }

    dynamic imgData = json['image'] ?? json['images'];
    Map<String, dynamic>? parsedImage;
    if (imgData is Map) {
      parsedImage = Map<String, dynamic>.from(imgData);
    } else if (imgData is List && imgData.isNotEmpty && imgData.first is Map) {
      parsedImage = Map<String, dynamic>.from(imgData.first);
    }

    double parsedInStock = (json['inStock'] as num?)?.toDouble() ?? 0.0;
    double parsedMinLevel = (json['minLevel'] as num?)?.toDouble() ?? 0.0;
    bool calculatedIsLowStock = parsedInStock <= parsedMinLevel && parsedInStock > 0;

    bool finalIsLowStock = calculatedIsLowStock;
    if (json.containsKey('isLowStock')) {
      finalIsLowStock = json['isLowStock'] == true;
      if (finalIsLowStock != calculatedIsLowStock) {
        print('InventoryItem isLowStock mismatch: server=${json['isLowStock']}, fallback=$calculatedIsLowStock');
      }
    }

    return InventoryItem(
      id: json['_id'] ?? json['id'] ?? '',
      organizationId: json['organizationId'] ?? '',
      inventoryNo: json['inventoryNo'],
      material: json['material'] ?? '',
      category: json['category'],
      unit: json['unit'],
      inStock: parsedInStock,
      minLevel: parsedMinLevel,
      rate: (json['rate'] as num?)?.toDouble() ?? 0.0,
      vendorId: vId,
      vendorName: vName,
      isActive: json['isActive'] ?? true,
      isLowStock: finalIsLowStock,
      image: parsedImage,
    );
  }

  // Client-side computation for UI indicators
  double get value => inStock * rate;
  bool get isLow => inStock <= minLevel && inStock > 0;
  bool get isOut => inStock <= 0;
}

class InventoryDropdownItem {
  final String id;
  final String material;
  final String? unit;
  final double rate;
  final bool isLowStock;

  const InventoryDropdownItem({
    required this.id,
    required this.material,
    this.unit,
    required this.rate,
    required this.isLowStock,
  });

  factory InventoryDropdownItem.fromJson(Map<String, dynamic> json) {
    return InventoryDropdownItem(
      id: json['_id'] ?? json['id'] ?? '',
      material: json['material'] ?? '',
      unit: json['unit'],
      rate: (json['rate'] as num?)?.toDouble() ?? 0.0,
      isLowStock: json['isLowStock'] ?? false,
    );
  }
}
