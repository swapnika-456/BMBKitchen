import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/vendor.dart';
import '../../../services/api/vendor_api_service.dart';
import '../../auth/controllers/auth_controller.dart';

final activeVendorsProvider =
    AsyncNotifierProvider<ActiveVendorsNotifier, List<Vendor>>(() {
  return ActiveVendorsNotifier();
});

class ActiveVendorsNotifier extends AsyncNotifier<List<Vendor>> {
  @override
  Future<List<Vendor>> build() async {
    return _fetchVendors();
  }

  Future<List<Vendor>> _fetchVendors() async {
    final user = ref.read(authControllerProvider).value;
    final orgId = user?.organizationId ?? '';
    if (orgId.isEmpty) return [];

    final api = ref.read(vendorApiProvider);
    final res = await api.getActive(orgId);
    if (!res.success) {
      throw Exception(res.message);
    }
    return res.data ?? [];
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchVendors());
    ref.invalidate(vendorDropdownProvider);
  }

  Future<bool> createVendor(Map<String, dynamic> data) async {
    final user = ref.read(authControllerProvider).value;
    final orgId = user?.organizationId ?? '';
    if (orgId.isEmpty) return false;
    final api = ref.read(vendorApiProvider);
    final res = await api.create(orgId, data);
    if (res.success) {
      ref.invalidateSelf();
      ref.invalidate(vendorDropdownProvider);
      return true;
    }
    throw Exception(res.message);
  }

  Future<bool> updateVendor(String vendorId, Map<String, dynamic> data) async {
    final user = ref.read(authControllerProvider).value;
    final orgId = user?.organizationId ?? '';
    if (orgId.isEmpty) return false;
    final api = ref.read(vendorApiProvider);
    final res = await api.update(orgId, vendorId, data);
    if (res.success) {
      ref.invalidateSelf();
      ref.invalidate(vendorDropdownProvider);
      return true;
    }
    throw Exception(res.message);
  }

  Future<bool> deactivateVendor(String vendorId) async {
    final user = ref.read(authControllerProvider).value;
    final orgId = user?.organizationId ?? '';
    if (orgId.isEmpty) return false;
    final api = ref.read(vendorApiProvider);
    final res = await api.softDelete(orgId, vendorId);
    if (res.success) {
      ref.invalidateSelf();
      ref.invalidate(inactiveVendorsProvider);
      ref.invalidate(vendorDropdownProvider);
      return true;
    }
    throw Exception(res.message);
  }
}

final inactiveVendorsProvider =
    AsyncNotifierProvider<InactiveVendorsNotifier, List<Vendor>>(() {
  return InactiveVendorsNotifier();
});

class InactiveVendorsNotifier extends AsyncNotifier<List<Vendor>> {
  @override
  Future<List<Vendor>> build() async {
    return _fetchVendors();
  }

  Future<List<Vendor>> _fetchVendors() async {
    final user = ref.read(authControllerProvider).value;
    final orgId = user?.organizationId ?? '';
    if (orgId.isEmpty) return [];

    final api = ref.read(vendorApiProvider);
    final res = await api.getInactive(orgId);
    if (!res.success) {
      throw Exception(res.message);
    }
    return res.data ?? [];
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchVendors());
  }

  Future<bool> restoreVendor(String vendorId) async {
    final user = ref.read(authControllerProvider).value;
    final orgId = user?.organizationId ?? '';
    if (orgId.isEmpty) return false;
    final api = ref.read(vendorApiProvider);
    final res = await api.restore(orgId, vendorId);
    if (res.success) {
      ref.invalidateSelf();
      ref.invalidate(activeVendorsProvider);
      ref.invalidate(vendorDropdownProvider);
      return true;
    }
    throw Exception(res.message);
  }

  Future<bool> hardDeleteVendor(String vendorId) async {
    final user = ref.read(authControllerProvider).value;
    final orgId = user?.organizationId ?? '';
    if (orgId.isEmpty) return false;
    final api = ref.read(vendorApiProvider);
    final res = await api.hardDelete(orgId, vendorId);
    if (res.success) {
      ref.invalidateSelf();
      return true;
    }
    throw Exception(res.message);
  }
}

final vendorDropdownProvider = FutureProvider<List<Vendor>>((ref) async {
  final user = ref.read(authControllerProvider).value;
  final orgId = user?.organizationId ?? '';
  if (orgId.isEmpty) return [];

  final api = ref.read(vendorApiProvider);
  final res = await api.getDropdown(orgId);
  if (!res.success) {
    throw Exception(res.message);
  }
  return res.data ?? [];
});
