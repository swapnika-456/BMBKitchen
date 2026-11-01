import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/widgets/bmb_card.dart';
import '../../../core/widgets/bmb_key_value_row.dart';
import '../../../core/widgets/bmb_kpi_tile.dart';
import '../../../models/dashboard_models.dart';
import '../../settings/controllers/active_outlet_provider.dart';
import '../controllers/dashboard_controller.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with WidgetsBindingObserver {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // 60-second periodic refresh while screen is mounted & visible
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (mounted) {
        ref.read(dashboardControllerProvider.notifier).refresh();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    if (lifecycleState == AppLifecycleState.resumed) {
      ref.read(dashboardControllerProvider.notifier).refresh();
    }
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: amount % 1 == 0 ? 0 : 2,
    );
    return formatter.format(amount);
  }

  Future<void> _pickCustomDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: DateTimeRange(
        start: now.subtract(const Duration(days: 7)),
        end: now,
      ),
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
      await ref
          .read(dashboardControllerProvider.notifier)
          .setCustomDateRange(picked.start, picked.end);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(dashboardControllerProvider);
    final activeOutlet = ref.watch(activeOutletProvider);
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 900;

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: dashboardAsync.when(
        loading: () => _buildLoadingSkeleton(isMobile),
        error: (err, stack) => _buildErrorState(err.toString()),
        data: (state) {
          if (state.errorMessage != null && state.summary == null) {
            return _buildErrorState(state.errorMessage!);
          }

          final summary = state.summary;
          final filter = state.filter;

          return RefreshIndicator(
            onRefresh: () =>
                ref.read(dashboardControllerProvider.notifier).refresh(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(Gap.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  _buildHeader(context, activeOutlet?.name ?? 'Main Outlet',
                      state.isLoading),

                  const SizedBox(height: Gap.md),

                  // Scope Filter Chips
                  _buildScopeFilter(context, filter),

                  const SizedBox(height: Gap.lg),

                  // Quick Stats (Tables, Kitchen Queue, Low Stock, Day Closing)
                  if (summary != null)
                    _buildQuickStatsSection(context, summary.quickStats, isMobile),

                  const SizedBox(height: Gap.lg),

                  // Empty State Check
                  if (summary == null ||
                      (summary.salesKpis.totalSales == 0 &&
                          summary.salesKpis.orders == 0))
                    _buildEmptyState()
                  else ...[
                    // KPI Cards Grid (4 KPIs)
                    _buildSalesKpisSection(summary.salesKpis, isMobile),

                    const SizedBox(height: Gap.lg),

                    // Sales Trend Chart (Proportional Bars)
                    _buildSalesTrendSection(summary.salesTrend, isMobile),

                    const SizedBox(height: Gap.lg),

                    // Middle Row: Kitchen Tickets + Top Items
                    _buildMiddleSection(
                      summary.kitchenTicketStatus,
                      summary.topSellingItems,
                      isMobile,
                    ),

                    const SizedBox(height: Gap.lg),

                    // Bottom Row: Payment Summary + Order Type Breakdown
                    _buildBottomSection(
                      summary.paymentSummary,
                      summary.salesByOrderType,
                      isMobile,
                    ),
                  ],

                  const SizedBox(height: Gap.xxl),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String outletName, bool isLoading) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dashboard',
                style: AppText.h2.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(Icons.storefront_outlined,
                      size: 14, color: AppColors.muted),
                  const SizedBox(width: 4),
                  Text(
                    outletName,
                    style: AppText.caption.copyWith(color: AppColors.muted),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: Gap.sm),
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        IconButton(
          key: const Key('dashboard_refresh_btn'),
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh Dashboard',
          onPressed: () =>
              ref.read(dashboardControllerProvider.notifier).refresh(),
        ),
      ],
    );
  }

  Widget _buildScopeFilter(BuildContext context, DashboardFilter filter) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _scopeChip('today', 'Today', filter.scope),
          const SizedBox(width: Gap.sm),
          _scopeChip('week', 'This Week', filter.scope),
          const SizedBox(width: Gap.sm),
          _scopeChip('month', 'This Month', filter.scope),
          const SizedBox(width: Gap.sm),
          _scopeChip('year', 'This Year', filter.scope),
          const SizedBox(width: Gap.sm),
          _scopeChip('custom', 'Custom', filter.scope, onCustomTap: _pickCustomDateRange),
        ],
      ),
    );
  }

  Widget _scopeChip(
    String key,
    String label,
    String currentScope, {
    VoidCallback? onCustomTap,
  }) {
    final isSelected = currentScope == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        if (key == 'custom') {
          if (onCustomTap != null) onCustomTap();
        } else {
          ref.read(dashboardControllerProvider.notifier).setScope(key);
        }
      },
      selectedColor: AppColors.tandoorSoft,
      backgroundColor: AppColors.card,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.tandoor : AppColors.ink,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      showCheckmark: false,
    );
  }

  // --- QUICK STATS (TABLES, KITCHEN QUEUE, LOW STOCK, DAY CLOSING) ---
  Widget _buildQuickStatsSection(
    BuildContext context,
    DashboardQuickStats stats,
    bool isMobile,
  ) {
    final cols = isMobile ? 2 : 4;
    return GridView.count(
      crossAxisCount: cols,
      crossAxisSpacing: Gap.md,
      mainAxisSpacing: Gap.md,
      childAspectRatio: isMobile ? 1.8 : 2.4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _quickStatTile(
          context,
          key: const Key('quick_stat_tables'),
          label: 'Tables Occupancy',
          value: '${stats.tablesOccupied}/${stats.tablesTotal}',
          subtext: 'Tables Occupied',
          icon: Icons.table_restaurant_outlined,
          color: AppColors.blue,
          route: '/tables',
        ),
        _quickStatTile(
          context,
          key: const Key('quick_stat_kitchen_queue'),
          label: 'Kitchen Queue',
          value: '${stats.kitchenQueueCount}',
          subtext: 'Items in Queue',
          icon: Icons.soup_kitchen_outlined,
          color: AppColors.amber,
          route: '/kitchen',
        ),
        _quickStatTile(
          context,
          key: const Key('quick_stat_low_stock'),
          label: 'Low Stock Alerts',
          value: '${stats.lowStockCount}',
          subtext: 'Items Below Min',
          icon: Icons.inventory_2_outlined,
          color: stats.lowStockCount > 0 ? AppColors.chilli : AppColors.leaf,
          route: '/stock',
        ),
        _quickStatTile(
          context,
          key: const Key('quick_stat_day_closing'),
          label: 'Day Closing',
          value: stats.dayClosingStatus,
          subtext: stats.dayClosingDifference != null
              ? 'Diff: ${_formatCurrency(stats.dayClosingDifference!)}'
              : 'End of Day',
          icon: Icons.point_of_sale_outlined,
          color: stats.dayClosingStatus.toLowerCase() == 'completed'
              ? AppColors.leaf
              : AppColors.tandoor,
          route: '/closing',
        ),
      ],
    );
  }

  Widget _quickStatTile(
    BuildContext context, {
    required Key key,
    required String label,
    required String value,
    required String subtext,
    required IconData icon,
    required Color color,
    required String route,
  }) {
    return InkWell(
      key: key,
      onTap: () => context.go(route),
      borderRadius: BorderRadius.circular(12),
      child: BmbCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: Gap.md),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: AppText.h3.copyWith(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtext,
                    style: AppText.caption.copyWith(color: AppColors.muted),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 16, color: AppColors.muted),
          ],
        ),
      ),
    );
  }

  // --- SALES KPIS SECTION ---
  Widget _buildSalesKpisSection(DashboardSalesKpis kpis, bool isMobile) {
    final cols = isMobile ? 2 : 4;
    return GridView.count(
      crossAxisCount: cols,
      crossAxisSpacing: Gap.md,
      mainAxisSpacing: Gap.md,
      childAspectRatio: isMobile ? 1.5 : 2.2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        BmbKpiTile(
          label: 'Total Sales',
          value: _formatCurrency(kpis.totalSales),
          icon: const Icon(Icons.currency_rupee, color: AppColors.tandoor, size: 20),
          iconBg: AppColors.tandoorSoft,
          iconFg: AppColors.tandoor,
          deltaPct: kpis.deltaVsPrevious?.salesPercent,
          deltaPeriod: 'vs yesterday',
        ),
        BmbKpiTile(
          label: 'Orders Count',
          value: '${kpis.orders}',
          icon: const Icon(Icons.receipt_long_outlined, color: AppColors.blue, size: 20),
          iconBg: AppColors.blueSoft,
          iconFg: AppColors.blue,
          deltaPct: kpis.deltaVsPrevious?.ordersPercent,
          deltaPeriod: 'vs yesterday',
        ),
        BmbKpiTile(
          label: 'Average Bill',
          value: _formatCurrency(kpis.avgBillValue),
          icon: const Icon(Icons.analytics_outlined, color: AppColors.leaf, size: 20),
          iconBg: AppColors.leafSoft,
          iconFg: AppColors.leaf,
          deltaPct: kpis.deltaVsPrevious?.avgBillPercent,
          deltaPeriod: 'vs yesterday',
        ),
        BmbKpiTile(
          label: 'Expenses',
          value: _formatCurrency(kpis.expenses),
          icon: const Icon(Icons.money_off_outlined, color: AppColors.chilli, size: 20),
          iconBg: AppColors.chilliSoft,
          iconFg: AppColors.chilli,
          deltaPct: kpis.deltaVsPrevious?.expensesPercent,
          deltaPeriod: 'vs yesterday',
        ),
      ],
    );
  }

  // --- SALES TREND CHART ---
  Widget _buildSalesTrendSection(DashboardSalesTrend trend, bool isMobile) {
    final pointsWithSales = trend.points.where((p) => p.sales > 0).toList();
    final maxSale = trend.points.fold<double>(
      0.0,
      (max, p) => p.sales > max ? p.sales : max,
    );

    return BmbCard(
      padding: const EdgeInsets.all(Gap.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                trend.granularity == 'hour'
                    ? 'Hourly Sales Trend'
                    : 'Daily Sales Distribution',
                style: AppText.h3.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                '${trend.points.length} data points',
                style: AppText.caption,
              ),
            ],
          ),
          const SizedBox(height: Gap.md),
          if (pointsWithSales.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Gap.xl),
              child: Center(
                child: Text('No sales activity recorded in this period',
                    style: AppText.caption),
              ),
            )
          else
            Column(
              children: [
                ...pointsWithSales.map((pt) {
                  final ratio = maxSale > 0 ? (pt.sales / maxSale) : 0.0;
                  final label = trend.granularity == 'hour'
                      ? '${pt.key.padLeft(2, '0')}:00'
                      : pt.key;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(label, style: AppText.bodyMedium),
                            Text(
                              '${pt.orders} orders • ${_formatCurrency(pt.sales)}',
                              style: AppText.bodyStrong.copyWith(color: AppColors.tandoor),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: ratio.clamp(0.0, 1.0),
                            backgroundColor: AppColors.line,
                            color: AppColors.tandoor,
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
        ],
      ),
    );
  }

  // --- MIDDLE SECTION: KITCHEN STATUS & TOP ITEMS ---
  Widget _buildMiddleSection(
    DashboardKitchenTicketStatus kitchen,
    DashboardTopSellingItems topItems,
    bool isMobile,
  ) {
    if (isMobile) {
      return Column(
        children: [
          _buildKitchenStatusCard(kitchen),
          const SizedBox(height: Gap.lg),
          _buildTopItemsCard(topItems),
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildKitchenStatusCard(kitchen)),
        const SizedBox(width: Gap.lg),
        Expanded(child: _buildTopItemsCard(topItems)),
      ],
    );
  }

  Widget _buildKitchenStatusCard(DashboardKitchenTicketStatus kitchen) {
    return BmbCard(
      padding: const EdgeInsets.all(Gap.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Kitchen Tickets Status',
                  style: AppText.h3.copyWith(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: Gap.sm),
              Text(
                '${kitchen.total} total',
                style: AppText.caption,
              ),
            ],
          ),
          const SizedBox(height: Gap.md),
          _ticketRow('Completed', kitchen.completed, AppColors.leaf),
          _ticketRow('Preparing', kitchen.preparing, AppColors.amber),
          _ticketRow('Ready for Pickup', kitchen.ready, AppColors.blue),
          _ticketRow('Cancelled', kitchen.cancelled, AppColors.chilli),
          const Divider(height: 24, color: AppColors.line),
          BmbKeyValueRow(
            label: 'Total Tickets Logged',
            value: '${kitchen.total}',
            isNumeric: true,
          ),
        ],
      ),
    );
  }

  Widget _ticketRow(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: Gap.sm),
                Flexible(
                  child: Text(
                    label,
                    style: AppText.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: Gap.sm),
          Text('$count', style: AppText.bodyStrong),
        ],
      ),
    );
  }

  Widget _buildTopItemsCard(DashboardTopSellingItems topItems) {
    return BmbCard(
      padding: const EdgeInsets.all(Gap.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Top-Selling Items',
                  style: AppText.h3.copyWith(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: Gap.sm),
              Text(
                '${topItems.items.length} items',
                style: AppText.caption,
              ),
            ],
          ),
          const SizedBox(height: Gap.md),
          if (topItems.items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Gap.lg),
              child: Center(
                child: Text('No item sales in this period', style: AppText.caption),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: topItems.items.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: 16, color: AppColors.line),
              itemBuilder: (context, index) {
                final item = topItems.items[index];
                return Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: index == 0
                            ? AppColors.tandoorSoft
                            : AppColors.paper,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '#${index + 1}',
                        style: AppText.label.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: index == 0
                              ? AppColors.tandoor
                              : AppColors.muted,
                        ),
                      ),
                    ),
                    const SizedBox(width: Gap.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.name,
                              style: AppText.bodyStrong,
                              overflow: TextOverflow.ellipsis),
                          Text('${item.qty} portions sold',
                              style: AppText.caption),
                        ],
                      ),
                    ),
                    Text(
                      _formatCurrency(item.amount),
                      style: AppText.bodyStrong.copyWith(color: AppColors.ink),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  // --- BOTTOM SECTION: PAYMENT SUMMARY & ORDER TYPES ---
  Widget _buildBottomSection(
    DashboardPaymentSummary payment,
    DashboardSalesByOrderType? orderTypes,
    bool isMobile,
  ) {
    if (isMobile) {
      return Column(
        children: [
          _buildPaymentSummaryCard(payment),
          if (orderTypes != null && orderTypes.byOrderType.isNotEmpty) ...[
            const SizedBox(height: Gap.lg),
            _buildOrderTypesCard(orderTypes),
          ],
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildPaymentSummaryCard(payment)),
        if (orderTypes != null && orderTypes.byOrderType.isNotEmpty) ...[
          const SizedBox(width: Gap.lg),
          Expanded(child: _buildOrderTypesCard(orderTypes)),
        ],
      ],
    );
  }

  Widget _buildPaymentSummaryCard(DashboardPaymentSummary payment) {
    return BmbCard(
      padding: const EdgeInsets.all(Gap.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Payment Collections',
                  style: AppText.h3.copyWith(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: Gap.sm),
              Text(
                _formatCurrency(payment.totalCollected),
                style: AppText.h3.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.leaf,
                ),
              ),
            ],
          ),
          const SizedBox(height: Gap.md),
          if (payment.byMode.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Gap.lg),
              child: Center(
                child: Text('No payment collections recorded', style: AppText.caption),
              ),
            )
          else ...[
            ...payment.byMode.map((m) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            m.mode.toUpperCase(),
                            style: AppText.bodyMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: Gap.sm),
                        Flexible(
                          child: Text(
                            '${_formatCurrency(m.amount)} (${m.sharePercent.toStringAsFixed(1)}%)',
                            style: AppText.bodyStrong,
                            textAlign: TextAlign.end,
                            overflow: TextOverflow.ellipsis,
                          ),
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
                  ],
                ),
              );
            }),
            const Divider(height: 24, color: AppColors.line),
            Text(
              'Note: Figures represent backend live collections including split and unpaid modes.',
              style: AppText.caption.copyWith(color: AppColors.muted),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOrderTypesCard(DashboardSalesByOrderType orderTypes) {
    return BmbCard(
      padding: const EdgeInsets.all(Gap.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Sales by Order Type',
                  style: AppText.h3.copyWith(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: Gap.sm),
              Text(
                _formatCurrency(orderTypes.totalSales),
                style: AppText.h3.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: Gap.md),
          ...orderTypes.byOrderType.map((ot) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          ot.orderType.toUpperCase(),
                          style: AppText.bodyMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: Gap.sm),
                      Flexible(
                        child: Text(
                          '${ot.orders} orders • ${_formatCurrency(ot.amount)} (${ot.sharePercent.toStringAsFixed(1)}%)',
                          style: AppText.bodyStrong,
                          textAlign: TextAlign.end,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (ot.sharePercent / 100.0).clamp(0.0, 1.0),
                      backgroundColor: AppColors.line,
                      color: ot.orderType.toLowerCase() == 'takeaway'
                          ? AppColors.tandoor
                          : AppColors.blue,
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return BmbCard(
      padding: const EdgeInsets.all(Gap.xxl),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.analytics_outlined, size: 56, color: AppColors.muted),
            const SizedBox(height: Gap.md),
            Text('No sales in this period',
                style: AppText.h3.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: Gap.xs),
            Text(
              'Switch to another date scope or record orders via POS.',
              style: AppText.caption.copyWith(color: AppColors.muted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Gap.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.chilli),
            const SizedBox(height: Gap.md),
            Text('Failed to load dashboard', style: AppText.h3),
            const SizedBox(height: Gap.xs),
            Text(message,
                style: AppText.caption.copyWith(color: AppColors.muted),
                textAlign: TextAlign.center),
            const SizedBox(height: Gap.lg),
            ElevatedButton.icon(
              key: const Key('dashboard_retry_btn'),
              onPressed: () =>
                  ref.read(dashboardControllerProvider.notifier).refresh(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton(bool isMobile) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}
