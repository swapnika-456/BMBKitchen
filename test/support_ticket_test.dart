import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bmb_kitchen/models/models.dart';
import 'package:bmb_kitchen/models/user.dart';
import 'package:bmb_kitchen/features/auth/controllers/auth_controller.dart';
import 'package:bmb_kitchen/features/settings/controllers/outlet_controller.dart';
import 'package:bmb_kitchen/features/support/controllers/support_ticket_controller.dart';
import 'package:bmb_kitchen/features/settings/screens/support_helpdesk_screen.dart';

// Mock Tickets
final mockTicket1 = SupportTicket(
  id: 'tkt_1',
  organizationId: 'org_test_1',
  outletId: 'out_1',
  outletName: 'Main Kitchen',
  ticketNo: 'TKT-0001',
  subject: 'POS printer disconnected',
  category: 'Printer',
  priority: 'High',
  details: 'Network error communicating with LAN printer',
  status: 'Open',
  raisedBy: 'user_1',
  raisedByName: 'John Doe',
  isActive: true,
  createdAt: DateTime(2026, 10, 27, 10, 30),
);

final mockTicket2 = SupportTicket(
  id: 'tkt_2',
  organizationId: 'org_test_1',
  outletId: 'out_2',
  outletName: 'Downtown Branch',
  ticketNo: 'TKT-0002',
  subject: 'Discrepancy in day closing cash',
  category: 'Billing / POS',
  priority: 'Medium',
  details: 'Cash count does not match register drawer',
  status: 'In progress',
  raisedBy: 'user_2',
  raisedByName: 'Jane Smith',
  isActive: true,
  createdAt: DateTime(2026, 10, 27, 11, 0),
);

final mockTicketInactive = SupportTicket(
  id: 'tkt_3',
  organizationId: 'org_test_1',
  outletId: 'out_1',
  outletName: 'Main Kitchen',
  ticketNo: 'TKT-0003',
  subject: 'Old question about tax rate',
  category: 'Reports',
  priority: 'Low',
  details: 'Resolved earlier',
  status: 'Closed',
  isActive: false,
  createdAt: DateTime(2026, 10, 26, 14, 0),
);

final mockOutlet1 = Outlet(
  id: 'out_1',
  code: 'MK',
  name: 'Main Kitchen',
  address: '123 Main St',
  phone: '9876543210',
  organizationId: 'org_test_1',
  isActive: true,
);

final mockOutlet2 = Outlet(
  id: 'out_2',
  code: 'DB',
  name: 'Downtown Branch',
  address: '456 Market St',
  phone: '9876543211',
  organizationId: 'org_test_1',
  isActive: true,
);

class _FakeAuthController extends AuthController {
  final User? _user;
  _FakeAuthController(this._user);

  @override
  Future<User?> build() async => _user;
}

class _FakeSupportTicketController extends SupportTicketController {
  final SupportTicketState _initialState;
  _FakeSupportTicketController(this._initialState);

  @override
  Future<SupportTicketState> build() async => _initialState;
}

class _FakeOutletController extends OutletController {
  final List<Outlet> _outlets;
  _FakeOutletController(this._outlets);

  @override
  Future<List<Outlet>> build() async => _outlets;
}

Widget createTestWidget({
  required String role,
  SupportTicketState? state,
  List<Outlet>? outlets,
  double textScaleFactor = 1.0,
}) {
  final user = User(
    id: 'user_test',
    email: 'test@bmb.com',
    name: 'Tester',
    role: role,
    organizationId: 'org_test_1',
    isActive: true,
  );

  final ticketState = state ??
      SupportTicketState(
        activeTickets: [mockTicket1, mockTicket2],
        inactiveTickets: [mockTicketInactive],
      );

  return ProviderScope(
    overrides: [
      authControllerProvider.overrideWith(() => _FakeAuthController(user)),
      supportTicketControllerProvider.overrideWith(() => _FakeSupportTicketController(ticketState)),
      outletControllerProvider.overrideWith(() => _FakeOutletController(outlets ?? [mockOutlet1, mockOutlet2])),
    ],
    child: MaterialApp(
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScaleFactor),
          ),
          child: child!,
        );
      },
      home: const SupportHelpdeskScreen(),
    ),
  );
}

void main() {
  group('Module 18: Support Ticket Model Deserialization & Serialization', () {
    test('#138 SupportTicket.fromJson parses server JSON with populated objects', () {
      final json = {
        "_id": "6ae08cf47878cd44ef7c8841",
        "organizationId": "6ac78e4f0a063d3e07a1bed5",
        "outletId": {
          "_id": "6adc5b307878cd44ef7c86b4",
          "name": "Downtown Branch",
          "code": "TO2"
        },
        "ticketNo": "TKT-0003",
        "subject": "Test Ticket C - Numbering",
        "category": "Reports",
        "priority": "High",
        "details": "Details for ticket C",
        "status": "Closed",
        "raisedBy": {
          "_id": "6ac78e4f0a063d3e07a1bed6",
          "userName": "Admin User"
        },
        "isActive": true,
        "createdBy": "6ac78e4f0a063d3e07a1bed6",
        "updatedBy": "6ac78e4f0a063d3e07a1bed6",
        "createdAt": "2026-10-27T11:37:24.813Z",
        "updatedAt": "2026-10-27T11:37:25.013Z"
      };

      final ticket = SupportTicket.fromJson(json);
      expect(ticket.id, "6ae08cf47878cd44ef7c8841");
      expect(ticket.organizationId, "6ac78e4f0a063d3e07a1bed5");
      expect(ticket.outletId, "6adc5b307878cd44ef7c86b4");
      expect(ticket.outletName, "Downtown Branch");
      expect(ticket.ticketNo, "TKT-0003");
      expect(ticket.subject, "Test Ticket C - Numbering");
      expect(ticket.category, "Reports");
      expect(ticket.priority, "High");
      expect(ticket.details, "Details for ticket C");
      expect(ticket.status, "Closed");
      expect(ticket.isClosed, isTrue);
      expect(ticket.raisedBy, "6ac78e4f0a063d3e07a1bed6");
      expect(ticket.raisedByName, "Admin User");
      expect(ticket.isActive, isTrue);
    });

    test('#137 SupportTicket.toServerPayload generates only payload fields', () {
      final ticket = SupportTicket(
        id: 'temp_id',
        organizationId: 'org_1',
        outletId: 'out_1',
        ticketNo: 'TKT-999',
        subject: '  POS issue  ',
        category: 'Billing / POS',
        priority: 'High',
        details: 'Payment sync failed',
      );

      final payload = ticket.toServerPayload();
      expect(payload['outletId'], 'out_1');
      expect(payload['subject'], 'POS issue'); // trimmed
      expect(payload['category'], 'Billing / POS');
      expect(payload['priority'], 'High');
      expect(payload['details'], 'Payment sync failed');
      // Read-only server fields excluded
      expect(payload.containsKey('ticketNo'), isFalse);
      expect(payload.containsKey('status'), isFalse);
      expect(payload.containsKey('id'), isFalse);
    });

    test('Sequential status transitions and labels', () {
      final tOpen = SupportTicket(
        id: '1', organizationId: 'o', outletId: 'a', ticketNo: 'T1', subject: 'S1', status: 'Open',
      );
      expect(tOpen.nextStatus, 'In progress');
      expect(tOpen.nextActionLabel, 'Start Progress');

      final tInProg = SupportTicket(
        id: '2', organizationId: 'o', outletId: 'a', ticketNo: 'T2', subject: 'S2', status: 'In progress',
      );
      expect(tInProg.nextStatus, 'Closed');
      expect(tInProg.nextActionLabel, 'Close Ticket');

      final tClosed = SupportTicket(
        id: '3', organizationId: 'o', outletId: 'a', ticketNo: 'T3', subject: 'S3', status: 'Closed',
      );
      expect(tClosed.nextStatus, 'Open');
      expect(tClosed.nextActionLabel, 'Reopen Ticket');
    });
  });

  group('Module 18: SupportHelpdeskScreen UI & Role Permissions', () {
    testWidgets('SupportHelpdeskScreen renders tickets list, KPI cards, and action buttons for Owner', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createTestWidget(role: 'owner'));
      await tester.pumpAndSettle();

      expect(find.text('Support & Helpdesk'), findsOneWidget);
      expect(find.text('Ticket #TKT-0001'), findsOneWidget);
      expect(find.text('POS printer disconnected'), findsOneWidget);
      expect(find.text('Ticket #TKT-0002'), findsOneWidget);
      expect(find.text('Discrepancy in day closing cash'), findsOneWidget);

      // KPI counts
      expect(find.text('Open'), findsWidgets);
      expect(find.text('In Progress'), findsWidgets);
      expect(find.text('Closed'), findsWidgets);

      // Owner can see Advance button and Deactivate button
      expect(find.text('Start Progress'), findsOneWidget); // For TKT-0001 (Open -> In progress)
      expect(find.text('Close Ticket'), findsOneWidget); // For TKT-0002 (In progress -> Closed)
      expect(find.text('Deactivate'), findsNWidgets(2));
      expect(find.text('+ Raise ticket'), findsOneWidget);
    });

    testWidgets('Staff Role: Can create and view details, but cannot advance status or deactivate', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createTestWidget(role: 'staff'));
      await tester.pumpAndSettle();

      expect(find.text('Ticket #TKT-0001'), findsOneWidget);
      expect(find.text('Details'), findsNWidgets(2));
      expect(find.text('+ Raise ticket'), findsOneWidget);

      // Status advance and Deactivate buttons MUST BE HIDDEN for staff
      expect(find.text('Start Progress'), findsNothing);
      expect(find.text('Close Ticket'), findsNothing);
      expect(find.text('Deactivate'), findsNothing);
      expect(find.text('Show Inactive'), findsNothing);
    });

    testWidgets('Empty State: Renders "No support tickets found" when active list is empty', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        createTestWidget(
          role: 'owner',
          state: const SupportTicketState(activeTickets: [], inactiveTickets: []),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No support tickets found'), findsOneWidget);
    });
  });

  group('Module 18: SupportHelpdeskScreen Viewport Responsiveness', () {
    testWidgets('Responsiveness: 360x800 portrait with no overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createTestWidget(role: 'owner'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('Responsiveness: 800x360 landscape with no overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 360));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createTestWidget(role: 'owner'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('Responsiveness: 360x800 with 1.5x font scale with no overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createTestWidget(role: 'owner', textScaleFactor: 1.5));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
