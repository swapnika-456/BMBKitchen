import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bmb_kitchen/models/printer.dart';
import 'package:bmb_kitchen/models/outlet.dart';
import 'package:bmb_kitchen/models/user.dart';
import 'package:bmb_kitchen/features/auth/controllers/auth_controller.dart';
import 'package:bmb_kitchen/features/settings/controllers/active_outlet_provider.dart';
import 'package:bmb_kitchen/features/settings/controllers/printer_controller.dart';
import 'package:bmb_kitchen/features/settings/screens/printer_settings_screen.dart';

class _FakeAuthController extends AuthController {
  final User? _user;
  _FakeAuthController(this._user);
  @override
  Future<User?> build() async => _user;
}

class _FakePrinterController extends PrinterController {
  final PrinterState _initialState;
  _FakePrinterController(this._initialState);
  @override
  PrinterState build() => _initialState;
}

void main() {
  final mockOwner = User(
    id: 'user_1',
    organizationId: 'org_1',
    role: 'owner',
    email: 'owner@test.com',
    name: 'Test Owner',
    isActive: true,
  );

  final mockStaff = User(
    id: 'user_2',
    organizationId: 'org_1',
    role: 'staff',
    email: 'staff@test.com',
    name: 'Test Staff',
    isActive: true,
  );

  final mockOutlet = Outlet(
    id: 'out_1',
    organizationId: 'org_1',
    name: 'Main Kitchen',
    code: 'MK-01',
    address: '123 Test St, Chennai, TN, 600001',
    phone: '9876543210',
    isActive: true,
  );

  final mockActivePrinter1 = Printer(
    id: 'prn_1',
    organizationId: 'org_1',
    outletId: 'out_1',
    outletName: 'Main Kitchen',
    name: 'Counter Bill Printer',
    type: 'Bill',
    printerModel: 'Epson TM-T82',
    conn: 'USB',
    size: '80mm',
    copies: 1,
    categories: const ['Beverages', 'Desserts'],
    isActive: true,
  );

  final mockActivePrinter2 = Printer(
    id: 'prn_2',
    organizationId: 'org_1',
    outletId: 'out_1',
    outletName: 'Main Kitchen',
    name: 'Hot Kitchen KOT',
    type: 'KOT',
    printerModel: 'TVS RP 3200',
    conn: 'LAN 192.168.1.44',
    size: '80mm',
    copies: 2,
    categories: const ['Starters', 'Main Course', 'Rice & Noodles'],
    isActive: true,
  );

  final mockInactivePrinter = Printer(
    id: 'prn_3',
    organizationId: 'org_1',
    outletId: 'out_1',
    outletName: 'Main Kitchen',
    name: 'Old Bar Printer',
    type: 'KOT',
    printerModel: 'NGX N-300',
    conn: 'USB',
    size: '58mm',
    copies: 1,
    categories: const ['Beverages'],
    isActive: false,
  );

  group('Module 15: Printer Model Deserialization & Serialization', () {
    test('#130 Printer.fromJson parses server JSON with populated outlet and categories', () {
      final json = {
        '_id': '6ae00b087878cd44ef7c87a0',
        'organizationId': '6ac78e4f0a063d3e07a1bed5',
        'outletId': {'_id': '6adc341988e080704d1fb5af', 'name': 'Main Kitchen', 'code': 'MK'},
        'name': 'Live KOT Station',
        'type': 'KOT',
        'printerModel': 'Epson TM-T82',
        'conn': 'LAN 192.168.1.44',
        'size': '80mm',
        'copies': 2,
        'categories': ['Beverages', 'Main Course'],
        'isActive': true,
        'createdBy': '6ac78e4f0a063d3e07a1bed6',
        'updatedBy': null,
        'createdAt': '2026-10-27T02:22:54.000Z',
        'updatedAt': '2026-10-27T02:22:54.000Z',
      };

      final printer = Printer.fromJson(json);
      expect(printer.id, '6ae00b087878cd44ef7c87a0');
      expect(printer.organizationId, '6ac78e4f0a063d3e07a1bed5');
      expect(printer.outletId, '6adc341988e080704d1fb5af');
      expect(printer.outletName, 'Main Kitchen');
      expect(printer.name, 'Live KOT Station');
      expect(printer.type, 'KOT');
      expect(printer.isKot, isTrue);
      expect(printer.isBill, isFalse);
      expect(printer.printerModel, 'Epson TM-T82');
      expect(printer.conn, 'LAN 192.168.1.44');
      expect(printer.size, '80mm');
      expect(printer.copies, 2);
      expect(printer.categories, ['Beverages', 'Main Course']);
      expect(printer.isActive, isTrue);
      expect(printer.createdAt, isNotNull);
    });

    test('#129 Printer.toJson generates required payload fields', () {
      final printer = Printer(
        id: 'new_1',
        organizationId: 'org_1',
        outletId: 'out_1',
        name: 'New Bill Printer',
        type: 'Bill',
        printerModel: 'Epson TM-T82',
        conn: 'USB',
        size: '80mm',
        copies: 1,
        categories: const ['Beverages'],
      );

      final json = printer.toJson();
      expect(json['outletId'], 'out_1');
      expect(json['name'], 'New Bill Printer');
      expect(json['type'], 'Bill');
      expect(json['printerModel'], 'Epson TM-T82');
      expect(json['conn'], 'USB');
      expect(json['size'], '80mm');
      expect(json['copies'], 1);
      expect(json['categories'], ['Beverages']);
    });
  });

  group('Module 15: PrinterSettingsScreen UI & Role Permissions', () {
    testWidgets('PrinterSettingsScreen renders active printers, chips, and Add button for Owner', (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 900));

      final state = PrinterState(
        activePrinters: [mockActivePrinter1, mockActivePrinter2],
        inactivePrinters: [mockInactivePrinter],
        isLoading: false,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(() => _FakeAuthController(mockOwner)),
            activeOutletProvider.overrideWith((ref) => mockOutlet),
            printerControllerProvider.overrideWith(() => _FakePrinterController(state)),
          ],
          child: const MaterialApp(home: PrinterSettingsScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Printer Settings (27)'), findsOneWidget);
      expect(find.text('Counter Bill Printer'), findsOneWidget);
      expect(find.text('Hot Kitchen KOT'), findsOneWidget);
      expect(find.text('Bill'), findsOneWidget);
      expect(find.text('KOT'), findsOneWidget);
      expect(find.text('80mm'), findsNWidgets(2));
      expect(find.text('1 copy'), findsOneWidget);
      expect(find.text('2 copies'), findsOneWidget);
      expect(find.text('Add Printer'), findsOneWidget);
      // Confirms NO Test Print button exists
      expect(find.text('Test Print'), findsNothing);
    });

    testWidgets('Staff Role: View-only with no Add, Edit, or Deactivate controls', (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 900));

      final state = PrinterState(
        activePrinters: [mockActivePrinter1],
        isLoading: false,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(() => _FakeAuthController(mockStaff)),
            activeOutletProvider.overrideWith((ref) => mockOutlet),
            printerControllerProvider.overrideWith(() => _FakePrinterController(state)),
          ],
          child: const MaterialApp(home: PrinterSettingsScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Counter Bill Printer'), findsOneWidget);
      expect(find.text('Add Printer'), findsNothing);
      expect(find.text('Edit'), findsNothing);
      expect(find.text('Deactivate'), findsNothing);
      expect(find.text('Test Print'), findsNothing);
    });

    testWidgets('Show Inactive toggle displays inactive printers and Restore button', (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 900));

      final state = PrinterState(
        activePrinters: [mockActivePrinter1],
        inactivePrinters: [mockInactivePrinter],
        showInactive: true,
        isLoading: false,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(() => _FakeAuthController(mockOwner)),
            activeOutletProvider.overrideWith((ref) => mockOutlet),
            printerControllerProvider.overrideWith(() => _FakePrinterController(state)),
          ],
          child: const MaterialApp(home: PrinterSettingsScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Old Bar Printer'), findsOneWidget);
      expect(find.text('Inactive Printers (1)'), findsOneWidget);
      expect(find.text('Restore'), findsOneWidget);
      expect(find.text('Delete permanently'), findsOneWidget);
    });

    testWidgets('Responsiveness: 360x800 portrait with no overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final state = PrinterState(
        activePrinters: [mockActivePrinter1, mockActivePrinter2],
        isLoading: false,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(() => _FakeAuthController(mockOwner)),
            activeOutletProvider.overrideWith((ref) => mockOutlet),
            printerControllerProvider.overrideWith(() => _FakePrinterController(state)),
          ],
          child: const MaterialApp(home: PrinterSettingsScreen()),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('Responsiveness: 800x360 landscape with no overflow', (tester) async {
      tester.view.physicalSize = const Size(800, 360);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final state = PrinterState(
        activePrinters: [mockActivePrinter1, mockActivePrinter2],
        isLoading: false,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(() => _FakeAuthController(mockOwner)),
            activeOutletProvider.overrideWith((ref) => mockOutlet),
            printerControllerProvider.overrideWith(() => _FakePrinterController(state)),
          ],
          child: const MaterialApp(home: PrinterSettingsScreen()),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('Responsiveness: 360x800 with 1.5x font scale with no overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final state = PrinterState(
        activePrinters: [mockActivePrinter1, mockActivePrinter2],
        isLoading: false,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(() => _FakeAuthController(mockOwner)),
            activeOutletProvider.overrideWith((ref) => mockOutlet),
            printerControllerProvider.overrideWith(() => _FakePrinterController(state)),
          ],
          child: const MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(
                textScaler: TextScaler.linear(1.5),
              ),
              child: PrinterSettingsScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
