import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bmb_kitchen/features/settings/screens/support_helpdesk_screen.dart';
import 'package:bmb_kitchen/features/menu/screens/menu_management_screen.dart';
import 'package:bmb_kitchen/features/supply_chain/screens/purchase_management_screen.dart';
import 'package:bmb_kitchen/features/supply_chain/screens/vendor_management_screen.dart';
import 'package:bmb_kitchen/features/supply_chain/screens/wastage_screen.dart';
import 'package:bmb_kitchen/features/finance/screens/expenses_screen.dart';

void main() {
  group('Comprehensive Overflow Remediation Tests', () {
    final viewports = [
      ('Small Mobile 320x568', const Size(320, 568)),
      ('Mobile 360x640', const Size(360, 640)),
      ('Mobile 390x844', const Size(390, 844)),
      ('Tablet 768x1024', const Size(768, 1024)),
      ('Desktop 1280x800', const Size(1280, 800)),
    ];

    for (final (device, size) in viewports) {
      testWidgets(
        'SupportHelpdeskScreen and Raise Ticket modal render without overflow on $device',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          await tester.pumpWidget(
            const ProviderScope(
              child: MaterialApp(home: Scaffold(body: SupportHelpdeskScreen())),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text('Support & Helpdesk'), findsOneWidget);
          expect(tester.takeException(), isNull);

          // Tap "+ Raise ticket"
          final raiseBtn = find.text('+ Raise ticket');
          expect(raiseBtn, findsOneWidget);
          await tester.tap(raiseBtn);
          await tester.pumpAndSettle();

          // Modal should be open without overflow
          expect(find.text('Raise Support Ticket'), findsOneWidget);
          expect(find.text('Submit Ticket'), findsOneWidget);
          expect(tester.takeException(), isNull);

          // Dismiss modal
          await tester.tap(find.text('Cancel'));
          await tester.pumpAndSettle();
        },
      );

      testWidgets(
        'MenuManagementScreen and Edit Item modal render without overflow on $device',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          await tester.pumpWidget(
            const ProviderScope(
              child: MaterialApp(home: Scaffold(body: MenuManagementScreen())),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text('Menu Management'), findsOneWidget);
          expect(tester.takeException(), isNull);

          // Open Add Item modal
          final addBtn = find.text('Add Menu Item');
          expect(addBtn, findsOneWidget);
          await tester.tap(addBtn);
          await tester.pumpAndSettle();

          expect(find.text('New Menu Item'), findsOneWidget);
          expect(find.text('Item Name'), findsOneWidget);
          expect(tester.takeException(), isNull);

          // Close modal
          final cancelBtn = find.text('Cancel');
          if (cancelBtn.evaluate().isNotEmpty) {
            await tester.tap(cancelBtn.first, warnIfMissed: false);
            await tester.pumpAndSettle();
          }
        },
      );

      testWidgets(
        'PurchaseManagementScreen and New Purchase sheet render without overflow on $device',
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
          expect(find.text('Purchases This Month'), findsOneWidget);
          expect(find.text('Outstanding to Vendors'), findsOneWidget);
          expect(tester.takeException(), isNull);

          // Open New Purchase sheet
          final newPurBtn = find.text('New Purchase');
          expect(newPurBtn, findsOneWidget);
          await tester.tap(newPurBtn);
          await tester.pumpAndSettle();

          expect(find.text('New Purchase Entry'), findsOneWidget);
          expect(find.text('Save & Update Stock'), findsOneWidget);
          expect(tester.takeException(), isNull);

          // Close sheet
          final closeBtn = find.byIcon(Icons.close);
          if (closeBtn.evaluate().isNotEmpty) {
            await tester.tap(closeBtn.first);
            await tester.pumpAndSettle();
          }
        },
      );

      testWidgets(
        'VendorManagementScreen and Add Vendor sheet render without overflow on $device',
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
          expect(find.text('Total Suppliers'), findsOneWidget);
          expect(find.text('Recorded Purchases'), findsOneWidget);
          expect(tester.takeException(), isNull);

          // Open Add Supplier sheet
          final addVendorBtn = find.text('Add Vendor');
          expect(addVendorBtn, findsOneWidget);
          await tester.tap(addVendorBtn);
          await tester.pumpAndSettle();

          expect(find.text('Save Vendor'), findsOneWidget);
          expect(tester.takeException(), isNull);

          // Close sheet
          final cancelBtn = find.text('Cancel');
          if (cancelBtn.evaluate().isNotEmpty) {
            await tester.tap(cancelBtn.first, warnIfMissed: false);
            await tester.pumpAndSettle();
          }
        },
      );

      testWidgets('WastageScreen renders without overflow on $device', (
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
        expect(find.text('Wastage Value (Month)'), findsOneWidget);
        expect(find.text('Entries This Month'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets(
        'ExpensesScreen and Log Expense modal render without overflow on $device',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          await tester.pumpWidget(
            const ProviderScope(
              child: MaterialApp(home: Scaffold(body: ExpensesScreen())),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text('Expense Management'), findsOneWidget);
          expect(find.text('Expenses this month'), findsOneWidget);
          expect(find.text('Purchases this month'), findsOneWidget);
          expect(tester.takeException(), isNull);

          // Open Log Expense modal
          final logBtn = find.text('+ Log expense');
          expect(logBtn, findsOneWidget);
          await tester.tap(logBtn);
          await tester.pumpAndSettle();

          expect(find.text('Log Expense'), findsOneWidget);
          expect(find.text('Save expense'), findsOneWidget);
          expect(tester.takeException(), isNull);

          // Close modal
          final cancelBtn = find.text('Cancel');
          if (cancelBtn.evaluate().isNotEmpty) {
            await tester.tap(cancelBtn.first, warnIfMissed: false);
            await tester.pumpAndSettle();
          }
        },
      );
    }
  });
}
