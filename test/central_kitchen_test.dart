import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bmb_kitchen/models/central_kitchen_transfer.dart';
import 'package:bmb_kitchen/models/user.dart';
import 'package:bmb_kitchen/features/auth/controllers/auth_controller.dart';
import 'package:bmb_kitchen/features/central_kitchen/controllers/central_kitchen_controller.dart';
import 'package:bmb_kitchen/features/settings/screens/central_kitchen_screen.dart';

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

// Mock Transfers
const mockTransferRequested = CentralKitchenTransfer(
  id: 't_req_1',
  organizationId: 'org_test_1',
  transferNo: 'TR-001',
  fromOutletId: 'out_1',
  fromOutletName: 'Main Kitchen',
  toOutletId: 'out_2',
  toOutletName: 'Downtown Branch',
  lines: [
    CentralKitchenTransferLine(
      id: 'line_1',
      inventoryId: 'inv_salt',
      materialName: 'Cooking Salt',
      quantity: 5.0,
    ),
  ],
  value: 100.0,
  status: 'Requested',
  isActive: true,
);

const mockTransferApproved = CentralKitchenTransfer(
  id: 't_app_2',
  organizationId: 'org_test_1',
  transferNo: 'TR-002',
  fromOutletId: 'out_1',
  fromOutletName: 'Main Kitchen',
  toOutletId: 'out_2',
  toOutletName: 'Downtown Branch',
  lines: [
    CentralKitchenTransferLine(
      id: 'line_2',
      inventoryId: 'inv_flour',
      materialName: 'Wheat Flour',
      quantity: 10.0,
    ),
  ],
  value: 400.0,
  status: 'Approved',
  isActive: true,
);

const mockTransferDispatched = CentralKitchenTransfer(
  id: 't_disp_3',
  organizationId: 'org_test_1',
  transferNo: 'TR-003',
  fromOutletId: 'out_1',
  fromOutletName: 'Main Kitchen',
  toOutletId: 'out_2',
  toOutletName: 'Downtown Branch',
  lines: [
    CentralKitchenTransferLine(
      id: 'line_3',
      inventoryId: 'inv_sugar',
      materialName: 'Sugar',
      quantity: 2.0,
    ),
  ],
  value: 80.0,
  status: 'Dispatched',
  isActive: true,
);

const mockTransferInactive = CentralKitchenTransfer(
  id: 't_inact_4',
  organizationId: 'org_test_1',
  transferNo: 'TR-004',
  fromOutletId: 'out_1',
  fromOutletName: 'Main Kitchen',
  toOutletId: 'out_2',
  toOutletName: 'Downtown Branch',
  lines: [
    CentralKitchenTransferLine(
      id: 'line_4',
      inventoryId: 'inv_oil',
      materialName: 'Mustard Oil',
      quantity: 1.0,
    ),
  ],
  value: 150.0,
  status: 'Requested',
  isActive: false,
);

class _FakeCentralKitchenController extends CentralKitchenController {
  final CentralKitchenState _initialState;
  _FakeCentralKitchenController(this._initialState);

  @override
  Future<CentralKitchenState> build() async => _initialState;
}

void main() {
  group('Module 16: Central Kitchen Model Deserialization & Serialization', () {
    test('#120 CentralKitchenTransfer.fromJson parses server JSON with populated outlets and lines', () {
      final json = {
        "_id": "6ae07ddc7878cd44ef7c87c4",
        "organizationId": "6ac78e4f0a063d3e07a1bed5",
        "transferNo": "TR-001",
        "fromOutletId": {
          "_id": "6adc341988e080704d1fb5af",
          "name": "THROWAWAY_ORDER_TEST_OUTLET",
          "code": "TOT"
        },
        "toOutletId": {
          "_id": "6adc5b307878cd44ef7c86b4",
          "name": "THROWAWAY_OUTLET_2",
          "code": "TO2"
        },
        "lines": [
          {
            "inventoryId": {
              "_id": "6adc33ec88e080704d1fb5ac",
              "material": "Salt",
              "rate": 20
            },
            "quantity": 5,
            "_id": "6ae07ddc7878cd44ef7c87c5"
          }
        ],
        "value": 100,
        "status": "Dispatched",
        "isActive": true,
        "createdBy": "6ac78e4f0a063d3e07a1bed6",
        "updatedBy": "6ac78e4f0a063d3e07a1bed6",
        "createdAt": "2026-10-27T10:33:00.982Z",
        "updatedAt": "2026-10-27T10:33:01.144Z"
      };

      final transfer = CentralKitchenTransfer.fromJson(json);

      expect(transfer.id, "6ae07ddc7878cd44ef7c87c4");
      expect(transfer.transferNo, "TR-001");
      expect(transfer.fromOutletId, "6adc341988e080704d1fb5af");
      expect(transfer.fromOutletName, "THROWAWAY_ORDER_TEST_OUTLET");
      expect(transfer.toOutletId, "6adc5b307878cd44ef7c86b4");
      expect(transfer.toOutletName, "THROWAWAY_OUTLET_2");
      expect(transfer.lines.length, 1);
      expect(transfer.lines[0].inventoryId, "6adc33ec88e080704d1fb5ac");
      expect(transfer.lines[0].materialName, "Salt");
      expect(transfer.lines[0].quantity, 5.0);
      expect(transfer.value, 100.0);
      expect(transfer.status, "Dispatched");
      expect(transfer.isDispatched, isTrue);
      expect(transfer.nextStatus, "Received");
      expect(transfer.nextActionLabel, "Mark received");
    });

    test('Exact sequential stage names and nextActionLabel values for #123', () {
      const tReq = CentralKitchenTransfer(
        id: '1', organizationId: 'o', transferNo: 'T1', fromOutletId: 'a', toOutletId: 'b', lines: [],
        status: 'Requested',
      );
      expect(tReq.status, 'Requested');
      expect(tReq.nextActionLabel, 'Approve');
      expect(tReq.nextStatus, 'Approved');

      const tApp = CentralKitchenTransfer(
        id: '2', organizationId: 'o', transferNo: 'T2', fromOutletId: 'a', toOutletId: 'b', lines: [],
        status: 'Approved',
      );
      expect(tApp.status, 'Approved');
      expect(tApp.nextActionLabel, 'Mark dispatched');
      expect(tApp.nextStatus, 'Dispatched');

      const tDisp = CentralKitchenTransfer(
        id: '3', organizationId: 'o', transferNo: 'T3', fromOutletId: 'a', toOutletId: 'b', lines: [],
        status: 'Dispatched',
      );
      expect(tDisp.status, 'Dispatched');
      expect(tDisp.nextActionLabel, 'Mark received');
      expect(tDisp.nextStatus, 'Received');

      const tRec = CentralKitchenTransfer(
        id: '4', organizationId: 'o', transferNo: 'T4', fromOutletId: 'a', toOutletId: 'b', lines: [],
        status: 'Received',
      );
      expect(tRec.status, 'Received');
      expect(tRec.nextActionLabel, isNull);
      expect(tRec.nextStatus, isNull);
    });

    test('#121 CentralKitchenTransfer.toJson generates only required creation payload fields', () {
      const transfer = CentralKitchenTransfer(
        id: 'temp_id',
        organizationId: 'org_1',
        transferNo: 'TR-999',
        fromOutletId: 'out_from',
        toOutletId: 'out_to',
        lines: [
          CentralKitchenTransferLine(
            inventoryId: 'inv_1',
            quantity: 3.5,
          ),
        ],
        value: 999.0,
      );

      final payload = transfer.toJson();
      expect(payload['fromOutletId'], 'out_from');
      expect(payload['toOutletId'], 'out_to');
      expect(payload['lines'], hasLength(1));
      expect(payload['lines'][0]['inventoryId'], 'inv_1');
      expect(payload['lines'][0]['quantity'], 3.5);
      // Ensure read-only server fields are NEVER sent in payload
      expect(payload.containsKey('transferNo'), isFalse);
      expect(payload.containsKey('value'), isFalse);
      expect(payload.containsKey('status'), isFalse);
    });
  });

  group('Module 16: CentralKitchenScreen UI & Role Permissions', () {
    testWidgets('CentralKitchenScreen renders transfer list, status chips, and stage action', (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final state = const CentralKitchenState(
        activeTransfers: [mockTransferRequested, mockTransferApproved],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(() => _FakeAuthController(mockOwner)),
            centralKitchenControllerProvider.overrideWith(() => _FakeCentralKitchenController(state)),
          ],
          child: const MaterialApp(home: CentralKitchenScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Central Kitchen (30)'), findsOneWidget);
      expect(find.text('Transfer #TR-001'), findsOneWidget);
      expect(find.text('Transfer #TR-002'), findsOneWidget);
      expect(find.text('Approve'), findsOneWidget); // Next stage for TR-001 (Requested -> Approved)
      expect(find.text('Mark dispatched'), findsOneWidget); // Next stage for TR-002 (Approved -> Dispatched)
      expect(find.text('Value: ₹100.00'), findsOneWidget);
      expect(find.text('Value: ₹400.00'), findsOneWidget);
    });

    testWidgets('Staff Role: Can view, create, and advance stage, but Deactivate and Delete are hidden', (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final state = const CentralKitchenState(
        activeTransfers: [mockTransferRequested],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(() => _FakeAuthController(mockStaff)),
            centralKitchenControllerProvider.overrideWith(() => _FakeCentralKitchenController(state)),
          ],
          child: const MaterialApp(home: CentralKitchenScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Staff can see New Transfer and stage action (Approve)
      expect(find.text('New Transfer'), findsOneWidget);
      expect(find.text('Approve'), findsOneWidget);
      // Staff CANNOT see Deactivate or Delete
      expect(find.text('Deactivate'), findsNothing);
      expect(find.text('Delete permanently'), findsNothing);
    });

    testWidgets('Admin Role: Can Deactivate and Restore, but Delete permanently (#126) is hidden (Owner/CTO only)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final state = const CentralKitchenState(
        activeTransfers: [mockTransferRequested],
        inactiveTransfers: [mockTransferInactive],
        showInactive: true,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(() => _FakeAuthController(mockAdmin)),
            centralKitchenControllerProvider.overrideWith(() => _FakeCentralKitchenController(state)),
          ],
          child: const MaterialApp(home: CentralKitchenScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Inactive transfer is shown
      expect(find.text('Transfer #TR-004'), findsOneWidget);
      // Admin CAN see Restore
      expect(find.text('Restore'), findsOneWidget);
      // Admin CANNOT see Delete permanently (PDF restricts #126 to Owner and CTO)
      expect(find.text('Delete permanently'), findsNothing);
    });

    testWidgets('Owner Role: Can Delete permanently (#126) with confirmation dialog', (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final state = const CentralKitchenState(
        inactiveTransfers: [mockTransferInactive],
        showInactive: true,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(() => _FakeAuthController(mockOwner)),
            centralKitchenControllerProvider.overrideWith(() => _FakeCentralKitchenController(state)),
          ],
          child: const MaterialApp(home: CentralKitchenScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Owner CAN see Delete permanently
      expect(find.text('Delete permanently'), findsOneWidget);

      await tester.tap(find.text('Delete permanently'));
      await tester.pumpAndSettle();

      // Confirmation dialog opens
      expect(find.text('Delete Transfer Permanently (#126)'), findsOneWidget);
      expect(find.text('Delete Permanently'), findsOneWidget);
    });
  });

  group('Module 16: CentralKitchenScreen Viewport Responsiveness', () {
    testWidgets('Responsiveness: 360x800 portrait with no overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final state = const CentralKitchenState(
        activeTransfers: [mockTransferRequested, mockTransferApproved, mockTransferDispatched],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(() => _FakeAuthController(mockOwner)),
            centralKitchenControllerProvider.overrideWith(() => _FakeCentralKitchenController(state)),
          ],
          child: const MaterialApp(home: CentralKitchenScreen()),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('Responsiveness: 800x360 landscape with no overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 360));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final state = const CentralKitchenState(
        activeTransfers: [mockTransferRequested, mockTransferApproved],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(() => _FakeAuthController(mockOwner)),
            centralKitchenControllerProvider.overrideWith(() => _FakeCentralKitchenController(state)),
          ],
          child: const MaterialApp(home: CentralKitchenScreen()),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('Responsiveness: 360x800 with 1.5x font scale with no overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final state = const CentralKitchenState(
        activeTransfers: [mockTransferRequested, mockTransferApproved],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(() => _FakeAuthController(mockOwner)),
            centralKitchenControllerProvider.overrideWith(() => _FakeCentralKitchenController(state)),
          ],
          child: const MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(
                textScaler: TextScaler.linear(1.5),
              ),
              child: CentralKitchenScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
