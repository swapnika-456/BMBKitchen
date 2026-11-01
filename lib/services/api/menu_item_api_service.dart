import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_response.dart';
import '../../core/network/dio_client.dart';
import '../../core/network/json_utils.dart';
import '../../models/models.dart'; // Ensure MenuItem is available

final menuItemApiProvider = Provider<MenuItemApiService>((ref) {
  final dio = ref.watch(dioProvider);
  return MenuItemApiService(dio);
});

class MenuItemApiService {
  final Dio _dio;
  final String _basePath = '/api/menu-item/v1';

  MenuItemApiService(this._dio);

  // #27: GET /:organizationId
  Future<ApiResponse<List<MenuItem>>> getActive(String orgId) async {
    try {
      final res = await _dio.get('$_basePath/$orgId');
      final listData = JsonUtils.extractList(res.data['data']);
      final list = listData
          .whereType<Map<String, dynamic>>()
          .map((e) => MenuItem.fromJson(e))
          .toList();
      return ApiResponse<List<MenuItem>>(
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

  // #25: GET /:organizationId/inactive
  Future<ApiResponse<List<MenuItem>>> getInactive(String orgId) async {
    try {
      final res = await _dio.get('$_basePath/$orgId/inactive');
      final listData = JsonUtils.extractList(res.data['data']);
      final list = listData
          .whereType<Map<String, dynamic>>()
          .map((e) => MenuItem.fromJson(e))
          .toList();
      return ApiResponse<List<MenuItem>>(
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

  static String normalizeFoodType(dynamic val) {
    if (val == null) return 'Veg';
    final s = val.toString().trim().toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
    if (s.contains('nonveg') || s.contains('nonvegetarian')) {
      return 'Non-veg';
    } else if (s.contains('egg')) {
      return 'Egg';
    }
    return 'Veg';
  }

  // POST /:organizationId
  Future<ApiResponse<MenuItem>> create(
    String orgId,
    Map<String, dynamic> data, {
    List<MultipartFile>? files,
  }) async {
    try {
      final sanitizedData = Map<String, dynamic>.from(data);
      // Ensure foodType is always present and strictly normalized
      if (!sanitizedData.containsKey('foodType') ||
          sanitizedData['foodType'] == null ||
          sanitizedData['foodType'].toString().trim().isEmpty) {
        sanitizedData['foodType'] = 'Veg';
      } else {
        sanitizedData['foodType'] = normalizeFoodType(sanitizedData['foodType']);
      }

      dynamic requestData = sanitizedData;
      if (files != null && files.isNotEmpty) {
        final map = <String, dynamic>{};
        sanitizedData.forEach((key, value) {
          if (value is List || value is Map) {
            map[key] = jsonEncode(value);
          } else {
            map[key] = value.toString();
          }
        });
        map['files'] = files;
        requestData = FormData.fromMap(map);
      }

      final res = await _dio.post('$_basePath/$orgId', data: requestData);
      final mapData = JsonUtils.extractMap(res.data['data']);
      final item = MenuItem.fromJson(mapData);
      return ApiResponse<MenuItem>(
        success: true,
        statusCode: res.statusCode ?? 201,
        message: res.data['message'] ?? '',
        data: item,
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

  // PUT /:organizationId/:id
  Future<ApiResponse<MenuItem>> update(
    String orgId,
    String itemId,
    Map<String, dynamic> data,
  ) async {
    try {
      final sanitizedData = Map<String, dynamic>.from(data);
      if (sanitizedData.containsKey('foodType') && sanitizedData['foodType'] != null) {
        sanitizedData['foodType'] = normalizeFoodType(sanitizedData['foodType']);
      }

      final res = await _dio.put('$_basePath/$orgId/$itemId', data: sanitizedData);
      final mapData = JsonUtils.extractMap(res.data['data']);
      final item = MenuItem.fromJson(mapData);
      return ApiResponse<MenuItem>(
        success: true,
        statusCode: res.statusCode ?? 200,
        message: res.data['message'] ?? '',
        data: item,
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

  // #31: PATCH /:organizationId/:id
  Future<ApiResponse<void>> deactivate(String orgId, String itemId) async {
    try {
      final res = await _dio.patch('$_basePath/$orgId/$itemId');
      return ApiResponse<void>(
        success: true,
        statusCode: res.statusCode ?? 200,
        message: res.data['message'] ?? '',
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

  // #28: PATCH /:organizationId/:id/recover
  Future<ApiResponse<void>> recover(String orgId, String itemId) async {
    try {
      final res = await _dio.patch('$_basePath/$orgId/$itemId/recover');
      return ApiResponse<void>(
        success: true,
        statusCode: res.statusCode ?? 200,
        message: res.data['message'] ?? '',
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

  // #32: DELETE /:organizationId/:id
  Future<ApiResponse<void>> hardDelete(String orgId, String itemId) async {
    try {
      final res = await _dio.delete('$_basePath/$orgId/$itemId');
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

  // #32A: POST /:organizationId/:menuItemId/images
  Future<ApiResponse<void>> uploadImages(
    String orgId,
    String itemId,
    List<MultipartFile> files,
  ) async {
    try {
      final formData = FormData.fromMap({'files': files});
      debugPrint('BMB_LOG: === FULL UPLOAD REQUEST ===');
      debugPrint('BMB_LOG: URL: $_basePath/$orgId/$itemId/images');
      debugPrint('BMB_LOG: METHOD: POST');
      debugPrint('BMB_LOG: Default Headers: ${_dio.options.headers}');

      final res = await _dio.post(
        '$_basePath/$orgId/$itemId/images',
        data: formData,
      );
      return ApiResponse<void>(
        success: true,
        statusCode: res.statusCode ?? 200,
        message: res.data['message'] ?? '',
      );
    } catch (e) {
      if (e is DioException && e.response != null) {
        final resData = e.response!.data;
        debugPrint(
          'BMB_LOG: [UPLOAD IMAGE ERROR] ${e.response?.statusCode} - $resData',
        );
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
      debugPrint('BMB_LOG: [UPLOAD IMAGE ERROR] $e');
      return ApiResponse(
        success: false,
        statusCode: 500,
        message: e.toString(),
      );
    }
  }

  // #32B: DELETE /:organizationId/:menuItemId/images/:imageId
  Future<ApiResponse<void>> deleteImage(
    String orgId,
    String itemId,
    String imageId,
  ) async {
    try {
      debugPrint('BMB_LOG: === FULL DELETE REQUEST ===');
      debugPrint('BMB_LOG: URL: $_basePath/$orgId/$itemId/images/$imageId');
      debugPrint('BMB_LOG: METHOD: DELETE');
      debugPrint('BMB_LOG: Default Headers: ${_dio.options.headers}');
      final res = await _dio.delete(
        '$_basePath/$orgId/$itemId/images/$imageId',
      );
      return ApiResponse<void>(
        success: true,
        statusCode: res.statusCode ?? 200,
        message: res.data['message'] ?? '',
      );
    } catch (e) {
      if (e is DioException && e.response != null) {
        final resData = e.response!.data;
        debugPrint(
          'BMB_LOG: [DELETE IMAGE ERROR] ${e.response?.statusCode} - $resData',
        );
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
      debugPrint('BMB_LOG: [DELETE IMAGE ERROR] $e');
      return ApiResponse(
        success: false,
        statusCode: 500,
        message: e.toString(),
      );
    }
  }
}
