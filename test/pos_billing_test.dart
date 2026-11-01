import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bmb_kitchen/models/order.dart';
import 'package:bmb_kitchen/models/outlet.dart';
import 'package:bmb_kitchen/models/restaurant_table.dart';
import 'package:bmb_kitchen/models/menu_category.dart';
import 'package:bmb_kitchen/models/menu_item.dart';
import 'package:bmb_kitchen/features/pos/screens/pos_billing_screen.dart';
import 'package:bmb_kitchen/features/pos/controllers/pos_order_controller.dart';
import 'package:bmb_kitchen/features/tables/providers/table_providers.dart';
import 'package:bmb_kitchen/features/menu/controllers/menu_category_controller.dart';
import 'package:bmb_kitchen/features/menu/controllers/menu_item_controller.dart';
import 'package:bmb_kitchen/features/settings/controllers/active_outlet_provider.dart';
import 'package:bmb_kitchen/models/user.dart';
import 'package:bmb_kitchen/features/auth/controllers/auth_controller.dart';
import 'package:bmb_kitchen/core/money/paise.dart';
import 'package:bmb_kitchen/core/widgets/food_type_dot.dart';

class _FakeActiveOrdersNotifier extends ActiveOrdersNotifier {
  final List<Order> _initialOrders;
  _FakeActiveOrdersNotifier(this._initialOrders);

  @override
  Future<List<Order>> build() async => _initialOrders;
}

class _FakeActiveTablesNotifier extends ActiveTablesNotifier {
  final List<RestaurantTable> _initialTables;
  _FakeActiveTablesNotifier(this._initialTables);

  @override
  Future<List<RestaurantTable>> build() async => _initialTables;
}

class _FakeMenuItemController extends MenuItemController {
  final List<MenuItem> _items;
  _FakeMenuItemController(this._items);

  @override
  Future<List<MenuItem>> build() async => _items;
}

class _FakeMenuCategoryController extends MenuCategoryController {
  final List<MenuCategory> _categories;
  _FakeMenuCategoryController(this._categories);

  @override
  Future<List<MenuCategory>> build() async => _categories;
}

class _FakeAuthController extends AuthController {
  final User? _user;
  _FakeAuthController(this._user);

  @override
  Future<User?> build() async => _user;
}

void main() {
  group('Module 12a Order Model Tests', () {
    test('Order parses populated JSON response correctly (#44, #46)', () {
      final json = {
        '_id': '6adc34cd88e080704d1fb5b6',
        'organizationId': '6ac78e4f0a063d3e07a1bed5',
        'outletId': {
          '_id': '6adc341988e080704d1fb5af',
          'name': 'Main Kitchen',
        },
        'tableId': {
          '_id': '6adc344588e080704d1fb5b1',
          'tableName': 'Table 1',
        },
        'orderType': 'dine_in',
        'items': [
          {
            '_id': '6adc34cd88e080704d1fb5b7',
            'menuItemId': {
              '_id': '6adc342588e080704d1fb5b0',
              'name': 'Butter Chicken',
            },
            'name': 'Butter Chicken',
            'price': 250,
            'quantity': 2,
            'itemTotal': 500,
            'notes': 'Extra spicy',
            'status': 'served',
            'sentToKitchenAt': '2026-10-24T04:32:13.047Z',
            'servedAt': '2026-10-24T04:32:13.538Z',
          }
        ],
        'subTotal': 500,
        'discountAmount': 50,
        'manualDiscountAmount': 50,
        'serviceChargeAmount': 25,
        'taxPercent': 5,
        'taxAmount': 25,
        'grandTotal': 500,
        'orderStatus': 'active',
        'paymentStatus': 'pending',
        'paymentMethod': 'unpaid',
        'orderNo': 'ORD-2026-0001',
        'billNo': 'BILL-2026-0001',
        'createdAt': '2026-10-24T04:32:13.060Z',
      };

      final order = Order.fromJson(json);

      expect(order.id, '6adc34cd88e080704d1fb5b6');
      expect(order.outletId, '6adc341988e080704d1fb5af');
      expect(order.outletName, 'Main Kitchen');
      expect(order.tableId, '6adc344588e080704d1fb5b1');
      expect(order.tableName, 'Table 1');
      expect(order.orderType, 'dine_in');
      expect(order.orderNo, 'ORD-2026-0001');
      expect(order.billNo, 'BILL-2026-0001');
      expect(order.subTotal, 500.0);
      expect(order.manualDiscountAmount, 50.0);
      expect(order.grandTotal, 500.0);
      expect(order.orderStatus, 'active');
      expect(order.paymentStatus, 'pending');

      expect(order.items.length, 1);
      final item = order.items.first;
      expect(item.name, 'Butter Chicken');
      expect(item.price, 250.0);
      expect(item.quantity, 2);
      expect(item.itemTotal, 500.0);
      expect(item.notes, 'Extra spicy');
      expect(item.status, 'served');
    });

    test('Order parses plain ID response defensively (#45, #48)', () {
      final json = {
        '_id': '6adc40b188e080704d1fb5d4',
        'organizationId': '6ac78e4f0a063d3e07a1bed5',
        'outletId': '6adc341988e080704d1fb5af',
        'tableId': null,
        'orderType': 'takeaway',
        'items': [],
        'subTotal': 0,
        'grandTotal': 0,
        'orderStatus': 'active',
        'paymentStatus': 'pending',
        'orderNo': 'ORD-2026-0009',
      };

      final order = Order.fromJson(json);

      expect(order.id, '6adc40b188e080704d1fb5d4');
      expect(order.outletId, '6adc341988e080704d1fb5af');
      expect(order.tableId, isNull);
      expect(order.orderType, 'takeaway');
      expect(order.items, isEmpty);
    });

    test('OrderCheckoutPreview parses server preview correctly (#50A)', () {
      final json = {
        'subTotal': 500,
        'offerDiscount': 0,
        'manualDiscount': 50,
        'loyaltyDiscount': 0,
        'totalDiscount': 50,
        'taxPercent': 5,
        'serviceChargePercent': 5,
        'serviceChargeAmount': 25,
        'taxAmount': 23.75,
        'grandTotal': 498.75,
        'maxRedeemablePoints': 100,
        'pointsRedeemed': 0,
      };

      final preview = OrderCheckoutPreview.fromJson(json);

      expect(preview.subTotal, 500.0);
      expect(preview.manualDiscount, 50.0);
      expect(preview.serviceChargeAmount, 25.0);
      expect(preview.taxPercent, 5.0);
      expect(preview.taxAmount, 23.75);
      expect(preview.grandTotal, 498.75);
    });

    test('OrderItem toCreateJson includes required fields', () {
      final item = OrderItem(
        id: '123',
        menuItemId: 'm1',
        name: 'Dal Makhani',
        price: 200,
        quantity: 2,
        itemTotal: 400,
        notes: 'Butter on top',
      );

      final json = item.toCreateJson();
      expect(json['menuItemId'], 'm1');
      expect(json['name'], 'Dal Makhani');
      expect(json['price'], 200.0);
      expect(json['quantity'], 2);
      expect(json['itemTotal'], 400.0);
      expect(json['notes'], 'Butter on top');
    });
  });

  group('PosBillingScreen Widget & Overflow Tests', () {
    final mockOutlet = Outlet(
      id: 'out1',
      organizationId: 'org1',
      name: 'Main Kitchen Outlet',
      code: 'OUT-001',
      address: '123 Main St',
      phone: '9999999999',
      isActive: true,
    );

    final mockTables = [
      const RestaurantTable(
        id: 't1',
        name: 'Table 1',
        cap: 4,
        area: 'Indoor',
        status: TableStatus.available,
        outlet: 'out1',
      ),
      const RestaurantTable(
        id: 't2',
        name: 'Table 2',
        cap: 2,
        area: 'Indoor',
        status: TableStatus.occupied,
        outlet: 'out1',
      ),
    ];

    final List<MenuCategory> mockCategories = [
      const MenuCategory(
        id: 'cat1',
        name: 'Main Course',
        description: 'Mains',
      ),
    ];

    final mockMenuItems = [
      const MenuItem(
        id: 'mi1',
        name: 'Paneer Butter Masala',
        cat: 'cat1',
        price: Paise(22000),
        type: FoodType.veg,
        isActive: true,
      ),
      const MenuItem(
        id: 'mi2',
        name: 'Chicken Tikka',
        cat: 'cat1',
        price: Paise(28000),
        type: FoodType.nonveg,
        isActive: true,
      ),
    ];

    final mockOrders = [
      Order(
        id: 'ord1',
        organizationId: 'org1',
        outletId: 'out1',
        orderNo: 'ORD-2026-0001',
        orderType: 'dine_in',
        tableId: 't2',
        tableName: 'Table 2',
        subTotal: 500,
        grandTotal: 525,
        orderStatus: 'active',
        paymentStatus: 'pending',
        items: [
          OrderItem(
            id: 'it1',
            menuItemId: 'mi1',
            name: 'Paneer Butter Masala',
            price: 220,
            quantity: 1,
            itemTotal: 220,
          ),
        ],
      ),
    ];

    Widget buildTestWidget({TextScaler textScaler = TextScaler.noScaling}) {
      return ProviderScope(
        overrides: [
          activeOutletProvider.overrideWithValue(mockOutlet),
          activeOrdersProvider.overrideWith(() => _FakeActiveOrdersNotifier(mockOrders)),
          activeTablesProvider.overrideWith(() => _FakeActiveTablesNotifier(mockTables)),
          menuItemControllerProvider.overrideWith(() => _FakeMenuItemController(mockMenuItems)),
          menuCategoryControllerProvider.overrideWith(() => _FakeMenuCategoryController(mockCategories)),
          authControllerProvider.overrideWith(() => _FakeAuthController(
                User(
                  id: 'u1',
                  email: 'test@bmb.com',
                  name: 'Admin User',
                  role: 'admin',
                  organizationId: 'org1',
                  isActive: true,
                ),
              )),
        ],
        child: MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(textScaler: textScaler),
            child: const PosBillingScreen(),
          ),
        ),
      );
    }

    testWidgets('renders cleanly in mobile portrait (360x800) with zero overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('POS Billing'), findsOneWidget);
      expect(find.text('Order Setup'), findsOneWidget);
      expect(find.text('Dine-in'), findsOneWidget);
      expect(find.text('Takeaway'), findsOneWidget);
      expect(find.text('Paneer Butter Masala'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly in mobile landscape (800x360) with zero overflow', (tester) async {
      tester.view.physicalSize = const Size(800, 360);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('POS Billing'), findsOneWidget);
      expect(find.text('Order Setup'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly with 1.5x large accessibility font scale', (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestWidget(textScaler: const TextScaler.linear(1.5)));
      await tester.pumpAndSettle();

      expect(find.text('POS Billing'), findsOneWidget);
      expect(find.text('Order Setup'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('switches to Active Orders tab and displays order cards', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Tap 'Active Orders' tab
      await tester.tap(find.text('Active Orders'));
      await tester.pumpAndSettle();

      expect(find.text('ORD-2026-0001'), findsOneWidget);
      expect(find.text('₹525'), findsOneWidget);
      expect(find.text('ACTIVE'), findsOneWidget);
      expect(find.text('PENDING'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
