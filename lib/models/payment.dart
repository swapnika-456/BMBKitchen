import '../core/network/json_utils.dart';

class PaymentItem {
  final String id;
  final String? outletId;
  final String? outletName;
  final String? outletCode;
  final String? tableId;
  final String orderType;
  final String? customerId;
  final double discountAmount;
  final double taxAmount;
  final double grandTotal;
  final String paymentMethod;
  final DateTime? paidAt;
  final String orderNo;
  final String? billNo;

  const PaymentItem({
    required this.id,
    this.outletId,
    this.outletName,
    this.outletCode,
    this.tableId,
    required this.orderType,
    this.customerId,
    required this.discountAmount,
    required this.taxAmount,
    required this.grandTotal,
    required this.paymentMethod,
    this.paidAt,
    required this.orderNo,
    this.billNo,
  });

  factory PaymentItem.fromJson(Map<String, dynamic> json) {
    String? outId;
    String? outName;
    String? outCode;
    final outletRaw = json['outletId'];
    if (outletRaw is Map) {
      outId = outletRaw['_id']?.toString();
      outName = outletRaw['name']?.toString();
      outCode = outletRaw['code']?.toString();
    } else if (outletRaw != null) {
      outId = outletRaw.toString();
    }

    String? tblId;
    final tblRaw = json['tableId'];
    if (tblRaw is Map) {
      tblId = tblRaw['_id']?.toString();
    } else if (tblRaw != null) {
      tblId = tblRaw.toString();
    }

    return PaymentItem(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      outletId: outId,
      outletName: outName,
      outletCode: outCode,
      tableId: tblId,
      orderType: json['orderType']?.toString() ?? 'dine_in',
      customerId: json['customerId']?.toString(),
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (json['taxAmount'] as num?)?.toDouble() ?? 0.0,
      grandTotal: (json['grandTotal'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: json['paymentMethod']?.toString() ?? 'cash',
      paidAt: json['paidAt'] != null ? DateTime.tryParse(json['paidAt'].toString()) : null,
      orderNo: json['orderNo']?.toString() ?? '',
      billNo: json['billNo']?.toString(),
    );
  }
}

class PaymentModeSummary {
  final double amount;
  final int count;

  const PaymentModeSummary({
    required this.amount,
    required this.count,
  });

  factory PaymentModeSummary.fromJson(Map<String, dynamic> json) {
    return PaymentModeSummary(
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}

class PaymentSummary {
  final double totalCollected;
  final Map<String, PaymentModeSummary> byMode;

  const PaymentSummary({
    required this.totalCollected,
    required this.byMode,
  });

  factory PaymentSummary.fromJson(Map<String, dynamic> json) {
    final modeMap = <String, PaymentModeSummary>{};
    final byModeRaw = json['byMode'];
    if (byModeRaw is Map) {
      byModeRaw.forEach((key, val) {
        if (val is Map) {
          modeMap[key.toString()] = PaymentModeSummary.fromJson(Map<String, dynamic>.from(val));
        }
      });
    }

    return PaymentSummary(
      totalCollected: (json['totalCollected'] as num?)?.toDouble() ?? 0.0,
      byMode: modeMap,
    );
  }
}

class PaymentListResponse {
  final List<PaymentItem> payments;
  final int total;
  final int page;
  final int limit;
  final int totalPages;
  final PaymentSummary? summary;

  const PaymentListResponse({
    required this.payments,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
    this.summary,
  });

  factory PaymentListResponse.fromJson(Map<String, dynamic> json) {
    final rawList = JsonUtils.extractList(json['payments'] ?? json['records'] ?? json['data']);
    final payments = rawList.map((e) => PaymentItem.fromJson(Map<String, dynamic>.from(e))).toList();

    final total = (json['total'] as num?)?.toInt() ?? payments.length;
    final page = (json['page'] as num?)?.toInt() ?? 1;
    final limit = (json['limit'] as num?)?.toInt() ?? 20;
    final totalPages = (json['totalPages'] as num?)?.toInt() ??
        (limit > 0 ? (total / limit).ceil() : 1);

    PaymentSummary? summary;
    if (json['summary'] is Map) {
      summary = PaymentSummary.fromJson(Map<String, dynamic>.from(json['summary']));
    }

    return PaymentListResponse(
      payments: payments,
      total: total,
      page: page,
      limit: limit,
      totalPages: totalPages > 0 ? totalPages : 1,
      summary: summary,
    );
  }
}

class PaymentDetailItem {
  final String? id;
  final String? menuItemId;
  final String name;
  final double price;
  final int quantity;
  final double itemTotal;
  final String notes;
  final String status;
  final DateTime? sentToKitchenAt;

  const PaymentDetailItem({
    this.id,
    this.menuItemId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.itemTotal,
    required this.notes,
    required this.status,
    this.sentToKitchenAt,
  });

  factory PaymentDetailItem.fromJson(Map<String, dynamic> json) {
    return PaymentDetailItem(
      id: json['_id']?.toString() ?? json['id']?.toString(),
      menuItemId: json['menuItemId']?.toString(),
      name: json['name']?.toString() ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      itemTotal: (json['itemTotal'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes']?.toString() ?? '',
      status: json['status']?.toString() ?? 'in_queue',
      sentToKitchenAt: json['sentToKitchenAt'] != null
          ? DateTime.tryParse(json['sentToKitchenAt'].toString())
          : null,
    );
  }
}

class PaymentDetail {
  final String id;
  final String? outletId;
  final String? outletName;
  final String? outletCode;
  final String? tableId;
  final String? tableName;
  final String orderType;
  final double? loyaltyPointsRedeemed;
  final String? customerId;
  final List<PaymentDetailItem> items;
  final double subTotal;
  final double discountAmount;
  final double taxPercent;
  final double taxAmount;
  final double grandTotal;
  final String paymentMethod;
  final DateTime? paidAt;
  final String orderNo;
  final String? billNo;

  const PaymentDetail({
    required this.id,
    this.outletId,
    this.outletName,
    this.outletCode,
    this.tableId,
    this.tableName,
    required this.orderType,
    this.loyaltyPointsRedeemed,
    this.customerId,
    required this.items,
    required this.subTotal,
    required this.discountAmount,
    required this.taxPercent,
    required this.taxAmount,
    required this.grandTotal,
    required this.paymentMethod,
    this.paidAt,
    required this.orderNo,
    this.billNo,
  });

  factory PaymentDetail.fromJson(Map<String, dynamic> json) {
    String? outId;
    String? outName;
    String? outCode;
    final outletRaw = json['outletId'];
    if (outletRaw is Map) {
      outId = outletRaw['_id']?.toString();
      outName = outletRaw['name']?.toString();
      outCode = outletRaw['code']?.toString();
    } else if (outletRaw != null) {
      outId = outletRaw.toString();
    }

    String? tblId;
    String? tblName;
    final tblRaw = json['tableId'] ?? json['table'];
    if (tblRaw is Map) {
      tblId = tblRaw['_id']?.toString();
      tblName = tblRaw['tableName']?.toString() ?? tblRaw['name']?.toString();
    } else if (tblRaw != null) {
      tblId = tblRaw.toString();
    }

    final rawItems = JsonUtils.extractList(json['items']);
    final items = rawItems.map((e) => PaymentDetailItem.fromJson(Map<String, dynamic>.from(e))).toList();

    return PaymentDetail(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      outletId: outId,
      outletName: outName,
      outletCode: outCode,
      tableId: tblId,
      tableName: tblName,
      orderType: json['orderType']?.toString() ?? 'dine_in',
      loyaltyPointsRedeemed: (json['loyaltyPointsRedeemed'] as num?)?.toDouble(),
      customerId: json['customerId']?.toString(),
      items: items,
      subTotal: (json['subTotal'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0.0,
      taxPercent: (json['taxPercent'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (json['taxAmount'] as num?)?.toDouble() ?? 0.0,
      grandTotal: (json['grandTotal'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: json['paymentMethod']?.toString() ?? 'cash',
      paidAt: json['paidAt'] != null ? DateTime.tryParse(json['paidAt'].toString()) : null,
      orderNo: json['orderNo']?.toString() ?? '',
      billNo: json['billNo']?.toString(),
    );
  }
}
