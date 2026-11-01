import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bmb_kitchen/features/finance/screens/expenses_screen.dart';
import 'package:bmb_kitchen/features/settings/screens/multi_outlet_screen.dart';
import 'package:bmb_kitchen/features/settings/screens/central_kitchen_screen.dart';
import 'package:bmb_kitchen/features/settings/screens/subscription_screen.dart';
import 'package:bmb_kitchen/features/settings/screens/notifications_screen.dart';
import 'package:bmb_kitchen/features/settings/screens/integrations_screen.dart';
import 'package:bmb_kitchen/features/settings/screens/support_helpdesk_screen.dart';

void main() {
  group('Modules 23 & 29-34 Responsive & Overflow Tests', () {
    final viewports = [
      ('Mobile 360x640', const Size(360, 640)),
      ('Small Mobile 320x568', const Size(320, 568)),
      ('Tablet 768x1024', const Size(768, 1024)),
      ('Desktop 1280x800', const Size(1280, 800)),
    ];

    for (final (device, size) in viewports) {
      testWidgets('ExpensesScreen (23) renders without overflow on $device', (
        tester,
      ) async {
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
        expect(tester.takeException(), isNull);
      });

      testWidgets(
        'MultiOutletScreen (29) renders without overflow on $device',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          await tester.pumpWidget(
            const ProviderScope(
              child: MaterialApp(home: Scaffold(body: MultiOutletScreen())),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text('Multi-Outlet Management'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );

      testWidgets(
        'CentralKitchenScreen (30) renders without overflow on $device',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          await tester.pumpWidget(
            const ProviderScope(
              child: MaterialApp(home: Scaffold(body: CentralKitchenScreen())),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text('Central Kitchen'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );

      testWidgets(
        'SubscriptionScreen (31) renders without overflow on $device',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          await tester.pumpWidget(
            const ProviderScope(
              child: MaterialApp(home: Scaffold(body: SubscriptionScreen())),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text('Subscription & Billing'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );

      testWidgets(
        'NotificationsScreen (32) renders without overflow on $device',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          await tester.pumpWidget(
            const ProviderScope(
              child: MaterialApp(home: Scaffold(body: NotificationsScreen())),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text('Notifications'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );

      testWidgets(
        'IntegrationsScreen (33) renders without overflow on $device',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          await tester.pumpWidget(
            const ProviderScope(
              child: MaterialApp(home: Scaffold(body: IntegrationsScreen())),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text('Integrations'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );

      testWidgets(
        'SupportHelpdeskScreen (34) renders without overflow on $device',
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
        },
      );
    }
  });
}
