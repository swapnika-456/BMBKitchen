import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_exceptions.dart';
import '../../core/network/api_response.dart';
import '../../core/network/dio_client.dart';
import '../../core/network/json_utils.dart';
import '../../models/menu_category.dart';

final menuCategoryApiProvider = Provider<MenuCategoryApiService>((ref) {
  final dio = ref.watch(dioProvider);
  return MenuCategoryApiService(dio);
});

class MenuCategoryApiService {
  final Dio _dio;
  final String _basePath = '/api/menu-category/v1';

  MenuCategoryApiService(this._dio);

  // #15: GET /:organizationId/dropdown
  Future<ApiResponse<List<MenuCategory>>> getDropdown(String orgId) async {
    try {
      final res = await _dio.get('$_basePath/$orgId/dropdown');
      final listData = JsonUtils.extractList(res.data['data']);
      final list = listData
          .whereType<Map<String, dynamic>>()
          .map((e) => MenuCategory.fromJson(e))
          .toList();
      return ApiResponse<List<MenuCategory>>(
        success: true,
        statusCode: res.statusCode ?? 200,
        message: res.data['message'] ?? '',
        data: list,
      );
    } catch (e) {
      if (e is DioException && e.response != null) {
        final resData = e.response!.data;
        if (resData is Map && resData['message'] != null) {
          return ApiResponse(
            success: false,
            statusCode: e.response!.statusCode ?? 500,
            message: resData['message'].toString(),
          );
        }
        return ApiResponse(
          success: false,
          statusCode: e.response!.statusCode ?? 500,
          message: resData.toString(),
        );
      }
      return ApiResponse(
        success: false,
        statusCode: 500,
        message: e.toString(),
      );
    }
  }

  // #16: GET /:organizationId/inactive
  Future<ApiResponse<List<MenuCategory>>> getInactive(String orgId) async {
    try {
      final res = await _dio.get('$_basePath/$orgId/inactive');
      final listData = JsonUtils.extractList(res.data['data']);
      final list = listData
          .whereType<Map<String, dynamic>>()
          .map((e) => MenuCategory.fromJson(e))
          .toList();
      return ApiResponse<List<MenuCategory>>(
        success: true,
        statusCode: res.statusCode ?? 200,
        message: res.data['message'] ?? '',
        data: list,
      );
    } catch (e) {
      if (e is DioException && e.response != null) {
        final resData = e.response!.data;
        if (resData is Map && resData['message'] != null) {
          return ApiResponse(
            success: false,
            statusCode: e.response!.statusCode ?? 500,
            message: resData['message'].toString(),
          );
        }
        return ApiResponse(
          success: false,
          statusCode: e.response!.statusCode ?? 500,
          message: resData.toString(),
        );
      }
      return ApiResponse(
        success: false,
        statusCode: 500,
        message: e.toString(),
      );
    }
  }

  // #17: POST /:organizationId
  Future<ApiResponse<MenuCategory>> create(
    String orgId, {
    required String name,
    String? description,
  }) async {
    try {
      final res = await _dio.post(
        '$_basePath/$orgId',
        data: {
          'name': name,
          if (description != null) 'description': description,
        },
      );
      final mapData = JsonUtils.extractMap(res.data['data']);
      final cat = MenuCategory.fromJson(mapData);
      return ApiResponse<MenuCategory>(
        success: true,
        statusCode: res.statusCode ?? 201,
        message: res.data['message'] ?? '',
        data: cat,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        statusCode: 500,
        message: e.toString(),
      );
    }
  }

  // #18: GET /:organizationId
  Future<ApiResponse<List<MenuCategory>>> getActive(String orgId) async {
    try {
      final res = await _dio.get('$_basePath/$orgId');
      final listData = JsonUtils.extractList(res.data['data']);
      final list = listData
          .whereType<Map<String, dynamic>>()
          .map((e) => MenuCategory.fromJson(e))
          .toList();
      return ApiResponse<List<MenuCategory>>(
        success: true,
        statusCode: res.statusCode ?? 200,
        message: res.data['message'] ?? '',
        data: list,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        statusCode: 500,
        message: e.toString(),
      );
    }
  }

  // #19: PATCH /:organizationId/:id/recover
  Future<ApiResponse<void>> recover(String orgId, String categoryId) async {
    try {
      final res = await _dio.patch('$_basePath/$orgId/$categoryId/recover');
      return ApiResponse<void>(
        success: true,
        statusCode: res.statusCode ?? 200,
        message: res.data['message'] ?? '',
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        statusCode: 500,
        message: e.toString(),
      );
    }
  }

  // #20: GET /:organizationId/:id
  Future<ApiResponse<MenuCategory>> getOne(
    String orgId,
    String categoryId,
  ) async {
    try {
      final res = await _dio.get('$_basePath/$orgId/$categoryId');
      final mapData = JsonUtils.extractMap(res.data['data']);
      final cat = MenuCategory.fromJson(mapData);
      return ApiResponse<MenuCategory>(
        success: true,
        statusCode: res.statusCode ?? 200,
        message: res.data['message'] ?? '',
        data: cat,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        statusCode: 500,
        message: e.toString(),
      );
    }
  }

  // #21: PUT /:organizationId/:id
  Future<ApiResponse<MenuCategory>> update(
    String orgId,
    String categoryId, {
    String? name,
    String? description,
  }) async {
    try {
      final res = await _dio.put(
        '$_basePath/$orgId/$categoryId',
        data: {
          if (name != null) 'name': name,
          if (description != null) 'description': description,
        },
      );
      final mapData = JsonUtils.extractMap(res.data['data']);
      final cat = MenuCategory.fromJson(mapData);
      return ApiResponse<MenuCategory>(
        success: true,
        statusCode: res.statusCode ?? 200,
        message: res.data['message'] ?? '',
        data: cat,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        statusCode: 500,
        message: e.toString(),
      );
    }
  }

  // #22: PATCH /:organizationId/:id
  Future<ApiResponse<void>> deactivate(String orgId, String categoryId) async {
    try {
      final res = await _dio.patch('$_basePath/$orgId/$categoryId');
      return ApiResponse<void>(
        success: true,
        statusCode: res.statusCode ?? 200,
        message: res.data['message'] ?? '',
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        statusCode: 500,
        message: e.toString(),
      );
    }
  }

  // #23: DELETE /:organizationId/:id
  Future<ApiResponse<void>> hardDelete(String orgId, String categoryId) async {
    try {
      final res = await _dio.delete('$_basePath/$orgId/$categoryId');
      return ApiResponse<void>(
        success: true,
        statusCode: res.statusCode ?? 200,
        message: res.data['message'] ?? '',
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        statusCode: 500,
        message: e.toString(),
      );
    }
  }
}
