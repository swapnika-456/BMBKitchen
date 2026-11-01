import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/widgets/bmb_scaffold.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/join_organization_screen.dart';
import '../features/auth/screens/auth_gate.dart';
import '../features/auth/controllers/auth_controller.dart';
import '../features/captain/screens/captain_ordering_screen.dart';
import '../features/qr/screens/qr_ordering_screen.dart';
import '../features/delivery/screens/delivery_orders_screen.dart';
import '../features/online/screens/online_orders_screen.dart';
import '../features/crm/screens/customer_management_screen.dart';
import '../features/offers/screens/offers_management_screen.dart';
import '../features/loyalty/screens/loyalty_management_screen.dart';
import '../features/kitchen/screens/kot_management_screen.dart';
import '../features/menu/screens/menu_management_screen.dart';
import '../features/orders/screens/all_orders_screen.dart';
import '../features/orders/screens/takeaway_orders_screen.dart';
import '../features/pos/screens/pos_billing_screen.dart';
import '../features/tables/screens/table_management_screen.dart';
import '../features/dashboard/screens/dashboard_screen.dart';
import '../features/finance/screens/day_closing_screen.dart';
import '../features/finance/screens/expenses_screen.dart';
import '../features/finance/screens/payments_screen.dart';
import '../features/finance/screens/reports_screen.dart';
import '../features/settings/screens/central_kitchen_screen.dart';
import '../features/settings/screens/integrations_screen.dart';
import '../features/settings/screens/multi_outlet_screen.dart';
import '../features/settings/screens/notifications_screen.dart';
import '../features/notifications/controllers/notification_controller.dart';
import '../features/settings/screens/printer_settings_screen.dart';
import '../features/settings/screens/roles_screen.dart';
import '../features/settings/screens/setup_screen.dart';
import '../features/settings/screens/staff_screen.dart';
import '../features/settings/screens/subscription_screen.dart';
import '../features/settings/screens/support_helpdesk_screen.dart';
import '../features/settings/screens/tax_settings_screen.dart';
import '../features/settings/controllers/outlet_controller.dart';
import '../models/outlet.dart';
import '../features/supply_chain/screens/inventory_screen.dart';
import '../features/supply_chain/screens/purchase_management_screen.dart';
import '../features/supply_chain/screens/vendor_management_screen.dart';
import '../features/supply_chain/screens/recipe_management_screen.dart';
import '../features/supply_chain/screens/wastage_screen.dart';
import '../mock/mock_state.dart';

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen(authControllerProvider, (_, _) => notifyListeners());
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authControllerProvider);

      // Wait for auth to initialize before making routing decisions
      if (authState.isLoading) return null;

      final isAuth = authState.value != null;
      final isGoingToLogin = state.uri.path == '/login';
      final isGoingToRegister = state.uri.path == '/register';
      final isGoingToJoin = state.uri.path == '/join';
      final isGoingToAuthScreen =
          isGoingToLogin || isGoingToRegister || isGoingToJoin;

      if (!isAuth && !isGoingToAuthScreen) {
        return '/login';
      }

      if (isAuth && isGoingToAuthScreen) {
        return '/auth-gate';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/auth-gate',
        builder: (context, state) => const AuthGate(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/join',
        builder: (context, state) {
          final orgId = state.uri.queryParameters['orgId'];
          final role = state.uri.queryParameters['role'];
          return JoinOrganizationScreen(organizationId: orgId, role: role);
        },
      ),
      ShellRoute(
        builder: (context, state, child) {
          final bmbState = ref.watch(bmbStateProvider);
          final currentKey = state.uri.path.replaceAll('/', '');

          // Calculate live badges
          final activeKotCount = bmbState.orders
              .expand((o) => o.kots)
              .where((k) => k.status.isActive)
              .length;

          final occupiedTableCount = bmbState.tables
              .where((t) => t.isOccupied)
              .length;

          final lowStockCount = bmbState.stockItems
              .where((i) => i.isLow)
              .length;

          final openOnlineCount = bmbState.orders
              .where(
                (o) =>
                    o.outlet == bmbState.activeOutletId &&
                    o.type.name == 'online' &&
                    o.isOpen,
              )
              .length;
          final openDeliveryCount = bmbState.orders
              .where(
                (o) =>
                    o.outlet == bmbState.activeOutletId &&
                    o.type.name == 'delivery' &&
                    o.isOpen,
              )
              .length;
          final unreadNotificationCount = ref.watch(notificationBadgeProvider);
          final openSupportCount = bmbState.tickets
              .where(
                (ticket) =>
                    ticket.outlet == bmbState.activeOutletId &&
                    ticket.status != 'Closed',
              )
              .length;

          final destinations = <BmbNavDestination>[
            // Overview
            const BmbNavDestination(
              key: 'dashboard',
              label: 'Dashboard (01)',
              icon: Icon(Icons.dashboard_outlined),
              group: 'Overview',
            ),
            const BmbNavDestination(
              key: 'setup',
              label: 'Restaurant Setup (02)',
              icon: Icon(Icons.storefront_outlined),
              group: 'Overview',
            ),
            const BmbNavDestination(
              key: 'staff',
              label: 'User & Staff (03)',
              icon: Icon(Icons.people_outline),
              group: 'Overview',
            ),
            const BmbNavDestination(
              key: 'roles',
              label: 'Roles & Permissions (04)',
              icon: Icon(Icons.lock_person_outlined),
              group: 'Overview',
            ),

            // Operations
            const BmbNavDestination(
              key: 'menu',
              label: 'Menu Management (05)',
              icon: Icon(Icons.menu_book_outlined),
              group: 'Operations',
            ),
            BmbNavDestination(
              key: 'tables',
              label: 'Table Management (06)',
              icon: const Icon(Icons.table_restaurant_outlined),
              group: 'Operations',
              badgeCount: occupiedTableCount > 0 ? occupiedTableCount : null,
            ),
            const BmbNavDestination(
              key: 'pos',
              label: 'POS Billing (07)',
              icon: Icon(Icons.receipt_long_outlined),
              group: 'Operations',
            ),
            BmbNavDestination(
              key: 'kitchen',
              label: 'KOT Management (08)',
              icon: const Icon(Icons.soup_kitchen_outlined),
              group: 'Operations',
              badgeCount: activeKotCount > 0 ? activeKotCount : null,
            ),
            const BmbNavDestination(
              key: 'captain',
              label: 'Captain Ordering (09)',
              icon: Icon(Icons.phone_android_outlined),
              group: 'Operations',
            ),
            const BmbNavDestination(
              key: 'qr',
              label: 'QR Scan Ordering (10)',
              icon: Icon(Icons.qr_code_scanner_outlined),
              group: 'Operations',
            ),

            // Orders
            const BmbNavDestination(
              key: 'takeaway',
              label: 'Takeaway Orders (11)',
              icon: Icon(Icons.shopping_bag_outlined),
              group: 'Orders',
            ),
            BmbNavDestination(
              key: 'delivery',
              label: 'Delivery Orders (12)',
              icon: Icon(Icons.two_wheeler_outlined),
              badgeCount: openDeliveryCount > 0 ? openDeliveryCount : null,
              group: 'Orders',
            ),
            BmbNavDestination(
              key: 'online',
              label: 'Online Orders (13)',
              icon: Icon(Icons.language_outlined),
              badgeCount: openOnlineCount > 0 ? openOnlineCount : null,
              group: 'Orders',
            ),
            const BmbNavDestination(
              key: 'orders',
              label: 'All Orders (14)',
              icon: Icon(Icons.list_alt_outlined),
              group: 'Orders',
            ),

            // Customers
            const BmbNavDestination(
              key: 'crm',
              label: 'Customers (CRM) (15)',
              icon: Icon(Icons.favorite_border),
              group: 'Customers',
            ),
            const BmbNavDestination(
              key: 'offers',
              label: 'Offers & Discounts (16)',
              icon: Icon(Icons.discount_outlined),
              group: 'Customers',
            ),
            const BmbNavDestination(
              key: 'loyalty',
              label: 'Loyalty (17)',
              icon: Icon(Icons.star_border),
              group: 'Customers',
            ),

            // Supply Chain
            BmbNavDestination(
              key: 'stock',
              label: 'Inventory (18)',
              icon: const Icon(Icons.inventory_2_outlined),
              group: 'Supply Chain',
              badgeCount: lowStockCount > 0 ? lowStockCount : null,
            ),
            const BmbNavDestination(
              key: 'purchase',
              label: 'Purchases (19)',
              icon: Icon(Icons.shopping_cart_outlined),
              group: 'Supply Chain',
            ),
            const BmbNavDestination(
              key: 'vendors',
              label: 'Vendors (20)',
              icon: Icon(Icons.local_shipping_outlined),
              group: 'Supply Chain',
            ),
            const BmbNavDestination(
              key: 'recipes',
              label: 'Recipes & Food Cost (21)',
              icon: Icon(Icons.restaurant_menu_outlined),
              group: 'Supply Chain',
            ),
            const BmbNavDestination(
              key: 'wastage',
              label: 'Wastage & Adjustment (22)',
              icon: Icon(Icons.delete_outline),
              group: 'Supply Chain',
            ),

            // Finance
            const BmbNavDestination(
              key: 'expenses',
              label: 'Expenses (23)',
              icon: Icon(Icons.payments_outlined),
              group: 'Finance',
            ),
            const BmbNavDestination(
              key: 'reports',
              label: 'Reports & Analytics (24)',
              icon: Icon(Icons.analytics_outlined),
              group: 'Finance',
            ),
            BmbNavDestination(
              key: 'payments',
              label: 'Payments (25)',
              icon: Icon(Icons.credit_card_outlined),
              group: 'Finance',
            ),
            const BmbNavDestination(
              key: 'closing',
              label: 'Day Closing (26)',
              icon: Icon(Icons.lock_clock_outlined),
              group: 'Finance',
            ),

            // Settings
            const BmbNavDestination(
              key: 'printers',
              label: 'Printer Settings (27)',
              icon: Icon(Icons.print_outlined),
              group: 'Settings',
            ),
            const BmbNavDestination(
              key: 'taxset',
              label: 'Tax Settings (28)',
              icon: Icon(Icons.percent_outlined),
              group: 'Settings',
            ),
            const BmbNavDestination(
              key: 'outlets',
              label: 'Multi-Outlet (29)',
              icon: Icon(Icons.domain_outlined),
              group: 'Settings',
            ),
            const BmbNavDestination(
              key: 'central',
              label: 'Central Kitchen (30)',
              icon: Icon(Icons.kitchen_outlined),
              group: 'Settings',
            ),
            const BmbNavDestination(
              key: 'subs',
              label: 'Subscription & Billing (31)',
              icon: Icon(Icons.card_membership_outlined),
              group: 'Settings',
            ),
            BmbNavDestination(
              key: 'notif',
              label: 'Notifications (32)',
              icon: Icon(Icons.notifications_none_outlined),
              badgeCount: unreadNotificationCount > 0
                  ? unreadNotificationCount
                  : null,
              group: 'Settings',
            ),
            const BmbNavDestination(
              key: 'integrations',
              label: 'Integrations (33)',
              icon: Icon(Icons.extension_outlined),
              group: 'Settings',
            ),
            BmbNavDestination(
              key: 'support',
              label: 'Support & Helpdesk (34)',
              icon: Icon(Icons.help_outline),
              badgeCount: openSupportCount > 0 ? openSupportCount : null,
              group: 'Settings',
            ),
          ];

          final outletAsync = ref.watch(outletControllerProvider);
          final outlets = outletAsync.value ?? [];

          final activeOutlet = outlets.firstWhere(
            (o) => o.id == bmbState.activeOutletId,
            orElse: () => outlets.isNotEmpty
                ? outlets.first
                : Outlet(
                    id: '',
                    name: 'Loading...',
                    code: '',
                    address: '',
                    phone: '',
                    isActive: true,
                    organizationId: '',
                  ),
          );

          return BmbResponsiveScaffold(
            currentRoute: currentKey,
            onNavigate: (key) => context.go('/$key'),
            destinations: destinations,
            activeOutletName: activeOutlet.name,
            availableOutlets: outlets.map((o) => o.name).toList(),
            onSelectOutlet: (name) {
              final found = outlets.firstWhere((o) => o.name == name);
              ref.read(bmbStateProvider.notifier).switchOutlet(found.id);
            },
            currentUserName: bmbState.currentUser.name,
            currentUserRole: bmbState.currentUserRole.name,
            onResetData: () =>
                ref.read(bmbStateProvider.notifier).resetAllData(),
            onLoadDemoData: () =>
                ref.read(bmbStateProvider.notifier).reloadDemoData(),
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/setup',
            builder: (context, state) => const SetupScreen(),
          ),
          GoRoute(
            path: '/staff',
            builder: (context, state) => const StaffScreen(),
          ),
          GoRoute(
            path: '/roles',
            builder: (context, state) => const RolesScreen(),
          ),
          GoRoute(
            path: '/menu',
            builder: (context, state) => const MenuManagementScreen(),
          ),
          GoRoute(
            path: '/tables',
            builder: (context, state) => const TableManagementScreen(),
          ),
          GoRoute(
            path: '/pos',
            builder: (context, state) {
              final tableId = state.uri.queryParameters['tableId'];
              final orderId = state.uri.queryParameters['orderId'];
              return PosBillingScreen(
                key: ValueKey('pos-${orderId ?? tableId ?? "default"}'),
                initialTableId: tableId,
                initialOrderId: orderId,
              );
            },
          ),
          GoRoute(
            path: '/kitchen',
            builder: (context, state) => const KotManagementScreen(),
          ),
          GoRoute(
            path: '/captain',
            builder: (context, state) => const CaptainOrderingScreen(),
          ),
          GoRoute(
            path: '/qr',
            builder: (context, state) => const QrOrderingScreen(),
          ),
          GoRoute(
            path: '/takeaway',
            builder: (context, state) => const TakeawayOrdersScreen(),
          ),
          GoRoute(
            path: '/delivery',
            builder: (context, state) => const DeliveryOrdersScreen(),
          ),
          GoRoute(
            path: '/online',
            builder: (context, state) => const OnlineOrdersScreen(),
          ),
          GoRoute(
            path: '/orders',
            builder: (context, state) {
              final orderId = state.uri.queryParameters['orderId'];
              return AllOrdersScreen(
                key: ValueKey('orders-${orderId ?? "default"}'),
                initialOrderId: orderId,
              );
            },
          ),
          GoRoute(
            path: '/crm',
            builder: (context, state) => const CustomerManagementScreen(),
          ),
          GoRoute(
            path: '/offers',
            builder: (context, state) => const OffersManagementScreen(),
          ),
          GoRoute(
            path: '/loyalty',
            builder: (context, state) => const LoyaltyManagementScreen(),
          ),
          GoRoute(
            path: '/stock',
            builder: (context, state) => const InventoryScreen(),
          ),
          GoRoute(
            path: '/purchase',
            builder: (context, state) => const PurchaseManagementScreen(),
          ),
          GoRoute(
            path: '/vendors',
            builder: (context, state) => const VendorManagementScreen(),
          ),
          GoRoute(
            path: '/recipes',
            builder: (context, state) => const RecipeManagementScreen(),
          ),
          GoRoute(
            path: '/wastage',
            builder: (context, state) => const WastageScreen(),
          ),
          GoRoute(
            path: '/expenses',
            builder: (context, state) => const ExpensesScreen(),
          ),
          GoRoute(
            path: '/reports',
            builder: (context, state) => const ReportsScreen(),
          ),
          GoRoute(
            path: '/payments',
            builder: (context, state) => const PaymentsScreen(),
          ),
          GoRoute(
            path: '/closing',
            builder: (context, state) => const DayClosingScreen(),
          ),
          GoRoute(
            path: '/printers',
            builder: (context, state) => const PrinterSettingsScreen(),
          ),
          GoRoute(
            path: '/taxset',
            builder: (context, state) => const TaxSettingsScreen(),
          ),
          GoRoute(
            path: '/outlets',
            builder: (context, state) => const MultiOutletScreen(),
          ),
          GoRoute(
            path: '/central',
            builder: (context, state) => const CentralKitchenScreen(),
          ),
          GoRoute(
            path: '/subs',
            builder: (context, state) => const SubscriptionScreen(),
          ),
          GoRoute(
            path: '/notif',
            builder: (context, state) => const NotificationsScreen(),
          ),
          GoRoute(
            path: '/integrations',
            builder: (context, state) => const IntegrationsScreen(),
          ),
          GoRoute(
            path: '/support',
            builder: (context, state) => const SupportHelpdeskScreen(),
          ),
        ],
      ),
    ],
  );
});
