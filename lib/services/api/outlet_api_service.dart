import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_exceptions.dart';
import '../../core/network/api_response.dart';
import '../../core/network/dio_client.dart';
import '../../core/network/json_utils.dart';

final outletApiServiceProvider = Provider<OutletApiService>((ref) {
  final dio = ref.watch(dioProvider);
  return OutletApiService(dio);
});

class OutletApiService {
  final Dio _dio;

  OutletApiService(this._dio);

  Future<ApiResponse<Map<String, dynamic>>> createOutlet(
    String organizationId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.post(
        '/api/outlet/v1/$organizationId',
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

  Future<ApiResponse<List<dynamic>>> getActiveOutlets(
    String organizationId,
  ) async {
    try {
      final response = await _dio.get('/api/outlet/v1/$organizationId');
      return ApiResponse(
        success: true,
        statusCode: 200,
        message: 'Success',
        data: JsonUtils.extractList(response.data['data']),
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        statusCode: e is DioException ? e.response?.statusCode ?? 0 : 0,
        message: ApiExceptions.getDetailedErrorMessage(e),
        data: [],
      );
    }
  }

  Future<ApiResponse<List<dynamic>>> getInactiveOutlets(
    String organizationId,
  ) async {
    try {
      final response = await _dio.get(
        '/api/outlet/v1/$organizationId/inactive',
      );
      return ApiResponse(
        success: true,
        statusCode: 200,
        message: 'Success',
        data: JsonUtils.extractList(response.data['data']),
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        statusCode: e is DioException ? e.response?.statusCode ?? 0 : 0,
        message: ApiExceptions.getDetailedErrorMessage(e),
        data: [],
      );
    }
  }

  Future<ApiResponse<List<dynamic>>> getOutletDropdown(
    String organizationId,
  ) async {
    try {
      final response = await _dio.get(
        '/api/outlet/v1/$organizationId/dropdown',
      );
      return ApiResponse(
        success: true,
        statusCode: 200,
        message: 'Success',
        data: JsonUtils.extractList(response.data['data']),
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        statusCode: e is DioException ? e.response?.statusCode ?? 0 : 0,
        message: ApiExceptions.getDetailedErrorMessage(e),
        data: [],
      );
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> getOutletById(
    String organizationId,
    String id,
  ) async {
    try {
      final response = await _dio.get('/api/outlet/v1/$organizationId/$id');
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

  Future<ApiResponse<Map<String, dynamic>>> updateOutlet(
    String organizationId,
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.patch(
        '/api/outlet/v1/$organizationId/$id',
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

  Future<ApiResponse<Map<String, dynamic>>> deactivateOutlet(
    String organizationId,
    String id,
  ) async {
    try {
      final response = await _dio.patch(
        '/api/outlet/v1/$organizationId/$id/deactivate',
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

  Future<ApiResponse<Map<String, dynamic>>> restoreOutlet(
    String organizationId,
    String id,
  ) async {
    try {
      final response = await _dio.patch(
        '/api/outlet/v1/$organizationId/$id/restore',
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

  Future<ApiResponse<Map<String, dynamic>>> deleteOutlet(
    String organizationId,
    String id,
  ) async {
    try {
      final response = await _dio.delete('/api/outlet/v1/$organizationId/$id');
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
