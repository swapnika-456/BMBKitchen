import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_exceptions.dart';
import '../../core/network/api_response.dart';
import '../../core/network/dio_client.dart';
import '../../core/network/json_utils.dart';
import '../../models/subscription.dart';

final subscriptionApiServiceProvider = Provider<SubscriptionApiService>((ref) {
  final dio = ref.watch(dioProvider);
  return SubscriptionApiService(dio);
});

/// Subscription API Service covering endpoints #109 to #113
/// from BMB_KITCHEN_BACKEND_API_8:
/// Base: /api/subscription/v1/:organizationId
class SubscriptionApiService {
  final Dio _dio;

  SubscriptionApiService(this._dio);

  String _basePath(String organizationId) =>
      '/api/subscription/v1/$organizationId';

  ApiResponse<T> _errorResponse<T>(dynamic error) {
    if (error is DioException) {
      final statusCode = error.response?.statusCode ?? 500;
      final serverMsg = ApiExceptions.getDetailedErrorMessage(error);
      return ApiResponse<T>(
        success: false,
        statusCode: statusCode,
        message: serverMsg,
      );
    }
    return ApiResponse<T>(
      success: false,
      statusCode: 500,
      message: error.toString(),
    );
  }

  // #109: GET /api/subscription/v1/:organizationId
  Future<ApiResponse<Subscription?>> getCurrentSubscription(
    String organizationId,
  ) async {
    try {
      final response = await _dio.get(_basePath(organizationId));
      if (response.statusCode == 404 || response.data['data'] == null) {
        return ApiResponse<Subscription?>(
          success: true,
          statusCode: response.statusCode ?? 404,
          message: 'No subscription yet',
          data: null,
        );
      }

      final mapData = JsonUtils.extractMap(response.data['data']);
      return ApiResponse<Subscription?>(
        success: response.data['ok'] == true || response.statusCode == 200,
        statusCode: response.statusCode ?? 200,
        message: response.data['message']?.toString() ?? 'Subscription loaded',
        data: Subscription.fromJson(mapData),
      );
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 404) {
        return ApiResponse<Subscription?>(
          success: true,
          statusCode: 404,
          message: 'No subscription yet',
          data: null,
        );
      }
      return _errorResponse<Subscription?>(e);
    }
  }

  // #110: POST /api/subscription/v1/:organizationId
  Future<ApiResponse<Subscription>> createSubscription(
    String organizationId, {
    required String plan,
    required num price,
    String cycle = 'monthly',
    required int outletsIncluded,
    required DateTime renewsAt,
  }) async {
    try {
      final payload = {
        'plan': plan,
        'price': price,
        'cycle': cycle,
        'outletsIncluded': outletsIncluded,
        'renewsAt': renewsAt.toIso8601String(),
      };

      final response = await _dio.post(_basePath(organizationId), data: payload);
      final mapData = JsonUtils.extractMap(response.data['data']);

      return ApiResponse<Subscription>(
        success: response.data['ok'] == true || response.statusCode == 201,
        statusCode: response.statusCode ?? 201,
        message: response.data['message']?.toString() ?? 'Subscription created',
        data: Subscription.fromJson(mapData),
      );
    } catch (e) {
      return _errorResponse<Subscription>(e);
    }
  }

  // #111: PATCH /api/subscription/v1/:organizationId/plan
  Future<ApiResponse<Subscription>> updatePlan(
    String organizationId, {
    required String plan,
    required num price,
    required int outletsIncluded,
  }) async {
    try {
      final payload = {
        'plan': plan,
        'price': price,
        'outletsIncluded': outletsIncluded,
      };

      final response = await _dio.patch(
        '${_basePath(organizationId)}/plan',
        data: payload,
      );
      final mapData = JsonUtils.extractMap(response.data['data']);

      return ApiResponse<Subscription>(
        success: response.data['ok'] == true || response.statusCode == 200,
        statusCode: response.statusCode ?? 200,
        message: response.data['message']?.toString() ?? 'Plan updated',
        data: Subscription.fromJson(mapData),
      );
    } catch (e) {
      return _errorResponse<Subscription>(e);
    }
  }

  // #112: POST /api/subscription/v1/:organizationId/invoices
  // Server returns { ok: true, data: subscription }
  Future<ApiResponse<Subscription>> addInvoice(
    String organizationId, {
    required String invoiceNo,
    DateTime? date,
    required num amount,
    String status = 'Pending',
  }) async {
    try {
      final payload = {
        'invoiceNo': invoiceNo,
        if (date != null) 'date': date.toIso8601String(),
        'amount': amount,
        'status': status,
      };

      final response = await _dio.post(
        '${_basePath(organizationId)}/invoices',
        data: payload,
      );
      final mapData = JsonUtils.extractMap(response.data['data']);

      return ApiResponse<Subscription>(
        success: response.data['ok'] == true || response.statusCode == 200,
        statusCode: response.statusCode ?? 200,
        message: response.data['message']?.toString() ?? 'Invoice added',
        data: Subscription.fromJson(mapData),
      );
    } catch (e) {
      return _errorResponse<Subscription>(e);
    }
  }

  // #113: GET /api/subscription/v1/:organizationId/invoices
  Future<ApiResponse<List<SubscriptionInvoice>>> getInvoices(
    String organizationId,
  ) async {
    try {
      final response = await _dio.get('${_basePath(organizationId)}/invoices');
      final listData = JsonUtils.extractList(response.data['data']);
      final invoices = listData
          .map((item) => SubscriptionInvoice.fromJson(item))
          .toList();

      return ApiResponse<List<SubscriptionInvoice>>(
        success: response.data['ok'] == true || response.statusCode == 200,
        statusCode: response.statusCode ?? 200,
        message: response.data['message']?.toString() ?? 'Invoices loaded',
        data: invoices,
      );
    } catch (e) {
      return _errorResponse<List<SubscriptionInvoice>>(e);
    }
  }
}
