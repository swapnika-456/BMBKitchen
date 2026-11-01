import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bmb_kitchen/models/models.dart';
import 'package:bmb_kitchen/models/user.dart';
import 'package:bmb_kitchen/features/auth/controllers/auth_controller.dart';
import 'package:bmb_kitchen/features/settings/controllers/outlet_controller.dart';
import 'package:bmb_kitchen/features/notifications/controllers/notification_controller.dart';
import 'package:bmb_kitchen/features/settings/screens/notifications_screen.dart';

// Test Data
final mockNotification1 = AppNotification(
  id: 'notif_1',
  organizationId: 'org_test_1',
  outletId: 'out_1',
  eventKey: 'lowStock',
  title: 'Low Stock Alert',
  message: 'Paneer inventory is below safety threshold (2.5 kg remaining).',
  relatedEntityType: 'InventoryItem',
  relatedEntityId: 'item_101',
  readBy: const [],
  createdAt: DateTime(2026, 10, 30, 9, 30),
);

final mockNotification2 = AppNotification(
  id: 'notif_2',
  organizationId: 'org_test_1',
  outletId: 'out_1',
  eventKey: 'orderReady',
  title: 'Order Ready',
  message: 'Order #ORD-1042 has been prepared by Main Kitchen.',
  relatedEntityType: 'Order',
  relatedEntityId: 'ord_1042',
  readBy: const ['user_1'],
  createdAt: DateTime(2026, 10, 30, 9, 15),
);

final mockNotification3 = AppNotification(
  id: 'notif_3',
  organizationId: 'org_test_1',
  outletId: 'out_1',
  eventKey: 'dayClosing',
  title: 'Day Closing Report',
  message: 'Day closing for Oct 29 locked with cash difference ₹0.00.',
  relatedEntityType: 'DayClosing',
  relatedEntityId: 'dc_101',
  readBy: const ['user_2'],
  createdAt: DateTime(2026, 10, 30, 8, 0),
);

final mockSettings = NotificationSettings(
  id: 'set_1',
  organizationId: 'org_test_1',
  channels: const NotificationChannels(whatsapp: true, sms: false, email: true),
  events: const NotificationEvents(
    billShare: true,
    orderReady: true,
    lowStock: true,
    dayClosing: true,
    newOnline: true,
    offerBlast: false,
  ),
  createdBy: 'user_1',
);

final mockOutlet = Outlet(
  id: 'out_1',
  code: 'MK',
  name: 'Main Kitchen',
  address: '123 Main St',
  phone: '9876543210',
  organizationId: 'org_test_1',
  isActive: true,
);

class _FakeAuthController extends AuthController {
  final User? _user;
  _FakeAuthController(this._user);

  @override
  Future<User?> build() async => _user;
}

class _FakeNotificationController extends NotificationController {
  final NotificationState _initialState;
  _FakeNotificationController(this._initialState);

  @override
  Future<NotificationState> build() async => _initialState;

  @override
  void setActiveTab(int tab) {
    state = AsyncValue.data(state.value!.copyWith(activeTab: tab));
  }

  @override
  void setUnreadOnly(bool val) {
    state = AsyncValue.data(state.value!.copyWith(unreadOnly: val));
  }

  @override
  void setEventFilter(String? event) {
    if (event == null || event == 'all') {
      state = AsyncValue.data(state.value!.copyWith(clearEventFilter: true));
    } else {
      state = AsyncValue.data(state.value!.copyWith(eventFilter: event));
    }
  }

  @override
  Future<bool> updateChannel(String channel, bool isEnabled) async {
    final curSettings = state.value!.settings!;
    final newChannels = curSettings.channels.copyWith(
      whatsapp: channel == 'whatsapp' ? isEnabled : null,
      sms: channel == 'sms' ? isEnabled : null,
      email: channel == 'email' ? isEnabled : null,
    );
    state = AsyncValue.data(state.value!.copyWith(
      settings: curSettings.copyWith(channels: newChannels),
    ));
    return true;
  }

  @override
  Future<bool> updateEvent(String event, bool isEnabled) async {
    final curSettings = state.value!.settings!;
    final newEvents = curSettings.events.copyWith(
      billShare: event == 'billShare' ? isEnabled : null,
      orderReady: event == 'orderReady' ? isEnabled : null,
      lowStock: event == 'lowStock' ? isEnabled : null,
      dayClosing: event == 'dayClosing' ? isEnabled : null,
      newOnline: event == 'newOnline' ? isEnabled : null,
      offerBlast: event == 'offerBlast' ? isEnabled : null,
    );
    state = AsyncValue.data(state.value!.copyWith(
      settings: curSettings.copyWith(events: newEvents),
    ));
    return true;
  }

  @override
  Future<AppNotification?> viewAndMarkRead(AppNotification notification) async {
    final updatedReadBy = [...notification.readBy, 'user_1'];
    final updated = notification.copyWith(readBy: updatedReadBy);
    final updatedList = state.value!.notifications.map((n) {
      return n.id == updated.id ? updated : n;
    }).toList();
    final newCount = state.value!.unreadCount > 0 ? state.value!.unreadCount - 1 : 0;
    state = AsyncValue.data(state.value!.copyWith(
      notifications: updatedList,
      unreadCount: newCount,
      selectedNotification: updated,
    ));
    return updated;
  }
}

class _FakeOutletController extends OutletController {
  final List<Outlet> _outlets;
  _FakeOutletController(this._outlets);

  @override
  Future<List<Outlet>> build() async => _outlets;
}

Widget createTestWidget({
  required String role,
  NotificationState? state,
  String currentUserId = 'user_1',
}) {
  final user = User(
    id: currentUserId,
    email: 'test@bmb.com',
    name: 'Test $role',
    role: role,
    organizationId: 'org_test_1',
    isActive: true,
  );

  final testState = state ??
      NotificationState(
        notifications: [mockNotification1, mockNotification2, mockNotification3],
        settings: mockSettings,
        unreadCount: 1,
        currentUserId: currentUserId,
      );

  return ProviderScope(
    overrides: [
      authControllerProvider.overrideWith(() => _FakeAuthController(user)),
      notificationControllerProvider
          .overrideWith(() => _FakeNotificationController(testState)),
      outletControllerProvider
          .overrideWith(() => _FakeOutletController([mockOutlet])),
    ],
    child: const MaterialApp(
      home: NotificationsScreen(),
    ),
  );
}

void main() {
  group('Module 19: Notification Settings Model & Defaults', () {
    test('Default channels and events match specification exactly', () {
      const channels = NotificationChannels();
      expect(channels.whatsapp, isTrue);
      expect(channels.sms, isFalse);
      expect(channels.email, isTrue);

      const events = NotificationEvents();
      expect(events.billShare, isTrue);
      expect(events.orderReady, isTrue);
      expect(events.lowStock, isTrue);
      expect(events.dayClosing, isTrue);
      expect(events.newOnline, isTrue);
      expect(events.offerBlast, isFalse);
    });

    test('NotificationSettings.fromJson parses server response and tolerant IDs', () {
      final json = {
        "_id": "6ae42adb038db3fa12daca8d",
        "organizationId": {"_id": "6ac78e4f0a063d3e07a1bed5", "name": "Test Org"},
        "channels": {"whatsapp": true, "sms": true, "email": false},
        "events": {
          "billShare": true,
          "orderReady": false,
          "lowStock": true,
          "dayClosing": true,
          "newOnline": false,
          "offerBlast": true
        },
        "createdBy": {"_id": "user_owner_1", "name": "Owner"},
        "createdAt": "2026-10-30T05:27:55.770Z",
        "updatedAt": "2026-10-30T05:27:56.123Z",
      };

      final settings = NotificationSettings.fromJson(json);
      expect(settings.id, "6ae42adb038db3fa12daca8d");
      expect(settings.organizationId, "6ac78e4f0a063d3e07a1bed5");
      expect(settings.channels.whatsapp, isTrue);
      expect(settings.channels.sms, isTrue);
      expect(settings.channels.email, isFalse);
      expect(settings.events.orderReady, isFalse);
      expect(settings.events.offerBlast, isTrue);
      expect(settings.createdBy, "user_owner_1");
    });
  });

  group('Module 20: AppNotification Model Deserialization & Serialization', () {
    test('AppNotification.fromJson parses populated outlet, createdBy, and readBy', () {
      final json = {
        "_id": "notif_99",
        "organizationId": "org_test_1",
        "outletId": {"_id": "out_101", "name": "Main Kitchen", "code": "MK"},
        "eventKey": "lowStock",
        "title": "Low Stock Warning",
        "message": "Butter is running low",
        "relatedEntityType": "InventoryItem",
        "relatedEntityId": "item_42",
        "readBy": [
          {"_id": "user_1", "name": "John"},
          "user_2"
        ],
        "createdBy": {"_id": "user_sys", "userName": "System"},
        "createdAt": "2026-10-30T05:00:00.000Z"
      };

      final notif = AppNotification.fromJson(json);
      expect(notif.id, "notif_99");
      expect(notif.outletId, "out_101");
      expect(notif.eventKey, "lowStock");
      expect(notif.title, "Low Stock Warning");
      expect(notif.message, "Butter is running low");
      expect(notif.relatedEntityType, "InventoryItem");
      expect(notif.relatedEntityId, "item_42");
      expect(notif.readBy, containsAll(["user_1", "user_2"]));
      expect(notif.isReadBy("user_1"), isTrue);
      expect(notif.isReadBy("user_3"), isFalse);
    });

    test('AppNotification toJson outputs valid schema', () {
      final notif = AppNotification(
        id: 'n_1',
        organizationId: 'org_1',
        outletId: 'out_1',
        eventKey: 'newOnline',
        title: 'New Online Order',
        message: 'Zomato order #1234',
        relatedEntityType: 'Order',
        relatedEntityId: '1234',
        readBy: const ['user_1'],
        createdAt: DateTime(2026, 10, 30, 8, 0),
      );

      final json = notif.toJson();
      expect(json['_id'], 'n_1');
      expect(json['organizationId'], 'org_1');
      expect(json['outletId'], 'out_1');
      expect(json['eventKey'], 'newOnline');
      expect(json['title'], 'New Online Order');
      expect(json['relatedEntityType'], 'Order');
      expect(json['readBy'], ['user_1']);
    });
  });

  group('Module 19 & 20: NotificationsScreen UI & Role Permissions', () {
    testWidgets('Owner Role: Shows Inbox and Settings tabs, renders notification cards', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createTestWidget(role: 'owner'));
      await tester.pumpAndSettle();

      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Inbox'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);

      // Cards rendered
      expect(find.text('Low Stock Alert'), findsWidgets);
      expect(find.text('Order #ORD-1042 has been prepared by Main Kitchen.'), findsOneWidget);
      expect(find.text('Day Closing Report'), findsWidgets);
    });

    testWidgets('Staff Role: Settings tab is hidden, can view Inbox only', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createTestWidget(role: 'staff'));
      await tester.pumpAndSettle();

      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Inbox'), findsNothing);
      expect(find.text('Settings'), findsNothing);

      // Staff still sees notifications list
      expect(find.text('Low Stock Alert'), findsWidgets);
    });

    testWidgets('Unread only filter toggles list correctly', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createTestWidget(role: 'owner', currentUserId: 'user_1'));
      await tester.pumpAndSettle();

      // Tap 'Unread only'
      await tester.tap(find.text('Unread only'));
      await tester.pumpAndSettle();

      // mockNotification1 is unread (readBy is empty)
      expect(find.text('Paneer inventory is below safety threshold (2.5 kg remaining).'), findsOneWidget);
      // mockNotification2 was read by user_1, so it is filtered out
      expect(find.text('Order #ORD-1042 has been prepared by Main Kitchen.'), findsNothing);
    });

    testWidgets('Tapping notification card opens detail view', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createTestWidget(role: 'owner'));
      await tester.pumpAndSettle();

      // Tap first notification
      await tester.tap(find.text('Low Stock Alert'));
      await tester.pumpAndSettle();

      // Modal bottom sheet with detail fields
      expect(find.text('Related Entity'), findsOneWidget);
      expect(find.text('InventoryItem'), findsOneWidget);
      expect(find.text('Entity ID'), findsOneWidget);
      expect(find.text('item_101'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);

      // Close modal
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
    });

    testWidgets('Empty State: Renders informative empty state when list is empty', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createTestWidget(
        role: 'owner',
        state: const NotificationState(
          notifications: [],
          settings: null,
          settingsNotFound: true,
          unreadCount: 0,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('No notifications found'), findsOneWidget);
    });

    testWidgets('Settings Tab: Shows Setup Notifications button when settings are 404', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createTestWidget(
        role: 'owner',
        state: const NotificationState(
          notifications: [],
          settings: null,
          settingsNotFound: true,
          activeTab: 1, // On settings tab
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Set up notifications'), findsNWidgets(2)); // Title and button
    });

    testWidgets('Settings Tab: Switches toggle channels and events, note banner is present', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createTestWidget(
        role: 'owner',
        state: NotificationState(
          notifications: [],
          settings: mockSettings,
          activeTab: 1, // On settings tab
        ),
      ));
      await tester.pumpAndSettle();

      expect(
        find.text('These switches control which notifications are enabled. Delivery depends on the integrations connected.'),
        findsOneWidget,
      );

      expect(find.text('WhatsApp'), findsOneWidget);
      expect(find.text('SMS'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);

      expect(find.text('Bill Share (billShare)'), findsOneWidget);
      expect(find.text('Order Ready (orderReady)'), findsOneWidget);
      expect(find.text('Low Stock Alert (lowStock)'), findsOneWidget);
      expect(find.text('Day Closing Report (dayClosing)'), findsOneWidget);
      expect(find.text('New Online Order (newOnline)'), findsOneWidget);
      expect(find.text('Offer Blast (offerBlast)'), findsOneWidget);
    });
  });

  group('Module 19 & 20: Viewport Responsiveness', () {
    testWidgets('360x800 portrait layout without overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createTestWidget(role: 'owner'));
      await tester.pumpAndSettle();

      expect(find.text('Notifications'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('800x360 landscape layout without overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 360));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createTestWidget(role: 'owner'));
      await tester.pumpAndSettle();

      expect(find.text('Notifications'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('360x800 with 1.5x font scale without overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final user = User(
        id: 'u1',
        email: 'test@bmb.com',
        name: 'Test Owner',
        role: 'owner',
        organizationId: 'org_test_1',
        isActive: true,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(() => _FakeAuthController(user)),
            notificationControllerProvider.overrideWith(
              () => _FakeNotificationController(
                NotificationState(
                  notifications: [mockNotification1, mockNotification2],
                  settings: mockSettings,
                  unreadCount: 1,
                  currentUserId: 'u1',
                ),
              ),
            ),
            outletControllerProvider.overrideWith(
              () => _FakeOutletController([mockOutlet]),
            ),
          ],
          child: const MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(1.5)),
              child: NotificationsScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Notifications'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
