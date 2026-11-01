import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bmb_kitchen/mock/mock_state.dart';
import 'package:bmb_kitchen/models/models.dart';
import 'package:bmb_kitchen/features/kitchen/screens/kot_management_screen.dart';
import 'package:bmb_kitchen/features/orders/screens/takeaway_orders_screen.dart';
import 'package:bmb_kitchen/features/orders/screens/all_orders_screen.dart';

void main() {
  group('KOT Workflow & Business Rules Tests', () {
    test('KOT advances through complete lifecycle stages', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(bmbStateProvider.notifier);
      final biryani = container
          .read(bmbStateProvider)
          .menuItems
          .firstWhere((m) => m.id == 'm10');

      // 1. Create order and send KOT
      final order = notifier.startNewOrder(
        type: OrderType.dinein,
        tableId: 'T1',
      );
      notifier.addLineToPending(order.id, biryani);
      notifier.sendOrderKOT(order.id);

      var curOrder = container
          .read(bmbStateProvider)
          .orders
          .firstWhere((o) => o.id == order.id);
      expect(curOrder.kots.length, 1);
      final kotId = curOrder.kots.first.id;
      expect(curOrder.kots.first.status, KOTStatus.newKot);

      // 2. Advance to accepted
      notifier.advanceKot(kotId);
      curOrder = container
          .read(bmbStateProvider)
          .orders
          .firstWhere((o) => o.id == order.id);
      expect(curOrder.kots.first.status, KOTStatus.accepted);

      // 3. Advance to preparing
      notifier.advanceKot(kotId);
      curOrder = container
          .read(bmbStateProvider)
          .orders
          .firstWhere((o) => o.id == order.id);
      expect(curOrder.kots.first.status, KOTStatus.preparing);

      // 4. Advance to ready
      notifier.advanceKot(kotId);
      curOrder = container
          .read(bmbStateProvider)
          .orders
          .firstWhere((o) => o.id == order.id);
      expect(curOrder.kots.first.status, KOTStatus.ready);

      // 5. Advance to completed
      notifier.advanceKot(kotId);
      curOrder = container
          .read(bmbStateProvider)
          .orders
          .firstWhere((o) => o.id == order.id);
      expect(curOrder.kots.first.status, KOTStatus.completed);
    });

    test('Late KOT threshold flag is true when elapsed minutes >= 10', () {
      final now = DateTime.now().millisecondsSinceEpoch;

      final recentKot = KOT(
        id: 'k_rec',
        no: 1,
        orderId: 'O1',
        items: const [],
        status: KOTStatus.preparing,
        createdAtMs: now - (5 * 60000), // 5 min ago
        printer: 'Hot Kitchen KOT',
      );
      expect(recentKot.isLate(now, thresholdMinutes: 10), isFalse);

      final lateKot = KOT(
        id: 'k_late',
        no: 2,
        orderId: 'O2',
        items: const [],
        status: KOTStatus.preparing,
        createdAtMs: now - (12 * 60000), // 12 min ago
        printer: 'Hot Kitchen KOT',
      );
      expect(lateKot.isLate(now, thresholdMinutes: 10), isTrue);
    });
  });

  group('KOT Privacy & UI Widget Tests', () {
    testWidgets(
      'Strict Privacy Rule: No prices or rupee symbols on KotManagementScreen',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          const ProviderScope(child: MaterialApp(home: KotManagementScreen())),
        );

        await tester.pumpAndSettle();

        // Ensure screen rendered
        expect(find.text('KOT Kitchen Display'), findsOneWidget);

        // Privacy Enforcement: Under NO circumstances should a Rupee symbol appear on kitchen tickets!
        expect(find.textContaining('₹'), findsNothing);
      },
    );

    testWidgets('TakeawayOrdersScreen renders token register and KPI tiles', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: TakeawayOrdersScreen())),
      );

      await tester.pumpAndSettle();

      expect(find.text('Takeaway Orders'), findsOneWidget);
      expect(find.text('READY FOR PICKUP'), findsOneWidget);
      expect(find.text('BEING COOKED'), findsOneWidget);
      expect(find.text('New Takeaway'), findsOneWidget);
    });

    testWidgets('AllOrdersScreen renders order table and filter chips', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: AllOrdersScreen())),
      );

      await tester.pumpAndSettle();

      expect(find.text('All Orders Register'), findsOneWidget);
      expect(find.textContaining('Running'), findsWidgets);
      expect(find.textContaining('Completed'), findsWidgets);
      expect(find.byType(TextField), findsOneWidget);
    });
  });
}
