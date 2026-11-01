import '../core/money/paise.dart';
import 'kot.dart';
import 'order_line.dart';
import 'payment_record.dart';

enum OrderType {
  dinein('Dine-in', 'dine_in'),
  takeaway('Takeaway', 'takeaway'),
  delivery('Delivery', 'delivery'),
  online('Online', 'online');

  final String label;
  final String apiValue;
  const OrderType(this.label, this.apiValue);

  static OrderType fromApi(String? val) {
    if (val == null) return OrderType.dinein;
    final lower = val.toLowerCase().replaceAll('-', '_');
    switch (lower) {
      case 'dine_in':
      case 'dinein':
        return OrderType.dinein;
      case 'takeaway':
        return OrderType.takeaway;
      case 'delivery':
        return OrderType.delivery;
      case 'online':
        return OrderType.online;
      default:
        return OrderType.dinein;
    }
  }
}

enum OrderSource {
  pos('POS'),
  qr('QR'),
  captain('Captain'),
  swiggy('Swiggy'),
  zomato('Zomato'),
  phone('Phone');

  final String label;
  const OrderSource(this.label);
}

enum OrderStatus {
  open('Active', 'active'),
  completed('Completed', 'completed'),
  cancelled('Cancelled', 'cancelled');

  final String label;
  final String apiValue;
  const OrderStatus(this.label, this.apiValue);

  static OrderStatus fromApi(String? val) {
    if (val == null) return OrderStatus.open;
    final lower = val.toLowerCase();
    switch (lower) {
      case 'active':
      case 'open':
        return OrderStatus.open;
      case 'completed':
        return OrderStatus.completed;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.open;
    }
  }
}

class OrderItem extends OrderLine {
  final String id;
  final String menuItemId;
  final double price;
  final int quantity;
  final double itemTotal;
  final String notes;
  final String status; // in_queue | preparing | ready | served | cancelled
  final DateTime? sentToKitchenAt;
  final DateTime? readyAt;
  final DateTime? servedAt;

  OrderItem({
    this.id = '',
    required this.menuItemId,
    required super.name,
    required this.price,
    this.quantity = 1,
    required this.itemTotal,
    this.notes = '',
    this.status = 'in_queue',
    this.sentToKitchenAt,
    this.readyAt,
    this.servedAt,
    super.sig = '',
    super.kotNo,
    super.variant,
    super.addons = const [],
  }) : super(
         itemId: menuItemId,
         qty: quantity,
         unitPrice: Paise((price * 100).round()),
         note: notes,
       );

  factory OrderItem.fromOrderLine(OrderLine line) {
    final priceVal = line.unitPrice.toRupees;
    return OrderItem(
      id: line.sig,
      menuItemId: line.itemId,
      name: line.name,
      price: priceVal,
      quantity: line.qty,
      itemTotal: priceVal * line.qty,
      notes: line.note,
      status: line.isSent ? 'preparing' : 'in_queue',
      sig: line.sig,
      kotNo: line.kotNo,
      variant: line.variant,
      addons: line.addons,
    );
  }

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    String mId = '';
    String mName = json['name']?.toString() ?? '';
    final rawMenu = json['menuItemId'];
    if (rawMenu is Map) {
      mId = rawMenu['_id']?.toString() ?? rawMenu['id']?.toString() ?? '';
      if (mName.isEmpty) {
        mName = rawMenu['name']?.toString() ?? '';
      }
    } else if (rawMenu != null) {
      mId = rawMenu.toString();
    }

    final priceVal = (json['price'] as num?)?.toDouble() ?? 0.0;
    final qtyVal = (json['quantity'] as num?)?.toInt() ?? 1;
    final itemTotalVal = (json['itemTotal'] as num?)?.toDouble() ?? (priceVal * qtyVal);

    DateTime? parseDate(dynamic d) {
      if (d == null) return null;
      if (d is DateTime) return d;
      return DateTime.tryParse(d.toString());
    }

    return OrderItem(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      menuItemId: mId,
      name: mName.isNotEmpty ? mName : 'Item',
      price: priceVal,
      quantity: qtyVal >= 1 ? qtyVal : 1,
      itemTotal: itemTotalVal,
      notes: json['notes']?.toString() ?? '',
      status: json['status']?.toString().toLowerCase() ?? 'in_queue',
      sentToKitchenAt: parseDate(json['sentToKitchenAt']),
      readyAt: parseDate(json['readyAt']),
      servedAt: parseDate(json['servedAt']),
    );
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'menuItemId': menuItemId,
      'name': name,
      'price': price,
      'quantity': quantity,
      'itemTotal': itemTotal,
      'notes': notes,
    };
  }

  @override
  OrderItem copyWith({
    String? id,
    String? itemId,
    String? menuItemId,
    String? name,
    double? price,
    int? quantity,
    double? itemTotal,
    String? notes,
    String? status,
    DateTime? sentToKitchenAt,
    DateTime? readyAt,
    DateTime? servedAt,
    String? sig,
    int? kotNo,
    int? qty,
    String? variant,
    List<String>? addons,
    Paise? unitPrice,
    String? note,
  }) {
    final effectivePrice = price ?? (unitPrice != null ? unitPrice.toRupees : this.price);
    final effectiveQty = quantity ?? qty ?? this.quantity;
    final effectiveMenuItemId = menuItemId ?? itemId ?? this.menuItemId;
    return OrderItem(
      id: id ?? this.id,
      menuItemId: effectiveMenuItemId,
      name: name ?? this.name,
      price: effectivePrice,
      quantity: effectiveQty,
      itemTotal: itemTotal ?? (effectivePrice * effectiveQty),
      notes: notes ?? note ?? this.notes,
      status: status ?? this.status,
      sentToKitchenAt: sentToKitchenAt ?? this.sentToKitchenAt,
      readyAt: readyAt ?? this.readyAt,
      servedAt: servedAt ?? this.servedAt,
      sig: sig ?? this.sig,
      kotNo: kotNo ?? this.kotNo,
      variant: variant ?? this.variant,
      addons: addons ?? this.addons,
    );
  }
}

class OrderCheckoutPreview {
  final double subTotal;
  final double offerDiscount;
  final double manualDiscount;
  final double loyaltyDiscount;
  final double totalDiscount;
  final double taxPercent;
  final double serviceChargePercent;
  final double serviceChargeAmount;
  final double taxAmount;
  final double grandTotal;
  final int maxRedeemablePoints;
  final int pointsRedeemed;

  const OrderCheckoutPreview({
    required this.subTotal,
    this.offerDiscount = 0,
    this.manualDiscount = 0,
    this.loyaltyDiscount = 0,
    this.totalDiscount = 0,
    this.taxPercent = 0,
    this.serviceChargePercent = 0,
    this.serviceChargeAmount = 0,
    this.taxAmount = 0,
    required this.grandTotal,
    this.maxRedeemablePoints = 0,
    this.pointsRedeemed = 0,
  });

  factory OrderCheckoutPreview.fromJson(Map<String, dynamic> json) {
    num n(dynamic v) => (v as num?) ?? 0;
    return OrderCheckoutPreview(
      subTotal: n(json['subTotal']).toDouble(),
      offerDiscount: n(json['offerDiscount']).toDouble(),
      manualDiscount: n(json['manualDiscount']).toDouble(),
      loyaltyDiscount: n(json['loyaltyDiscount']).toDouble(),
      totalDiscount: n(json['totalDiscount']).toDouble(),
      taxPercent: n(json['taxPercent']).toDouble(),
      serviceChargePercent: n(json['serviceChargePercent']).toDouble(),
      serviceChargeAmount: n(json['serviceChargeAmount']).toDouble(),
      taxAmount: n(json['taxAmount']).toDouble(),
      grandTotal: n(json['grandTotal']).toDouble(),
      maxRedeemablePoints: n(json['maxRedeemablePoints']).toInt(),
      pointsRedeemed: n(json['pointsRedeemed']).toInt(),
    );
  }
}

class Order {
  final String id;
  final String organizationId;
  final String outletId;
  final String outletName;
  final String orderNo;
  final String? billNo;
  final String? tableId;
  final String? tableName;
  final String orderType; // dine_in | takeaway | delivery | online
  final List<OrderItem> items;
  final double subTotal;
  final double discountAmount;
  final double offerDiscountAmount;
  final double loyaltyDiscountAmount;
  final double manualDiscountAmount;
  final double serviceChargeAmount;
  final double taxPercent;
  final double taxAmount;
  final double grandTotal;
  final String orderStatus; // active | completed | cancelled
  final String paymentStatus; // pending | paid | partially_paid
  final String paymentMethod; // cash | card | upi | split | unpaid
  final DateTime? paidAt;
  final dynamic createdBy;
  final dynamic updatedBy;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Legacy/mock compatibility fields
  final int no;
  final OrderType type;
  final OrderSource src;
  final String outlet;
  final int? token;
  final String? customerId;
  final String customerName;
  final String customerPhone;
  final String address;
  final String rider;
  final List<OrderLine> legacyItems;
  final List<OrderItem> pending;
  final List<KOT> kots;
  final List<PaymentRecord> payments;
  final double discVal;
  final String discType;
  final String offerCode;
  final Paise redeem;
  final OrderStatus status;
  final String? cancelReason;
  final String? deliveryStatus;
  final int createdAtMs;
  final int? closedAtMs;
  final String staffId;
  final String? channel;
  final bool qrPending;

  Order({
    required this.id,
    this.organizationId = '',
    String outletId = '',
    this.outletName = '',
    this.orderNo = '',
    this.billNo,
    this.tableId,
    this.tableName,
    this.orderType = 'dine_in',
    List<dynamic> items = const [],
    this.subTotal = 0.0,
    this.discountAmount = 0.0,
    this.offerDiscountAmount = 0.0,
    this.loyaltyDiscountAmount = 0.0,
    this.manualDiscountAmount = 0.0,
    this.serviceChargeAmount = 0.0,
    this.taxPercent = 5.0,
    this.taxAmount = 0.0,
    this.grandTotal = 0.0,
    this.orderStatus = 'active',
    this.paymentStatus = 'pending',
    this.paymentMethod = 'unpaid',
    this.paidAt,
    this.createdBy,
    this.updatedBy,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
    // Legacy support
    this.no = 0,
    this.type = OrderType.dinein,
    this.src = OrderSource.pos,
    String outlet = '',
    this.token,
    this.customerId,
    this.customerName = '',
    this.customerPhone = '',
    this.address = '',
    this.rider = '',
    this.legacyItems = const [],
    List<dynamic> pending = const [],
    this.kots = const [],
    this.payments = const [],
    this.discVal = 0,
    this.discType = 'amt',
    this.offerCode = '',
    this.redeem = const Paise(0),
    this.status = OrderStatus.open,
    this.cancelReason,
    this.deliveryStatus,
    this.createdAtMs = 0,
    this.closedAtMs,
    this.staffId = '',
    this.channel,
    this.qrPending = false,
  })  : outletId = outletId.isNotEmpty ? outletId : outlet,
        outlet = outlet.isNotEmpty ? outlet : outletId,
        items = items.map((e) {
          if (e is OrderItem) return e;
          if (e is OrderLine) return OrderItem.fromOrderLine(e);
          if (e is Map<String, dynamic>) return OrderItem.fromJson(e);
          return OrderItem(
            menuItemId: e.toString(),
            name: e.toString(),
            price: 0,
            itemTotal: 0,
          );
        }).toList(),
        pending = pending.map((e) {
          if (e is OrderItem) return e;
          if (e is OrderLine) return OrderItem.fromOrderLine(e);
          if (e is Map<String, dynamic>) return OrderItem.fromJson(e);
          return OrderItem(
            menuItemId: e.toString(),
            name: e.toString(),
            price: 0,
            itemTotal: 0,
          );
        }).toList();

  bool get isOpen => orderStatus == 'active' || status == OrderStatus.open;
  bool get isCompleted => orderStatus == 'completed' || status == OrderStatus.completed;
  bool get isCancelled => orderStatus == 'cancelled' || status == OrderStatus.cancelled;
  bool get hasUnsentItems => pending.isNotEmpty;

  Paise get subtotal => Paise.fromRupees(subTotal > 0 ? subTotal : 0);
  Paise get totalPaid => Paise.fromRupees(grandTotal > 0 && isCompleted ? grandTotal : 0);

  factory Order.fromJson(Map<String, dynamic> json) {
    String parseId(dynamic val) {
      if (val == null) return '';
      if (val is Map) return val['_id']?.toString() ?? val['id']?.toString() ?? '';
      return val.toString();
    }

    String? tId;
    String? tName;
    final rawTable = json['tableId'];
    if (rawTable is Map) {
      tId = rawTable['_id']?.toString() ?? rawTable['id']?.toString();
      tName = rawTable['tableName']?.toString() ?? rawTable['name']?.toString();
    } else if (rawTable != null) {
      tId = rawTable.toString();
    }

    String outId = '';
    String outName = '';
    final rawOutlet = json['outletId'] ?? json['outlet'];
    if (rawOutlet is Map) {
      outId = rawOutlet['_id']?.toString() ?? rawOutlet['id']?.toString() ?? '';
      outName = rawOutlet['name']?.toString() ?? '';
    } else if (rawOutlet != null) {
      outId = rawOutlet.toString();
    }

    final rawItems = json['items'];
    List<OrderItem> itemList = [];
    if (rawItems is List) {
      itemList = rawItems
          .whereType<Map<String, dynamic>>()
          .map((i) => OrderItem.fromJson(i))
          .toList();
    }

    DateTime? parseDate(dynamic d) {
      if (d == null) return null;
      if (d is DateTime) return d;
      return DateTime.tryParse(d.toString());
    }

    final oTypeStr = json['orderType']?.toString().toLowerCase() ?? 'dine_in';
    final oStatusStr = json['orderStatus']?.toString().toLowerCase() ??
        (json['status'] is String ? json['status'].toString().toLowerCase() : 'active');
    final pStatusStr = json['paymentStatus']?.toString().toLowerCase() ?? 'pending';
    final pMethodStr = json['paymentMethod']?.toString().toLowerCase() ?? 'unpaid';

    final orderNoStr = json['orderNo']?.toString() ?? '';
    int extractedNo = int.tryParse(orderNoStr.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

    num n(dynamic v) => (v as num?) ?? 0;

    final createdAtDate = parseDate(json['createdAt']);
    final updatedAtDate = parseDate(json['updatedAt']);
    final paidAtDate = parseDate(json['paidAt']);

    return Order(
      id: parseId(json['_id'] ?? json['id']),
      organizationId: parseId(json['organizationId']),
      outletId: outId,
      outletName: outName,
      orderNo: orderNoStr,
      billNo: json['billNo']?.toString(),
      tableId: tId,
      tableName: tName,
      orderType: oTypeStr,
      items: itemList,
      subTotal: n(json['subTotal']).toDouble(),
      discountAmount: n(json['discountAmount']).toDouble(),
      offerDiscountAmount: n(json['offerDiscountAmount']).toDouble(),
      loyaltyDiscountAmount: n(json['loyaltyDiscountAmount']).toDouble(),
      manualDiscountAmount: n(json['manualDiscountAmount']).toDouble(),
      serviceChargeAmount: n(json['serviceChargeAmount']).toDouble(),
      taxPercent: n(json['taxPercent'] ?? 5).toDouble(),
      taxAmount: n(json['taxAmount']).toDouble(),
      grandTotal: n(json['grandTotal']).toDouble(),
      orderStatus: oStatusStr,
      paymentStatus: pStatusStr,
      paymentMethod: pMethodStr,
      paidAt: paidAtDate,
      createdBy: json['createdBy'],
      updatedBy: json['updatedBy'],
      isActive: json['isActive'] != false,
      createdAt: createdAtDate,
      updatedAt: updatedAtDate,
      // Legacy support mappings
      no: extractedNo,
      type: OrderType.fromApi(oTypeStr),
      status: OrderStatus.fromApi(oStatusStr),
      outlet: outId,
      createdAtMs: createdAtDate?.millisecondsSinceEpoch ?? 0,
    );
  }

  Order copyWith({
    String? id,
    String? organizationId,
    String? outletId,
    String? outletName,
    String? orderNo,
    String? billNo,
    String? tableId,
    String? tableName,
    String? orderType,
    List<dynamic>? items,
    double? subTotal,
    double? discountAmount,
    double? offerDiscountAmount,
    double? loyaltyDiscountAmount,
    double? manualDiscountAmount,
    double? serviceChargeAmount,
    double? taxPercent,
    double? taxAmount,
    double? grandTotal,
    String? orderStatus,
    String? paymentStatus,
    String? paymentMethod,
    DateTime? paidAt,
    dynamic createdBy,
    dynamic updatedBy,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    // Legacy support
    int? no,
    OrderType? type,
    OrderSource? src,
    String? outlet,
    int? token,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? address,
    String? rider,
    List<OrderLine>? legacyItems,
    List<dynamic>? pending,
    List<KOT>? kots,
    List<PaymentRecord>? payments,
    double? discVal,
    String? discType,
    String? offerCode,
    Paise? redeem,
    OrderStatus? status,
    String? cancelReason,
    String? deliveryStatus,
    int? createdAtMs,
    int? closedAtMs,
    String? staffId,
    String? channel,
    bool? qrPending,
  }) {
    final effectiveItems = items != null
        ? items.map((e) {
            if (e is OrderItem) return e;
            if (e is OrderLine) return OrderItem.fromOrderLine(e);
            if (e is Map<String, dynamic>) return OrderItem.fromJson(e);
            return OrderItem(
              menuItemId: e.toString(),
              name: e.toString(),
              price: 0,
              itemTotal: 0,
            );
          }).toList()
        : this.items;

    final effectivePending = pending != null
        ? pending.map((e) {
            if (e is OrderItem) return e;
            if (e is OrderLine) return OrderItem.fromOrderLine(e);
            if (e is Map<String, dynamic>) return OrderItem.fromJson(e);
            return OrderItem(
              menuItemId: e.toString(),
              name: e.toString(),
              price: 0,
              itemTotal: 0,
            );
          }).toList()
        : this.pending;

    return Order(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      outletId: outletId ?? this.outletId,
      outletName: outletName ?? this.outletName,
      orderNo: orderNo ?? this.orderNo,
      billNo: billNo ?? this.billNo,
      tableId: tableId ?? this.tableId,
      tableName: tableName ?? this.tableName,
      orderType: orderType ?? this.orderType,
      items: effectiveItems,
      subTotal: subTotal ?? this.subTotal,
      discountAmount: discountAmount ?? this.discountAmount,
      offerDiscountAmount: offerDiscountAmount ?? this.offerDiscountAmount,
      loyaltyDiscountAmount: loyaltyDiscountAmount ?? this.loyaltyDiscountAmount,
      manualDiscountAmount: manualDiscountAmount ?? this.manualDiscountAmount,
      serviceChargeAmount: serviceChargeAmount ?? this.serviceChargeAmount,
      taxPercent: taxPercent ?? this.taxPercent,
      taxAmount: taxAmount ?? this.taxAmount,
      grandTotal: grandTotal ?? this.grandTotal,
      orderStatus: orderStatus ?? this.orderStatus,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paidAt: paidAt ?? this.paidAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      no: no ?? this.no,
      type: type ?? this.type,
      src: src ?? this.src,
      outlet: outlet ?? this.outlet,
      token: token ?? this.token,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      address: address ?? this.address,
      rider: rider ?? this.rider,
      legacyItems: legacyItems ?? this.legacyItems,
      pending: effectivePending,
      kots: kots ?? this.kots,
      payments: payments ?? this.payments,
      discVal: discVal ?? this.discVal,
      discType: discType ?? this.discType,
      offerCode: offerCode ?? this.offerCode,
      redeem: redeem ?? this.redeem,
      status: status ?? this.status,
      cancelReason: cancelReason ?? this.cancelReason,
      deliveryStatus: deliveryStatus ?? this.deliveryStatus,
      createdAtMs: createdAtMs ?? this.createdAtMs,
      closedAtMs: closedAtMs ?? this.closedAtMs,
      staffId: staffId ?? this.staffId,
      channel: channel ?? this.channel,
      qrPending: qrPending ?? this.qrPending,
    );
  }
}

class KitchenItem {
  final String orderId;
  final String orderNo;
  final String orderType;
  final String itemId;
  final String name;
  final int quantity;
  final String notes;
  final String status; // in_queue | preparing | ready | served | cancelled
  final String? tableId;
  final String? tableName;
  final DateTime? sentToKitchenAt;
  final String outletId;

  KitchenItem({
    required this.orderId,
    required this.orderNo,
    required this.orderType,
    required this.itemId,
    required this.name,
    this.quantity = 1,
    this.notes = '',
    this.status = 'in_queue',
    this.tableId,
    this.tableName,
    this.sentToKitchenAt,
    this.outletId = '',
  });

  factory KitchenItem.fromJson(Map<String, dynamic> json) {
    String? tId;
    String? tName;
    final rawTable = json['table'];
    if (rawTable is Map) {
      final tidStr = rawTable['_id']?.toString() ?? rawTable['id']?.toString();
      final tnameStr = rawTable['tableName']?.toString() ?? rawTable['name']?.toString();
      if (tidStr != null && tidStr.isNotEmpty && tidStr != '{}') tId = tidStr;
      if (tnameStr != null && tnameStr.isNotEmpty && tnameStr != '{}') tName = tnameStr;
    } else if (rawTable != null && rawTable.toString() != '{}' && rawTable.toString().trim().isNotEmpty) {
      tName = rawTable.toString();
    }
    if (tId == null && json['tableId'] != null) {
      final rawTid = json['tableId'];
      if (rawTid is Map) {
        tId = rawTid['_id']?.toString() ?? rawTid['id']?.toString();
        tName ??= rawTid['tableName']?.toString() ?? rawTid['name']?.toString();
      } else {
        tId = rawTid.toString();
      }
    }

    DateTime? parseDate(dynamic d) {
      if (d == null) return null;
      if (d is DateTime) return d;
      return DateTime.tryParse(d.toString());
    }

    return KitchenItem(
      orderId: (json['orderId'] ?? '').toString(),
      orderNo: (json['orderNo'] ?? '').toString(),
      orderType: (json['orderType'] ?? 'dine_in').toString(),
      itemId: (json['itemId'] ?? json['_id'] ?? '').toString(),
      name: (json['name'] ?? 'Item').toString(),
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      notes: (json['notes'] ?? '').toString(),
      status: (json['status'] ?? 'in_queue').toString(),
      tableId: tId,
      tableName: tName,
      sentToKitchenAt: parseDate(json['sentToKitchenAt']),
      outletId: (json['outletId'] is Map ? json['outletId']['_id'] : json['outletId'] ?? '').toString(),
    );
  }
}

class KitchenOrdersResponse {
  final List<KitchenItem> items;
  final Map<String, int> counts;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  KitchenOrdersResponse({
    required this.items,
    this.counts = const {},
    this.total = 0,
    this.page = 1,
    this.limit = 20,
    this.totalPages = 1,
  });

  factory KitchenOrdersResponse.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final itemsList = (rawItems is List ? rawItems : [])
        .whereType<Map<String, dynamic>>()
        .map((e) => KitchenItem.fromJson(e))
        .toList();

    final countsMap = <String, int>{};
    final rawCounts = json['counts'];
    if (rawCounts is Map) {
      rawCounts.forEach((k, v) {
        countsMap[k.toString()] = (v as num?)?.toInt() ?? 0;
      });
    }

    return KitchenOrdersResponse(
      items: itemsList,
      counts: countsMap,
      total: (json['total'] as num?)?.toInt() ?? itemsList.length,
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 20,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
    );
  }
}

class OrderListResponse {
  final List<Order> orders;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  OrderListResponse({
    required this.orders,
    this.total = 0,
    this.page = 1,
    this.limit = 20,
    this.totalPages = 1,
  });

  factory OrderListResponse.fromJson(Map<String, dynamic> json) {
    final rawOrders = json['orders'] ?? json['data'];
    final list = (rawOrders is List ? rawOrders : [])
        .whereType<Map<String, dynamic>>()
        .map((e) => Order.fromJson(e))
        .toList();
    final tot = (json['total'] as num?)?.toInt() ?? list.length;
    final lim = (json['limit'] as num?)?.toInt() ?? 20;
    final tp = (json['totalPages'] as num?)?.toInt() ?? (lim > 0 ? (tot / lim).ceil() : 1);

    return OrderListResponse(
      orders: list,
      total: tot,
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: lim,
      totalPages: tp > 0 ? tp : 1,
    );
  }
}

class PaymentMethodSummary {
  final String mode;
  final double amount;
  final int count;

  PaymentMethodSummary({
    required this.mode,
    required this.amount,
    required this.count,
  });

  factory PaymentMethodSummary.fromJson(Map<String, dynamic> json) {
    return PaymentMethodSummary(
      mode: (json['mode'] ?? '').toString(),
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}

class PaidOrdersSummary {
  final double totalCollected;
  final double totalDiscounts;
  final int totalOrders;
  final double avgOrderValue;
  final List<PaymentMethodSummary> byPaymentMethod;

  PaidOrdersSummary({
    required this.totalCollected,
    required this.totalDiscounts,
    required this.totalOrders,
    required this.avgOrderValue,
    this.byPaymentMethod = const [],
  });

  factory PaidOrdersSummary.fromJson(Map<String, dynamic> json) {
    final rawPm = json['byPaymentMethod'];
    final pmList = (rawPm is List ? rawPm : [])
        .whereType<Map<String, dynamic>>()
        .map((e) => PaymentMethodSummary.fromJson(e))
        .toList();

    return PaidOrdersSummary(
      totalCollected: (json['totalCollected'] as num?)?.toDouble() ?? 0.0,
      totalDiscounts: (json['totalDiscounts'] as num?)?.toDouble() ?? 0.0,
      totalOrders: (json['totalOrders'] as num?)?.toInt() ?? 0,
      avgOrderValue: (json['avgOrderValue'] as num?)?.toDouble() ?? 0.0,
      byPaymentMethod: pmList,
    );
  }
}

class PaidOrdersResponse {
  final List<Order> orders;
  final PaidOrdersSummary? summary;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  PaidOrdersResponse({
    required this.orders,
    this.summary,
    this.total = 0,
    this.page = 1,
    this.limit = 20,
    this.totalPages = 1,
  });

  factory PaidOrdersResponse.fromJson(Map<String, dynamic> json) {
    final rawOrders = json['orders'];
    final list = (rawOrders is List ? rawOrders : [])
        .whereType<Map<String, dynamic>>()
        .map((e) => Order.fromJson(e))
        .toList();

    final rawSum = json['summary'];
    final sum = rawSum is Map<String, dynamic> ? PaidOrdersSummary.fromJson(rawSum) : null;
    final tot = (json['total'] as num?)?.toInt() ?? list.length;
    final lim = (json['limit'] as num?)?.toInt() ?? 20;
    final tp = (json['totalPages'] as num?)?.toInt() ?? (lim > 0 ? (tot / lim).ceil() : 1);

    return PaidOrdersResponse(
      orders: list,
      summary: sum,
      total: tot,
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: lim,
      totalPages: tp > 0 ? tp : 1,
    );
  }
}
