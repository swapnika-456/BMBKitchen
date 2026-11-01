import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_text.dart';
import '../theme/spacing.dart';

/// Module navigation destination descriptor
class BmbNavDestination {
  final String key;
  final String label;
  final Widget icon;
  final String group;
  final int? badgeCount;
  final Color? badgeColor;

  const BmbNavDestination({
    required this.key,
    required this.label,
    required this.icon,
    required this.group,
    this.badgeCount,
    this.badgeColor,
  });
}

/// Responsive scaffold delivering:
/// - Tablet & Landscape (>= 768px): Persistent left navigation rail (~80px)
///   or expandable sidebar (~240px) with Dashboard, Tables, POS, KOT, and More.
/// - Phone Portrait (< 768px): Top app bar with hamburger menu opening a full-height
///   categorized drawer, and pinned 44x44 quick-access icons for Tables, POS, and KOT.
/// - Zero bottom navigation bar anywhere in the app.
class BmbResponsiveScaffold extends StatefulWidget {
  final String currentRoute;
  final ValueChanged<String> onNavigate;
  final Widget child;
  final List<BmbNavDestination> destinations;
  final String activeOutletName;
  final List<String> availableOutlets;
  final ValueChanged<String>? onSelectOutlet;
  final String currentUserName;
  final String currentUserRole;
  final String? currentUserPhotoUrl;
  final VoidCallback? onTapUser;
  final VoidCallback? onResetData;
  final VoidCallback? onLoadDemoData;

  const BmbResponsiveScaffold({
    super.key,
    required this.currentRoute,
    required this.onNavigate,
    required this.child,
    required this.destinations,
    required this.activeOutletName,
    this.availableOutlets = const [],
    this.onSelectOutlet,
    required this.currentUserName,
    required this.currentUserRole,
    this.currentUserPhotoUrl,
    this.onTapUser,
    this.onResetData,
    this.onLoadDemoData,
  });


  @override
  State<BmbResponsiveScaffold> createState() => _BmbResponsiveScaffoldState();
}

class _BmbResponsiveScaffoldState extends State<BmbResponsiveScaffold> {
  bool? _railExpandedOverride;

  static const _groups = <String>[
    'Overview',
    'Operations',
    'Orders',
    'Customers',
    'Supply Chain',
    'Finance',
    'Settings',
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isTablet = screenWidth >= 768;

    if (isTablet) {
      final isExpanded = _railExpandedOverride ?? (screenWidth >= 1100);

      return Scaffold(
        backgroundColor: AppColors.paper,
        drawer: Drawer(
          backgroundColor: AppColors.card,
          width: 300,
          child: _buildSidebarContent(context, isDrawer: true),
        ),
        body: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isExpanded ? 240 : 80,
              child: isExpanded
                  ? _buildSidebarContent(context, isDrawer: false)
                  : _buildCompactRail(context),
            ),
            const VerticalDivider(color: AppColors.line, width: 1),
            Expanded(child: SafeArea(child: widget.child)),
          ],
        ),
      );
    }

    // Phone Portrait (< 768px)
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: _buildPhoneAppBar(context),
      drawer: Drawer(
        backgroundColor: AppColors.card,
        width: MediaQuery.of(context).size.width * 0.85 > 320
            ? 320
            : MediaQuery.of(context).size.width * 0.85,
        child: _buildSidebarContent(context, isDrawer: true),
      ),
      body: SafeArea(child: widget.child),
      // Rule 2: Bottom navigation bar removed completely
      bottomNavigationBar: null,
    );
  }

  /// Phone App Bar with hamburger menu, brand logo, and 44x44 pinned quick icons
  PreferredSizeWidget _buildPhoneAppBar(BuildContext context) {
    final activeTables = widget.destinations
        .where((d) => d.key == 'tables')
        .map((d) => d.badgeCount ?? 0)
        .fold(0, (a, b) => a + b);

    final activeKots = widget.destinations
        .where((d) => d.key == 'kitchen')
        .map((d) => d.badgeCount ?? 0)
        .fold(0, (a, b) => a + b);

    return AppBar(
      backgroundColor: AppColors.card,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      titleSpacing: 0,
      leading: Builder(
        builder: (scaffoldContext) => IconButton(
          icon: const Icon(Icons.menu, color: AppColors.ink, size: 24),
          tooltip: 'Open navigation menu',
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          onPressed: () => Scaffold.of(scaffoldContext).openDrawer(),
        ),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.tandoor,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              'BK',
              style: AppText.h3.copyWith(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          AppSpacing.gapW8,
          Flexible(
            child: RichText(
              maxLines: 1,
              overflow: TextOverflow.visible,
              text: TextSpan(
                text: 'BMB ',
                style: AppText.h2.copyWith(fontSize: 16, color: AppColors.ink),
                children: [
                  TextSpan(
                    text: 'Kitchen',
                    style: AppText.h2.copyWith(
                      fontSize: 16,
                      color: AppColors.tandoor,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      actions: [
        // Quick Action 1: Tables (44x44 touch target)
        _buildQuickIcon(
          icon: Icons.table_restaurant_outlined,
          tooltip: 'Tables',
          route: 'tables',
          badgeCount: activeTables,
        ),
        // Quick Action 2: POS (44x44 touch target)
        _buildQuickIcon(
          icon: Icons.receipt_long_outlined,
          tooltip: 'POS Billing',
          route: 'pos',
        ),
        // Quick Action 3: Kitchen KOT (44x44 touch target)
        _buildQuickIcon(
          icon: Icons.soup_kitchen_outlined,
          tooltip: 'Kitchen KOT',
          route: 'kitchen',
          badgeCount: activeKots,
        ),
        const SizedBox(width: 4),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, thickness: 1, color: AppColors.line),
      ),
    );
  }

  Widget _buildQuickIcon({
    required IconData icon,
    required String tooltip,
    required String route,
    int badgeCount = 0,
  }) {
    final isSelected = widget.currentRoute == route;

    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          IconButton(
            icon: Icon(
              icon,
              size: 22,
              color: isSelected ? AppColors.tandoor : AppColors.ink,
            ),
            tooltip: tooltip,
            onPressed: () => widget.onNavigate(route),
          ),
          if (badgeCount > 0)
            Positioned(
              right: 4,
              top: 4,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: AppColors.tandoor,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                alignment: Alignment.center,
                child: Text(
                  badgeCount > 9 ? '9+' : '$badgeCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Compact Navigation Rail for Tablet (~80px wide)
  Widget _buildCompactRail(BuildContext context) {
    final activeTables = widget.destinations
        .where((d) => d.key == 'tables')
        .map((d) => d.badgeCount ?? 0)
        .fold(0, (a, b) => a + b);

    final activeKots = widget.destinations
        .where((d) => d.key == 'kitchen')
        .map((d) => d.badgeCount ?? 0)
        .fold(0, (a, b) => a + b);

    return Container(
      color: AppColors.card,
      child: Column(
        children: [
          // Logo & Expand toggle
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: InkWell(
              onTap: () {
                setState(() {
                  _railExpandedOverride = true;
                });
              },
              borderRadius: BorderRadius.circular(10),
              child: Tooltip(
                message: 'Expand sidebar',
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.tandoor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'BK',
                    style: AppText.h2.copyWith(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.line),
          const SizedBox(height: 8),

          // Primary Destinations
          _buildRailItem('dashboard', 'Dashboard', Icons.dashboard_outlined),
          _buildRailItem(
            'tables',
            'Tables',
            Icons.table_restaurant_outlined,
            badgeCount: activeTables,
          ),
          _buildRailItem('pos', 'POS', Icons.receipt_long_outlined),
          _buildRailItem(
            'kitchen',
            'KOT',
            Icons.soup_kitchen_outlined,
            badgeCount: activeKots,
          ),

          // "More" Destination opening the drawer
          Builder(
            builder: (scaffoldContext) => _buildRailButton(
              label: 'More',
              icon: Icons.grid_view_outlined,
              tooltip: 'All 34 Modules',
              onTap: () {
                Scaffold.of(scaffoldContext).openDrawer();
              },
            ),
          ),

          const Spacer(),

          // Bottom Avatar / Outlet
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Tooltip(
              message: '${widget.currentUserName} · ${widget.activeOutletName}',
              child: InkWell(
                onTap: widget.onTapUser ?? () => widget.onNavigate('profile'),
                borderRadius: BorderRadius.circular(20),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.tandoorSoft,
                  backgroundImage: (widget.currentUserPhotoUrl != null &&
                          widget.currentUserPhotoUrl!.isNotEmpty)
                      ? NetworkImage(widget.currentUserPhotoUrl!)
                      : null,
                  child: (widget.currentUserPhotoUrl == null ||
                          widget.currentUserPhotoUrl!.isEmpty)
                      ? Text(
                          widget.currentUserName.isNotEmpty
                              ? widget.currentUserName[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            color: AppColors.tandoor,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        )
                      : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );

  }

  Widget _buildRailItem(
    String key,
    String label,
    IconData icon, {
    int badgeCount = 0,
  }) {
    final isSelected = widget.currentRoute == key;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Tooltip(
        message: label,
        child: InkWell(
          onTap: () => widget.onNavigate(key),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 64,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.tandoorSoft : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      icon,
                      size: 22,
                      color: isSelected ? AppColors.tandoor : AppColors.ink,
                    ),
                    if (badgeCount > 0)
                      Positioned(
                        right: -6,
                        top: -4,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: AppColors.tandoor,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 14,
                            minHeight: 14,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            badgeCount > 9 ? '9+' : '$badgeCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: AppText.caption.copyWith(
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? AppColors.tandoor : AppColors.muted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.visible,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRailButton({
    required String label,
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 64,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 22, color: AppColors.ink),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: AppText.caption.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.visible,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Full-featured sidebar & drawer content with all 7 groups, outlet switcher,
  /// and untruncated user information at the bottom.
  Widget _buildSidebarContent(BuildContext context, {required bool isDrawer}) {
    return Container(
      color: AppColors.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Brand Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 12, 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.tandoor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'BK',
                    style: AppText.h2.copyWith(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                AppSpacing.gapW12,
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      text: 'BMB ',
                      style: AppText.h2.copyWith(
                        fontSize: 18,
                        color: AppColors.ink,
                      ),
                      children: [
                        TextSpan(
                          text: 'Kitchen',
                          style: AppText.h2.copyWith(
                            fontSize: 18,
                            color: AppColors.tandoor,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (!isDrawer)
                  IconButton(
                    icon: const Icon(
                      Icons.chevron_left,
                      size: 20,
                      color: AppColors.muted,
                    ),
                    tooltip: 'Collapse sidebar',
                    onPressed: () {
                      setState(() {
                        _railExpandedOverride = false;
                      });
                    },
                  )
                else
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      size: 20,
                      color: AppColors.muted,
                    ),
                    tooltip: 'Close drawer',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.line),

          // Scrollable Navigation List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              children: [
                for (final group in _groups) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 14, 10, 6),
                    child: Text(
                      group.toUpperCase(),
                      style: AppText.sectionLabel.copyWith(
                        fontSize: 10,
                        color: const Color(0xFFA99F91),
                        letterSpacing: 1.0,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  for (final item in widget.destinations.where(
                    (d) => d.group == group,
                  ))
                    _buildNavListItem(item, isDrawer),
                ],
              ],
            ),
          ),

          // Bottom pinned user & outlet section
          const Divider(height: 1, color: AppColors.line),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Outlet box (never truncated!)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.inputFill,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CURRENT OUTLET',
                        style: AppText.caption.copyWith(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.muted,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            Icons.storefront,
                            size: 14,
                            color: AppColors.tandoor,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              widget.activeOutletName,
                              style: AppText.bodyBold.copyWith(fontSize: 12),
                              maxLines: 2,
                              overflow: TextOverflow.visible,
                            ),
                          ),
                          if (widget.availableOutlets.length > 1 &&
                              widget.onSelectOutlet != null)
                            PopupMenuButton<String>(
                              icon: const Icon(
                                Icons.arrow_drop_down,
                                size: 18,
                                color: AppColors.muted,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              tooltip: 'Switch outlet',
                              onSelected: widget.onSelectOutlet,
                              itemBuilder: (context) =>
                                  widget.availableOutlets.map((outlet) {
                                    return PopupMenuItem(
                                      value: outlet,
                                      child: Text(outlet, style: AppText.body),
                                    );
                                  }).toList(),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // User box (Rule 1 & 3: Never truncated!)
                InkWell(
                  onTap: () {
                    // Close drawer first if open
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    }
                    if (widget.onTapUser != null) {
                      widget.onTapUser!();
                    } else {
                      widget.onNavigate('profile');
                    }
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.tandoorSoft,
                          backgroundImage: (widget.currentUserPhotoUrl != null &&
                                  widget.currentUserPhotoUrl!.isNotEmpty)
                              ? NetworkImage(widget.currentUserPhotoUrl!)
                              : null,
                          child: (widget.currentUserPhotoUrl == null ||
                                  widget.currentUserPhotoUrl!.isEmpty)
                              ? Text(
                                  widget.currentUserName.isNotEmpty
                                      ? widget.currentUserName[0].toUpperCase()
                                      : 'U',
                                  style: const TextStyle(
                                    color: AppColors.tandoor,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.currentUserName,
                                style: AppText.bodyBold.copyWith(fontSize: 12.5),
                                maxLines: 2,
                                overflow: TextOverflow.visible,
                              ),
                              Text(
                                widget.currentUserRole,
                                style: AppText.caption.copyWith(
                                  fontSize: 11,
                                  color: AppColors.muted,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.visible,
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          size: 16,
                          color: AppColors.muted,
                        ),
                      ],
                    ),
                  ),
                ),

              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavListItem(BmbNavDestination item, bool isDrawer) {
    final isSelected = widget.currentRoute == item.key;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Material(
        color: isSelected ? AppColors.tandoor : Colors.transparent,
        borderRadius: BorderRadius.circular(9),
        child: InkWell(
          onTap: () {
            if (isDrawer) {
              Navigator.of(context).pop();
            }
            widget.onNavigate(item.key);
          },
          borderRadius: BorderRadius.circular(9),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8.5),
            child: Row(
              children: [
                IconTheme(
                  data: IconThemeData(
                    color: isSelected ? Colors.white : const Color(0xFF3E382F),
                    size: 18,
                  ),
                  child: item.icon,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.label,
                    style: AppText.button.copyWith(
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF3E382F),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.visible,
                  ),
                ),
                if (item.badgeCount != null && item.badgeCount! > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1.5,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.25)
                          : (item.badgeColor ?? AppColors.badgeGrey),
                      borderRadius: AppRadii.pillRadius,
                    ),
                    child: Text(
                      '${item.badgeCount}',
                      style: AppText.caption.copyWith(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : AppColors.muted,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
