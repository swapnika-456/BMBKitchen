import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/day_closing.dart';
import '../../../services/api/day_closing_api_service.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../settings/controllers/active_outlet_provider.dart';

class DayClosingState {
  final String selectedDate;
  final AsyncValue<DayClosingSummary?> summary;
  final AsyncValue<DayClosing?> closing;
  final AsyncValue<List<DayClosing>> history;
  final bool isSubmitting;
  final bool isReopening;
  final String? errorMessage;
  final String? successMessage;

  const DayClosingState({
    required this.selectedDate,
    this.summary = const AsyncValue.loading(),
    this.closing = const AsyncValue.loading(),
    this.history = const AsyncValue.loading(),
    this.isSubmitting = false,
    this.isReopening = false,
    this.errorMessage,
    this.successMessage,
  });

  DayClosingState copyWith({
    String? selectedDate,
    AsyncValue<DayClosingSummary?>? summary,
    AsyncValue<DayClosing?>? closing,
    AsyncValue<List<DayClosing>>? history,
    bool? isSubmitting,
    bool? isReopening,
    String? errorMessage,
    bool clearError = false,
    String? successMessage,
    bool clearSuccess = false,
  }) {
    return DayClosingState(
      selectedDate: selectedDate ?? this.selectedDate,
      summary: summary ?? this.summary,
      closing: closing ?? this.closing,
      history: history ?? this.history,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isReopening: isReopening ?? this.isReopening,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

final dayClosingControllerProvider =
    NotifierProvider<DayClosingController, DayClosingState>(
  () => DayClosingController(),
);

class DayClosingController extends Notifier<DayClosingState> {
  @override
  DayClosingState build() {
    final now = DateTime.now();
    final today =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    
    // Automatically load data when outlet or user changes
    Future.microtask(() => loadAll());

    return DayClosingState(selectedDate: today);
  }

  DayClosingApiService get _api => ref.read(dayClosingApiServiceProvider);

  String? get _orgId {
    final auth = ref.read(authControllerProvider).value;
    return auth?.organizationId;
  }

  String? get _outletId {
    final activeOutlet = ref.read(activeOutletProvider);
    return activeOutlet?.id;
  }

  Future<void> setDate(String date) async {
    if (state.selectedDate == date) return;
    state = state.copyWith(
      selectedDate: date,
      summary: const AsyncValue.loading(),
      closing: const AsyncValue.loading(),
      clearError: true,
      clearSuccess: true,
    );
    await Future.wait([
      _loadSummary(date),
      _loadClosing(date),
    ]);
  }

  Future<void> loadAll() async {
    state = state.copyWith(
      summary: const AsyncValue.loading(),
      closing: const AsyncValue.loading(),
      history: const AsyncValue.loading(),
      clearError: true,
      clearSuccess: true,
    );
    await Future.wait([
      _loadSummary(state.selectedDate),
      _loadClosing(state.selectedDate),
      _loadHistory(),
    ]);
  }

  Future<void> _loadSummary(String date) async {
    final orgId = _orgId;
    final outletId = _outletId;
    if (orgId == null || outletId == null) {
      state = state.copyWith(
        summary: const AsyncValue.error('Outlet or organization not selected', StackTrace.empty),
      );
      return;
    }

    final resp = await _api.getSummary(orgId, outletId, date);
    if (resp.success) {
      state = state.copyWith(summary: AsyncValue.data(resp.data));
    } else {
      state = state.copyWith(summary: AsyncValue.error(resp.message, StackTrace.empty));
    }
  }

  Future<void> _loadClosing(String date) async {
    final orgId = _orgId;
    final outletId = _outletId;
    if (orgId == null || outletId == null) {
      state = state.copyWith(
        closing: const AsyncValue.error('Outlet or organization not selected', StackTrace.empty),
      );
      return;
    }

    final resp = await _api.getClosing(orgId, outletId, date);
    if (resp.success) {
      state = state.copyWith(closing: AsyncValue.data(resp.data));
    } else {
      state = state.copyWith(closing: AsyncValue.error(resp.message, StackTrace.empty));
    }
  }

  Future<void> _loadHistory() async {
    final orgId = _orgId;
    final outletId = _outletId;
    if (orgId == null || outletId == null) {
      state = state.copyWith(
        history: const AsyncValue.error('Outlet or organization not selected', StackTrace.empty),
      );
      return;
    }

    final resp = await _api.getHistory(orgId, outletId);
    if (resp.success) {
      state = state.copyWith(history: AsyncValue.data(resp.data ?? []));
    } else {
      state = state.copyWith(history: AsyncValue.error(resp.message, StackTrace.empty));
    }
  }

  Future<bool> submitClosing({
    required double actualCash,
    String? note,
  }) async {
    final orgId = _orgId;
    final outletId = _outletId;
    if (orgId == null || outletId == null) {
      state = state.copyWith(errorMessage: 'No outlet or organization selected');
      return false;
    }

    state = state.copyWith(isSubmitting: true, clearError: true, clearSuccess: true);
    final resp = await _api.createClosing(
      orgId,
      outletId: outletId,
      closingDate: state.selectedDate,
      actualCash: actualCash,
      note: note,
    );

    state = state.copyWith(isSubmitting: false);
    if (resp.success && resp.data != null) {
      state = state.copyWith(
        closing: AsyncValue.data(resp.data),
        successMessage: 'Day closing ${resp.data!.closingNo} recorded successfully',
      );
      // Reload history and closing
      _loadHistory();
      return true;
    } else {
      state = state.copyWith(errorMessage: resp.message);
      return false;
    }
  }

  Future<bool> reopenClosing(String closingId, {String? reason}) async {
    final orgId = _orgId;
    if (orgId == null) {
      state = state.copyWith(errorMessage: 'No organization selected');
      return false;
    }

    state = state.copyWith(isReopening: true, clearError: true, clearSuccess: true);
    final resp = await _api.reopenClosing(orgId, closingId, reason: reason);
    state = state.copyWith(isReopening: false);

    if (resp.success && resp.data != null) {
      state = state.copyWith(
        closing: AsyncValue.data(resp.data),
        successMessage: 'Day closing reopened successfully',
      );
      _loadHistory();
      return true;
    } else {
      state = state.copyWith(errorMessage: resp.message);
      return false;
    }
  }
}
