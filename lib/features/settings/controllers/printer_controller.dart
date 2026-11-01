import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/printer.dart';
import '../../../services/api/printer_api_service.dart';
import '../../auth/controllers/auth_controller.dart';
import 'active_outlet_provider.dart';

class PrinterState {
  final List<Printer> activePrinters;
  final List<Printer> inactivePrinters;
  final bool showInactive;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;

  const PrinterState({
    this.activePrinters = const [],
    this.inactivePrinters = const [],
    this.showInactive = false,
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
  });

  PrinterState copyWith({
    List<Printer>? activePrinters,
    List<Printer>? inactivePrinters,
    bool? showInactive,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PrinterState(
      activePrinters: activePrinters ?? this.activePrinters,
      inactivePrinters: inactivePrinters ?? this.inactivePrinters,
      showInactive: showInactive ?? this.showInactive,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final printerControllerProvider =
    NotifierProvider<PrinterController, PrinterState>(
  () => PrinterController(),
);

class PrinterController extends Notifier<PrinterState> {
  @override
  PrinterState build() {
    final activeOutlet = ref.watch(activeOutletProvider);
    final user = ref.watch(authControllerProvider).value;

    // Trigger initial load when user/outlet available
    if (user != null && user.organizationId.isNotEmpty) {
      Future.microtask(() => loadPrinters(outletId: activeOutlet?.id));
      return const PrinterState(isLoading: true);
    }

    return const PrinterState(isLoading: false);
  }

  PrinterApiService get _api => ref.read(printerApiServiceProvider);

  String? get _orgId => ref.read(authControllerProvider).value?.organizationId;

  Future<void> loadPrinters({String? outletId}) async {
    final orgId = _orgId;
    if (orgId == null || orgId.isEmpty) {
      state = state.copyWith(isLoading: false);
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final activeRes = await _api.getActivePrinters(orgId, outletId: outletId);
      final inactiveRes = await _api.getInactivePrinters(orgId, outletId: outletId);

      if (activeRes.success) {
        state = state.copyWith(
          activePrinters: activeRes.data ?? [],
          inactivePrinters: inactiveRes.success ? (inactiveRes.data ?? []) : [],
          isLoading: false,
          clearError: true,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: activeRes.message,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  void toggleShowInactive() {
    state = state.copyWith(showInactive: !state.showInactive);
  }

  Future<bool> createPrinter({
    required String outletId,
    required String name,
    required String type,
    String? printerModel,
    String? conn,
    String? size,
    int? copies,
    List<String>? categories,
  }) async {
    final orgId = _orgId;
    if (orgId == null) return false;

    state = state.copyWith(isSaving: true, clearError: true);
    final res = await _api.createPrinter(
      orgId,
      outletId: outletId,
      name: name,
      type: type,
      printerModel: printerModel,
      conn: conn,
      size: size,
      copies: copies,
      categories: categories,
    );

    state = state.copyWith(isSaving: false);

    if (res.success && res.data != null) {
      state = state.copyWith(
        activePrinters: [...state.activePrinters, res.data!],
      );
      return true;
    } else {
      state = state.copyWith(errorMessage: res.message);
      return false;
    }
  }

  Future<bool> updatePrinter({
    required String printerId,
    String? outletId,
    String? name,
    String? type,
    String? printerModel,
    String? conn,
    String? size,
    int? copies,
    List<String>? categories,
  }) async {
    final orgId = _orgId;
    if (orgId == null) return false;

    state = state.copyWith(isSaving: true, clearError: true);
    final res = await _api.updatePrinter(
      orgId,
      printerId,
      outletId: outletId,
      name: name,
      type: type,
      printerModel: printerModel,
      conn: conn,
      size: size,
      copies: copies,
      categories: categories,
    );

    state = state.copyWith(isSaving: false);

    if (res.success && res.data != null) {
      final updated = res.data!;
      state = state.copyWith(
        activePrinters: state.activePrinters.map((p) => p.id == updated.id ? updated : p).toList(),
        inactivePrinters: state.inactivePrinters.map((p) => p.id == updated.id ? updated : p).toList(),
      );
      return true;
    } else {
      state = state.copyWith(errorMessage: res.message);
      return false;
    }
  }

  Future<bool> deactivatePrinter(String printerId) async {
    final orgId = _orgId;
    if (orgId == null) return false;

    state = state.copyWith(isSaving: true, clearError: true);
    final res = await _api.deactivatePrinter(orgId, printerId);
    state = state.copyWith(isSaving: false);

    if (res.success && res.data != null) {
      final updated = res.data!;
      state = state.copyWith(
        activePrinters: state.activePrinters.where((p) => p.id != printerId).toList(),
        inactivePrinters: [...state.inactivePrinters.where((p) => p.id != printerId), updated],
      );
      return true;
    } else {
      state = state.copyWith(errorMessage: res.message);
      return false;
    }
  }

  Future<bool> restorePrinter(String printerId) async {
    final orgId = _orgId;
    if (orgId == null) return false;

    state = state.copyWith(isSaving: true, clearError: true);
    final res = await _api.restorePrinter(orgId, printerId);
    state = state.copyWith(isSaving: false);

    if (res.success && res.data != null) {
      final updated = res.data!;
      state = state.copyWith(
        inactivePrinters: state.inactivePrinters.where((p) => p.id != printerId).toList(),
        activePrinters: [...state.activePrinters.where((p) => p.id != printerId), updated],
      );
      return true;
    } else {
      state = state.copyWith(errorMessage: res.message);
      return false;
    }
  }

  Future<bool> deletePrinter(String printerId) async {
    final orgId = _orgId;
    if (orgId == null) return false;

    state = state.copyWith(isSaving: true, clearError: true);
    final res = await _api.deletePrinter(orgId, printerId);
    state = state.copyWith(isSaving: false);

    if (res.success) {
      state = state.copyWith(
        activePrinters: state.activePrinters.where((p) => p.id != printerId).toList(),
        inactivePrinters: state.inactivePrinters.where((p) => p.id != printerId).toList(),
      );
      return true;
    } else {
      state = state.copyWith(errorMessage: res.message);
      return false;
    }
  }
}
