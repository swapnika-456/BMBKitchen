import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_response.dart';
import '../../core/network/dio_client.dart';
import '../../core/network/json_utils.dart';
import '../../models/vendor.dart';

final vendorApiProvider = Provider<VendorApiService>((ref) {
  final dio = ref.watch(dioProvider);
  return VendorApiService(dio);
});

class VendorApiService {
  final Dio _dio;
  final String _basePath = '/api/vendor/v1';

  VendorApiService(this._dio);

  // #62: GET /:organizationId
  Future<ApiResponse<List<Vendor>>> getActive(String orgId) async {
    try {
      final res = await _dio.get('$_basePath/$orgId');
      final listData = JsonUtils.extractList(res.data['data'] ?? res.data);
      final list = listData
          .whereType<Map<String, dynamic>>()
          .map((e) => Vendor.fromJson(e))
          .toList();
      return ApiResponse<List<Vendor>>(
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

  // #63: POST /:organizationId
  Future<ApiResponse<Vendor>> create(
    String orgId,
    Map<String, dynamic> data,
  ) async {
    try {
      final res = await _dio.post('$_basePath/$orgId', data: data);
      final mapData = JsonUtils.extractMap(res.data['data'] ?? res.data);
      final vendor = Vendor.fromJson(mapData);
      return ApiResponse<Vendor>(
        success: true,
        statusCode: res.statusCode ?? 201,
        message: res.data['message'] ?? 'Vendor created successfully',
        data: vendor,
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

  // #64: GET /:organizationId/dropdown
  Future<ApiResponse<List<Vendor>>> getDropdown(String orgId) async {
    try {
      final res = await _dio.get('$_basePath/$orgId/dropdown');
      final listData = JsonUtils.extractList(res.data['data'] ?? res.data);
      final list = listData
          .whereType<Map<String, dynamic>>()
          .map((e) => Vendor.fromJson(e))
          .toList();
      return ApiResponse<List<Vendor>>(
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

  // #65: GET /:organizationId/inactive
  Future<ApiResponse<List<Vendor>>> getInactive(String orgId) async {
    try {
      final res = await _dio.get('$_basePath/$orgId/inactive');
      final listData = JsonUtils.extractList(res.data['data'] ?? res.data);
      final list = listData
          .whereType<Map<String, dynamic>>()
          .map((e) => Vendor.fromJson(e))
          .toList();
      return ApiResponse<List<Vendor>>(
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

  // #66: GET /:organizationId/:vendorId
  Future<ApiResponse<Vendor>> getById(String orgId, String vendorId) async {
    try {
      final res = await _dio.get('$_basePath/$orgId/$vendorId');
      final mapData = JsonUtils.extractMap(res.data['data'] ?? res.data);
      final vendor = Vendor.fromJson(mapData);
      return ApiResponse<Vendor>(
        success: true,
        statusCode: res.statusCode ?? 200,
        message: res.data['message'] ?? '',
        data: vendor,
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

  // #67: PUT /:organizationId/:vendorId
  Future<ApiResponse<Vendor>> update(
    String orgId,
    String vendorId,
    Map<String, dynamic> data,
  ) async {
    try {
      final res = await _dio.put('$_basePath/$orgId/$vendorId', data: data);
      final mapData = JsonUtils.extractMap(res.data['data'] ?? res.data);
      final vendor = Vendor.fromJson(mapData);
      return ApiResponse<Vendor>(
        success: true,
        statusCode: res.statusCode ?? 200,
        message: res.data['message'] ?? 'Vendor updated successfully',
        data: vendor,
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

  // #68: PATCH /:organizationId/:vendorId/restore
  Future<ApiResponse<void>> restore(String orgId, String vendorId) async {
    try {
      final res = await _dio.patch('$_basePath/$orgId/$vendorId/restore');
      return ApiResponse<void>(
        success: true,
        statusCode: res.statusCode ?? 200,
        message: res.data['message'] ?? 'Vendor restored successfully',
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

  // #69: DELETE /:organizationId/:vendorId (Soft Delete)
  Future<ApiResponse<void>> softDelete(String orgId, String vendorId) async {
    try {
      final res = await _dio.delete('$_basePath/$orgId/$vendorId');
      return ApiResponse<void>(
        success: true,
        statusCode: res.statusCode ?? 200,
        message: res.data['message'] ?? 'Vendor deleted successfully',
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

  // #70: DELETE /:organizationId/:vendorId/hard (Hard Delete)
  Future<ApiResponse<void>> hardDelete(String orgId, String vendorId) async {
    try {
      final res = await _dio.delete('$_basePath/$orgId/$vendorId/hard');
      return ApiResponse<void>(
        success: true,
        statusCode: res.statusCode ?? 200,
        message: res.data['message'] ?? 'Vendor permanently deleted',
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
}
