import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/dio_client.dart';
import '../../core/network/api_response.dart';
import '../../core/network/json_utils.dart';
import '../../models/order.dart';

/// The backend route path segment for fetching orders by type (#51A).
/// Note: The API PDF (BMB_KITCHEN_BACKEND_API_8) documents singular 'order'
/// (GET /api/orders/v1/:organizationId/order/:orderType), but the live server
/// answers on plural 'orders' (GET /api/orders/v1/:organizationId/orders/:orderType)
/// and returns 404 on singular. The backend developer will confirm route harmonization.
const String kOrdersByTypeSegment = 'orders';

final orderApiServiceProvider = Provider<OrderApiService>((ref) {
  return OrderApiService(ref.watch(dioProvider));
});

class OrderApiService {
  final Dio _dio;

  OrderApiService(this._dio);

  String _basePath(String organizationId) => '/api/orders/v1/$organizationId';

  ApiResponse<T> _errorResponse<T>(dynamic e) {
    if (e is DioException && e.response != null) {
      final res = e.response!;
      final body = res.data;
      String message = 'Unknown error';
      if (body is Map) {
        if (body['message'] != null && body['message'].toString().trim().isNotEmpty) {
          message = body['message'].toString();
        } else if (body['error'] != null && body['error'].toString().trim().isNotEmpty) {
          message = body['error'].toString();
        } else if (body['msg'] != null && body['msg'].toString().trim().isNotEmpty) {
          message = body['msg'].toString();
        } else if (body['errorMessage'] != null && body['errorMessage'].toString().trim().isNotEmpty) {
          message = body['errorMessage'].toString();
        } else if (body['errors'] != null) {
          final errs = body['errors'];
          if (errs is List && errs.isNotEmpty) {
            message = errs.join(', ');
          } else {
            message = errs.toString();
          }
        }
      } else if (body is String && body.trim().isNotEmpty) {
        message = body;
      }
      return ApiResponse<T>(
        success: false,
        statusCode: res.statusCode ?? 500,
        message: message,
        data: null,
      );
    }
    return ApiResponse<T>(
      success: false,
      statusCode: 500,
      message: e.toString(),
      data: null,
    );
  }

  // #44: GET /api/orders/v1/:organizationId (Active POS Orders)
  Future<ApiResponse<List<Order>>> getActiveOrders(
    String organizationId, {
    String? outletId,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (outletId != null && outletId.isNotEmpty) {
        queryParams['outletId'] = outletId;
      }

      final response = await _dio.get(
        _basePath(organizationId),
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      final rawData = response.data is Map ? response.data['data'] : response.data;
      final listData = JsonUtils.extractList(rawData);
      final list = listData
          .whereType<Map<String, dynamic>>()
          .map((e) => Order.fromJson(e))
          .toList();

      return ApiResponse<List<Order>>(
        success: response.data['ok'] == true || response.statusCode == 200,
        statusCode: response.statusCode ?? 200,
        message: response.data['message']?.toString() ?? 'Success',
        data: list,
      );
    } catch (e) {
      return _errorResponse<List<Order>>(e);
    }
  }

  // #45: POST /api/orders/v1/:organizationId (Create Order)
  Future<ApiResponse<Order>> createOrder(
    String organizationId, {
    required String outletId,
    required String orderType,
    String? tableId,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final payload = <String, dynamic>{
        'outletId': outletId,
        'orderType': orderType,
        'items': items,
        if (tableId != null && tableId.isNotEmpty) 'tableId': tableId,
      };

      final response = await _dio.post(
        _basePath(organizationId),
        data: payload,
      );
      final mapData = JsonUtils.extractMap(response.data['data']);
      return ApiResponse<Order>(
        success: response.data['ok'] == true || response.statusCode == 201,
        statusCode: response.statusCode ?? 201,
        message: response.data['message']?.toString() ?? 'Order placed successfully',
        data: Order.fromJson(mapData),
      );
    } catch (e) {
      return _errorResponse<Order>(e);
    }
  }

  // #46/#47: GET /api/orders/v1/:organizationId/:id (Single Order)
  Future<ApiResponse<Order>> getOrder(
    String organizationId,
    String orderId,
  ) async {
    try {
      final response = await _dio.get('${_basePath(organizationId)}/$orderId');
      final mapData = JsonUtils.extractMap(response.data['data']);
      return ApiResponse<Order>(
        success: response.data['ok'] == true || response.statusCode == 200,
        statusCode: response.statusCode ?? 200,
        message: response.data['message']?.toString() ?? 'Success',
        data: Order.fromJson(mapData),
      );
    } catch (e) {
      return _errorResponse<Order>(e);
    }
  }

  // #48: POST /api/orders/v1/:organizationId/:id/items (Add Items to Order)
  Future<ApiResponse<Order>> addItems(
    String organizationId,
    String orderId,
    List<Map<String, dynamic>> items,
  ) async {
    try {
      final response = await _dio.post(
        '${_basePath(organizationId)}/$orderId/items',
        data: {'items': items},
      );
      final mapData = JsonUtils.extractMap(response.data['data']);
      return ApiResponse<Order>(
        success: response.data['ok'] == true || response.statusCode == 200,
        statusCode: response.statusCode ?? 200,
        message: response.data['message']?.toString() ?? 'Items added successfully',
        data: Order.fromJson(mapData),
      );
    } catch (e) {
      return _errorResponse<Order>(e);
    }
  }

  // #49: PATCH /api/orders/v1/:organizationId/:id/items/:itemId/status (Change Item Status)
  Future<ApiResponse<Order>> updateItemStatus(
    String organizationId,
    String orderId,
    String itemId,
    String status,
  ) async {
    try {
      final response = await _dio.patch(
        '${_basePath(organizationId)}/$orderId/items/$itemId/status',
        data: {'status': status},
      );
      final mapData = JsonUtils.extractMap(response.data['data']);
      return ApiResponse<Order>(
        success: response.data['ok'] == true || response.statusCode == 200,
        statusCode: response.statusCode ?? 200,
        message: response.data['message']?.toString() ?? 'Item status updated',
        data: Order.fromJson(mapData),
      );
    } catch (e) {
      return _errorResponse<Order>(e);
    }
  }

  // #50A: GET /api/orders/v1/:organizationId/:id/checkout-preview
  Future<ApiResponse<OrderCheckoutPreview>> getCheckoutPreview(
    String organizationId,
    String orderId,
  ) async {
    try {
      final response = await _dio.get(
        '${_basePath(organizationId)}/$orderId/checkout-preview',
      );
      final mapData = JsonUtils.extractMap(response.data['data']);
      return ApiResponse<OrderCheckoutPreview>(
        success: response.data['ok'] == true || response.statusCode == 200,
        statusCode: response.statusCode ?? 200,
        message: response.data['message']?.toString() ?? 'Success',
        data: OrderCheckoutPreview.fromJson(mapData),
      );
    } catch (e) {
      return _errorResponse<OrderCheckoutPreview>(e);
    }
  }

  // #50: POST /api/orders/v1/:organizationId/:id/checkout (Complete Order)
  Future<ApiResponse<Order>> checkout(
    String organizationId,
    String orderId, {
    required String paymentMethod,
    double? manualDiscount,
  }) async {
    try {
      final payload = <String, dynamic>{
        'paymentMethod': paymentMethod,
        if (manualDiscount != null && manualDiscount > 0)
          'manualDiscount': manualDiscount,
      };

      final response = await _dio.post(
        '${_basePath(organizationId)}/$orderId/checkout',
        data: payload,
      );
      final mapData = JsonUtils.extractMap(response.data['data']);
      return ApiResponse<Order>(
        success: response.data['ok'] == true || response.statusCode == 200,
        statusCode: response.statusCode ?? 200,
        message: response.data['message']?.toString() ?? 'Order checked out successfully',
        data: Order.fromJson(mapData),
      );
    } catch (e) {
      return _errorResponse<Order>(e);
    }
  }

  // #51: PATCH /api/orders/v1/:organizationId/:id/cancel (Cancel Order)
  Future<ApiResponse<Order>> cancelOrder(
    String organizationId,
    String orderId,
  ) async {
    try {
      final response = await _dio.patch(
        '${_basePath(organizationId)}/$orderId/cancel',
      );
      final mapData = JsonUtils.extractMap(response.data['data']);
      return ApiResponse<Order>(
        success: response.data['ok'] == true || response.statusCode == 200,
        statusCode: response.statusCode ?? 200,
        message: response.data['message']?.toString() ?? 'Order cancelled successfully',
        data: Order.fromJson(mapData),
      );
    } catch (e) {
      return _errorResponse<Order>(e);
    }
  }

  // #51A: GET /api/orders/v1/:organizationId/orders/:orderType
  Future<ApiResponse<OrderListResponse>> getOrdersByType(
    String organizationId,
    String orderType, {
    String? outletId,
    String? orderStatus,
    String? paymentStatus,
    String? scope,
    String? from,
    String? to,
    int? page,
    int? limit,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        if (outletId != null && outletId.isNotEmpty) 'outletId': outletId,
        if (orderStatus != null && orderStatus.isNotEmpty) 'orderStatus': orderStatus,
        if (paymentStatus != null && paymentStatus.isNotEmpty) 'paymentStatus': paymentStatus,
        if (scope != null && scope.isNotEmpty) 'scope': scope,
        if (from != null && from.isNotEmpty) 'from': from,
        if (to != null && to.isNotEmpty) 'to': to,
        'page': ?page,
        'limit': ?limit,
      };

      final response = await _dio.get(
        '${_basePath(organizationId)}/$kOrdersByTypeSegment/$orderType',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final mapData = JsonUtils.extractMap(response.data['data']);
      return ApiResponse<OrderListResponse>(
        success: response.data['ok'] == true || response.statusCode == 200,
        statusCode: response.statusCode ?? 200,
        message: response.data['message']?.toString() ?? 'Success',
        data: OrderListResponse.fromJson(mapData),
      );
    } catch (e) {
      return _errorResponse<OrderListResponse>(e);
    }
  }

  // #51B: GET /api/orders/v1/:organizationId/kitchen
  Future<ApiResponse<KitchenOrdersResponse>> getKitchenOrders(
    String organizationId, {
    String? outletId,
    String? status, // in_queue | preparing | ready | served | cancelled
    String? orderType,
    String? scope, // running | today
    int? page,
    int? limit,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        if (outletId != null && outletId.isNotEmpty) 'outletId': outletId,
        if (status != null && status.isNotEmpty) 'status': status,
        if (orderType != null && orderType.isNotEmpty) 'orderType': orderType,
        if (scope != null && scope.isNotEmpty) 'scope': scope,
        'page': ?page,
        'limit': ?limit,
      };

      final response = await _dio.get(
        '${_basePath(organizationId)}/kitchen',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final mapData = JsonUtils.extractMap(response.data['data']);
      return ApiResponse<KitchenOrdersResponse>(
        success: response.data['ok'] == true || response.statusCode == 200,
        statusCode: response.statusCode ?? 200,
        message: response.data['message']?.toString() ?? 'Success',
        data: KitchenOrdersResponse.fromJson(mapData),
      );
    } catch (e) {
      return _errorResponse<KitchenOrdersResponse>(e);
    }
  }

  // #51C: GET /api/orders/v1/:organizationId/my-orders
  Future<ApiResponse<PaidOrdersResponse>> getMyOrders(
    String organizationId, {
    String? outletId,
    String? scope, // today | week | month | year | custom | all
    String? from,
    String? to,
    String? orderType,
    String? paymentMethod,
    String? tableId,
    String? customerId,
    String? search,
    double? minAmount,
    double? maxAmount,
    bool? hasDiscount,
    String? sortBy,
    String? sortOrder,
    int? page,
    int? limit,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        if (outletId != null && outletId.isNotEmpty) 'outletId': outletId,
        if (scope != null && scope.isNotEmpty) 'scope': scope,
        if (from != null && from.isNotEmpty) 'from': from,
        if (to != null && to.isNotEmpty) 'to': to,
        if (orderType != null && orderType.isNotEmpty) 'orderType': orderType,
        if (paymentMethod != null && paymentMethod.isNotEmpty) 'paymentMethod': paymentMethod,
        if (tableId != null && tableId.isNotEmpty) 'tableId': tableId,
        if (customerId != null && customerId.isNotEmpty) 'customerId': customerId,
        if (search != null && search.isNotEmpty) 'search': search,
        'minAmount': ?minAmount,
        'maxAmount': ?maxAmount,
        'hasDiscount': ?hasDiscount,
        if (sortBy != null && sortBy.isNotEmpty) 'sortBy': sortBy,
        if (sortOrder != null && sortOrder.isNotEmpty) 'sortOrder': sortOrder,
        'page': ?page,
        'limit': ?limit,
      };

      final response = await _dio.get(
        '${_basePath(organizationId)}/my-orders',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final mapData = JsonUtils.extractMap(response.data['data']);
      return ApiResponse<PaidOrdersResponse>(
        success: response.data['ok'] == true || response.statusCode == 200,
        statusCode: response.statusCode ?? 200,
        message: response.data['message']?.toString() ?? 'Success',
        data: PaidOrdersResponse.fromJson(mapData),
      );
    } catch (e) {
      return _errorResponse<PaidOrdersResponse>(e);
    }
  }
}
