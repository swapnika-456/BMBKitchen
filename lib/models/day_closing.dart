/// Day Closing models corresponding to DayClosingSchema from BMB_KITCHEN_BACKEND_API_8
/// (Endpoints #104 to #108).
class DayClosingSummary {
  final String outletId;
  final String closingDate;
  final double totalSales;
  final double cashSales;
  final double upiSales;
  final double cardSales;
  final double onlinePaid;
  final double creditAmount;
  final double discountsGiven;
  final double cashExpensesPaidOut;
  final double totalExpensesToday;
  final int billsSettled;
  final int cancelledOrders;
  final double expectedCash;

  const DayClosingSummary({
    required this.outletId,
    required this.closingDate,
    this.totalSales = 0.0,
    this.cashSales = 0.0,
    this.upiSales = 0.0,
    this.cardSales = 0.0,
    this.onlinePaid = 0.0,
    this.creditAmount = 0.0,
    this.discountsGiven = 0.0,
    this.cashExpensesPaidOut = 0.0,
    this.totalExpensesToday = 0.0,
    this.billsSettled = 0,
    this.cancelledOrders = 0,
    this.expectedCash = 0.0,
  });

  factory DayClosingSummary.fromJson(Map<String, dynamic> json) {
    return DayClosingSummary(
      outletId: _parseString(json['outletId']),
      closingDate: (json['closingDate'] ?? '').toString(),
      totalSales: _parseDouble(json['totalSales']),
      cashSales: _parseDouble(json['cashSales']),
      upiSales: _parseDouble(json['upiSales']),
      cardSales: _parseDouble(json['cardSales']),
      onlinePaid: _parseDouble(json['onlinePaid']),
      creditAmount: _parseDouble(json['creditAmount']),
      discountsGiven: _parseDouble(json['discountsGiven']),
      cashExpensesPaidOut: _parseDouble(json['cashExpensesPaidOut']),
      totalExpensesToday: _parseDouble(json['totalExpensesToday']),
      billsSettled: (json['billsSettled'] as num?)?.toInt() ?? 0,
      cancelledOrders: (json['cancelledOrders'] as num?)?.toInt() ?? 0,
      expectedCash: _parseDouble(json['expectedCash']),
    );
  }

  static double _parseDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0.0;
  }

  static String _parseString(dynamic val) {
    if (val == null) return '';
    if (val is Map) return (val['_id'] ?? val['id'] ?? '').toString();
    return val.toString();
  }
}

class DayClosing {
  final String id;
  final String organizationId;
  final String outletId;
  final String? outletName;
  final String closingNo;
  final String closingDate;
  final double totalSales;
  final double cashSales;
  final double upiSales;
  final double cardSales;
  final double onlinePaid;
  final double creditAmount;
  final double discountsGiven;
  final double cashExpensesPaidOut;
  final double totalExpensesToday;
  final int billsSettled;
  final int cancelledOrders;
  final double expectedCash;
  final double actualCash;
  final double difference;
  final String? closedBy;
  final String? note;
  final String status; // "locked" | "reopened"
  final String? reopenedBy;
  final DateTime? reopenedAt;
  final String? reopenReason;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const DayClosing({
    this.id = '',
    this.organizationId = '',
    required this.outletId,
    this.outletName,
    this.closingNo = '',
    required this.closingDate,
    this.totalSales = 0.0,
    this.cashSales = 0.0,
    this.upiSales = 0.0,
    this.cardSales = 0.0,
    this.onlinePaid = 0.0,
    this.creditAmount = 0.0,
    this.discountsGiven = 0.0,
    this.cashExpensesPaidOut = 0.0,
    this.totalExpensesToday = 0.0,
    this.billsSettled = 0,
    this.cancelledOrders = 0,
    this.expectedCash = 0.0,
    this.actualCash = 0.0,
    this.difference = 0.0,
    this.closedBy,
    this.note,
    this.status = 'locked',
    this.reopenedBy,
    this.reopenedAt,
    this.reopenReason,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  // Compatibility getters for mock_state
  String get date => closingDate;
  String get outlet => outletId;

  bool get isLocked => status == 'locked';
  bool get isReopened => status == 'reopened';

  factory DayClosing.fromJson(Map<String, dynamic> json) {
    String outId = '';
    String? outName;
    final rawOutlet = json['outletId'];
    if (rawOutlet is Map) {
      outId = (rawOutlet['_id'] ?? rawOutlet['id'] ?? '').toString();
      outName = rawOutlet['name']?.toString();
    } else if (rawOutlet != null) {
      outId = rawOutlet.toString();
    }

    String? parseUser(dynamic val) {
      if (val == null) return null;
      if (val is Map) return (val['name'] ?? val['email'] ?? val['_id'] ?? '').toString();
      return val.toString();
    }

    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is DateTime) return val;
      return DateTime.tryParse(val.toString());
    }

    return DayClosing(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      organizationId: (json['organizationId'] ?? '').toString(),
      outletId: outId,
      outletName: outName,
      closingNo: (json['closingNo'] ?? '').toString(),
      closingDate: (json['closingDate'] ?? '').toString(),
      totalSales: _parseDouble(json['totalSales']),
      cashSales: _parseDouble(json['cashSales']),
      upiSales: _parseDouble(json['upiSales']),
      cardSales: _parseDouble(json['cardSales']),
      onlinePaid: _parseDouble(json['onlinePaid']),
      creditAmount: _parseDouble(json['creditAmount']),
      discountsGiven: _parseDouble(json['discountsGiven']),
      cashExpensesPaidOut: _parseDouble(json['cashExpensesPaidOut']),
      totalExpensesToday: _parseDouble(json['totalExpensesToday']),
      billsSettled: (json['billsSettled'] as num?)?.toInt() ?? 0,
      cancelledOrders: (json['cancelledOrders'] as num?)?.toInt() ?? 0,
      expectedCash: _parseDouble(json['expectedCash']),
      actualCash: _parseDouble(json['actualCash']),
      difference: _parseDouble(json['difference']),
      closedBy: parseUser(json['closedBy']),
      note: json['note'] as String?,
      status: (json['status'] ?? 'locked').toString(),
      reopenedBy: parseUser(json['reopenedBy']),
      reopenedAt: parseDate(json['reopenedAt']),
      reopenReason: json['reopenReason'] as String?,
      createdBy: parseUser(json['createdBy']),
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }

  DayClosing copyWith({
    String? id,
    String? organizationId,
    String? outletId,
    String? outletName,
    String? closingNo,
    String? closingDate,
    double? totalSales,
    double? cashSales,
    double? upiSales,
    double? cardSales,
    double? onlinePaid,
    double? creditAmount,
    double? discountsGiven,
    double? cashExpensesPaidOut,
    double? totalExpensesToday,
    int? billsSettled,
    int? cancelledOrders,
    double? expectedCash,
    double? actualCash,
    double? difference,
    String? closedBy,
    String? note,
    String? status,
    String? reopenedBy,
    DateTime? reopenedAt,
    String? reopenReason,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DayClosing(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      outletId: outletId ?? this.outletId,
      outletName: outletName ?? this.outletName,
      closingNo: closingNo ?? this.closingNo,
      closingDate: closingDate ?? this.closingDate,
      totalSales: totalSales ?? this.totalSales,
      cashSales: cashSales ?? this.cashSales,
      upiSales: upiSales ?? this.upiSales,
      cardSales: cardSales ?? this.cardSales,
      onlinePaid: onlinePaid ?? this.onlinePaid,
      creditAmount: creditAmount ?? this.creditAmount,
      discountsGiven: discountsGiven ?? this.discountsGiven,
      cashExpensesPaidOut: cashExpensesPaidOut ?? this.cashExpensesPaidOut,
      totalExpensesToday: totalExpensesToday ?? this.totalExpensesToday,
      billsSettled: billsSettled ?? this.billsSettled,
      cancelledOrders: cancelledOrders ?? this.cancelledOrders,
      expectedCash: expectedCash ?? this.expectedCash,
      actualCash: actualCash ?? this.actualCash,
      difference: difference ?? this.difference,
      closedBy: closedBy ?? this.closedBy,
      note: note ?? this.note,
      status: status ?? this.status,
      reopenedBy: reopenedBy ?? this.reopenedBy,
      reopenedAt: reopenedAt ?? this.reopenedAt,
      reopenReason: reopenReason ?? this.reopenReason,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static double _parseDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0.0;
  }
}
