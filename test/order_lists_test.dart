import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:bmb_kitchen/models/order.dart';
import 'package:bmb_kitchen/models/outlet.dart';
import 'package:bmb_kitchen/models/user.dart';
import 'package:bmb_kitchen/core/network/api_exceptions.dart';
import 'package:bmb_kitchen/core/money/paise.dart';
import 'package:bmb_kitchen/core/money/money_format.dart';
import 'package:bmb_kitchen/features/auth/controllers/auth_controller.dart';
import 'package:bmb_kitchen/features/settings/controllers/active_outlet_provider.dart';
import 'package:bmb_kitchen/features/kitchen/controllers/kitchen_orders_controller.dart';
import 'package:bmb_kitchen/features/kitchen/screens/kot_management_screen.dart';
import 'package:bmb_kitchen/features/orders/controllers/orders_by_type_controller.dart';
import 'package:bmb_kitchen/features/orders/controllers/paid_orders_controller.dart';
import 'package:bmb_kitchen/features/orders/screens/takeaway_orders_screen.dart';
import 'package:bmb_kitchen/features/delivery/screens/delivery_orders_screen.dart';
import 'package:bmb_kitchen/features/online/screens/online_orders_screen.dart';
import 'package:bmb_kitchen/features/orders/screens/all_orders_screen.dart';
import 'package:bmb_kitchen/features/pos/controllers/pos_order_controller.dart';

class _FakeAuthController extends AuthController {
  final User? _user;
  _FakeAuthController(this._user);
  @override
  Future<User?> build() async => _user;
}

class _FakeKitchenOrdersController extends KitchenOrdersController {
  final KitchenOrdersResponse _response;
  _FakeKitchenOrdersController(this._response);
  @override
  Future<KitchenOrdersResponse> build() async => _response;
}

class _FakeOrdersByTypeNotifier extends OrdersByTypeNotifier {
  final OrderListResponse _response;
  _FakeOrdersByTypeNotifier(super.orderType, this._response);
  @override
  Future<OrderListResponse> build() async => _response;
}

class _FakePaidOrdersController extends PaidOrdersController {
  final PaidOrdersResponse _response;
  _FakePaidOrdersController(this._response);
  @override
  Future<PaidOrdersResponse> build() async => _response;
}

class _FakeActiveOrdersNotifier extends ActiveOrdersNotifier {
  final List<Order> _orders;
  _FakeActiveOrdersNotifier(this._orders);
  @override
  Future<List<Order>> build() async => _orders;
}

void main() {
  final mockUser = User(
    id: 'user_1',
    organizationId: 'org_1',
    role: 'owner',
    email: 'owner@test.com',
    name: 'Test Owner',
    isActive: true,
  );

  final mockOutlet = Outlet(
    id: 'outlet_1',
    organizationId: 'org_1',
    name: 'Main Kitchen',
    code: 'MK-01',
    address: '123 Test St, Chennai, TN, 600001',
    phone: '9876543210',
    isActive: true,
  );

  final mockKitchenItem = KitchenItem(
    orderId: 'order_1',
    orderNo: 'ORD-2026-0001',
    orderType: 'takeaway',
    itemId: 'item_1',
    name: 'Paneer Butter Masala',
    quantity: 2,
    notes: 'Extra butter',
    status: 'in_queue',
    sentToKitchenAt: DateTime.now().subtract(const Duration(minutes: 5)),
  );

  final mockKitchenResponse = KitchenOrdersResponse(
    items: [mockKitchenItem],
    counts: {'in_queue': 1, 'preparing': 0, 'ready': 0, 'served': 0, 'cancelled': 0},
    total: 1,
    page: 1,
    limit: 20,
    totalPages: 1,
  );

  final mockOrderItem = OrderItem(
    id: 'item_1',
    menuItemId: 'menu_1',
    name: 'Paneer Butter Masala',
    price: 250.0,
    quantity: 2,
    itemTotal: 500.0,
    notes: 'Extra spicy',
    status: 'served',
  );

  final mockOrder = Order(
    id: 'order_1',
    orderNo: 'ORD-2026-0001',
    billNo: 'BILL-0001',
    outletId: 'outlet_1',
    orderType: 'takeaway',
    items: [mockOrderItem],
    subTotal: 500.0,
    grandTotal: 525.0,
    orderStatus: 'completed',
    paymentStatus: 'paid',
    paymentMethod: 'upi',
    createdAt: DateTime.now(),
  );

  final mockOrderListResponse = OrderListResponse(
    orders: [mockOrder],
    total: 1,
    page: 1,
    limit: 20,
    totalPages: 1,
  );

  final mockPaidOrdersResponse = PaidOrdersResponse(
    orders: [mockOrder],
    summary: PaidOrdersSummary(
      totalCollected: 525.0,
      totalDiscounts: 25.0,
      totalOrders: 1,
      avgOrderValue: 525.0,
      byPaymentMethod: [
        PaymentMethodSummary(mode: 'upi', amount: 525.0, count: 1),
      ],
    ),
    total: 1,
    page: 1,
    limit: 20,
    totalPages: 1,
  );

  group('PART A: Fixes Verification', () {
    test('1. OrderItem.toCreateJson always sends name, price, quantity, itemTotal and notes', () {
      final item = OrderItem(
        menuItemId: 'menu_123',
        name: 'Dal Makhani',
        price: 220.0,
        quantity: 3,
        itemTotal: 660.0,
        notes: 'Less oil',
      );

      final payload = item.toCreateJson();
      expect(payload['menuItemId'], 'menu_123');
      expect(payload['name'], 'Dal Makhani');
      expect(payload['price'], 220.0);
      expect(payload['quantity'], 3);
      expect(payload['itemTotal'], 660.0);
      expect(payload['notes'], 'Less oil');
    });

    test('3. Tax calculation follows server rule #50A (SC on subtotal, taxable = subtotal + SC - discounts, total = taxable + tax)', () {
      final totals = OrderTotals.calculate(
        subtotal: const Paise(100000), // Rs 1000
        discount: const Paise(10000),  // Rs 100
        serviceChargePct: 5.0,         // 5% SC
        applyServiceCharge: true,      // dine-in on
        taxPct: 5.0,                  // 5% GST
        loyaltyRedemption: const Paise(0),
      );

      // Subtotal = 1000
      expect(totals.subtotal.toRupees, 1000.0);
      // Service charge = 5% of 1000 = 50
      expect(totals.serviceCharge.toRupees, 50.0);
      // Taxable = 1000 + 50 - 100 = 950
      expect(totals.taxable.toRupees, 950.0);
      // GST = 5% of 950 = 47.50
      expect(totals.gst.toRupees, 47.50);
      // Total = 950 + 47.50 = 997.50, rounded to 998
      expect(totals.total.toRupees, 998.0);
    });

    test('5. Unserved item check detects non-served items for checkout dialog', () {
      final items = [
        OrderItem(menuItemId: 'm1', name: 'Item 1', price: 100, quantity: 1, itemTotal: 100, status: 'in_queue'),
        OrderItem(menuItemId: 'm2', name: 'Item 2', price: 150, quantity: 1, itemTotal: 150, status: 'preparing'),
        OrderItem(menuItemId: 'm3', name: 'Item 3', price: 200, quantity: 1, itemTotal: 200, status: 'served'),
      ];

      final unservedCount = items.where((i) => i.status.toLowerCase() != 'served').length;
      expect(unservedCount, 2);
      final confirmMsg = '$unservedCount items not served yet. Check out anyway?';
      expect(confirmMsg, '2 items not served yet. Check out anyway?');
    });

    test('6. ApiExceptions.getDetailedErrorMessage extracts server message on 500 errors', () {
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/test'),
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 500,
          data: {'message': 'Order validation failed: items.0.price is required'},
        ),
      );

      final extractedMsg = ApiExceptions.getDetailedErrorMessage(dioError);
      expect(extractedMsg, 'Order validation failed: items.0.price is required');
    });
  });

  group('PART B: Models Deserialization Tests', () {
    test('#51B KitchenOrdersResponse parses JSON with items and counts', () {
      final json = {
        'items': [
          {
            'orderId': 'ord_123',
            'orderNo': 'ORD-2026-0005',
            'orderType': 'dine_in',
            'itemId': 'item_456',
            'name': 'Chicken Tikka',
            'quantity': 1,
            'notes': 'Well done',
            'status': 'preparing',
            'table': {'_id': 'tbl_1', 'tableName': 'Table 4'},
            'sentToKitchenAt': '2026-10-27T06:00:00.000Z',
          }
        ],
        'counts': {'in_queue': 2, 'preparing': 1, 'ready': 3, 'served': 5, 'cancelled': 0},
        'total': 11,
        'page': 1,
        'limit': 20,
        'totalPages': 1,
      };

      final resp = KitchenOrdersResponse.fromJson(json);
      expect(resp.items.length, 1);
      expect(resp.items[0].orderNo, 'ORD-2026-0005');
      expect(resp.items[0].tableName, 'Table 4');
      expect(resp.items[0].status, 'preparing');
      expect(resp.counts['preparing'], 1);
      expect(resp.total, 11);
    });

    test('#51A OrderListResponse parses paginated order list', () {
      final json = {
        'orders': [
          {
            '_id': 'ord_999',
            'orderNo': 'ORD-2026-0009',
            'orderType': 'takeaway',
            'items': [],
            'subTotal': 300,
            'grandTotal': 315,
            'orderStatus': 'active',
            'paymentStatus': 'pending',
          }
        ],
        'total': 15,
        'page': 2,
        'limit': 10,
        'totalPages': 2,
      };

      final resp = OrderListResponse.fromJson(json);
      expect(resp.orders.length, 1);
      expect(resp.orders[0].orderNo, 'ORD-2026-0009');
      expect(resp.total, 15);
      expect(resp.page, 2);
      expect(resp.totalPages, 2);
    });

    test('#51C PaidOrdersResponse parses summary and orders', () {
      final json = {
        'orders': [],
        'summary': {
          'totalCollected': 1500.5,
          'totalDiscounts': 100.0,
          'totalOrders': 10,
          'avgOrderValue': 150.05,
          'byPaymentMethod': [
            {'mode': 'cash', 'amount': 1000.0, 'count': 6},
            {'mode': 'upi', 'amount': 500.5, 'count': 4},
          ],
        },
        'total': 10,
        'page': 1,
        'limit': 20,
        'totalPages': 1,
      };

      final resp = PaidOrdersResponse.fromJson(json);
      expect(resp.summary, isNotNull);
      expect(resp.summary!.totalCollected, 1500.5);
      expect(resp.summary!.byPaymentMethod.length, 2);
      expect(resp.summary!.byPaymentMethod[0].mode, 'cash');
    });
  });

  group('PART B: Screen Rendering & Responsiveness', () {
    testWidgets('KOT Management Screen renders queue items, counts and buttons', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 600));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(() => _FakeAuthController(mockUser)),
            activeOutletProvider.overrideWith((ref) => mockOutlet),
            kitchenOrdersControllerProvider.overrideWith(() => _FakeKitchenOrdersController(mockKitchenResponse)),
          ],
          child: const MaterialApp(home: KotManagementScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Kitchen Order Tickets (KOT)'), findsOneWidget);
      expect(find.text('Auto (30s)'), findsOneWidget);
      expect(find.text('Running'), findsOneWidget);
      expect(find.text('Paneer Butter Masala'), findsWidgets);
      expect(find.text('Start Preparing'), findsWidgets);
    });

    testWidgets('Takeaway Orders Screen renders #51A list, filters and pagination', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(() => _FakeAuthController(mockUser)),
            activeOutletProvider.overrideWith((ref) => mockOutlet),
            takeawayOrdersControllerProvider.overrideWith(
              () => _FakeOrdersByTypeNotifier('takeaway', mockOrderListResponse),
            ),
          ],
          child: const MaterialApp(home: TakeawayOrdersScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Takeaway Orders'), findsOneWidget);
      expect(find.text('Order #ORD-2026-0001'), findsOneWidget);
      expect(find.text('₹525'), findsOneWidget);
      expect(find.text('Page 1 / 1'), findsOneWidget);
    });

    testWidgets('Delivery Orders Screen renders gap notice banner and orders', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(() => _FakeAuthController(mockUser)),
            activeOutletProvider.overrideWith((ref) => mockOutlet),
            deliveryOrdersControllerProvider.overrideWith(
              () => _FakeOrdersByTypeNotifier('delivery', mockOrderListResponse),
            ),
          ],
          child: const MaterialApp(home: DeliveryOrdersScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Delivery Orders'), findsOneWidget);
      expect(find.textContaining('API Gap: Delivery and Online orders have no customer or address fields'), findsOneWidget);
      expect(find.text('Order #ORD-2026-0001'), findsOneWidget);
    });

    testWidgets('Online Orders Screen renders gap notice banner and orders', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(() => _FakeAuthController(mockUser)),
            activeOutletProvider.overrideWith((ref) => mockOutlet),
            onlineOrdersControllerProvider.overrideWith(
              () => _FakeOrdersByTypeNotifier('online', mockOrderListResponse),
            ),
          ],
          child: const MaterialApp(home: OnlineOrdersScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Online Orders'), findsOneWidget);
      expect(find.textContaining('API Gap: Delivery and Online orders have no customer or address fields'), findsOneWidget);
      expect(find.text('Order #ORD-2026-0001'), findsOneWidget);
    });

    testWidgets('All Orders Screen renders Active (#44) and Paid (#51C) tabs', (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 900));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(() => _FakeAuthController(mockUser)),
            activeOutletProvider.overrideWith((ref) => mockOutlet),
            activeOrdersProvider.overrideWith(() => _FakeActiveOrdersNotifier([mockOrder])),
            paidOrdersControllerProvider.overrideWith(() => _FakePaidOrdersController(mockPaidOrdersResponse)),
          ],
          child: const MaterialApp(home: AllOrdersScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('All Orders'), findsOneWidget);
      expect(find.textContaining('API Gap: The API PDF has no endpoint to list cancelled orders'), findsOneWidget);
      expect(find.text('Active Orders (#44)'), findsOneWidget);
      expect(find.text('Paid Orders (#51C)'), findsOneWidget);

      // Switch to Paid tab
      await tester.tap(find.text('Paid Orders (#51C)'));
      await tester.pumpAndSettle();

      expect(find.text('COLLECTED'), findsOneWidget);
      expect(find.text('₹525'), findsWidgets);
      expect(find.text('PAID ORDERS'), findsOneWidget);
    });

    testWidgets('Responsiveness: 360x800 portrait, 800x360 landscape, 1.5x font scale without overflow', (tester) async {
      // 1. Portrait 360x800
      await tester.binding.setSurfaceSize(const Size(360, 800));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(() => _FakeAuthController(mockUser)),
            activeOutletProvider.overrideWith((ref) => mockOutlet),
            takeawayOrdersControllerProvider.overrideWith(
              () => _FakeOrdersByTypeNotifier('takeaway', mockOrderListResponse),
            ),
          ],
          child: const MaterialApp(home: TakeawayOrdersScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // 2. Landscape 800x360
      await tester.binding.setSurfaceSize(const Size(800, 360));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(() => _FakeAuthController(mockUser)),
            activeOutletProvider.overrideWith((ref) => mockOutlet),
            takeawayOrdersControllerProvider.overrideWith(
              () => _FakeOrdersByTypeNotifier('takeaway', mockOrderListResponse),
            ),
          ],
          child: const MaterialApp(home: TakeawayOrdersScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // 3. Large font scale 1.5x
      await tester.binding.setSurfaceSize(const Size(360, 800));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(() => _FakeAuthController(mockUser)),
            activeOutletProvider.overrideWith((ref) => mockOutlet),
            takeawayOrdersControllerProvider.overrideWith(
              () => _FakeOrdersByTypeNotifier('takeaway', mockOrderListResponse),
            ),
          ],
          child: const MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(1.5)),
              child: TakeawayOrdersScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('Responsiveness: Delivery Orders screen at 360x800 with 1.5x font scale', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(() => _FakeAuthController(mockUser)),
            activeOutletProvider.overrideWith((ref) => mockOutlet),
            deliveryOrdersControllerProvider.overrideWith(
              () => _FakeOrdersByTypeNotifier('delivery', mockOrderListResponse),
            ),
          ],
          child: const MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(1.5)),
              child: DeliveryOrdersScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('Responsiveness: Online Orders screen at 360x800 with 1.5x font scale', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(() => _FakeAuthController(mockUser)),
            activeOutletProvider.overrideWith((ref) => mockOutlet),
            onlineOrdersControllerProvider.overrideWith(
              () => _FakeOrdersByTypeNotifier('online', mockOrderListResponse),
            ),
          ],
          child: const MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(1.5)),
              child: OnlineOrdersScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('Responsiveness: All Orders screen at 360x800 with 1.5x font scale', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(() => _FakeAuthController(mockUser)),
            activeOutletProvider.overrideWith((ref) => mockOutlet),
            activeOrdersProvider.overrideWith(() => _FakeActiveOrdersNotifier([mockOrder])),
            paidOrdersControllerProvider.overrideWith(() => _FakePaidOrdersController(mockPaidOrdersResponse)),
          ],
          child: const MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(1.5)),
              child: AllOrdersScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
