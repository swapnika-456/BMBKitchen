import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/restaurant_table.dart';
import '../../../services/api/table_api_service.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../settings/controllers/active_outlet_provider.dart';

final activeTablesProvider =
    AsyncNotifierProvider<ActiveTablesNotifier, List<RestaurantTable>>(() {
      return ActiveTablesNotifier();
    });

class ActiveTablesNotifier extends AsyncNotifier<List<RestaurantTable>> {
  @override
  Future<List<RestaurantTable>> build() async {
    return _fetchTables();
  }

  Future<List<RestaurantTable>> _fetchTables() async {
    final user = ref.read(authControllerProvider).value;
    final orgId = user?.organizationId ?? '';
    final activeOutletId = ref.watch(activeOutletProvider)?.id;
    if (orgId.isEmpty || activeOutletId == null) return [];

    final api = ref.read(tableApiProvider);
    final res = await api.getActive(orgId, outletId: activeOutletId);
    if (!res.success) {
      throw Exception(res.message);
    }
    return res.data ?? [];
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchTables());
  }

  Future<bool> createTable(Map<String, dynamic> data) async {
    final user = ref.read(authControllerProvider).value;
    final orgId = user?.organizationId ?? '';
    if (orgId.isEmpty) return false;
    final api = ref.read(tableApiProvider);
    final res = await api.create(orgId, data);
    if (res.success) {
      ref.invalidateSelf();
      return true;
    }
    return false;
  }

  Future<bool> updateTable(String tableId, Map<String, dynamic> data) async {
    final user = ref.read(authControllerProvider).value;
    final orgId = user?.organizationId ?? '';
    if (orgId.isEmpty) return false;
    final api = ref.read(tableApiProvider);
    final res = await api.update(orgId, tableId, data);
    if (res.success) {
      ref.invalidateSelf();
      return true;
    }
    return false;
  }

  Future<bool> updateStatus(String tableId, String status) async {
    final user = ref.read(authControllerProvider).value;
    final orgId = user?.organizationId ?? '';
    if (orgId.isEmpty) return false;
    final api = ref.read(tableApiProvider);
    final res = await api.updateStatus(orgId, tableId, status);
    if (res.success) {
      ref.invalidateSelf();
      return true;
    }
    return false;
  }

  Future<bool> reserveTable(String tableId, Map<String, dynamic> data) async {
    final user = ref.read(authControllerProvider).value;
    final orgId = user?.organizationId ?? '';
    if (orgId.isEmpty) return false;
    final api = ref.read(tableApiProvider);
    final res = await api.reserve(orgId, tableId, data);
    if (res.success) {
      ref.invalidateSelf();
      return true;
    }
    return false;
  }

  Future<bool> deactivateTable(String tableId) async {
    final user = ref.read(authControllerProvider).value;
    final orgId = user?.organizationId ?? '';
    if (orgId.isEmpty) return false;
    final api = ref.read(tableApiProvider);
    final res = await api.deactivate(orgId, tableId);
    if (res.success) {
      ref.invalidateSelf();
      ref.invalidate(inactiveTablesProvider);
      return true;
    }
    return false;
  }
}

final inactiveTablesProvider =
    AsyncNotifierProvider<InactiveTablesNotifier, List<RestaurantTable>>(() {
      return InactiveTablesNotifier();
    });

class InactiveTablesNotifier extends AsyncNotifier<List<RestaurantTable>> {
  @override
  Future<List<RestaurantTable>> build() async {
    return _fetchTables();
  }

  Future<List<RestaurantTable>> _fetchTables() async {
    final user = ref.read(authControllerProvider).value;
    final orgId = user?.organizationId ?? '';
    final activeOutletId = ref.watch(activeOutletProvider)?.id;
    if (orgId.isEmpty || activeOutletId == null) return [];

    final api = ref.read(tableApiProvider);
    final res = await api.getInactive(orgId, outletId: activeOutletId);
    if (!res.success) {
      throw Exception(res.message);
    }
    return res.data ?? [];
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchTables());
  }

  Future<bool> recoverTable(String tableId) async {
    final user = ref.read(authControllerProvider).value;
    final orgId = user?.organizationId ?? '';
    if (orgId.isEmpty) return false;
    final api = ref.read(tableApiProvider);
    final res = await api.recover(orgId, tableId);
    if (res.success) {
      ref.invalidateSelf();
      ref.invalidate(activeTablesProvider);
      return true;
    }
    return false;
  }

  Future<bool> hardDeleteTable(String tableId) async {
    final user = ref.read(authControllerProvider).value;
    final orgId = user?.organizationId ?? '';
    if (orgId.isEmpty) return false;
    final api = ref.read(tableApiProvider);
    final res = await api.delete(orgId, tableId);
    if (res.success) {
      ref.invalidateSelf();
      return true;
    }
    return false;
  }
}

final tableDropdownProvider = FutureProvider<List<RestaurantTable>>((
  ref,
) async {
  final user = ref.read(authControllerProvider).value;
  final orgId = user?.organizationId ?? '';
  final activeOutletId = ref.watch(activeOutletProvider)?.id;
  if (orgId.isEmpty || activeOutletId == null) return [];

  final api = ref.read(tableApiProvider);
  final res = await api.getDropdown(orgId, outletId: activeOutletId);
  if (!res.success) {
    throw Exception(res.message);
  }
  return res.data ?? [];
});
