import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/dio_client.dart';
import '../../core/network/api_response.dart';
import '../../core/network/api_exceptions.dart';

final organizationApiServiceProvider = Provider<OrganizationApiService>((ref) {
  final dio = ref.watch(dioProvider);
  return OrganizationApiService(dio);
});

class OrganizationApiService {
  final Dio _dio;

  OrganizationApiService(this._dio);

  Future<ApiResponse<Map<String, dynamic>>> register(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.post(
        '/api/organization/v1/register',
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

  Future<ApiResponse<List<dynamic>>> getOrganizations() async {
    try {
      final response = await _dio.get('/api/organization/v1/');
      if (response.statusCode == 200) {
        final data = response.data['data'];
        if (data is List) {
          return ApiResponse(
            success: true,
            statusCode: 200,
            message: 'Success',
            data: data,
          );
        } else if (data is Map) {
          return ApiResponse(
            success: true,
            statusCode: 200,
            message: 'Success',
            data: [data],
          );
        }
      }
      return ApiResponse(
        success: false,
        statusCode: response.statusCode ?? 400,
        message: response.data['message'] ?? 'Failed to get organizations',
        data: [],
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

  Future<ApiResponse<Map<String, dynamic>>> getOrganizationById(
    String id,
  ) async {
    try {
      final response = await _dio.get('/api/organization/v1/$id');
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

  Future<ApiResponse<Map<String, dynamic>>> updateOrganization(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.patch('/api/organization/v1/$id', data: data);
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

  Future<ApiResponse<Map<String, dynamic>>> deleteOrganization(
    String id,
  ) async {
    try {
      final response = await _dio.delete('/api/organization/v1/$id');
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
