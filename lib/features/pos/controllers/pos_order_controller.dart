import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_response.dart';
import '../../../models/order.dart';
import '../../../services/api/order_api_service.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../settings/controllers/active_outlet_provider.dart';
import '../../supply_chain/providers/inventory_providers.dart';
import '../../tables/providers/table_providers.dart';

final activeOrdersProvider =
    AsyncNotifierProvider<ActiveOrdersNotifier, List<Order>>(() {
  return ActiveOrdersNotifier();
});

class ActiveOrdersNotifier extends AsyncNotifier<List<Order>> {
  @override
  Future<List<Order>> build() async {
    return _fetchOrders();
  }

  Future<List<Order>> _fetchOrders() async {
    final user = ref.read(authControllerProvider).value;
    final orgId = user?.organizationId ?? '';
    if (orgId.isEmpty) return [];

    final activeOutlet = ref.watch(activeOutletProvider);
    final outletId = activeOutlet?.id;

    final api = ref.read(orderApiServiceProvider);
    final res = await api.getActiveOrders(orgId, outletId: outletId);
    if (!res.success) {
      throw Exception(res.message);
    }
    return res.data ?? [];
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchOrders());
  }

  /// Create a new order (#45)
  Future<ApiResponse<Order>> createOrder({
    required String outletId,
    required String orderType,
    String? tableId,
    required List<Map<String, dynamic>> items,
  }) async {
    final user = ref.read(authControllerProvider).value;
    final orgId = user?.organizationId ?? '';
    if (orgId.isEmpty) {
      return ApiResponse(success: false, statusCode: 400, message: 'No organization found');
    }

    final api = ref.read(orderApiServiceProvider);
    final res = await api.createOrder(
      orgId,
      outletId: outletId,
      orderType: orderType,
      tableId: tableId,
      items: items,
    );

    if (res.success) {
      ref.invalidateSelf();
      ref.invalidate(activeTablesProvider);
    }
    return res;
  }

  /// Add items to existing order (#48)
  Future<ApiResponse<Order>> addItems(
    String orderId,
    List<Map<String, dynamic>> items,
  ) async {
    final user = ref.read(authControllerProvider).value;
    final orgId = user?.organizationId ?? '';
    if (orgId.isEmpty) {
      return ApiResponse(success: false, statusCode: 400, message: 'No organization found');
    }

    final api = ref.read(orderApiServiceProvider);
    final res = await api.addItems(orgId, orderId, items);

    if (res.success) {
      ref.invalidateSelf();
    }
    return res;
  }

  /// Update an item's kitchen/service status (#49)
  Future<ApiResponse<Order>> updateItemStatus(
    String orderId,
    String itemId,
    String status,
  ) async {
    final user = ref.read(authControllerProvider).value;
    final orgId = user?.organizationId ?? '';
    if (orgId.isEmpty) {
      return ApiResponse(success: false, statusCode: 400, message: 'No organization found');
    }

    final api = ref.read(orderApiServiceProvider);
    final res = await api.updateItemStatus(orgId, orderId, itemId, status);

    if (res.success) {
      ref.invalidateSelf();
    }
    return res;
  }

  /// Complete and checkout an order (#50)
  Future<ApiResponse<Order>> checkout(
    String orderId, {
    required String paymentMethod,
    double? manualDiscount,
  }) async {
    final user = ref.read(authControllerProvider).value;
    final orgId = user?.organizationId ?? '';
    if (orgId.isEmpty) {
      return ApiResponse(success: false, statusCode: 400, message: 'No organization found');
    }

    final api = ref.read(orderApiServiceProvider);
    final res = await api.checkout(
      orgId,
      orderId,
      paymentMethod: paymentMethod,
      manualDiscount: manualDiscount,
    );

    if (res.success) {
      ref.invalidateSelf();
      ref.invalidate(activeTablesProvider);
      ref.invalidate(activeInventoryProvider);
    }
    return res;
  }

  /// Cancel an order and free the table (#51)
  Future<ApiResponse<Order>> cancelOrder(String orderId) async {
    final user = ref.read(authControllerProvider).value;
    final orgId = user?.organizationId ?? '';
    if (orgId.isEmpty) {
      return ApiResponse(success: false, statusCode: 400, message: 'No organization found');
    }

    final api = ref.read(orderApiServiceProvider);
    final res = await api.cancelOrder(orgId, orderId);

    if (res.success) {
      ref.invalidateSelf();
      ref.invalidate(activeTablesProvider);
    }
    return res;
  }

  /// Fetch checkout preview (#50A)
  Future<ApiResponse<OrderCheckoutPreview>> getCheckoutPreview(String orderId) async {
    final user = ref.read(authControllerProvider).value;
    final orgId = user?.organizationId ?? '';
    if (orgId.isEmpty) {
      return ApiResponse(success: false, statusCode: 400, message: 'No organization found');
    }

    final api = ref.read(orderApiServiceProvider);
    return api.getCheckoutPreview(orgId, orderId);
  }

  /// Fetch single order details (#46)
  Future<ApiResponse<Order>> getOrder(String orderId) async {
    final user = ref.read(authControllerProvider).value;
    final orgId = user?.organizationId ?? '';
    if (orgId.isEmpty) {
      return ApiResponse(success: false, statusCode: 400, message: 'No organization found');
    }

    final api = ref.read(orderApiServiceProvider);
    return api.getOrder(orgId, orderId);
  }
}
