import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bmb_kitchen/core/network/api_response.dart';
import 'package:bmb_kitchen/models/integration.dart';
import 'package:bmb_kitchen/models/user.dart';
import 'package:bmb_kitchen/features/auth/controllers/auth_controller.dart';
import 'package:bmb_kitchen/features/integrations/controllers/integration_controller.dart';
import 'package:bmb_kitchen/features/settings/screens/integrations_screen.dart';

// Test Data
final mockIntegrationSwiggy = Integration(
  id: 'int_swiggy_1',
  organizationId: 'org_test_1',
  name: 'Swiggy',
  category: 'Aggregator',
  status: 'connected',
  note: 'Menu + order sync',
  connectedSince: DateTime(2026, 10, 15, 10, 30),
  createdAt: DateTime(2026, 10, 1, 10, 0),
  updatedAt: DateTime(2026, 10, 15, 10, 30),
);

final mockIntegrationRazorpay = Integration(
  id: 'int_razorpay_2',
  organizationId: 'org_test_1',
  name: 'Razorpay',
  category: 'Payments',
  status: 'not_connected',
  note: 'UPI / card settlement',
  connectedSince: null,
  createdAt: DateTime(2026, 10, 1, 10, 0),
  updatedAt: DateTime(2026, 10, 1, 10, 0),
);

final mockIntegrationWhatsApp = Integration(
  id: 'int_whatsapp_3',
  organizationId: 'org_test_1',
  name: 'AiSensy WhatsApp',
  category: 'Messaging',
  status: 'not_connected',
  note: 'Bill share + campaigns',
  connectedSince: null,
  createdAt: DateTime(2026, 10, 1, 10, 0),
  updatedAt: DateTime(2026, 10, 1, 10, 0),
);

final mockIntegrationTally = Integration(
  id: 'int_tally_4',
  organizationId: 'org_test_1',
  name: 'Tally',
  category: 'Accounting',
  status: 'connected',
  note: 'Sales & purchase export',
  connectedSince: DateTime(2026, 10, 20, 14, 0),
  createdAt: DateTime(2026, 10, 1, 10, 0),
  updatedAt: DateTime(2026, 10, 20, 14, 0),
);

final mockIntegrationReviews = Integration(
  id: 'int_reviews_5',
  organizationId: 'org_test_1',
  name: 'Google Reviews',
  category: 'Reputation',
  status: 'not_connected',
  note: 'Feedback requests',
  connectedSince: null,
  createdAt: DateTime(2026, 10, 1, 10, 0),
  updatedAt: DateTime(2026, 10, 1, 10, 0),
);

final mockOwnerUser = User(
  id: 'user_owner',
  name: 'Owner User',
  email: 'owner@bmb.com',
  role: 'owner',
  organizationId: 'org_test_1',
  isActive: true,
);

final mockStaffUser = User(
  id: 'user_staff',
  name: 'Staff User',
  email: 'staff@bmb.com',
  role: 'staff',
  organizationId: 'org_test_1',
  isActive: true,
);

class _TestAuthController extends AuthController {
  final User? _user;
  _TestAuthController(this._user);

  @override
  Future<User?> build() async => _user;
}

class _FakeIntegrationController extends IntegrationController {
  final IntegrationState _initialState;
  _FakeIntegrationController(this._initialState);

  @override
  Future<IntegrationState> build() async => _initialState;

  @override
  Future<ApiResponse<List<Integration>>> seedDefaults() async {
    final seeded = [
      mockIntegrationSwiggy,
      mockIntegrationRazorpay,
      mockIntegrationWhatsApp,
      mockIntegrationTally,
      mockIntegrationReviews,
    ];
    state = AsyncValue.data(state.value!.copyWith(
      integrations: seeded,
      isSeeding: false,
      successMessage: 'Default integrations configured successfully',
    ));
    return ApiResponse(
      success: true,
      statusCode: 201,
      message: 'Default integrations configured',
      data: seeded,
    );
  }

  @override
  Future<ApiResponse<Integration>> connect(String integrationId) async {
    final updatedList = state.value!.integrations.map((item) {
      if (item.id == integrationId) {
        return item.copyWith(
          status: 'connected',
          connectedSince: DateTime(2026, 10, 30, 12, 0),
        );
      }
      return item;
    }).toList();
    final updated = updatedList.firstWhere((i) => i.id == integrationId);
    state = AsyncValue.data(state.value!.copyWith(
      integrations: updatedList,
      successMessage: '${updated.name} marked as connected',
    ));
    return ApiResponse(
      success: true,
      statusCode: 200,
      message: '${updated.name} connected',
      data: updated,
    );
  }

  @override
  Future<ApiResponse<Integration>> disconnect(String integrationId) async {
    final updatedList = state.value!.integrations.map((item) {
      if (item.id == integrationId) {
        return item.copyWith(
          status: 'not_connected',
          connectedSince: null,
        );
      }
      return item;
    }).toList();
    final updated = updatedList.firstWhere((i) => i.id == integrationId);
    state = AsyncValue.data(state.value!.copyWith(
      integrations: updatedList,
      successMessage: '${updated.name} marked as disconnected',
    ));
    return ApiResponse(
      success: true,
      statusCode: 200,
      message: '${updated.name} disconnected',
      data: updated,
    );
  }
}

Widget createTestWidget({
  required User? user,
  required IntegrationState integrationState,
  Size size = const Size(1024, 768),
  double textScale = 1.0,
}) {
  return ProviderScope(
    overrides: [
      authControllerProvider.overrideWith(() => _TestAuthController(user)),
      integrationControllerProvider
          .overrideWith(() => _FakeIntegrationController(integrationState)),
    ],
    child: MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
        ),
        child: const Scaffold(
          body: IntegrationsScreen(),
        ),
      ),
    ),
  );
}

void main() {
  group('Integration Model & State Tests', () {
    test('Integration.fromJson parses full valid payload correctly', () {
      final json = {
        '_id': '6ae43017038db3fa12daca90',
        'organizationId': '6ac78e4f0a063d3e07a1bed5',
        'name': 'Swiggy',
        'category': 'Aggregator',
        'status': 'connected',
        'note': 'Menu + order sync',
        'connectedSince': '2026-10-30T05:50:15.155Z',
        'createdBy': '6ac78e4f0a063d3e07a1bed6',
        'updatedBy': '6ac78e4f0a063d3e07a1bed6',
        'createdAt': '2026-10-30T05:50:15.060Z',
        'updatedAt': '2026-10-30T05:50:15.155Z',
      };

      final item = Integration.fromJson(json);
      expect(item.id, '6ae43017038db3fa12daca90');
      expect(item.organizationId, '6ac78e4f0a063d3e07a1bed5');
      expect(item.name, 'Swiggy');
      expect(item.category, 'Aggregator');
      expect(item.status, 'connected');
      expect(item.isConnected, isTrue);
      expect(item.note, 'Menu + order sync');
      expect(item.connectedSince, isNotNull);
      expect(item.createdBy, '6ac78e4f0a063d3e07a1bed6');
    });

    test('Integration.fromJson tolerant parsing with missing/fallback fields', () {
      final json = {
        'id': 'alt_id_123',
        'name': 'Razorpay',
        'cat': 'Payments',
      };

      final item = Integration.fromJson(json);
      expect(item.id, 'alt_id_123');
      expect(item.name, 'Razorpay');
      expect(item.category, 'Payments');
      expect(item.cat, 'Payments');
      expect(item.status, 'not_connected');
      expect(item.isConnected, isFalse);
      expect(item.connectedSince, isNull);
      expect(item.since, '');
    });

    test('Integration.toJson produces compliant map', () {
      final json = mockIntegrationSwiggy.toJson();
      expect(json['_id'], 'int_swiggy_1');
      expect(json['name'], 'Swiggy');
      expect(json['category'], 'Aggregator');
      expect(json['status'], 'connected');
      expect(json['connectedSince'], contains('2026-10-15'));
    });

    test('Integration.copyWith correctly updates values', () {
      final updated = mockIntegrationRazorpay.copyWith(
        status: 'connected',
        connectedSince: DateTime(2026, 10, 30, 11, 0),
      );
      expect(updated.status, 'connected');
      expect(updated.isConnected, isTrue);
      expect(updated.connectedSince, isNotNull);
      expect(updated.name, mockIntegrationRazorpay.name);
    });

    test('IntegrationState.groupedByCategory groups in predefined order', () {
      final state = IntegrationState(
        integrations: [
          mockIntegrationReviews, // Reputation
          mockIntegrationTally, // Accounting
          mockIntegrationRazorpay, // Payments
          mockIntegrationSwiggy, // Aggregator
          mockIntegrationWhatsApp, // Messaging
        ],
      );

      final grouped = state.groupedByCategory;
      final keys = grouped.keys.toList();
      expect(keys, [
        'Aggregator',
        'Payments',
        'Messaging',
        'Accounting',
        'Reputation',
      ]);
      expect(state.connectedCount, 2); // Swiggy & Tally
      expect(state.totalCount, 5);
    });
  });

  group('IntegrationsScreen Widget Tests', () {
    testWidgets('Renders header, note banner, and category-grouped cards for owner',
        (tester) async {
      final state = IntegrationState(
        integrations: [
          mockIntegrationSwiggy,
          mockIntegrationRazorpay,
          mockIntegrationWhatsApp,
          mockIntegrationTally,
          mockIntegrationReviews,
        ],
      );

      await tester.pumpWidget(createTestWidget(
        user: mockOwnerUser,
        integrationState: state,
      ));
      await tester.pumpAndSettle();

      // Screen Header
      expect(find.text('Integrations'), findsOneWidget);
      expect(find.text('2 of 5 connected to third-party services'), findsOneWidget);

      // Note Banner
      expect(
        find.text(
          'This records the connection status only. Credentials and syncing aren\'t part of this API.',
        ),
        findsOneWidget,
      );

      // Categories
      expect(find.text('AGGREGATOR'), findsOneWidget);
      expect(find.text('PAYMENTS'), findsOneWidget);
      expect(find.text('MESSAGING'), findsOneWidget);
      expect(find.text('ACCOUNTING'), findsOneWidget);
      expect(find.text('REPUTATION'), findsOneWidget);

      // Integration names
      expect(find.text('Swiggy'), findsOneWidget);
      expect(find.text('Razorpay'), findsOneWidget);
      expect(find.text('AiSensy WhatsApp'), findsOneWidget);
      expect(find.text('Tally'), findsOneWidget);
      expect(find.text('Google Reviews'), findsOneWidget);

      // Status badges
      expect(find.text('Connected'), findsNWidgets(2));
      expect(find.text('Not connected'), findsNWidgets(3));

      // Buttons
      expect(find.text('Disconnect'), findsNWidgets(2));
      expect(find.text('Mark as connected'), findsNWidgets(3));
    });

    testWidgets('Shows connect confirm dialog when Mark as connected is tapped',
        (tester) async {
      final state = IntegrationState(
        integrations: [mockIntegrationRazorpay],
      );

      await tester.pumpWidget(createTestWidget(
        user: mockOwnerUser,
        integrationState: state,
      ));
      await tester.pumpAndSettle();

      // Tap Mark as connected button
      await tester.tap(find.byKey(const Key('connect_btn_int_razorpay_2')));
      await tester.pumpAndSettle();

      // Confirm dialog appears
      expect(find.text('Connect Razorpay'), findsOneWidget);
      expect(find.text('Mark Razorpay as connected?'), findsOneWidget);
      expect(
        find.text(
          'Note: This records the connection status only. Credentials and syncing aren\'t part of this API.',
        ),
        findsOneWidget,
      );

      // Confirm connect inside AlertDialog
      await tester.tap(find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(ElevatedButton, 'Mark as connected'),
      ));
      await tester.pumpAndSettle();

      // Success message shown
      expect(find.text('Razorpay marked as connected'), findsOneWidget);
    });

    testWidgets('Shows disconnect confirm dialog when Disconnect is tapped',
        (tester) async {
      final state = IntegrationState(
        integrations: [mockIntegrationSwiggy],
      );

      await tester.pumpWidget(createTestWidget(
        user: mockOwnerUser,
        integrationState: state,
      ));
      await tester.pumpAndSettle();

      // Tap Disconnect button
      await tester.tap(find.byKey(const Key('disconnect_btn_int_swiggy_1')));
      await tester.pumpAndSettle();

      // Confirm dialog appears
      expect(find.text('Disconnect Swiggy'), findsOneWidget);
      expect(
        find.text('Are you sure you want to disconnect Swiggy?'),
        findsOneWidget,
      );

      // Confirm disconnect
      await tester.tap(find.widgetWithText(ElevatedButton, 'Disconnect'));
      await tester.pumpAndSettle();

      // Success message shown
      expect(find.text('Swiggy marked as disconnected'), findsOneWidget);
    });

    testWidgets('Empty state shows "No integrations yet" and "Set up defaults" button',
        (tester) async {
      const state = IntegrationState(integrations: []);

      await tester.pumpWidget(createTestWidget(
        user: mockOwnerUser,
        integrationState: state,
      ));
      await tester.pumpAndSettle();

      expect(find.text('No integrations yet'), findsOneWidget);
      expect(find.byKey(const Key('setup_defaults_button')), findsOneWidget);

      // Tap Set up defaults
      await tester.tap(find.byKey(const Key('setup_defaults_button')));
      await tester.pumpAndSettle();

      // Seeded integrations now visible
      expect(find.text('Swiggy'), findsOneWidget);
      expect(find.text('Razorpay'), findsOneWidget);
      expect(find.text('Default integrations configured successfully'), findsOneWidget);
    });

    testWidgets('Staff role shows Access Restricted view', (tester) async {
      final state = IntegrationState(
        integrations: [mockIntegrationSwiggy],
      );

      await tester.pumpWidget(createTestWidget(
        user: mockStaffUser,
        integrationState: state,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Access Restricted'), findsOneWidget);
      expect(
        find.text(
          'Staff members do not have access to this screen.\n'
          'Only Organization Owners, Admins, and CTOs can view and manage integrations.',
        ),
        findsOneWidget,
      );
      // Integration cards should NOT be shown
      expect(find.text('Swiggy'), findsNothing);
    });

    testWidgets('Responsive rendering: Mobile portrait (360x800) does not overflow',
        (tester) async {
      final state = IntegrationState(
        integrations: [
          mockIntegrationSwiggy,
          mockIntegrationRazorpay,
          mockIntegrationWhatsApp,
        ],
      );

      await tester.pumpWidget(createTestWidget(
        user: mockOwnerUser,
        integrationState: state,
        size: const Size(360, 800),
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Swiggy'), findsOneWidget);
    });

    testWidgets('Responsive rendering: Mobile landscape (800x360) does not overflow',
        (tester) async {
      final state = IntegrationState(
        integrations: [
          mockIntegrationSwiggy,
          mockIntegrationRazorpay,
          mockIntegrationWhatsApp,
        ],
      );

      await tester.pumpWidget(createTestWidget(
        user: mockOwnerUser,
        integrationState: state,
        size: const Size(800, 360),
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Swiggy'), findsOneWidget);
    });

    testWidgets('Responsive rendering: Large font scale 1.5x does not overflow',
        (tester) async {
      final state = IntegrationState(
        integrations: [
          mockIntegrationSwiggy,
          mockIntegrationRazorpay,
        ],
      );

      await tester.pumpWidget(createTestWidget(
        user: mockOwnerUser,
        integrationState: state,
        size: const Size(360, 800),
        textScale: 1.5,
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Swiggy'), findsOneWidget);
    });
  });
}
