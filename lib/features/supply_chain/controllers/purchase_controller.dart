import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/purchase.dart';
import '../../../services/api/purchase_api_service.dart';
import '../../auth/controllers/auth_controller.dart';

// Provides the list of active purchases
class ActivePurchaseNotifier extends AsyncNotifier<List<Purchase>> {
  @override
  Future<List<Purchase>> build() async {
    final user = ref.watch(authControllerProvider).value;
    if (user == null || user.organizationId.isEmpty) return [];

    final apiService = ref.watch(purchaseApiServiceProvider);
    final response = await apiService.getActivePurchases(user.organizationId);

    if (response.success && response.data != null) {
      return response.data!.map((json) => Purchase.fromJson(json)).toList();
    }
    return [];
  }

  Future<String?> createPurchase(Map<String, dynamic> data) async {
    final user = ref.read(authControllerProvider).value;
    if (user == null) return 'User not found';

    final apiService = ref.read(purchaseApiServiceProvider);
    final res = await apiService.createPurchase(user.organizationId, data);
    
    if (res.success) {
      ref.invalidateSelf();
      return null;
    }
    return res.message;
  }

  Future<String?> updatePaymentStatus(String purchaseId, String status) async {
    final user = ref.read(authControllerProvider).value;
    if (user == null) return 'User not found';

    final apiService = ref.read(purchaseApiServiceProvider);
    final res = await apiService.updatePaymentStatus(user.organizationId, purchaseId, status);
    
    if (res.success) {
      ref.invalidateSelf();
      return null;
    }
    return res.message;
  }

  Future<String?> deletePurchase(String purchaseId) async {
    final user = ref.read(authControllerProvider).value;
    if (user == null) return 'User not found';

    final apiService = ref.read(purchaseApiServiceProvider);
    final res = await apiService.deletePurchase(user.organizationId, purchaseId);
    
    if (res.success) {
      ref.invalidateSelf();
      ref.invalidate(inactivePurchaseProvider);
      return null;
    }
    return res.message;
  }
}

final activePurchaseProvider = AsyncNotifierProvider<ActivePurchaseNotifier, List<Purchase>>(
  () => ActivePurchaseNotifier(),
);

// Provides the list of inactive purchases
class InactivePurchaseNotifier extends AsyncNotifier<List<Purchase>> {
  @override
  Future<List<Purchase>> build() async {
    final user = ref.watch(authControllerProvider).value;
    if (user == null || user.organizationId.isEmpty) return [];

    final apiService = ref.watch(purchaseApiServiceProvider);
    final response = await apiService.getInactivePurchases(user.organizationId);

    if (response.success && response.data != null) {
      return response.data!.map((json) => Purchase.fromJson(json)).toList();
    }
    return [];
  }

  Future<String?> restorePurchase(String purchaseId) async {
    final user = ref.read(authControllerProvider).value;
    if (user == null) return 'User not found';

    final apiService = ref.read(purchaseApiServiceProvider);
    final res = await apiService.restorePurchase(user.organizationId, purchaseId);
    
    if (res.success) {
      ref.invalidateSelf();
      ref.invalidate(activePurchaseProvider);
      return null;
    }
    return res.message;
  }

  Future<String?> hardDeletePurchase(String purchaseId) async {
    final user = ref.read(authControllerProvider).value;
    if (user == null) return 'User not found';

    final apiService = ref.read(purchaseApiServiceProvider);
    final res = await apiService.hardDeletePurchase(user.organizationId, purchaseId);
    
    if (res.success) {
      ref.invalidateSelf();
      return null;
    }
    return res.message;
  }
}

final inactivePurchaseProvider = AsyncNotifierProvider<InactivePurchaseNotifier, List<Purchase>>(
  () => InactivePurchaseNotifier(),
);
