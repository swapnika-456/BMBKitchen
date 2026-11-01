import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/app_notification.dart';
import '../../../models/notification_settings.dart';
import '../../../services/api/notification_api_service.dart';
import '../../../services/api/notification_settings_api_service.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../settings/controllers/active_outlet_provider.dart';
import '../../settings/controllers/outlet_controller.dart';

class NotificationState {
  final List<AppNotification> notifications;
  final bool unreadOnly;
  final String? eventFilter;
  final String searchQuery;
  final NotificationSettings? settings;
  final bool settingsNotFound;
  final int activeTab; // 0: Inbox, 1: Settings
  final int unreadCount;
  final AppNotification? selectedNotification;
  final bool isSettingUp;
  final bool isUpdating;
  final String? errorMessage;
  final String? successMessage;
  final String currentUserId;

  const NotificationState({
    this.notifications = const [],
    this.unreadOnly = false,
    this.eventFilter,
    this.searchQuery = '',
    this.settings,
    this.settingsNotFound = false,
    this.activeTab = 0,
    this.unreadCount = 0,
    this.selectedNotification,
    this.isSettingUp = false,
    this.isUpdating = false,
    this.errorMessage,
    this.successMessage,
    this.currentUserId = '',
  });

  List<AppNotification> get displayedNotifications {
    final list = notifications.where((n) {
      if (unreadOnly) {
        final isRead = currentUserId.isNotEmpty
            ? n.isReadBy(currentUserId)
            : n.read;
        if (isRead) return false;
      }
      if (eventFilter != null && eventFilter!.isNotEmpty && eventFilter != 'all') {
        if (n.eventKey != eventFilter) return false;
      }
      if (searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        final matchTitle = n.title.toLowerCase().contains(q);
        final matchMsg = n.message.toLowerCase().contains(q);
        final matchEvent = n.eventKey.toLowerCase().contains(q);
        final matchType = n.relatedEntityType?.toLowerCase().contains(q) ?? false;
        final matchId = n.relatedEntityId?.toLowerCase().contains(q) ?? false;
        if (!matchTitle && !matchMsg && !matchEvent && !matchType && !matchId) {
          return false;
        }
      }
      return true;
    }).toList();

    // Sort newest first
    list.sort((a, b) {
      final aTime = a.createdAt?.millisecondsSinceEpoch ?? a.at;
      final bTime = b.createdAt?.millisecondsSinceEpoch ?? b.at;
      return bTime.compareTo(aTime);
    });

    return list;
  }

  NotificationState copyWith({
    List<AppNotification>? notifications,
    bool? unreadOnly,
    String? eventFilter,
    bool clearEventFilter = false,
    String? searchQuery,
    NotificationSettings? settings,
    bool? settingsNotFound,
    int? activeTab,
    int? unreadCount,
    AppNotification? selectedNotification,
    bool clearSelectedNotification = false,
    bool? isSettingUp,
    bool? isUpdating,
    String? errorMessage,
    bool clearError = false,
    String? successMessage,
    bool clearSuccess = false,
    String? currentUserId,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      unreadOnly: unreadOnly ?? this.unreadOnly,
      eventFilter: clearEventFilter ? null : (eventFilter ?? this.eventFilter),
      searchQuery: searchQuery ?? this.searchQuery,
      settings: settings ?? this.settings,
      settingsNotFound: settingsNotFound ?? this.settingsNotFound,
      activeTab: activeTab ?? this.activeTab,
      unreadCount: unreadCount ?? this.unreadCount,
      selectedNotification: clearSelectedNotification
          ? null
          : (selectedNotification ?? this.selectedNotification),
      isSettingUp: isSettingUp ?? this.isSettingUp,
      isUpdating: isUpdating ?? this.isUpdating,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
      currentUserId: currentUserId ?? this.currentUserId,
    );
  }
}

class NotificationController extends AsyncNotifier<NotificationState> {
  @override
  Future<NotificationState> build() async {
    final authUser = ref.watch(authControllerProvider).value;
    final orgId = authUser?.organizationId ?? '';
    final role = authUser?.role ?? 'staff';
    final userId = authUser?.id ?? '';

    final outlet = ref.watch(activeOutletProvider);
    String outletId = outlet?.id ?? '';
    if (outletId.isEmpty) {
      final outlets = ref.watch(outletControllerProvider).value ?? [];
      if (outlets.isNotEmpty) {
        outletId = outlets.first.id;
      }
    }

    if (orgId.isEmpty) {
      return NotificationState(currentUserId: userId);
    }

    final notifApi = ref.read(notificationApiServiceProvider);
    final settingsApi = ref.read(notificationSettingsApiServiceProvider);

    NotificationSettings? settings;
    bool settingsNotFound = false;

    // Settings are accessible by owner/admin/cto only
    final isPrivileged = role == 'owner' || role == 'admin' || role == 'cto';
    if (isPrivileged) {
      final settingsRes = await settingsApi.getSettings(orgId);
      if (settingsRes.success && settingsRes.data != null) {
        settings = settingsRes.data;
      } else if (settingsRes.statusCode == 404) {
        settingsNotFound = true;
      }
    }

    List<AppNotification> notifications = [];
    int unreadCount = 0;

    if (outletId.isNotEmpty) {
      final notifsRes = await notifApi.getNotifications(orgId, outletId);
      if (notifsRes.success && notifsRes.data != null) {
        notifications = notifsRes.data!;
      }

      final countRes = await notifApi.getUnreadCount(orgId, outletId);
      if (countRes.success && countRes.data != null) {
        unreadCount = countRes.data!;
      }
    }

    return NotificationState(
      notifications: notifications,
      settings: settings,
      settingsNotFound: settingsNotFound,
      unreadCount: unreadCount,
      currentUserId: userId,
    );
  }

  void setActiveTab(int tab) {
    if (!state.hasValue) return;
    state = AsyncValue.data(state.value!.copyWith(activeTab: tab));
  }

  void setUnreadOnly(bool val) {
    if (!state.hasValue) return;
    state = AsyncValue.data(state.value!.copyWith(unreadOnly: val));
  }

  void setEventFilter(String? event) {
    if (!state.hasValue) return;
    if (event == null || event == 'all') {
      state = AsyncValue.data(state.value!.copyWith(clearEventFilter: true));
    } else {
      state = AsyncValue.data(state.value!.copyWith(eventFilter: event));
    }
  }

  void setSearchQuery(String query) {
    if (!state.hasValue) return;
    state = AsyncValue.data(state.value!.copyWith(searchQuery: query.trim()));
  }

  void setSelectedNotification(AppNotification? notif) {
    if (!state.hasValue) return;
    if (notif == null) {
      state = AsyncValue.data(state.value!.copyWith(clearSelectedNotification: true));
    } else {
      state = AsyncValue.data(state.value!.copyWith(selectedNotification: notif));
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    ref.invalidateSelf();
  }

  // #167: POST /api/notification-settings/v1/:orgId (One-time setup if 404)
  Future<bool> setupSettings() async {
    if (!state.hasValue) return false;
    final authUser = ref.read(authControllerProvider).value;
    final orgId = authUser?.organizationId ?? '';
    if (orgId.isEmpty) return false;

    state = AsyncValue.data(state.value!.copyWith(isSettingUp: true, clearError: true));
    final settingsApi = ref.read(notificationSettingsApiServiceProvider);
    final res = await settingsApi.setupSettings(orgId);

    if (res.success && res.data != null) {
      state = AsyncValue.data(state.value!.copyWith(
        isSettingUp: false,
        settings: res.data,
        settingsNotFound: false,
        successMessage: 'Notification settings configured with default preferences',
      ));
      return true;
    } else {
      state = AsyncValue.data(state.value!.copyWith(
        isSettingUp: false,
        errorMessage: res.message.isNotEmpty ? res.message : 'Failed to setup notification settings',
      ));
      return false;
    }
  }

  // #168: PATCH /api/notification-settings/v1/:orgId/channels/:channel
  Future<bool> updateChannel(String channel, bool isEnabled) async {
    if (!state.hasValue) return false;
    final authUser = ref.read(authControllerProvider).value;
    final orgId = authUser?.organizationId ?? '';
    if (orgId.isEmpty) return false;

    state = AsyncValue.data(state.value!.copyWith(isUpdating: true, clearError: true));
    final settingsApi = ref.read(notificationSettingsApiServiceProvider);
    final res = await settingsApi.updateChannel(orgId, channel, isEnabled);

    if (res.success && res.data != null) {
      state = AsyncValue.data(state.value!.copyWith(
        isUpdating: false,
        settings: res.data,
      ));
      return true;
    } else {
      state = AsyncValue.data(state.value!.copyWith(
        isUpdating: false,
        errorMessage: res.message.isNotEmpty ? res.message : 'Failed to update channel $channel',
      ));
      return false;
    }
  }

  // #169: PATCH /api/notification-settings/v1/:orgId/events/:event
  Future<bool> updateEvent(String event, bool isEnabled) async {
    if (!state.hasValue) return false;
    final authUser = ref.read(authControllerProvider).value;
    final orgId = authUser?.organizationId ?? '';
    if (orgId.isEmpty) return false;

    state = AsyncValue.data(state.value!.copyWith(isUpdating: true, clearError: true));
    final settingsApi = ref.read(notificationSettingsApiServiceProvider);
    final res = await settingsApi.updateEvent(orgId, event, isEnabled);

    if (res.success && res.data != null) {
      state = AsyncValue.data(state.value!.copyWith(
        isUpdating: false,
        settings: res.data,
      ));
      return true;
    } else {
      state = AsyncValue.data(state.value!.copyWith(
        isUpdating: false,
        errorMessage: res.message.isNotEmpty ? res.message : 'Failed to update event $event',
      ));
      return false;
    }
  }

  // #172 and #173: Open detail and mark as read
  Future<AppNotification?> viewAndMarkRead(AppNotification notification) async {
    if (!state.hasValue) return notification;
    final authUser = ref.read(authControllerProvider).value;
    final orgId = authUser?.organizationId ?? '';
    final userId = authUser?.id ?? '';
    final outlet = ref.read(activeOutletProvider);
    final outletId = outlet?.id ?? '';

    if (orgId.isEmpty) return notification;

    final notifApi = ref.read(notificationApiServiceProvider);

    // Fetch single detail #172
    AppNotification currentItem = notification;
    final detailRes = await notifApi.getSingleNotification(orgId, notification.id);
    if (detailRes.success && detailRes.data != null) {
      currentItem = detailRes.data!;
    }

    // Mark as read #173
    final readRes = await notifApi.markAsRead(orgId, notification.id);
    if (readRes.success && readRes.data != null) {
      currentItem = readRes.data!;
    } else {
      // Optimistically mark as read locally
      final updatedReadBy = [...currentItem.readBy];
      if (userId.isNotEmpty && !updatedReadBy.contains(userId)) {
        updatedReadBy.add(userId);
      }
      currentItem = currentItem.copyWith(readBy: updatedReadBy);
    }

    // Update notifications in state
    final updatedList = state.value!.notifications.map((n) {
      return n.id == currentItem.id ? currentItem : n;
    }).toList();

    // Re-fetch or decrement unread count
    int newCount = state.value!.unreadCount;
    if (outletId.isNotEmpty) {
      final countRes = await notifApi.getUnreadCount(orgId, outletId);
      if (countRes.success && countRes.data != null) {
        newCount = countRes.data!;
      } else if (newCount > 0) {
        newCount -= 1;
      }
    } else if (newCount > 0) {
      newCount -= 1;
    }

    state = AsyncValue.data(state.value!.copyWith(
      notifications: updatedList,
      unreadCount: newCount,
      selectedNotification: currentItem,
    ));

    // Also update badge provider
    ref.read(notificationBadgeProvider.notifier).refresh();

    return currentItem;
  }
}

final notificationControllerProvider =
    AsyncNotifierProvider<NotificationController, NotificationState>(
  () => NotificationController(),
);

/// Sidebar Badge Controller:
/// Fetches #171 for current outlet.
/// Refreshes on app open, on resume, and every 60 seconds while foreground.
/// Zero packages used.
class NotificationBadgeNotifier extends Notifier<int>
    with WidgetsBindingObserver {
  Timer? _timer;
  bool _isForeground = true;

  @override
  int build() {
    WidgetsBinding.instance.addObserver(this);
    ref.onDispose(() {
      WidgetsBinding.instance.removeObserver(this);
      _timer?.cancel();
    });

    _startTimer();

    // Initial fetch on app open
    Future.microtask(() => refresh());

    return 0;
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (_isForeground) {
        refresh();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _isForeground = true;
      refresh();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      _isForeground = false;
    }
  }

  Future<void> refresh() async {
    final user = ref.read(authControllerProvider).value;
    if (user == null || user.organizationId.isEmpty) return;

    final outlet = ref.read(activeOutletProvider);
    String outletId = outlet?.id ?? '';
    if (outletId.isEmpty) {
      final outlets = ref.read(outletControllerProvider).value ?? [];
      if (outlets.isNotEmpty) {
        outletId = outlets.first.id;
      }
    }
    if (outletId.isEmpty) return;

    final apiService = ref.read(notificationApiServiceProvider);
    final res = await apiService.getUnreadCount(user.organizationId, outletId);
    if (res.success && res.data != null) {
      state = res.data!;
    }
  }
}

final notificationBadgeProvider =
    NotifierProvider<NotificationBadgeNotifier, int>(
  () => NotificationBadgeNotifier(),
);
