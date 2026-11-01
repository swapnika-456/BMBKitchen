import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_exceptions.dart';
import '../../core/network/api_response.dart';
import '../../core/network/dio_client.dart';
import '../../core/network/json_utils.dart';
import '../../models/payment.dart';

final paymentApiServiceProvider = Provider<PaymentApiService>((ref) {
  final dio = ref.watch(dioProvider);
  return PaymentApiService(dio);
});

class PaymentApiService {
  final Dio _dio;

  PaymentApiService(this._dio);

  String _basePath(String organizationId) => '/api/payment/v1/$organizationId';

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

  // #127: GET /api/payment/v1/:organizationId
  Future<ApiResponse<PaymentListResponse>> getPayments(
    String organizationId, {
    String? outletId,
    String? paymentMethod,
    String? orderType,
    String? scope, // today | week | month | year | custom | all
    String? from,
    String? to,
    int? page,
    int? limit,
  }) async {
    try {
      // The backend treats `to` date in custom date range queries as exclusive UTC midnight
      // (e.g. timestamp < 2026-10-24T00:00:00.000Z, which excludes orders placed on that day).
      // We adjust `to` by +1 day here in the service layer only, ensuring the user's selected
      // range remains displayed unchanged in the UI.
      String? adjustedTo = to;
      if (adjustedTo != null && adjustedTo.isNotEmpty) {
        final parsed = DateTime.tryParse(adjustedTo);
        if (parsed != null) {
          final nextDay = parsed.add(const Duration(days: 1));
          adjustedTo =
              "${nextDay.year}-${nextDay.month.toString().padLeft(2, '0')}-${nextDay.day.toString().padLeft(2, '0')}";
        }
      }

      final queryParams = <String, dynamic>{
        if (outletId != null && outletId.isNotEmpty) 'outletId': outletId,
        if (paymentMethod != null && paymentMethod.isNotEmpty) 'paymentMethod': paymentMethod,
        if (orderType != null && orderType.isNotEmpty) 'orderType': orderType,
        if (scope != null && scope.isNotEmpty) 'scope': scope,
        if (from != null && from.isNotEmpty) 'from': from,
        if (adjustedTo != null && adjustedTo.isNotEmpty) 'to': adjustedTo,
        'page': ?page,
        'limit': ?limit,
      };

      final response = await _dio.get(
        _basePath(organizationId),
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final mapData = JsonUtils.extractMap(response.data['data']);
      return ApiResponse<PaymentListResponse>(
        success: response.data['ok'] == true || response.statusCode == 200,
        statusCode: response.statusCode ?? 200,
        message: response.data['message']?.toString() ?? 'Success',
        data: PaymentListResponse.fromJson(mapData),
      );
    } catch (e) {
      return _errorResponse<PaymentListResponse>(e);
    }
  }

  // #128: GET /api/payment/v1/:organizationId/:id
  Future<ApiResponse<PaymentDetail>> getPaymentDetail(
    String organizationId,
    String paymentId,
  ) async {
    try {
      final response = await _dio.get(
        '${_basePath(organizationId)}/$paymentId',
      );

      final mapData = JsonUtils.extractMap(response.data['data']);
      return ApiResponse<PaymentDetail>(
        success: response.data['ok'] == true || response.statusCode == 200,
        statusCode: response.statusCode ?? 200,
        message: response.data['message']?.toString() ?? 'Success',
        data: PaymentDetail.fromJson(mapData),
      );
    } catch (e) {
      return _errorResponse<PaymentDetail>(e);
    }
  }
}
