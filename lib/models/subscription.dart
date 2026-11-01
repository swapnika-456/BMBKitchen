import '../core/network/json_utils.dart';

class SubscriptionInvoice {
  final String id;
  final String invoiceNo;
  final DateTime? date;
  final double amount;
  final String status; // Paid | Pending | Failed

  const SubscriptionInvoice({
    required this.id,
    required this.invoiceNo,
    this.date,
    required this.amount,
    required this.status,
  });

  factory SubscriptionInvoice.fromJson(Map<String, dynamic> json) {
    return SubscriptionInvoice(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      invoiceNo: json['invoiceNo']?.toString() ?? '',
      date: json['date'] != null ? DateTime.tryParse(json['date'].toString()) : null,
      amount: (json['amount'] is num) ? (json['amount'] as num).toDouble() : 0.0,
      status: json['status']?.toString() ?? 'Pending',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) '_id': id,
      'invoiceNo': invoiceNo,
      if (date != null) 'date': date!.toIso8601String(),
      'amount': amount,
      'status': status,
    };
  }
}

class SubscriptionInfo {
  final String plan;
  final dynamic price;
  final String cycle;
  final int outlets;
  final String started;
  final String renews;
  final String status;
  final List<dynamic> invoices;

  const SubscriptionInfo({
    this.plan = 'Growth',
    this.price,
    this.cycle = 'monthly',
    this.outlets = 2,
    this.started = '',
    this.renews = '',
    this.status = 'active',
    this.invoices = const [],
  });

  SubscriptionInfo copyWith({
    String? plan,
    dynamic price,
    String? cycle,
    int? outlets,
    String? started,
    String? renews,
    String? status,
    List<dynamic>? invoices,
  }) {
    return SubscriptionInfo(
      plan: plan ?? this.plan,
      price: price ?? this.price,
      cycle: cycle ?? this.cycle,
      outlets: outlets ?? this.outlets,
      started: started ?? this.started,
      renews: renews ?? this.renews,
      status: status ?? this.status,
      invoices: invoices ?? this.invoices,
    );
  }
}

class Subscription {
  final String id;
  final String organizationId;
  final String plan; // Starter | Growth | Chain
  final double price;
  final String cycle; // monthly | yearly
  final int outletsIncluded;
  final DateTime? startedAt;
  final DateTime? renewsAt;
  final String status; // active | expired | cancelled
  final List<SubscriptionInvoice> invoices;
  final String? createdBy;
  final String? updatedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Subscription({
    required this.id,
    required this.organizationId,
    required this.plan,
    required this.price,
    required this.cycle,
    required this.outletsIncluded,
    this.startedAt,
    this.renewsAt,
    required this.status,
    this.invoices = const [],
    this.createdBy,
    this.updatedBy,
    this.createdAt,
    this.updatedAt,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    // Tolerant parsing for organizationId (plain or populated)
    final orgData = json['organizationId'];
    final orgId = orgData is Map
        ? (orgData['_id']?.toString() ?? '')
        : (orgData?.toString() ?? '');

    // Invoices list
    final invListRaw = JsonUtils.extractList(json['invoices']);
    final parsedInvoices = invListRaw
        .map((e) => SubscriptionInvoice.fromJson(e))
        .toList();

    return Subscription(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      organizationId: orgId,
      plan: json['plan']?.toString() ?? 'Starter',
      price: (json['price'] is num) ? (json['price'] as num).toDouble() : 0.0,
      cycle: json['cycle']?.toString() ?? 'monthly',
      outletsIncluded: (json['outletsIncluded'] is num)
          ? (json['outletsIncluded'] as num).toInt()
          : 1,
      startedAt: json['startedAt'] != null
          ? DateTime.tryParse(json['startedAt'].toString())
          : null,
      renewsAt: json['renewsAt'] != null
          ? DateTime.tryParse(json['renewsAt'].toString())
          : null,
      status: json['status']?.toString() ?? 'active',
      invoices: parsedInvoices,
      createdBy: json['createdBy'] is Map
          ? (json['createdBy']['_id']?.toString())
          : json['createdBy']?.toString(),
      updatedBy: json['updatedBy'] is Map
          ? (json['updatedBy']['_id']?.toString())
          : json['updatedBy']?.toString(),
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
      'plan': plan,
      'price': price,
      'cycle': cycle,
      'outletsIncluded': outletsIncluded,
      if (renewsAt != null) 'renewsAt': renewsAt!.toIso8601String(),
    };
  }

  bool get isActive => status.toLowerCase() == 'active';
  bool get isExpired => status.toLowerCase() == 'expired';
  bool get isCancelled => status.toLowerCase() == 'cancelled';
}
