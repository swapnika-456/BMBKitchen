class RecipeCostIngredient {
  final String id;
  final String inventoryId;
  final String inventoryMaterial;
  final String unit;
  final double rate;
  final double unitValue;

  const RecipeCostIngredient({
    required this.id,
    required this.inventoryId,
    this.inventoryMaterial = '',
    required this.unit,
    required this.rate,
    required this.unitValue,
  });

  double get lineCost => rate * unitValue;

  factory RecipeCostIngredient.fromJson(Map<String, dynamic> json) {
    String invId = '';
    String material = '';
    double invRate = (json['rate'] as num?)?.toDouble() ?? 0.0;
    String invUnit = json['unit']?.toString() ?? '';

    if (json['inventoryId'] is Map) {
      final invMap = json['inventoryId'] as Map<String, dynamic>;
      invId = invMap['_id']?.toString() ?? invMap['id']?.toString() ?? '';
      material = invMap['material']?.toString() ?? invMap['name']?.toString() ?? '';
      if (invRate == 0.0 && invMap['rate'] != null) {
        invRate = (invMap['rate'] as num).toDouble();
      }
      if (invUnit.isEmpty && invMap['unit'] != null) {
        invUnit = invMap['unit'].toString();
      }
    } else if (json['inventoryId'] != null) {
      invId = json['inventoryId'].toString();
    }

    if (material.isEmpty) {
      material = json['inventoryMaterial']?.toString() ??
          json['material']?.toString() ??
          '';
    }

    return RecipeCostIngredient(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      inventoryId: invId,
      inventoryMaterial: material,
      unit: invUnit,
      rate: invRate,
      unitValue: (json['unitValue'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'inventoryId': inventoryId,
      'unit': unit,
      'rate': rate,
      'unitValue': unitValue,
    };
  }
}

class RecipeCost {
  final String id;
  final String organizationId;
  final String recipeCostNo;
  final String menuItemId;
  final String menuItemName;
  final List<RecipeCostIngredient> ingredients;
  final double totalPrice;
  final double grossMargin;
  final double sellingPrice;
  final bool isActive;
  final String? createdBy;
  final String? updatedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const RecipeCost({
    required this.id,
    required this.organizationId,
    required this.recipeCostNo,
    required this.menuItemId,
    this.menuItemName = '',
    required this.ingredients,
    required this.totalPrice,
    required this.grossMargin,
    required this.sellingPrice,
    required this.isActive,
    this.createdBy,
    this.updatedBy,
    this.createdAt,
    this.updatedAt,
  });

  factory RecipeCost.fromJson(Map<String, dynamic> json) {
    String mId = '';
    String mName = '';

    if (json['menuItemId'] is Map) {
      final mMap = json['menuItemId'] as Map<String, dynamic>;
      mId = mMap['_id']?.toString() ?? mMap['id']?.toString() ?? '';
      mName = mMap['name']?.toString() ?? '';
    } else if (json['menuItemId'] != null) {
      mId = json['menuItemId'].toString();
    }

    if (mName.isEmpty && json['menuItemName'] != null) {
      mName = json['menuItemName'].toString();
    }

    final rawIngredients = json['ingredients'];
    final ingredientsList = <RecipeCostIngredient>[];
    if (rawIngredients is List) {
      for (final item in rawIngredients) {
        if (item is Map<String, dynamic>) {
          ingredientsList.add(RecipeCostIngredient.fromJson(item));
        }
      }
    }

    return RecipeCost(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      organizationId: json['organizationId']?.toString() ?? '',
      recipeCostNo: json['recipeCostNo']?.toString() ?? '',
      menuItemId: mId,
      menuItemName: mName,
      ingredients: ingredientsList,
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0.0,
      grossMargin: (json['grossMargin'] as num?)?.toDouble() ?? 0.0,
      sellingPrice: (json['sellingPrice'] as num?)?.toDouble() ?? 0.0,
      isActive: json['isActive'] as bool? ?? true,
      createdBy: json['createdBy']?.toString(),
      updatedBy: json['updatedBy']?.toString(),
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'menuItemId': menuItemId,
      'sellingPrice': sellingPrice,
      'ingredients': ingredients.map((i) => i.toJson()).toList(),
    };
  }
}
