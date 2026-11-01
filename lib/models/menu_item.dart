import '../core/money/paise.dart';
import '../core/widgets/food_type_dot.dart';

class MenuItemImage {
  final String id;
  final String url;
  const MenuItemImage({required this.id, required this.url});

  factory MenuItemImage.fromJson(Map<String, dynamic> json) {
    return MenuItemImage(
      id:
          json['imageId']?.toString() ??
          json['public_id']?.toString() ??
          json['_id']?.toString() ??
          json['id']?.toString() ??
          '',
      url: json['url']?.toString() ?? json['path']?.toString() ?? '',
    );
  }
}

class MenuVariant {
  final String name;
  final Paise priceDelta; // can be negative e.g. -₹60 for Half

  const MenuVariant({required this.name, required this.priceDelta});

  factory MenuVariant.fromJson(Map<String, dynamic> json) {
    return MenuVariant(
      name: json['name'] as String? ?? '',
      priceDelta: Paise.fromRupees(
        num.tryParse(
              json['priceDelta']?.toString() ?? json['price']?.toString() ?? '',
            ) ??
            0,
      ),
    );
  }
}

class MenuAddon {
  final String name;
  final Paise price;

  const MenuAddon({required this.name, required this.price});

  factory MenuAddon.fromJson(Map<String, dynamic> json) {
    return MenuAddon(
      name: json['name'] as String? ?? '',
      price: Paise.fromRupees(
        num.tryParse(json['price']?.toString() ?? '') ?? 0,
      ),
    );
  }
}

class MenuItem {
  final String id;
  final String name;
  final String cat;
  final Paise price;
  final FoodType type;
  final List<MenuVariant> variants;
  final List<MenuAddon> addons;
  final bool avail;
  final bool isActive;
  final int prepMin;
  final List<MenuItemImage> images;

  const MenuItem({
    required this.id,
    required this.name,
    required this.cat,
    required this.price,
    required this.type,
    this.variants = const [],
    this.addons = const [],
    this.avail = true,
    this.isActive = true,
    this.prepMin = 12,
    this.images = const [],
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    final typeStr = json['foodType'] as String?;
    print('BMB_LOG: foodType returned by server: "$typeStr"');

    FoodType t = FoodType.unknown;
    if (typeStr != null) {
      final s = typeStr.toString().toLowerCase().replaceAll(
        RegExp(r'[^a-z]'),
        '',
      );
      if (s.contains('nonveg') || s.contains('nonvegetarian')) {
        t = FoodType.nonveg;
      } else if (s.contains('egg')) {
        t = FoodType.egg;
      } else if (s.contains('veg')) {
        t = FoodType.veg;
      }
    }

    return MenuItem(
      id: _parseId(json['_id'] ?? json['id']),
      name: json['name'] as String? ?? '',
      cat: _parseId(json['categoryId'] ?? json['cat']),
      price: Paise.fromRupees(
        num.tryParse(
              json['basePrice']?.toString() ?? json['price']?.toString() ?? '',
            ) ??
            0,
      ),
      type: t,
      variants:
          (json['variants'] as List<dynamic>?)
              ?.map((e) => MenuVariant.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      addons:
          (json['addOns'] as List<dynamic>?)
              ?.map((e) => MenuAddon.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      avail: json['avail'] as bool? ?? true,
      isActive: json['isActive'] as bool? ?? true,
      prepMin: int.tryParse(json['prepTime']?.toString() ?? '') ?? 12,
      images: _parseImages(json['images'] ?? json['files']),
    );
  }

  static List<MenuItemImage> _parseImages(dynamic imgJson) {
    if (imgJson == null) return [];
    if (imgJson is! List) return [];
    return imgJson
        .map((e) {
          if (e is Map<String, dynamic>) return MenuItemImage.fromJson(e);
          if (e is String) return MenuItemImage(id: '', url: e);
          return MenuItemImage(id: '', url: '');
        })
        .where((e) => e.url.isNotEmpty)
        .toList();
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

  /// Calculates unit price for this item with specified variant and add-ons
  Paise calculateUnitPrice({
    MenuVariant? variant,
    List<MenuAddon> selectedAddons = const [],
  }) {
    var unit = price;
    if (variant != null) {
      unit = unit + variant.priceDelta;
    }
    for (final addon in selectedAddons) {
      unit = unit + addon.price;
    }
    return unit;
  }

  MenuItem copyWith({
    String? id,
    String? name,
    String? cat,
    Paise? price,
    FoodType? type,
    List<MenuVariant>? variants,
    List<MenuAddon>? addons,
    bool? avail,
    bool? isActive,
    int? prepMin,
    List<MenuItemImage>? images,
  }) {
    return MenuItem(
      id: id ?? this.id,
      name: name ?? this.name,
      cat: cat ?? this.cat,
      price: price ?? this.price,
      type: type ?? this.type,
      variants: variants ?? this.variants,
      addons: addons ?? this.addons,
      avail: avail ?? this.avail,
      isActive: isActive ?? this.isActive,
      prepMin: prepMin ?? this.prepMin,
      images: images ?? this.images,
    );
  }
}
