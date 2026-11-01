import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_exceptions.dart';
import '../../core/network/api_response.dart';
import '../../core/network/dio_client.dart';

final taxSettingsApiServiceProvider = Provider<TaxSettingsApiService>((ref) {
  final dio = ref.watch(dioProvider);
  return TaxSettingsApiService(dio);
});

class TaxSettingsApiService {
  final Dio _dio;

  TaxSettingsApiService(this._dio);

  // #114 GET /:organizationId
  Future<ApiResponse<Map<String, dynamic>>> getTaxSettings(
    String organizationId,
  ) async {
    try {
      final response = await _dio.get('/api/tax-settings/v1/$organizationId');
      return ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        response.statusCode!,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        statusCode: e is DioException ? e.response?.statusCode ?? 0 : 0,
        message: ApiExceptions.getDetailedErrorMessage(e),
      );
    }
  }

  // #115 POST /:organizationId
  Future<ApiResponse<Map<String, dynamic>>> createTaxSettings(
    String organizationId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.post(
        '/api/tax-settings/v1/$organizationId',
        data: data,
      );
      return ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        response.statusCode!,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        statusCode: e is DioException ? e.response?.statusCode ?? 0 : 0,
        message: ApiExceptions.getDetailedErrorMessage(e),
      );
    }
  }

  // #116 PATCH /:organizationId
  Future<ApiResponse<Map<String, dynamic>>> updateTaxSettings(
    String organizationId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.patch(
        '/api/tax-settings/v1/$organizationId',
        data: data,
      );
      return ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        response.statusCode!,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        statusCode: e is DioException ? e.response?.statusCode ?? 0 : 0,
        message: ApiExceptions.getDetailedErrorMessage(e),
      );
    }
  }

  // #117 POST /:organizationId/rates
  Future<ApiResponse<Map<String, dynamic>>> addTaxRate(
    String organizationId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.post(
        '/api/tax-settings/v1/$organizationId/rates',
        data: data,
      );
      return ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        response.statusCode!,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        statusCode: e is DioException ? e.response?.statusCode ?? 0 : 0,
        message: ApiExceptions.getDetailedErrorMessage(e),
      );
    }
  }

  // #118 PATCH /:organizationId/rates/:rateId/default
  Future<ApiResponse<Map<String, dynamic>>> setDefaultTaxRate(
    String organizationId,
    String rateId,
  ) async {
    try {
      final response = await _dio.patch(
        '/api/tax-settings/v1/$organizationId/rates/$rateId/default',
      );
      return ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        response.statusCode!,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        statusCode: e is DioException ? e.response?.statusCode ?? 0 : 0,
        message: ApiExceptions.getDetailedErrorMessage(e),
      );
    }
  }
}
