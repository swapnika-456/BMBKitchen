import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bmb_kitchen/models/subscription.dart';
import 'package:bmb_kitchen/models/user.dart';
import 'package:bmb_kitchen/models/outlet.dart';
import 'package:bmb_kitchen/features/auth/controllers/auth_controller.dart';
import 'package:bmb_kitchen/features/settings/controllers/outlet_controller.dart';
import 'package:bmb_kitchen/features/subscription/controllers/subscription_controller.dart';
import 'package:bmb_kitchen/features/settings/screens/subscription_screen.dart';

// Mock Users
final mockOwner = User(
  id: 'usr_owner',
  name: 'Owner User',
  email: 'owner@example.com',
  organizationId: 'org_test_1',
  role: 'owner',
  isActive: true,
);

final mockAdmin = User(
  id: 'usr_admin',
  name: 'Admin User',
  email: 'admin@example.com',
  organizationId: 'org_test_1',
  role: 'admin',
  isActive: true,
);

final mockStaff = User(
  id: 'usr_staff',
  name: 'Staff User',
  email: 'staff@example.com',
  organizationId: 'org_test_1',
  role: 'staff',
  isActive: true,
);

class _FakeAuthController extends AuthController {
  final User? _user;
  _FakeAuthController(this._user);

  @override
  Future<User?> build() async => _user;
}

// Mock Outlets
final mockOutlet1 = Outlet(
  id: 'out_1',
  name: 'Main Kitchen',
  code: 'MK',
  organizationId: 'org_test_1',
  address: 'Address 1',
  phone: '1234567890',
  isActive: true,
);

final mockOutlet2 = Outlet(
  id: 'out_2',
  name: 'Branch Outlet',
  code: 'BO',
  organizationId: 'org_test_1',
  address: 'Address 2',
  phone: '0987654321',
  isActive: true,
);

class _FakeOutletController extends OutletController {
  final List<Outlet> _outlets;
  _FakeOutletController(this._outlets);

  @override
  Future<List<Outlet>> build() async => _outlets;
}

// Mock Subscription
final mockInvoice = SubscriptionInvoice(
  id: 'inv_1',
  invoiceNo: 'INV-SUB-001',
  date: DateTime(2026, 10, 27, 11, 16),
  amount: 999.0,
  status: 'Paid',
);

final mockSubscription = Subscription(
  id: 'sub_1',
  organizationId: 'org_test_1',
  plan: 'Starter',
  price: 999.0,
  cycle: 'monthly',
  outletsIncluded: 2,
  startedAt: DateTime(2026, 10, 27),
  renewsAt: DateTime(2027, 10, 27),
  status: 'active',
  invoices: [mockInvoice],
);

class _FakeSubscriptionController extends SubscriptionController {
  final SubscriptionState _state;
  _FakeSubscriptionController(this._state);

  @override
  Future<SubscriptionState> build() async => _state;
}

Widget createTestWidget({
  required User? user,
  required SubscriptionState subState,
  List<Outlet>? outlets,
  Size size = const Size(390, 844),
  double textScale = 1.0,
}) {
  final effectiveOutlets = outlets ?? [mockOutlet1, mockOutlet2];
  return ProviderScope(
    overrides: [
      authControllerProvider.overrideWith(() => _FakeAuthController(user)),
      outletControllerProvider.overrideWith(() => _FakeOutletController(effectiveOutlets)),
      subscriptionControllerProvider.overrideWith(
        () => _FakeSubscriptionController(subState),
      ),
    ],
    child: MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
        ),
        child: const SubscriptionScreen(),
      ),
    ),
  );
}

void main() {
  group('Module 17: Subscription Models Deserialization & Serialization', () {
    test('#109 Subscription.fromJson parses server JSON with invoices', () {
      final json = {
        '_id': '6ae0880f7878cd44ef7c882e',
        'organizationId': '6ac78e4f0a063d3e07a1bed5',
        'plan': 'Starter',
        'price': 999,
        'cycle': 'monthly',
        'outletsIncluded': 1,
        'renewsAt': '2027-10-27T11:16:31.361Z',
        'status': 'active',
        'createdBy': '6ac78e4f0a063d3e07a1bed6',
        'startedAt': '2026-10-27T11:16:31.628Z',
        'invoices': [
          {
            '_id': '6ae0880f7878cd44ef7c882f',
            'invoiceNo': 'INV-SUB-001',
            'date': '2026-10-27T11:16:31.509Z',
            'amount': 999,
            'status': 'Paid',
          }
        ],
        'createdAt': '2026-10-27T11:16:31.638Z',
        'updatedAt': '2026-10-27T11:16:31.946Z',
      };

      final sub = Subscription.fromJson(json);
      expect(sub.id, '6ae0880f7878cd44ef7c882e');
      expect(sub.organizationId, '6ac78e4f0a063d3e07a1bed5');
      expect(sub.plan, 'Starter');
      expect(sub.price, 999.0);
      expect(sub.cycle, 'monthly');
      expect(sub.outletsIncluded, 1);
      expect(sub.status, 'active');
      expect(sub.isActive, isTrue);
      expect(sub.invoices.length, 1);
      expect(sub.invoices.first.invoiceNo, 'INV-SUB-001');
      expect(sub.invoices.first.amount, 999.0);
      expect(sub.invoices.first.status, 'Paid');
    });

    test('#110 Subscription.toJson outputs only payload fields', () {
      final sub = Subscription(
        id: 'sub_dummy',
        organizationId: 'org_dummy',
        plan: 'Growth',
        price: 2499.0,
        cycle: 'monthly',
        outletsIncluded: 3,
        renewsAt: DateTime(2027, 10, 27),
        status: 'active',
      );

      final json = sub.toJson();
      expect(json['plan'], 'Growth');
      expect(json['price'], 2499.0);
      expect(json['cycle'], 'monthly');
      expect(json['outletsIncluded'], 3);
      expect(json.containsKey('_id'), isFalse);
      expect(json.containsKey('organizationId'), isFalse);
      expect(json.containsKey('createdAt'), isFalse);
    });

    test('#113 SubscriptionInvoice.fromJson parses invoice list items', () {
      final json = {
        '_id': 'inv_123',
        'invoiceNo': 'INV-2026-002',
        'date': '2026-10-27T10:00:00.000Z',
        'amount': 1500,
        'status': 'Pending',
      };

      final inv = SubscriptionInvoice.fromJson(json);
      expect(inv.id, 'inv_123');
      expect(inv.invoiceNo, 'INV-2026-002');
      expect(inv.amount, 1500.0);
      expect(inv.status, 'Pending');
    });
  });

  group('Module 17: SubscriptionScreen UI & Role Permissions', () {
    testWidgets('SubscriptionScreen renders Plan Card, Outlet Usage, and Invoice List for Owner', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          user: mockOwner,
          subState: SubscriptionState(
            subscription: mockSubscription,
            invoices: [mockInvoice],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Top bar & Title
      expect(find.text('Subscription'), findsOneWidget);
      // Plan overview
      expect(find.text('Starter Plan'), findsOneWidget);
      expect(find.text('₹999.00 / monthly'), findsOneWidget);
      expect(find.text('ACTIVE'), findsOneWidget);
      // Outlet usage
      expect(find.text('Using 2 of 2 outlets'), findsOneWidget);
      expect(find.text('Informational'), findsOneWidget);
      // Invoices
      expect(find.text('Billing Invoices (#113)'), findsOneWidget);
      expect(find.text('INV-SUB-001'), findsOneWidget);
      expect(find.text('PAID'), findsOneWidget);
    });

    testWidgets('Staff Role: Access Restricted message displayed and screen content hidden', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          user: mockStaff,
          subState: SubscriptionState(
            subscription: mockSubscription,
            invoices: [mockInvoice],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Access Restricted'), findsOneWidget);
      expect(
        find.text('Subscription management is restricted to Owner, Admin, and CTO accounts only.'),
        findsOneWidget,
      );
      // Plan and invoices must not be rendered
      expect(find.text('Starter Plan'), findsNothing);
      expect(find.text('INV-SUB-001'), findsNothing);
    });

    testWidgets('Admin Role: Full access to plan and invoices', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          user: mockAdmin,
          subState: SubscriptionState(
            subscription: mockSubscription,
            invoices: [mockInvoice],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Starter Plan'), findsOneWidget);
      expect(find.text('Using 2 of 2 outlets'), findsOneWidget);
      expect(find.text('INV-SUB-001'), findsOneWidget);
    });

    testWidgets('Empty State: Renders "No subscription yet" when subscription is null', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          user: mockOwner,
          subState: const SubscriptionState(
            subscription: null,
            invoices: [],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No subscription yet'), findsOneWidget);
      expect(find.text('Starter Plan'), findsNothing);
    });

    testWidgets('Write actions are hidden when kSubscriptionWriteEnabled is false', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          user: mockOwner,
          subState: SubscriptionState(
            subscription: mockSubscription,
            invoices: [mockInvoice],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(kSubscriptionWriteEnabled, isFalse);
      expect(find.text('Change Plan'), findsNothing);
      expect(find.text('Create Subscription'), findsNothing);
      expect(find.text('Add Invoice'), findsNothing);
    });
  });

  group('Module 17: SubscriptionScreen Viewport Responsiveness', () {
    testWidgets('Responsiveness: 360x800 portrait with no overflow', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          user: mockOwner,
          subState: SubscriptionState(
            subscription: mockSubscription,
            invoices: [mockInvoice],
          ),
          size: const Size(360, 800),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Starter Plan'), findsOneWidget);
    });

    testWidgets('Responsiveness: 800x360 landscape with no overflow', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          user: mockOwner,
          subState: SubscriptionState(
            subscription: mockSubscription,
            invoices: [mockInvoice],
          ),
          size: const Size(800, 360),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Starter Plan'), findsOneWidget);
    });

    testWidgets('Responsiveness: 360x800 with 1.5x font scale with no overflow', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          user: mockOwner,
          subState: SubscriptionState(
            subscription: mockSubscription,
            invoices: [mockInvoice],
          ),
          size: const Size(360, 800),
          textScale: 1.5,
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Starter Plan'), findsOneWidget);
    });
  });
}
