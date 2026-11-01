import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bmb_kitchen/models/outlet.dart';
import 'package:bmb_kitchen/models/report_models.dart';
import 'package:bmb_kitchen/models/user.dart';
import 'package:bmb_kitchen/features/auth/controllers/auth_controller.dart';
import 'package:bmb_kitchen/features/finance/controllers/reports_controller.dart';
import 'package:bmb_kitchen/features/finance/screens/reports_screen.dart';
import 'package:bmb_kitchen/features/settings/controllers/outlet_controller.dart';
import 'package:bmb_kitchen/services/api/menu_item_api_service.dart';

// Test Data
final mockSalesReport = SalesReportData(
  range: ReportDateRange(
    from: DateTime(2026, 10, 23, 18, 30),
    to: DateTime(2026, 10, 24, 18, 29, 59, 999),
  ),
  grossSales: 731.0,
  taxableValue: 690.0,
  totalDiscounts: 10.0,
  totalGST: 21.0,
  totalBills: 7,
  avgBillValue: 104.43,
  cancelledOrders: 3,
  orderTypeSplit: const {
    'takeaway': OrderTypeStat(amount: 530.75, count: 5),
    'dine_in': OrderTypeStat(amount: 200.25, count: 2),
  },
  dailyTrend: const [
    DailyTrendItem(date: '2026-10-24', sales: 731.0, bills: 7),
  ],
);

final mockItemsReport = ItemsReportData(
  range: ReportDateRange(
    from: DateTime(2026, 10, 23, 18, 30),
    to: DateTime(2026, 10, 24, 18, 29, 59, 999),
  ),
  items: const [
    ReportItemRanking(
      rank: 1,
      menuItemId: 'item_101',
      name: 'Paneer Butter Masala',
      qtySold: 7,
      revenue: 700.0,
      sharePercent: 100.0,
    ),
  ],
);

final mockPaymentsReport = PaymentsSummaryReportData(
  range: ReportDateRange(
    from: DateTime(2026, 10, 23, 18, 30),
    to: DateTime(2026, 10, 24, 18, 29, 59, 999),
  ),
  totalCollected: 731.0,
  byMode: const [
    PaymentModeBreakdown(mode: 'cash', amount: 310.5, count: 3, sharePercent: 42.5),
    PaymentModeBreakdown(mode: 'split', amount: 210.25, count: 2, sharePercent: 28.8),
    PaymentModeBreakdown(mode: 'unpaid', amount: 210.25, count: 2, sharePercent: 28.8),
  ],
  byOrderType: const [
    PaymentOrderTypeBreakdown(orderType: 'takeaway', amount: 530.75, count: 5),
    PaymentOrderTypeBreakdown(orderType: 'dine_in', amount: 200.25, count: 2),
  ],
);

final mockGstReport = GstSummaryReportData(
  range: ReportDateRange(
    from: DateTime(2026, 10, 23, 18, 30),
    to: DateTime(2026, 10, 24, 18, 29, 59, 999),
  ),
  gstRatePercent: 5.0,
  taxableValue: 690.0,
  cgst: 10.5,
  sgst: 10.5,
  totalGST: 21.0,
  page: 1,
  limit: 50,
  total: 7,
  bills: [
    GstBillItem(
      billNo: 'BILL-2026-0007',
      orderNo: 'ORD-2026-0015',
      paidAt: DateTime(2026, 10, 24, 12, 45),
      subTotal: 100.0,
      discountAmount: 0.0,
      taxableValue: 100.0,
      cgst: 2.625,
      sgst: 2.625,
      grandTotal: 110.25,
    ),
  ],
);

final mockExpensesReport = ExpensesReportData(
  range: ReportDateRange(
    from: DateTime(2026, 10, 23, 18, 30),
    to: DateTime(2026, 10, 24, 18, 29, 59, 999),
  ),
  totalExpenses: 0.0,
  totalEntries: 0,
  byCategory: const [],
  byPaymentMode: const [],
);

final mockOwnerUser = User(
  id: 'user_owner',
  name: 'Owner User',
  email: 'owner@bmb.com',
  role: 'owner',
  organizationId: 'org_test_1',
  isActive: true,
);

final mockStaffUser = User(
  id: 'user_staff',
  name: 'Staff User',
  email: 'staff@bmb.com',
  role: 'staff',
  organizationId: 'org_test_1',
  isActive: true,
);

final mockOutlet = Outlet(
  id: 'out_1',
  organizationId: 'org_test_1',
  name: 'Main Outlet',
  code: 'OUT-1',
  address: 'Test address',
  phone: '1234567890',
  isActive: true,
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
);

class _TestAuthController extends AuthController {
  final User? _user;
  _TestAuthController(this._user);

  @override
  Future<User?> build() async => _user;
}

class _TestOutletController extends OutletController {
  @override
  Future<List<Outlet>> build() async => [mockOutlet];
}

class _FakeReportsController extends ReportsController {
  final ReportsState _initialState;
  _FakeReportsController(this._initialState);

  @override
  Future<ReportsState> build() async => _initialState;

  @override
  Future<void> setTab(int tab) async {
    state = AsyncValue.data(state.value!.copyWith(
      filter: state.value!.filter.copyWith(selectedTab: tab),
    ));
  }

  @override
  Future<void> setScope(String scope) async {
    state = AsyncValue.data(state.value!.copyWith(
      filter: state.value!.filter.copyWith(scope: scope),
    ));
  }
}

Widget createTestWidget({
  required User? user,
  required ReportsState reportsState,
  Size size = const Size(1024, 768),
  double textScale = 1.0,
}) {
  return ProviderScope(
    overrides: [
      authControllerProvider.overrideWith(() => _TestAuthController(user)),
      outletControllerProvider.overrideWith(() => _TestOutletController()),
      reportsControllerProvider
          .overrideWith(() => _FakeReportsController(reportsState)),
    ],
    child: MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
        ),
        child: const Scaffold(
          body: ReportsScreen(),
        ),
      ),
    ),
  );
}

void main() {
  group('Module 22: Report Models Deserialization Tests', () {
    test('SalesReportData.fromJson parses server data correctly', () {
      final json = {
        'range': {
          'from': '2026-10-23T18:30:00.000Z',
          'to': '2026-10-24T18:29:59.999Z',
        },
        'grossSales': 731,
        'taxableValue': 690,
        'totalDiscounts': 10,
        'totalGST': 21,
        'totalBills': 7,
        'avgBillValue': 104.42857142857143,
        'cancelledOrders': 3,
        'orderTypeSplit': {
          'takeaway': {'amount': 530.75, 'count': 5},
          'dine_in': {'amount': 200.25, 'count': 2},
        },
        'dailyTrend': [
          {'date': '2026-10-24', 'sales': 731, 'bills': 7},
        ],
      };

      final data = SalesReportData.fromJson(json);
      expect(data.grossSales, 731.0);
      expect(data.taxableValue, 690.0);
      expect(data.totalDiscounts, 10.0);
      expect(data.totalGST, 21.0);
      expect(data.totalBills, 7);
      expect(data.cancelledOrders, 3);
      expect(data.orderTypeSplit['takeaway']?.amount, 530.75);
      expect(data.orderTypeSplit['takeaway']?.count, 5);
      expect(data.dailyTrend.length, 1);
      expect(data.dailyTrend.first.sales, 731.0);
    });

    test('ItemsReportData.fromJson parses item leaderboard correctly', () {
      final json = {
        'range': {'from': '2026-10-23T18:30:00.000Z', 'to': '2026-10-24T18:29:59.999Z'},
        'items': [
          {
            'rank': 1,
            'menuItemId': '6adc342588e080704d1fb5b0',
            'name': 'THROWAWAY_ORDER_TEST_ITEM',
            'qtySold': 7,
            'revenue': 700,
            'sharePercent': 100,
          }
        ],
      };

      final data = ItemsReportData.fromJson(json);
      expect(data.items.length, 1);
      final item = data.items.first;
      expect(item.rank, 1);
      expect(item.name, 'THROWAWAY_ORDER_TEST_ITEM');
      expect(item.qtySold, 7);
      expect(item.revenue, 700.0);
      expect(item.sharePercent, 100.0);
    });

    test('PaymentsSummaryReportData.fromJson calculates split and unpaid amounts', () {
      final json = {
        'range': {'from': '2026-10-23T18:30:00.000Z', 'to': '2026-10-24T18:29:59.999Z'},
        'totalCollected': 731,
        'byMode': [
          {'mode': 'cash', 'amount': 310.5, 'count': 3, 'sharePercent': 42.5},
          {'mode': 'split', 'amount': 210.25, 'count': 2, 'sharePercent': 28.8},
          {'mode': 'unpaid', 'amount': 210.25, 'count': 2, 'sharePercent': 28.8},
        ],
        'byOrderType': [
          {'orderType': 'takeaway', 'amount': 530.75, 'count': 5},
          {'orderType': 'dine_in', 'amount': 200.25, 'count': 2},
        ],
      };

      final data = PaymentsSummaryReportData.fromJson(json);
      expect(data.totalCollected, 731.0);
      expect(data.splitAmount, 210.25);
      expect(data.unpaidAmount, 210.25);
      expect(data.byMode.length, 3);
      expect(data.byOrderType.length, 2);
    });

    test('GstSummaryReportData.fromJson handles pagination calculations', () {
      final json = {
        'gstRatePercent': 5,
        'taxableValue': 690,
        'cgst': 10.5,
        'sgst': 10.5,
        'totalGST': 21,
        'page': 1,
        'limit': 50,
        'total': 7,
        'bills': [
          {
            'billNo': 'BILL-2026-0007',
            'orderNo': 'ORD-2026-0015',
            'paidAt': '2026-10-24T07:15:34.562Z',
            'subTotal': 100,
            'discountAmount': 0,
            'taxableValue': 100,
            'cgst': 2.625,
            'sgst': 2.625,
            'grandTotal': 110.25,
          }
        ],
      };

      final data = GstSummaryReportData.fromJson(json);
      expect(data.taxableValue, 690.0);
      expect(data.totalGST, 21.0);
      expect(data.page, 1);
      expect(data.total, 7);
      expect(data.totalPages, 1);
      expect(data.bills.length, 1);
      expect(data.bills.first.billNo, 'BILL-2026-0007');
    });

    test('ExpensesReportData.fromJson handles empty expenses schema', () {
      final json = {
        'totalExpenses': 0,
        'totalEntries': 0,
        'byCategory': [],
        'byPaymentMode': [],
      };

      final data = ExpensesReportData.fromJson(json);
      expect(data.totalExpenses, 0.0);
      expect(data.totalEntries, 0);
      expect(data.byCategory, isEmpty);
      expect(data.byPaymentMode, isEmpty);
    });

    test('MenuItemApiService.normalizeFoodType enforces strict allowed strings', () {
      expect(MenuItemApiService.normalizeFoodType('Veg'), 'Veg');
      expect(MenuItemApiService.normalizeFoodType('veg'), 'Veg');
      expect(MenuItemApiService.normalizeFoodType('Non-veg'), 'Non-veg');
      expect(MenuItemApiService.normalizeFoodType('nonveg'), 'Non-veg');
      expect(MenuItemApiService.normalizeFoodType('Non-Vegetarian'), 'Non-veg');
      expect(MenuItemApiService.normalizeFoodType('Egg'), 'Egg');
      expect(MenuItemApiService.normalizeFoodType('egg'), 'Egg');
      // Invalid/null falls back to Veg
      expect(MenuItemApiService.normalizeFoodType(null), 'Veg');
      expect(MenuItemApiService.normalizeFoodType('Seafood'), 'Veg');
      expect(MenuItemApiService.normalizeFoodType(''), 'Veg');
    });
  });

  group('Module 22: ReportsScreen Widget Tests', () {
    testWidgets('Renders header, filters, scope chips, and Sales tab for Owner',
        (tester) async {
      final state = ReportsState(
        filter: const ReportsFilter(selectedTab: 0, scope: 'today'),
        salesReport: mockSalesReport,
      );

      await tester.pumpWidget(createTestWidget(
        user: mockOwnerUser,
        reportsState: state,
      ));
      await tester.pumpAndSettle();

      // Header
      expect(find.text('Reports & Analytics'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('This Week'), findsOneWidget);
      expect(find.text('This Month'), findsOneWidget);

      // Tab Buttons
      expect(find.text('Sales Summary'), findsOneWidget);
      expect(find.text('Items Leaderboard'), findsOneWidget);
      expect(find.text('Payments Summary'), findsOneWidget);
      expect(find.text('GST Summary'), findsOneWidget);
      expect(find.text('Expenses'), findsOneWidget);

      // Exact server KPI values
      expect(find.text('₹731.00'), findsNWidgets(2)); // Gross Sales & Daily Trend
      expect(find.text('₹690.00'), findsOneWidget); // Taxable
      expect(find.text('₹21.00'), findsOneWidget); // Total GST
      expect(find.text('₹10.00'), findsOneWidget); // Total Discounts

      // Cancelled Orders & Order Breakdown
      expect(find.text('3'), findsOneWidget); // Cancelled orders
      expect(find.text('TAKEAWAY (5 orders)'), findsOneWidget);
      expect(find.text('₹530.75'), findsOneWidget);
      expect(find.text('DINE_IN (2 orders)'), findsOneWidget);
      expect(find.text('₹200.25'), findsOneWidget);
    });

    testWidgets('Renders Items tab with dish rankings and share percent',
        (tester) async {
      final state = ReportsState(
        filter: const ReportsFilter(selectedTab: 1),
        itemsReport: mockItemsReport,
      );

      await tester.pumpWidget(createTestWidget(
        user: mockOwnerUser,
        reportsState: state,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Dish Performance Rankings'), findsOneWidget);
      expect(find.text('Paneer Butter Masala'), findsOneWidget);
      expect(find.text('#1'), findsOneWidget);
      expect(find.text('7 portions'), findsOneWidget);
      expect(find.text('₹700.00'), findsOneWidget);
      expect(find.text('100.0% share'), findsOneWidget);
    });

    testWidgets('Renders Payments tab with split/unpaid notice', (tester) async {
      final state = ReportsState(
        filter: const ReportsFilter(selectedTab: 2),
        paymentsReport: mockPaymentsReport,
      );

      await tester.pumpWidget(createTestWidget(
        user: mockOwnerUser,
        reportsState: state,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Collection by Payment Mode'), findsOneWidget);
      expect(find.text('₹731.00'), findsOneWidget);

      // Note banner mentioning split and unpaid
      expect(
        find.textContaining('includes split payments (₹210.25) and unpaid balances (₹210.25)'),
        findsOneWidget,
      );

      expect(find.text('CASH (3 txns)'), findsOneWidget);
      expect(find.text('₹310.50'), findsOneWidget);
      expect(find.text('SPLIT (2 txns)'), findsOneWidget);
      expect(find.text('UNPAID (2 txns)'), findsOneWidget);
    });

    testWidgets('Renders GST Summary tab with bills table and pagination',
        (tester) async {
      final state = ReportsState(
        filter: const ReportsFilter(selectedTab: 3),
        gstReport: mockGstReport,
      );

      await tester.pumpWidget(createTestWidget(
        user: mockOwnerUser,
        reportsState: state,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Invoiced Bills (Filing Schedule)'), findsOneWidget);
      expect(find.text('BILL-2026-0007'), findsOneWidget);
      expect(find.text('ORD-2026-0015'), findsOneWidget);
      expect(find.text('₹110.25'), findsOneWidget);
      expect(find.text('Page 1 of 1'), findsOneWidget);
      expect(find.byKey(const Key('gst_prev_page')), findsOneWidget);
      expect(find.byKey(const Key('gst_next_page')), findsOneWidget);
    });

    testWidgets('Renders Expenses tab with categories and read-only notice',
        (tester) async {
      final state = ReportsState(
        filter: const ReportsFilter(selectedTab: 4),
        expensesReport: mockExpensesReport,
      );

      await tester.pumpWidget(createTestWidget(
        user: mockOwnerUser,
        reportsState: state,
      ));
      await tester.pumpAndSettle();

      expect(find.text('All Categories'), findsOneWidget);
      expect(find.text('Supplies'), findsOneWidget);
      expect(find.text('Utilities'), findsOneWidget);
      expect(find.text('Rent'), findsOneWidget);
      expect(find.text('Total Expenses'), findsOneWidget);
      expect(find.text('₹0.00'), findsOneWidget);
      expect(find.text('No expense records found'), findsOneWidget);
    });

    testWidgets('Staff role shows No access restricted view', (tester) async {
      final state = ReportsState(
        filter: const ReportsFilter(selectedTab: 0),
        salesReport: mockSalesReport,
      );

      await tester.pumpWidget(createTestWidget(
        user: mockStaffUser,
        reportsState: state,
      ));
      await tester.pumpAndSettle();

      expect(find.text('No access'), findsOneWidget);
      expect(
        find.text(
          'Staff members do not have access to Reports & Analytics.\n'
          'Only Organization Owners, Admins, and CTOs can view financial reports.',
        ),
        findsOneWidget,
      );
      expect(find.text('Gross Sales'), findsNothing);
    });

    testWidgets('Viewport responsiveness: Mobile portrait (360x800) does not overflow',
        (tester) async {
      final state = ReportsState(
        filter: const ReportsFilter(selectedTab: 0),
        salesReport: mockSalesReport,
      );

      await tester.pumpWidget(createTestWidget(
        user: mockOwnerUser,
        reportsState: state,
        size: const Size(360, 800),
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Reports & Analytics'), findsOneWidget);
    });

    testWidgets('Viewport responsiveness: Mobile landscape (800x360) does not overflow',
        (tester) async {
      final state = ReportsState(
        filter: const ReportsFilter(selectedTab: 0),
        salesReport: mockSalesReport,
      );

      await tester.pumpWidget(createTestWidget(
        user: mockOwnerUser,
        reportsState: state,
        size: const Size(800, 360),
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Reports & Analytics'), findsOneWidget);
    });

    testWidgets('Viewport responsiveness: 1.5x font scale does not overflow',
        (tester) async {
      final state = ReportsState(
        filter: const ReportsFilter(selectedTab: 0),
        salesReport: mockSalesReport,
      );

      await tester.pumpWidget(createTestWidget(
        user: mockOwnerUser,
        reportsState: state,
        size: const Size(360, 800),
        textScale: 1.5,
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Reports & Analytics'), findsOneWidget);
    });
  });
}
