import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/dio_client.dart';
import '../../core/network/api_response.dart';
import '../../core/network/json_utils.dart';
import '../../models/inventory_item.dart';

final inventoryApiServiceProvider = Provider<InventoryApiService>((ref) {
  final dio = ref.watch(dioProvider);
  return InventoryApiService(dio);
});

class InventoryApiService {
  final Dio _dio;

  InventoryApiService(this._dio);

  String _base(String orgId) => '/api/inventory/v1/$orgId';
  String _item(String orgId, String id) => '${_base(orgId)}/$id';

  // #52 GET /
  Future<ApiResponse<List<InventoryItem>>> getActiveInventory(String orgId) async {
    try {
      final res = await _dio.get(_base(orgId));
      final listData = JsonUtils.extractList(res.data['data'] ?? res.data);
      final list = listData.whereType<Map<String, dynamic>>().map((e) => InventoryItem.fromJson(e)).toList();
      return ApiResponse<List<InventoryItem>>(
        success: true,
        statusCode: res.statusCode ?? 200,
        message: res.data['message'] ?? '',
        data: list,
      );
    } catch (e) {
      return _errorResponse<List<InventoryItem>>(e);
    }
  }

  // #54 GET /dropdown
  Future<ApiResponse<List<InventoryDropdownItem>>> getDropdown(String orgId) async {
    try {
      final res = await _dio.get('${_base(orgId)}/dropdown');
      final listData = JsonUtils.extractList(res.data['data'] ?? res.data);
      final list = listData.whereType<Map<String, dynamic>>().map((e) => InventoryDropdownItem.fromJson(e)).toList();
      return ApiResponse<List<InventoryDropdownItem>>(
        success: true,
        statusCode: res.statusCode ?? 200,
        message: res.data['message'] ?? '',
        data: list,
      );
    } catch (e) {
      return _errorResponse<List<InventoryDropdownItem>>(e);
    }
  }

  // #55 GET /inactive
  Future<ApiResponse<List<InventoryItem>>> getInactiveInventory(String orgId) async {
    try {
      final res = await _dio.get('${_base(orgId)}/inactive');
      final listData = JsonUtils.extractList(res.data['data'] ?? res.data);
      final list = listData.whereType<Map<String, dynamic>>().map((e) => InventoryItem.fromJson(e)).toList();
      return ApiResponse<List<InventoryItem>>(
        success: true,
        statusCode: res.statusCode ?? 200,
        message: res.data['message'] ?? '',
        data: list,
      );
    } catch (e) {
      return _errorResponse<List<InventoryItem>>(e);
    }
  }

  // #56 GET /:inventoryId
  Future<ApiResponse<InventoryItem>> getInventoryItem(String orgId, String id) async {
    try {
      final res = await _dio.get(_item(orgId, id));
      final itemData = JsonUtils.extractMap(res.data['data'] ?? res.data);
      return ApiResponse<InventoryItem>(
        success: true,
        statusCode: res.statusCode ?? 200,
        message: res.data['message'] ?? '',
        data: InventoryItem.fromJson(itemData),
      );
    } catch (e) {
      return _errorResponse<InventoryItem>(e);
    }
  }

  // #53 POST /
  Future<ApiResponse<InventoryItem>> createInventory(String orgId, Map<String, dynamic> data) async {
    try {
      dynamic requestData;
      if (data.containsKey('file') && data['file'] != null) {
        requestData = FormData.fromMap({
          ...data,
          'file': data['file'], // Ensure it's a MultipartFile
        });
      } else {
        requestData = data;
      }

      final res = await _dio.post(_base(orgId), data: requestData);
      final itemData = JsonUtils.extractMap(res.data['data'] ?? res.data);
      return ApiResponse<InventoryItem>(
        success: true,
        statusCode: res.statusCode ?? 201,
        message: res.data['message'] ?? '',
        data: InventoryItem.fromJson(itemData),
      );
    } catch (e) {
      return _errorResponse<InventoryItem>(e);
    }
  }

  // #57 PUT /:inventoryId
  Future<ApiResponse<InventoryItem>> updateInventory(String orgId, String id, Map<String, dynamic> data) async {
    try {
      final res = await _dio.put(_item(orgId, id), data: data);
      final itemData = JsonUtils.extractMap(res.data['data'] ?? res.data);
      return ApiResponse<InventoryItem>(
        success: true,
        statusCode: res.statusCode ?? 200,
        message: res.data['message'] ?? '',
        data: InventoryItem.fromJson(itemData),
      );
    } catch (e) {
      return _errorResponse<InventoryItem>(e);
    }
  }

  // #53A PUT /:inventoryId/image
  Future<ApiResponse<void>> addImage(String orgId, String id, MultipartFile file) async {
    try {
      final formData = FormData.fromMap({'file': file});
      final res = await _dio.put('${_item(orgId, id)}/image', data: formData);
      return ApiResponse<void>(
        success: true,
        statusCode: res.statusCode ?? 200,
        message: res.data['message'] ?? '',
      );
    } catch (e) {
      return _errorResponse<void>(e);
    }
  }

  // #53B DELETE /:inventoryId/image
  Future<ApiResponse<void>> deleteImage(String orgId, String id, [String? imageId]) async {
    try {
      final res = await _dio.delete('${_item(orgId, id)}/image');
      return ApiResponse<void>(
        success: true,
        statusCode: res.statusCode ?? 200,
        message: res.data['message'] ?? '',
      );
    } catch (e) {
      if (imageId != null && imageId.isNotEmpty) {
        try {
          final res2 = await _dio.delete('${_item(orgId, id)}/images/$imageId');
          return ApiResponse<void>(
            success: true,
            statusCode: res2.statusCode ?? 200,
            message: res2.data['message'] ?? '',
          );
        } catch (_) {}
      }
      return _errorResponse<void>(e);
    }
  }

  // #58 POST /:inventoryId/adjust
  Future<ApiResponse<InventoryItem>> adjustStock(String orgId, String id, Map<String, dynamic> data) async {
    try {
      final res = await _dio.post('${_item(orgId, id)}/adjust', data: data);
      final itemData = JsonUtils.extractMap(res.data['data'] ?? res.data);
      return ApiResponse<InventoryItem>(
        success: true,
        statusCode: res.statusCode ?? 200,
        message: res.data['message'] ?? '',
        data: InventoryItem.fromJson(itemData),
      );
    } catch (e) {
      return _errorResponse<InventoryItem>(e);
    }
  }

  // #59 PATCH /:inventoryId/restore
  Future<ApiResponse<InventoryItem>> restoreInventory(String orgId, String id) async {
    try {
      final res = await _dio.patch('${_item(orgId, id)}/restore');
      final itemData = JsonUtils.extractMap(res.data['data'] ?? res.data);
      return ApiResponse<InventoryItem>(
        success: true,
        statusCode: res.statusCode ?? 200,
        message: res.data['message'] ?? '',
        data: InventoryItem.fromJson(itemData),
      );
    } catch (e) {
      return _errorResponse<InventoryItem>(e);
    }
  }

  // #60 DELETE /:inventoryId
  Future<ApiResponse<InventoryItem>> deactivateInventory(String orgId, String id) async {
    try {
      final res = await _dio.delete(_item(orgId, id));
      final itemData = JsonUtils.extractMap(res.data['data'] ?? res.data);
      return ApiResponse<InventoryItem>(
        success: true,
        statusCode: res.statusCode ?? 200,
        message: res.data['message'] ?? '',
        data: InventoryItem.fromJson(itemData),
      );
    } catch (e) {
      return _errorResponse<InventoryItem>(e);
    }
  }

  // #61 DELETE /:inventoryId/hard
  Future<ApiResponse<void>> deleteInventoryHard(String orgId, String id) async {
    try {
      final res = await _dio.delete('${_item(orgId, id)}/hard');
      return ApiResponse<void>(
        success: true,
        statusCode: res.statusCode ?? 200,
        message: res.data['message'] ?? '',
      );
    } catch (e) {
      return _errorResponse<void>(e);
    }
  }

  ApiResponse<T> _errorResponse<T>(dynamic e) {
    if (e is DioException && e.response != null) {
      final resData = e.response!.data;
      if (resData is Map && resData['message'] != null) {
        return ApiResponse(
          success: false,
          statusCode: e.response!.statusCode ?? 500,
          message: resData['message'],
        );
      }
    }
    return ApiResponse(
      success: false,
      statusCode: 500,
      message: e.toString(),
    );
  }
}
