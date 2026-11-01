import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_response.dart';
import '../../../models/order.dart';
import '../../../services/api/order_api_service.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../settings/controllers/active_outlet_provider.dart';

class KitchenOrdersFilter {
  final String? status; // in_queue | preparing | ready | served | cancelled | null for all
  final String? orderType;
  final String scope; // running | today (default running)
  final int page;
  final int limit;

  const KitchenOrdersFilter({
    this.status,
    this.orderType,
    this.scope = 'running',
    this.page = 1,
    this.limit = 50,
  });

  KitchenOrdersFilter copyWith({
    String? Function()? status,
    String? Function()? orderType,
    String? scope,
    int? page,
    int? limit,
  }) {
    return KitchenOrdersFilter(
      status: status != null ? status() : this.status,
      orderType: orderType != null ? orderType() : this.orderType,
      scope: scope ?? this.scope,
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }
}

class KitchenOrdersFilterNotifier extends Notifier<KitchenOrdersFilter> {
  @override
  KitchenOrdersFilter build() => const KitchenOrdersFilter();

  void update(KitchenOrdersFilter Function(KitchenOrdersFilter) fn) {
    state = fn(state);
  }
}

final kitchenOrdersFilterProvider =
    NotifierProvider<KitchenOrdersFilterNotifier, KitchenOrdersFilter>(
  KitchenOrdersFilterNotifier.new,
);

final kitchenOrdersControllerProvider =
    AsyncNotifierProvider<KitchenOrdersController, KitchenOrdersResponse>(() {
  return KitchenOrdersController();
});

class KitchenOrdersController extends AsyncNotifier<KitchenOrdersResponse> {
  @override
  Future<KitchenOrdersResponse> build() async {
    final filter = ref.watch(kitchenOrdersFilterProvider);
    return _fetchKitchenOrders(filter);
  }

  Future<KitchenOrdersResponse> _fetchKitchenOrders(KitchenOrdersFilter filter) async {
    final user = ref.read(authControllerProvider).value;
    final orgId = user?.organizationId ?? '';
    if (orgId.isEmpty) {
      return KitchenOrdersResponse(items: []);
    }

    final activeOutlet = ref.watch(activeOutletProvider);
    final outletId = activeOutlet?.id;

    final api = ref.read(orderApiServiceProvider);
    final res = await api.getKitchenOrders(
      orgId,
      outletId: outletId,
      status: filter.status,
      orderType: filter.orderType,
      scope: filter.scope,
      page: filter.page,
      limit: filter.limit,
    );

    if (!res.success) {
      throw Exception(res.message);
    }
    return res.data ?? KitchenOrdersResponse(items: []);
  }

  Future<void> refresh() async {
    final filter = ref.read(kitchenOrdersFilterProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchKitchenOrders(filter));
  }

  /// Update item status (#49)
  Future<ApiResponse<Order>> updateItemStatus(
    String orderId,
    String itemId,
    String newStatus,
  ) async {
    final user = ref.read(authControllerProvider).value;
    final orgId = user?.organizationId ?? '';
    if (orgId.isEmpty) {
      return ApiResponse(success: false, statusCode: 400, message: 'No organization found');
    }

    final api = ref.read(orderApiServiceProvider);
    final res = await api.updateItemStatus(orgId, orderId, itemId, newStatus);
    if (res.success) {
      // Refresh kitchen orders
      ref.invalidateSelf();
    }
    return res;
  }
}
