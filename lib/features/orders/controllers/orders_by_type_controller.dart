import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/order.dart';
import '../../../services/api/order_api_service.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../settings/controllers/active_outlet_provider.dart';

class OrdersByTypeFilter {
  final String? orderStatus; // active | completed | cancelled | null
  final String? paymentStatus; // pending | paid | partially_paid | null
  final String scope; // today | running | all (default today)
  final String? from; // YYYY-MM-DD
  final String? to; // YYYY-MM-DD
  final int page;
  final int limit;

  const OrdersByTypeFilter({
    this.orderStatus,
    this.paymentStatus,
    this.scope = 'today',
    this.from,
    this.to,
    this.page = 1,
    this.limit = 20,
  });

  OrdersByTypeFilter copyWith({
    String? Function()? orderStatus,
    String? Function()? paymentStatus,
    String? scope,
    String? Function()? from,
    String? Function()? to,
    int? page,
    int? limit,
  }) {
    return OrdersByTypeFilter(
      orderStatus: orderStatus != null ? orderStatus() : this.orderStatus,
      paymentStatus: paymentStatus != null ? paymentStatus() : this.paymentStatus,
      scope: scope ?? this.scope,
      from: from != null ? from() : this.from,
      to: to != null ? to() : this.to,
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }
}

class OrdersFilterNotifier extends Notifier<OrdersByTypeFilter> {
  @override
  OrdersByTypeFilter build() => const OrdersByTypeFilter();

  void update(OrdersByTypeFilter Function(OrdersByTypeFilter) fn) {
    state = fn(state);
  }
}

final takeawayFilterProvider =
    NotifierProvider<OrdersFilterNotifier, OrdersByTypeFilter>(
  OrdersFilterNotifier.new,
);

final deliveryFilterProvider =
    NotifierProvider<OrdersFilterNotifier, OrdersByTypeFilter>(
  OrdersFilterNotifier.new,
);

final onlineFilterProvider =
    NotifierProvider<OrdersFilterNotifier, OrdersByTypeFilter>(
  OrdersFilterNotifier.new,
);

NotifierProvider<OrdersFilterNotifier, OrdersByTypeFilter> getFilterProviderForType(String orderType) {
  switch (orderType.toLowerCase()) {
    case 'delivery':
      return deliveryFilterProvider;
    case 'online':
      return onlineFilterProvider;
    case 'takeaway':
    default:
      return takeawayFilterProvider;
  }
}

class OrdersByTypeNotifier extends AsyncNotifier<OrderListResponse> {
  final String orderType;

  OrdersByTypeNotifier(this.orderType);

  @override
  Future<OrderListResponse> build() async {
    final filter = ref.watch(getFilterProviderForType(orderType));
    return _fetchOrders(filter);
  }

  Future<OrderListResponse> _fetchOrders(OrdersByTypeFilter filter) async {
    final user = ref.read(authControllerProvider).value;
    final orgId = user?.organizationId ?? '';
    if (orgId.isEmpty) {
      return OrderListResponse(orders: []);
    }

    final activeOutlet = ref.watch(activeOutletProvider);
    final outletId = activeOutlet?.id;

    final api = ref.read(orderApiServiceProvider);
    final res = await api.getOrdersByType(
      orgId,
      orderType,
      outletId: outletId,
      orderStatus: filter.orderStatus,
      paymentStatus: filter.paymentStatus,
      scope: filter.scope,
      from: filter.from,
      to: filter.to,
      page: filter.page,
      limit: filter.limit,
    );

    if (!res.success) {
      throw Exception(res.message);
    }
    return res.data ?? OrderListResponse(orders: []);
  }

  Future<void> refresh() async {
    final filter = ref.read(getFilterProviderForType(orderType));
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchOrders(filter));
  }

  void setScope(String scope) {
    ref.read(getFilterProviderForType(orderType).notifier).update(
          (f) => f.copyWith(scope: scope, page: 1),
        );
  }

  void setOrderStatus(String? orderStatus) {
    ref.read(getFilterProviderForType(orderType).notifier).update(
          (f) => f.copyWith(orderStatus: () => orderStatus, page: 1),
        );
  }

  void setPaymentStatus(String? paymentStatus) {
    ref.read(getFilterProviderForType(orderType).notifier).update(
          (f) => f.copyWith(paymentStatus: () => paymentStatus, page: 1),
        );
  }

  void setDateRange(String? from, String? to) {
    ref.read(getFilterProviderForType(orderType).notifier).update(
          (f) => f.copyWith(from: () => from, to: () => to, page: 1),
        );
  }

  void setPage(int page) {
    ref.read(getFilterProviderForType(orderType).notifier).update(
          (f) => f.copyWith(page: page),
        );
  }
}

final takeawayOrdersControllerProvider =
    AsyncNotifierProvider<OrdersByTypeNotifier, OrderListResponse>(() {
  return OrdersByTypeNotifier('takeaway');
});

final deliveryOrdersControllerProvider =
    AsyncNotifierProvider<OrdersByTypeNotifier, OrderListResponse>(() {
  return OrdersByTypeNotifier('delivery');
});

final onlineOrdersControllerProvider =
    AsyncNotifierProvider<OrdersByTypeNotifier, OrderListResponse>(() {
  return OrdersByTypeNotifier('online');
});
