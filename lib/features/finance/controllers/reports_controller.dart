import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/report_models.dart';
import '../../../services/api/report_api_service.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../settings/controllers/active_outlet_provider.dart';

class ReportsFilter {
  final String scope; // 'today' | 'week' | 'month' | 'year' | 'custom'
  final String? outletId; // null or 'all' = all outlets
  final DateTime? customFrom;
  final DateTime? customTo;
  final String? expenseCategory;
  final int selectedTab; // 0: Sales, 1: Items, 2: Payments, 3: GST, 4: Expenses
  final int gstPage;
  final int gstLimit;

  const ReportsFilter({
    this.scope = 'today',
    this.outletId,
    this.customFrom,
    this.customTo,
    this.expenseCategory,
    this.selectedTab = 0,
    this.gstPage = 1,
    this.gstLimit = 50,
  });

  String? get fromFormatted {
    if (scope == 'custom' && customFrom != null) {
      return '${customFrom!.year}-${customFrom!.month.toString().padLeft(2, '0')}-${customFrom!.day.toString().padLeft(2, '0')}';
    }
    return null;
  }

  String? get toFormatted {
    if (scope == 'custom' && customTo != null) {
      return '${customTo!.year}-${customTo!.month.toString().padLeft(2, '0')}-${customTo!.day.toString().padLeft(2, '0')}';
    }
    return null;
  }

  ReportsFilter copyWith({
    String? scope,
    String? outletId,
    bool clearOutletId = false,
    DateTime? customFrom,
    DateTime? customTo,
    String? expenseCategory,
    bool clearExpenseCategory = false,
    int? selectedTab,
    int? gstPage,
    int? gstLimit,
  }) {
    return ReportsFilter(
      scope: scope ?? this.scope,
      outletId: clearOutletId ? null : (outletId ?? this.outletId),
      customFrom: customFrom ?? this.customFrom,
      customTo: customTo ?? this.customTo,
      expenseCategory: clearExpenseCategory
          ? null
          : (expenseCategory ?? this.expenseCategory),
      selectedTab: selectedTab ?? this.selectedTab,
      gstPage: gstPage ?? this.gstPage,
      gstLimit: gstLimit ?? this.gstLimit,
    );
  }
}

class ReportsState {
  final ReportsFilter filter;
  final bool isLoading;
  final String? errorMessage;
  final SalesReportData? salesReport;
  final ItemsReportData? itemsReport;
  final ExpensesReportData? expensesReport;
  final PaymentsSummaryReportData? paymentsReport;
  final GstSummaryReportData? gstReport;

  const ReportsState({
    this.filter = const ReportsFilter(),
    this.isLoading = false,
    this.errorMessage,
    this.salesReport,
    this.itemsReport,
    this.expensesReport,
    this.paymentsReport,
    this.gstReport,
  });

  ReportsState copyWith({
    ReportsFilter? filter,
    bool? isLoading,
    String? errorMessage,
    bool clearErrorMessage = false,
    SalesReportData? salesReport,
    ItemsReportData? itemsReport,
    ExpensesReportData? expensesReport,
    PaymentsSummaryReportData? paymentsReport,
    GstSummaryReportData? gstReport,
  }) {
    return ReportsState(
      filter: filter ?? this.filter,
      isLoading: isLoading ?? this.isLoading,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      salesReport: salesReport ?? this.salesReport,
      itemsReport: itemsReport ?? this.itemsReport,
      expensesReport: expensesReport ?? this.expensesReport,
      paymentsReport: paymentsReport ?? this.paymentsReport,
      gstReport: gstReport ?? this.gstReport,
    );
  }
}

final reportsControllerProvider =
    AsyncNotifierProvider<ReportsController, ReportsState>(
  ReportsController.new,
);

class ReportsController extends AsyncNotifier<ReportsState> {
  String? _getOrgId() {
    final user = ref.read(authControllerProvider).value;
    if (user == null) return null;
    return user.organizationId.isNotEmpty ? user.organizationId : null;
  }

  bool _isAllowedRole() {
    final user = ref.read(authControllerProvider).value;
    final role = user?.role.toLowerCase() ?? '';
    return role == 'owner' || role == 'admin' || role == 'cto';
  }

  @override
  FutureOr<ReportsState> build() async {
    final orgId = _getOrgId();
    if (orgId == null || !_isAllowedRole()) {
      return const ReportsState();
    }

    // Default to active outlet or all
    final activeOutlet = ref.read(activeOutletProvider);
    final initialFilter = ReportsFilter(
      outletId: activeOutlet?.id,
      scope: 'today',
    );

    return _fetchReportForTab(initialFilter, 0, currentReports: const ReportsState());
  }

  Future<ReportsState> _fetchReportForTab(
    ReportsFilter filter,
    int tab, {
    required ReportsState currentReports,
  }) async {
    final orgId = _getOrgId();
    if (orgId == null || !_isAllowedRole()) {
      return currentReports.copyWith(filter: filter, isLoading: false);
    }

    final api = ref.read(reportApiServiceProvider);
    final outlet = filter.outletId;
    final scope = filter.scope;
    final from = filter.fromFormatted;
    final to = filter.toFormatted;

    var updated = currentReports.copyWith(
      filter: filter,
      isLoading: false,
      clearErrorMessage: true,
    );

    switch (tab) {
      case 0: // Sales
        final res = await api.getSales(
          orgId,
          outletId: outlet,
          scope: scope,
          from: from,
          to: to,
        );
        if (res.success && res.data != null) {
          updated = updated.copyWith(salesReport: res.data);
        } else {
          updated = updated.copyWith(errorMessage: res.message);
        }
        break;

      case 1: // Items
        final res = await api.getItems(
          orgId,
          outletId: outlet,
          scope: scope,
          from: from,
          to: to,
        );
        if (res.success && res.data != null) {
          updated = updated.copyWith(itemsReport: res.data);
        } else {
          updated = updated.copyWith(errorMessage: res.message);
        }
        break;

      case 2: // Payments summary
        final res = await api.getPaymentsSummary(
          orgId,
          outletId: outlet,
          scope: scope,
          from: from,
          to: to,
        );
        if (res.success && res.data != null) {
          updated = updated.copyWith(paymentsReport: res.data);
        } else {
          updated = updated.copyWith(errorMessage: res.message);
        }
        break;

      case 3: // GST summary
        final res = await api.getGstSummary(
          orgId,
          outletId: outlet,
          scope: scope,
          from: from,
          to: to,
          page: filter.gstPage,
          limit: filter.gstLimit,
        );
        if (res.success && res.data != null) {
          updated = updated.copyWith(gstReport: res.data);
        } else {
          updated = updated.copyWith(errorMessage: res.message);
        }
        break;

      case 4: // Expenses
        final res = await api.getExpenses(
          orgId,
          outletId: outlet,
          scope: scope,
          from: from,
          to: to,
          category: filter.expenseCategory,
        );
        if (res.success && res.data != null) {
          updated = updated.copyWith(expensesReport: res.data);
        } else {
          updated = updated.copyWith(errorMessage: res.message);
        }
        break;
    }

    return updated;
  }

  Future<void> setTab(int tab) async {
    final current = state.value ?? const ReportsState();
    final newFilter = current.filter.copyWith(selectedTab: tab);
    state = AsyncData(current.copyWith(filter: newFilter, isLoading: true));

    final updated = await _fetchReportForTab(newFilter, tab, currentReports: current);
    state = AsyncData(updated);
  }

  Future<void> setScope(String scope) async {
    final current = state.value ?? const ReportsState();
    final newFilter = current.filter.copyWith(scope: scope);
    state = AsyncData(current.copyWith(filter: newFilter, isLoading: true));

    final updated = await _fetchReportForTab(
      newFilter,
      newFilter.selectedTab,
      currentReports: current,
    );
    state = AsyncData(updated);
  }

  Future<void> setCustomDateRange(DateTime from, DateTime to) async {
    final current = state.value ?? const ReportsState();
    final newFilter = current.filter.copyWith(
      scope: 'custom',
      customFrom: from,
      customTo: to,
    );
    state = AsyncData(current.copyWith(filter: newFilter, isLoading: true));

    final updated = await _fetchReportForTab(
      newFilter,
      newFilter.selectedTab,
      currentReports: current,
    );
    state = AsyncData(updated);
  }

  Future<void> setOutlet(String? outletId) async {
    final current = state.value ?? const ReportsState();
    final newFilter = current.filter.copyWith(
      outletId: outletId,
      clearOutletId: outletId == null || outletId == 'all',
    );
    state = AsyncData(current.copyWith(filter: newFilter, isLoading: true));

    final updated = await _fetchReportForTab(
      newFilter,
      newFilter.selectedTab,
      currentReports: current,
    );
    state = AsyncData(updated);
  }

  Future<void> setExpenseCategory(String? category) async {
    final current = state.value ?? const ReportsState();
    final newFilter = current.filter.copyWith(
      expenseCategory: category,
      clearExpenseCategory: category == null || category == 'all',
    );
    state = AsyncData(current.copyWith(filter: newFilter, isLoading: true));

    final updated = await _fetchReportForTab(newFilter, 4, currentReports: current);
    state = AsyncData(updated);
  }

  Future<void> setGstPage(int page) async {
    final current = state.value ?? const ReportsState();
    final newFilter = current.filter.copyWith(gstPage: page);
    state = AsyncData(current.copyWith(filter: newFilter, isLoading: true));

    final updated = await _fetchReportForTab(newFilter, 3, currentReports: current);
    state = AsyncData(updated);
  }

  Future<void> refresh() async {
    final current = state.value ?? const ReportsState();
    state = AsyncData(current.copyWith(isLoading: true));

    final updated = await _fetchReportForTab(
      current.filter,
      current.filter.selectedTab,
      currentReports: current,
    );
    state = AsyncData(updated);
  }
}
