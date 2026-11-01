import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/models.dart';
import '../../../services/api/dashboard_api_service.dart';
import '../../../services/api/order_api_service.dart';
import '../../../services/api/inventory_api_service.dart';
import '../../../services/api/support_ticket_api_service.dart';
import '../../../services/api/table_api_service.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../settings/controllers/active_outlet_provider.dart';

class SidebarBadges {
  final int tablesOccupied;
  final int kitchenQueue;
  final int onlineOrdersRunning;
  final int lowStockCount;
  final int openSupportTickets;

  const SidebarBadges({
    this.tablesOccupied = 0,
    this.kitchenQueue = 0,
    this.onlineOrdersRunning = 0,
    this.lowStockCount = 0,
    this.openSupportTickets = 0,
  });

  int? get tablesBadge => tablesOccupied > 0 ? tablesOccupied : null;
  int? get kitchenBadge => kitchenQueue > 0 ? kitchenQueue : null;
  int? get onlineBadge => onlineOrdersRunning > 0 ? onlineOrdersRunning : null;
  int? get stockBadge => lowStockCount > 0 ? lowStockCount : null;
  int? get supportBadge => openSupportTickets > 0 ? openSupportTickets : null;

  SidebarBadges copyWith({
    int? tablesOccupied,
    int? kitchenQueue,
    int? onlineOrdersRunning,
    int? lowStockCount,
    int? openSupportTickets,
  }) {
    return SidebarBadges(
      tablesOccupied: tablesOccupied ?? this.tablesOccupied,
      kitchenQueue: kitchenQueue ?? this.kitchenQueue,
      onlineOrdersRunning: onlineOrdersRunning ?? this.onlineOrdersRunning,
      lowStockCount: lowStockCount ?? this.lowStockCount,
      openSupportTickets: openSupportTickets ?? this.openSupportTickets,
    );
  }
}

final sidebarBadgesProvider =
    NotifierProvider<SidebarBadgesNotifier, SidebarBadges>(() {
  return SidebarBadgesNotifier();
});

class SidebarBadgesNotifier extends Notifier<SidebarBadges>
    with WidgetsBindingObserver {
  Timer? _timer;

  @override
  SidebarBadges build() {
    WidgetsBinding.instance.addObserver(this);
    ref.onDispose(() {
      WidgetsBinding.instance.removeObserver(this);
      _timer?.cancel();
    });

    // Start 60-second periodic poll
    _timer = Timer.periodic(const Duration(seconds: 60), (_) {
      refresh();
    });

    // Trigger initial fetch
    Future.microtask(() => refresh());

    return const SidebarBadges();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      refresh();
    }
  }

  Future<void> refresh() async {
    final user = ref.read(authControllerProvider).value;
    final orgId = user?.organizationId;
    final outlet = ref.read(activeOutletProvider);
    final outletId = outlet?.id;

    if (orgId == null || orgId.isEmpty) return;

    final role = (user?.role ?? 'staff').toLowerCase();

    int tablesOccupied = 0;
    int kitchenQueue = 0;
    int lowStockCount = 0;
    int onlineOrdersRunning = 0;
    int openSupportTickets = 0;

    // 1. Dashboard summary quick stats (#159)
    try {
      if (outletId != null && outletId.isNotEmpty) {
        final dashRes = await ref.read(dashboardApiServiceProvider).getSummary(
              orgId,
              outletId,
              scope: 'today',
            );

        if (dashRes.success && dashRes.data != null) {
          final qs = dashRes.data!.quickStats;
          tablesOccupied = qs.tablesOccupied;
          kitchenQueue = qs.kitchenQueueCount;
          lowStockCount = qs.lowStockCount;
        }
      }
    } catch (_) {}

    // Fallback for tables if summary didn't return
    if (tablesOccupied == 0 && outletId != null && outletId.isNotEmpty) {
      try {
        final tableRes = await ref.read(tableApiProvider).getActive(
              orgId,
              outletId: outletId,
            );
        if (tableRes.success && tableRes.data != null) {
          tablesOccupied = tableRes.data!
              .where((t) => t.status == TableStatus.occupied)
              .length;
        }
      } catch (_) {}
    }

    // Fallback for low stock if summary didn't return
    if (lowStockCount == 0) {
      try {
        final invRes =
            await ref.read(inventoryApiServiceProvider).getActiveInventory(orgId);
        if (invRes.success && invRes.data != null) {
          lowStockCount =
              invRes.data!.where((item) => item.isLowStock).length;
        }
      } catch (_) {}
    }

    // 2. Online orders via #51A (working route with kOrdersByTypeSegment)
    try {
      final onlineRes = await ref.read(orderApiServiceProvider).getOrdersByType(
            orgId,
            'online',
            outletId: outletId,
            scope: 'running',
          );
      if (onlineRes.success && onlineRes.data != null) {
        onlineOrdersRunning = onlineRes.data!.orders.length;
      }
    } catch (_) {}

    // 3. Open support tickets via #138
    try {
      final ticketRes = await ref
          .read(supportTicketApiServiceProvider)
          .getActiveTickets(orgId, outletId: outletId, status: 'Open');
      if (ticketRes.success && ticketRes.data != null) {
        openSupportTickets = ticketRes.data!.length;
      }
    } catch (_) {}

    // Role-based restrictions if needed
    // Owner, Admin, CTO have full visibility. Staff has visibility into operational modules.

    state = SidebarBadges(
      tablesOccupied: tablesOccupied,
      kitchenQueue: kitchenQueue,
      onlineOrdersRunning: onlineOrdersRunning,
      lowStockCount: lowStockCount,
      openSupportTickets: openSupportTickets,
    );
  }
}
