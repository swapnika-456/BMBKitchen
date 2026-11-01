import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/models.dart';
import '../../../services/api/menu_item_api_service.dart';
import '../../auth/controllers/auth_controller.dart';

final menuItemControllerProvider =
    AsyncNotifierProvider<MenuItemController, List<MenuItem>>(
      MenuItemController.new,
    );

class MenuItemController extends AsyncNotifier<List<MenuItem>> {
  @override
  Future<List<MenuItem>> build() async {
    return fetchActive();
  }

  Future<List<MenuItem>> fetchActive() async {
    final user = ref.read(authControllerProvider).value;
    if (user?.organizationId == null || user!.organizationId.isEmpty) return [];

    final api = ref.read(menuItemApiProvider);
    final res = await api.getActive(user.organizationId);

    if (res.success && res.data != null) {
      return res.data!;
    }

    if (!res.success) throw res.message;
    return [];
  }

  Future<List<MenuItem>> fetchInactive() async {
    final user = ref.read(authControllerProvider).value;
    if (user?.organizationId == null || user!.organizationId.isEmpty) return [];

    final api = ref.read(menuItemApiProvider);
    final res = await api.getInactive(user.organizationId);

    if (res.success && res.data != null) {
      return res.data!;
    }

    if (!res.success) throw res.message;
    return [];
  }

  Future<String?> createItem(
    Map<String, dynamic> data, {
    List<MultipartFile>? files,
  }) async {
    final res = await createItemReturnObj(data, files: files);
    return res.error;
  }

  Future<({String? error, MenuItem? item})> createItemReturnObj(
    Map<String, dynamic> data, {
    List<MultipartFile>? files,
  }) async {
    final user = ref.read(authControllerProvider).value;
    if (user?.organizationId == null || user!.organizationId.isEmpty)
      return (error: 'Not authenticated', item: null);

    final api = ref.read(menuItemApiProvider);
    final res = await api.create(user.organizationId, data, files: files);

    if (res.success && res.data != null) {
      ref.invalidateSelf();
      return (error: null, item: res.data);
    }

    return (
      error: res.message.isNotEmpty ? res.message : 'Failed to create item',
      item: null,
    );
  }

  Future<String?> updateItem(String id, Map<String, dynamic> data) async {
    final user = ref.read(authControllerProvider).value;
    if (user?.organizationId == null || user!.organizationId.isEmpty)
      return 'Not authenticated';

    final api = ref.read(menuItemApiProvider);
    final res = await api.update(user.organizationId, id, data);

    if (res.success) {
      ref.invalidateSelf();
      return null;
    }

    return res.message.isNotEmpty ? res.message : 'Failed to update item';
  }

  Future<String?> deactivateItem(String id) async {
    final user = ref.read(authControllerProvider).value;
    if (user?.organizationId == null || user!.organizationId.isEmpty)
      return 'Not authenticated';

    final api = ref.read(menuItemApiProvider);
    final res = await api.deactivate(user.organizationId, id);

    if (res.success) {
      ref.invalidateSelf();
      return null;
    }

    return res.message.isNotEmpty ? res.message : 'Failed to deactivate item';
  }

  Future<String?> recoverItem(String id) async {
    final user = ref.read(authControllerProvider).value;
    if (user?.organizationId == null || user!.organizationId.isEmpty)
      return 'Not authenticated';

    final api = ref.read(menuItemApiProvider);
    final res = await api.recover(user.organizationId, id);

    if (res.success) {
      ref.invalidateSelf();
      return null;
    }

    return res.message.isNotEmpty ? res.message : 'Failed to recover item';
  }

  Future<String?> hardDeleteItem(String id) async {
    final user = ref.read(authControllerProvider).value;
    if (user?.organizationId == null || user!.organizationId.isEmpty)
      return 'Not authenticated';

    final api = ref.read(menuItemApiProvider);
    final res = await api.hardDelete(user.organizationId, id);

    if (res.success) {
      ref.invalidateSelf();
      return null;
    }

    return res.message.isNotEmpty
        ? res.message
        : 'Failed to permanently delete item';
  }
}
