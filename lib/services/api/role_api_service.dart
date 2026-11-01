import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_exceptions.dart';
import '../../core/network/api_response.dart';
import '../../core/network/dio_client.dart';
import '../../core/network/json_utils.dart';

final roleApiServiceProvider = Provider<RoleApiService>((ref) {
  final dio = ref.watch(dioProvider);
  return RoleApiService(dio);
});

class RoleApiService {
  final Dio _dio;

  RoleApiService(this._dio);

  Future<ApiResponse<Map<String, dynamic>>> createRole(
    String organizationId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.post(
        '/api/role/v1/$organizationId',
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

  Future<ApiResponse<List<dynamic>>> getActiveRoles(
    String organizationId,
  ) async {
    try {
      final response = await _dio.get('/api/role/v1/$organizationId');
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

  Future<ApiResponse<List<dynamic>>> getInactiveRoles(
    String organizationId,
  ) async {
    try {
      final response = await _dio.get('/api/role/v1/$organizationId/inactive');
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

  Future<ApiResponse<List<dynamic>>> getRoleDropdown(
    String organizationId,
  ) async {
    try {
      final response = await _dio.get('/api/role/v1/$organizationId/dropdown');
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

  Future<ApiResponse<Map<String, dynamic>>> getRoleById(
    String organizationId,
    String id,
  ) async {
    try {
      final response = await _dio.get('/api/role/v1/$organizationId/$id');
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

  Future<ApiResponse<Map<String, dynamic>>> updateRole(
    String organizationId,
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.patch(
        '/api/role/v1/$organizationId/$id',
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

  Future<ApiResponse<Map<String, dynamic>>> deactivateRole(
    String organizationId,
    String id,
  ) async {
    try {
      final response = await _dio.patch(
        '/api/role/v1/$organizationId/$id/deactivate',
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

  Future<ApiResponse<Map<String, dynamic>>> restoreRole(
    String organizationId,
    String id,
  ) async {
    try {
      final response = await _dio.patch(
        '/api/role/v1/$organizationId/$id/restore',
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

  Future<ApiResponse<Map<String, dynamic>>> deleteRole(
    String organizationId,
    String id,
  ) async {
    try {
      final response = await _dio.delete('/api/role/v1/$organizationId/$id');
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
