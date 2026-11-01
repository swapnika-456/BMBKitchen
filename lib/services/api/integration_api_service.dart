import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_exceptions.dart';
import '../../core/network/api_response.dart';
import '../../core/network/dio_client.dart';
import '../../core/network/json_utils.dart';
import '../../models/integration.dart';

final integrationApiServiceProvider = Provider<IntegrationApiService>((ref) {
  final dio = ref.watch(dioProvider);
  return IntegrationApiService(dio);
});

/// Integration API Service covering endpoints #174 to #178
/// Base: /api/integration/v1/:organizationId
class IntegrationApiService {
  final Dio _dio;

  IntegrationApiService(this._dio);

  String _basePath(String organizationId) =>
      '/api/integration/v1/$organizationId';

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

  // #174: POST /api/integration/v1/:organizationId/seed
  Future<ApiResponse<List<Integration>>> seedDefaults(
    String organizationId,
  ) async {
    try {
      final response = await _dio.post('${_basePath(organizationId)}/seed');
      final listData = JsonUtils.extractList(response.data['data']);
      final integrations = listData
          .map((item) => Integration.fromJson(item))
          .toList();
      return ApiResponse<List<Integration>>(
        success: response.data['ok'] == true || response.statusCode == 201,
        statusCode: response.statusCode ?? 201,
        message: response.data['message']?.toString() ?? 'Default integrations seeded',
        data: integrations,
      );
    } catch (e) {
      return _errorResponse<List<Integration>>(e);
    }
  }

  // #175: GET /api/integration/v1/:organizationId
  Future<ApiResponse<List<Integration>>> getIntegrations(
    String organizationId,
  ) async {
    try {
      final response = await _dio.get(_basePath(organizationId));
      final listData = JsonUtils.extractList(response.data['data']);
      final integrations = listData
          .map((item) => Integration.fromJson(item))
          .toList();
      return ApiResponse<List<Integration>>(
        success: response.data['ok'] == true || response.statusCode == 200,
        statusCode: response.statusCode ?? 200,
        message: response.data['message']?.toString() ?? 'Integrations loaded',
        data: integrations,
      );
    } catch (e) {
      return _errorResponse<List<Integration>>(e);
    }
  }

  // #176: GET /api/integration/v1/:organizationId/:id
  Future<ApiResponse<Integration>> getIntegrationById(
    String organizationId,
    String id,
  ) async {
    try {
      final response = await _dio.get('${_basePath(organizationId)}/$id');
      final mapData = JsonUtils.extractMap(response.data['data']);
      return ApiResponse<Integration>(
        success: response.data['ok'] == true || response.statusCode == 200,
        statusCode: response.statusCode ?? 200,
        message: response.data['message']?.toString() ?? 'Integration loaded',
        data: Integration.fromJson(mapData),
      );
    } catch (e) {
      return _errorResponse<Integration>(e);
    }
  }

  // #177: PATCH /api/integration/v1/:organizationId/:id/connect
  Future<ApiResponse<Integration>> connect(
    String organizationId,
    String id,
  ) async {
    try {
      final response = await _dio.patch('${_basePath(organizationId)}/$id/connect');
      final mapData = JsonUtils.extractMap(response.data['data']);
      return ApiResponse<Integration>(
        success: response.data['ok'] == true || response.statusCode == 200,
        statusCode: response.statusCode ?? 200,
        message: response.data['message']?.toString() ?? 'Integration connected',
        data: Integration.fromJson(mapData),
      );
    } catch (e) {
      return _errorResponse<Integration>(e);
    }
  }

  // #178: PATCH /api/integration/v1/:organizationId/:id/disconnect
  Future<ApiResponse<Integration>> disconnect(
    String organizationId,
    String id,
  ) async {
    try {
      final response =
          await _dio.patch('${_basePath(organizationId)}/$id/disconnect');
      final mapData = JsonUtils.extractMap(response.data['data']);
      return ApiResponse<Integration>(
        success: response.data['ok'] == true || response.statusCode == 200,
        statusCode: response.statusCode ?? 200,
        message: response.data['message']?.toString() ?? 'Integration disconnected',
        data: Integration.fromJson(mapData),
      );
    } catch (e) {
      return _errorResponse<Integration>(e);
    }
  }
}
