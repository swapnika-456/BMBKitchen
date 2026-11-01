import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bmb_kitchen/features/online/screens/online_orders_screen.dart';
import 'package:bmb_kitchen/features/crm/screens/customer_management_screen.dart';
import 'package:bmb_kitchen/features/offers/screens/offers_management_screen.dart';
import 'package:bmb_kitchen/features/loyalty/screens/loyalty_management_screen.dart';
import 'package:bmb_kitchen/features/supply_chain/screens/inventory_screen.dart';
import 'package:bmb_kitchen/features/supply_chain/screens/purchase_management_screen.dart';
import 'package:bmb_kitchen/features/supply_chain/screens/vendor_management_screen.dart';
import 'package:bmb_kitchen/features/supply_chain/screens/recipe_management_screen.dart';
import 'package:bmb_kitchen/features/supply_chain/screens/wastage_screen.dart';
import 'package:bmb_kitchen/features/qr/screens/qr_ordering_screen.dart';

void main() {
  group('Mobile & Desktop Overflow Validation Tests (Modules 13, 15-22)', () {
    final viewports = [
      ('Mobile 360x640', const Size(360, 640)),
      ('Small Mobile 320x568', const Size(320, 568)),
      ('Tablet 768x1024', const Size(768, 1024)),
      ('Desktop 1280x800', const Size(1280, 800)),
    ];

    for (final (device, size) in viewports) {
      testWidgets(
        'OnlineOrdersScreen (13) renders without overflow on $device',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          await tester.pumpWidget(
            const ProviderScope(
              child: MaterialApp(home: Scaffold(body: OnlineOrdersScreen())),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text('Online Orders'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );

      testWidgets(
        'CustomerManagementScreen (15) renders without overflow on $device',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          await tester.pumpWidget(
            const ProviderScope(
              child: MaterialApp(
                home: Scaffold(body: CustomerManagementScreen()),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text('Customer Management'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );

      testWidgets(
        'OffersManagementScreen (16) renders without overflow on $device',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          await tester.pumpWidget(
            const ProviderScope(
              child: MaterialApp(
                home: Scaffold(body: OffersManagementScreen()),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text('Offers & Discounts'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );

      testWidgets(
        'LoyaltyManagementScreen (17) renders without overflow on $device',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          await tester.pumpWidget(
            const ProviderScope(
              child: MaterialApp(
                home: Scaffold(body: LoyaltyManagementScreen()),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text('Loyalty Program'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );

      testWidgets('InventoryScreen (18) renders without overflow on $device', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(home: Scaffold(body: InventoryScreen())),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Inventory Management'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets(
        'PurchaseManagementScreen (19) renders without overflow on $device',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          await tester.pumpWidget(
            const ProviderScope(
              child: MaterialApp(
                home: Scaffold(body: PurchaseManagementScreen()),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text('Purchase Management'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );

      testWidgets(
        'VendorManagementScreen (20) renders without overflow on $device',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          await tester.pumpWidget(
            const ProviderScope(
              child: MaterialApp(
                home: Scaffold(body: VendorManagementScreen()),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text('Vendor Management'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );

      testWidgets(
        'RecipeManagementScreen (21) renders without overflow on $device',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          await tester.pumpWidget(
            const ProviderScope(
              child: MaterialApp(
                home: Scaffold(body: RecipeManagementScreen()),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text('Recipes & Food Cost'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );

      testWidgets('WastageScreen (22) renders without overflow on $device', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(home: Scaffold(body: WastageScreen())),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Wastage & Stock Adjustment'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('QrOrderingScreen (10) renders without overflow on $device', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(home: Scaffold(body: QrOrderingScreen())),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('QR Scan Ordering'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
