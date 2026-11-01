import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bmb_kitchen/features/settings/screens/printer_settings_screen.dart';
import 'package:bmb_kitchen/features/settings/screens/tax_settings_screen.dart';
import 'package:bmb_kitchen/features/dashboard/screens/dashboard_screen.dart';

void main() {
  group('Settings & Dashboard Overflow Tests', () {
    final viewports = [
      ('Mobile 360x640', const Size(360, 640)),
      ('Small Mobile 320x568', const Size(320, 568)),
      ('Tablet 768x1024', const Size(768, 1024)),
      ('Desktop 1280x800', const Size(1280, 800)),
    ];

    for (final (device, size) in viewports) {
      testWidgets(
        'PrinterSettingsScreen (27) renders without overflow on $device',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          await tester.pumpWidget(
            const ProviderScope(
              child: MaterialApp(home: Scaffold(body: PrinterSettingsScreen())),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.textContaining('Printer Settings'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );

      testWidgets(
        'TaxSettingsScreen (28) renders without overflow on $device',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          await tester.pumpWidget(
            const ProviderScope(
              child: MaterialApp(home: Scaffold(body: TaxSettingsScreen())),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.textContaining('Tax Settings'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );

      testWidgets('DashboardScreen (01) renders without overflow on $device', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(home: Scaffold(body: DashboardScreen())),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Dashboard'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
