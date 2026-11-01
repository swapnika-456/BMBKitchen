import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/money/money_format.dart';
import '../core/money/paise.dart';
import '../models/models.dart';
import 'mock_seed.dart';

class BmbState {
  final String activeOutletId;
  final String currentUserId;
  final RestaurantSetup setup;

  final List<Role> roles;
  final List<Staff> staff;
  final List<String> categories;
  final List<MenuItem> menuItems;
  final List<RestaurantTable> tables;
  final List<Order> orders;
  final List<Customer> customers;
  final List<Offer> offers;
  final LoyaltySettings loyalty;
  final List<StockItem> stockItems;
  final Map<String, Recipe> recipes;
  final List<Purchase> purchases;
  final List<Vendor> vendors;
  final List<Expense> expenses;
  final List<DayClosing> dayClosings;
  final List<Printer> printers;
  final List<AppNotification> notifications;
  final List<Integration> integrations;
  final List<StockMovement> stockMovements;
  final List<CentralKitchenIndent> indents;
  final List<LegacyMockSupportTicket> tickets;
  final SubscriptionInfo subscription;
  final NotificationChannels notificationChannels;
  final NotificationEvents notificationEvents;
  final int orderSeq;
  final int kotSeq;
  final int tokenSeq;
  final int billSeq;
  final int poSeq;
  final bool isEmptyDemo;

  const BmbState({
    required this.activeOutletId,
    required this.currentUserId,
    required this.setup,

    required this.roles,
    required this.staff,
    required this.categories,
    required this.menuItems,
    required this.tables,
    required this.orders,
    required this.customers,
    required this.offers,
    required this.loyalty,
    required this.stockItems,
    required this.recipes,
    required this.purchases,
    required this.vendors,
    required this.expenses,
    required this.dayClosings,
    required this.printers,
    required this.notifications,
    required this.integrations,
    this.stockMovements = const [],
    this.indents = const [],
    this.tickets = const [],
    this.subscription = const SubscriptionInfo(
      plan: 'Growth',
      price: Paise(499900),
      cycle: 'monthly',
      outlets: 2,
      started: '2026-01-15',
      renews: '2026-08-15',
      status: 'active',
      invoices: [
        LegacyMockSubscriptionInvoice(
          no: 'BMB-INV-0041',
          date: '2026-07-15',
          amt: Paise(499900),
          status: 'Paid',
        ),
        LegacyMockSubscriptionInvoice(
          no: 'BMB-INV-0033',
          date: '2026-06-15',
          amt: Paise(499900),
          status: 'Paid',
        ),
        LegacyMockSubscriptionInvoice(
          no: 'BMB-INV-0025',
          date: '2026-05-15',
          amt: Paise(499900),
          status: 'Paid',
        ),
      ],
    ),
    this.notificationChannels = const NotificationChannels(),
    this.notificationEvents = const NotificationEvents(),
    this.orderSeq = 42,
    this.kotSeq = 18,
    this.tokenSeq = 14,
    this.billSeq = 38,
    this.poSeq = 4,
    this.isEmptyDemo = false,
  });

  Staff get currentUser =>
      staff.firstWhere((s) => s.id == currentUserId, orElse: () => staff.first);

  Role get currentUserRole => roles.firstWhere(
    (r) => r.id == currentUser.role,
    orElse: () => roles.first,
  );

  BmbState copyWith({
    String? activeOutletId,
    String? currentUserId,
    RestaurantSetup? setup,

    List<Role>? roles,
    List<Staff>? staff,
    List<String>? categories,
    List<MenuItem>? menuItems,
    List<RestaurantTable>? tables,
    List<Order>? orders,
    List<Customer>? customers,
    List<Offer>? offers,
    LoyaltySettings? loyalty,
    List<StockItem>? stockItems,
    Map<String, Recipe>? recipes,
    List<Purchase>? purchases,
    List<Vendor>? vendors,
    List<Expense>? expenses,
    List<DayClosing>? dayClosings,
    List<Printer>? printers,
    List<AppNotification>? notifications,
    List<Integration>? integrations,
    List<StockMovement>? stockMovements,
    List<CentralKitchenIndent>? indents,
    List<LegacyMockSupportTicket>? tickets,
    SubscriptionInfo? subscription,
    NotificationChannels? notificationChannels,
    NotificationEvents? notificationEvents,
    int? orderSeq,
    int? kotSeq,
    int? tokenSeq,
    int? billSeq,
    int? poSeq,
    bool? isEmptyDemo,
  }) {
    return BmbState(
      activeOutletId: activeOutletId ?? this.activeOutletId,
      currentUserId: currentUserId ?? this.currentUserId,
      setup: setup ?? this.setup,

      roles: roles ?? this.roles,
      staff: staff ?? this.staff,
      categories: categories ?? this.categories,
      menuItems: menuItems ?? this.menuItems,
      tables: tables ?? this.tables,
      orders: orders ?? this.orders,
      customers: customers ?? this.customers,
      offers: offers ?? this.offers,
      loyalty: loyalty ?? this.loyalty,
      stockItems: stockItems ?? this.stockItems,
      recipes: recipes ?? this.recipes,
      purchases: purchases ?? this.purchases,
      vendors: vendors ?? this.vendors,
      expenses: expenses ?? this.expenses,
      dayClosings: dayClosings ?? this.dayClosings,
      printers: printers ?? this.printers,
      notifications: notifications ?? this.notifications,
      integrations: integrations ?? this.integrations,
      stockMovements: stockMovements ?? this.stockMovements,
      indents: indents ?? this.indents,
      tickets: tickets ?? this.tickets,
      subscription: subscription ?? this.subscription,
      notificationChannels: notificationChannels ?? this.notificationChannels,
      notificationEvents: notificationEvents ?? this.notificationEvents,
      orderSeq: orderSeq ?? this.orderSeq,
      kotSeq: kotSeq ?? this.kotSeq,
      tokenSeq: tokenSeq ?? this.tokenSeq,
      billSeq: billSeq ?? this.billSeq,
      poSeq: poSeq ?? this.poSeq,
      isEmptyDemo: isEmptyDemo ?? this.isEmptyDemo,
    );
  }
}

class BmbStateNotifier extends Notifier<BmbState> {
  @override
  BmbState build() {
    return _initialState();
  }

  static BmbState _initialState() {
    final state = BmbState(
      activeOutletId: 'o1',
      currentUserId: 's1',
      setup: MockSeedData.createSetup(),

      roles: MockSeedData.createRoles(),
      staff: MockSeedData.createStaff(),
      categories: MockSeedData.createCategories(),
      menuItems: MockSeedData.createMenuItems(),
      tables: MockSeedData.createTables(),
      orders: const [],
      customers: MockSeedData.createCustomers(),
      offers: MockSeedData.createOffers(),
      loyalty: MockSeedData.createLoyalty(),
      stockItems: MockSeedData.createStockItems(),
      recipes: MockSeedData.createRecipes(),
      purchases: MockSeedData.createPurchases(),
      vendors: MockSeedData.createVendors(),
      expenses: MockSeedData.createExpenses(),
      dayClosings: const [],
      printers: MockSeedData.createPrinters(),
      notifications: MockSeedData.createNotifications(),
      integrations: MockSeedData.createIntegrations(),
      stockMovements: MockSeedData.createStockMovements(),
      indents: MockSeedData.createIndents(),
      tickets: MockSeedData.createTickets(),
    );

    return _seedInitialOrders(state);
  }

  static BmbState _seedInitialOrders(BmbState s) {
    final now = DateTime.now().millisecondsSinceEpoch;

    // Seed historical completed orders for realistic analytics
    final completedOrders = <Order>[];
    final itemsPool = s.menuItems;
    final paymentModes = [
      PaymentMode.cash,
      PaymentMode.upi,
      PaymentMode.card,
      PaymentMode.upi,
    ];

    for (int i = 1; i <= 12; i++) {
      final item1 = itemsPool[i % itemsPool.length];
      final item2 = itemsPool[(i + 3) % itemsPool.length];
      final line1 = OrderLine(
        sig: OrderLine.generateSig(itemId: item1.id),
        itemId: item1.id,
        name: item1.name,
        qty: 1,
        unitPrice: item1.price,
      );
      final line2 = OrderLine(
        sig: OrderLine.generateSig(itemId: item2.id),
        itemId: item2.id,
        name: item2.name,
        qty: 2,
        unitPrice: item2.price,
      );

      final orderTime = now - (12 - i) * 28 * 60000;
      final mode = paymentModes[i % paymentModes.length];
      final sub = line1.lineTotal + line2.lineTotal;
      final totals = OrderTotals.calculate(
        subtotal: sub,
        discount: const Paise(0),
        serviceChargePct: 0.0,
        applyServiceCharge: false,
        taxPct: 5.0,
        loyaltyRedemption: const Paise(0),
      );

      completedOrders.add(
        Order(
          id: 'O$i',
          no: i,
          type: i % 3 == 0
              ? OrderType.takeaway
              : (i % 4 == 0 ? OrderType.delivery : OrderType.dinein),
          src: OrderSource.pos,
          tableId: i % 3 == 0 || i % 4 == 0 ? null : 'T${(i % 8) + 1}',
          token: i % 3 == 0 || i % 4 == 0 ? i : null,
          outlet: 'o1',
          items: [line1, line2],
          payments: [PaymentRecord(mode: mode, amount: totals.total)],
          status: OrderStatus.completed,
          createdAtMs: orderTime,
          closedAtMs: orderTime + 20 * 60000,
          staffId: 's1',
          billNo: 'BMB-${i.toString().padLeft(4, '0')}',
        ),
      );
    }

    // Seed one active occupied table with a live order
    final biryani = itemsPool.firstWhere((m) => m.id == 'm10');
    final naan = itemsPool.firstWhere((m) => m.id == 'm13');
    final activeLines = [
      OrderLine(
        sig: OrderLine.generateSig(
          itemId: biryani.id,
          variant: 'Full',
          addons: ['Raita'],
          note: 'Less spicy',
        ),
        itemId: biryani.id,
        name: biryani.name,
        qty: 1,
        variant: 'Full',
        addons: const ['Raita'],
        unitPrice: Paise.fromRupees(280 + 30),
        note: 'Less spicy',
        kotNo: 1,
      ),
      OrderLine(
        sig: OrderLine.generateSig(itemId: naan.id),
        itemId: naan.id,
        name: naan.name,
        qty: 2,
        unitPrice: naan.price,
        kotNo: 1,
      ),
    ];

    final liveKot = KOT(
      id: 'K1',
      no: 1,
      orderId: 'O13',
      items: activeLines,
      status: KOTStatus.preparing,
      createdAtMs: now - 8 * 60000, // 8 minutes ago (approaching threshold)
      printer: 'Hot Kitchen KOT',
    );

    final liveOrder = Order(
      id: 'O13',
      no: 13,
      type: OrderType.dinein,
      tableId: 'T3',
      outlet: 'o1',
      items: activeLines,
      pending: const [],
      kots: [liveKot],
      status: OrderStatus.open,
      createdAtMs: now - 9 * 60000,
      staffId: 's1',
    );

    // Seed live online orders (matching HTML spec VIEWS.online)
    final paneer = itemsPool.firstWhere((m) => m.id == 'm5');
    final newOnlineOrder = Order(
      id: 'O14',
      no: 14,
      type: OrderType.online,
      src: OrderSource.zomato,
      outlet: 'o1',
      customerName: 'Akshaya S (Shanthi Colony)',
      pending: [
        OrderLine(
          sig: OrderLine.generateSig(itemId: paneer.id),
          itemId: paneer.id,
          name: paneer.name,
          qty: 1,
          unitPrice: paneer.price,
        ),
        OrderLine(
          sig: OrderLine.generateSig(itemId: naan.id),
          itemId: naan.id,
          name: naan.name,
          qty: 3,
          unitPrice: naan.price,
        ),
      ],
      deliveryStatus: 'new',
      channel: 'Zomato',
      status: OrderStatus.open,
      createdAtMs: now - 2 * 60000, // 2 minutes ago
      staffId: 's1',
    );

    final chicken = itemsPool.firstWhere((m) => m.id == 'm2');
    final prepKot = KOT(
      id: 'K2',
      no: 2,
      orderId: 'O15',
      items: [
        OrderLine(
          sig: OrderLine.generateSig(itemId: chicken.id),
          itemId: chicken.id,
          name: chicken.name,
          qty: 2,
          unitPrice: chicken.price,
          kotNo: 2,
        ),
      ],
      status: KOTStatus.preparing,
      createdAtMs: now - 6 * 60000,
      printer: 'Hot Kitchen KOT',
    );
    final prepOnlineOrder = Order(
      id: 'O15',
      no: 15,
      type: OrderType.online,
      src: OrderSource.swiggy,
      outlet: 'o1',
      customerName: 'Karthik Raja (Kilpauk)',
      items: prepKot.items,
      pending: const [],
      kots: [prepKot],
      deliveryStatus: 'preparing',
      channel: 'Swiggy',
      status: OrderStatus.open,
      payments: [
        PaymentRecord(mode: PaymentMode.online, amount: Paise.fromRupees(480)),
      ],
      createdAtMs: now - 6 * 60000,
      staffId: 's1',
      billNo: 'BMB-0015',
    );

    // Mark T3 as occupied
    final updatedTables = s.tables.map((t) {
      if (t.id == 'T3') {
        return t.copyWith(status: TableStatus.occupied, orderId: liveOrder.id);
      }
      return t;
    }).toList();

    return s.copyWith(
      orders: [...completedOrders, liveOrder, newOnlineOrder, prepOnlineOrder],
      tables: updatedTables,
      orderSeq: 15,
      kotSeq: 2,
    );
  }

  // --- Context controls ---
  void switchOutlet(String id) {
    state = state.copyWith(activeOutletId: id);
  }

  void setCurrentUser(String staffId) {
    state = state.copyWith(currentUserId: staffId);
  }

  void toggleEmptyState() {
    state = state.copyWith(isEmptyDemo: !state.isEmptyDemo);
  }

  void resetAllData() {
    state = BmbState(
      activeOutletId: 'o1',
      currentUserId: 's1',
      setup: MockSeedData.createSetup(),

      roles: MockSeedData.createRoles(),
      staff: MockSeedData.createStaff(),
      categories: MockSeedData.createCategories(),
      menuItems: MockSeedData.createMenuItems(),
      tables: MockSeedData.createTables(),
      orders: const [],
      customers: MockSeedData.createCustomers(),
      offers: MockSeedData.createOffers(),
      loyalty: MockSeedData.createLoyalty(),
      stockItems: MockSeedData.createStockItems(),
      recipes: MockSeedData.createRecipes(),
      purchases: const [],
      vendors: MockSeedData.createVendors(),
      expenses: const [],
      dayClosings: const [],
      printers: MockSeedData.createPrinters(),
      notifications: const [],
      integrations: MockSeedData.createIntegrations(),
      isEmptyDemo: false,
    );
  }

  void reloadDemoData() {
    state = _initialState();
  }

  // --- Order lifecycle ---
  Order startNewOrder({
    required OrderType type,
    String? tableId,
    OrderSource src = OrderSource.pos,
  }) {
    final nextOrderSeq = state.orderSeq + 1;
    final nextTokenSeq =
        (type == OrderType.takeaway || type == OrderType.delivery)
        ? state.tokenSeq + 1
        : state.tokenSeq;

    final newOrder = Order(
      id: 'O$nextOrderSeq',
      no: nextOrderSeq,
      type: type,
      src: src,
      tableId: tableId,
      outlet: state.activeOutletId,
      token: (type == OrderType.takeaway || type == OrderType.delivery)
          ? nextTokenSeq
          : null,
      createdAtMs: DateTime.now().millisecondsSinceEpoch,
      staffId: state.currentUserId,
    );

    var updatedTables = state.tables;
    if (tableId != null) {
      updatedTables = state.tables.map((t) {
        if (t.id == tableId) {
          return t.copyWith(status: TableStatus.occupied, orderId: newOrder.id);
        }
        return t;
      }).toList();
    }

    state = state.copyWith(
      orders: [...state.orders, newOrder],
      tables: updatedTables,
      orderSeq: nextOrderSeq,
      tokenSeq: nextTokenSeq,
    );

    return newOrder;
  }

  void addLineToPending(
    String orderId,
    MenuItem item, {
    MenuVariant? variant,
    List<MenuAddon> addons = const [],
    String note = '',
  }) {
    final order = state.orders.firstWhere((o) => o.id == orderId);
    final sig = OrderLine.generateSig(
      itemId: item.id,
      variant: variant?.name,
      addons: addons.map((a) => a.name).toList(),
      note: note,
    );

    final existingIndex = order.pending.indexWhere((line) => line.sig == sig);
    final unitPrice = item.calculateUnitPrice(
      variant: variant,
      selectedAddons: addons,
    );

    List<OrderLine> updatedPending;
    if (existingIndex >= 0) {
      // Stacking rule: Identical configurations stack quantity
      final existing = order.pending[existingIndex];
      updatedPending = [...order.pending];
      updatedPending[existingIndex] = existing.copyWith(qty: existing.qty + 1);
    } else {
      // Different configurations stay separate lines
      final newLine = OrderLine(
        sig: sig,
        itemId: item.id,
        name: item.name,
        qty: 1,
        variant: variant?.name,
        addons: addons.map((a) => a.name).toList(),
        unitPrice: unitPrice,
        note: note,
      );
      updatedPending = [...order.pending, newLine];
    }

    final updatedOrder = order.copyWith(pending: updatedPending);
    state = state.copyWith(
      orders: state.orders
          .map((o) => o.id == orderId ? updatedOrder : o)
          .toList(),
    );
  }

  void updatePendingQty(String orderId, int index, int delta) {
    final order = state.orders.firstWhere((o) => o.id == orderId);
    if (index < 0 || index >= order.pending.length) return;

    final line = order.pending[index];
    final newQty = line.qty + delta;

    final updatedPending = [...order.pending];
    if (newQty <= 0) {
      updatedPending.removeAt(index);
    } else {
      updatedPending[index] = line.copyWith(qty: newQty);
    }

    final updatedOrder = order.copyWith(pending: updatedPending);
    state = state.copyWith(
      orders: state.orders
          .map((o) => o.id == orderId ? updatedOrder : o)
          .toList(),
    );
  }

  void sendOrderKOT(String orderId) {
    final order = state.orders.firstWhere((o) => o.id == orderId);
    if (order.pending.isEmpty) return;

    final nextKotSeq = state.kotSeq + 1;
    final kotNo = nextKotSeq;

    // Determine printer station by category
    final cats = order.pending
        .map((l) {
          final it = state.menuItems.firstWhere((m) => m.id == l.itemId);
          return it.cat;
        })
        .toSet()
        .toList();

    String printerName = 'Hot Kitchen KOT';
    for (final p in state.printers) {
      if (p.isKot &&
          p.active &&
          cats.any((c) => p.cats.contains(c))) {
        printerName = p.name;
        break;
      }
    }

    final sentLines = order.pending
        .map((l) => l.copyWith(kotNo: kotNo))
        .toList();
    final newKot = KOT(
      id: 'K$nextKotSeq',
      no: kotNo,
      orderId: order.id,
      items: sentLines,
      status: KOTStatus.newKot,
      createdAtMs: DateTime.now().millisecondsSinceEpoch,
      printer: printerName,
    );

    // Automatic recipe deduction
    _consumeStockForLines(order.pending);

    final updatedOrder = order.copyWith(
      items: [...order.items, ...sentLines],
      pending: const [],
      kots: [...order.kots, newKot],
    );

    state = state.copyWith(
      orders: state.orders
          .map((o) => o.id == orderId ? updatedOrder : o)
          .toList(),
      kotSeq: nextKotSeq,
    );
  }

  void advanceKot(String kotId) {
    var updatedOrders = <Order>[];
    for (final order in state.orders) {
      final kotIndex = order.kots.indexWhere((k) => k.id == kotId);
      if (kotIndex >= 0) {
        final kot = order.kots[kotIndex];
        KOTStatus? nextStatus;
        switch (kot.status) {
          case KOTStatus.newKot:
            nextStatus = KOTStatus.accepted;
            break;
          case KOTStatus.accepted:
            nextStatus = KOTStatus.preparing;
            break;
          case KOTStatus.preparing:
            nextStatus = KOTStatus.ready;
            break;
          case KOTStatus.ready:
            nextStatus = KOTStatus.completed;
            break;
          default:
            nextStatus = null;
        }

        if (nextStatus != null) {
          final updatedKot = kot.copyWith(
            status: nextStatus,
            logs: [
              ...kot.logs,
              KOTStatusLog(
                status: nextStatus,
                timestamp: DateTime.now().millisecondsSinceEpoch,
              ),
            ],
          );
          final updatedKots = [...order.kots]..[kotIndex] = updatedKot;
          updatedOrders.add(order.copyWith(kots: updatedKots));
        } else {
          updatedOrders.add(order);
        }
      } else {
        updatedOrders.add(order);
      }
    }

    state = state.copyWith(orders: updatedOrders);
  }

  void cancelKot(String kotId, String reason) {
    var updatedOrders = <Order>[];
    for (final order in state.orders) {
      final kotIndex = order.kots.indexWhere((k) => k.id == kotId);
      if (kotIndex >= 0) {
        final kot = order.kots[kotIndex];
        final updatedKot = kot.copyWith(status: KOTStatus.cancelled);
        final updatedKots = [...order.kots]..[kotIndex] = updatedKot;

        // Remove cancelled items from the running bill
        final remainingItems = order.items
            .where((l) => l.kotNo != kot.no)
            .toList();
        updatedOrders.add(
          order.copyWith(items: remainingItems, kots: updatedKots),
        );
      } else {
        updatedOrders.add(order);
      }
    }

    state = state.copyWith(orders: updatedOrders);
  }

  void applyDiscount(
    String orderId, {
    required double value,
    required String type,
  }) {
    final order = state.orders.firstWhere((o) => o.id == orderId);
    final updatedOrder = order.copyWith(
      discVal: value,
      discType: type,
      offerCode: '', // mutually exclusive
    );

    state = state.copyWith(
      orders: state.orders
          .map((o) => o.id == orderId ? updatedOrder : o)
          .toList(),
    );
  }

  void applyOffer(String orderId, String code) {
    final order = state.orders.firstWhere((o) => o.id == orderId);
    final updatedOrder = order.copyWith(
      offerCode: code,
      discVal: 0, // mutually exclusive with manual discount
    );

    state = state.copyWith(
      orders: state.orders
          .map((o) => o.id == orderId ? updatedOrder : o)
          .toList(),
    );
  }

  void setLoyaltyRedeem(String orderId, Paise amount) {
    final order = state.orders.firstWhere((o) => o.id == orderId);
    final updatedOrder = order.copyWith(redeem: amount);

    state = state.copyWith(
      orders: state.orders
          .map((o) => o.id == orderId ? updatedOrder : o)
          .toList(),
    );
  }

  void attachCustomer(String orderId, Customer customer) {
    final order = state.orders.firstWhere((o) => o.id == orderId);
    final updatedOrder = order.copyWith(
      customerId: customer.id,
      customerName: customer.name,
      customerPhone: customer.phone,
      address: customer.addr,
    );

    state = state.copyWith(
      orders: state.orders
          .map((o) => o.id == orderId ? updatedOrder : o)
          .toList(),
    );
  }

  void settleBill(
    String orderId,
    List<PaymentRecord> payments, {
    Paise change = const Paise(0),
  }) {
    final order = state.orders.firstWhere((o) => o.id == orderId);
    final nextBillSeq = state.billSeq + 1;
    final billNo =
        '${state.setup.billPrefix}-${nextBillSeq.toString().padLeft(4, '0')}';

    // Free table if dine-in
    var updatedTables = state.tables;
    if (order.tableId != null) {
      updatedTables = state.tables.map((t) {
        if (t.id == order.tableId) {
          return t.copyWith(status: TableStatus.available, clearOrderId: true);
        }
        return t;
      }).toList();
    }

    // Mark remaining KOTs completed
    final updatedKots = order.kots.map((k) {
      if (k.status != KOTStatus.cancelled) {
        return k.copyWith(status: KOTStatus.completed);
      }
      return k;
    }).toList();

    final updatedOrder = order.copyWith(
      payments: payments,
      status: OrderStatus.completed,
      closedAtMs: DateTime.now().millisecondsSinceEpoch,
      billNo: billNo,
      kots: updatedKots,
    );

    state = state.copyWith(
      orders: state.orders
          .map((o) => o.id == orderId ? updatedOrder : o)
          .toList(),
      tables: updatedTables,
      billSeq: nextBillSeq,
    );
  }

  void cancelOrder(String orderId, String reason) {
    final order = state.orders.firstWhere((o) => o.id == orderId);

    var updatedTables = state.tables;
    if (order.tableId != null) {
      updatedTables = state.tables.map((t) {
        if (t.id == order.tableId) {
          return t.copyWith(status: TableStatus.available, clearOrderId: true);
        }
        return t;
      }).toList();
    }

    final updatedOrder = order.copyWith(
      status: OrderStatus.cancelled,
      cancelReason: reason,
      closedAtMs: DateTime.now().millisecondsSinceEpoch,
      kots: order.kots
          .map((k) => k.copyWith(status: KOTStatus.cancelled))
          .toList(),
    );

    state = state.copyWith(
      orders: state.orders
          .map((o) => o.id == orderId ? updatedOrder : o)
          .toList(),
      tables: updatedTables,
    );
  }

  // --- Day closing ---
  void submitDayClosing({
    required Paise actualCash,
    required String closedBy,
    String note = '',
  }) {
    final todayStr = DateTime.now().toIso8601String().split('T').first;
    final expectedCash = calculateExpectedCashForDay(todayStr);
    final diff = actualCash - expectedCash;

    final newClosing = DayClosing(
      closingDate: todayStr,
      outletId: state.activeOutletId,
      expectedCash: expectedCash.value / 100.0,
      actualCash: actualCash.value / 100.0,
      difference: diff.value / 100.0,
      closedBy: closedBy,
      note: note,
      createdAt: DateTime.now(),
    );

    state = state.copyWith(dayClosings: [...state.dayClosings, newClosing]);
  }

  void reopenDayClosing(String date) {
    state = state.copyWith(
      dayClosings: state.dayClosings
          .where((c) => !(c.date == date && c.outlet == state.activeOutletId))
          .toList(),
    );
  }

  Paise calculateExpectedCashForDay(String dateStr) {
    var cashSales = const Paise(0);
    for (final o in state.orders) {
      if (o.status == OrderStatus.completed &&
          o.outlet == state.activeOutletId) {
        final orderDate = DateTime.fromMillisecondsSinceEpoch(
          o.createdAtMs,
        ).toIso8601String().split('T').first;
        if (orderDate == dateStr) {
          for (final p in o.payments) {
            if (p.mode == PaymentMode.cash) {
              cashSales = cashSales + p.amount;
            }
          }
        }
      }
    }

    var cashExpenses = const Paise(0);
    for (final e in state.expenses) {
      if (e.date == dateStr && e.outlet == state.activeOutletId && e.isCash) {
        cashExpenses = cashExpenses + e.amt;
      }
    }

    return cashSales - cashExpenses;
  }

  // --- Helpers ---
  void _consumeStockForLines(List<OrderLine> lines) {
    final updatedStock = [...state.stockItems];
    for (final line in lines) {
      final recipe = state.recipes[line.itemId];
      if (recipe != null) {
        for (final ing in recipe.ingredients) {
          final stockIdx = updatedStock.indexWhere((s) => s.id == ing.ing);
          if (stockIdx >= 0) {
            final s = updatedStock[stockIdx];
            final consumed = ing.qty * line.qty;
            updatedStock[stockIdx] = s.copyWith(
              qty: double.parse((s.qty - consumed).toStringAsFixed(3)),
            );
          }
        }
      }
    }
    state = state.copyWith(stockItems: updatedStock);
  }

  void toggleItemAvailability(String itemId) {
    state = state.copyWith(
      menuItems: state.menuItems.map((m) {
        if (m.id == itemId) return m.copyWith(avail: !m.avail);
        return m;
      }).toList(),
    );
  }

  Paise? calculateFoodCost(String itemId) {
    final recipe = state.recipes[itemId];
    if (recipe == null || recipe.ingredients.isEmpty) return null;

    var totalCost = const Paise(0);
    for (final ing in recipe.ingredients) {
      final stockItem = state.stockItems.firstWhere(
        (s) => s.id == ing.ing,
        orElse: () => const StockItem(
          id: '',
          name: '',
          unit: '',
          qty: 0,
          min: 0,
          rate: Paise(0),
          cat: '',
          vendor: '',
        ),
      );
      if (stockItem.id.isNotEmpty) {
        totalCost = totalCost + (stockItem.rate * ing.qty);
      }
    }
    return totalCost;
  }

  void addCategory(String categoryName) {
    final trimmed = categoryName.trim();
    if (trimmed.isEmpty || state.categories.contains(trimmed)) return;
    state = state.copyWith(categories: [...state.categories, trimmed]);
  }

  void saveMenuItem(MenuItem item) {
    final exists = state.menuItems.any((m) => m.id == item.id);
    if (exists) {
      state = state.copyWith(
        menuItems: state.menuItems
            .map((m) => m.id == item.id ? item : m)
            .toList(),
      );
    } else {
      state = state.copyWith(menuItems: [...state.menuItems, item]);
    }
  }

  void deleteMenuItem(String itemId) {
    final updatedRecipes = Map<String, Recipe>.from(state.recipes)
      ..remove(itemId);
    state = state.copyWith(
      menuItems: state.menuItems.where((m) => m.id != itemId).toList(),
      recipes: updatedRecipes,
    );
  }

  void saveTable(RestaurantTable table) {
    final exists = state.tables.any((t) => t.id == table.id);
    if (exists) {
      state = state.copyWith(
        tables: state.tables.map((t) => t.id == table.id ? table : t).toList(),
      );
    } else {
      state = state.copyWith(tables: [...state.tables, table]);
    }
  }

  bool deleteTable(String tableId) {
    final table = state.tables.firstWhere((t) => t.id == tableId);
    if (table.isOccupied) return false;
    state = state.copyWith(
      tables: state.tables.where((t) => t.id != tableId).toList(),
    );
    return true;
  }

  void releaseReservation(String tableId) {
    state = state.copyWith(
      tables: state.tables.map((t) {
        if (t.id == tableId) {
          return t.copyWith(status: TableStatus.available, clearResName: true);
        }
        return t;
      }).toList(),
    );
  }

  void saveCustomer(Customer customer) {
    final exists = state.customers.any((c) => c.id == customer.id);
    if (exists) {
      state = state.copyWith(
        customers: state.customers
            .map((c) => c.id == customer.id ? customer : c)
            .toList(),
      );
    } else {
      state = state.copyWith(customers: [customer, ...state.customers]);
    }
  }

  void removePendingLine(String orderId, int index) {
    final order = state.orders.firstWhere((o) => o.id == orderId);
    if (index < 0 || index >= order.pending.length) return;

    final updatedPending = [...order.pending]..removeAt(index);
    final updatedOrder = order.copyWith(pending: updatedPending);
    state = state.copyWith(
      orders: state.orders
          .map((o) => o.id == orderId ? updatedOrder : o)
          .toList(),
    );
  }

  void clearOrderPending(String orderId) {
    final order = state.orders.firstWhere((o) => o.id == orderId);
    final updatedOrder = order.copyWith(pending: const []);
    state = state.copyWith(
      orders: state.orders
          .map((o) => o.id == orderId ? updatedOrder : o)
          .toList(),
    );
  }

  void updateSetup(RestaurantSetup setup) {
    state = state.copyWith(setup: setup);
  }

  void saveStaff(Staff staffMember) {
    final exists = state.staff.any((s) => s.id == staffMember.id);
    if (exists) {
      state = state.copyWith(
        staff: state.staff
            .map((s) => s.id == staffMember.id ? staffMember : s)
            .toList(),
      );
    } else {
      state = state.copyWith(staff: [...state.staff, staffMember]);
    }
  }

  void deleteStaff(String staffId) {
    state = state.copyWith(
      staff: state.staff.where((s) => s.id != staffId).toList(),
    );
  }

  void saveRole(Role role) {
    final exists = state.roles.any((r) => r.id == role.id);
    if (exists) {
      state = state.copyWith(
        roles: state.roles.map((r) => r.id == role.id ? role : r).toList(),
      );
    } else {
      state = state.copyWith(roles: [...state.roles, role]);
    }
  }

  void savePrinter(Printer printer) {
    final exists = state.printers.any((p) => p.id == printer.id);
    if (exists) {
      state = state.copyWith(
        printers: state.printers
            .map((p) => p.id == printer.id ? printer : p)
            .toList(),
      );
    } else {
      state = state.copyWith(printers: [...state.printers, printer]);
    }
  }

  void deletePrinter(String printerId) {
    state = state.copyWith(
      printers: state.printers.where((p) => p.id != printerId).toList(),
    );
  }

  // --- Expenses ---
  void saveExpense(Expense expense) {
    state = state.copyWith(expenses: [expense, ...state.expenses]);
  }

  void deleteExpense(String id) {
    state = state.copyWith(
      expenses: state.expenses.where((e) => e.id != id).toList(),
    );
  }

  // --- Offers & Loyalty ---
  void saveOffer(Offer offer) {
    final exists = state.offers.any((o) => o.id == offer.id);
    if (exists) {
      state = state.copyWith(
        offers: state.offers.map((o) => o.id == offer.id ? offer : o).toList(),
      );
    } else {
      state = state.copyWith(offers: [...state.offers, offer]);
    }
  }

  void toggleOffer(String offerId) {
    state = state.copyWith(
      offers: state.offers
          .map((o) => o.id == offerId ? o.copyWith(active: !o.active) : o)
          .toList(),
    );
  }

  void deleteCustomer(String customerId) {
    state = state.copyWith(
      customers: state.customers.where((c) => c.id != customerId).toList(),
    );
  }

  void deleteOffer(String offerId) {
    state = state.copyWith(
      offers: state.offers.where((o) => o.id != offerId).toList(),
    );
  }

  void updateLoyalty(LoyaltySettings loyalty) {
    state = state.copyWith(loyalty: loyalty);
  }

  // --- Notifications ---
  void addNotification(AppNotification notif) {
    state = state.copyWith(notifications: [notif, ...state.notifications]);
  }

  void markNotificationRead(String id) {
    state = state.copyWith(
      notifications: state.notifications
          .map((n) => n.id == id ? n.copyWith(read: true) : n)
          .toList(),
    );
  }

  void markAllNotificationsRead() {
    state = state.copyWith(
      notifications: state.notifications
          .map((n) => n.copyWith(read: true))
          .toList(),
    );
  }

  void toggleNotificationChannel(String channel) {
    final ch = state.notificationChannels;
    if (channel == 'whatsapp') {
      state = state.copyWith(
        notificationChannels: ch.copyWith(whatsapp: !ch.whatsapp),
      );
    } else if (channel == 'sms') {
      state = state.copyWith(notificationChannels: ch.copyWith(sms: !ch.sms));
    } else if (channel == 'email') {
      state = state.copyWith(
        notificationChannels: ch.copyWith(email: !ch.email),
      );
    }
  }

  void toggleNotificationEvent(String event) {
    final ev = state.notificationEvents;
    if (event == 'billShare') {
      state = state.copyWith(
        notificationEvents: ev.copyWith(billShare: !ev.billShare),
      );
    } else if (event == 'orderReady') {
      state = state.copyWith(
        notificationEvents: ev.copyWith(orderReady: !ev.orderReady),
      );
    } else if (event == 'lowStock') {
      state = state.copyWith(
        notificationEvents: ev.copyWith(lowStock: !ev.lowStock),
      );
    } else if (event == 'dayClosing') {
      state = state.copyWith(
        notificationEvents: ev.copyWith(dayClosing: !ev.dayClosing),
      );
    } else if (event == 'newOnline') {
      state = state.copyWith(
        notificationEvents: ev.copyWith(newOnline: !ev.newOnline),
      );
    } else if (event == 'offerBlast') {
      state = state.copyWith(
        notificationEvents: ev.copyWith(offerBlast: !ev.offerBlast),
      );
    }
  }

  // --- Integrations ---
  void toggleIntegration(String id) {
    state = state.copyWith(
      integrations: state.integrations.map((i) {
        if (i.id == id) {
          final isConn = i.status == 'connected';
          return i.copyWith(
            status: isConn ? 'not_connected' : 'connected',
            since: isConn
                ? ''
                : DateTime.now().toIso8601String().substring(0, 10),
          );
        }
        return i;
      }).toList(),
    );
  }

  // --- Outlets ---
  // Outlets methods removed as they are now handled by OutletController

  // --- Central Kitchen ---
  void saveIndent(CentralKitchenIndent indent) {
    state = state.copyWith(indents: [indent, ...state.indents]);
  }

  void updateIndentStatus(String id, String status) {
    state = state.copyWith(
      indents: state.indents
          .map((i) => i.id == id ? i.copyWith(status: status) : i)
          .toList(),
    );
  }

  void advanceIndentStatus(String id) {
    const nextStatus = {
      'Requested': 'Approved',
      'Approved': 'Dispatched',
      'Dispatched': 'Received',
    };
    state = state.copyWith(
      indents: state.indents.map((t) {
        if (t.id == id) {
          final next = nextStatus[t.status] ?? t.status;
          return t.copyWith(status: next);
        }
        return t;
      }).toList(),
    );
  }

  // --- Subscription ---
  void changeSubscriptionPlan(String name, Paise price, int outlets) {
    state = state.copyWith(
      subscription: state.subscription.copyWith(
        plan: name,
        price: price,
        outlets: outlets,
      ),
    );
  }

  // --- Support ---
  void saveTicket(LegacyMockSupportTicket ticket) {
    state = state.copyWith(tickets: [ticket, ...state.tickets]);
  }

  void updateTicketStatus(String id, String status) {
    state = state.copyWith(
      tickets: state.tickets
          .map((t) => t.id == id ? t.copyWith(status: status) : t)
          .toList(),
    );
  }

  void cycleTicketStatus(String id) {
    state = state.copyWith(
      tickets: state.tickets.map((t) {
        if (t.id == id) {
          final next = t.status == 'Open'
              ? 'In progress'
              : t.status == 'In progress'
              ? 'Closed'
              : 'Open';
          return t.copyWith(status: next);
        }
        return t;
      }).toList(),
    );
  }

  // --- Online Orders (matching VIEWS.online in HTML spec) ---
  void simulateOnlineOrder() {
    final channels = ['Swiggy', 'Zomato', 'Website'];
    final names = ['Anitha', 'Prakash', 'Deepa', 'Ravi', 'Sneha'];
    final selectedChannel =
        channels[DateTime.now().millisecond % channels.length];
    final selectedCustomer = names[DateTime.now().second % names.length];

    final nextNo = state.orderSeq + 1;
    final nextToken = state.tokenSeq + 1;
    final pool = state.menuItems.where((m) => m.avail).toList();
    if (pool.isEmpty) return;

    final pending = <OrderLine>[];
    final itemCount = (DateTime.now().second % 2) + 2; // 2 or 3 items
    for (int i = 0; i < itemCount; i++) {
      final item = pool[(DateTime.now().millisecond + i * 3) % pool.length];
      pending.add(
        OrderLine(
          sig: OrderLine.generateSig(itemId: item.id),
          itemId: item.id,
          name: item.name,
          qty: (i == 0) ? 2 : 1,
          unitPrice: item.price,
        ),
      );
    }

    final newOrder = Order(
      id: 'O$nextNo',
      no: nextNo,
      type: OrderType.online,
      src: selectedChannel == 'Website'
          ? OrderSource.pos
          : (selectedChannel == 'Swiggy'
                ? OrderSource.swiggy
                : OrderSource.zomato),
      outlet: state.activeOutletId,
      token: nextToken,
      customerName: selectedCustomer,
      pending: pending,
      deliveryStatus: 'new',
      channel: selectedChannel,
      status: OrderStatus.open,
      createdAtMs: DateTime.now().millisecondsSinceEpoch,
      staffId: state.currentUserId,
    );

    final newNotification = AppNotification(
      id: 'n_${DateTime.now().millisecondsSinceEpoch}',
      type: 'online',
      text: 'New $selectedChannel order #${newOrder.no} from $selectedCustomer',
      at: DateTime.now().millisecondsSinceEpoch,
    );

    state = state.copyWith(
      orders: [newOrder, ...state.orders],
      orderSeq: nextNo,
      tokenSeq: nextToken,
      notifications: [newNotification, ...state.notifications],
    );
  }

  void acceptOnlineOrder(String orderId) {
    final order = state.orders.firstWhere((o) => o.id == orderId);
    if (order.pending.isEmpty && order.items.isEmpty) return;

    final nextKotSeq = state.kotSeq + 1;
    final linesToSent = order.pending.isNotEmpty ? order.pending : order.items;
    final sentLines = linesToSent
        .map((l) => l.copyWith(kotNo: nextKotSeq))
        .toList();

    _consumeStockForLines(sentLines);

    final newKot = KOT(
      id: 'K$nextKotSeq',
      no: nextKotSeq,
      orderId: order.id,
      items: sentLines,
      status: KOTStatus.newKot,
      createdAtMs: DateTime.now().millisecondsSinceEpoch,
      printer: 'Hot Kitchen KOT',
    );

    final nextBillSeq = state.billSeq + 1;
    final billNo =
        '${state.setup.billPrefix}-${nextBillSeq.toString().padLeft(4, '0')}';
    final total = order.subtotal;

    final updatedOrder = order.copyWith(
      items: order.pending.isNotEmpty
          ? [...order.items, ...sentLines]
          : order.items,
      pending: const [],
      kots: [...order.kots, newKot],
      deliveryStatus: 'preparing',
      payments: [PaymentRecord(mode: PaymentMode.online, amount: total)],
      billNo: order.billNo ?? billNo,
    );

    final notif = AppNotification(
      id: 'n_${DateTime.now().millisecondsSinceEpoch}',
      type: 'online',
      text:
          'Accepted ${order.channel ?? 'Online'} order #${order.no} -> KOT #$nextKotSeq sent',
      at: DateTime.now().millisecondsSinceEpoch,
    );

    state = state.copyWith(
      orders: state.orders
          .map((o) => o.id == orderId ? updatedOrder : o)
          .toList(),
      kotSeq: nextKotSeq,
      billSeq: order.billNo == null ? nextBillSeq : state.billSeq,
      notifications: [notif, ...state.notifications],
    );
  }

  void rejectOnlineOrder(String orderId, String reason) {
    final order = state.orders.firstWhere((o) => o.id == orderId);
    final updatedOrder = order.copyWith(
      status: OrderStatus.cancelled,
      deliveryStatus: 'rejected',
      cancelReason: reason,
      closedAtMs: DateTime.now().millisecondsSinceEpoch,
      kots: order.kots
          .map((k) => k.copyWith(status: KOTStatus.cancelled))
          .toList(),
    );

    state = state.copyWith(
      orders: state.orders
          .map((o) => o.id == orderId ? updatedOrder : o)
          .toList(),
    );
  }

  void advanceOnlineOrder(String orderId) {
    final order = state.orders.firstWhere((o) => o.id == orderId);
    String nextDeliveryStatus = order.deliveryStatus ?? 'preparing';
    OrderStatus nextStatus = order.status;

    if (order.deliveryStatus == 'new') {
      acceptOnlineOrder(orderId);
      return;
    } else if (order.deliveryStatus == 'preparing') {
      nextDeliveryStatus = 'ready';
    } else if (order.deliveryStatus == 'ready') {
      nextDeliveryStatus = 'completed';
      nextStatus = OrderStatus.completed;
    }

    final updatedOrder = order.copyWith(
      deliveryStatus: nextDeliveryStatus,
      status: nextStatus,
      closedAtMs: nextStatus == OrderStatus.completed
          ? DateTime.now().millisecondsSinceEpoch
          : order.closedAtMs,
    );

    state = state.copyWith(
      orders: state.orders
          .map((o) => o.id == orderId ? updatedOrder : o)
          .toList(),
    );
  }

  // --- Supply Chain: Inventory ---
  void saveStockItem(StockItem item) {
    final exists = state.stockItems.any((i) => i.id == item.id);
    state = state.copyWith(
      stockItems: exists
          ? state.stockItems.map((i) => i.id == item.id ? item : i).toList()
          : [...state.stockItems, item],
    );
  }

  void deleteStockItem(String id) {
    state = state.copyWith(
      stockItems: state.stockItems.where((i) => i.id != id).toList(),
    );
  }

  void adjustStockItem({
    required String itemId,
    required double qtyDelta,
    required String reason,
    required String type,
  }) {
    final item = state.stockItems.firstWhere((i) => i.id == itemId);
    final newQty = ((item.qty + qtyDelta) * 1000).round() / 1000;
    final updatedItem = item.copyWith(qty: newQty < 0 ? 0 : newQty);

    final movement = StockMovement(
      id: 'w_${DateTime.now().millisecondsSinceEpoch}',
      date: DateTime.now().toIso8601String().split('T').first,
      ing: itemId,
      qty: qtyDelta,
      reason: reason,
      type: type,
      by: state.currentUserId,
      outlet: state.activeOutletId,
      value: item.rate * qtyDelta.abs(),
    );

    state = state.copyWith(
      stockItems: state.stockItems
          .map((i) => i.id == itemId ? updatedItem : i)
          .toList(),
      stockMovements: [movement, ...state.stockMovements],
    );
  }

  // --- Supply Chain: Purchases ---
  void savePurchase(Purchase purchase) {
    // Generate PO Number if new
    final nextPoSeq = state.poSeq + 1;
    final poNo = purchase.no.isNotEmpty
        ? purchase.no
        : 'PO-${nextPoSeq.toString().padLeft(4, '0')}';
    final savedPurchase = purchase.copyWith(no: poNo);

    // Update stock levels and rates for all lines
    var currentStock = [...state.stockItems];
    for (final line in savedPurchase.lines) {
      final idx = currentStock.indexWhere((s) => s.id == line.ing);
      if (idx != -1) {
        final st = currentStock[idx];
        final newQty = ((st.qty + line.qty) * 1000).round() / 1000;
        currentStock[idx] = st.copyWith(qty: newQty, rate: line.rate);
      }
    }

    final newPurchases = <Purchase>[savedPurchase, ...state.purchases];

    // Recalculate vendor dues
    final updatedVendors = state.vendors.map((v) {
      return v;
    }).toList();

    state = state.copyWith(
      poSeq: nextPoSeq,
      purchases: newPurchases,
      stockItems: currentStock,
      vendors: updatedVendors,
    );
  }

  void cyclePurchasePayment(String purchaseId) {
    final purchase = state.purchases.firstWhere((p) => p.id == purchaseId);
    String nextPayStatus;
    if (purchase.payStatus == 'Unpaid') {
      nextPayStatus = 'Partial';
    } else if (purchase.payStatus == 'Partial') {
      nextPayStatus = 'Paid';
    } else {
      nextPayStatus = 'Unpaid';
    }

    final updatedPurchase = purchase.copyWith(payStatus: nextPayStatus);
    final updatedPurchases = state.purchases
        .map<Purchase>((p) => p.id == purchaseId ? updatedPurchase : p)
        .toList();

    // Recalculate vendor due
    final updatedVendors = state.vendors.map((v) {
      return v;
    }).toList();

    state = state.copyWith(
      purchases: updatedPurchases,
      vendors: updatedVendors,
    );
  }

  // --- Supply Chain: Vendors ---
  void saveVendor(Vendor vendor) {
    final exists = state.vendors.any((v) => v.id == vendor.id);
    state = state.copyWith(
      vendors: exists
          ? state.vendors.map((v) => v.id == vendor.id ? vendor : v).toList()
          : [...state.vendors, vendor],
    );
  }

  bool deleteVendor(String id) {
    final hasPurchases = state.purchases.any((p) => p.vendor == id);
    if (hasPurchases) return false;
    state = state.copyWith(
      vendors: state.vendors.where((v) => v.id != id).toList(),
    );
    return true;
  }

  // --- Supply Chain: Recipes ---
  void saveRecipe(Recipe recipe) {
    final updatedRecipes = Map<String, Recipe>.from(state.recipes);
    if (recipe.ingredients.isEmpty) {
      updatedRecipes.remove(recipe.menuItemId);
    } else {
      updatedRecipes[recipe.menuItemId] = recipe;
    }
    state = state.copyWith(recipes: updatedRecipes);
  }

  void deleteRecipe(String menuItemId) {
    final updatedRecipes = Map<String, Recipe>.from(state.recipes)
      ..remove(menuItemId);
    state = state.copyWith(recipes: updatedRecipes);
  }

  // --- Supply Chain: Wastage ---
  void recordWastage({
    required String itemId,
    required double qtyWasted,
    required String reason,
    required String date,
  }) {
    final item = state.stockItems.firstWhere((i) => i.id == itemId);
    final newQty = ((item.qty - qtyWasted) * 1000).round() / 1000;
    final updatedItem = item.copyWith(qty: newQty < 0 ? 0 : newQty);

    final movement = StockMovement(
      id: 'w_${DateTime.now().millisecondsSinceEpoch}',
      date: date.isNotEmpty
          ? date
          : DateTime.now().toIso8601String().split('T').first,
      ing: itemId,
      qty: -qtyWasted,
      reason: reason,
      type: 'Wastage',
      by: state.currentUserId,
      outlet: state.activeOutletId,
      value: item.rate * qtyWasted,
    );

    state = state.copyWith(
      stockItems: state.stockItems
          .map((i) => i.id == itemId ? updatedItem : i)
          .toList(),
      stockMovements: [movement, ...state.stockMovements],
    );
  }

  void updateDeliveryStatus(String orderId, String status, {String? rider}) {
    final order = state.orders.firstWhere((o) => o.id == orderId);
    final updatedOrder = order.copyWith(
      deliveryStatus: status,
      rider: rider ?? order.rider,
    );
    state = state.copyWith(
      orders: state.orders
          .map((o) => o.id == orderId ? updatedOrder : o)
          .toList(),
    );
  }
}

final bmbStateProvider = NotifierProvider<BmbStateNotifier, BmbState>(
  BmbStateNotifier.new,
);
