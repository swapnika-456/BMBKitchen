/// Central Kitchen Transfer model corresponding to CentralKitchenTransferSchema
/// from BMB_KITCHEN_BACKEND_API_8 (Endpoints #119 to #126).
class CentralKitchenTransferLine {
  final String id;
  final String inventoryId;
  final String materialName;
  final double quantity;

  const CentralKitchenTransferLine({
    this.id = '',
    required this.inventoryId,
    this.materialName = '',
    required this.quantity,
  });

  factory CentralKitchenTransferLine.fromJson(Map<String, dynamic> json) {
    String invId = '';
    String matName = '';
    final rawInv = json['inventoryId'];
    if (rawInv is Map) {
      invId = (rawInv['_id'] ?? rawInv['id'] ?? '').toString();
      matName = (rawInv['material'] ?? rawInv['name'] ?? '').toString();
    } else if (rawInv != null) {
      invId = rawInv.toString();
    }

    return CentralKitchenTransferLine(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      inventoryId: invId,
      materialName: matName,
      quantity: _parseDouble(json['quantity']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'inventoryId': inventoryId,
      'quantity': quantity,
    };
  }

  static double _parseDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0.0;
  }
}

class CentralKitchenTransfer {
  final String id;
  final String organizationId;
  final String transferNo;
  final String fromOutletId;
  final String fromOutletName;
  final String toOutletId;
  final String toOutletName;
  final List<CentralKitchenTransferLine> lines;
  final double value;
  final String status; // "Requested" | "Approved" | "Dispatched" | "Received"
  final bool isActive;
  final String? createdBy;
  final String? updatedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CentralKitchenTransfer({
    required this.id,
    required this.organizationId,
    required this.transferNo,
    required this.fromOutletId,
    this.fromOutletName = '',
    required this.toOutletId,
    this.toOutletName = '',
    required this.lines,
    this.value = 0.0,
    this.status = 'Requested',
    this.isActive = true,
    this.createdBy,
    this.updatedBy,
    this.createdAt,
    this.updatedAt,
  });

  factory CentralKitchenTransfer.fromJson(Map<String, dynamic> json) {
    String fromId = '';
    String fromName = '';
    final rawFrom = json['fromOutletId'];
    if (rawFrom is Map) {
      fromId = (rawFrom['_id'] ?? rawFrom['id'] ?? '').toString();
      fromName = (rawFrom['name'] ?? rawFrom['code'] ?? '').toString();
    } else if (rawFrom != null) {
      fromId = rawFrom.toString();
    }

    String toId = '';
    String toName = '';
    final rawTo = json['toOutletId'];
    if (rawTo is Map) {
      toId = (rawTo['_id'] ?? rawTo['id'] ?? '').toString();
      toName = (rawTo['name'] ?? rawTo['code'] ?? '').toString();
    } else if (rawTo != null) {
      toId = rawTo.toString();
    }

    final rawLines = json['lines'];
    final parsedLines = <CentralKitchenTransferLine>[];
    if (rawLines is List) {
      for (final l in rawLines) {
        if (l is Map<String, dynamic>) {
          parsedLines.add(CentralKitchenTransferLine.fromJson(l));
        } else if (l is Map) {
          parsedLines.add(
            CentralKitchenTransferLine.fromJson(Map<String, dynamic>.from(l)),
          );
        }
      }
    }

    return CentralKitchenTransfer(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      organizationId: (json['organizationId'] ?? '').toString(),
      transferNo: (json['transferNo'] ?? '').toString(),
      fromOutletId: fromId,
      fromOutletName: fromName,
      toOutletId: toId,
      toOutletName: toName,
      lines: parsedLines,
      value: _parseDouble(json['value']),
      status: (json['status'] ?? 'Requested').toString(),
      isActive: json['isActive'] ?? true,
      createdBy: json['createdBy']?.toString(),
      updatedBy: json['updatedBy']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fromOutletId': fromOutletId,
      'toOutletId': toOutletId,
      'lines': lines.map((l) => l.toJson()).toList(),
    };
  }

  CentralKitchenTransfer copyWith({
    String? id,
    String? organizationId,
    String? transferNo,
    String? fromOutletId,
    String? fromOutletName,
    String? toOutletId,
    String? toOutletName,
    List<CentralKitchenTransferLine>? lines,
    double? value,
    String? status,
    bool? isActive,
    String? createdBy,
    String? updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CentralKitchenTransfer(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      transferNo: transferNo ?? this.transferNo,
      fromOutletId: fromOutletId ?? this.fromOutletId,
      fromOutletName: fromOutletName ?? this.fromOutletName,
      toOutletId: toOutletId ?? this.toOutletId,
      toOutletName: toOutletName ?? this.toOutletName,
      lines: lines ?? this.lines,
      value: value ?? this.value,
      status: status ?? this.status,
      isActive: isActive ?? this.isActive,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isRequested => status.toLowerCase() == 'requested';
  bool get isApproved => status.toLowerCase() == 'approved';
  bool get isDispatched => status.toLowerCase() == 'dispatched';
  bool get isReceived => status.toLowerCase() == 'received';

  /// Next sequential stage per strict server pipeline rules
  String? get nextStatus {
    switch (status) {
      case 'Requested':
        return 'Approved';
      case 'Approved':
        return 'Dispatched';
      case 'Dispatched':
        return 'Received';
      default:
        return null;
    }
  }

  /// Action verb for next step
  String? get nextActionLabel {
    switch (status) {
      case 'Requested':
        return 'Approve';
      case 'Approved':
        return 'Mark dispatched';
      case 'Dispatched':
        return 'Mark received';
      default:
        return null;
    }
  }

  static double _parseDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0.0;
  }
}
