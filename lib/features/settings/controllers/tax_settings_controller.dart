import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/tax_settings.dart';
import '../../../services/api/tax_settings_api_service.dart';
import '../../auth/controllers/auth_controller.dart';

final taxSettingsControllerProvider =
    AsyncNotifierProvider<TaxSettingsController, TaxSettings?>(
      () => TaxSettingsController(),
    );

class TaxSettingsController extends AsyncNotifier<TaxSettings?> {
  @override
  Future<TaxSettings?> build() async {
    return _fetchTaxSettings();
  }

  Future<TaxSettings?> _fetchTaxSettings() async {
    final user = ref.watch(authControllerProvider).value;
    if (user == null || user.organizationId.isEmpty) return null;

    final api = ref.read(taxSettingsApiServiceProvider);
    final response = await api.getTaxSettings(user.organizationId);

    if (response.success && response.data != null) {
      return TaxSettings.fromJson(response.data!);
    }
    return null; // Return null if 404 or empty, so UI can show "Set up taxes" state
  }

  Future<bool> createTaxSettings({
    String? mode,
    double? serviceCharge,
    bool? scOnDinein,
  }) async {
    final user = ref.read(authControllerProvider).value;
    if (user == null || user.organizationId.isEmpty) return false;

    state = const AsyncValue.loading();
    final api = ref.read(taxSettingsApiServiceProvider);

    final body = <String, dynamic>{};
    if (mode != null) body['mode'] = mode;
    if (serviceCharge != null) body['serviceCharge'] = serviceCharge;
    if (scOnDinein != null) body['scOnDinein'] = scOnDinein;

    final response = await api.createTaxSettings(user.organizationId, body);

    if (response.success && response.data != null) {
      state = AsyncValue.data(TaxSettings.fromJson(response.data!));
      return true;
    } else {
      state = AsyncValue.error(
        response.message ?? 'Failed to create tax settings',
        StackTrace.current,
      );
      return false;
    }
  }

  Future<bool> updateTaxSettings({
    String? mode,
    double? serviceCharge,
    bool? scOnDinein,
  }) async {
    final user = ref.read(authControllerProvider).value;
    if (user == null || user.organizationId.isEmpty) return false;

    state = const AsyncValue.loading();
    final api = ref.read(taxSettingsApiServiceProvider);

    final body = <String, dynamic>{};
    if (mode != null) body['mode'] = mode;
    if (serviceCharge != null) body['serviceCharge'] = serviceCharge;
    if (scOnDinein != null) body['scOnDinein'] = scOnDinein;

    final response = await api.updateTaxSettings(user.organizationId, body);

    if (response.success && response.data != null) {
      state = AsyncValue.data(TaxSettings.fromJson(response.data!));
      return true;
    } else {
      state = AsyncValue.error(
        response.message ?? 'Failed to update tax settings',
        StackTrace.current,
      );
      return false;
    }
  }

  Future<bool> addTaxRate({
    required String name,
    required double percentage,
  }) async {
    final user = ref.read(authControllerProvider).value;
    if (user == null || user.organizationId.isEmpty) return false;

    state = const AsyncValue.loading();
    final api = ref.read(taxSettingsApiServiceProvider);

    final body = <String, dynamic>{'name': name, 'percentage': percentage};

    final response = await api.addTaxRate(user.organizationId, body);

    if (response.success && response.data != null) {
      state = AsyncValue.data(TaxSettings.fromJson(response.data!));
      return true;
    } else {
      state = AsyncValue.error(
        response.message ?? 'Failed to add tax rate',
        StackTrace.current,
      );
      return false;
    }
  }

  Future<bool> setDefaultTaxRate(String rateId) async {
    final user = ref.read(authControllerProvider).value;
    if (user == null || user.organizationId.isEmpty) return false;

    state = const AsyncValue.loading();
    final api = ref.read(taxSettingsApiServiceProvider);

    final response = await api.setDefaultTaxRate(user.organizationId, rateId);

    if (response.success && response.data != null) {
      state = AsyncValue.data(TaxSettings.fromJson(response.data!));
      return true;
    } else {
      state = AsyncValue.error(
        response.message ?? 'Failed to set default tax rate',
        StackTrace.current,
      );
      return false;
    }
  }
}
