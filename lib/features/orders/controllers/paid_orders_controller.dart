import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/order.dart';
import '../../../services/api/order_api_service.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../settings/controllers/active_outlet_provider.dart';

class PaidOrdersFilter {
  final String scope; // today | week | month | year | custom | all (default today)
  final String? from; // YYYY-MM-DD
  final String? to; // YYYY-MM-DD
  final String? orderType;
  final String? paymentMethod;
  final String? search;
  final String sortBy; // createdAt | grandTotal | orderNo | billNo | paidAt
  final String sortOrder; // asc | desc
  final int page;
  final int limit;

  const PaidOrdersFilter({
    this.scope = 'today',
    this.from,
    this.to,
    this.orderType,
    this.paymentMethod,
    this.search,
    this.sortBy = 'createdAt',
    this.sortOrder = 'desc',
    this.page = 1,
    this.limit = 20,
  });

  PaidOrdersFilter copyWith({
    String? scope,
    String? Function()? from,
    String? Function()? to,
    String? Function()? orderType,
    String? Function()? paymentMethod,
    String? Function()? search,
    String? sortBy,
    String? sortOrder,
    int? page,
    int? limit,
  }) {
    return PaidOrdersFilter(
      scope: scope ?? this.scope,
      from: from != null ? from() : this.from,
      to: to != null ? to() : this.to,
      orderType: orderType != null ? orderType() : this.orderType,
      paymentMethod: paymentMethod != null ? paymentMethod() : this.paymentMethod,
      search: search != null ? search() : this.search,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }
}

class PaidOrdersFilterNotifier extends Notifier<PaidOrdersFilter> {
  @override
  PaidOrdersFilter build() => const PaidOrdersFilter();

  void update(PaidOrdersFilter Function(PaidOrdersFilter) fn) {
    state = fn(state);
  }
}

final paidOrdersFilterProvider =
    NotifierProvider<PaidOrdersFilterNotifier, PaidOrdersFilter>(
  PaidOrdersFilterNotifier.new,
);

final paidOrdersControllerProvider =
    AsyncNotifierProvider<PaidOrdersController, PaidOrdersResponse>(() {
  return PaidOrdersController();
});

class PaidOrdersController extends AsyncNotifier<PaidOrdersResponse> {
  @override
  Future<PaidOrdersResponse> build() async {
    final filter = ref.watch(paidOrdersFilterProvider);
    return _fetchPaidOrders(filter);
  }

  Future<PaidOrdersResponse> _fetchPaidOrders(PaidOrdersFilter filter) async {
    final user = ref.read(authControllerProvider).value;
    final orgId = user?.organizationId ?? '';
    if (orgId.isEmpty) {
      return PaidOrdersResponse(orders: []);
    }

    final activeOutlet = ref.watch(activeOutletProvider);
    final outletId = activeOutlet?.id;

    final api = ref.read(orderApiServiceProvider);
    final res = await api.getMyOrders(
      orgId,
      outletId: outletId,
      scope: filter.scope,
      from: filter.from,
      to: filter.to,
      orderType: filter.orderType,
      paymentMethod: filter.paymentMethod,
      search: filter.search,
      sortBy: filter.sortBy,
      sortOrder: filter.sortOrder,
      page: filter.page,
      limit: filter.limit,
    );

    if (!res.success) {
      throw Exception(res.message);
    }
    return res.data ?? PaidOrdersResponse(orders: []);
  }

  Future<void> refresh() async {
    final filter = ref.read(paidOrdersFilterProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchPaidOrders(filter));
  }

  void setScope(String scope) {
    ref.read(paidOrdersFilterProvider.notifier).update(
          (f) => f.copyWith(scope: scope, page: 1),
        );
  }

  void setDateRange(String? from, String? to) {
    ref.read(paidOrdersFilterProvider.notifier).update(
          (f) => f.copyWith(from: () => from, to: () => to, page: 1),
        );
  }

  void setSearch(String? search) {
    ref.read(paidOrdersFilterProvider.notifier).update(
          (f) => f.copyWith(search: () => search, page: 1),
        );
  }

  void setOrderType(String? orderType) {
    ref.read(paidOrdersFilterProvider.notifier).update(
          (f) => f.copyWith(orderType: () => orderType, page: 1),
        );
  }

  void setPaymentMethod(String? paymentMethod) {
    ref.read(paidOrdersFilterProvider.notifier).update(
          (f) => f.copyWith(paymentMethod: () => paymentMethod, page: 1),
        );
  }

  void setPage(int page) {
    ref.read(paidOrdersFilterProvider.notifier).update(
          (f) => f.copyWith(page: page),
        );
  }

  void setSort(String sortBy, String sortOrder) {
    ref.read(paidOrdersFilterProvider.notifier).update(
          (f) => f.copyWith(sortBy: sortBy, sortOrder: sortOrder, page: 1),
        );
  }
}
