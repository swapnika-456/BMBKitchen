import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/payment.dart';
import '../../../services/api/payment_api_service.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../settings/controllers/active_outlet_provider.dart';

class PaymentsFilter {
  final String? outletId;
  final String? paymentMethod;
  final String? orderType;
  final String scope; // today | week | month | year | custom | all
  final String? from;
  final String? to;
  final int page;
  final int limit;

  const PaymentsFilter({
    this.outletId,
    this.paymentMethod,
    this.orderType,
    this.scope = 'today',
    this.from,
    this.to,
    this.page = 1,
    this.limit = 20,
  });

  PaymentsFilter copyWith({
    String? outletId,
    bool clearOutlet = false,
    String? paymentMethod,
    bool clearPaymentMethod = false,
    String? orderType,
    bool clearOrderType = false,
    String? scope,
    String? from,
    String? to,
    bool clearDates = false,
    int? page,
    int? limit,
  }) {
    return PaymentsFilter(
      outletId: clearOutlet ? null : (outletId ?? this.outletId),
      paymentMethod: clearPaymentMethod ? null : (paymentMethod ?? this.paymentMethod),
      orderType: clearOrderType ? null : (orderType ?? this.orderType),
      scope: scope ?? this.scope,
      from: clearDates ? null : (from ?? this.from),
      to: clearDates ? null : (to ?? this.to),
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }
}

final paymentsFilterProvider = NotifierProvider<PaymentsFilterNotifier, PaymentsFilter>(
  () => PaymentsFilterNotifier(),
);

class PaymentsFilterNotifier extends Notifier<PaymentsFilter> {
  @override
  PaymentsFilter build() => const PaymentsFilter();

  void update(PaymentsFilter Function(PaymentsFilter) updater) {
    state = updater(state);
  }

  void setScope(String scope) {
    state = state.copyWith(scope: scope, page: 1);
  }

  void setPaymentMethod(String? mode) {
    state = mode == null
        ? state.copyWith(clearPaymentMethod: true, page: 1)
        : state.copyWith(paymentMethod: mode, page: 1);
  }

  void setOrderType(String? type) {
    state = type == null
        ? state.copyWith(clearOrderType: true, page: 1)
        : state.copyWith(orderType: type, page: 1);
  }

  void setDateRange(String from, String to) {
    state = state.copyWith(scope: 'custom', from: from, to: to, page: 1);
  }

  void clearDateRange() {
    state = state.copyWith(clearDates: true, scope: 'today', page: 1);
  }

  void setOutletId(String? outletId) {
    state = outletId == null
        ? state.copyWith(clearOutlet: true, page: 1)
        : state.copyWith(outletId: outletId, page: 1);
  }

  void setPage(int page) {
    state = state.copyWith(page: page);
  }
}

final paymentsControllerProvider =
    AsyncNotifierProvider<PaymentsController, PaymentListResponse>(
  () => PaymentsController(),
);

class PaymentsController extends AsyncNotifier<PaymentListResponse> {
  @override
  Future<PaymentListResponse> build() async {
    return _fetchPayments();
  }

  Future<PaymentListResponse> _fetchPayments() async {
    final user = ref.watch(authControllerProvider).value;
    if (user == null || user.organizationId.isEmpty) {
      return const PaymentListResponse(
        payments: [],
        total: 0,
        page: 1,
        limit: 20,
        totalPages: 1,
      );
    }

    final filter = ref.watch(paymentsFilterProvider);
    final activeOutlet = ref.watch(activeOutletProvider);
    final api = ref.read(paymentApiServiceProvider);

    final effectiveOutletId = filter.outletId ?? activeOutlet?.id;

    final response = await api.getPayments(
      user.organizationId,
      outletId: effectiveOutletId,
      paymentMethod: filter.paymentMethod,
      orderType: filter.orderType,
      scope: filter.scope,
      from: filter.from,
      to: filter.to,
      page: filter.page,
      limit: filter.limit,
    );

    if (response.success && response.data != null) {
      return response.data!;
    } else {
      throw Exception(response.message.isNotEmpty ? response.message : 'Failed to load payments');
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchPayments());
  }

  void setScope(String scope) {
    ref.read(paymentsFilterProvider.notifier).setScope(scope);
  }

  void setPaymentMethod(String? mode) {
    ref.read(paymentsFilterProvider.notifier).setPaymentMethod(mode);
  }

  void setOrderType(String? type) {
    ref.read(paymentsFilterProvider.notifier).setOrderType(type);
  }

  void setDateRange(String from, String to) {
    ref.read(paymentsFilterProvider.notifier).setDateRange(from, to);
  }

  void clearDateRange() {
    ref.read(paymentsFilterProvider.notifier).clearDateRange();
  }

  void setPage(int page) {
    ref.read(paymentsFilterProvider.notifier).setPage(page);
  }
}
