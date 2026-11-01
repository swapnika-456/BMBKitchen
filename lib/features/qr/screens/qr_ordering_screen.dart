import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/money/paise.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/widgets/bmb_button.dart';
import '../../../core/widgets/bmb_card.dart';
import '../../../core/widgets/bmb_screen_header.dart';
import '../../../core/widgets/bmb_tag.dart';
import '../../../core/widgets/demo_banner.dart';
import '../../../mock/mock_state.dart';



class QrOrderingScreen extends ConsumerStatefulWidget {
  const QrOrderingScreen({super.key});

  @override
  ConsumerState<QrOrderingScreen> createState() => _QrOrderingScreenState();
}

class _QrOrderingScreenState extends ConsumerState<QrOrderingScreen> {
  bool _qrEnabled = true;
  String _approvalMode = 'approval'; // 'approval' or 'direct'

  // Pending QR orders awaiting staff approval
  final List<Map<String, dynamic>> _pendingOrders = [
    {
      'id': 'QR-101',
      'tableId': 'T4',
      'tableName': 'Table T4',
      'createdAt': '2 mins ago',
      'total': const Paise(71000), // ₹710
      'items': [
        {'name': 'Chicken Biryani', 'qty': 2, 'price': const Paise(28000)},
        {'name': 'Butter Naan', 'qty': 3, 'price': const Paise(5000)},
      ],
    },
    {
      'id': 'QR-102',
      'tableId': 'T2',
      'tableName': 'Table T2',
      'createdAt': '5 mins ago',
      'total': const Paise(34000), // ₹340
      'items': [
        {'name': 'Paneer Tikka', 'qty': 1, 'price': const Paise(22000)},
        {'name': 'Fresh Lime Soda', 'qty': 2, 'price': const Paise(6000)},
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bmbStateProvider);

    return Material(
      color: AppColors.paper,
      child: Column(
        children: [
          BmbScreenHeader(
            title: 'QR Scan Ordering',
            subtitle:
                'Customers scan the table QR, browse the menu and place orders themselves',
            icon: Icons.qr_code_scanner_outlined,
            iconBg: AppColors.blueSoft,
            iconColor: AppColors.blue,
            trailing: BmbButton.outline(
              label: 'Simulate a QR order',
              icon: const Icon(Icons.flash_on, size: 16),
              size: BmbButtonSize.sm,
              onPressed: () => _simulateQrOrder(state),
            ),
          ),
          const DemoBanner(),
          Expanded(
            child: LayoutBuilder(

              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final isWide = width >= 860;

                return SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.horizontalPadding(context),
                    vertical: Gap.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row: Settings and Table QR Codes (Grid g2)
                      if (isWide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildSettingsCard()),
                            AppSpacing.gapWMd,
                            Expanded(child: _buildTableQrCard(context, state)),
                          ],
                        )
                      else ...[
                        _buildSettingsCard(),
                        AppSpacing.gapHLg,
                        _buildTableQrCard(context, state),
                        const SizedBox(height: Gap.xl),
                      ],

                      // Section: Pending QR orders
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: Gap.sm,
                        children: [
                          Text(
                            'PENDING QR ORDERS',
                            style: AppText.caption.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.1,
                              color: AppColors.muted,
                            ),
                          ),
                          if (_pendingOrders.isNotEmpty)
                            BmbTag(
                              label: '${_pendingOrders.length}',
                              variant: BmbTagVariant.amber,
                            ),
                        ],
                      ),
                      AppSpacing.gapHSm,

                      if (_pendingOrders.isEmpty)
                        BmbCard(
                          padding: const EdgeInsets.symmetric(
                            vertical: 40,
                            horizontal: 20,
                          ),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.qr_code_scanner,
                                  size: 36,
                                  color: AppColors.muted,
                                ),
                                AppSpacing.gapHSm,
                                Text(
                                  'No QR orders waiting. Use "Simulate a QR order" to see the flow.',
                                  textAlign: TextAlign.center,
                                  style: AppText.body.copyWith(
                                    color: AppColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        LayoutBuilder(
                          builder: (context, innerConstraints) {
                            final innerWidth = innerConstraints.maxWidth;
                            final gridCols = innerWidth >= 960
                                ? 3
                                : (innerWidth >= 580 ? 2 : 1);

                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: gridCols,
                                    crossAxisSpacing: Gap.md,
                                    mainAxisSpacing: Gap.md,
                                    mainAxisExtent: 220,
                                  ),
                              itemCount: _pendingOrders.length,
                              itemBuilder: (context, idx) {
                                final order = _pendingOrders[idx];
                                return _buildOrderCard(order);
                              },
                            );
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
    );
  }

  // --- Settings Card ---
  Widget _buildSettingsCard() {
    return BmbCard(
      padding: const EdgeInsets.all(Gap.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Settings', style: AppText.h3.copyWith(fontSize: 16)),
          const SizedBox(height: Gap.md),
          const Divider(height: 1, color: AppColors.line),
          const SizedBox(height: Gap.md),

          // QR ordering enabled switch
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('QR ordering enabled', style: AppText.bodyStrong),
                    const SizedBox(height: 2),
                    Text(
                      'Customers can order without calling a waiter',
                      style: AppText.caption.copyWith(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _qrEnabled,
                activeThumbColor: AppColors.leaf,
                activeTrackColor: AppColors.leafSoft,
                onChanged: (val) {
                  setState(() => _qrEnabled = val);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        val ? 'QR ordering enabled' : 'QR ordering disabled',
                      ),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: Gap.lg),

          // Order approval mode
          Text(
            'Order approval mode',
            style: AppText.caption.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: Gap.xs),
          Wrap(
            spacing: Gap.sm,
            runSpacing: Gap.xs,
            children: [
              _buildModeButton('approval', 'Staff approves first'),
              _buildModeButton('direct', 'Straight to kitchen'),
            ],
          ),
          const SizedBox(height: Gap.sm),
          Text(
            'Staff approval prevents prank and mis-tapped orders. Direct mode is faster in high-trust cafés.',
            style: AppText.caption.copyWith(
              color: AppColors.muted,
              fontSize: 11.5,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton(String mode, String label) {
    final isSel = _approvalMode == mode;
    return InkWell(
      onTap: () {
        setState(() => _approvalMode = mode);
      },
      borderRadius: BorderRadius.circular(AppRadii.button),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSel ? AppColors.tandoorSoft : AppColors.card,
          borderRadius: BorderRadius.circular(AppRadii.button),
          border: Border.all(
            color: isSel ? AppColors.tandoor : AppColors.line,
            width: isSel ? 1.5 : 1.0,
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: AppText.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: isSel ? AppColors.tandoor : AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }

  // --- Table QR Codes Card ---
  Widget _buildTableQrCard(BuildContext context, BmbState state) {
    final tables = state.tables;

    return BmbCard(
      padding: const EdgeInsets.all(Gap.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Table QR codes',
                  style: AppText.h3.copyWith(fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: Gap.xs),
              Text(
                '${tables.length} tables',
                style: AppText.caption.copyWith(color: AppColors.muted),
              ),
            ],
          ),
          const SizedBox(height: Gap.md),
          const Divider(height: 1, color: AppColors.line),
          const SizedBox(height: Gap.md),

          // Grid of table QR codes
          LayoutBuilder(
            builder: (context, innerConstraints) {
              final gridWidth = innerConstraints.maxWidth;
              final crossAxisCount = gridWidth >= 420
                  ? 5
                  : (gridWidth >= 280 ? 4 : 3);

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  mainAxisExtent: 82,
                ),
                itemCount: tables.length,
                itemBuilder: (context, idx) {
                  final t = tables[idx];
                  return InkWell(
                    onTap: () => _showTentCardDialog(context, t.name),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.line),
                      ),
                      padding: const EdgeInsets.all(6),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.qr_code_2,
                            size: 36,
                            color: AppColors.ink,
                          ),
                          const SizedBox(height: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              t.name,
                              style: AppText.caption.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),

          const SizedBox(height: Gap.md),

          // Print all button
          BmbButton.outline(
            label: 'Print all QR table cards',
            expanded: true,
            icon: const Icon(Icons.print_outlined, size: 16),
            onPressed: () {
              final printerName = state.printers.isNotEmpty
                  ? state.printers.first.name
                  : 'Receipt Printer';
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Print job queued to $printerName'),
                  backgroundColor: AppColors.ink,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // --- Pending Order Card ---
  Widget _buildOrderCard(Map<String, dynamic> order) {
    final items = order['items'] as List<dynamic>;
    final total = order['total'] as Paise;

    return BmbCard(
      padding: const EdgeInsets.all(Gap.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Table & Status Tag
          Row(
            children: [
              Expanded(
                child: Text(
                  order['tableName'] as String,
                  style: AppText.bodyStrong.copyWith(fontSize: 15),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: Gap.xs),
              const BmbTag(
                label: 'Awaiting approval',
                variant: BmbTagVariant.amber,
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            order['createdAt'] as String,
            style: AppText.caption.copyWith(
              color: AppColors.muted,
              fontSize: 11,
            ),
          ),

          const SizedBox(height: Gap.sm),

          // Items list
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: items.map((it) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 3.0),
                    child: Text(
                      '${it['qty']}× ${it['name']}',
                      style: AppText.body.copyWith(fontSize: 12.5),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: AppText.caption.copyWith(color: AppColors.muted),
              ),
              Text(total.inr, style: AppText.bodyStrong),
            ],
          ),

          const SizedBox(height: Gap.xs),
          const Divider(height: 1, color: AppColors.line),
          const SizedBox(height: Gap.sm),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: BmbButton.green(
                  label: 'Approve → KOT',
                  size: BmbButtonSize.sm,
                  onPressed: () => _approveOrder(order),
                ),
              ),
              AppSpacing.gapWSm,
              BmbButton.danger(
                label: 'Reject',
                size: BmbButtonSize.sm,
                onPressed: () => _rejectOrder(order),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Handlers ---
  void _simulateQrOrder(BmbState state) {
    if (!_qrEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('QR ordering is currently disabled in Settings.'),
          backgroundColor: AppColors.chilli,
        ),
      );
      return;
    }

    final rand = Random();
    final tables = state.tables;
    final table = tables[rand.nextInt(tables.length)];

    final menuPool = state.menuItems.where((m) => m.avail).toList();
    if (menuPool.isEmpty) return;

    final item1 = menuPool[rand.nextInt(menuPool.length)];
    final item2 = menuPool[rand.nextInt(menuPool.length)];

    final totalPaise = (item1.price * 2) + item2.price;

    final simulatedOrder = {
      'id': 'QR-${rand.nextInt(900) + 100}',
      'tableId': table.id,
      'tableName': table.name,
      'createdAt': 'Just now',
      'total': totalPaise,
      'items': [
        {'name': item1.name, 'qty': 2, 'price': item1.price},
        {'name': item2.name, 'qty': 1, 'price': item2.price},
      ],
    };

    if (_approvalMode == 'direct') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('QR order on ${table.name} sent straight to kitchen!'),
          backgroundColor: AppColors.leaf,
        ),
      );
    } else {
      setState(() {
        _pendingOrders.insert(0, simulatedOrder);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'QR order received from ${table.name} — awaiting approval',
          ),
          backgroundColor: AppColors.amber,
        ),
      );
    }
  }

  void _approveOrder(Map<String, dynamic> order) {
    setState(() {
      _pendingOrders.removeWhere((o) => o['id'] == order['id']);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Approved ${order['tableName']} → KOT sent to kitchen!'),
        backgroundColor: AppColors.leaf,
      ),
    );
  }

  void _rejectOrder(Map<String, dynamic> order) {
    setState(() {
      _pendingOrders.removeWhere((o) => o['id'] == order['id']);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('QR order for ${order['tableName']} rejected'),
        backgroundColor: AppColors.chilli,
      ),
    );
  }

  void _showTentCardDialog(BuildContext context, String tableName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
        ),
        title: Text('$tableName Tent Card', style: AppText.h3),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.line),
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
              ),
              child: const Center(
                child: Icon(Icons.qr_code_2, size: 130, color: AppColors.ink),
              ),
            ),
            const SizedBox(height: Gap.md),
            Text(
              'Scan to browse menu & order',
              style: AppText.caption.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: Gap.xs),
            Text(tableName, style: AppText.bodyStrong.copyWith(fontSize: 16)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.tandoor),
            icon: const Icon(Icons.print, size: 16, color: Colors.white),
            label: const Text(
              'Print Tent Card',
              style: TextStyle(color: Colors.white),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Print job for $tableName sent to Thermal Printer',
                  ),
                  backgroundColor: AppColors.ink,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
