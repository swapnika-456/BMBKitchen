import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/widgets/bmb_card.dart';
import '../../../core/widgets/bmb_key_value_row.dart';
import '../../../core/widgets/bmb_kpi_tile.dart';
import '../../../core/widgets/bmb_screen_header.dart';
import '../../../models/report_models.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../settings/controllers/outlet_controller.dart';
import '../controllers/reports_controller.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  String _formatCurrency(double amount) {
    return '₹${amount.toStringAsFixed(2)}';
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '-';
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final m = months[dt.month - 1];
    final d = dt.day.toString().padLeft(2, '0');
    final y = dt.year;
    final hr = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$d $m $y, $hr:$min';
  }

  bool _isAllowedRole() {
    final user = ref.watch(authControllerProvider).value;
    final role = user?.role.toLowerCase() ?? '';
    return role == 'owner' || role == 'admin' || role == 'cto';
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAllowedRole()) {
      return _buildAccessRestrictedView();
    }

    final reportsAsync = ref.watch(reportsControllerProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: reportsAsync.when(
        loading: () => _buildLoadingSkeleton(),
        error: (err, _) => _buildErrorState(err.toString()),
        data: (state) => _buildContent(context, state),
      ),
    );
  }

  Widget _buildAccessRestrictedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Gap.xl),
        child: BmbCard(
          padding: const EdgeInsets.all(Gap.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.lock_outline_rounded,
                size: 56,
                color: AppColors.muted,
              ),
              const SizedBox(height: Gap.md),
              Text(
                'No access',
                style: AppText.h2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Gap.sm),
              Text(
                'Staff members do not have access to Reports & Analytics.\n'
                'Only Organization Owners, Admins, and CTOs can view financial reports.',
                style: AppText.bodyMedium.copyWith(color: AppColors.muted),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Gap.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const BmbScreenHeader(
            title: 'Reports & Analytics',
            subtitle: 'Loading live business metrics...',
          ),
          const SizedBox(height: Gap.lg),
          ...List.generate(
            3,
            (idx) => Padding(
              padding: const EdgeInsets.only(bottom: Gap.lg),
              child: BmbCard(
                padding: const EdgeInsets.all(Gap.lg),
                child: SizedBox(
                  height: 120,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.tandoor,
                      strokeWidth: 2,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Gap.xl),
        child: BmbCard(
          padding: const EdgeInsets.all(Gap.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: AppColors.chilli,
              ),
              const SizedBox(height: Gap.md),
              Text(
                'Failed to load report',
                style: AppText.h3,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Gap.sm),
              Text(
                message,
                style: AppText.caption.copyWith(color: AppColors.muted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Gap.lg),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.tandoor,
                  foregroundColor: Colors.white,
                ),
                onPressed: () =>
                    ref.read(reportsControllerProvider.notifier).refresh(),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, ReportsState state) {
    final filter = state.filter;
    final outletsAsync = ref.watch(outletControllerProvider);
    final outlets = outletsAsync.value ?? [];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 640;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(Gap.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BmbScreenHeader(
                title: 'Reports & Analytics',
                subtitle:
                    'Sales summaries, item ranks & tax filing reports (Sidebar 24)',
              ),
              const SizedBox(height: Gap.md),

              // Filter Controls Card
              BmbCard(
                padding: const EdgeInsets.all(Gap.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Outlet & Scope Selector
                    Wrap(
                      spacing: Gap.md,
                      runSpacing: Gap.sm,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        // Outlet Dropdown
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: Gap.sm),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.line),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: filter.outletId ?? 'all',
                              isDense: true,
                              items: [
                                const DropdownMenuItem(
                                  value: 'all',
                                  child: Text('All Outlets'),
                                ),
                                ...outlets.map(
                                  (o) => DropdownMenuItem(
                                    value: o.id,
                                    child: Text(o.name),
                                  ),
                                ),
                              ],
                              onChanged: (val) {
                                ref
                                    .read(reportsControllerProvider.notifier)
                                    .setOutlet(val == 'all' ? null : val);
                              },
                            ),
                          ),
                        ),

                        // Scope Chips
                        _scopeChip('today', 'Today', filter.scope),
                        _scopeChip('week', 'This Week', filter.scope),
                        _scopeChip('month', 'This Month', filter.scope),
                        _scopeChip('year', 'This Year', filter.scope),
                        _scopeChip('custom', 'Custom Range', filter.scope),

                        if (filter.scope == 'custom' &&
                            filter.customFrom != null &&
                            filter.customTo != null)
                          Text(
                            '${filter.fromFormatted} to ${filter.toFormatted}',
                            style: AppText.caption.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.tandoor,
                            ),
                          ),
                      ],
                    ),

                    if (state.isLoading) ...[
                      const SizedBox(height: Gap.sm),
                      const LinearProgressIndicator(
                        backgroundColor: Colors.transparent,
                        color: AppColors.tandoor,
                        minHeight: 2,
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: Gap.md),

              // Report Tab Navigation Bar
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _tabButton(0, 'Sales Summary', Icons.analytics_outlined, filter.selectedTab),
                    const SizedBox(width: Gap.sm),
                    _tabButton(1, 'Items Leaderboard', Icons.restaurant_menu, filter.selectedTab),
                    const SizedBox(width: Gap.sm),
                    _tabButton(2, 'Payments Summary', Icons.payment, filter.selectedTab),
                    const SizedBox(width: Gap.sm),
                    _tabButton(3, 'GST Summary', Icons.receipt_long, filter.selectedTab),
                    const SizedBox(width: Gap.sm),
                    _tabButton(4, 'Expenses', Icons.account_balance_wallet, filter.selectedTab),
                  ],
                ),
              ),

              const SizedBox(height: Gap.lg),

              // Active Tab Content
              if (state.errorMessage != null) ...[
                _buildAlertBanner(state.errorMessage!),
                const SizedBox(height: Gap.md),
              ],

              _buildActiveTabContent(context, state, isMobile),
            ],
          ),
        );
      },
    );
  }

  Widget _scopeChip(String key, String label, String currentScope) {
    final isSelected = currentScope == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (!selected) return;
        if (key == 'custom') {
          _pickCustomDateRange();
        } else {
          ref.read(reportsControllerProvider.notifier).setScope(key);
        }
      },
      selectedColor: AppColors.tandoorSoft,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.tandoor : AppColors.ink,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      showCheckmark: false,
    );
  }

  Widget _tabButton(int index, String title, IconData icon, int activeTab) {
    final isSelected = activeTab == index;
    return InkWell(
      onTap: () => ref.read(reportsControllerProvider.notifier).setTab(index),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: Gap.md, vertical: Gap.sm),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.tandoor : AppColors.card,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.tandoor : AppColors.line,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : AppColors.muted,
            ),
            const SizedBox(width: Gap.xs),
            Text(
              title,
              style: AppText.caption.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickCustomDateRange() async {
    final current = ref.read(reportsControllerProvider).value?.filter;
    final now = DateTime.now();
    final initialRange = DateTimeRange(
      start: current?.customFrom ?? now.subtract(const Duration(days: 7)),
      end: current?.customTo ?? now,
    );

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: initialRange,
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
      ref
          .read(reportsControllerProvider.notifier)
          .setCustomDateRange(picked.start, picked.end);
    }
  }

  Widget _buildAlertBanner(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Gap.md, vertical: Gap.sm),
      decoration: BoxDecoration(
        color: AppColors.chilli.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.chilli.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.chilli, size: 18),
          const SizedBox(width: Gap.sm),
          Expanded(
            child: Text(
              message,
              style: AppText.caption.copyWith(color: AppColors.chilli),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveTabContent(
    BuildContext context,
    ReportsState state,
    bool isMobile,
  ) {
    switch (state.filter.selectedTab) {
      case 0:
        return _buildSalesTab(state.salesReport, isMobile);
      case 1:
        return _buildItemsTab(state.itemsReport);
      case 2:
        return _buildPaymentsTab(state.paymentsReport, isMobile);
      case 3:
        return _buildGstTab(state.gstReport, isMobile);
      case 4:
        return _buildExpensesTab(state.expensesReport, state.filter);
      default:
        return const SizedBox.shrink();
    }
  }

  // --- TAB 0: SALES ---
  Widget _buildSalesTab(SalesReportData? sales, bool isMobile) {
    if (sales == null) {
      return const Center(child: Text('No sales data loaded'));
    }

    final kpiCols = isMobile ? 2 : 4;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // KPI Grid
        GridView.count(
          crossAxisCount: kpiCols,
          crossAxisSpacing: Gap.md,
          mainAxisSpacing: Gap.md,
          childAspectRatio: isMobile ? 1.6 : 2.2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            BmbKpiTile(
              label: 'Gross Sales',
              value: _formatCurrency(sales.grossSales),
              icon: const Icon(Icons.currency_rupee, color: AppColors.tandoor, size: 20),
              iconBg: AppColors.tandoorSoft,
              iconFg: AppColors.tandoor,
            ),
            BmbKpiTile(
              label: 'Taxable Turnover',
              value: _formatCurrency(sales.taxableValue),
              icon: const Icon(Icons.receipt_outlined, color: AppColors.blue, size: 20),
              iconBg: AppColors.blueSoft,
              iconFg: AppColors.blue,
            ),
            BmbKpiTile(
              label: 'Total GST (5%)',
              value: _formatCurrency(sales.totalGST),
              icon: const Icon(Icons.percent, color: AppColors.leaf, size: 20),
              iconBg: AppColors.leafSoft,
              iconFg: AppColors.leaf,
            ),
            BmbKpiTile(
              label: 'Total Discounts',
              value: _formatCurrency(sales.totalDiscounts),
              icon: const Icon(Icons.discount_outlined, color: AppColors.amber, size: 20),
              iconBg: AppColors.amberSoft,
              iconFg: AppColors.amber,
            ),
          ],
        ),

        const SizedBox(height: Gap.md),

        // Secondary KPI metrics row
        Row(
          children: [
            Expanded(
              child: BmbCard(
                padding: const EdgeInsets.all(Gap.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Bills', style: AppText.caption),
                    const SizedBox(height: 4),
                    Text('${sales.totalBills}', style: AppText.h3),
                  ],
                ),
              ),
            ),
            const SizedBox(width: Gap.md),
            Expanded(
              child: BmbCard(
                padding: const EdgeInsets.all(Gap.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Average Bill Value', style: AppText.caption),
                    const SizedBox(height: 4),
                    Text(_formatCurrency(sales.avgBillValue), style: AppText.h3),
                  ],
                ),
              ),
            ),
            const SizedBox(width: Gap.md),
            Expanded(
              child: BmbCard(
                padding: const EdgeInsets.all(Gap.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Cancelled Orders', style: AppText.caption),
                    const SizedBox(height: 4),
                    Text(
                      '${sales.cancelledOrders}',
                      style: AppText.h3.copyWith(color: AppColors.chilli),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: Gap.md),

        // Channel Breakdown & Note
        BmbCard(
          padding: const EdgeInsets.all(Gap.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Order Type Breakdown',
                style: AppText.h3.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: Gap.md),
              if (sales.orderTypeSplit.isEmpty)
                Text('No order breakdown for this period', style: AppText.caption)
              else
                ...sales.orderTypeSplit.entries.map((e) {
                  final channelName = e.key.toUpperCase();
                  final item = e.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: Gap.sm),
                    child: BmbKeyValueRow(
                      label: '$channelName (${item.count} orders)',
                      value: _formatCurrency(item.amount),
                      isNumeric: true,
                    ),
                  );
                }),
              const Divider(height: 24, color: AppColors.line),
              Text(
                'Note: Figures represent exact live server totals. Cancelled orders (${sales.cancelledOrders}) are excluded from gross sales.',
                style: AppText.caption.copyWith(color: AppColors.muted),
              ),
            ],
          ),
        ),

        const SizedBox(height: Gap.md),

        // Daily trend
        if (sales.dailyTrend.isNotEmpty)
          BmbCard(
            padding: const EdgeInsets.all(Gap.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Trend',
                  style: AppText.h3.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: Gap.md),
                ...sales.dailyTrend.map((d) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(d.date, style: AppText.bodyMedium),
                        Text('${d.bills} bills', style: AppText.caption),
                        Text(
                          _formatCurrency(d.sales),
                          style: AppText.bodyStrong.copyWith(color: AppColors.tandoor),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
      ],
    );
  }

  // --- TAB 1: ITEMS LEADERBOARD ---
  Widget _buildItemsTab(ItemsReportData? itemsReport) {
    if (itemsReport == null || itemsReport.items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(Gap.xxl),
          child: Text('No item sales recorded for this period'),
        ),
      );
    }

    return BmbCard(
      padding: const EdgeInsets.all(Gap.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Dish Performance Rankings',
                style: AppText.h3.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                '${itemsReport.items.length} items sold',
                style: AppText.caption,
              ),
            ],
          ),
          const SizedBox(height: Gap.md),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: itemsReport.items.length,
            separatorBuilder: (context, index) =>
                const Divider(height: 16, color: AppColors.line),
            itemBuilder: (context, index) {
              final item = itemsReport.items[index];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: index < 3
                              ? AppColors.tandoorSoft
                              : AppColors.paper,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '#${item.rank}',
                          style: AppText.label.copyWith(
                            color: index < 3
                                ? AppColors.tandoor
                                : AppColors.muted,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: Gap.md),
                      Expanded(
                        child: Text(
                          item.name,
                          style: AppText.bodyStrong,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${item.qtySold} portions',
                        style: AppText.caption,
                      ),
                      const SizedBox(width: Gap.md),
                      Text(
                        _formatCurrency(item.revenue),
                        style: AppText.numeric.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Proportional bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (item.sharePercent / 100.0).clamp(0.0, 1.0),
                      backgroundColor: AppColors.line,
                      color: index < 3 ? AppColors.tandoor : AppColors.blue,
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${item.sharePercent.toStringAsFixed(1)}% share',
                      style: AppText.caption.copyWith(fontSize: 10),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // --- TAB 2: PAYMENTS SUMMARY ---
  Widget _buildPaymentsTab(PaymentsSummaryReportData? payments, bool isMobile) {
    if (payments == null) {
      return const Center(child: Text('No payments data loaded'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Total Collected KPI
        BmbKpiTile(
          label: 'Total Collected Across Modes',
          value: _formatCurrency(payments.totalCollected),
          icon: const Icon(Icons.account_balance_wallet, color: AppColors.leaf, size: 22),
          iconBg: AppColors.leafSoft,
          iconFg: AppColors.leaf,
        ),
        const SizedBox(height: Gap.md),

        // Unpaid / Split Note Banner
        Container(
          padding: const EdgeInsets.all(Gap.md),
          decoration: BoxDecoration(
            color: AppColors.amberSoft,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.amber.withValues(alpha: 0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline, color: AppColors.amber, size: 20),
              const SizedBox(width: Gap.sm),
              Expanded(
                child: Text(
                  'Note: Server total collected includes split payments '
                  '(${_formatCurrency(payments.splitAmount)}) and unpaid balances '
                  '(${_formatCurrency(payments.unpaidAmount)}). Totals are displayed exactly as computed by the backend.',
                  style: AppText.caption.copyWith(
                    color: AppColors.ink,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: Gap.md),

        // Breakdown by Mode
        BmbCard(
          padding: const EdgeInsets.all(Gap.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Collection by Payment Mode',
                style: AppText.h3.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: Gap.md),
              if (payments.byMode.isEmpty)
                Text('No payment records for this period', style: AppText.caption)
              else
                ...payments.byMode.map((m) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: Gap.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${m.mode.toUpperCase()} (${m.count} txns)',
                              style: AppText.bodyStrong,
                            ),
                            Text(
                              _formatCurrency(m.amount),
                              style: AppText.numeric.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: (m.sharePercent / 100.0).clamp(0.0, 1.0),
                            backgroundColor: AppColors.line,
                            color: m.mode.toLowerCase() == 'cash'
                                ? AppColors.leaf
                                : (m.mode.toLowerCase() == 'split'
                                    ? AppColors.blue
                                    : AppColors.amber),
                            minHeight: 6,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            '${m.sharePercent.toStringAsFixed(1)}% of total',
                            style: AppText.caption.copyWith(fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),

        const SizedBox(height: Gap.md),

        // Breakdown by Channel
        if (payments.byOrderType.isNotEmpty)
          BmbCard(
            padding: const EdgeInsets.all(Gap.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Collection by Order Type',
                  style: AppText.h3.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: Gap.md),
                ...payments.byOrderType.map((o) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: BmbKeyValueRow(
                      label: '${o.orderType.toUpperCase()} (${o.count} orders)',
                      value: _formatCurrency(o.amount),
                      isNumeric: true,
                    ),
                  );
                }),
              ],
            ),
          ),
      ],
    );
  }

  // --- TAB 3: GST SUMMARY ---
  Widget _buildGstTab(GstSummaryReportData? gst, bool isMobile) {
    if (gst == null) {
      return const Center(child: Text('No GST summary data loaded'));
    }

    final kpiCols = isMobile ? 2 : 4;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // GST KPIs
        GridView.count(
          crossAxisCount: kpiCols,
          crossAxisSpacing: Gap.md,
          mainAxisSpacing: Gap.md,
          childAspectRatio: isMobile ? 1.6 : 2.2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            BmbKpiTile(
              label: 'Taxable Turnover',
              value: _formatCurrency(gst.taxableValue),
              icon: const Icon(Icons.receipt, color: AppColors.blue, size: 20),
              iconBg: AppColors.blueSoft,
              iconFg: AppColors.blue,
            ),
            BmbKpiTile(
              label: 'CGST (2.5%)',
              value: _formatCurrency(gst.cgst),
              icon: const Icon(Icons.percent, color: AppColors.leaf, size: 20),
              iconBg: AppColors.leafSoft,
              iconFg: AppColors.leaf,
            ),
            BmbKpiTile(
              label: 'SGST (2.5%)',
              value: _formatCurrency(gst.sgst),
              icon: const Icon(Icons.percent, color: AppColors.leaf, size: 20),
              iconBg: AppColors.leafSoft,
              iconFg: AppColors.leaf,
            ),
            BmbKpiTile(
              label: 'Total GST (${gst.gstRatePercent.toStringAsFixed(0)}%)',
              value: _formatCurrency(gst.totalGST),
              icon: const Icon(Icons.account_balance, color: AppColors.tandoor, size: 20),
              iconBg: AppColors.tandoorSoft,
              iconFg: AppColors.tandoor,
            ),
          ],
        ),

        const SizedBox(height: Gap.md),

        // Paged Bills Table
        BmbCard(
          padding: const EdgeInsets.all(Gap.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Invoiced Bills (Filing Schedule)',
                    style: AppText.h3.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${gst.total} bills total',
                    style: AppText.caption,
                  ),
                ],
              ),
              const SizedBox(height: Gap.md),
              if (gst.bills.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: Gap.xxl),
                  child: Center(child: Text('No billed transactions in this date range')),
                )
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStatePropertyAll(
                      AppColors.line.withValues(alpha: 0.2),
                    ),
                    columns: const [
                      DataColumn(label: Text('Bill No')),
                      DataColumn(label: Text('Order No')),
                      DataColumn(label: Text('Paid Date')),
                      DataColumn(label: Text('Taxable')),
                      DataColumn(label: Text('CGST')),
                      DataColumn(label: Text('SGST')),
                      DataColumn(label: Text('Grand Total')),
                    ],
                    rows: gst.bills.map((b) {
                      return DataRow(
                        cells: [
                          DataCell(Text(b.billNo, style: AppText.bodyStrong)),
                          DataCell(Text(b.orderNo, style: AppText.caption)),
                          DataCell(Text(_formatDate(b.paidAt), style: AppText.caption)),
                          DataCell(Text(_formatCurrency(b.taxableValue))),
                          DataCell(Text(_formatCurrency(b.cgst))),
                          DataCell(Text(_formatCurrency(b.sgst))),
                          DataCell(
                            Text(
                              _formatCurrency(b.grandTotal),
                              style: AppText.bodyStrong.copyWith(color: AppColors.leaf),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),

              const SizedBox(height: Gap.md),

              // Pagination Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Page ${gst.page} of ${gst.totalPages}',
                    style: AppText.caption,
                  ),
                  Row(
                    children: [
                      OutlinedButton(
                        key: const Key('gst_prev_page'),
                        onPressed: gst.page > 1
                            ? () => ref
                                .read(reportsControllerProvider.notifier)
                                .setGstPage(gst.page - 1)
                            : null,
                        child: const Text('Previous'),
                      ),
                      const SizedBox(width: Gap.sm),
                      OutlinedButton(
                        key: const Key('gst_next_page'),
                        onPressed: gst.page < gst.totalPages
                            ? () => ref
                                .read(reportsControllerProvider.notifier)
                                .setGstPage(gst.page + 1)
                            : null,
                        child: const Text('Next'),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- TAB 4: EXPENSES ---
  Widget _buildExpensesTab(ExpensesReportData? expenses, ReportsFilter filter) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Category Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _expenseCategoryChip('all', 'All Categories', filter.expenseCategory),
              const SizedBox(width: Gap.sm),
              _expenseCategoryChip('Supplies', 'Supplies', filter.expenseCategory),
              const SizedBox(width: Gap.sm),
              _expenseCategoryChip('Utilities', 'Utilities', filter.expenseCategory),
              const SizedBox(width: Gap.sm),
              _expenseCategoryChip('Rent', 'Rent', filter.expenseCategory),
              const SizedBox(width: Gap.sm),
              _expenseCategoryChip('Salaries', 'Salaries', filter.expenseCategory),
              const SizedBox(width: Gap.sm),
              _expenseCategoryChip('Other', 'Other', filter.expenseCategory),
            ],
          ),
        ),

        const SizedBox(height: Gap.md),

        // Total Expenses KPI
        BmbKpiTile(
          label: 'Total Expenses',
          value: _formatCurrency(expenses?.totalExpenses ?? 0.0),
          icon: const Icon(Icons.receipt_outlined, color: AppColors.chilli, size: 22),
          iconBg: AppColors.chilliSoft,
          iconFg: AppColors.chilli,
        ),

        const SizedBox(height: Gap.md),

        BmbCard(
          padding: const EdgeInsets.all(Gap.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.folder_open_outlined,
                size: 48,
                color: AppColors.muted,
              ),
              const SizedBox(height: Gap.md),
              Text(
                'No expense records found',
                style: AppText.h3,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Gap.sm),
              Text(
                'Expense entries can be filtered by category. Note that expenses currently do not have a dedicated creation endpoint in this API.',
                style: AppText.bodyMedium.copyWith(color: AppColors.muted),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _expenseCategoryChip(String key, String label, String? activeCategory) {
    final isSelected = (activeCategory == null && key == 'all') ||
        (activeCategory == key);
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (!selected) return;
        ref
            .read(reportsControllerProvider.notifier)
            .setExpenseCategory(key == 'all' ? null : key);
      },
      selectedColor: AppColors.blueSoft,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.blue : AppColors.ink,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      showCheckmark: false,
    );
  }
}
