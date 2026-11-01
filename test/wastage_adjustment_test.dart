import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bmb_kitchen/models/wastage_adjustment.dart';
import 'package:bmb_kitchen/models/inventory_item.dart';
import 'package:bmb_kitchen/models/user.dart';
import 'package:bmb_kitchen/features/auth/controllers/auth_controller.dart';
import 'package:bmb_kitchen/features/supply_chain/controllers/wastage_adjustment_controller.dart';
import 'package:bmb_kitchen/features/supply_chain/providers/inventory_providers.dart';
import 'package:bmb_kitchen/features/supply_chain/screens/wastage_screen.dart';
import 'package:bmb_kitchen/core/widgets/lifecycle_list_view.dart';

class _MockActiveWastageNotifier extends ActiveWastageAdjustmentNotifier {
  final List<WastageAdjustment> initial;
  _MockActiveWastageNotifier(this.initial);

  @override
  Future<List<WastageAdjustment>> build() async => initial;
}

class _MockInactiveWastageNotifier extends InactiveWastageAdjustmentNotifier {
  final List<WastageAdjustment> initial;
  _MockInactiveWastageNotifier(this.initial);

  @override
  Future<List<WastageAdjustment>> build() async => initial;
}

class _MockActiveInventoryNotifier extends ActiveInventoryNotifier {
  final List<InventoryItem> initial;
  _MockActiveInventoryNotifier(this.initial);

  @override
  Future<List<InventoryItem>> build() async => initial;
}

void main() {
  group('Module 11 WastageAdjustment Model Tests', () {
    test('WastageAdjustment parses populated response correctly (#87, #89, #90)', () {
      final json = {
        '_id': 'wa_123',
        'organizationId': {'_id': 'org_1', 'name': 'Org 1'},
        'wastageNo': 'WA-001',
        'inventoryId': {
          '_id': 'inv_1',
          'material': 'Whole Wheat Flour',
          'unit': 'kg',
          'rate': 40
        },
        'type': 'wastage',
        'quantity': 5.5,
        'reason': 'Water damage in store room',
        'isActive': true,
        'createdBy': {'_id': 'u1', 'userName': 'Chef Gordon'},
        'createdAt': '2026-10-21T05:15:22.176Z',
        'updatedAt': '2026-10-21T05:15:22.176Z',
      };

      final wa = WastageAdjustment.fromJson(json);
      expect(wa.id, 'wa_123');
      expect(wa.organizationId, 'org_1');
      expect(wa.wastageNo, 'WA-001');
      expect(wa.inventoryId, 'inv_1');
      expect(wa.inventoryMaterial, 'Whole Wheat Flour');
      expect(wa.inventoryUnit, 'kg');
      expect(wa.type, 'wastage');
      expect(wa.quantity, 5.5);
      expect(wa.reason, 'Water damage in store room');
      expect(wa.createdBy, 'Chef Gordon');
      expect(wa.isActive, isTrue);
      expect(wa.createdAt, isNotNull);
    });

    test('WastageAdjustment parses plain ID response correctly (#88, #91)', () {
      final json = {
        '_id': 'wa_456',
        'organizationId': 'org_1',
        'wastageNo': 'WA-002',
        'inventoryId': 'inv_2',
        'type': 'adjustment',
        'action': 'add',
        'quantity': 10,
        'reason': 'Unrecorded shipment',
        'isActive': true,
        'createdBy': 'user_1',
      };

      final wa = WastageAdjustment.fromJson(json);
      expect(wa.id, 'wa_456');
      expect(wa.inventoryId, 'inv_2');
      expect(wa.inventoryMaterial, isEmpty);
      expect(wa.type, 'adjustment');
      expect(wa.action, 'add');
      expect(wa.quantity, 10.0);
      expect(wa.createdBy, 'user_1');
    });

    test('toCreateJson includes required fields and action if present', () {
      const wa = WastageAdjustment(
        id: 'wa_1',
        organizationId: 'org_1',
        wastageNo: 'WA-001',
        inventoryId: 'inv_1',
        type: 'adjustment',
        action: 'remove',
        quantity: 3.0,
        reason: 'Audit correction',
      );

      final map = wa.toCreateJson();
      expect(map['inventoryId'], 'inv_1');
      expect(map['type'], 'adjustment');
      expect(map['action'], 'remove');
      expect(map['quantity'], 3.0);
      expect(map['reason'], 'Audit correction');
    });

    test('toUpdateJson only sends type and reason (#91 spec)', () {
      const wa = WastageAdjustment(
        id: 'wa_1',
        organizationId: 'org_1',
        wastageNo: 'WA-001',
        inventoryId: 'inv_1',
        type: 'adjustment',
        quantity: 5.0,
        reason: 'Updated reason',
      );

      final map = wa.toUpdateJson();
      expect(map.containsKey('quantity'), isFalse);
      expect(map.containsKey('inventoryId'), isFalse);
      expect(map['type'], 'adjustment');
      expect(map['reason'], 'Updated reason');
    });
  });

  group('Wastage & Adjustment Screen Responsive & Overflow Tests', () {
    Widget createTestApp({required Size screenSize, double textScale = 1.0, String role = 'admin'}) {
      const wa1 = WastageAdjustment(
        id: 'wa_1',
        organizationId: 'org_1',
        wastageNo: 'WA-001',
        inventoryId: 'inv_1',
        inventoryMaterial: 'Test Flour',
        inventoryUnit: 'kg',
        type: 'wastage',
        quantity: 5.0,
        reason: 'Expired package',
        isActive: true,
      );

      const wa2 = WastageAdjustment(
        id: 'wa_2',
        organizationId: 'org_1',
        wastageNo: 'WA-002',
        inventoryId: 'inv_2',
        inventoryMaterial: 'Sugar',
        inventoryUnit: 'kg',
        type: 'adjustment',
        action: 'add',
        quantity: 10.0,
        reason: 'Audit discrepancy found',
        isActive: true,
      );

      final inv1 = InventoryItem(
        id: 'inv_1',
        organizationId: 'org_1',
        material: 'Test Flour',
        unit: 'kg',
        rate: 40.0,
        inStock: 45.0,
        minLevel: 10.0,
        category: 'Flour',
        isActive: true,
      );

      final testUser = User(
        id: 'u1',
        name: 'Admin User',
        email: 'admin@bmb.com',
        role: role,
        organizationId: 'org_1',
        isActive: true,
      );

      return ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(() => _MockAuthController(testUser)),
          activeWastageAdjustmentProvider.overrideWith(() => _MockActiveWastageNotifier([wa1, wa2])),
          inactiveWastageAdjustmentProvider.overrideWith(() => _MockInactiveWastageNotifier([])),
          activeInventoryProvider.overrideWith(() => _MockActiveInventoryNotifier([inv1])),
        ],
        child: MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: screenSize,
              textScaler: TextScaler.linear(textScale),
            ),
            child: const Scaffold(
              body: WastageScreen(),
            ),
          ),
        ),
      );
    }

    testWidgets('renders cleanly in mobile portrait (360x800)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      await tester.pumpWidget(createTestApp(screenSize: const Size(360, 800)));
      await tester.pumpAndSettle();

      expect(find.text('Wastage & Stock Adjustment'), findsOneWidget);
      expect(find.text('Total Logged'), findsOneWidget);
      expect(find.text('Wastage Entries'), findsOneWidget);
      expect(find.text('Adjustments'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly in mobile landscape (800x360)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 360));
      await tester.pumpWidget(createTestApp(screenSize: const Size(800, 360)));
      await tester.pumpAndSettle();

      expect(find.text('Wastage & Stock Adjustment'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly with 1.5x large accessibility fonts', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      await tester.pumpWidget(createTestApp(screenSize: const Size(400, 800), textScale: 1.5));
      await tester.pumpAndSettle();

      expect(find.text('Wastage & Stock Adjustment'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('staff sees read-only list with Record Wastage button (#88)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      await tester.pumpWidget(createTestApp(screenSize: const Size(360, 800), role: 'staff'));
      await tester.pumpAndSettle();

      expect(find.text('Record Wastage'), findsOneWidget);
      expect(find.byType(LifecycleListView<WastageAdjustment>), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}

class _MockAuthController extends AuthController {
  final User? initialUser;
  _MockAuthController(this.initialUser);

  @override
  Future<User?> build() async => initialUser;
}
