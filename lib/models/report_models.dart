// Strongly typed models for Module 22: Report & Analytics (#154 - #158)
// Based strictly on verbatim live server responses from /api/report/v1/:organizationId

class ReportDateRange {
  final DateTime? from;
  final DateTime? to;

  const ReportDateRange({this.from, this.to});

  factory ReportDateRange.fromJson(Map<String, dynamic> json) {
    return ReportDateRange(
      from: json['from'] != null ? DateTime.tryParse(json['from'].toString()) : null,
      to: json['to'] != null ? DateTime.tryParse(json['to'].toString()) : null,
    );
  }
}

class OrderTypeStat {
  final double amount;
  final int count;

  const OrderTypeStat({
    required this.amount,
    required this.count,
  });

  factory OrderTypeStat.fromJson(Map<String, dynamic> json) {
    return OrderTypeStat(
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}

class DailyTrendItem {
  final String date;
  final double sales;
  final int bills;

  const DailyTrendItem({
    required this.date,
    required this.sales,
    required this.bills,
  });

  factory DailyTrendItem.fromJson(Map<String, dynamic> json) {
    return DailyTrendItem(
      date: json['date']?.toString() ?? '',
      sales: (json['sales'] as num?)?.toDouble() ?? 0.0,
      bills: (json['bills'] as num?)?.toInt() ?? 0,
    );
  }
}

/// #154 GET /sales
class SalesReportData {
  final ReportDateRange? range;
  final double grossSales;
  final double taxableValue;
  final double totalDiscounts;
  final double totalGST;
  final int totalBills;
  final double avgBillValue;
  final int cancelledOrders;
  final Map<String, OrderTypeStat> orderTypeSplit;
  final List<DailyTrendItem> dailyTrend;

  const SalesReportData({
    this.range,
    required this.grossSales,
    required this.taxableValue,
    required this.totalDiscounts,
    required this.totalGST,
    required this.totalBills,
    required this.avgBillValue,
    required this.cancelledOrders,
    required this.orderTypeSplit,
    required this.dailyTrend,
  });

  factory SalesReportData.fromJson(Map<String, dynamic> json) {
    final splitMap = <String, OrderTypeStat>{};
    if (json['orderTypeSplit'] is Map) {
      final raw = json['orderTypeSplit'] as Map<String, dynamic>;
      raw.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          splitMap[key] = OrderTypeStat.fromJson(value);
        }
      });
    }

    final trendList = <DailyTrendItem>[];
    if (json['dailyTrend'] is List) {
      for (final item in json['dailyTrend']) {
        if (item is Map<String, dynamic>) {
          trendList.add(DailyTrendItem.fromJson(item));
        }
      }
    }

    return SalesReportData(
      range: json['range'] is Map<String, dynamic>
          ? ReportDateRange.fromJson(json['range'])
          : null,
      grossSales: (json['grossSales'] as num?)?.toDouble() ?? 0.0,
      taxableValue: (json['taxableValue'] as num?)?.toDouble() ?? 0.0,
      totalDiscounts: (json['totalDiscounts'] as num?)?.toDouble() ?? 0.0,
      totalGST: (json['totalGST'] as num?)?.toDouble() ?? 0.0,
      totalBills: (json['totalBills'] as num?)?.toInt() ?? 0,
      avgBillValue: (json['avgBillValue'] as num?)?.toDouble() ?? 0.0,
      cancelledOrders: (json['cancelledOrders'] as num?)?.toInt() ?? 0,
      orderTypeSplit: splitMap,
      dailyTrend: trendList,
    );
  }
}

/// #155 GET /items
class ReportItemRanking {
  final int rank;
  final String menuItemId;
  final String name;
  final int qtySold;
  final double revenue;
  final double sharePercent;

  const ReportItemRanking({
    required this.rank,
    required this.menuItemId,
    required this.name,
    required this.qtySold,
    required this.revenue,
    required this.sharePercent,
  });

  factory ReportItemRanking.fromJson(Map<String, dynamic> json) {
    return ReportItemRanking(
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      menuItemId: json['menuItemId']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown Item',
      qtySold: (json['qtySold'] as num?)?.toInt() ?? 0,
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0.0,
      sharePercent: (json['sharePercent'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class ItemsReportData {
  final ReportDateRange? range;
  final List<ReportItemRanking> items;

  const ItemsReportData({
    this.range,
    required this.items,
  });

  factory ItemsReportData.fromJson(Map<String, dynamic> json) {
    final list = <ReportItemRanking>[];
    if (json['items'] is List) {
      for (final item in json['items']) {
        if (item is Map<String, dynamic>) {
          list.add(ReportItemRanking.fromJson(item));
        }
      }
    }
    return ItemsReportData(
      range: json['range'] is Map<String, dynamic>
          ? ReportDateRange.fromJson(json['range'])
          : null,
      items: list,
    );
  }
}

/// #156 GET /expenses
class ExpenseCategorySummary {
  final String category;
  final double amount;
  final int count;
  final double sharePercent;

  const ExpenseCategorySummary({
    required this.category,
    required this.amount,
    required this.count,
    required this.sharePercent,
  });

  factory ExpenseCategorySummary.fromJson(Map<String, dynamic> json) {
    return ExpenseCategorySummary(
      category: json['category']?.toString() ?? 'General',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      count: (json['count'] as num?)?.toInt() ?? 0,
      sharePercent: (json['sharePercent'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class ExpensePaymentModeSummary {
  final String mode;
  final double amount;
  final int count;

  const ExpensePaymentModeSummary({
    required this.mode,
    required this.amount,
    required this.count,
  });

  factory ExpensePaymentModeSummary.fromJson(Map<String, dynamic> json) {
    return ExpensePaymentModeSummary(
      mode: json['mode']?.toString() ?? 'cash',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}

class ExpensesReportData {
  final ReportDateRange? range;
  final double totalExpenses;
  final int totalEntries;
  final List<ExpenseCategorySummary> byCategory;
  final List<ExpensePaymentModeSummary> byPaymentMode;

  const ExpensesReportData({
    this.range,
    required this.totalExpenses,
    required this.totalEntries,
    required this.byCategory,
    required this.byPaymentMode,
  });

  factory ExpensesReportData.fromJson(Map<String, dynamic> json) {
    final cats = <ExpenseCategorySummary>[];
    if (json['byCategory'] is List) {
      for (final c in json['byCategory']) {
        if (c is Map<String, dynamic>) {
          cats.add(ExpenseCategorySummary.fromJson(c));
        }
      }
    }
    final modes = <ExpensePaymentModeSummary>[];
    if (json['byPaymentMode'] is List) {
      for (final m in json['byPaymentMode']) {
        if (m is Map<String, dynamic>) {
          modes.add(ExpensePaymentModeSummary.fromJson(m));
        }
      }
    }
    return ExpensesReportData(
      range: json['range'] is Map<String, dynamic>
          ? ReportDateRange.fromJson(json['range'])
          : null,
      totalExpenses: (json['totalExpenses'] as num?)?.toDouble() ?? 0.0,
      totalEntries: (json['totalEntries'] as num?)?.toInt() ?? 0,
      byCategory: cats,
      byPaymentMode: modes,
    );
  }
}

/// #157 GET /payments-summary
class PaymentModeBreakdown {
  final String mode;
  final double amount;
  final int count;
  final double sharePercent;

  const PaymentModeBreakdown({
    required this.mode,
    required this.amount,
    required this.count,
    required this.sharePercent,
  });

  factory PaymentModeBreakdown.fromJson(Map<String, dynamic> json) {
    return PaymentModeBreakdown(
      mode: json['mode']?.toString() ?? 'unknown',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      count: (json['count'] as num?)?.toInt() ?? 0,
      sharePercent: (json['sharePercent'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class PaymentOrderTypeBreakdown {
  final String orderType;
  final double amount;
  final int count;

  const PaymentOrderTypeBreakdown({
    required this.orderType,
    required this.amount,
    required this.count,
  });

  factory PaymentOrderTypeBreakdown.fromJson(Map<String, dynamic> json) {
    return PaymentOrderTypeBreakdown(
      orderType: json['orderType']?.toString() ?? 'other',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}

class PaymentsSummaryReportData {
  final ReportDateRange? range;
  final double totalCollected;
  final List<PaymentModeBreakdown> byMode;
  final List<PaymentOrderTypeBreakdown> byOrderType;

  const PaymentsSummaryReportData({
    this.range,
    required this.totalCollected,
    required this.byMode,
    required this.byOrderType,
  });

  factory PaymentsSummaryReportData.fromJson(Map<String, dynamic> json) {
    final modes = <PaymentModeBreakdown>[];
    if (json['byMode'] is List) {
      for (final m in json['byMode']) {
        if (m is Map<String, dynamic>) {
          modes.add(PaymentModeBreakdown.fromJson(m));
        }
      }
    }
    final orderTypes = <PaymentOrderTypeBreakdown>[];
    if (json['byOrderType'] is List) {
      for (final ot in json['byOrderType']) {
        if (ot is Map<String, dynamic>) {
          orderTypes.add(PaymentOrderTypeBreakdown.fromJson(ot));
        }
      }
    }
    return PaymentsSummaryReportData(
      range: json['range'] is Map<String, dynamic>
          ? ReportDateRange.fromJson(json['range'])
          : null,
      totalCollected: (json['totalCollected'] as num?)?.toDouble() ?? 0.0,
      byMode: modes,
      byOrderType: orderTypes,
    );
  }

  double get splitAmount {
    for (final m in byMode) {
      if (m.mode.toLowerCase() == 'split') return m.amount;
    }
    return 0.0;
  }

  double get unpaidAmount {
    for (final m in byMode) {
      if (m.mode.toLowerCase() == 'unpaid') return m.amount;
    }
    return 0.0;
  }
}

/// #158 GET /gst-summary
class GstBillItem {
  final String billNo;
  final String orderNo;
  final DateTime? paidAt;
  final double subTotal;
  final double discountAmount;
  final double taxableValue;
  final double cgst;
  final double sgst;
  final double grandTotal;

  const GstBillItem({
    required this.billNo,
    required this.orderNo,
    this.paidAt,
    required this.subTotal,
    required this.discountAmount,
    required this.taxableValue,
    required this.cgst,
    required this.sgst,
    required this.grandTotal,
  });

  factory GstBillItem.fromJson(Map<String, dynamic> json) {
    return GstBillItem(
      billNo: json['billNo']?.toString() ?? '',
      orderNo: json['orderNo']?.toString() ?? '',
      paidAt: json['paidAt'] != null ? DateTime.tryParse(json['paidAt'].toString()) : null,
      subTotal: (json['subTotal'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0.0,
      taxableValue: (json['taxableValue'] as num?)?.toDouble() ?? 0.0,
      cgst: (json['cgst'] as num?)?.toDouble() ?? 0.0,
      sgst: (json['sgst'] as num?)?.toDouble() ?? 0.0,
      grandTotal: (json['grandTotal'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class GstSummaryReportData {
  final ReportDateRange? range;
  final double gstRatePercent;
  final double taxableValue;
  final double cgst;
  final double sgst;
  final double totalGST;
  final int page;
  final int limit;
  final int total;
  final List<GstBillItem> bills;

  const GstSummaryReportData({
    this.range,
    required this.gstRatePercent,
    required this.taxableValue,
    required this.cgst,
    required this.sgst,
    required this.totalGST,
    required this.page,
    required this.limit,
    required this.total,
    required this.bills,
  });

  factory GstSummaryReportData.fromJson(Map<String, dynamic> json) {
    final billList = <GstBillItem>[];
    if (json['bills'] is List) {
      for (final b in json['bills']) {
        if (b is Map<String, dynamic>) {
          billList.add(GstBillItem.fromJson(b));
        }
      }
    }
    return GstSummaryReportData(
      range: json['range'] is Map<String, dynamic>
          ? ReportDateRange.fromJson(json['range'])
          : null,
      gstRatePercent: (json['gstRatePercent'] as num?)?.toDouble() ?? 5.0,
      taxableValue: (json['taxableValue'] as num?)?.toDouble() ?? 0.0,
      cgst: (json['cgst'] as num?)?.toDouble() ?? 0.0,
      sgst: (json['sgst'] as num?)?.toDouble() ?? 0.0,
      totalGST: (json['totalGST'] as num?)?.toDouble() ?? 0.0,
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 50,
      total: (json['total'] as num?)?.toInt() ?? 0,
      bills: billList,
    );
  }

  int get totalPages {
    if (limit <= 0) return 1;
    return (total / limit).ceil();
  }
}
