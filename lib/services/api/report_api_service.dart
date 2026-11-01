import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_exceptions.dart';
import '../../core/network/api_response.dart';
import '../../core/network/dio_client.dart';
import '../../core/network/json_utils.dart';
import '../../models/report_models.dart';

final reportApiServiceProvider = Provider<ReportApiService>((ref) {
  final dio = ref.watch(dioProvider);
  return ReportApiService(dio);
});

/// Report API Service covering endpoints #154 to #158
/// Base: /api/report/v1/:organizationId
class ReportApiService {
  final Dio _dio;

  ReportApiService(this._dio);

  String _basePath(String organizationId) => '/api/report/v1/$organizationId';

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

  Map<String, dynamic> _cleanQuery({
    String? outletId,
    String? scope,
    String? from,
    String? to,
    String? category,
    int? page,
    int? limit,
  }) {
    final query = <String, dynamic>{};
    if (outletId != null && outletId.isNotEmpty && outletId != 'all') {
      query['outletId'] = outletId;
    }
    if (scope != null && scope.isNotEmpty) {
      query['scope'] = scope;
    }
    if (from != null && from.isNotEmpty) {
      query['from'] = from;
    }
    if (to != null && to.isNotEmpty) {
      query['to'] = to;
    }
    if (category != null && category.isNotEmpty && category != 'all') {
      query['category'] = category;
    }
    if (page != null && page > 0) {
      query['page'] = page;
    }
    if (limit != null && limit > 0) {
      query['limit'] = limit;
    }
    return query;
  }

  // #154: GET /api/report/v1/:organizationId/sales
  Future<ApiResponse<SalesReportData>> getSales(
    String organizationId, {
    String? outletId,
    String? scope,
    String? from,
    String? to,
  }) async {
    try {
      final query = _cleanQuery(
        outletId: outletId,
        scope: scope,
        from: from,
        to: to,
      );
      final response = await _dio.get(
        '${_basePath(organizationId)}/sales',
        queryParameters: query,
      );
      final mapData = JsonUtils.extractMap(response.data['data']);
      return ApiResponse<SalesReportData>(
        success: response.data['ok'] == true || response.statusCode == 200,
        statusCode: response.statusCode ?? 200,
        message: response.data['message']?.toString() ?? 'Sales report loaded',
        data: SalesReportData.fromJson(mapData),
      );
    } catch (e) {
      return _errorResponse<SalesReportData>(e);
    }
  }

  // #155: GET /api/report/v1/:organizationId/items
  Future<ApiResponse<ItemsReportData>> getItems(
    String organizationId, {
    String? outletId,
    String? scope,
    String? from,
    String? to,
  }) async {
    try {
      final query = _cleanQuery(
        outletId: outletId,
        scope: scope,
        from: from,
        to: to,
      );
      final response = await _dio.get(
        '${_basePath(organizationId)}/items',
        queryParameters: query,
      );
      final mapData = JsonUtils.extractMap(response.data['data']);
      return ApiResponse<ItemsReportData>(
        success: response.data['ok'] == true || response.statusCode == 200,
        statusCode: response.statusCode ?? 200,
        message: response.data['message']?.toString() ?? 'Items report loaded',
        data: ItemsReportData.fromJson(mapData),
      );
    } catch (e) {
      return _errorResponse<ItemsReportData>(e);
    }
  }

  // #156: GET /api/report/v1/:organizationId/expenses
  Future<ApiResponse<ExpensesReportData>> getExpenses(
    String organizationId, {
    String? outletId,
    String? scope,
    String? from,
    String? to,
    String? category,
  }) async {
    try {
      final query = _cleanQuery(
        outletId: outletId,
        scope: scope,
        from: from,
        to: to,
        category: category,
      );
      final response = await _dio.get(
        '${_basePath(organizationId)}/expenses',
        queryParameters: query,
      );
      final mapData = JsonUtils.extractMap(response.data['data']);
      return ApiResponse<ExpensesReportData>(
        success: response.data['ok'] == true || response.statusCode == 200,
        statusCode: response.statusCode ?? 200,
        message: response.data['message']?.toString() ?? 'Expenses report loaded',
        data: ExpensesReportData.fromJson(mapData),
      );
    } catch (e) {
      return _errorResponse<ExpensesReportData>(e);
    }
  }

  // #157: GET /api/report/v1/:organizationId/payments-summary
  Future<ApiResponse<PaymentsSummaryReportData>> getPaymentsSummary(
    String organizationId, {
    String? outletId,
    String? scope,
    String? from,
    String? to,
  }) async {
    try {
      final query = _cleanQuery(
        outletId: outletId,
        scope: scope,
        from: from,
        to: to,
      );
      final response = await _dio.get(
        '${_basePath(organizationId)}/payments-summary',
        queryParameters: query,
      );
      final mapData = JsonUtils.extractMap(response.data['data']);
      return ApiResponse<PaymentsSummaryReportData>(
        success: response.data['ok'] == true || response.statusCode == 200,
        statusCode: response.statusCode ?? 200,
        message: response.data['message']?.toString() ?? 'Payments summary loaded',
        data: PaymentsSummaryReportData.fromJson(mapData),
      );
    } catch (e) {
      return _errorResponse<PaymentsSummaryReportData>(e);
    }
  }

  // #158: GET /api/report/v1/:organizationId/gst-summary
  Future<ApiResponse<GstSummaryReportData>> getGstSummary(
    String organizationId, {
    String? outletId,
    String? scope,
    String? from,
    String? to,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final query = _cleanQuery(
        outletId: outletId,
        scope: scope,
        from: from,
        to: to,
        page: page,
        limit: limit,
      );
      final response = await _dio.get(
        '${_basePath(organizationId)}/gst-summary',
        queryParameters: query,
      );
      final mapData = JsonUtils.extractMap(response.data['data']);
      return ApiResponse<GstSummaryReportData>(
        success: response.data['ok'] == true || response.statusCode == 200,
        statusCode: response.statusCode ?? 200,
        message: response.data['message']?.toString() ?? 'GST summary loaded',
        data: GstSummaryReportData.fromJson(mapData),
      );
    } catch (e) {
      return _errorResponse<GstSummaryReportData>(e);
    }
  }
}
