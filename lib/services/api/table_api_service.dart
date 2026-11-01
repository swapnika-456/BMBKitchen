import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_response.dart';
import '../../core/network/dio_client.dart';
import '../../core/network/json_utils.dart';
import '../../models/restaurant_table.dart';

final tableApiProvider = Provider<TableApiService>((ref) {
  final dio = ref.watch(dioProvider);
  return TableApiService(dio);
});

class TableApiService {
  final Dio _dio;
  final String _basePath = '/api/table/v1';

  TableApiService(this._dio);

  // #33 GET /dropdown
  Future<ApiResponse<List<RestaurantTable>>> getDropdown(
    String orgId, {
    String? outletId,
  }) async {
    return _getList('$_basePath/$orgId/dropdown', outletId: outletId);
  }

  // #34 GET /inactive
  Future<ApiResponse<List<RestaurantTable>>> getInactive(
    String orgId, {
    String? outletId,
  }) async {
    return _getList('$_basePath/$orgId/inactive', outletId: outletId);
  }

  // #36 GET / (Active)
  Future<ApiResponse<List<RestaurantTable>>> getActive(
    String orgId, {
    String? outletId,
  }) async {
    return _getList('$_basePath/$orgId', outletId: outletId);
  }

  Future<ApiResponse<List<RestaurantTable>>> _getList(
    String url, {
    String? outletId,
  }) async {
    try {
      final queryParams = outletId != null ? {'outletId': outletId} : null;
      final res = await _dio.get(url, queryParameters: queryParams);
      final listData = JsonUtils.extractList(res.data['data']);
      final list = listData
          .whereType<Map<String, dynamic>>()
          .map((e) => RestaurantTable.fromJson(e))
          .toList();
      return ApiResponse<List<RestaurantTable>>(
        success: true,
        statusCode: res.statusCode ?? 200,
        message: res.data['message'] ?? '',
        data: list,
      );
    } catch (e) {
      return _handleError(e);
    }
  }

  // #40 GET /:id
  Future<ApiResponse<RestaurantTable>> getTable(
    String orgId,
    String tableId,
  ) async {
    try {
      final res = await _dio.get('$_basePath/$orgId/$tableId');
      final mapData = JsonUtils.extractMap(res.data['data']);
      return ApiResponse<RestaurantTable>(
        success: true,
        statusCode: res.statusCode ?? 200,
        message: res.data['message'] ?? '',
        data: RestaurantTable.fromJson(mapData),
      );
    } catch (e) {
      return _handleError(e);
    }
  }

  // #35 POST /
  Future<ApiResponse<RestaurantTable>> create(
    String orgId,
    Map<String, dynamic> data,
  ) async {
    try {
      final res = await _dio.post('$_basePath/$orgId', data: data);
      final mapData = JsonUtils.extractMap(res.data['data']);
      return ApiResponse<RestaurantTable>(
        success: true,
        statusCode: res.statusCode ?? 201,
        message: res.data['message'] ?? '',
        data: RestaurantTable.fromJson(mapData),
      );
    } catch (e) {
      return _handleError(e);
    }
  }

  // #41 PUT /:id
  Future<ApiResponse<RestaurantTable>> update(
    String orgId,
    String tableId,
    Map<String, dynamic> data,
  ) async {
    try {
      final res = await _dio.put('$_basePath/$orgId/$tableId', data: data);
      final mapData = JsonUtils.extractMap(res.data['data']);
      return ApiResponse<RestaurantTable>(
        success: true,
        statusCode: res.statusCode ?? 200,
        message: res.data['message'] ?? '',
        data: RestaurantTable.fromJson(mapData),
      );
    } catch (e) {
      return _handleError(e);
    }
  }

  // #37 PATCH /:id/status
  Future<ApiResponse<RestaurantTable>> updateStatus(
    String orgId,
    String tableId,
    String status,
  ) async {
    try {
      final res = await _dio.patch(
        '$_basePath/$orgId/$tableId/status',
        data: {'status': status},
      );
      final mapData = JsonUtils.extractMap(res.data['data']);
      return ApiResponse<RestaurantTable>(
        success: true,
        statusCode: res.statusCode ?? 200,
        message: res.data['message'] ?? '',
        data: RestaurantTable.fromJson(mapData),
      );
    } catch (e) {
      return _handleError(e);
    }
  }

  // #38 PATCH /:id/reserve
  Future<ApiResponse<RestaurantTable>> reserve(
    String orgId,
    String tableId,
    Map<String, dynamic> data,
  ) async {
    try {
      final res = await _dio.patch(
        '$_basePath/$orgId/$tableId/reserve',
        data: data,
      );
      final mapData = JsonUtils.extractMap(res.data['data']);
      return ApiResponse<RestaurantTable>(
        success: true,
        statusCode: res.statusCode ?? 200,
        message: res.data['message'] ?? '',
        data: RestaurantTable.fromJson(mapData),
      );
    } catch (e) {
      return _handleError(e);
    }
  }

  // #42 PATCH /:id (Deactivate)
  Future<ApiResponse<void>> deactivate(String orgId, String tableId) async {
    try {
      final res = await _dio.patch('$_basePath/$orgId/$tableId');
      return ApiResponse<void>(
        success: true,
        statusCode: res.statusCode ?? 200,
        message: res.data['message'] ?? '',
      );
    } catch (e) {
      return _handleError(e);
    }
  }

  // #39 PATCH /:id/recover
  Future<ApiResponse<void>> recover(String orgId, String tableId) async {
    try {
      final res = await _dio.patch('$_basePath/$orgId/$tableId/recover');
      return ApiResponse<void>(
        success: true,
        statusCode: res.statusCode ?? 200,
        message: res.data['message'] ?? '',
      );
    } catch (e) {
      return _handleError(e);
    }
  }

  // #43 DELETE /:id
  Future<ApiResponse<void>> delete(String orgId, String tableId) async {
    try {
      final res = await _dio.delete('$_basePath/$orgId/$tableId');
      return ApiResponse<void>(
        success: true,
        statusCode: res.statusCode ?? 200,
        message: res.data['message'] ?? '',
      );
    } catch (e) {
      return _handleError(e);
    }
  }

  ApiResponse<T> _handleError<T>(dynamic e) {
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
    return ApiResponse(success: false, statusCode: 500, message: e.toString());
  }
}
