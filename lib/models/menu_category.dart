import 'package:flutter/foundation.dart';

@immutable
class MenuCategory {
  final String id;
  final String name;
  final String? description;
  final bool isActive;
  final String? organizationId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const MenuCategory({
    required this.id,
    required this.name,
    this.description,
    this.isActive = true,
    this.organizationId,
    this.createdAt,
    this.updatedAt,
  });

  factory MenuCategory.fromJson(Map<String, dynamic> json) {
    return MenuCategory(
      id: _parseId(json['_id'] ?? json['id']),
      name: json['name'] as String? ?? 'Unnamed Category',
      description: json['description'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      organizationId: json['organizationId'] != null
          ? _parseId(json['organizationId'])
          : null,
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
    if (idVal is Map && idVal.containsKey('\$oid')) {
      return idVal['\$oid'].toString();
    }
    return idVal.toString();
  }

  MenuCategory copyWith({
    String? id,
    String? name,
    String? description,
    bool? isActive,
    String? organizationId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MenuCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      organizationId: organizationId ?? this.organizationId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
