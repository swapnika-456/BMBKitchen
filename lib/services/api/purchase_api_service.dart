import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/dio_client.dart';
import '../../core/network/api_response.dart';

final purchaseApiServiceProvider = Provider<PurchaseApiService>((ref) {
  return PurchaseApiService(ref.watch(dioProvider));
});

class PurchaseApiService {
  final Dio _dio;

  PurchaseApiService(this._dio);

  String _basePath(String organizationId) => '/api/purchase/v1/$organizationId';

  ApiResponse<T> _errorResponse<T>(dynamic e) {
    if (e is DioException && e.response != null) {
      final res = e.response!;
      return ApiResponse<T>.fromJson(res.data ?? {}, res.statusCode ?? 500);
    }
    return ApiResponse<T>(
      success: false,
      statusCode: 500,
      message: e.toString(),
    );
  }

  Future<ApiResponse<List<dynamic>>> getActivePurchases(String organizationId) async {
    try {
      final response = await _dio.get(_basePath(organizationId));
      return ApiResponse<List<dynamic>>.fromJson(response.data, response.statusCode!);
    } catch (e) {
      return _errorResponse<List<dynamic>>(e);
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> createPurchase(
    String organizationId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.post(_basePath(organizationId), data: data);
      return ApiResponse<Map<String, dynamic>>.fromJson(response.data, response.statusCode!);
    } catch (e) {
      return _errorResponse<Map<String, dynamic>>(e);
    }
  }

  Future<ApiResponse<List<dynamic>>> getInactivePurchases(String organizationId) async {
    try {
      final response = await _dio.get('${_basePath(organizationId)}/inactive');
      return ApiResponse<List<dynamic>>.fromJson(response.data, response.statusCode!);
    } catch (e) {
      return _errorResponse<List<dynamic>>(e);
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> getPurchase(
    String organizationId,
    String purchaseId,
  ) async {
    try {
      final response = await _dio.get('${_basePath(organizationId)}/$purchaseId');
      return ApiResponse<Map<String, dynamic>>.fromJson(response.data, response.statusCode!);
    } catch (e) {
      return _errorResponse<Map<String, dynamic>>(e);
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> updatePaymentStatus(
    String organizationId,
    String purchaseId,
    String paymentStatus,
  ) async {
    try {
      final response = await _dio.put(
        '${_basePath(organizationId)}/$purchaseId',
        data: {'paymentStatus': paymentStatus},
      );
      return ApiResponse<Map<String, dynamic>>.fromJson(response.data, response.statusCode!);
    } catch (e) {
      return _errorResponse<Map<String, dynamic>>(e);
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> restorePurchase(
    String organizationId,
    String purchaseId,
  ) async {
    try {
      final response = await _dio.patch('${_basePath(organizationId)}/$purchaseId/restore');
      return ApiResponse<Map<String, dynamic>>.fromJson(response.data, response.statusCode!);
    } catch (e) {
      return _errorResponse<Map<String, dynamic>>(e);
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> deletePurchase(
    String organizationId,
    String purchaseId,
  ) async {
    try {
      final response = await _dio.delete('${_basePath(organizationId)}/$purchaseId');
      return ApiResponse<Map<String, dynamic>>.fromJson(response.data, response.statusCode!);
    } catch (e) {
      return _errorResponse<Map<String, dynamic>>(e);
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> hardDeletePurchase(
    String organizationId,
    String purchaseId,
  ) async {
    try {
      final response = await _dio.delete('${_basePath(organizationId)}/$purchaseId/hard');
      return ApiResponse<Map<String, dynamic>>.fromJson(response.data, response.statusCode!);
    } catch (e) {
      return _errorResponse<Map<String, dynamic>>(e);
    }
  }
}
