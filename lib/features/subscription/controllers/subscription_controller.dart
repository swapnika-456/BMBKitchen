import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/subscription.dart';
import '../../../services/api/subscription_api_service.dart';
import '../../auth/controllers/auth_controller.dart';

/// Write actions for subscription are disabled by default.
/// The PDF specification defines no plan price list and no payment gateway integration.
/// Write operations are gated behind this flag to prevent arbitrary price setting in production.
const bool kSubscriptionWriteEnabled = false;

class SubscriptionState {
  final Subscription? subscription;
  final List<SubscriptionInvoice> invoices;
  final bool isSubmitting;
  final String? errorMessage;
  final String? successMessage;

  const SubscriptionState({
    this.subscription,
    this.invoices = const [],
    this.isSubmitting = false,
    this.errorMessage,
    this.successMessage,
  });

  bool get hasSubscription => subscription != null;

  SubscriptionState copyWith({
    Subscription? Function()? subscription,
    List<SubscriptionInvoice>? invoices,
    bool? isSubmitting,
    String? Function()? errorMessage,
    String? Function()? successMessage,
  }) {
    return SubscriptionState(
      subscription: subscription != null ? subscription() : this.subscription,
      invoices: invoices ?? this.invoices,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      successMessage: successMessage != null ? successMessage() : this.successMessage,
    );
  }
}

final subscriptionControllerProvider =
    AsyncNotifierProvider<SubscriptionController, SubscriptionState>(() {
  return SubscriptionController();
});

class SubscriptionController extends AsyncNotifier<SubscriptionState> {
  @override
  Future<SubscriptionState> build() async {
    final user = ref.watch(authControllerProvider).value;
    if (user == null || user.organizationId.isEmpty) {
      return const SubscriptionState();
    }

    final api = ref.read(subscriptionApiServiceProvider);

    // Fetch subscription #109
    final subRes = await api.getCurrentSubscription(user.organizationId);
    if (!subRes.success) {
      return SubscriptionState(errorMessage: subRes.message);
    }

    final sub = subRes.data;
    List<SubscriptionInvoice> invoices = sub?.invoices ?? [];

    // If subscription exists, fetch invoice history #113 for complete listing
    if (sub != null) {
      final invRes = await api.getInvoices(user.organizationId);
      if (invRes.success && invRes.data != null && invRes.data!.isNotEmpty) {
        invoices = invRes.data!;
      }
    }

    return SubscriptionState(
      subscription: sub,
      invoices: invoices,
    );
  }

  Future<void> refresh() async {
    final user = ref.read(authControllerProvider).value;
    if (user == null || user.organizationId.isEmpty) return;

    state = const AsyncLoading();
    final api = ref.read(subscriptionApiServiceProvider);

    final subRes = await api.getCurrentSubscription(user.organizationId);
    if (!subRes.success) {
      state = AsyncData(SubscriptionState(errorMessage: subRes.message));
      return;
    }

    final sub = subRes.data;
    List<SubscriptionInvoice> invoices = sub?.invoices ?? [];

    if (sub != null) {
      final invRes = await api.getInvoices(user.organizationId);
      if (invRes.success && invRes.data != null && invRes.data!.isNotEmpty) {
        invoices = invRes.data!;
      }
    }

    state = AsyncData(
      SubscriptionState(
        subscription: sub,
        invoices: invoices,
      ),
    );
  }

  Future<bool> createSubscription({
    required String plan,
    required num price,
    String cycle = 'monthly',
    required int outletsIncluded,
    required DateTime renewsAt,
  }) async {
    if (!kSubscriptionWriteEnabled) return false;

    final user = ref.read(authControllerProvider).value;
    if (user == null || user.organizationId.isEmpty) return false;

    final cur = state.value ?? const SubscriptionState();
    state = AsyncData(cur.copyWith(isSubmitting: true, errorMessage: () => null));

    final api = ref.read(subscriptionApiServiceProvider);
    final res = await api.createSubscription(
      user.organizationId,
      plan: plan,
      price: price,
      cycle: cycle,
      outletsIncluded: outletsIncluded,
      renewsAt: renewsAt,
    );

    if (res.success && res.data != null) {
      state = AsyncData(
        cur.copyWith(
          isSubmitting: false,
          subscription: () => res.data,
          invoices: res.data!.invoices,
          successMessage: () => 'Subscription created successfully',
        ),
      );
      return true;
    } else {
      state = AsyncData(
        cur.copyWith(
          isSubmitting: false,
          errorMessage: () => res.message,
        ),
      );
      return false;
    }
  }

  Future<bool> updatePlan({
    required String plan,
    required num price,
    required int outletsIncluded,
  }) async {
    if (!kSubscriptionWriteEnabled) return false;

    final user = ref.read(authControllerProvider).value;
    if (user == null || user.organizationId.isEmpty) return false;

    final cur = state.value ?? const SubscriptionState();
    state = AsyncData(cur.copyWith(isSubmitting: true, errorMessage: () => null));

    final api = ref.read(subscriptionApiServiceProvider);
    final res = await api.updatePlan(
      user.organizationId,
      plan: plan,
      price: price,
      outletsIncluded: outletsIncluded,
    );

    if (res.success && res.data != null) {
      state = AsyncData(
        cur.copyWith(
          isSubmitting: false,
          subscription: () => res.data,
          invoices: res.data!.invoices,
          successMessage: () => 'Subscription plan updated',
        ),
      );
      return true;
    } else {
      state = AsyncData(
        cur.copyWith(
          isSubmitting: false,
          errorMessage: () => res.message,
        ),
      );
      return false;
    }
  }

  Future<bool> addInvoice({
    required String invoiceNo,
    DateTime? date,
    required num amount,
    String status = 'Pending',
  }) async {
    if (!kSubscriptionWriteEnabled) return false;

    final user = ref.read(authControllerProvider).value;
    if (user == null || user.organizationId.isEmpty) return false;

    final cur = state.value ?? const SubscriptionState();
    state = AsyncData(cur.copyWith(isSubmitting: true, errorMessage: () => null));

    final api = ref.read(subscriptionApiServiceProvider);
    final res = await api.addInvoice(
      user.organizationId,
      invoiceNo: invoiceNo,
      date: date,
      amount: amount,
      status: status,
    );

    if (res.success && res.data != null) {
      state = AsyncData(
        cur.copyWith(
          isSubmitting: false,
          subscription: () => res.data,
          invoices: res.data!.invoices,
          successMessage: () => 'Invoice added successfully',
        ),
      );
      return true;
    } else {
      state = AsyncData(
        cur.copyWith(
          isSubmitting: false,
          errorMessage: () => res.message,
        ),
      );
      return false;
    }
  }
}
