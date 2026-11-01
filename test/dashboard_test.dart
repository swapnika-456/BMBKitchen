import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bmb_kitchen/models/dashboard_models.dart';
import 'package:bmb_kitchen/models/outlet.dart';
import 'package:bmb_kitchen/models/report_models.dart';
import 'package:bmb_kitchen/features/dashboard/controllers/dashboard_controller.dart';
import 'package:bmb_kitchen/features/dashboard/screens/dashboard_screen.dart';
import 'package:bmb_kitchen/features/settings/controllers/active_outlet_provider.dart';

final mockDashboardSummary = DashboardSummaryData(
  range: ReportDateRange(
    from: DateTime(2026, 10, 23, 18, 30),
    to: DateTime(2026, 10, 24, 18, 29, 59, 999),
  ),
  salesKpis: const DashboardSalesKpis(
    totalSales: 731.0,
    orders: 7,
    avgBillValue: 104.43,
    expenses: 0.0,
    deltaVsPrevious: DashboardDeltaVsPrevious(
      salesPercent: 12.5,
      ordersPercent: 5.0,
      avgBillPercent: 7.2,
      expensesPercent: 0.0,
    ),
  ),
  salesTrend: const DashboardSalesTrend(
    granularity: 'hour',
    points: [
      DashboardTrendPoint(key: '10', sales: 290.0, orders: 3),
      DashboardTrendPoint(key: '12', sales: 441.0, orders: 4),
    ],
  ),
  kitchenTicketStatus: const DashboardKitchenTicketStatus(
    completed: 3,
    preparing: 12,
    ready: 0,
    cancelled: 3,
    total: 18,
  ),
  topSellingItems: const DashboardTopSellingItems(
    items: [
      DashboardTopItem(
        id: 'item_1',
        name: 'THROWAWAY_ORDER_TEST_ITEM',
        qty: 7,
        amount: 700.0,
      ),
    ],
  ),
  paymentSummary: const DashboardPaymentSummary(
    totalCollected: 731.0,
    byMode: [
      DashboardPaymentMode(mode: 'cash', amount: 310.5, sharePercent: 42.5),
      DashboardPaymentMode(mode: 'split', amount: 210.25, sharePercent: 28.8),
      DashboardPaymentMode(mode: 'unpaid', amount: 210.25, sharePercent: 28.8),
    ],
  ),
  salesByOrderType: const DashboardSalesByOrderType(
    totalSales: 731.0,
    byOrderType: [
      DashboardOrderTypeItem(
        orderType: 'takeaway',
        amount: 530.75,
        orders: 5,
        sharePercent: 72.6,
      ),
      DashboardOrderTypeItem(
        orderType: 'dine_in',
        amount: 200.25,
        orders: 2,
        sharePercent: 27.4,
      ),
    ],
  ),
  quickStats: const DashboardQuickStats(
    tablesOccupied: 0,
    tablesTotal: 1,
    kitchenQueueCount: 6,
    lowStockCount: 0,
    lowStockPreview: [],
    dayClosingStatus: 'Pending',
    dayClosingDifference: null,
  ),
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

Widget createTestWidget({
  required DashboardState dashboardState,
  Size size = const Size(800, 600),
  double textScale = 1.0,
}) {
  return ProviderScope(
    overrides: [
      activeOutletProvider.overrideWithValue(mockOutlet),
      dashboardControllerProvider.overrideWith(
        () => _TestDashboardController(dashboardState),
      ),
    ],
    child: MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
        ),
        child: const DashboardScreen(),
      ),
    ),
  );
}

class _TestDashboardController extends DashboardController {
  final DashboardState _initialState;
  _TestDashboardController(this._initialState);

  @override
  DashboardState build() {
    return _initialState;
  }

  @override
  Future<void> refresh() async {}

  @override
  Future<void> setScope(String scope) async {
    state = AsyncValue.data(
      state.value!.copyWith(
        filter: state.value!.filter.copyWith(scope: scope),
      ),
    );
  }
}

void main() {
  group('Module 25: Dashboard Models Deserialization Tests', () {
    test('DashboardSummaryData.fromJson parses server data correctly', () {
      final json = {
        'range': {
          'from': '2026-10-23T18:30:00.000Z',
          'to': '2026-10-24T18:29:59.999Z',
        },
        'salesKpis': {
          'totalSales': 731,
          'orders': 7,
          'avgBillValue': 104.42857142857143,
          'expenses': 0,
          'deltaVsPrevious': {
            'salesPercent': 15.0,
            'ordersPercent': 10.0,
            'avgBillPercent': 4.5,
            'expensesPercent': null,
          },
        },
        'salesTrend': {
          'granularity': 'hour',
          'points': [
            {'key': '10', 'sales': 290, 'orders': 3},
            {'key': '12', 'sales': 441, 'orders': 4},
          ],
        },
        'kitchenTicketStatus': {
          'completed': 3,
          'preparing': 12,
          'ready': 0,
          'cancelled': 3,
          'total': 18,
        },
        'topSellingItems': {
          'items': [
            {
              '_id': '6adc342588e080704d1fb5b0',
              'name': 'THROWAWAY_ORDER_TEST_ITEM',
              'qty': 7,
              'amount': 700,
            }
          ],
        },
        'paymentSummary': {
          'totalCollected': 731,
          'byMode': [
            {'mode': 'cash', 'amount': 310.5, 'sharePercent': 42.5},
            {'mode': 'split', 'amount': 210.25, 'sharePercent': 28.8},
            {'mode': 'unpaid', 'amount': 210.25, 'sharePercent': 28.8},
          ],
        },
        'salesByOrderType': {
          'totalSales': 731,
          'byOrderType': [
            {
              'orderType': 'takeaway',
              'amount': 530.75,
              'orders': 5,
              'sharePercent': 72.6,
            },
            {
              'orderType': 'dine_in',
              'amount': 200.25,
              'orders': 2,
              'sharePercent': 27.4,
            },
          ],
        },
        'quickStats': {
          'tablesOccupied': 0,
          'tablesTotal': 1,
          'kitchenQueueCount': 6,
          'lowStockCount': 0,
          'lowStockPreview': [],
          'dayClosingStatus': 'Pending',
          'dayClosingDifference': null,
        },
      };

      final data = DashboardSummaryData.fromJson(json);
      expect(data.salesKpis.totalSales, 731.0);
      expect(data.salesKpis.orders, 7);
      expect(data.salesKpis.avgBillValue, closeTo(104.43, 0.01));
      expect(data.salesKpis.deltaVsPrevious?.salesPercent, 15.0);

      expect(data.salesTrend.granularity, 'hour');
      expect(data.salesTrend.points.length, 2);

      expect(data.kitchenTicketStatus.completed, 3);
      expect(data.kitchenTicketStatus.preparing, 12);
      expect(data.kitchenTicketStatus.cancelled, 3);
      expect(data.kitchenTicketStatus.total, 18);

      expect(data.topSellingItems.items.length, 1);
      expect(data.topSellingItems.items.first.name, 'THROWAWAY_ORDER_TEST_ITEM');
      expect(data.topSellingItems.items.first.qty, 7);

      expect(data.paymentSummary.totalCollected, 731.0);
      expect(data.paymentSummary.byMode.length, 3);

      expect(data.salesByOrderType?.byOrderType.length, 2);
      expect(data.salesByOrderType?.byOrderType.first.orderType, 'takeaway');

      expect(data.quickStats.tablesTotal, 1);
      expect(data.quickStats.kitchenQueueCount, 6);
      expect(data.quickStats.dayClosingStatus, 'Pending');
    });
  });

  group('Module 25: DashboardScreen Widget Tests', () {
    testWidgets('Renders Quick-Stats 4 tiles and KPIs correctly', (tester) async {
      final state = DashboardState(
        summary: mockDashboardSummary,
      );

      await tester.pumpWidget(createTestWidget(dashboardState: state));
      await tester.pumpAndSettle();

      // Quick-stat tiles
      expect(find.byKey(const Key('quick_stat_tables')), findsOneWidget);
      expect(find.byKey(const Key('quick_stat_kitchen_queue')), findsOneWidget);
      expect(find.byKey(const Key('quick_stat_low_stock')), findsOneWidget);
      expect(find.byKey(const Key('quick_stat_day_closing')), findsOneWidget);
      expect(find.text('0/1'), findsOneWidget);
      expect(find.text('6'), findsOneWidget);

      // KPI tiles
      expect(find.text('Total Sales'), findsOneWidget);
      expect(find.text('₹731'), findsWidgets);
      expect(find.text('Orders Count'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
      expect(find.text('Average Bill'), findsOneWidget);
      expect(find.text('₹104.43'), findsOneWidget);
    });

    testWidgets('Renders Kitchen Tickets and Top Items sections', (tester) async {
      final state = DashboardState(
        summary: mockDashboardSummary,
      );

      await tester.pumpWidget(createTestWidget(dashboardState: state));
      await tester.pumpAndSettle();

      expect(find.text('Kitchen Tickets Status'), findsOneWidget);
      expect(find.text('18 total'), findsOneWidget);
      expect(find.text('Top-Selling Items'), findsOneWidget);
      expect(find.text('THROWAWAY_ORDER_TEST_ITEM'), findsOneWidget);
      expect(find.text('7 portions sold'), findsOneWidget);
    });

    testWidgets('Renders Payment Summary and Order Types breakdown', (tester) async {
      final state = DashboardState(
        summary: mockDashboardSummary,
      );

      await tester.pumpWidget(createTestWidget(dashboardState: state));
      await tester.pumpAndSettle();

      expect(find.text('Payment Collections'), findsOneWidget);
      expect(find.text('CASH'), findsOneWidget);
      expect(find.text('SPLIT'), findsOneWidget);
      expect(find.text('UNPAID'), findsOneWidget);
      expect(find.text('Sales by Order Type'), findsOneWidget);
      expect(find.text('TAKEAWAY'), findsOneWidget);
      expect(find.text('DINE_IN'), findsOneWidget);
    });

    testWidgets('Renders Empty state when sales and orders are 0', (tester) async {
      const emptySummary = DashboardSummaryData(
        salesKpis: DashboardSalesKpis(
          totalSales: 0.0,
          orders: 0,
          avgBillValue: 0.0,
          expenses: 0.0,
        ),
        salesTrend: DashboardSalesTrend(granularity: 'hour', points: []),
        kitchenTicketStatus: DashboardKitchenTicketStatus(
          completed: 0,
          preparing: 0,
          ready: 0,
          cancelled: 0,
          total: 0,
        ),
        topSellingItems: DashboardTopSellingItems(items: []),
        paymentSummary: DashboardPaymentSummary(totalCollected: 0.0, byMode: []),
        quickStats: DashboardQuickStats(
          tablesOccupied: 0,
          tablesTotal: 1,
          kitchenQueueCount: 0,
          lowStockCount: 0,
          lowStockPreview: [],
          dayClosingStatus: 'Pending',
        ),
      );

      final state = const DashboardState(summary: emptySummary);

      await tester.pumpWidget(createTestWidget(dashboardState: state));
      await tester.pumpAndSettle();

      expect(find.text('No sales in this period'), findsOneWidget);
      expect(
        find.text('Switch to another date scope or record orders via POS.'),
        findsOneWidget,
      );
    });

    testWidgets('Viewport responsiveness: Mobile portrait (360x800) does not overflow',
        (tester) async {
      final state = DashboardState(summary: mockDashboardSummary);

      await tester.pumpWidget(createTestWidget(
        dashboardState: state,
        size: const Size(360, 800),
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Dashboard'), findsOneWidget);
    });

    testWidgets('Viewport responsiveness: Mobile landscape (800x360) does not overflow',
        (tester) async {
      final state = DashboardState(summary: mockDashboardSummary);

      await tester.pumpWidget(createTestWidget(
        dashboardState: state,
        size: const Size(800, 360),
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Dashboard'), findsOneWidget);
    });

    testWidgets('Viewport responsiveness: 1.5x font scale does not overflow',
        (tester) async {
      final state = DashboardState(summary: mockDashboardSummary);

      await tester.pumpWidget(createTestWidget(
        dashboardState: state,
        size: const Size(360, 800),
        textScale: 1.5,
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Dashboard'), findsOneWidget);
    });

    testWidgets('Viewport responsiveness: Desktop layout (1280x800) does not overflow',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final state = DashboardState(summary: mockDashboardSummary);

      await tester.pumpWidget(createTestWidget(
        dashboardState: state,
        size: const Size(1280, 800),
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Payment Collections'), findsOneWidget);
      expect(find.text('Kitchen Tickets Status'), findsOneWidget);
    });
  });
}
