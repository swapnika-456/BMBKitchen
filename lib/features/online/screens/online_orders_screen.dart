import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/bmb_button.dart';
import '../../../core/widgets/bmb_card.dart';
import '../../../core/widgets/bmb_empty_state.dart';
import '../../../core/widgets/bmb_skeleton.dart';
import '../../../models/order.dart';
import '../../orders/controllers/orders_by_type_controller.dart';
import '../../orders/widgets/order_detail_sheet.dart';
import '../../settings/controllers/active_outlet_provider.dart';

class OnlineOrdersScreen extends ConsumerStatefulWidget {
  const OnlineOrdersScreen({super.key});

  @override
  ConsumerState<OnlineOrdersScreen> createState() => _OnlineOrdersScreenState();
}

class _OnlineOrdersScreenState extends ConsumerState<OnlineOrdersScreen> {
  static const String _orderType = 'online';

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
      ref.read(onlineOrdersControllerProvider.notifier).setDateRange(fromStr, toStr);
    }
  }

  void _clearDateRange() {
    ref.read(onlineOrdersControllerProvider.notifier).setDateRange(null, null);
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(onlineOrdersControllerProvider);
    final filter = ref.watch(onlineFilterProvider);
    final activeOutlet = ref.watch(activeOutletProvider);

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            _buildTopBar(activeOutlet),
            // Gap Notice
            _buildGapNoticeBanner(),
            // Filters
            _buildFilterBar(filter),
            const Divider(height: 1),
            // Orders List
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => ref.read(onlineOrdersControllerProvider.notifier).refresh(),
                child: ordersAsync.when(
                  data: (data) {
                    if (data.orders.isEmpty) {
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.5,
                            child: const Center(
                              child: BmbEmptyState(
                                title: 'No Online Orders',
                                description: 'No orders found matching the selected filter criteria.',
                                icon: Icon(Icons.language_outlined, size: 48, color: AppColors.muted),
                              ),
                            ),
                          ),
                        ],
                      );
                    }

                    return Column(
                      children: [
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: data.orders.length,
                            separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                            itemBuilder: (ctx, i) => _buildOrderCard(data.orders[i]),
                          ),
                        ),
                        _buildPaginationBar(data, filter),
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
                                Text('Error loading online orders: $e',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(color: AppColors.chilli)),
                                const SizedBox(height: 16),
                                BmbButton(
                                  label: 'Retry',
                                  onPressed: () => ref.read(onlineOrdersControllerProvider.notifier).refresh(),
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
              color: AppColors.plumSoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.language, color: AppColors.plum, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Online Orders', style: AppText.h2),
                Text(
                  activeOutlet != null ? '${activeOutlet.name} (${activeOutlet.code})' : 'Online Platform Queue (#51A)',
                  style: AppText.caption.copyWith(color: AppColors.muted),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => ref.read(onlineOrdersControllerProvider.notifier).refresh(),
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
              'API Gap: Delivery and Online orders have no customer or address fields in the API PDF.',
              style: TextStyle(fontSize: 11, color: AppColors.ink.withValues(alpha: 0.8)),
            ),
          ),
        ],
      ),
    );
  }

  // --- Filter Bar ---
  Widget _buildFilterBar(OrdersByTypeFilter filter) {
    final notifier = ref.read(onlineOrdersControllerProvider.notifier);

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
                      _buildScopeTab('running', 'Running', filter.scope, notifier),
                      _buildScopeTab('all', 'All', filter.scope, notifier),
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
          // Row 2: Status & Payment Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Text('Status:', style: AppText.caption.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(width: 6),
                _buildStatusChoiceChip(null, 'All', filter.orderStatus, notifier),
                const SizedBox(width: 4),
                _buildStatusChoiceChip('active', 'Active', filter.orderStatus, notifier),
                const SizedBox(width: 4),
                _buildStatusChoiceChip('completed', 'Completed', filter.orderStatus, notifier),
                const SizedBox(width: 4),
                _buildStatusChoiceChip('cancelled', 'Cancelled', filter.orderStatus, notifier),
                const SizedBox(width: 12),
                Text('Payment:', style: AppText.caption.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(width: 6),
                _buildPaymentChoiceChip(null, 'All', filter.paymentStatus, notifier),
                const SizedBox(width: 4),
                _buildPaymentChoiceChip('pending', 'Pending', filter.paymentStatus, notifier),
                const SizedBox(width: 4),
                _buildPaymentChoiceChip('paid', 'Paid', filter.paymentStatus, notifier),
                const SizedBox(width: 4),
                _buildPaymentChoiceChip('partially_paid', 'Partially Paid', filter.paymentStatus, notifier),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScopeTab(String scope, String label, String currentScope, OrdersByTypeNotifier notifier) {
    final isSel = currentScope == scope;
    return InkWell(
      onTap: () => notifier.setScope(scope),
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

  Widget _buildStatusChoiceChip(String? status, String label, String? currentStatus, OrdersByTypeNotifier notifier) {
    final isSel = currentStatus == status;
    return ChoiceChip(
      selected: isSel,
      selectedColor: AppColors.tandoorSoft,
      backgroundColor: AppColors.inputFill,
      side: BorderSide(color: isSel ? AppColors.tandoor : AppColors.line),
      label: Text(label, style: TextStyle(color: isSel ? AppColors.tandoor : AppColors.ink, fontSize: 11, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
      onSelected: (_) => notifier.setOrderStatus(status),
    );
  }

  Widget _buildPaymentChoiceChip(String? payment, String label, String? currentPayment, OrdersByTypeNotifier notifier) {
    final isSel = currentPayment == payment;
    return ChoiceChip(
      selected: isSel,
      selectedColor: AppColors.tandoorSoft,
      backgroundColor: AppColors.inputFill,
      side: BorderSide(color: isSel ? AppColors.tandoor : AppColors.line),
      label: Text(label, style: TextStyle(color: isSel ? AppColors.tandoor : AppColors.ink, fontSize: 11, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
      onSelected: (_) => notifier.setPaymentStatus(payment),
    );
  }

  // --- Order Card ---
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
                          color: AppColors.plumSoft,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(order.orderType.toUpperCase(), style: const TextStyle(fontSize: 10, color: AppColors.plum, fontWeight: FontWeight.bold)),
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
            const SizedBox(height: 8),
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

  Widget _buildPaginationBar(OrderListResponse data, OrdersByTypeFilter filter) {
    final notifier = ref.read(onlineOrdersControllerProvider.notifier);
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
            'Showing ${data.orders.length} of ${data.total} orders',
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
