import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_response.dart';
import '../../../models/integration.dart';
import '../../../services/api/integration_api_service.dart';
import '../../auth/controllers/auth_controller.dart';

class IntegrationState {
  final List<Integration> integrations;
  final bool isSeeding;
  final String? actionLoadingId;
  final String? errorMessage;
  final String? successMessage;

  const IntegrationState({
    this.integrations = const [],
    this.isSeeding = false,
    this.actionLoadingId,
    this.errorMessage,
    this.successMessage,
  });

  int get connectedCount => integrations.where((i) => i.isConnected).length;
  int get totalCount => integrations.length;

  /// Returns integrations grouped by category according to standard PDF categories order
  Map<String, List<Integration>> get groupedByCategory {
    const predefinedOrder = [
      'Aggregator',
      'Payments',
      'Messaging',
      'Accounting',
      'Reputation',
    ];

    final map = <String, List<Integration>>{};
    for (final cat in predefinedOrder) {
      final items = integrations.where((i) => i.category == cat).toList();
      if (items.isNotEmpty) {
        map[cat] = items;
      }
    }

    // Include any other categories not in predefined list
    for (final item in integrations) {
      if (!predefinedOrder.contains(item.category)) {
        map.putIfAbsent(item.category, () => []).add(item);
      }
    }

    return map;
  }

  IntegrationState copyWith({
    List<Integration>? integrations,
    bool? isSeeding,
    String? actionLoadingId,
    bool clearActionLoadingId = false,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? successMessage,
    bool clearSuccessMessage = false,
  }) {
    return IntegrationState(
      integrations: integrations ?? this.integrations,
      isSeeding: isSeeding ?? this.isSeeding,
      actionLoadingId: clearActionLoadingId
          ? null
          : (actionLoadingId ?? this.actionLoadingId),
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccessMessage
          ? null
          : (successMessage ?? this.successMessage),
    );
  }
}

final integrationControllerProvider =
    AsyncNotifierProvider<IntegrationController, IntegrationState>(
  IntegrationController.new,
);

class IntegrationController extends AsyncNotifier<IntegrationState> {
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

  void clearErrorMessage() {
    final current = state.value;
    if (current != null) {
      state = AsyncData(current.copyWith(clearErrorMessage: true));
    }
  }

  void clearSuccessMessage() {
    final current = state.value;
    if (current != null) {
      state = AsyncData(current.copyWith(clearSuccessMessage: true));
    }
  }

  @override
  FutureOr<IntegrationState> build() async {
    final orgId = _getOrgId();
    if (orgId == null || !_isAllowedRole()) {
      return const IntegrationState();
    }

    final api = ref.read(integrationApiServiceProvider);
    final res = await api.getIntegrations(orgId);

    if (!res.success) {
      return IntegrationState(errorMessage: res.message);
    }

    return IntegrationState(integrations: res.data ?? []);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final orgId = _getOrgId();
      if (orgId == null || !_isAllowedRole()) {
        return const IntegrationState();
      }

      final api = ref.read(integrationApiServiceProvider);
      final res = await api.getIntegrations(orgId);

      if (!res.success) {
        return IntegrationState(errorMessage: res.message);
      }

      return IntegrationState(integrations: res.data ?? []);
    });
  }

  /// Calls POST #174 seed defaults exactly once. Never auto-retries.
  Future<ApiResponse<List<Integration>>> seedDefaults() async {
    final current = state.value ?? const IntegrationState();
    if (current.isSeeding) {
      return ApiResponse(
        success: false,
        statusCode: 400,
        message: 'Setup is already in progress',
      );
    }

    final orgId = _getOrgId();
    if (orgId == null || !_isAllowedRole()) {
      return ApiResponse(
        success: false,
        statusCode: 403,
        message: 'Only Owner, Admin, or CTO can set up default integrations',
      );
    }

    state = AsyncData(current.copyWith(isSeeding: true, clearErrorMessage: true));

    final api = ref.read(integrationApiServiceProvider);
    final res = await api.seedDefaults(orgId);

    if (res.success && res.data != null) {
      state = AsyncData(current.copyWith(
        integrations: res.data!,
        isSeeding: false,
        successMessage: 'Default integrations configured successfully',
        clearErrorMessage: true,
      ));
    } else {
      state = AsyncData(current.copyWith(
        isSeeding: false,
        errorMessage: res.message.isNotEmpty
            ? res.message
            : 'Failed to seed default integrations',
      ));
    }

    return res;
  }

  /// Connects an integration (#177)
  Future<ApiResponse<Integration>> connect(String integrationId) async {
    final current = state.value ?? const IntegrationState();
    final orgId = _getOrgId();
    if (orgId == null || !_isAllowedRole()) {
      return ApiResponse(
        success: false,
        statusCode: 403,
        message: 'Only Owner, Admin, or CTO can manage integrations',
      );
    }

    state = AsyncData(current.copyWith(
      actionLoadingId: integrationId,
      clearErrorMessage: true,
      clearSuccessMessage: true,
    ));

    final api = ref.read(integrationApiServiceProvider);
    final res = await api.connect(orgId, integrationId);

    if (res.success && res.data != null) {
      final updatedList = current.integrations.map((item) {
        if (item.id == integrationId) {
          return res.data!;
        }
        return item;
      }).toList();

      state = AsyncData(current.copyWith(
        integrations: updatedList,
        clearActionLoadingId: true,
        successMessage: '${res.data!.name} marked as connected',
        clearErrorMessage: true,
      ));
    } else {
      state = AsyncData(current.copyWith(
        clearActionLoadingId: true,
        errorMessage: res.message.isNotEmpty
            ? res.message
            : 'Failed to connect integration',
      ));
    }

    return res;
  }

  /// Disconnects an integration (#178)
  Future<ApiResponse<Integration>> disconnect(String integrationId) async {
    final current = state.value ?? const IntegrationState();
    final orgId = _getOrgId();
    if (orgId == null || !_isAllowedRole()) {
      return ApiResponse(
        success: false,
        statusCode: 403,
        message: 'Only Owner, Admin, or CTO can manage integrations',
      );
    }

    state = AsyncData(current.copyWith(
      actionLoadingId: integrationId,
      clearErrorMessage: true,
      clearSuccessMessage: true,
    ));

    final api = ref.read(integrationApiServiceProvider);
    final res = await api.disconnect(orgId, integrationId);

    if (res.success && res.data != null) {
      final updatedList = current.integrations.map((item) {
        if (item.id == integrationId) {
          return res.data!;
        }
        return item;
      }).toList();

      state = AsyncData(current.copyWith(
        integrations: updatedList,
        clearActionLoadingId: true,
        successMessage: '${res.data!.name} marked as disconnected',
        clearErrorMessage: true,
      ));
    } else {
      state = AsyncData(current.copyWith(
        clearActionLoadingId: true,
        errorMessage: res.message.isNotEmpty
            ? res.message
            : 'Failed to disconnect integration',
      ));
    }

    return res;
  }
}
