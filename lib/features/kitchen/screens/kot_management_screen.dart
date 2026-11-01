import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/bmb_button.dart';
import '../../../core/widgets/bmb_card.dart';
import '../../../core/widgets/bmb_empty_state.dart';
import '../../../core/widgets/bmb_skeleton.dart';
import '../../../models/order.dart';
import '../../orders/widgets/order_detail_sheet.dart';
import '../../settings/controllers/active_outlet_provider.dart';
import '../controllers/kitchen_orders_controller.dart';

class KotManagementScreen extends ConsumerStatefulWidget {
  const KotManagementScreen({super.key});

  @override
  ConsumerState<KotManagementScreen> createState() => _KotManagementScreenState();
}

class _KotManagementScreenState extends ConsumerState<KotManagementScreen>
    with WidgetsBindingObserver {
  Timer? _refreshTimer;
  Timer? _ticker;
  bool _isResumed = true;
  String _selectedScope = 'running'; // running | today
  String? _selectedStatus; // null for all
  String? _selectedOrderType; // null for all
  bool _isBoardView = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // 30-second timed refresh only while screen is visible
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted && _isResumed && (ModalRoute.of(context)?.isCurrent ?? true)) {
        ref.read(kitchenOrdersControllerProvider.notifier).refresh();
      }
    });

    // 15-second ticker for elapsed time calculation
    _ticker = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isResumed = state == AppLifecycleState.resumed;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    _ticker?.cancel();
    super.dispose();
  }

  void _onScopeChanged(String scope) {
    setState(() => _selectedScope = scope);
    ref.read(kitchenOrdersFilterProvider.notifier).update(
          (f) => f.copyWith(scope: scope, page: 1),
        );
  }

  void _onStatusChanged(String? status) {
    setState(() => _selectedStatus = status);
    ref.read(kitchenOrdersFilterProvider.notifier).update(
          (f) => f.copyWith(status: () => status, page: 1),
        );
  }

  void _onOrderTypeChanged(String? orderType) {
    setState(() => _selectedOrderType = orderType);
    ref.read(kitchenOrdersFilterProvider.notifier).update(
          (f) => f.copyWith(orderType: () => orderType, page: 1),
        );
  }

  Future<void> _updateItemStatus(KitchenItem item, String newStatus) async {
    final res = await ref.read(kitchenOrdersControllerProvider.notifier).updateItemStatus(
          item.orderId,
          item.itemId,
          newStatus,
        );
    if (!mounted) return;
    if (res.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${item.name} marked as ${newStatus.replaceAll('_', ' ')}')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: AppColors.chilli, content: Text(res.message)),
      );
    }
  }

  String _formatElapsed(DateTime? sentAt) {
    if (sentAt == null) return '';
    final diff = DateTime.now().difference(sentAt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ${diff.inMinutes % 60}m ago';
  }

  @override
  Widget build(BuildContext context) {
    final kitchenDataAsync = ref.watch(kitchenOrdersControllerProvider);
    final activeOutlet = ref.watch(activeOutletProvider);
    final isTablet = MediaQuery.of(context).size.width >= 850;

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            _buildTopBar(activeOutlet, isTablet),
            // Filter Bar
            _buildFilterBar(kitchenDataAsync.value?.counts ?? {}),
            const Divider(height: 1),
            // Content
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => ref.read(kitchenOrdersControllerProvider.notifier).refresh(),
                child: kitchenDataAsync.when(
                  data: (data) {
                    if (data.items.isEmpty) {
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.5,
                            child: const Center(
                              child: BmbEmptyState(
                                title: 'No Kitchen Orders',
                                description: 'There are currently no active orders in the kitchen queue.',
                                icon: Icon(Icons.soup_kitchen_outlined, size: 48, color: AppColors.muted),
                              ),
                            ),
                          ),
                        ],
                      );
                    }

                    if (isTablet && _isBoardView && _selectedStatus == null) {
                      return _buildKanbanBoard(data.items);
                    } else {
                      return _buildItemsList(data.items);
                    }
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
                                Text('Error loading kitchen orders: $e',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(color: AppColors.chilli)),
                                const SizedBox(height: 16),
                                BmbButton(
                                  label: 'Retry',
                                  onPressed: () => ref.read(kitchenOrdersControllerProvider.notifier).refresh(),
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
  Widget _buildTopBar(dynamic activeOutlet, bool isTablet) {
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
            child: const Icon(Icons.soup_kitchen, color: AppColors.tandoor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Kitchen Order Tickets (KOT)', style: AppText.h2),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.leafSoft,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.sync, size: 12, color: AppColors.leaf),
                          SizedBox(width: 4),
                          Text('Auto (30s)', style: TextStyle(fontSize: 10, color: AppColors.leaf, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
                Text(
                  activeOutlet != null ? '${activeOutlet.name} (${activeOutlet.code})' : 'Active Kitchen Queue (#51B)',
                  style: AppText.caption.copyWith(color: AppColors.muted),
                ),
              ],
            ),
          ),
          if (isTablet) ...[
            IconButton(
              icon: Icon(_isBoardView ? Icons.view_agenda_outlined : Icons.view_column_outlined),
              tooltip: _isBoardView ? 'Switch to List' : 'Switch to Board',
              onPressed: () => setState(() => _isBoardView = !_isBoardView),
            ),
            const SizedBox(width: 8),
          ],
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Queue',
            onPressed: () => ref.read(kitchenOrdersControllerProvider.notifier).refresh(),
          ),
        ],
      ),
    );
  }

  // --- Filter Bar ---
  Widget _buildFilterBar(Map<String, int> counts) {
    final statusOptions = [
      {'key': null, 'label': 'All', 'count': counts.values.fold<int>(0, (a, b) => a + b)},
      {'key': 'in_queue', 'label': 'In Queue', 'count': counts['in_queue'] ?? 0},
      {'key': 'preparing', 'label': 'Preparing', 'count': counts['preparing'] ?? 0},
      {'key': 'ready', 'label': 'Ready', 'count': counts['ready'] ?? 0},
      {'key': 'served', 'label': 'Served', 'count': counts['served'] ?? 0},
      {'key': 'cancelled', 'label': 'Cancelled', 'count': counts['cancelled'] ?? 0},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Scope toggle: Running vs Today
              Container(
                decoration: BoxDecoration(
                  color: AppColors.inputFill,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.line),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildScopeTab('running', 'Running'),
                    _buildScopeTab('today', 'Today'),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Order Type dropdown
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildTypeFilterChip(null, 'All Types'),
                      const SizedBox(width: 6),
                      _buildTypeFilterChip('dine_in', 'Dine-in'),
                      const SizedBox(width: 6),
                      _buildTypeFilterChip('takeaway', 'Takeaway'),
                      const SizedBox(width: 6),
                      _buildTypeFilterChip('delivery', 'Delivery'),
                      const SizedBox(width: 6),
                      _buildTypeFilterChip('online', 'Online'),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Status Chips with counts
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: statusOptions.map((opt) {
                final isSel = _selectedStatus == opt['key'];
                final count = opt['count'] as int;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    selected: isSel,
                    selectedColor: AppColors.tandoorSoft,
                    backgroundColor: AppColors.inputFill,
                    side: BorderSide(color: isSel ? AppColors.tandoor : AppColors.line),
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          opt['label'] as String,
                          style: TextStyle(
                            color: isSel ? AppColors.tandoor : AppColors.ink,
                            fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                            fontSize: 12,
                          ),
                        ),
                        if (count > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: isSel ? AppColors.tandoor : AppColors.muted.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$count',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isSel ? Colors.white : AppColors.ink,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    onSelected: (_) => _onStatusChanged(opt['key'] as String?),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScopeTab(String scope, String label) {
    final isSel = _selectedScope == scope;
    return InkWell(
      onTap: () => _onScopeChanged(scope),
      borderRadius: BorderRadius.circular(7),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSel ? AppColors.tandoor : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
            color: isSel ? Colors.white : AppColors.ink,
          ),
        ),
      ),
    );
  }

  Widget _buildTypeFilterChip(String? type, String label) {
    final isSel = _selectedOrderType == type;
    return ChoiceChip(
      selected: isSel,
      selectedColor: AppColors.tandoorSoft,
      backgroundColor: AppColors.inputFill,
      side: BorderSide(color: isSel ? AppColors.tandoor : AppColors.line),
      label: Text(
        label,
        style: TextStyle(
          color: isSel ? AppColors.tandoor : AppColors.ink,
          fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
          fontSize: 11,
        ),
      ),
      onSelected: (_) => _onOrderTypeChanged(type),
    );
  }

  // --- List View ---
  Widget _buildItemsList(List<KitchenItem> items) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (ctx, i) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) => _buildKitchenItemCard(items[i]),
    );
  }

  // --- Kanban Board View (Tablet/Desktop) ---
  Widget _buildKanbanBoard(List<KitchenItem> allItems) {
    final statuses = [
      {'status': 'in_queue', 'title': 'In Queue', 'color': AppColors.amber},
      {'status': 'preparing', 'title': 'Preparing', 'color': AppColors.tandoor},
      {'status': 'ready', 'title': 'Ready', 'color': AppColors.blue},
      {'status': 'served', 'title': 'Served', 'color': AppColors.leaf},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: statuses.map((col) {
          final colItems = allItems.where((i) => i.status == col['status']).toList();
          return Container(
            width: 320,
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(color: col['color'] as Color, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 8),
                        Text(col['title'] as String, style: AppText.h3),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: (col['color'] as Color).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${colItems.length}',
                        style: TextStyle(color: col['color'] as Color, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const Divider(),
                if (colItems.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text('No items ${col['title']}', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                    ),
                  )
                else
                  ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: colItems.length,
                      separatorBuilder: (ctx, i) => const SizedBox(height: 8),
                      itemBuilder: (ctx, i) => _buildKitchenItemCard(colItems[i], isCompact: true),
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // --- Single Kitchen Item Card ---
  Widget _buildKitchenItemCard(KitchenItem item, {bool isCompact = false}) {
    final elapsedStr = _formatElapsed(item.sentToKitchenAt);

    return BmbCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order Header with Tap to open detail (#46)
          InkWell(
            onTap: () => OrderDetailSheet.show(context, item.orderId),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'Order #${item.orderNo}',
                      style: AppText.body.copyWith(fontWeight: FontWeight.bold, color: AppColors.tandoor),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.open_in_new, size: 14, color: AppColors.muted),
                  ],
                ),
                if (item.orderType.toLowerCase() == 'takeaway')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.tandoorSoft,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('Takeaway', style: TextStyle(color: AppColors.tandoor, fontSize: 10, fontWeight: FontWeight.bold)),
                  )
                else if (item.tableName != null && item.tableName!.isNotEmpty && item.tableName != '{}')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.blueSoft,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('Table: ${item.tableName}', style: const TextStyle(color: AppColors.blue, fontSize: 10, fontWeight: FontWeight.bold)),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.inputFill,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(item.orderType.toUpperCase(), style: const TextStyle(color: AppColors.ink, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),
          const Divider(height: 12),
          // Item details
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.inputFill,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${item.quantity}x',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name, style: AppText.body.copyWith(fontWeight: FontWeight.w600)),
                    if (item.notes.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text('Note: ${item.notes}', style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.muted)),
                    ],
                    if (elapsedStr.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.timer_outlined, size: 12, color: AppColors.muted),
                          const SizedBox(width: 4),
                          Text(elapsedStr, style: const TextStyle(fontSize: 10, color: AppColors.muted)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              _buildItemStatusChip(item.status),
            ],
          ),
          const SizedBox(height: 10),
          // Action Buttons (#49)
          _buildItemActionButtons(item),
        ],
      ),
    );
  }

  Widget _buildItemActionButtons(KitchenItem item) {
    switch (item.status.toLowerCase()) {
      case 'in_queue':
        return Row(
          children: [
            Expanded(
              child: BmbButton(
                label: 'Start Preparing',
                icon: const Icon(Icons.outdoor_grill, size: 16, color: Colors.white),
                onPressed: () => _updateItemStatus(item, 'preparing'),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.cancel_outlined, color: AppColors.chilli, size: 20),
              tooltip: 'Cancel item',
              onPressed: () => _updateItemStatus(item, 'cancelled'),
            ),
          ],
        );
      case 'preparing':
        return Row(
          children: [
            Expanded(
              child: BmbButton(
                label: 'Mark Ready',
                icon: const Icon(Icons.check_circle_outline, size: 16, color: Colors.white),
                onPressed: () => _updateItemStatus(item, 'ready'),
              ),
            ),
          ],
        );
      case 'ready':
        return Row(
          children: [
            Expanded(
              child: BmbButton(
                label: 'Mark Served',
                icon: const Icon(Icons.room_service, size: 16, color: Colors.white),
                onPressed: () => _updateItemStatus(item, 'served'),
              ),
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildItemStatusChip(String status) {
    Color bg = AppColors.inputFill;
    Color text = AppColors.ink;
    switch (status.toLowerCase()) {
      case 'in_queue':
        bg = AppColors.amberSoft;
        text = AppColors.amber;
        break;
      case 'preparing':
        bg = AppColors.tandoorSoft;
        text = AppColors.tandoor;
        break;
      case 'ready':
        bg = AppColors.blueSoft;
        text = AppColors.blue;
        break;
      case 'served':
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
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style: TextStyle(color: text, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      separatorBuilder: (ctx, i) => const SizedBox(height: 12),
      itemBuilder: (ctx, i) => const BmbSkeleton(width: double.infinity, height: 110),
    );
  }
}
