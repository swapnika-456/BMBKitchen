import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_exceptions.dart';
import '../../core/network/api_response.dart';
import '../../core/network/dio_client.dart';
import '../../core/network/json_utils.dart';
import '../../models/dashboard_models.dart';

final dashboardApiServiceProvider = Provider<DashboardApiService>((ref) {
  final dio = ref.watch(dioProvider);
  return DashboardApiService(dio);
});

/// Dashboard API Service covering endpoints #159 to #165
/// Base: /api/dashboard/v1/:organizationId/:outletId
class DashboardApiService {
  final Dio _dio;

  DashboardApiService(this._dio);

  String _basePath(String organizationId, String outletId) =>
      '/api/dashboard/v1/$organizationId/$outletId';

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
    String? scope,
    String? from,
    String? to,
    int? limit,
  }) {
    final query = <String, dynamic>{};
    if (scope != null && scope.isNotEmpty) {
      query['scope'] = scope;
    }
    if (from != null && from.isNotEmpty) {
      query['from'] = from;
    }
    if (to != null && to.isNotEmpty) {
      query['to'] = to;
    }
    if (limit != null && limit > 0) {
      query['limit'] = limit;
    }
    return query;
  }

  /// #159 GET /summary
  /// Complete dashboard in one request: sales KPIs, hourly sales,
  /// kitchen ticket status, top-selling items, payment summary, quick stats.
  Future<ApiResponse<DashboardSummaryData>> getSummary(
    String organizationId,
    String outletId, {
    String? scope,
    String? from,
    String? to,
    int? limit,
  }) async {
    try {
      final res = await _dio.get(
        '${_basePath(organizationId, outletId)}/summary',
        queryParameters: _cleanQuery(
          scope: scope,
          from: from,
          to: to,
          limit: limit,
        ),
      );
      final dataMap = JsonUtils.extractMap(res.data['data']);
      return ApiResponse<DashboardSummaryData>(
        success: true,
        statusCode: res.statusCode ?? 200,
        data: DashboardSummaryData.fromJson(dataMap),
        message: res.data['message']?.toString() ?? '',
      );
    } catch (e) {
      return _errorResponse<DashboardSummaryData>(e);
    }
  }

  /// #160 GET /sales-kpis
  Future<ApiResponse<DashboardSalesKpis>> getSalesKpis(
    String organizationId,
    String outletId, {
    String? scope,
    String? from,
    String? to,
  }) async {
    try {
      final res = await _dio.get(
        '${_basePath(organizationId, outletId)}/sales-kpis',
        queryParameters: _cleanQuery(scope: scope, from: from, to: to),
      );
      final dataMap = JsonUtils.extractMap(res.data['data']);
      return ApiResponse<DashboardSalesKpis>(
        success: true,
        statusCode: res.statusCode ?? 200,
        data: DashboardSalesKpis.fromJson(dataMap),
        message: res.data['message']?.toString() ?? '',
      );
    } catch (e) {
      return _errorResponse<DashboardSalesKpis>(e);
    }
  }

  /// #161 GET /sales-by-trend
  Future<ApiResponse<DashboardSalesTrend>> getSalesByTrend(
    String organizationId,
    String outletId, {
    String? scope,
    String? from,
    String? to,
  }) async {
    try {
      final res = await _dio.get(
        '${_basePath(organizationId, outletId)}/sales-by-trend',
        queryParameters: _cleanQuery(scope: scope, from: from, to: to),
      );
      final dataMap = JsonUtils.extractMap(res.data['data']);
      return ApiResponse<DashboardSalesTrend>(
        success: true,
        statusCode: res.statusCode ?? 200,
        data: DashboardSalesTrend.fromJson(dataMap),
        message: res.data['message']?.toString() ?? '',
      );
    } catch (e) {
      return _errorResponse<DashboardSalesTrend>(e);
    }
  }

  /// #162 GET /kitchen-ticket-status
  Future<ApiResponse<DashboardKitchenTicketStatus>> getKitchenTicketStatus(
    String organizationId,
    String outletId, {
    String? scope,
    String? from,
    String? to,
  }) async {
    try {
      final res = await _dio.get(
        '${_basePath(organizationId, outletId)}/kitchen-ticket-status',
        queryParameters: _cleanQuery(scope: scope, from: from, to: to),
      );
      final dataMap = JsonUtils.extractMap(res.data['data']);
      return ApiResponse<DashboardKitchenTicketStatus>(
        success: true,
        statusCode: res.statusCode ?? 200,
        data: DashboardKitchenTicketStatus.fromJson(dataMap),
        message: res.data['message']?.toString() ?? '',
      );
    } catch (e) {
      return _errorResponse<DashboardKitchenTicketStatus>(e);
    }
  }

  /// #163 GET /top-selling-items
  Future<ApiResponse<DashboardTopSellingItems>> getTopSellingItems(
    String organizationId,
    String outletId, {
    String? scope,
    String? from,
    String? to,
    int? limit,
  }) async {
    try {
      final res = await _dio.get(
        '${_basePath(organizationId, outletId)}/top-selling-items',
        queryParameters: _cleanQuery(
          scope: scope,
          from: from,
          to: to,
          limit: limit,
        ),
      );
      final dataMap = JsonUtils.extractMap(res.data['data']);
      return ApiResponse<DashboardTopSellingItems>(
        success: true,
        statusCode: res.statusCode ?? 200,
        data: DashboardTopSellingItems.fromJson(dataMap),
        message: res.data['message']?.toString() ?? '',
      );
    } catch (e) {
      return _errorResponse<DashboardTopSellingItems>(e);
    }
  }

  /// #164 GET /payment-summary
  Future<ApiResponse<DashboardPaymentSummary>> getPaymentSummary(
    String organizationId,
    String outletId, {
    String? scope,
    String? from,
    String? to,
  }) async {
    try {
      final res = await _dio.get(
        '${_basePath(organizationId, outletId)}/payment-summary',
        queryParameters: _cleanQuery(scope: scope, from: from, to: to),
      );
      final dataMap = JsonUtils.extractMap(res.data['data']);
      return ApiResponse<DashboardPaymentSummary>(
        success: true,
        statusCode: res.statusCode ?? 200,
        data: DashboardPaymentSummary.fromJson(dataMap),
        message: res.data['message']?.toString() ?? '',
      );
    } catch (e) {
      return _errorResponse<DashboardPaymentSummary>(e);
    }
  }

  /// #165 GET /quick-stats
  Future<ApiResponse<DashboardQuickStats>> getQuickStats(
    String organizationId,
    String outletId, {
    String? scope,
    String? from,
    String? to,
  }) async {
    try {
      final res = await _dio.get(
        '${_basePath(organizationId, outletId)}/quick-stats',
        queryParameters: _cleanQuery(scope: scope, from: from, to: to),
      );
      final dataMap = JsonUtils.extractMap(res.data['data']);
      return ApiResponse<DashboardQuickStats>(
        success: true,
        statusCode: res.statusCode ?? 200,
        data: DashboardQuickStats.fromJson(dataMap),
        message: res.data['message']?.toString() ?? '',
      );
    } catch (e) {
      return _errorResponse<DashboardQuickStats>(e);
    }
  }
}
