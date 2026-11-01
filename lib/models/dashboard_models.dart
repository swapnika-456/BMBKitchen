// Strongly typed models for Module 25: Dashboard (#159 - #165)
// Based strictly on verbatim live server responses from /api/dashboard/v1/:organizationId/:outletId

import 'report_models.dart';

class DashboardDeltaVsPrevious {
  final double? salesPercent;
  final double? ordersPercent;
  final double? avgBillPercent;
  final double? expensesPercent;

  const DashboardDeltaVsPrevious({
    this.salesPercent,
    this.ordersPercent,
    this.avgBillPercent,
    this.expensesPercent,
  });

  factory DashboardDeltaVsPrevious.fromJson(Map<String, dynamic> json) {
    return DashboardDeltaVsPrevious(
      salesPercent: (json['salesPercent'] as num?)?.toDouble(),
      ordersPercent: (json['ordersPercent'] as num?)?.toDouble(),
      avgBillPercent: (json['avgBillPercent'] as num?)?.toDouble(),
      expensesPercent: (json['expensesPercent'] as num?)?.toDouble(),
    );
  }
}

class DashboardSalesKpis {
  final ReportDateRange? range;
  final double totalSales;
  final int orders;
  final double avgBillValue;
  final double expenses;
  final DashboardDeltaVsPrevious? deltaVsPrevious;

  const DashboardSalesKpis({
    this.range,
    required this.totalSales,
    required this.orders,
    required this.avgBillValue,
    required this.expenses,
    this.deltaVsPrevious,
  });

  factory DashboardSalesKpis.fromJson(Map<String, dynamic> json) {
    return DashboardSalesKpis(
      range: json['range'] is Map<String, dynamic>
          ? ReportDateRange.fromJson(json['range'])
          : null,
      totalSales: (json['totalSales'] as num?)?.toDouble() ?? 0.0,
      orders: (json['orders'] as num?)?.toInt() ?? 0,
      avgBillValue: (json['avgBillValue'] as num?)?.toDouble() ?? 0.0,
      expenses: (json['expenses'] as num?)?.toDouble() ?? 0.0,
      deltaVsPrevious: json['deltaVsPrevious'] is Map<String, dynamic>
          ? DashboardDeltaVsPrevious.fromJson(json['deltaVsPrevious'])
          : null,
    );
  }
}

class DashboardTrendPoint {
  final String key;
  final double sales;
  final int orders;

  const DashboardTrendPoint({
    required this.key,
    required this.sales,
    required this.orders,
  });

  factory DashboardTrendPoint.fromJson(Map<String, dynamic> json) {
    return DashboardTrendPoint(
      key: json['key']?.toString() ?? '',
      sales: (json['sales'] as num?)?.toDouble() ?? 0.0,
      orders: (json['orders'] as num?)?.toInt() ?? 0,
    );
  }
}

class DashboardSalesTrend {
  final ReportDateRange? range;
  final String granularity; // 'hour' or 'day'
  final List<DashboardTrendPoint> points;

  const DashboardSalesTrend({
    this.range,
    required this.granularity,
    required this.points,
  });

  factory DashboardSalesTrend.fromJson(Map<String, dynamic> json) {
    final list = <DashboardTrendPoint>[];
    if (json['points'] is List) {
      for (final p in json['points']) {
        if (p is Map<String, dynamic>) {
          list.add(DashboardTrendPoint.fromJson(p));
        }
      }
    }
    return DashboardSalesTrend(
      range: json['range'] is Map<String, dynamic>
          ? ReportDateRange.fromJson(json['range'])
          : null,
      granularity: json['granularity']?.toString() ?? 'hour',
      points: list,
    );
  }
}

class DashboardKitchenTicketStatus {
  final ReportDateRange? range;
  final int completed;
  final int preparing;
  final int ready;
  final int cancelled;
  final int total;

  const DashboardKitchenTicketStatus({
    this.range,
    required this.completed,
    required this.preparing,
    required this.ready,
    required this.cancelled,
    required this.total,
  });

  factory DashboardKitchenTicketStatus.fromJson(Map<String, dynamic> json) {
    return DashboardKitchenTicketStatus(
      range: json['range'] is Map<String, dynamic>
          ? ReportDateRange.fromJson(json['range'])
          : null,
      completed: (json['completed'] as num?)?.toInt() ?? 0,
      preparing: (json['preparing'] as num?)?.toInt() ?? 0,
      ready: (json['ready'] as num?)?.toInt() ?? 0,
      cancelled: (json['cancelled'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? 0,
    );
  }
}

class DashboardTopItem {
  final String id;
  final String name;
  final int qty;
  final double amount;

  const DashboardTopItem({
    required this.id,
    required this.name,
    required this.qty,
    required this.amount,
  });

  factory DashboardTopItem.fromJson(Map<String, dynamic> json) {
    return DashboardTopItem(
      id: (json['_id'] ?? json['id'])?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown Item',
      qty: (json['qty'] as num?)?.toInt() ?? 0,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class DashboardTopSellingItems {
  final ReportDateRange? range;
  final List<DashboardTopItem> items;

  const DashboardTopSellingItems({
    this.range,
    required this.items,
  });

  factory DashboardTopSellingItems.fromJson(Map<String, dynamic> json) {
    final list = <DashboardTopItem>[];
    if (json['items'] is List) {
      for (final item in json['items']) {
        if (item is Map<String, dynamic>) {
          list.add(DashboardTopItem.fromJson(item));
        }
      }
    }
    return DashboardTopSellingItems(
      range: json['range'] is Map<String, dynamic>
          ? ReportDateRange.fromJson(json['range'])
          : null,
      items: list,
    );
  }
}

class DashboardPaymentMode {
  final String mode;
  final double amount;
  final double sharePercent;

  const DashboardPaymentMode({
    required this.mode,
    required this.amount,
    required this.sharePercent,
  });

  factory DashboardPaymentMode.fromJson(Map<String, dynamic> json) {
    return DashboardPaymentMode(
      mode: json['mode']?.toString() ?? 'unknown',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      sharePercent: (json['sharePercent'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class DashboardPaymentSummary {
  final ReportDateRange? range;
  final double totalCollected;
  final List<DashboardPaymentMode> byMode;

  const DashboardPaymentSummary({
    this.range,
    required this.totalCollected,
    required this.byMode,
  });

  factory DashboardPaymentSummary.fromJson(Map<String, dynamic> json) {
    final modes = <DashboardPaymentMode>[];
    if (json['byMode'] is List) {
      for (final m in json['byMode']) {
        if (m is Map<String, dynamic>) {
          modes.add(DashboardPaymentMode.fromJson(m));
        }
      }
    }
    return DashboardPaymentSummary(
      range: json['range'] is Map<String, dynamic>
          ? ReportDateRange.fromJson(json['range'])
          : null,
      totalCollected: (json['totalCollected'] as num?)?.toDouble() ?? 0.0,
      byMode: modes,
    );
  }
}

class DashboardOrderTypeItem {
  final String orderType;
  final double amount;
  final int orders;
  final double sharePercent;

  const DashboardOrderTypeItem({
    required this.orderType,
    required this.amount,
    required this.orders,
    required this.sharePercent,
  });

  factory DashboardOrderTypeItem.fromJson(Map<String, dynamic> json) {
    return DashboardOrderTypeItem(
      orderType: json['orderType']?.toString() ?? 'other',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      orders: (json['orders'] as num?)?.toInt() ?? 0,
      sharePercent: (json['sharePercent'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class DashboardSalesByOrderType {
  final ReportDateRange? range;
  final double totalSales;
  final List<DashboardOrderTypeItem> byOrderType;

  const DashboardSalesByOrderType({
    this.range,
    required this.totalSales,
    required this.byOrderType,
  });

  factory DashboardSalesByOrderType.fromJson(Map<String, dynamic> json) {
    final list = <DashboardOrderTypeItem>[];
    if (json['byOrderType'] is List) {
      for (final item in json['byOrderType']) {
        if (item is Map<String, dynamic>) {
          list.add(DashboardOrderTypeItem.fromJson(item));
        }
      }
    }
    return DashboardSalesByOrderType(
      range: json['range'] is Map<String, dynamic>
          ? ReportDateRange.fromJson(json['range'])
          : null,
      totalSales: (json['totalSales'] as num?)?.toDouble() ?? 0.0,
      byOrderType: list,
    );
  }
}

class DashboardQuickStats {
  final int tablesOccupied;
  final int tablesTotal;
  final int kitchenQueueCount;
  final int lowStockCount;
  final List<dynamic> lowStockPreview;
  final String dayClosingStatus;
  final double? dayClosingDifference;

  const DashboardQuickStats({
    required this.tablesOccupied,
    required this.tablesTotal,
    required this.kitchenQueueCount,
    required this.lowStockCount,
    required this.lowStockPreview,
    required this.dayClosingStatus,
    this.dayClosingDifference,
  });

  factory DashboardQuickStats.fromJson(Map<String, dynamic> json) {
    return DashboardQuickStats(
      tablesOccupied: (json['tablesOccupied'] as num?)?.toInt() ?? 0,
      tablesTotal: (json['tablesTotal'] as num?)?.toInt() ?? 0,
      kitchenQueueCount: (json['kitchenQueueCount'] as num?)?.toInt() ?? 0,
      lowStockCount: (json['lowStockCount'] as num?)?.toInt() ?? 0,
      lowStockPreview: json['lowStockPreview'] is List ? json['lowStockPreview'] : [],
      dayClosingStatus: json['dayClosingStatus']?.toString() ?? 'Pending',
      dayClosingDifference: (json['dayClosingDifference'] as num?)?.toDouble(),
    );
  }
}

/// #159 /summary complete dashboard payload
class DashboardSummaryData {
  final ReportDateRange? range;
  final DashboardSalesKpis salesKpis;
  final DashboardSalesTrend salesTrend;
  final DashboardKitchenTicketStatus kitchenTicketStatus;
  final DashboardTopSellingItems topSellingItems;
  final DashboardPaymentSummary paymentSummary;
  final DashboardSalesByOrderType? salesByOrderType;
  final DashboardQuickStats quickStats;

  const DashboardSummaryData({
    this.range,
    required this.salesKpis,
    required this.salesTrend,
    required this.kitchenTicketStatus,
    required this.topSellingItems,
    required this.paymentSummary,
    this.salesByOrderType,
    required this.quickStats,
  });

  factory DashboardSummaryData.fromJson(Map<String, dynamic> json) {
    return DashboardSummaryData(
      range: json['range'] is Map<String, dynamic>
          ? ReportDateRange.fromJson(json['range'])
          : null,
      salesKpis: json['salesKpis'] is Map<String, dynamic>
          ? DashboardSalesKpis.fromJson(json['salesKpis'])
          : const DashboardSalesKpis(
              totalSales: 0, orders: 0, avgBillValue: 0, expenses: 0),
      salesTrend: json['salesTrend'] is Map<String, dynamic>
          ? DashboardSalesTrend.fromJson(json['salesTrend'])
          : const DashboardSalesTrend(granularity: 'hour', points: []),
      kitchenTicketStatus: json['kitchenTicketStatus'] is Map<String, dynamic>
          ? DashboardKitchenTicketStatus.fromJson(json['kitchenTicketStatus'])
          : const DashboardKitchenTicketStatus(
              completed: 0, preparing: 0, ready: 0, cancelled: 0, total: 0),
      topSellingItems: json['topSellingItems'] is Map<String, dynamic>
          ? DashboardTopSellingItems.fromJson(json['topSellingItems'])
          : const DashboardTopSellingItems(items: []),
      paymentSummary: json['paymentSummary'] is Map<String, dynamic>
          ? DashboardPaymentSummary.fromJson(json['paymentSummary'])
          : const DashboardPaymentSummary(totalCollected: 0, byMode: []),
      salesByOrderType: json['salesByOrderType'] is Map<String, dynamic>
          ? DashboardSalesByOrderType.fromJson(json['salesByOrderType'])
          : null,
      quickStats: json['quickStats'] is Map<String, dynamic>
          ? DashboardQuickStats.fromJson(json['quickStats'])
          : const DashboardQuickStats(
              tablesOccupied: 0,
              tablesTotal: 0,
              kitchenQueueCount: 0,
              lowStockCount: 0,
              lowStockPreview: [],
              dayClosingStatus: 'Pending'),
    );
  }
}
