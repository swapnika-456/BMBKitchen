import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/money/paise.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/widgets/bmb_button.dart';
import '../../../core/widgets/bmb_card.dart';
import '../../../core/widgets/bmb_kpi_tile.dart';
import '../../../core/widgets/bmb_screen_header.dart';
import '../../../core/widgets/bmb_tag.dart';
import '../../../core/widgets/demo_banner.dart';
import '../../../mock/mock_state.dart';

import '../../../models/models.dart';

/// Module 17 — Loyalty Management
/// Strict alignment with VIEWS.loyalty in the HTML reference:
/// - Screen header: "Loyalty Management", subtitle on earning & bill redemption
/// - 4 responsive KPI tiles with fixed 135px height (immune to aspect-ratio overflow)
/// - 2-column responsive layout:
///   1. Programme rules form with responsive form stacking on mobile and live simulation box
///   2. Tiers breakdown (Silver, Gold, Platinum) and Top Point Holders leaderboard with flexible truncation
class LoyaltyManagementScreen extends ConsumerStatefulWidget {
  const LoyaltyManagementScreen({super.key});

  @override
  ConsumerState<LoyaltyManagementScreen> createState() =>
      _LoyaltyManagementScreenState();
}

class _LoyaltyManagementScreenState
    extends ConsumerState<LoyaltyManagementScreen> {
  late TextEditingController _earnPerCtrl;
  late TextEditingController _pointsCtrl;
  late TextEditingController _redeemValueCtrl;
  late TextEditingController _minRedeemCtrl;
  late TextEditingController _expiryDaysCtrl;
  bool _initialized = false;

  void _initControllers(LoyaltySettings l) {
    if (_initialized) return;
    _earnPerCtrl = TextEditingController(
      text: l.earnPer.toRupees.round().toString(),
    );
    _pointsCtrl = TextEditingController(text: l.points.toString());
    _redeemValueCtrl = TextEditingController(
      text: l.redeemValue.toRupees.toString(),
    );
    _minRedeemCtrl = TextEditingController(text: l.minRedeem.toString());
    _expiryDaysCtrl = TextEditingController(text: l.expiryDays.toString());
    _initialized = true;
  }

  @override
  void dispose() {
    if (_initialized) {
      _earnPerCtrl.dispose();
      _pointsCtrl.dispose();
      _redeemValueCtrl.dispose();
      _minRedeemCtrl.dispose();
      _expiryDaysCtrl.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bmbStateProvider);
    final loyalty = state.loyalty;
    _initControllers(loyalty);

    final customers = state.customers;
    final membersWithPoints = customers.where((c) => c.points > 0).toList();
    final totPts = customers.fold<int>(0, (sum, c) => sum + c.points);
    final liabilityPaise = loyalty.redeemValue * totPts;

    final sortedMembers = [...customers]
      ..sort((a, b) => b.points.compareTo(a.points));

    // Simulation calculation for ₹1,000 bill
    final earnBlockRupees =
        double.tryParse(_earnPerCtrl.text) ?? loyalty.earnPer.toRupees;
    final ptsPerBlock = int.tryParse(_pointsCtrl.text) ?? loyalty.points;
    final redeemValRupees =
        double.tryParse(_redeemValueCtrl.text) ?? loyalty.redeemValue.toRupees;

    final simBlocks = earnBlockRupees > 0 ? (1000 ~/ earnBlockRupees) : 0;
    final simPoints = simBlocks * ptsPerBlock;
    final simValuePaise = Paise.fromRupees(simPoints * redeemValRupees);

    return Material(
      color: AppColors.paper,
      child: Column(
        children: [
          BmbScreenHeader(
            title: 'Loyalty Program',
            subtitle:
                'Points earn automatically at billing and redeem against the bill total',
            icon: Icons.star_border,
            iconBg: AppColors.amberSoft,
            iconColor: const Color(0xFF96650B),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: loyalty.active
                    ? AppColors.leafSoft
                    : AppColors.badgeGrey,
                borderRadius: BorderRadius.circular(AppRadii.pill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: loyalty.active ? AppColors.leaf : AppColors.muted,
                      shape: BoxShape.circle,
                    ),
                  ),
                  AppSpacing.gapWSm,
                  Text(
                    loyalty.active ? 'Loyalty Active' : 'Loyalty Paused',
                    style: AppText.caption.copyWith(
                      color: loyalty.active ? AppColors.leaf : AppColors.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const DemoBanner(),
          Expanded(
            child: SingleChildScrollView(

              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.horizontalPadding(context),
                vertical: Gap.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 4 Responsive KPI Tiles with guaranteed 135px height
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      final crossAxisCount = width >= 900 ? 4 : 2;

                      final tiles = [
                        BmbKpiTile(
                          label: 'Programme',
                          value: loyalty.active ? 'Active' : 'Paused',
                          hint:
                              '${loyalty.earnPer.inr} spend = ${loyalty.points} pts',
                          icon: const Icon(
                            Icons.star,
                            color: Color(0xFF96650B),
                            size: 20,
                          ),
                          iconBg: AppColors.amberSoft,
                          iconFg: const Color(0xFF96650B),
                        ),
                        BmbKpiTile(
                          label: 'Active Members',
                          value: '${membersWithPoints.length}',
                          hint: 'customers with points',
                          icon: const Icon(
                            Icons.people_outline,
                            color: AppColors.tandoor,
                            size: 20,
                          ),
                          iconBg: AppColors.tandoorSoft,
                          iconFg: AppColors.tandoor,
                        ),
                        BmbKpiTile(
                          label: 'Points Outstanding',
                          value: totPts.toString(),
                          hint: 'liability ${liabilityPaise.inr}',
                          icon: const Icon(
                            Icons.currency_rupee,
                            color: AppColors.chilli,
                            size: 20,
                          ),
                          iconBg: AppColors.chilliSoft,
                          iconFg: AppColors.chilli,
                        ),
                        BmbKpiTile(
                          label: 'Redemption Value',
                          value: loyalty.redeemValue.inr,
                          hint: 'value per point',
                          icon: const Icon(
                            Icons.credit_card,
                            color: AppColors.leaf,
                            size: 20,
                          ),
                          iconBg: AppColors.leafSoft,
                          iconFg: AppColors.leaf,
                        ),
                      ];

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: Gap.sm,
                          mainAxisSpacing: Gap.sm,
                          mainAxisExtent: 144,
                        ),
                        itemCount: tiles.length,
                        itemBuilder: (context, index) => tiles[index],
                      );
                    },
                  ),
                  AppSpacing.gapHLg,

                  // 2-Column Responsive Layout
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 860;
                      if (isWide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildRulesCard(
                                context,
                                loyalty,
                                simPoints,
                                simValuePaise,
                              ),
                            ),
                            AppSpacing.gapWMd,
                            Expanded(
                              child: _buildTiersAndLeaderboardCard(
                                context,
                                loyalty,
                                customers,
                                sortedMembers,
                              ),
                            ),
                          ],
                        );
                      } else {
                        return Column(
                          children: [
                            _buildRulesCard(
                              context,
                              loyalty,
                              simPoints,
                              simValuePaise,
                            ),
                            AppSpacing.gapHMd,
                            _buildTiersAndLeaderboardCard(
                              context,
                              loyalty,
                              customers,
                              sortedMembers,
                            ),
                          ],
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRulesCard(
    BuildContext context,
    LoyaltySettings loyalty,
    int simPoints,
    Paise simValuePaise,
  ) {
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
                  'Programme Rules',
                  style: AppText.h3,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: Gap.sm),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    loyalty.active ? 'Enabled' : 'Disabled',
                    style: AppText.caption.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Switch(
                    value: loyalty.active,
                    activeThumbColor: AppColors.leaf,
                    onChanged: (val) {
                      ref
                          .read(bmbStateProvider.notifier)
                          .updateLoyalty(loyalty.copyWith(active: val));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            val
                                ? 'Loyalty programme enabled'
                                : 'Loyalty programme paused',
                          ),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          Text(
            'Points earn on every settled bill and can be redeemed at checkout.',
            style: AppText.caption.copyWith(color: AppColors.muted),
          ),
          const Divider(height: 24, color: AppColors.line),

          LayoutBuilder(
            builder: (context, c) {
              final isSmall = c.maxWidth < 420;
              if (isSmall) {
                return Column(
                  children: [
                    TextField(
                      controller: _earnPerCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Spend per earn block (₹)',
                        hintText: '100',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    AppSpacing.gapHMd,
                    TextField(
                      controller: _pointsCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Points per block',
                        hintText: '5',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _earnPerCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Spend per earn block (₹)',
                        hintText: '100',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  AppSpacing.gapWMd,
                  Expanded(
                    child: TextField(
                      controller: _pointsCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Points per block',
                        hintText: '5',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              );
            },
          ),
          AppSpacing.gapHMd,

          LayoutBuilder(
            builder: (context, c) {
              final isSmall = c.maxWidth < 420;
              if (isSmall) {
                return Column(
                  children: [
                    TextField(
                      controller: _redeemValueCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: '1 point = ₹',
                        hintText: '1.0',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    AppSpacing.gapHMd,
                    TextField(
                      controller: _minRedeemCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Min points to redeem',
                        hintText: '100',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _redeemValueCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: '1 point = ₹',
                        hintText: '1.0',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  AppSpacing.gapWMd,
                  Expanded(
                    child: TextField(
                      controller: _minRedeemCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Min points to redeem',
                        hintText: '100',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          AppSpacing.gapHMd,

          TextField(
            controller: _expiryDaysCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Points expire after (days)',
              hintText: '365',
              border: OutlineInputBorder(),
            ),
          ),
          AppSpacing.gapHLg,

          BmbButton.primary(
            label: 'Save Rules',
            expanded: true,
            onPressed: () {
              final earnB = double.tryParse(_earnPerCtrl.text) ?? 100;
              final pts = int.tryParse(_pointsCtrl.text) ?? 5;
              final redV = double.tryParse(_redeemValueCtrl.text) ?? 1;
              final minR = int.tryParse(_minRedeemCtrl.text) ?? 100;
              final expD = int.tryParse(_expiryDaysCtrl.text) ?? 365;

              final updated = loyalty.copyWith(
                earnPer: Paise.fromRupees(earnB > 0 ? earnB : 100),
                points: pts > 0 ? pts : 5,
                redeemValue: Paise.fromRupees(redV > 0 ? redV : 1),
                minRedeem: minR,
                expiryDays: expD,
              );

              ref.read(bmbStateProvider.notifier).updateLoyalty(updated);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Loyalty rules saved successfully!'),
                  backgroundColor: AppColors.leaf,
                ),
              );
            },
          ),
          AppSpacing.gapHMd,

          // Live Simulation Note
          Container(
            padding: const EdgeInsets.all(Gap.md),
            decoration: BoxDecoration(
              color: AppColors.amberSoft,
              borderRadius: BorderRadius.circular(AppRadii.card),
              border: Border.all(color: const Color(0xFFE8A013)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.lightbulb_outline,
                  size: 18,
                  color: Color(0xFF96650B),
                ),
                AppSpacing.gapWSm,
                Expanded(
                  child: Text(
                    'Live Simulation: A ₹1,000 bill earns $simPoints points, worth ${simValuePaise.inr} discount on the customer\'s next visit.',
                    style: AppText.caption.copyWith(
                      color: const Color(0xFF96650B),
                      fontWeight: FontWeight.w600,
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

  Widget _buildTiersAndLeaderboardCard(
    BuildContext context,
    LoyaltySettings loyalty,
    List<Customer> customers,
    List<Customer> sortedMembers,
  ) {
    return BmbCard(
      padding: const EdgeInsets.all(Gap.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Customer Tiers', style: AppText.h3),
          const Divider(height: 20, color: AppColors.line),

          ...loyalty.tiers.map((t) {
            final count = customers
                .where((c) => loyalty.getTierForSpend(c.spend) == t.name)
                .length;
            BmbTagVariant tagVar;
            if (t.name == 'Platinum') {
              tagVar = BmbTagVariant.plum;
            } else if (t.name == 'Gold') {
              tagVar = BmbTagVariant.amber;
            } else {
              tagVar = BmbTagVariant.grey;
            }

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: Gap.xs,
                          runSpacing: Gap.xs,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(t.name, style: AppText.bodyStrong),
                            BmbTag(
                              label: tagVar == BmbTagVariant.plum
                                  ? 'VIP'
                                  : (tagVar == BmbTagVariant.amber
                                        ? 'Gold'
                                        : 'Base'),
                              variant: tagVar,
                            ),
                          ],
                        ),
                        Text(
                          'Lifetime spend ≥ ${t.minSpend.inr}',
                          style: AppText.caption.copyWith(
                            color: AppColors.muted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.gapWSm,
                  BmbTag(
                    label: '$count member${count == 1 ? "" : "s"}',
                    variant: BmbTagVariant.grey,
                  ),
                ],
              ),
            );
          }),

          const Divider(height: 28, color: AppColors.line),
          Text('Top Point Holders Leaderboard', style: AppText.h3),
          AppSpacing.gapHSm,

          if (sortedMembers.isEmpty)
            Padding(
              padding: const EdgeInsets.all(Gap.md),
              child: Center(
                child: Text('No loyalty members yet', style: AppText.caption),
              ),
            )
          else
            ...sortedMembers.take(6).map((c) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: AppColors.tandoorSoft,
                            child: Text(
                              c.name.isNotEmpty ? c.name[0] : '?',
                              style: AppText.caption.copyWith(
                                color: AppColors.tandoor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          AppSpacing.gapWSm,
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c.name,
                                  style: AppText.bodyStrong,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  c.phone,
                                  style: AppText.caption.copyWith(
                                    color: AppColors.muted,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    AppSpacing.gapWSm,
                    Text(
                      '${c.points} pts',
                      style: AppText.numeric.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.tandoor,
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
}
