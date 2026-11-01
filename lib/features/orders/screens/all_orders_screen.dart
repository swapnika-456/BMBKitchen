import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/bmb_button.dart';
import '../../../core/widgets/bmb_card.dart';
import '../../../core/widgets/bmb_empty_state.dart';
import '../../../core/widgets/bmb_skeleton.dart';
import '../../../models/order.dart';
import '../../pos/controllers/pos_order_controller.dart';
import '../../settings/controllers/active_outlet_provider.dart';
import '../controllers/paid_orders_controller.dart';
import '../widgets/order_detail_sheet.dart';

class AllOrdersScreen extends ConsumerStatefulWidget {
  final String? initialOrderId;

  const AllOrdersScreen({super.key, this.initialOrderId});

  @override
  ConsumerState<AllOrdersScreen> createState() => _AllOrdersScreenState();
}

class _AllOrdersScreenState extends ConsumerState<AllOrdersScreen> {
  int _currentTab = 0; // 0: Active (#44), 1: Paid (#51C)
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialOrderId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        OrderDetailSheet.show(context, widget.initialOrderId!);
      });
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
      initialDateRange: DateTimeRange(
        start: now.subtract(const Duration(days: 7)),
        end: now,
      ),
    );

    if (picked != null) {
      final fromStr = '${picked.start.year}-${picked.start.month.toString().padLeft(2, '0')}-${picked.start.day.toString().padLeft(2, '0')}';
      final toStr = '${picked.end.year}-${picked.end.month.toString().padLeft(2, '0')}-${picked.end.day.toString().padLeft(2, '0')}';
      ref.read(paidOrdersControllerProvider.notifier).setDateRange(fromStr, toStr);
    }
  }

  void _clearDateRange() {
    ref.read(paidOrdersControllerProvider.notifier).setDateRange(null, null);
  }

  @override
  Widget build(BuildContext context) {
    final activeOutlet = ref.watch(activeOutletProvider);
    final activeOrdersAsync = ref.watch(activeOrdersProvider);
    final activeCount = activeOrdersAsync.value?.length ?? 0;

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar with Outlet
            _buildTopBar(activeOutlet),
            // PDF Gap Notice Banner
            _buildGapNoticeBanner(),
            // Tabs: Active vs Paid
            _buildTabBar(activeCount),
            const Divider(height: 1),
            // Tab View
            Expanded(
              child: _currentTab == 0 ? _buildActiveOrdersTab() : _buildPaidOrdersTab(),
            ),
          ],
        ),
      ),
    );
  }

  // --- Top Bar ---
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
              color: AppColors.tandoorSoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.receipt_long, color: AppColors.tandoor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('All Orders', style: AppText.h2),
                Text(
                  activeOutlet != null ? '${activeOutlet.name} (${activeOutlet.code})' : 'Order Management',
                  style: AppText.caption.copyWith(color: AppColors.muted),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              if (_currentTab == 0) {
                ref.read(activeOrdersProvider.notifier).refresh();
              } else {
                ref.read(paidOrdersControllerProvider.notifier).refresh();
              }
            },
          ),
        ],
      ),
    );
  }

  // --- Gap Notice Banner ---
  Widget _buildGapNoticeBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      color: AppColors.amberSoft.withValues(alpha: 0.5),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 16, color: AppColors.amber),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'API Gap: The API PDF has no endpoint to list cancelled orders across all types.',
              style: TextStyle(fontSize: 11, color: AppColors.ink.withValues(alpha: 0.8)),
            ),
          ),
        ],
      ),
    );
  }

  // --- Tab Bar ---
  Widget _buildTabBar(int activeCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.card,
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _currentTab = 0),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _currentTab == 0 ? AppColors.tandoorSoft : AppColors.inputFill,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _currentTab == 0 ? AppColors.tandoor : AppColors.line),
                ),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Active Orders (#44)',
                            style: TextStyle(
                              fontWeight: _currentTab == 0 ? FontWeight.bold : FontWeight.normal,
                              color: _currentTab == 0 ? AppColors.tandoor : AppColors.ink,
                              fontSize: 13,
                            ),
                          ),
                          if (activeCount > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _currentTab == 0 ? AppColors.tandoor : AppColors.muted,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$activeCount',
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _currentTab = 1),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _currentTab == 1 ? AppColors.leafSoft : AppColors.inputFill,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _currentTab == 1 ? AppColors.leaf : AppColors.line),
                ),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        'Paid Orders (#51C)',
                        style: TextStyle(
                          fontWeight: _currentTab == 1 ? FontWeight.bold : FontWeight.normal,
                          color: _currentTab == 1 ? AppColors.leaf : AppColors.ink,
                          fontSize: 13,
                        ),
                      ),
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

  // ===========================================================================
  // TAB 0: ACTIVE ORDERS (#44)
  // ===========================================================================
  Widget _buildActiveOrdersTab() {
    final activeOrdersAsync = ref.watch(activeOrdersProvider);

    return RefreshIndicator(
      onRefresh: () => ref.read(activeOrdersProvider.notifier).refresh(),
      child: activeOrdersAsync.when(
        data: (orders) {
          if (orders.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.5,
                  child: const Center(
                    child: BmbEmptyState(
                      title: 'No Active Orders',
                      description: 'There are no active orders running right now.',
                      icon: Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.muted),
                    ),
                  ),
                ),
              ],
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (ctx, i) => const SizedBox(height: 12),
            itemBuilder: (ctx, i) => _buildOrderCard(orders[i]),
          );
        },
        loading: () => _buildLoadingSkeleton(),
        error: (e, _) => ListView(
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
                      Text('Error loading active orders: $e',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.chilli)),
                      const SizedBox(height: 16),
                      BmbButton(
                        label: 'Retry',
                        onPressed: () => ref.read(activeOrdersProvider.notifier).refresh(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // TAB 1: PAID ORDERS (#51C)
  // ===========================================================================
  Widget _buildPaidOrdersTab() {
    final paidOrdersAsync = ref.watch(paidOrdersControllerProvider);
    final filter = ref.watch(paidOrdersFilterProvider);
    final notifier = ref.read(paidOrdersControllerProvider.notifier);

    return Column(
      children: [
        // Filter & Search Controls
        _buildPaidOrdersFilterBar(filter, notifier),
        const Divider(height: 1),
        // List with Pull-to-Refresh & Pagination
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => notifier.refresh(),
            child: paidOrdersAsync.when(
              data: (data) {
                return Column(
                  children: [
                    // Summary KPIs if available
                    if (data.summary != null) _buildSummaryKpis(data.summary!),
                    // Orders List
                    Expanded(
                      child: data.orders.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                SizedBox(
                                  height: MediaQuery.of(context).size.height * 0.4,
                                  child: const Center(
                                    child: BmbEmptyState(
                                      title: 'No Paid Orders',
                                      description: 'No paid orders match the selected filters.',
                                      icon: Icon(Icons.payments_outlined, size: 48, color: AppColors.muted),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: data.orders.length,
                              separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                              itemBuilder: (ctx, i) => _buildOrderCard(data.orders[i]),
                            ),
                    ),
                    _buildPaidPaginationBar(data, filter, notifier),
                  ],
                );
              },
              loading: () => _buildLoadingSkeleton(),
              error: (e, _) => ListView(
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
                            Text('Error loading paid orders: $e',
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
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- Paid Orders Filter Bar ---
  Widget _buildPaidOrdersFilterBar(PaidOrdersFilter filter, PaidOrdersController notifier) {
    final scopes = [
      {'key': 'today', 'label': 'Today'},
      {'key': 'week', 'label': 'Week'},
      {'key': 'month', 'label': 'Month'},
      {'key': 'year', 'label': 'Year'},
      {'key': 'all', 'label': 'All'},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Search & Date Range
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Search orderNo / billNo',
                      prefixIcon: const Icon(Icons.search, size: 18),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed: () {
                                _searchCtrl.clear();
                                notifier.setSearch(null);
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.line)),
                      isDense: true,
                    ),
                    onSubmitted: (val) => notifier.setSearch(val.trim().isEmpty ? null : val.trim()),
                  ),
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
                  filter.from != null ? '${filter.from} to ${filter.to}' : 'Dates',
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
          const SizedBox(height: 8),
          // Row 2: Scope Tabs & Order Type & Payment Method
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Scopes
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.inputFill,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Row(
                    children: scopes.map((s) {
                      final isSel = filter.scope == s['key'];
                      return InkWell(
                        onTap: () => notifier.setScope(s['key']!),
                        borderRadius: BorderRadius.circular(7),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: isSel ? AppColors.tandoor : Colors.transparent,
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Text(
                            s['label']!,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                              color: isSel ? Colors.white : AppColors.ink,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(width: 10),
                // Order Type
                Text('Type:', style: AppText.caption.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(width: 4),
                _buildChipFilter(null, 'All', filter.orderType, (val) => notifier.setOrderType(val)),
                const SizedBox(width: 4),
                _buildChipFilter('dine_in', 'Dine-in', filter.orderType, (val) => notifier.setOrderType(val)),
                const SizedBox(width: 4),
                _buildChipFilter('takeaway', 'Takeaway', filter.orderType, (val) => notifier.setOrderType(val)),
                const SizedBox(width: 4),
                _buildChipFilter('delivery', 'Delivery', filter.orderType, (val) => notifier.setOrderType(val)),
                const SizedBox(width: 4),
                _buildChipFilter('online', 'Online', filter.orderType, (val) => notifier.setOrderType(val)),
                const SizedBox(width: 10),
                // Payment Method
                Text('Pay:', style: AppText.caption.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(width: 4),
                _buildChipFilter(null, 'All', filter.paymentMethod, (val) => notifier.setPaymentMethod(val)),
                const SizedBox(width: 4),
                _buildChipFilter('cash', 'Cash', filter.paymentMethod, (val) => notifier.setPaymentMethod(val)),
                const SizedBox(width: 4),
                _buildChipFilter('card', 'Card', filter.paymentMethod, (val) => notifier.setPaymentMethod(val)),
                const SizedBox(width: 4),
                _buildChipFilter('upi', 'UPI', filter.paymentMethod, (val) => notifier.setPaymentMethod(val)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChipFilter(String? value, String label, String? currentValue, Function(String?) onSelected) {
    final isSel = currentValue == value;
    return ChoiceChip(
      selected: isSel,
      selectedColor: AppColors.tandoorSoft,
      backgroundColor: AppColors.inputFill,
      side: BorderSide(color: isSel ? AppColors.tandoor : AppColors.line),
      label: Text(label, style: TextStyle(color: isSel ? AppColors.tandoor : AppColors.ink, fontSize: 11, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
      onSelected: (_) => onSelected(value),
    );
  }

  // --- Summary KPIs Card ---
  Widget _buildSummaryKpis(PaidOrdersSummary sum) {
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
            _buildKpiItem('COLLECTED', '₹${sum.totalCollected.toStringAsFixed(0)}', AppColors.leaf),
            const SizedBox(width: 24),
            _buildKpiItem('PAID ORDERS', '${sum.totalOrders}', AppColors.ink),
            const SizedBox(width: 24),
            _buildKpiItem('AVG VALUE', '₹${sum.avgOrderValue.toStringAsFixed(0)}', AppColors.tandoor),
            const SizedBox(width: 24),
            _buildKpiItem('DISCOUNTS', '₹${sum.totalDiscounts.toStringAsFixed(0)}', AppColors.muted),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiItem(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.muted, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  // --- Single Order Card ---
  Widget _buildOrderCard(Order order) {
    return InkWell(
      onTap: () => OrderDetailSheet.show(context, order.id),
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
                      Text('Order #${order.orderNo}', style: AppText.body.copyWith(fontWeight: FontWeight.bold)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.inputFill,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(order.orderType.toUpperCase(), style: const TextStyle(fontSize: 10, color: AppColors.muted, fontWeight: FontWeight.bold)),
                      ),
                      if (order.tableName != null && order.tableName!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: AppColors.blueSoft, borderRadius: BorderRadius.circular(4)),
                          child: Text(order.tableName!, style: const TextStyle(fontSize: 10, color: AppColors.blue, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '₹${order.grandTotal.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.tandoor),
                ),
              ],
            ),
            if (order.billNo != null && order.billNo!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Bill: ${order.billNo}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.ink)),
            ],
            const SizedBox(height: 6),
            Text(
              '${order.items.length} item${order.items.length == 1 ? '' : 's'}: ${order.items.map((i) => "${i.quantity}x ${i.name}").join(', ')}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppText.caption.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              runSpacing: 4,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _buildStatusChip(order.orderStatus),
                    _buildPaymentStatusChip(order.paymentStatus),
                    if (order.paymentMethod != null && order.paymentMethod!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.inputFill, borderRadius: BorderRadius.circular(4)),
                        child: Text(order.paymentMethod!.toUpperCase(), style: const TextStyle(fontSize: 10, color: AppColors.muted, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (order.createdAt != null)
                      Text(
                        '${order.createdAt!.hour.toString().padLeft(2, '0')}:${order.createdAt!.minute.toString().padLeft(2, '0')}',
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

  Widget _buildPaidPaginationBar(PaidOrdersResponse data, PaidOrdersFilter filter, PaidOrdersController notifier) {
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
            'Showing ${data.orders.length} of ${data.total} paid orders',
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

  Widget _buildStatusChip(String status) {
    Color bg = AppColors.inputFill;
    Color text = AppColors.ink;
    switch (status.toLowerCase()) {
      case 'active':
        bg = AppColors.tandoorSoft;
        text = AppColors.tandoor;
        break;
      case 'completed':
        bg = AppColors.leafSoft;
        text = AppColors.leaf;
        break;
      case 'cancelled':
        bg = AppColors.chilliSoft;
        text = AppColors.chilli;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(status.toUpperCase(), style: TextStyle(color: text, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildPaymentStatusChip(String status) {
    Color bg = AppColors.inputFill;
    Color text = AppColors.ink;
    switch (status.toLowerCase()) {
      case 'paid':
        bg = AppColors.leafSoft;
        text = AppColors.leaf;
        break;
      case 'pending':
        bg = AppColors.amberSoft;
        text = AppColors.amber;
        break;
      case 'partially_paid':
        bg = AppColors.amberSoft;
        text = AppColors.amber;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(status.toUpperCase(), style: TextStyle(color: text, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      separatorBuilder: (ctx, i) => const SizedBox(height: 12),
      itemBuilder: (ctx, i) => const BmbSkeleton(width: double.infinity, height: 100),
    );
  }
}
