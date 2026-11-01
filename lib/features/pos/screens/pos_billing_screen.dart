import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/bmb_button.dart';
import '../../../core/widgets/bmb_card.dart';
import '../../../core/widgets/bmb_empty_state.dart';
import '../../../core/widgets/bmb_skeleton.dart';
import '../../../core/widgets/food_type_dot.dart';
import '../../../models/menu_item.dart';
import '../../../models/order.dart';
import '../../../models/restaurant_table.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../menu/controllers/menu_category_controller.dart';
import '../../menu/controllers/menu_item_controller.dart';
import '../../settings/controllers/active_outlet_provider.dart';
import '../../tables/providers/table_providers.dart';
import '../controllers/pos_order_controller.dart';

class PosBillingScreen extends ConsumerStatefulWidget {
  final String? initialTableId;
  final String? initialOrderId;

  const PosBillingScreen({super.key, this.initialTableId, this.initialOrderId});

  @override
  ConsumerState<PosBillingScreen> createState() => _PosBillingScreenState();
}

class _PosBillingScreenState extends ConsumerState<PosBillingScreen> {
  // Navigation: 0 = New Order (Billing/Cart), 1 = Active Orders List
  int _currentTab = 0;

  // Order Setup
  String _orderType = 'dine_in'; // dine_in, takeaway, delivery, online
  String? _selectedTableId;

  // Menu Search & Category
  String _selectedCategory = 'All';
  final TextEditingController _searchController = TextEditingController();

  // Cart for New Order
  final Map<String, _CartEntry> _cart = {}; // menuItemId -> _CartEntry
  bool _isPlacingOrder = false;

  // Selected Order for Detail View
  String? _activeDetailOrderId;

  @override
  void initState() {
    super.initState();
    if (widget.initialOrderId != null) {
      _activeDetailOrderId = widget.initialOrderId;
      _currentTab = 1;
    }
    if (widget.initialTableId != null) {
      _selectedTableId = widget.initialTableId;
      _orderType = 'dine_in';
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  double get _cartEstimateSubtotal {
    double sum = 0.0;
    for (final entry in _cart.values) {
      sum += entry.item.price.toRupees * entry.quantity;
    }
    return sum;
  }

  int get _cartTotalItems {
    int count = 0;
    for (final entry in _cart.values) {
      count += entry.quantity;
    }
    return count;
  }

  void _addToCart(MenuItem item) {
    if (item.price.toRupees <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot add "${item.name}" because it does not have a valid price.'),
          backgroundColor: AppColors.chilli,
        ),
      );
      return;
    }
    setState(() {
      if (_cart.containsKey(item.id)) {
        _cart[item.id]!.quantity++;
      } else {
        _cart[item.id] = _CartEntry(item: item, quantity: 1);
      }
    });
  }

  void _decrementCart(String itemId) {
    setState(() {
      if (_cart.containsKey(itemId)) {
        if (_cart[itemId]!.quantity > 1) {
          _cart[itemId]!.quantity--;
        } else {
          _cart.remove(itemId);
        }
      }
    });
  }

  void _clearCart() {
    setState(() {
      _cart.clear();
    });
  }

  // #45: Place Order
  Future<void> _placeOrder() async {
    final activeOutlet = ref.read(activeOutletProvider);
    if (activeOutlet == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active outlet found. Please select an outlet in Settings.')),
      );
      return;
    }

    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cart is empty. Please add items to place an order.')),
      );
      return;
    }

    if (_orderType == 'dine_in' && (_selectedTableId == null || _selectedTableId!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a table for Dine-in orders.')),
      );
      return;
    }

    for (final e in _cart.values) {
      if (e.item.price.toRupees <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.chilli,
            content: Text('Cannot place order: "${e.item.name}" has no valid price.'),
          ),
        );
        return;
      }
    }

    setState(() => _isPlacingOrder = true);

    final itemsPayload = _cart.values.map((e) {
      final itemPrice = e.item.price.toRupees;
      final itemQty = e.quantity;
      return {
        'menuItemId': e.item.id,
        'name': e.item.name,
        'price': itemPrice,
        'quantity': itemQty,
        'itemTotal': itemPrice * itemQty,
        'notes': e.notes,
      };
    }).toList();

    try {
      final res = await ref.read(activeOrdersProvider.notifier).createOrder(
            outletId: activeOutlet.id,
            orderType: _orderType,
            tableId: _orderType == 'dine_in' ? _selectedTableId : null,
            items: itemsPayload,
          );

      if (!mounted) return;
      setState(() => _isPlacingOrder = false);

      if (res.success && res.data != null) {
        final newOrder = res.data!;
        _clearCart();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order ${newOrder.orderNo} placed successfully!')),
        );
        setState(() {
          _activeDetailOrderId = newOrder.id;
          _currentTab = 1;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.chilli,
            content: Text(res.message.isNotEmpty ? res.message : 'Failed to place order'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isPlacingOrder = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: AppColors.chilli, content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeOutlet = ref.watch(activeOutletProvider);
    final activeOrdersAsync = ref.watch(activeOrdersProvider);
    final activeOrdersCount = activeOrdersAsync.value?.length ?? 0;

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopNavBar(activeOutlet, activeOrdersCount),
            Expanded(
              child: _activeDetailOrderId != null
                  ? _buildOrderDetailView(_activeDetailOrderId!)
                  : (_currentTab == 0 ? _buildNewOrderView() : _buildActiveOrdersListView()),
            ),
          ],
        ),
      ),
    );
  }

  // --- Top App Header & Tabs ---
  Widget _buildTopNavBar(dynamic activeOutlet, int activeOrdersCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 600;
          return Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.tandoorSoft,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.point_of_sale, color: AppColors.tandoor, size: 20),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('POS Billing', style: AppText.h2),
                        Text(
                          activeOutlet != null
                              ? '${activeOutlet.name} (${activeOutlet.code})'
                              : 'No active outlet',
                          style: AppText.caption.copyWith(color: AppColors.muted),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (_activeDetailOrderId != null)
                    TextButton.icon(
                      onPressed: () => setState(() => _activeDetailOrderId = null),
                      icon: const Icon(Icons.arrow_back, size: 18),
                      label: const Text('Back to Orders'),
                    ),
                ],
              ),
              if (_activeDetailOrderId == null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _currentTab = 0),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                          decoration: BoxDecoration(
                            color: _currentTab == 0 ? AppColors.tandoorSoft : AppColors.inputFill,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _currentTab == 0 ? AppColors.tandoor : AppColors.line),
                          ),
                          child: Center(
                            child: Text(
                              isNarrow ? 'New Order' : 'New Order / Menu',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: _currentTab == 0 ? FontWeight.bold : FontWeight.normal,
                                color: _currentTab == 0 ? AppColors.tandoor : AppColors.ink,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _currentTab = 1),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                          decoration: BoxDecoration(
                            color: _currentTab == 1 ? AppColors.tandoorSoft : AppColors.inputFill,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _currentTab == 1 ? AppColors.tandoor : AppColors.line),
                          ),
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    'Active Orders',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: _currentTab == 1 ? FontWeight.bold : FontWeight.normal,
                                      color: _currentTab == 1 ? AppColors.tandoor : AppColors.ink,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                if (activeOrdersCount > 0) ...[
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _currentTab == 1 ? AppColors.tandoor : AppColors.muted,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '$activeOrdersCount',
                                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  // ===========================================================================
  // TAB 0: NEW ORDER (Order Setup + Menu Picker + Cart)
  // ===========================================================================
  Widget _buildNewOrderView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 6,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildOrderSetupCard(),
                      const SizedBox(height: 16),
                      _buildMenuPicker(),
                    ],
                  ),
                ),
              ),
              Container(width: 1, color: AppColors.line),
              Expanded(
                flex: 4,
                child: _buildCartPanel(),
              ),
            ],
          );
        } else {
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildOrderSetupCard(),
                      const SizedBox(height: 16),
                      _buildMenuPicker(),
                    ],
                  ),
                ),
              ),
              _buildBottomCartSummaryBar(),
            ],
          );
        }
      },
    );
  }

  // --- 1. Order Setup Card ---
  Widget _buildOrderSetupCard() {
    final tablesAsync = ref.watch(activeTablesProvider);
    final activeOrders = ref.watch(activeOrdersProvider).value ?? [];

    return BmbCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tune, size: 18, color: AppColors.tandoor),
              const SizedBox(width: 6),
              Text('Order Setup', style: AppText.h3),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildOrderTypeChip('dine_in', 'Dine-in', Icons.restaurant),
              _buildOrderTypeChip('takeaway', 'Takeaway', Icons.takeout_dining),
              _buildOrderTypeChip('delivery', 'Delivery', Icons.delivery_dining),
              _buildOrderTypeChip('online', 'Online', Icons.language),
            ],
          ),
          if (_orderType == 'dine_in') ...[
            const SizedBox(height: 16),
            Text('Select Table', style: AppText.body.copyWith(fontWeight: FontWeight.w600)),
            const Text(
              'Green = Available | Red = Occupied (Tap to open order) | Blue = Reserved',
              style: TextStyle(fontSize: 11, color: AppColors.muted),
            ),
            const SizedBox(height: 8),
            tablesAsync.when(
              data: (tables) {
                if (tables.isEmpty) {
                  return const Text('No active tables found for this outlet.', style: TextStyle(color: AppColors.muted));
                }
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: tables.map((t) {
                    final isOccupied = t.status == TableStatus.occupied;
                    final isReserved = t.status == TableStatus.reserved;
                    final isSelected = _selectedTableId == t.id;

                    Color bg = isOccupied ? AppColors.chilliSoft : (isReserved ? AppColors.blueSoft : AppColors.leafSoft);
                    Color text = isOccupied ? AppColors.chilli : (isReserved ? AppColors.blue : AppColors.leaf);
                    BorderSide border = isSelected
                        ? const BorderSide(color: AppColors.tandoor, width: 2)
                        : BorderSide(color: text.withValues(alpha: 0.3));

                    return ActionChip(
                      backgroundColor: bg,
                      side: border,
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isOccupied ? Icons.lock : (isReserved ? Icons.event_seat : Icons.table_restaurant),
                            size: 14,
                            color: text,
                          ),
                          const SizedBox(width: 4),
                          Text('${t.name} (${t.cap}p)', style: TextStyle(color: text, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      onPressed: () {
                        if (isOccupied) {
                          final existingOrder = activeOrders.firstWhere(
                            (o) => o.tableId == t.id && o.orderStatus == 'active',
                            orElse: () => Order(id: '', outletId: ''),
                          );
                          if (existingOrder.id.isNotEmpty) {
                            setState(() {
                              _activeDetailOrderId = existingOrder.id;
                              _currentTab = 1;
                            });
                            return;
                          }
                        }
                        setState(() => _selectedTableId = t.id);
                      },
                    );
                  }).toList(),
                );
              },
              loading: () => const BmbSkeleton(width: double.infinity, height: 40),
              error: (e, _) => Text('Error loading tables: $e', style: const TextStyle(color: AppColors.chilli)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOrderTypeChip(String type, String label, IconData icon) {
    final isSelected = _orderType == type;
    return ChoiceChip(
      selected: isSelected,
      selectedColor: AppColors.tandoorSoft,
      backgroundColor: AppColors.inputFill,
      side: BorderSide(color: isSelected ? AppColors.tandoor : AppColors.line),
      avatar: Icon(icon, size: 16, color: isSelected ? AppColors.tandoor : AppColors.muted),
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? AppColors.tandoor : AppColors.ink,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onSelected: (_) {
        setState(() {
          _orderType = type;
          if (_orderType != 'dine_in') {
            _selectedTableId = null;
          }
        });
      },
    );
  }

  // --- 2. Menu Picker ---
  Widget _buildMenuPicker() {
    final categoriesAsync = ref.watch(menuCategoryControllerProvider);
    final menuItemsAsync = ref.watch(menuItemControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.restaurant_menu, size: 18, color: AppColors.tandoor),
            const SizedBox(width: 6),
            Text('Menu Items', style: AppText.h3),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search items...',
            prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.muted),
            filled: true,
            fillColor: AppColors.inputFill,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.line)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.line)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),
        categoriesAsync.when(
          data: (categories) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('All'),
                    selected: _selectedCategory == 'All',
                    selectedColor: AppColors.tandoorSoft,
                    backgroundColor: AppColors.inputFill,
                    side: BorderSide(color: _selectedCategory == 'All' ? AppColors.tandoor : AppColors.line),
                    onSelected: (_) => setState(() => _selectedCategory = 'All'),
                  ),
                  const SizedBox(width: 6),
                  ...categories.map((c) {
                    final isSel = _selectedCategory == c.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(c.name),
                        selected: isSel,
                        selectedColor: AppColors.tandoorSoft,
                        backgroundColor: AppColors.inputFill,
                        side: BorderSide(color: isSel ? AppColors.tandoor : AppColors.line),
                        onSelected: (_) => setState(() => _selectedCategory = c.id),
                      ),
                    );
                  }),
                ],
              ),
            );
          },
          loading: () => const BmbSkeleton(width: double.infinity, height: 32),
          error: (err, stack) => const SizedBox.shrink(),
        ),
        const SizedBox(height: 16),
        menuItemsAsync.when(
          data: (items) {
            final query = _searchController.text.trim().toLowerCase();
            final filtered = items.where((i) {
              if (!i.isActive) return false;
              if (_selectedCategory != 'All' && i.cat != _selectedCategory) return false;
              if (query.isNotEmpty && !i.name.toLowerCase().contains(query)) return false;
              return true;
            }).toList();

            if (filtered.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: BmbEmptyState(
                  title: 'No Menu Items',
                  description: 'No items match your filter criteria.',
                  icon: Icon(Icons.fastfood_outlined, size: 40, color: AppColors.muted),
                ),
              );
            }

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 220,
                mainAxisExtent: 130,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: filtered.length,
              itemBuilder: (ctx, idx) {
                final item = filtered[idx];
                final inCart = _cart[item.id]?.quantity ?? 0;

                return InkWell(
                  onTap: () => _addToCart(item),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: inCart > 0 ? AppColors.tandoorSoft.withValues(alpha: 0.3) : AppColors.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: inCart > 0 ? AppColors.tandoor : AppColors.line,
                        width: inCart > 0 ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FoodTypeDot(type: item.type),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                item.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.body.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '₹${item.price.toRupees.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.tandoor,
                              ),
                            ),
                            if (inCart > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.tandoor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$inCart in cart',
                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              )
                            else
                              const Icon(Icons.add_circle_outline, color: AppColors.tandoor, size: 20),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())),
          error: (e, _) => Text('Error loading menu: $e', style: const TextStyle(color: AppColors.chilli)),
        ),
      ],
    );
  }

  // --- 3. Cart Panel (Wide screens) ---
  Widget _buildCartPanel() {
    return Container(
      color: AppColors.card,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.shopping_cart_outlined, color: AppColors.tandoor),
                  const SizedBox(width: 6),
                  Text('Cart ($_cartTotalItems)', style: AppText.h3),
                ],
              ),
              if (_cart.isNotEmpty)
                TextButton(
                  onPressed: _clearCart,
                  child: const Text('Clear', style: TextStyle(color: AppColors.chilli)),
                ),
            ],
          ),
          const Divider(),
          Expanded(
            child: _cart.isEmpty
                ? const Center(
                    child: Text(
                      'No items in cart.\nSelect items from the menu.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.muted),
                    ),
                  )
                : ListView.separated(
                    itemCount: _cart.values.length,
                    separatorBuilder: (ctx, i) => const Divider(height: 1),
                    itemBuilder: (ctx, idx) {
                      final entry = _cart.values.elementAt(idx);
                      final itemPrice = entry.item.price.toRupees;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    entry.item.name,
                                    style: AppText.body.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ),
                                Text(
                                  '₹${(itemPrice * entry.quantity).toStringAsFixed(0)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline, size: 20),
                                      color: AppColors.tandoor,
                                      onPressed: () => _decrementCart(entry.item.id),
                                    ),
                                    Text('${entry.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline, size: 20),
                                      color: AppColors.tandoor,
                                      onPressed: () => _addToCart(entry.item),
                                    ),
                                  ],
                                ),
                                IconButton(
                                  icon: Icon(Icons.notes, size: 18, color: entry.notes.isNotEmpty ? AppColors.tandoor : AppColors.muted),
                                  onPressed: () => _editItemNotesDialog(entry),
                                ),
                              ],
                            ),
                            if (entry.notes.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: Text('Note: ${entry.notes}', style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.muted)),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          const Divider(),
          Container(
            padding: const EdgeInsets.all(12),
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
                    const Text('Subtotal Estimate:', style: TextStyle(fontWeight: FontWeight.w600)),
                    Text(
                      '₹${_cartEstimateSubtotal.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.tandoor),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Final tax & service charge are computed by the server on order placement.',
                  style: TextStyle(fontSize: 10, color: AppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: BmbButton(
              label: _isPlacingOrder ? 'Placing Order...' : 'Place Order (#45)',
              icon: const Icon(Icons.check, color: Colors.white, size: 18),
              isLoading: _isPlacingOrder,
              onPressed: _cart.isEmpty || _isPlacingOrder ? null : _placeOrder,
            ),
          ),
        ],
      ),
    );
  }

  // --- 4. Mobile Bottom Cart Bar ---
  Widget _buildBottomCartSummaryBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: const Border(top: BorderSide(color: AppColors.line)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, -2)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: _showMobileCartSheet,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.shopping_cart, size: 16, color: AppColors.tandoor),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          '$_cartTotalItems items in cart',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  Text('Estimate: ₹${_cartEstimateSubtotal.toStringAsFixed(0)}',
                      style: const TextStyle(color: AppColors.tandoor, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          BmbButton(
            label: _isPlacingOrder ? 'Sending...' : 'Place Order',
            isLoading: _isPlacingOrder,
            onPressed: _cart.isEmpty || _isPlacingOrder ? null : _placeOrder,
          ),
        ],
      ),
    );
  }

  void _showMobileCartSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.65,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Cart (${_cart.length} items)', style: AppText.h3),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: _cart.isEmpty
                        ? const Center(child: Text('Cart is empty'))
                        : ListView.separated(
                            itemCount: _cart.values.length,
                            separatorBuilder: (ctx, i) => const Divider(height: 1),
                            itemBuilder: (c, i) {
                              final entry = _cart.values.elementAt(i);
                              return ListTile(
                                title: Text(entry.item.name),
                                subtitle: Text('₹${entry.item.price.toRupees * entry.quantity}'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove),
                                      onPressed: () {
                                        _decrementCart(entry.item.id);
                                        setSheetState(() {});
                                        setState(() {});
                                      },
                                    ),
                                    Text('${entry.quantity}'),
                                    IconButton(
                                      icon: const Icon(Icons.add),
                                      onPressed: () {
                                        _addToCart(entry.item);
                                        setSheetState(() {});
                                        setState(() {});
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Estimate Subtotal:'),
                      Text('₹${_cartEstimateSubtotal.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: BmbButton(
                      label: 'Done',
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _editItemNotesDialog(_CartEntry entry) {
    final noteCtrl = TextEditingController(text: entry.notes);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Notes for ${entry.item.name}'),
        content: TextField(
          controller: noteCtrl,
          decoration: const InputDecoration(hintText: 'e.g. Less spicy, no onions'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              setState(() => entry.notes = noteCtrl.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 1: ACTIVE ORDERS LIST (#44)
  // ===========================================================================
  Widget _buildActiveOrdersListView() {
    final activeOrdersAsync = ref.watch(activeOrdersProvider);

    return activeOrdersAsync.when(
      data: (orders) {
        if (orders.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const BmbEmptyState(
                    title: 'No Active Orders',
                    description: 'There are no active orders for this outlet.',
                    icon: Icon(Icons.receipt_long_outlined, size: 40, color: AppColors.muted),
                  ),
                  const SizedBox(height: 16),
                  BmbButton(
                    label: 'Create New Order',
                    icon: const Icon(Icons.add, color: Colors.white, size: 18),
                    onPressed: () => setState(() => _currentTab = 0),
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => ref.read(activeOrdersProvider.notifier).refresh(),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (ctx, i) => const SizedBox(height: 8),
            itemBuilder: (ctx, idx) {
              final o = orders[idx];
              return InkWell(
                onTap: () => setState(() => _activeDetailOrderId = o.id),
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
                              spacing: 8,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.tandoorSoft,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(o.orderNo, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.tandoor)),
                                ),
                                if (o.tableName != null && o.tableName!.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.blueSoft,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(o.tableName!, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.blue, fontSize: 12)),
                                  )
                                else
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.inputFill,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(o.orderType.toUpperCase(), style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '₹${o.grandTotal.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.tandoor),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${o.items.length} item${o.items.length == 1 ? '' : 's'}: ${o.items.map((i) => "${i.quantity}x ${i.name}").join(', ')}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.caption.copyWith(color: AppColors.muted),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                _buildStatusChip(o.orderStatus),
                                _buildPaymentStatusChip(o.paymentStatus),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: AppColors.muted),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 4,
        separatorBuilder: (ctx, i) => const SizedBox(height: 8),
        itemBuilder: (ctx, i) => const BmbSkeleton(width: double.infinity, height: 100),
      ),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Error loading active orders: $e', style: const TextStyle(color: AppColors.chilli)),
              const SizedBox(height: 12),
              BmbButton(
                label: 'Retry',
                onPressed: () => ref.read(activeOrdersProvider.notifier).refresh(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // ORDER DETAIL VIEW (#46)
  // ===========================================================================
  Widget _buildOrderDetailView(String orderId) {
    return FutureBuilder(
      future: ref.read(activeOrdersProvider.notifier).getOrder(orderId),
      builder: (ctx, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || snapshot.data == null || !snapshot.data!.success || snapshot.data!.data == null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Failed to load order: ${snapshot.data?.message ?? snapshot.error}'),
                const SizedBox(height: 12),
                BmbButton(label: 'Back', onPressed: () => setState(() => _activeDetailOrderId = null)),
              ],
            ),
          );
        }

        final order = snapshot.data!.data!;
        final user = ref.watch(authControllerProvider).value;
        final isManager = ['owner', 'admin', 'cto'].contains(user?.role.toLowerCase());

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header card
              BmbCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(order.orderNo, style: AppText.h1),
                            Text(
                              'Type: ${order.orderType.toUpperCase()}${order.tableName != null ? " · Table: ${order.tableName}" : ""}',
                              style: AppText.body.copyWith(color: AppColors.muted),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _buildStatusChip(order.orderStatus),
                            const SizedBox(height: 4),
                            _buildPaymentStatusChip(order.paymentStatus),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Items List
              BmbCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Order Items (${order.items.length})', style: AppText.h3),
                        if (order.orderStatus == 'active')
                          TextButton.icon(
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Add Items (#48)'),
                            onPressed: () => _showAddItemsDialog(order),
                          ),
                      ],
                    ),
                    const Divider(),
                    if (order.items.isEmpty)
                      const Text('No items in this order.', style: TextStyle(color: AppColors.muted))
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: order.items.length,
                        separatorBuilder: (ctx, i) => const Divider(height: 1),
                        itemBuilder: (ctx, i) {
                          final item = order.items[i];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${item.quantity}x ${item.name}',
                                        style: AppText.body.copyWith(fontWeight: FontWeight.w600),
                                      ),
                                      Text('₹${item.price} each · Total: ₹${item.itemTotal}', style: AppText.caption),
                                      if (item.notes.isNotEmpty)
                                        Text('Note: ${item.notes}', style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.muted)),
                                    ],
                                  ),
                                ),
                                if (order.orderStatus == 'active')
                                  PopupMenuButton<String>(
                                    initialValue: item.status,
                                    onSelected: (newStatus) => _updateItemStatus(order.id, item.id, newStatus),
                                    itemBuilder: (c) => const [
                                      PopupMenuItem(value: 'in_queue', child: Text('In Queue')),
                                      PopupMenuItem(value: 'preparing', child: Text('Preparing')),
                                      PopupMenuItem(value: 'ready', child: Text('Ready')),
                                      PopupMenuItem(value: 'served', child: Text('Served')),
                                      PopupMenuItem(value: 'cancelled', child: Text('Cancelled')),
                                    ],
                                    child: _buildItemStatusChip(item.status),
                                  )
                                else
                                  _buildItemStatusChip(item.status),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Server Totals Breakdown Card
              BmbCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Server Computed Totals', style: AppText.h3),
                    const Divider(),
                    _buildSummaryRow('Subtotal', '₹${order.subTotal.toStringAsFixed(2)}'),
                    if (order.discountAmount > 0)
                      _buildSummaryRow('Total Discount', '-₹${order.discountAmount.toStringAsFixed(2)}', color: AppColors.leaf),
                    if (order.manualDiscountAmount > 0)
                      _buildSummaryRow('  Manual Discount', '-₹${order.manualDiscountAmount.toStringAsFixed(2)}', color: AppColors.leaf),
                    if (order.serviceChargeAmount > 0)
                      _buildSummaryRow('Service Charge', '₹${order.serviceChargeAmount.toStringAsFixed(2)}'),
                    if (order.taxAmount > 0)
                      _buildSummaryRow('Tax (${order.taxPercent.toStringAsFixed(0)}%)', '₹${order.taxAmount.toStringAsFixed(2)}'),
                    const Divider(),
                    _buildSummaryRow(
                      'Grand Total',
                      '₹${order.grandTotal.toStringAsFixed(2)}',
                      isBold: true,
                      color: AppColors.tandoor,
                    ),
                    if (order.billNo != null) ...[
                      const SizedBox(height: 4),
                      _buildSummaryRow('Bill No', order.billNo!, isBold: true),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Actions: Checkout (#50) & Cancel (#51)
              if (order.orderStatus == 'active')
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.chilli,
                          side: const BorderSide(color: AppColors.chilli),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: const Icon(Icons.cancel_outlined),
                        label: const Text('Cancel Order (#51)'),
                        onPressed: () => _confirmCancelOrder(order),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: BmbButton(
                        label: 'Checkout (#50)',
                        icon: const Icon(Icons.payment, color: Colors.white, size: 18),
                        onPressed: () => _startCheckoutFlow(order, isManager),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: AppColors.ink)),
          Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: color ?? AppColors.ink)),
        ],
      ),
    );
  }

  // --- Change Item Status (#49) ---
  Future<void> _updateItemStatus(String orderId, String itemId, String newStatus) async {
    final res = await ref.read(activeOrdersProvider.notifier).updateItemStatus(orderId, itemId, newStatus);
    if (!mounted) return;
    if (res.success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Item marked as $newStatus')));
      setState(() {});
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: AppColors.chilli, content: Text(res.message)));
    }
  }

  // --- Add Items Dialog (#48) ---
  void _showAddItemsDialog(Order order) {
    final menuItems = ref.read(menuItemControllerProvider).value ?? [];
    final Map<String, _CartEntry> newItems = {};

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDlgState) {
            return AlertDialog(
              title: Text('Add Items to ${order.orderNo}'),
              content: SizedBox(
                width: 450,
                height: 400,
                child: Column(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        itemCount: menuItems.length,
                        separatorBuilder: (ctx, i) => const Divider(height: 1),
                        itemBuilder: (c, idx) {
                          final item = menuItems[idx];
                          final count = newItems[item.id]?.quantity ?? 0;
                          return ListTile(
                            title: Text(item.name),
                            subtitle: Text('₹${item.price.toRupees.toStringAsFixed(0)}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (count > 0) ...[
                                  IconButton(
                                    icon: const Icon(Icons.remove),
                                    onPressed: () {
                                      setDlgState(() {
                                        if (count > 1) {
                                          newItems[item.id]!.quantity--;
                                        } else {
                                          newItems.remove(item.id);
                                        }
                                      });
                                    },
                                  ),
                                  Text('$count'),
                                ],
                                IconButton(
                                  icon: const Icon(Icons.add),
                                  onPressed: () {
                                    if (item.price.toRupees <= 0) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          backgroundColor: AppColors.chilli,
                                          content: Text('Cannot add "${item.name}" because it has no price.'),
                                        ),
                                      );
                                      return;
                                    }
                                    setDlgState(() {
                                      if (newItems.containsKey(item.id)) {
                                        newItems[item.id]!.quantity++;
                                      } else {
                                        newItems[item.id] = _CartEntry(item: item, quantity: 1);
                                      }
                                    });
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                BmbButton(
                  label: 'Add to Order',
                  onPressed: newItems.isEmpty
                      ? null
                      : () async {
                          Navigator.pop(ctx);
                          final payload = newItems.values.map((e) {
                            final itemPrice = e.item.price.toRupees;
                            return {
                              'menuItemId': e.item.id,
                              'name': e.item.name,
                              'price': itemPrice,
                              'quantity': e.quantity,
                              'itemTotal': itemPrice * e.quantity,
                              'notes': e.notes,
                            };
                          }).toList();
                          final res = await ref.read(activeOrdersProvider.notifier).addItems(order.id, payload);
                          if (!mounted) return;
                          if (res.success) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Items added to order')));
                            setState(() {});
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: AppColors.chilli, content: Text(res.message)));
                          }
                        },
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- Checkout Flow (#50A Preview + #50 Checkout) ---
  Future<void> _startCheckoutFlow(Order order, bool isManager) async {
    final unservedCount = order.items.where((i) => i.status.toLowerCase() != 'served' && i.status.toLowerCase() != 'cancelled').length;
    if (unservedCount > 0) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Items Not Served'),
          content: Text('$unservedCount items not served yet. Check out anyway?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            BmbButton(
              label: 'Check Out Anyway',
              onPressed: () => Navigator.pop(ctx, true),
            ),
          ],
        ),
      );
      if (proceed != true) return;
    }

    final previewRes = await ref.read(activeOrdersProvider.notifier).getCheckoutPreview(order.id);
    if (!mounted) return;

    if (!previewRes.success || previewRes.data == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: AppColors.chilli, content: Text(previewRes.message.isNotEmpty ? previewRes.message : 'Failed to fetch checkout preview')),
      );
      return;
    }

    final preview = previewRes.data!;
    String selectedPaymentMethod = 'cash'; // cash, card, upi
    final discountCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDlgState) {
            double currentGrandTotal = preview.grandTotal;
            final enteredDisc = double.tryParse(discountCtrl.text.trim()) ?? 0.0;
            if (enteredDisc > 0) {
              currentGrandTotal = (currentGrandTotal - enteredDisc).clamp(0.0, double.infinity);
            }

            return AlertDialog(
              title: Text('Checkout ${order.orderNo}'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.inputFill,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: Column(
                        children: [
                          _buildSummaryRow('Subtotal', '₹${preview.subTotal.toStringAsFixed(2)}'),
                          if (preview.serviceChargeAmount > 0)
                            _buildSummaryRow('Service Charge (${preview.serviceChargePercent}%)', '₹${preview.serviceChargeAmount.toStringAsFixed(2)}'),
                          if (preview.taxAmount > 0)
                            _buildSummaryRow('Tax (${preview.taxPercent}%)', '₹${preview.taxAmount.toStringAsFixed(2)}'),
                          if (preview.totalDiscount > 0)
                            _buildSummaryRow('Offer/Loyalty Discount', '-₹${preview.totalDiscount.toStringAsFixed(2)}', color: AppColors.leaf),
                          const Divider(),
                          _buildSummaryRow('Total to Pay', '₹${currentGrandTotal.toStringAsFixed(2)}', isBold: true, color: AppColors.tandoor),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (isManager) ...[
                      Text('Manual Discount (Owner/Admin/CTO)', style: AppText.caption.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      TextField(
                        controller: discountCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: 'Enter discount amount (e.g. 50)',
                          prefixText: '₹ ',
                          isDense: true,
                        ),
                        onChanged: (_) => setDlgState(() {}),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Text('Payment Method', style: AppText.caption.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: ['cash', 'card', 'upi'].map((pm) {
                        final isSel = selectedPaymentMethod == pm;
                        return ChoiceChip(
                          label: Text(pm.toUpperCase()),
                          selected: isSel,
                          selectedColor: AppColors.tandoorSoft,
                          side: BorderSide(color: isSel ? AppColors.tandoor : AppColors.line),
                          onSelected: (_) => setDlgState(() => selectedPaymentMethod = pm),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                BmbButton(
                  label: 'Confirm Payment',
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final disc = double.tryParse(discountCtrl.text.trim());
                    final checkRes = await ref.read(activeOrdersProvider.notifier).checkout(
                          order.id,
                          paymentMethod: selectedPaymentMethod,
                          manualDiscount: disc,
                        );

                    if (!mounted) return;
                    if (checkRes.success && checkRes.data != null) {
                      final completed = checkRes.data!;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Order completed! Bill: ${completed.billNo ?? completed.orderNo}')),
                      );
                      setState(() {});
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(backgroundColor: AppColors.chilli, content: Text(checkRes.message)),
                      );
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- Cancel Order (#51) ---
  Future<void> _confirmCancelOrder(Order order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Order'),
        content: Text('Are you sure you want to cancel order ${order.orderNo}?\n\nThis will mark all items as cancelled and free the table.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No, Keep Order')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, Cancel Order', style: TextStyle(color: AppColors.chilli)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final res = await ref.read(activeOrdersProvider.notifier).cancelOrder(order.id);
      if (!mounted) return;
      if (res.success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order cancelled and table freed')));
        setState(() {});
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: AppColors.chilli, content: Text(res.message)));
      }
    }
  }

  // --- Chips Helpers ---
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
      child: Text(status.toUpperCase(), style: TextStyle(color: text, fontSize: 11, fontWeight: FontWeight.bold)),
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
      child: Text(status.toUpperCase(), style: TextStyle(color: text, fontSize: 11, fontWeight: FontWeight.bold)),
    );
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(status.toUpperCase(), style: TextStyle(color: text, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}

class _CartEntry {
  final MenuItem item;
  int quantity;
  String notes;

  _CartEntry({required this.item, required this.quantity}) : notes = '';
}
