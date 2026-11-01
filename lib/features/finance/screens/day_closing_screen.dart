import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/bmb_card.dart';
import '../../../core/widgets/bmb_empty_state.dart';
import '../../../models/day_closing.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../settings/controllers/active_outlet_provider.dart';
import '../controllers/day_closing_controller.dart';

/// #108 Reopen action is a dead end (re-closing the same date returns 409 even after a reopen).
/// Disabled behind this constant until the backend supports re-closing a reopened day.
const bool kDayReopenEnabled = false;

class DayClosingScreen extends ConsumerStatefulWidget {
  const DayClosingScreen({super.key});

  @override
  ConsumerState<DayClosingScreen> createState() => _DayClosingScreenState();
}

class _DayClosingScreenState extends ConsumerState<DayClosingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _actualCashController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _reopenReasonController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index != _tabIndex) {
        setState(() => _tabIndex = _tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _actualCashController.dispose();
    _noteController.dispose();
    _reopenReasonController.dispose();
    super.dispose();
  }

  bool _canReopen(String? role) {
    if (role == null) return false;
    final r = role.toLowerCase().trim();
    return r == 'owner' || r == 'admin' || r == 'cto';
  }

  Future<void> _pickDate(BuildContext context, String currentDate) async {
    final parts = currentDate.split('-');
    DateTime initial = DateTime.now();
    if (parts.length == 3) {
      initial = DateTime(
        int.tryParse(parts[0]) ?? initial.year,
        int.tryParse(parts[1]) ?? initial.month,
        int.tryParse(parts[2]) ?? initial.day,
      );
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.tandoor,
              onPrimary: Colors.white,
              surface: AppColors.card,
              onSurface: AppColors.ink,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formatted =
          '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      ref.read(dayClosingControllerProvider.notifier).setDate(formatted);
    }
  }

  Future<void> _showConfirmSubmitDialog(double actualCash, double expectedCash) async {
    final diff = actualCash - expectedCash;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: const [
            Icon(Icons.lock_outline, color: AppColors.tandoor),
            SizedBox(width: 8),
            Text('Confirm Day Closing', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Closing is locked upon saving. Only an Owner, Admin, or CTO can reopen it.',
              style: TextStyle(fontSize: 13, color: AppColors.ink),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.inputFill,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.line),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Expected Cash:', style: TextStyle(fontSize: 12, color: AppColors.muted)),
                      Text('₹${expectedCash.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Actual Cash:', style: TextStyle(fontSize: 12, color: AppColors.muted)),
                      Text('₹${actualCash.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                  const Divider(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Difference:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      Text(
                        '${diff >= 0 ? "+" : ""}₹${diff.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: diff == 0 ? AppColors.leaf : AppColors.chilli,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.muted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.tandoor,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Lock & Submit'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await ref.read(dayClosingControllerProvider.notifier).submitClosing(
            actualCash: actualCash,
            note: _noteController.text,
          );
      if (success && mounted) {
        _actualCashController.clear();
        _noteController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Day closing locked and recorded successfully!'),
            backgroundColor: AppColors.leaf,
          ),
        );
      }
    }
  }

  Future<void> _showReopenDialog(DayClosing closing) async {
    _reopenReasonController.clear();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: const [
            Icon(Icons.lock_open, color: AppColors.blue),
            SizedBox(width: 8),
            Text('Reopen Day Closing', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reopening closing #${closing.closingNo} for ${closing.closingDate}. Only Owner, Admin or CTO may perform this action.',
              style: const TextStyle(fontSize: 13, color: AppColors.ink),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _reopenReasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for reopening (optional)',
                hintText: 'e.g. Discrepancy discovered during audit',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.muted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.blue,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Reopen Closing'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await ref.read(dayClosingControllerProvider.notifier).reopenClosing(
            closing.id,
            reason: _reopenReasonController.text,
          );
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Day closing reopened successfully.'),
            backgroundColor: AppColors.blue,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dayClosingControllerProvider);
    final activeOutlet = ref.watch(activeOutletProvider);
    final user = ref.watch(authControllerProvider).value;
    final canReopen = _canReopen(user?.role);

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            _buildTopBar(activeOutlet, state.selectedDate),
            // Tab Header
            Container(
              color: AppColors.card,
              child: TabBar(
                controller: _tabController,
                indicatorColor: AppColors.tandoor,
                labelColor: AppColors.tandoor,
                unselectedLabelColor: AppColors.muted,
                tabs: const [
                  Tab(icon: Icon(Icons.today, size: 18), text: "Daily Closing"),
                  Tab(icon: Icon(Icons.history, size: 18), text: "History (#107)"),
                ],
              ),
            ),
            const Divider(height: 1),
            // Tab Views
            Expanded(
              child: _tabIndex == 0
                  ? _buildDailyClosingTab(state, canReopen)
                  : _buildHistoryTab(state),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(dynamic activeOutlet, String selectedDate) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.card,
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('End-of-Day Closing (26)', style: AppText.h2),
              Text(
                activeOutlet != null ? '${activeOutlet.name} (${activeOutlet.code})' : 'All Outlets',
                style: AppText.caption.copyWith(color: AppColors.muted),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  side: const BorderSide(color: AppColors.line),
                  backgroundColor: AppColors.inputFill,
                ),
                icon: const Icon(Icons.calendar_today, size: 14, color: AppColors.tandoor),
                label: Text(
                  selectedDate,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.ink),
                ),
                onPressed: () => _pickDate(context, selectedDate),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh',
                onPressed: () => ref.read(dayClosingControllerProvider.notifier).loadAll(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDailyClosingTab(DayClosingState state, bool canReopen) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner for errors if any
          if (state.errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.chilliSoft,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.chilli),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: AppColors.chilli, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      state.errorMessage!,
                      style: TextStyle(fontSize: 12, color: AppColors.chilli, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
          // Section 1: #104 Live Summary Card
          _buildLiveSummarySection(state),
          const SizedBox(height: 16),
          // Section 2: Closing Record or Submission Form
          _buildClosingSection(state, canReopen),
        ],
      ),
    );
  }

  Widget _buildLiveSummarySection(DayClosingState state) {
    return state.summary.when(
      data: (summary) {
        if (summary == null) {
          return const BmbCard(
            child: Text('No summary data available for this date.', style: TextStyle(color: AppColors.muted)),
          );
        }

        return BmbCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.analytics_outlined, size: 18, color: AppColors.tandoor),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text('Live Day Summary (#104)', style: AppText.h3, overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.inputFill,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(summary.closingDate, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const Divider(height: 16),
              // KPI Row
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _buildSummaryKpi('TOTAL SALES', '₹${summary.totalSales.toStringAsFixed(2)}', AppColors.leaf),
                  _buildSummaryKpi('EXPECTED CASH', '₹${summary.expectedCash.toStringAsFixed(2)}', AppColors.tandoor),
                  _buildSummaryKpi('BILLS SETTLED', '${summary.billsSettled}', AppColors.ink),
                  _buildSummaryKpi('CANCELLED', '${summary.cancelledOrders}', AppColors.muted),
                ],
              ),
              const SizedBox(height: 16),
              // Sales Breakdown Grid
              const Text('Payment Mode Breakdown (Server-Provided)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.muted)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.inputFill,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.line),
                ),
                child: Column(
                  children: [
                    _buildBreakdownRow('Cash Sales', summary.cashSales),
                    _buildBreakdownRow('UPI Sales', summary.upiSales),
                    _buildBreakdownRow('Card Sales', summary.cardSales),
                    _buildBreakdownRow('Online Paid', summary.onlinePaid),
                    _buildBreakdownRow('Credit Amount', summary.creditAmount),
                    _buildBreakdownRow('Discounts Given', summary.discountsGiven, isDeduction: true),
                    const Divider(height: 12),
                    _buildBreakdownRow('Cash Expenses Paid Out', summary.cashExpensesPaidOut, isDeduction: true),
                    _buildBreakdownRow('Total Expenses Today', summary.totalExpensesToday),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Server-Only Expenses Gap Note
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.amberSoft,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.info_outline, size: 14, color: AppColors.amber),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Expenses have no API, so totalExpensesToday and cashExpensesPaidOut are server-provided only.',
                        style: TextStyle(fontSize: 10, color: AppColors.ink),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const BmbCard(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (e, _) => BmbCard(
        child: Text('Failed to load live summary: $e', style: TextStyle(color: AppColors.chilli)),
      ),
    );
  }

  Widget _buildSummaryKpi(String label, String value, Color color) {
    return Container(
      constraints: const BoxConstraints(minWidth: 120),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.muted)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(String label, double amount, {bool isDeduction = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 11, color: AppColors.ink))),
          const SizedBox(width: 8),
          Text(
            '${isDeduction && amount > 0 ? "-" : ""}₹${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDeduction && amount > 0 ? AppColors.chilli : AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClosingSection(DayClosingState state, bool canReopen) {
    return state.closing.when(
      data: (closing) {
        if (closing != null) {
          // A closing already exists for this date (#106)
          return _buildExistingClosingCard(closing, canReopen);
        } else {
          // Not closed yet -> show closing form (#105)
          final expected = state.summary.value?.expectedCash ?? 0.0;
          return _buildClosingFormCard(state, expected);
        }
      },
      loading: () => const BmbCard(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (e, _) => BmbCard(
        child: Text('Failed to check closing status: $e', style: TextStyle(color: AppColors.chilli)),
      ),
    );
  }

  Widget _buildExistingClosingCard(DayClosing closing, bool canReopen) {
    final isLocked = closing.status.toLowerCase() == 'locked';
    final isReopened = closing.status.toLowerCase() == 'reopened';

    return BmbCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      isLocked ? Icons.lock : Icons.lock_open,
                      color: isLocked ? AppColors.tandoor : AppColors.blue,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text('Closing #${closing.closingNo}', style: AppText.h3, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isLocked ? AppColors.leafSoft : AppColors.blueSoft,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isLocked ? 'Locked' : (isReopened ? 'Reopened' : closing.status),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isLocked ? AppColors.leaf : AppColors.blue,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 16),
          // Closing Details
          _buildDetailRow('Closing Date', closing.closingDate),
          _buildDetailRow('Actual Cash Counted', '₹${closing.actualCash.toStringAsFixed(2)}'),
          _buildDetailRow('Expected Cash', '₹${closing.expectedCash.toStringAsFixed(2)}'),
          _buildDetailRow(
            'Difference',
            '${closing.difference >= 0 ? "+" : ""}₹${closing.difference.toStringAsFixed(2)}',
            color: closing.difference == 0 ? AppColors.leaf : AppColors.chilli,
            isBold: true,
          ),
          if (closing.closedBy != null) _buildDetailRow('Closed By', closing.closedBy!),
          if (closing.note != null && closing.note!.isNotEmpty) _buildDetailRow('Note', closing.note!),
          if (isReopened) ...[
            const Divider(height: 16),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.blueSoft,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.info_outline, size: 14, color: AppColors.blue),
                      SizedBox(width: 4),
                      Text('Reopened Details (#108)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.blue)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (closing.reopenedBy != null) Text('Reopened by: ${closing.reopenedBy}', style: const TextStyle(fontSize: 11)),
                  if (closing.reopenReason != null) Text('Reason: ${closing.reopenReason}', style: const TextStyle(fontSize: 11)),
                  const SizedBox(height: 4),
                  const Text(
                    "Reopened. It can't be closed again until the backend supports it.",
                    style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: AppColors.muted),
                  ),
                ],
              ),
            ),
          ],
          if (isLocked) ...[
            const SizedBox(height: 16),
            if (kDayReopenEnabled && canReopen)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.blue,
                    side: const BorderSide(color: AppColors.blue),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.lock_open, size: 16),
                  label: const Text('Reopen Closing (#108)'),
                  onPressed: () => _showReopenDialog(closing),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.inputFill,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Center(
                  child: Text(
                    'Closing is locked.',
                    style: TextStyle(fontSize: 11, color: AppColors.muted),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? color, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.muted))),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: color ?? AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClosingFormCard(DayClosingState state, double expectedCash) {
    return BmbCard(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.edit_note, color: AppColors.tandoor),
                SizedBox(width: 8),
                Text('Record Day Closing (#105)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            // Actual cash field
            TextFormField(
              controller: _actualCashController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Actual Cash Counted (₹) *',
                hintText: 'e.g. 500.00',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.currency_rupee, size: 18),
                isDense: true,
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Please enter actual cash counted';
                }
                final numVal = double.tryParse(val.trim());
                if (numVal == null || numVal < 0) {
                  return 'Cash amount must be greater than or equal to 0';
                }
                return null;
              },
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),
            // Note field
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'e.g. Cash drawer balanced',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            // Dynamic Difference Estimate
            Builder(builder: (ctx) {
              final val = double.tryParse(_actualCashController.text.trim());
              if (val != null) {
                final diff = val - expectedCash;
                return Container(
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.inputFill,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Estimated Difference:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      Text(
                        '${diff >= 0 ? "+" : ""}₹${diff.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: diff == 0 ? AppColors.leaf : AppColors.chilli,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            }),
            // Staff / Role notice
            Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.inputFill,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Staff may create a closing per PDF roles. Closing is locked upon saving and can only be reopened by an Owner, Admin, or CTO.',
                style: TextStyle(fontSize: 10, color: AppColors.muted),
              ),
            ),
            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.tandoor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: state.isSubmitting
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.check_circle_outline),
                label: Text(state.isSubmitting ? 'Submitting...' : 'Lock & Submit Day Closing'),
                onPressed: state.isSubmitting
                    ? null
                    : () {
                        if (_formKey.currentState?.validate() == true) {
                          final cash = double.parse(_actualCashController.text.trim());
                          _showConfirmSubmitDialog(cash, expectedCash);
                        }
                      },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab(DayClosingState state) {
    return state.history.when(
      data: (items) {
        if (items.isEmpty) {
          return const Center(
            child: BmbEmptyState(
              title: 'No Day Closings',
              description: 'No day closing history records exist for this outlet.',
              icon: Icon(Icons.history_toggle_off, size: 48, color: AppColors.muted),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (ctx, i) => const SizedBox(height: 10),
          itemBuilder: (ctx, i) {
            final item = items[i];
            final isLocked = item.status.toLowerCase() == 'locked';
            return InkWell(
              onTap: () {
                // Switch to daily tab for this item's date
                ref.read(dayClosingControllerProvider.notifier).setDate(item.closingDate);
                _tabController.animateTo(0);
                setState(() => _tabIndex = 0);
              },
              borderRadius: BorderRadius.circular(10),
              child: BmbCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Closing #${item.closingNo}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isLocked ? AppColors.leafSoft : AppColors.blueSoft,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                isLocked ? 'Locked' : (item.status.toLowerCase() == 'reopened' ? 'Reopened' : item.status),
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: isLocked ? AppColors.leaf : AppColors.blue,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('Date: ${item.closingDate}', style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('₹${item.totalSales.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 2),
                        Text(
                          'Diff: ${item.difference >= 0 ? "+" : ""}₹${item.difference.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: item.difference == 0 ? AppColors.leaf : AppColors.chilli,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text('Failed to load history: $e', style: TextStyle(color: AppColors.chilli)),
      ),
    );
  }
}
