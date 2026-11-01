import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bmb_kitchen/models/day_closing.dart';
import 'package:bmb_kitchen/models/user.dart';
import 'package:bmb_kitchen/features/auth/controllers/auth_controller.dart';
import 'package:bmb_kitchen/features/finance/controllers/day_closing_controller.dart';
import 'package:bmb_kitchen/features/finance/screens/day_closing_screen.dart';
import 'package:bmb_kitchen/features/settings/controllers/active_outlet_provider.dart';
import 'package:bmb_kitchen/models/outlet.dart';

void main() {
  group('Module 14: Day Closing Models Deserialization Tests', () {
    test('#104 DayClosingSummary parses live server JSON correctly', () {
      final json = {
        "outletId": "6adc341988e080704d1fb5af",
        "closingDate": "2026-10-24",
        "totalSales": 731,
        "cashSales": 310.5,
        "upiSales": 0,
        "cardSales": 0,
        "onlinePaid": 0,
        "creditAmount": 0,
        "discountsGiven": 10,
        "cashExpensesPaidOut": 0,
        "totalExpensesToday": 0,
        "billsSettled": 7,
        "cancelledOrders": 3,
        "expectedCash": 310.5
      };

      final summary = DayClosingSummary.fromJson(json);

      expect(summary.outletId, '6adc341988e080704d1fb5af');
      expect(summary.closingDate, '2026-10-24');
      expect(summary.totalSales, 731.0);
      expect(summary.cashSales, 310.5);
      expect(summary.expectedCash, 310.5);
      expect(summary.billsSettled, 7);
      expect(summary.cancelledOrders, 3);
      expect(summary.discountsGiven, 10.0);
    });

    test('#105/#106 DayClosing parses closing record with differences and status', () {
      final json = {
        "_id": "6ae000107878cd44ef7c8798",
        "organizationId": "6ac78e4f0a063d3e07a1bed5",
        "outletId": {
          "_id": "6adc341988e080704d1fb5af",
          "name": "THROWAWAY_ORDER_TEST_OUTLET",
          "code": "TOT"
        },
        "closingNo": "DC-001",
        "closingDate": "2026-10-24",
        "totalSales": 731,
        "cashSales": 310.5,
        "upiSales": 0,
        "cardSales": 0,
        "onlinePaid": 0,
        "creditAmount": 0,
        "discountsGiven": 10,
        "cashExpensesPaidOut": 0,
        "totalExpensesToday": 0,
        "billsSettled": 7,
        "cancelledOrders": 3,
        "expectedCash": 310.5,
        "actualCash": 360.5,
        "difference": 50,
        "closedBy": {"_id": "6ac78e4f0a063d3e07a1bed6", "name": "Admin User"},
        "note": "Test Day Closing",
        "status": "locked",
        "createdAt": "2026-10-27T01:36:16.409Z",
        "updatedAt": "2026-10-27T01:36:16.409Z"
      };

      final closing = DayClosing.fromJson(json);

      expect(closing.id, '6ae000107878cd44ef7c8798');
      expect(closing.closingNo, 'DC-001');
      expect(closing.closingDate, '2026-10-24');
      expect(closing.outletId, '6adc341988e080704d1fb5af');
      expect(closing.outletName, 'THROWAWAY_ORDER_TEST_OUTLET');
      expect(closing.actualCash, 360.5);
      expect(closing.expectedCash, 310.5);
      expect(closing.difference, 50.0);
      expect(closing.isLocked, true);
      expect(closing.isReopened, false);
      expect(closing.closedBy, 'Admin User');
    });

    test('#108 DayClosing parses reopened fields and reasons', () {
      final json = {
        "_id": "6ae000107878cd44ef7c8798",
        "organizationId": "6ac78e4f0a063d3e07a1bed5",
        "outletId": "6adc341988e080704d1fb5af",
        "closingNo": "DC-001",
        "closingDate": "2026-10-24",
        "totalSales": 731,
        "actualCash": 360.5,
        "difference": 50,
        "status": "reopened",
        "reopenedBy": "6ac78e4f0a063d3e07a1bed6",
        "reopenedAt": "2026-10-27T01:36:16.581Z",
        "reopenReason": "Auditing discrepancy"
      };

      final closing = DayClosing.fromJson(json);

      expect(closing.isLocked, false);
      expect(closing.isReopened, true);
      expect(closing.reopenReason, 'Auditing discrepancy');
      expect(closing.reopenedBy, '6ac78e4f0a063d3e07a1bed6');
    });
  });

  group('Module 14: DayClosingScreen UI & Responsiveness', () {
    final mockOutlet = Outlet(
      id: '6adc341988e080704d1fb5af',
      organizationId: '6ac78e4f0a063d3e07a1bed5',
      name: 'Main Kitchen',
      code: 'MK01',
      address: '123 Main St',
      phone: '9999999999',
      isActive: true,
    );

    final mockUser = User(
      id: 'user_1',
      name: 'Test Owner',
      email: 'owner@bmb.com',
      role: 'owner',
      organizationId: 'org_1',
      isActive: true,
    );

    final mockSummary = DayClosingSummary(
      outletId: '6adc341988e080704d1fb5af',
      closingDate: '2026-10-24',
      totalSales: 731.0,
      cashSales: 310.5,
      expectedCash: 310.5,
      billsSettled: 7,
      cancelledOrders: 3,
      discountsGiven: 10.0,
    );

    final mockClosing = DayClosing(
      id: 'closing_1',
      organizationId: 'org_1',
      outletId: '6adc341988e080704d1fb5af',
      closingNo: 'DC-001',
      closingDate: '2026-10-24',
      totalSales: 731.0,
      cashSales: 310.5,
      expectedCash: 310.5,
      actualCash: 360.5,
      difference: 50.0,
      status: 'locked',
    );

    testWidgets('DayClosingScreen renders #104 live summary and closing form when not closed', (tester) async {
      final mockState = DayClosingState(
        selectedDate: '2026-10-24',
        summary: AsyncValue.data(mockSummary),
        closing: const AsyncValue.data(null), // not closed yet
        history: const AsyncValue.data([]),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeOutletProvider.overrideWith((ref) => mockOutlet),
            authControllerProvider.overrideWith(() => _FakeAuthController(mockUser)),
            dayClosingControllerProvider.overrideWith(() => _MockDayClosingController(mockState)),
          ],
          child: const MaterialApp(
            home: DayClosingScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('End-of-Day Closing (26)'), findsOneWidget);
      expect(find.text('Live Day Summary (#104)'), findsOneWidget);
      expect(find.text('₹731.00'), findsOneWidget); // Total sales
      expect(find.text('₹310.50'), findsNWidgets(2)); // Expected cash and cash sales
      expect(find.text('7'), findsOneWidget); // Bills settled
      expect(find.text('Record Day Closing (#105)'), findsOneWidget);
      expect(find.text('Lock & Submit Day Closing'), findsOneWidget);
    });

    testWidgets('DayClosingScreen renders locked closing card with kDayReopenEnabled check', (tester) async {
      final mockState = DayClosingState(
        selectedDate: '2026-10-24',
        summary: AsyncValue.data(mockSummary),
        closing: AsyncValue.data(mockClosing), // already closed
        history: AsyncValue.data([mockClosing]),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeOutletProvider.overrideWith((ref) => mockOutlet),
            authControllerProvider.overrideWith(() => _FakeAuthController(mockUser)),
            dayClosingControllerProvider.overrideWith(() => _MockDayClosingController(mockState)),
          ],
          child: const MaterialApp(
            home: DayClosingScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Closing #DC-001'), findsOneWidget);
      expect(find.text('Locked'), findsOneWidget);
      expect(find.text('+₹50.00'), findsOneWidget); // Difference
      // Since kDayReopenEnabled = false, Reopen button is hidden behind the constant
      expect(find.text('Closing is locked.'), findsOneWidget);
      expect(find.text('Reopen Closing (#108)'), findsNothing);
    });

    testWidgets('DayClosingScreen renders reopened closing notice when status is reopened', (tester) async {
      final reopenedClosing = mockClosing.copyWith(
        status: 'reopened',
        reopenedBy: 'audit-manager@example.com',
        reopenReason: 'Auditing discrepancy',
      );
      final mockState = DayClosingState(
        selectedDate: '2026-10-24',
        summary: AsyncValue.data(mockSummary),
        closing: AsyncValue.data(reopenedClosing),
        history: AsyncValue.data([reopenedClosing]),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeOutletProvider.overrideWith((ref) => mockOutlet),
            authControllerProvider.overrideWith(() => _FakeAuthController(mockUser)),
            dayClosingControllerProvider.overrideWith(() => _MockDayClosingController(mockState)),
          ],
          child: const MaterialApp(
            home: DayClosingScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Closing #DC-001'), findsOneWidget);
      expect(find.text('Reopened'), findsOneWidget);
      expect(find.text("Reopened. It can't be closed again until the backend supports it."), findsOneWidget);
    });

    testWidgets('Responsiveness: DayClosingScreen at 360x800 with 1.5x font scale with no overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final mockState = DayClosingState(
        selectedDate: '2026-10-24',
        summary: AsyncValue.data(mockSummary),
        closing: AsyncValue.data(mockClosing),
        history: AsyncValue.data([mockClosing]),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeOutletProvider.overrideWith((ref) => mockOutlet),
            authControllerProvider.overrideWith(() => _FakeAuthController(mockUser)),
            dayClosingControllerProvider.overrideWith(() => _MockDayClosingController(mockState)),
          ],
          child: const MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(
                size: Size(360, 800),
                textScaler: TextScaler.linear(1.5),
              ),
              child: DayClosingScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('Responsiveness: DayClosingScreen at 800x360 landscape with no overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 360));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final mockState = DayClosingState(
        selectedDate: '2026-10-24',
        summary: AsyncValue.data(mockSummary),
        closing: const AsyncValue.data(null),
        history: const AsyncValue.data([]),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeOutletProvider.overrideWith((ref) => mockOutlet),
            authControllerProvider.overrideWith(() => _FakeAuthController(mockUser)),
            dayClosingControllerProvider.overrideWith(() => _MockDayClosingController(mockState)),
          ],
          child: const MaterialApp(
            home: DayClosingScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}

class _FakeAuthController extends AuthController {
  final User? _user;
  _FakeAuthController(this._user);

  @override
  Future<User?> build() async => _user;
}

class _MockDayClosingController extends DayClosingController {
  final DayClosingState _initial;
  _MockDayClosingController(this._initial);

  @override
  DayClosingState build() => _initial;

  @override
  Future<void> loadAll() async {}
}
