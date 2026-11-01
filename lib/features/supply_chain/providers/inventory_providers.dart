import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dio/dio.dart';

import '../../../models/inventory_item.dart';
import '../../../services/api/inventory_api_service.dart';
import '../../auth/controllers/auth_controller.dart';

final activeInventoryProvider =
    AsyncNotifierProvider<ActiveInventoryNotifier, List<InventoryItem>>(() {
  return ActiveInventoryNotifier();
});

class ActiveInventoryNotifier extends AsyncNotifier<List<InventoryItem>> {
  @override
  Future<List<InventoryItem>> build() async {
    return _fetchInventory();
  }

  Future<List<InventoryItem>> _fetchInventory() async {
    final user = ref.read(authControllerProvider).value;
    final orgId = user?.organizationId ?? '';
    if (orgId.isEmpty) return [];

    final api = ref.read(inventoryApiServiceProvider);
    final res = await api.getActiveInventory(orgId);
    if (!res.success) {
      throw Exception(res.message);
    }
    return res.data ?? [];
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchInventory());
    ref.invalidate(inventoryDropdownProvider);
  }

  Future<bool> createItem(Map<String, dynamic> data) async {
    final user = ref.read(authControllerProvider).value;
    final orgId = user?.organizationId ?? '';
    if (orgId.isEmpty) return false;
    
    final api = ref.read(inventoryApiServiceProvider);
    final res = await api.createInventory(orgId, data);
    if (res.success) {
      ref.invalidateSelf();
      ref.invalidate(inventoryDropdownProvider);
      return true;
    }
    throw Exception(res.message);
  }

  Future<bool> updateItem(String id, Map<String, dynamic> data) async {
    final user = ref.read(authControllerProvider).value;
    final orgId = user?.organizationId ?? '';
    if (orgId.isEmpty) return false;
    
    final api = ref.read(inventoryApiServiceProvider);
    final res = await api.updateInventory(orgId, id, data);
    if (res.success) {
      ref.invalidateSelf();
      ref.invalidate(inventoryDropdownProvider);
      return true;
    }
    throw Exception(res.message);
  }

  Future<void> addImage(String id, MultipartFile file) async {
    final user = ref.read(authControllerProvider).value;
    final orgId = user?.organizationId ?? '';
    if (orgId.isEmpty) return;

    final api = ref.read(inventoryApiServiceProvider);
    final res = await api.addImage(orgId, id, file);
    if (!res.success) {
      throw Exception(res.message);
    }
    ref.invalidateSelf();
  }

  Future<void> deleteImage(String id, [String? imageId]) async {
    final user = ref.read(authControllerProvider).value;
    final orgId = user?.organizationId ?? '';
    if (orgId.isEmpty) return;

    final api = ref.read(inventoryApiServiceProvider);
    final res = await api.deleteImage(orgId, id, imageId);
    if (!res.success) {
      throw Exception(res.message);
    }
    ref.invalidateSelf();
  }

  Future<bool> adjustStock(String id, Map<String, dynamic> data) async {
    final user = ref.read(authControllerProvider).value;
    final orgId = user?.organizationId ?? '';
    if (orgId.isEmpty) return false;
    
    final api = ref.read(inventoryApiServiceProvider);
    final res = await api.adjustStock(orgId, id, data);
    if (res.success) {
      ref.invalidateSelf();
      ref.invalidate(inventoryDropdownProvider);
      return true;
    }
    throw Exception(res.message);
  }

  Future<bool> deactivateItem(String id) async {
    final user = ref.read(authControllerProvider).value;
    final orgId = user?.organizationId ?? '';
    if (orgId.isEmpty) return false;
    
    final api = ref.read(inventoryApiServiceProvider);
    final res = await api.deactivateInventory(orgId, id);
    if (res.success) {
      ref.invalidateSelf();
      ref.invalidate(inactiveInventoryProvider);
      ref.invalidate(inventoryDropdownProvider);
      return true;
    }
    throw Exception(res.message);
  }
}

final inactiveInventoryProvider =
    AsyncNotifierProvider<InactiveInventoryNotifier, List<InventoryItem>>(() {
  return InactiveInventoryNotifier();
});

class InactiveInventoryNotifier extends AsyncNotifier<List<InventoryItem>> {
  @override
  Future<List<InventoryItem>> build() async {
    return _fetchInventory();
  }

  Future<List<InventoryItem>> _fetchInventory() async {
    final user = ref.read(authControllerProvider).value;
    final orgId = user?.organizationId ?? '';
    if (orgId.isEmpty) return [];

    final api = ref.read(inventoryApiServiceProvider);
    final res = await api.getInactiveInventory(orgId);
    if (!res.success) {
      throw Exception(res.message);
    }
    return res.data ?? [];
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchInventory());
  }

  Future<bool> restoreItem(String id) async {
    final user = ref.read(authControllerProvider).value;
    final orgId = user?.organizationId ?? '';
    if (orgId.isEmpty) return false;
    
    final api = ref.read(inventoryApiServiceProvider);
    final res = await api.restoreInventory(orgId, id);
    if (res.success) {
      ref.invalidateSelf();
      ref.invalidate(activeInventoryProvider);
      ref.invalidate(inventoryDropdownProvider);
      return true;
    }
    throw Exception(res.message);
  }

  Future<bool> hardDeleteItem(String id) async {
    final user = ref.read(authControllerProvider).value;
    final orgId = user?.organizationId ?? '';
    if (orgId.isEmpty) return false;
    
    final api = ref.read(inventoryApiServiceProvider);
    final res = await api.deleteInventoryHard(orgId, id);
    if (res.success) {
      ref.invalidateSelf();
      return true;
    }
    throw Exception(res.message);
  }
}

final inventoryDropdownProvider =
    FutureProvider<List<InventoryDropdownItem>>((ref) async {
  final user = ref.read(authControllerProvider).value;
  final orgId = user?.organizationId ?? '';
  if (orgId.isEmpty) return [];

  final api = ref.read(inventoryApiServiceProvider);
  final res = await api.getDropdown(orgId);
  if (!res.success) {
    throw Exception(res.message);
  }
  return res.data ?? [];
});
