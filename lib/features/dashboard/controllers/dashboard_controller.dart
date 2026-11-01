import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../models/dashboard_models.dart';
import '../../../services/api/dashboard_api_service.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../settings/controllers/active_outlet_provider.dart';

class DashboardFilter {
  final String scope; // 'today', 'week', 'month', 'year', 'custom'
  final String? from;
  final String? to;

  const DashboardFilter({
    this.scope = 'today',
    this.from,
    this.to,
  });

  DashboardFilter copyWith({
    String? scope,
    String? from,
    String? to,
  }) {
    return DashboardFilter(
      scope: scope ?? this.scope,
      from: from ?? this.from,
      to: to ?? this.to,
    );
  }
}

class DashboardState {
  final DashboardFilter filter;
  final DashboardSummaryData? summary;
  final bool isLoading;
  final String? errorMessage;

  const DashboardState({
    this.filter = const DashboardFilter(),
    this.summary,
    this.isLoading = false,
    this.errorMessage,
  });

  DashboardState copyWith({
    DashboardFilter? filter,
    DashboardSummaryData? summary,
    bool? isLoading,
    String? errorMessage,
  }) {
    return DashboardState(
      filter: filter ?? this.filter,
      summary: summary ?? this.summary,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

final dashboardControllerProvider =
    AsyncNotifierProvider<DashboardController, DashboardState>(
  DashboardController.new,
);

class DashboardController extends AsyncNotifier<DashboardState> {
  String? _getOrgId() {
    final user = ref.read(authControllerProvider).value;
    if (user == null) return null;
    return user.organizationId.isNotEmpty ? user.organizationId : null;
  }

  String? _getOutletId() {
    final outlet = ref.read(activeOutletProvider);
    return outlet?.id;
  }

  @override
  FutureOr<DashboardState> build() async {
    final orgId = _getOrgId();
    final outletId = _getOutletId();

    if (orgId == null || outletId == null) {
      return const DashboardState();
    }

    return _fetchSummary(const DashboardFilter());
  }

  Future<DashboardState> _fetchSummary(DashboardFilter filter) async {
    final orgId = _getOrgId();
    final outletId = _getOutletId();

    if (orgId == null || outletId == null) {
      return DashboardState(
        filter: filter,
        errorMessage: 'No active outlet selected',
      );
    }

    final api = ref.read(dashboardApiServiceProvider);
    final res = await api.getSummary(
      orgId,
      outletId,
      scope: filter.scope,
      from: filter.from,
      to: filter.to,
    );

    if (res.success && res.data != null) {
      return DashboardState(
        filter: filter,
        summary: res.data,
        isLoading: false,
      );
    } else {
      return DashboardState(
        filter: filter,
        summary: state.value?.summary,
        isLoading: false,
        errorMessage: res.message.isNotEmpty
            ? res.message
            : 'Failed to load dashboard summary',
      );
    }
  }

  Future<void> refresh() async {
    final current = state.value ?? const DashboardState();
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return _fetchSummary(current.filter);
    });
  }

  Future<void> setScope(String scope) async {
    final current = state.value ?? const DashboardState();
    if (current.filter.scope == scope && scope != 'custom') return;

    final newFilter = current.filter.copyWith(scope: scope);
    state = AsyncValue.data(current.copyWith(filter: newFilter, isLoading: true));

    final updated = await _fetchSummary(newFilter);
    state = AsyncValue.data(updated);
  }

  Future<void> setCustomDateRange(DateTime from, DateTime to) async {
    final current = state.value ?? const DashboardState();
    final fmt = DateFormat('yyyy-MM-dd');
    final fromStr = fmt.format(from);
    final toStr = fmt.format(to);

    final newFilter = DashboardFilter(
      scope: 'custom',
      from: fromStr,
      to: toStr,
    );

    state = AsyncValue.data(current.copyWith(filter: newFilter, isLoading: true));
    final updated = await _fetchSummary(newFilter);
    state = AsyncValue.data(updated);
  }
}
