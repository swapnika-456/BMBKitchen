import 'package:flutter/foundation.dart';

/// Wastage & Stock Adjustment Model
/// Maps to wastageAdjustmentSchema from the BMB Kitchen API (#87 - #94).
@immutable
class WastageAdjustment {
  final String id;
  final String organizationId;
  final String wastageNo;
  final String inventoryId;
  final String inventoryMaterial;
  final String inventoryUnit;
  final String type; // "wastage" | "adjustment"
  final String? action; // "add" | "remove"
  final double quantity;
  final String? reason;
  final bool isActive;
  final String createdBy;
  final String? updatedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const WastageAdjustment({
    required this.id,
    required this.organizationId,
    required this.wastageNo,
    required this.inventoryId,
    this.inventoryMaterial = '',
    this.inventoryUnit = '',
    required this.type,
    this.action,
    required this.quantity,
    this.reason,
    this.isActive = true,
    this.createdBy = '',
    this.updatedBy,
    this.createdAt,
    this.updatedAt,
  });

  factory WastageAdjustment.fromJson(Map<String, dynamic> json) {
    // Tolerant id resolution
    final id = (json['_id'] ?? json['id'] ?? '').toString();
    final organizationId = (json['organizationId'] is Map
            ? json['organizationId']['_id']
            : json['organizationId'] ?? '')
        .toString();

    final wastageNo = (json['wastageNo'] ?? '').toString();

    // Tolerant inventoryId parsing (plain string or populated object)
    String invId = '';
    String invMaterial = '';
    String invUnit = '';
    final rawInv = json['inventoryId'];
    if (rawInv is Map<String, dynamic>) {
      invId = (rawInv['_id'] ?? rawInv['id'] ?? '').toString();
      invMaterial = (rawInv['material'] ?? rawInv['name'] ?? '').toString();
      invUnit = (rawInv['unit'] ?? '').toString();
    } else if (rawInv is String) {
      invId = rawInv;
    }

    final type = (json['type'] ?? 'wastage').toString().toLowerCase();
    final action = json['action']?.toString().toLowerCase();

    final quantity = (json['quantity'] as num?)?.toDouble() ?? 0.0;
    final reason = json['reason']?.toString();
    final isActive = json['isActive'] is bool ? json['isActive'] as bool : true;

    // Tolerant createdBy parsing (plain string or populated user map)
    String createdByStr = '';
    final rawCreatedBy = json['createdBy'];
    if (rawCreatedBy is Map<String, dynamic>) {
      createdByStr = (rawCreatedBy['userName'] ??
              rawCreatedBy['name'] ??
              rawCreatedBy['_id'] ??
              '')
          .toString();
    } else if (rawCreatedBy != null) {
      createdByStr = rawCreatedBy.toString();
    }

    String? updatedByStr;
    final rawUpdatedBy = json['updatedBy'];
    if (rawUpdatedBy is Map<String, dynamic>) {
      updatedByStr = (rawUpdatedBy['userName'] ??
              rawUpdatedBy['name'] ??
              rawUpdatedBy['_id'] ??
              '')
          .toString();
    } else if (rawUpdatedBy != null) {
      updatedByStr = rawUpdatedBy.toString();
    }

    DateTime? createdAt;
    if (json['createdAt'] != null) {
      createdAt = DateTime.tryParse(json['createdAt'].toString());
    }

    DateTime? updatedAt;
    if (json['updatedAt'] != null) {
      updatedAt = DateTime.tryParse(json['updatedAt'].toString());
    }

    return WastageAdjustment(
      id: id,
      organizationId: organizationId,
      wastageNo: wastageNo,
      inventoryId: invId,
      inventoryMaterial: invMaterial,
      inventoryUnit: invUnit,
      type: type,
      action: action,
      quantity: quantity,
      reason: reason,
      isActive: isActive,
      createdBy: createdByStr,
      updatedBy: updatedByStr,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Create body (#88)
  Map<String, dynamic> toCreateJson() {
    final map = <String, dynamic>{
      'inventoryId': inventoryId,
      'type': type,
      'quantity': quantity,
      'reason': reason ?? '',
    };
    if (action != null && action!.isNotEmpty) {
      map['action'] = action;
    }
    return map;
  }

  /// Update body (#91) - Only type and reason are mutable per PDF API specs
  Map<String, dynamic> toUpdateJson() {
    final map = <String, dynamic>{};
    if (type.isNotEmpty) {
      map['type'] = type;
    }
    if (reason != null) {
      map['reason'] = reason;
    }
    return map;
  }

  WastageAdjustment copyWith({
    String? id,
    String? organizationId,
    String? wastageNo,
    String? inventoryId,
    String? inventoryMaterial,
    String? inventoryUnit,
    String? type,
    String? action,
    double? quantity,
    String? reason,
    bool? isActive,
    String? createdBy,
    String? updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WastageAdjustment(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      wastageNo: wastageNo ?? this.wastageNo,
      inventoryId: inventoryId ?? this.inventoryId,
      inventoryMaterial: inventoryMaterial ?? this.inventoryMaterial,
      inventoryUnit: inventoryUnit ?? this.inventoryUnit,
      type: type ?? this.type,
      action: action ?? this.action,
      quantity: quantity ?? this.quantity,
      reason: reason ?? this.reason,
      isActive: isActive ?? this.isActive,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
