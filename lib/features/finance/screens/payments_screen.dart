import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/bmb_button.dart';
import '../../../core/widgets/bmb_card.dart';
import '../../../core/widgets/bmb_empty_state.dart';
import '../../../core/widgets/bmb_skeleton.dart';
import '../../../models/payment.dart';
import '../../settings/controllers/active_outlet_provider.dart';
import '../controllers/payments_controller.dart';
import '../widgets/payment_detail_sheet.dart';

class PaymentsScreen extends ConsumerStatefulWidget {
  const PaymentsScreen({super.key});

  @override
  ConsumerState<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends ConsumerState<PaymentsScreen> {
  Future<void> _selectDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 2),
      initialDateRange: DateTimeRange(
        start: now.subtract(const Duration(days: 7)),
        end: now,
      ),
    );
    if (picked != null) {
      final fromStr =
          "${picked.start.year}-${picked.start.month.toString().padLeft(2, '0')}-${picked.start.day.toString().padLeft(2, '0')}";
      final toStr =
          "${picked.end.year}-${picked.end.month.toString().padLeft(2, '0')}-${picked.end.day.toString().padLeft(2, '0')}";
      ref.read(paymentsControllerProvider.notifier).setDateRange(fromStr, toStr);
    }
  }

  void _clearDateRange() {
    ref.read(paymentsControllerProvider.notifier).clearDateRange();
  }

  @override
  Widget build(BuildContext context) {
    final paymentsAsync = ref.watch(paymentsControllerProvider);
    final filter = ref.watch(paymentsFilterProvider);
    final activeOutlet = ref.watch(activeOutletProvider);
    final notifier = ref.read(paymentsControllerProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            _buildTopBar(activeOutlet),
            // Filters
            _buildFilterBar(filter, notifier),
            const Divider(height: 1),
            // Body with Pull-to-Refresh
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => notifier.refresh(),
                child: paymentsAsync.when(
                  data: (data) => _buildContent(data, filter, notifier),
                  loading: () => _buildLoadingSkeleton(),
                  error: (err, _) => _buildErrorState(err.toString(), notifier),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(dynamic activeOutlet) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.leafSoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.payments, color: AppColors.leaf, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Payments & Receipts', style: AppText.h2),
                Text(
                  activeOutlet != null ? '${activeOutlet.name} (${activeOutlet.code})' : 'Payment Records (#127)',
                  style: AppText.caption.copyWith(color: AppColors.muted),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => ref.read(paymentsControllerProvider.notifier).refresh(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(PaymentsFilter filter, PaymentsController notifier) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Scope & Date Range
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.inputFill,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildScopeTab('today', 'Today', filter.scope, notifier),
                      _buildScopeTab('week', 'Week', filter.scope, notifier),
                      _buildScopeTab('month', 'Month', filter.scope, notifier),
                      _buildScopeTab('year', 'Year', filter.scope, notifier),
                      _buildScopeTab('all', 'All', filter.scope, notifier),
                      _buildScopeTab('custom', 'Custom', filter.scope, notifier, onTap: _selectDateRange),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    side: BorderSide(color: filter.from != null ? AppColors.tandoor : AppColors.line),
                    backgroundColor: filter.from != null ? AppColors.tandoorSoft : Colors.transparent,
                  ),
                  icon: Icon(Icons.calendar_today, size: 14, color: filter.from != null ? AppColors.tandoor : AppColors.ink),
                  label: Text(
                    filter.from != null ? '${filter.from} to ${filter.to}' : 'Date Range',
                    style: TextStyle(fontSize: 11, color: filter.from != null ? AppColors.tandoor : AppColors.ink),
                  ),
                  onPressed: _selectDateRange,
                ),
                if (filter.from != null)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 16),
                    tooltip: 'Clear dates',
                    onPressed: _clearDateRange,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Row 2: Payment Method & Order Type Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Text('Method:', style: AppText.caption.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(width: 6),
                _buildMethodChip(null, 'All', filter.paymentMethod, notifier),
                const SizedBox(width: 4),
                _buildMethodChip('cash', 'Cash', filter.paymentMethod, notifier),
                const SizedBox(width: 4),
                _buildMethodChip('upi', 'UPI', filter.paymentMethod, notifier),
                const SizedBox(width: 4),
                _buildMethodChip('card', 'Card', filter.paymentMethod, notifier),
                const SizedBox(width: 4),
                _buildMethodChip('split', 'Split', filter.paymentMethod, notifier),
                const SizedBox(width: 4),
                _buildMethodChip('unpaid', 'Unpaid', filter.paymentMethod, notifier),
                const SizedBox(width: 12),
                Text('Type:', style: AppText.caption.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(width: 6),
                _buildTypeChip(null, 'All', filter.orderType, notifier),
                const SizedBox(width: 4),
                _buildTypeChip('dine_in', 'Dine-in', filter.orderType, notifier),
                const SizedBox(width: 4),
                _buildTypeChip('takeaway', 'Takeaway', filter.orderType, notifier),
                const SizedBox(width: 4),
                _buildTypeChip('delivery', 'Delivery', filter.orderType, notifier),
                const SizedBox(width: 4),
                _buildTypeChip('online', 'Online', filter.orderType, notifier),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScopeTab(
    String scope,
    String label,
    String currentScope,
    PaymentsController notifier, {
    VoidCallback? onTap,
  }) {
    final isSel = currentScope == scope;
    return InkWell(
      onTap: onTap ?? () => notifier.setScope(scope),
      borderRadius: BorderRadius.circular(7),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSel ? AppColors.tandoor : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
            color: isSel ? Colors.white : AppColors.ink,
          ),
        ),
      ),
    );
  }

  Widget _buildMethodChip(String? method, String label, String? currentMethod, PaymentsController notifier) {
    final isSel = currentMethod == method;
    return ChoiceChip(
      selected: isSel,
      selectedColor: AppColors.tandoorSoft,
      backgroundColor: AppColors.inputFill,
      side: BorderSide(color: isSel ? AppColors.tandoor : AppColors.line),
      label: Text(label, style: TextStyle(color: isSel ? AppColors.tandoor : AppColors.ink, fontSize: 11, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
      onSelected: (_) => notifier.setPaymentMethod(method),
    );
  }

  Widget _buildTypeChip(String? type, String label, String? currentType, PaymentsController notifier) {
    final isSel = currentType == type;
    return ChoiceChip(
      selected: isSel,
      selectedColor: AppColors.tandoorSoft,
      backgroundColor: AppColors.inputFill,
      side: BorderSide(color: isSel ? AppColors.tandoor : AppColors.line),
      label: Text(label, style: TextStyle(color: isSel ? AppColors.tandoor : AppColors.ink, fontSize: 11, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
      onSelected: (_) => notifier.setOrderType(type),
    );
  }

  Widget _buildContent(PaymentListResponse data, PaymentsFilter filter, PaymentsController notifier) {
    return Column(
      children: [
        // Server Summary (Shown ONLY if server sent summary)
        if (data.summary != null) _buildServerSummary(data.summary!),
        // Payments List
        Expanded(
          child: data.payments.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.4,
                      child: const Center(
                        child: BmbEmptyState(
                          title: 'No Payments Found',
                          description: 'No payment records match the current filters.',
                          icon: Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.muted),
                        ),
                      ),
                    ),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: data.payments.length,
                  separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                  itemBuilder: (ctx, i) => _buildPaymentCard(data.payments[i]),
                ),
        ),
        // Pagination Bar
        _buildPaginationBar(data, filter, notifier),
      ],
    );
  }

  Widget _buildServerSummary(PaymentSummary summary) {
    final unpaidMode = summary.byMode['unpaid'];
    final num? unpaidAmount = unpaidMode?.amount;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.line),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildKpiItem('TOTAL COLLECTED', '₹${summary.totalCollected.toStringAsFixed(0)}', AppColors.leaf),
            if (unpaidAmount != null && unpaidAmount > 0)
              Padding(
                padding: const EdgeInsets.only(left: 14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.chilliSoft,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.chilli.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.info_outline, size: 13, color: AppColors.chilli),
                      const SizedBox(width: 5),
                      Text(
                        'Includes ₹${unpaidAmount.toStringAsFixed(unpaidAmount % 1 == 0 ? 0 : 2)} marked unpaid',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.chilli,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ...summary.byMode.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(left: 20),
                child: _buildKpiItem(
                  '${entry.key.toUpperCase()} (${entry.value.count})',
                  '₹${entry.value.amount.toStringAsFixed(0)}',
                  entry.key.toLowerCase() == 'unpaid' ? AppColors.chilli : AppColors.ink,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiItem(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.muted, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildPaymentCard(PaymentItem item) {
    return InkWell(
      onTap: () => PaymentDetailSheet.show(context, item.id),
      borderRadius: BorderRadius.circular(12),
      child: BmbCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      Text('Order #${item.orderNo}', style: AppText.body.copyWith(fontWeight: FontWeight.bold)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.inputFill,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(item.orderType.toUpperCase(), style: const TextStyle(fontSize: 10, color: AppColors.muted, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '₹${item.grandTotal.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.tandoor),
                ),
              ],
            ),
            if (item.billNo != null && item.billNo!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Bill: ${item.billNo}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.ink)),
            ],
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              runSpacing: 4,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.leafSoft,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item.paymentMethod.toUpperCase(),
                    style: const TextStyle(color: AppColors.leaf, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (item.paidAt != null)
                      Text(
                        '${item.paidAt!.hour.toString().padLeft(2, '0')}:${item.paidAt!.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(fontSize: 11, color: AppColors.muted),
                      ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right, size: 16, color: AppColors.muted),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaginationBar(PaymentListResponse data, PaymentsFilter filter, PaymentsController notifier) {
    final totalPages = data.totalPages > 0 ? data.totalPages : 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 6,
        children: [
          Text(
            'Showing ${data.payments.length} of ${data.total} payments',
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, size: 20),
                onPressed: filter.page > 1 ? () => notifier.setPage(filter.page - 1) : null,
              ),
              Text(
                'Page ${filter.page} / $totalPages',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, size: 20),
                onPressed: filter.page < totalPages ? () => notifier.setPage(filter.page + 1) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      separatorBuilder: (ctx, i) => const SizedBox(height: 12),
      itemBuilder: (ctx, i) => const BmbSkeleton(width: double.infinity, height: 90),
    );
  }

  Widget _buildErrorState(String error, PaymentsController notifier) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.5,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Error loading payments: $error',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.chilli)),
                  const SizedBox(height: 16),
                  BmbButton(
                    label: 'Retry',
                    onPressed: () => notifier.refresh(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
