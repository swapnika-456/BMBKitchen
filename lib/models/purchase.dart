import '../core/money/paise.dart';

class PurchaseLine {
  final String ing;
  final double qty;
  final Paise rate;

  const PurchaseLine({
    required this.ing,
    required this.qty,
    required this.rate,
  });

  PurchaseItem toPurchaseItem() => PurchaseItem(
        id: ing,
        inventoryId: ing,
        inventoryName: '',
        quantity: qty,
        rate: rate.toRupees,
        amount: (rate * qty).toRupees,
      );
}

class PurchaseItem {
  final String id;
  final String inventoryId;
  final String inventoryName;
  final double quantity;
  final double rate;
  final double amount;

  PurchaseItem({
    required this.id,
    required this.inventoryId,
    required this.inventoryName,
    required this.quantity,
    required this.rate,
    required this.amount,
  });

  factory PurchaseItem.fromJson(Map<String, dynamic> json) {
    String invId = '';
    String invName = '';

    if (json['inventoryId'] is Map) {
      final invMap = json['inventoryId'] as Map;
      invId = invMap['_id']?.toString() ?? invMap['id']?.toString() ?? '';
      invName = invMap['material']?.toString() ??
          invMap['name']?.toString() ??
          invMap['inventoryName']?.toString() ??
          '';
    } else {
      invId = json['inventoryId']?.toString() ?? '';
    }

    if (invName.isEmpty) {
      invName = json['inventoryName']?.toString() ??
          json['material']?.toString() ??
          json['name']?.toString() ??
          '';
    }

    return PurchaseItem(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      inventoryId: invId,
      inventoryName: invName.isNotEmpty ? invName : 'Unknown Material',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      rate: (json['rate'] as num?)?.toDouble() ?? 0.0,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'inventoryId': inventoryId,
      'quantity': quantity,
      'rate': rate,
      'amount': amount,
    };
  }
}

class Purchase {
  final String id;
  final String organizationId;
  final String purchaseNo;
  final String vendorId;
  final String vendorName;
  final List<PurchaseItem> items;
  final double totalAmount;
  final String paymentStatus;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? createdBy;
  final String? updatedBy;

  // Legacy/Mock compatibility fields
  final String? invoice;
  final int? at;
  final String outlet;
  final String? by;
  final String? _date;
  final List<PurchaseLine>? _lines;

  Purchase({
    required this.id,
    this.organizationId = '',
    String? purchaseNo,
    String? no,
    String? vendorId,
    String? vendor,
    this.vendorName = '',
    List<PurchaseItem>? items,
    List<PurchaseLine>? lines,
    double? totalAmount,
    Paise? total,
    String? paymentStatus,
    String? payStatus,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.invoice,
    this.at,
    this.outlet = '',
    this.by,
    String? date,
  })  : purchaseNo = purchaseNo ?? no ?? '',
        vendorId = vendorId ?? vendor ?? '',
        _date = date,
        _lines = lines,
        items = items ??
            lines
                ?.map((l) => PurchaseItem(
                      id: l.ing,
                      inventoryId: l.ing,
                      inventoryName: '',
                      quantity: l.qty,
                      rate: l.rate.toRupees,
                      amount: (l.rate * l.qty).toRupees,
                    ))
                .toList() ??
            [],
        totalAmount = totalAmount ??
            (total != null
                ? total.toRupees
                : (lines != null
                    ? lines.fold<double>(
                        0.0,
                        (sum, l) => sum + (l.rate * l.qty).toRupees,
                      )
                    : 0.0)),
        paymentStatus = paymentStatus ?? payStatus ?? 'pending';

  // Legacy aliases
  String get no => purchaseNo;
  String get vendor => vendorId;
  String get payStatus => paymentStatus;
  String get date {
    final d = _date;
    if (d != null && d.isNotEmpty) return d;
    if (createdAt != null) {
      return createdAt!.toIso8601String().substring(0, 10);
    }
    if (at != null) {
      return DateTime.fromMillisecondsSinceEpoch(at!)
          .toIso8601String()
          .substring(0, 10);
    }
    return '';
  }

  Paise get total => Paise.fromRupees(totalAmount);

  List<PurchaseLine> get lines =>
      _lines ??
      items
          .map((i) => PurchaseLine(
                ing: i.inventoryId,
                qty: i.quantity,
                rate: Paise.fromRupees(i.rate),
              ))
          .toList();

  Purchase copyWith({
    String? id,
    String? organizationId,
    String? purchaseNo,
    String? no,
    String? vendorId,
    String? vendor,
    String? vendorName,
    List<PurchaseItem>? items,
    List<PurchaseLine>? lines,
    double? totalAmount,
    Paise? total,
    String? paymentStatus,
    String? payStatus,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
    String? invoice,
    int? at,
    String? outlet,
    String? by,
    String? date,
  }) {
    return Purchase(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      purchaseNo: purchaseNo ?? no ?? this.purchaseNo,
      vendorId: vendorId ?? vendor ?? this.vendorId,
      vendorName: vendorName ?? this.vendorName,
      items: items ?? this.items,
      lines: lines ?? _lines,
      totalAmount: totalAmount ?? (total != null ? total.toRupees : this.totalAmount),
      paymentStatus: paymentStatus ?? payStatus ?? this.paymentStatus,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      invoice: invoice ?? this.invoice,
      at: at ?? this.at,
      outlet: outlet ?? this.outlet,
      by: by ?? this.by,
      date: date ?? _date,
    );
  }

  factory Purchase.fromJson(Map<String, dynamic> json) {
    String vId = '';
    String vName = '';

    if (json['vendorId'] is Map) {
      final vMap = json['vendorId'] as Map;
      vId = vMap['_id']?.toString() ?? vMap['id']?.toString() ?? '';
      vName = vMap['vendorName']?.toString() ??
          vMap['name']?.toString() ??
          '';
    } else if (json['vendorId'] != null) {
      vId = json['vendorId'].toString();
    }

    if (vName.isEmpty) {
      if (json['vendor'] is Map) {
        final vMap = json['vendor'] as Map;
        if (vId.isEmpty) {
          vId = vMap['_id']?.toString() ?? vMap['id']?.toString() ?? '';
        }
        vName = vMap['vendorName']?.toString() ??
            vMap['name']?.toString() ??
            '';
      } else if (json['vendor'] is String) {
        if (vId.isEmpty) vId = json['vendor'] as String;
      }
    }

    if (vName.isEmpty) {
      vName = json['vendorName']?.toString() ?? '';
    }

    return Purchase(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      organizationId: json['organizationId']?.toString() ?? '',
      purchaseNo: json['purchaseNo']?.toString() ?? json['no']?.toString() ?? '',
      vendorId: vId,
      vendorName: vName.isNotEmpty ? vName : 'Unknown Vendor',
      items: (json['items'] as List?)
              ?.map((e) => PurchaseItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ??
          (json['total'] is num ? (json['total'] as num).toDouble() : 0.0),
      paymentStatus: json['paymentStatus']?.toString() ?? json['payStatus']?.toString() ?? 'pending',
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
      createdBy: json['createdBy']?.toString(),
      updatedBy: json['updatedBy']?.toString(),
      invoice: json['invoice']?.toString(),
      outlet: json['outlet']?.toString() ?? '',
      by: json['by']?.toString(),
    );
  }
}
