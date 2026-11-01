import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/money/paise.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/widgets/bmb_button.dart';
import '../../../core/widgets/bmb_card.dart';
import '../../../core/widgets/bmb_empty_state.dart';
import '../../../core/widgets/bmb_kpi_tile.dart';
import '../../../core/widgets/bmb_screen_header.dart';
import '../../../core/widgets/bmb_tag.dart';
import '../../../mock/mock_state.dart';
import '../../../models/models.dart';

/// Module 16 — Offers & Discounts
/// Strict alignment with VIEWS.offers in the HTML reference:
/// - Screen header: live offer count & "Create Offer" action
/// - 3 responsive KPI tiles with fixed 135px height (immune to aspect-ratio overflow)
/// - Grid of offer cards displaying Code, Name, Value, Minimum Bill, Max Cap, Channel applicability, Dates, Usage
/// - Quick Live / Paused toggle on each offer card
/// - Create / Edit / Delete Offer bottom sheet with full validation
class OffersManagementScreen extends ConsumerStatefulWidget {
  const OffersManagementScreen({super.key});

  @override
  ConsumerState<OffersManagementScreen> createState() =>
      _OffersManagementScreenState();
}

class _OffersManagementScreenState
    extends ConsumerState<OffersManagementScreen> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bmbStateProvider);
    final offers = state.offers;
    final activeCount = offers.where((o) => o.active).length;
    final totalUsed = offers.fold<int>(0, (sum, o) => sum + o.used);

    return Material(
      color: AppColors.paper,
      child: Column(
        children: [
          BmbScreenHeader(
            title: 'Offers & Discounts',
            subtitle: '$activeCount live offers · codes apply at billing',
            icon: Icons.discount_outlined,
            iconBg: AppColors.tandoorSoft,
            iconColor: AppColors.tandoor,
            trailing: BmbButton.primary(
              label: 'Create Offer',
              size: BmbButtonSize.sm,
              icon: const Icon(Icons.add, size: 16),
              onPressed: () => _openOfferSheet(context, null),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.horizontalPadding(context),
                vertical: Gap.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // KPI Summary Tiles (2*1 grid on mobile/tablet)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      final crossAxisCount = width >= 900 ? 3 : 2;

                      final tiles = [
                        BmbKpiTile(
                          label: 'Active Offers',
                          value: '$activeCount',
                          hint: 'applicable at POS billing',
                          icon: const Icon(
                            Icons.local_offer_outlined,
                            color: AppColors.leaf,
                            size: 20,
                          ),
                          iconBg: AppColors.leafSoft,
                          iconFg: AppColors.leaf,
                        ),
                        BmbKpiTile(
                          label: 'Times Redeemed',
                          value: '$totalUsed',
                          hint: 'across all outlets',
                          icon: const Icon(
                            Icons.confirmation_num_outlined,
                            color: AppColors.blue,
                            size: 20,
                          ),
                          iconBg: AppColors.blueSoft,
                          iconFg: AppColors.blue,
                        ),
                        BmbKpiTile(
                          label: 'Total Offer Codes',
                          value: '${offers.length}',
                          hint: 'configured promotional campaigns',
                          icon: const Icon(
                            Icons.percent,
                            color: AppColors.tandoor,
                            size: 20,
                          ),
                          iconBg: AppColors.tandoorSoft,
                          iconFg: AppColors.tandoor,
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

                  // Offers Grid
                  if (offers.isEmpty)
                    const BmbEmptyState(
                      title: 'No promotional offers yet',
                      description:
                          'Create an offer code like WELCOME10 or FLAT100 for your customers.',
                    )
                  else
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        final crossAxisCount = width >= 960
                            ? 3
                            : (width >= 620 ? 2 : 1);

                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: Gap.md,
                                mainAxisSpacing: Gap.md,
                                mainAxisExtent: 325,
                              ),
                          itemCount: offers.length,
                          itemBuilder: (context, index) {
                            final offer = offers[index];
                            return _buildOfferCard(context, offer);
                          },
                        );
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

  Widget _buildOfferCard(BuildContext context, Offer offer) {
    final valueDisplay = offer.type == 'pct'
        ? '${offer.value.round()}% off'
        : '${Paise.fromRupees(offer.value).inr} off';

    String appliesLabel;
    switch (offer.applies) {
      case 'dinein':
        appliesLabel = 'Dine-in only';
        break;
      case 'takeaway':
        appliesLabel = 'Takeaway only';
        break;
      case 'delivery':
        appliesLabel = 'Delivery only';
        break;
      case 'online':
        appliesLabel = 'Online orders only';
        break;
      default:
        appliesLabel = 'All order types';
    }

    return BmbCard(
      padding: const EdgeInsets.all(Gap.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Code, Name, and Status Toggle Tag
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      offer.code,
                      style: AppText.h3.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    AppSpacing.gapHXs,
                    Text(
                      offer.name,
                      style: AppText.caption.copyWith(color: AppColors.muted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              AppSpacing.gapWSm,
              InkWell(
                borderRadius: AppRadii.pillRadius,
                onTap: () {
                  ref.read(bmbStateProvider.notifier).toggleOffer(offer.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${offer.code} ${offer.active ? "paused" : "activated"}',
                      ),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                child: BmbTag(
                  label: offer.active ? 'Live' : 'Paused',
                  variant: offer.active
                      ? BmbTagVariant.green
                      : BmbTagVariant.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Big discount highlight
          Text(
            valueDisplay,
            style: AppText.h2.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.tandoor,
            ),
          ),
          AppSpacing.gapHXs,

          // Min bill & cap
          Text(
            'Min bill ${offer.minBill.inr}${offer.maxDisc > const Paise(0) ? " · max ${offer.maxDisc.inr}" : ""}',
            style: AppText.caption.copyWith(
              fontSize: 11.5,
              color: AppColors.muted,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const Divider(height: 18, color: AppColors.line),

          // Metadata Rows
          _buildInfoRow('Applies to', appliesLabel),
          AppSpacing.gapHXs,
          _buildInfoRow('Valid', '${offer.from} → ${offer.to}'),
          AppSpacing.gapHXs,
          _buildInfoRow('Times used', '${offer.used}'),

          const Spacer(),
          BmbButton.outline(
            label: 'Edit Offer',
            size: BmbButtonSize.sm,
            expanded: true,
            onPressed: () => _openOfferSheet(context, offer),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppText.caption.copyWith(color: AppColors.muted)),
        const SizedBox(width: Gap.sm),
        Flexible(
          child: Text(
            value,
            style: AppText.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  void _openOfferSheet(BuildContext context, Offer? offer) {
    final isEdit = offer != null;
    final codeCtrl = TextEditingController(text: offer?.code ?? '');
    final nameCtrl = TextEditingController(text: offer?.name ?? '');
    String discType = offer?.type ?? 'pct';
    final valueCtrl = TextEditingController(
      text: offer != null ? offer.value.toString() : '10',
    );
    final minBillCtrl = TextEditingController(
      text: offer != null ? offer.minBill.toRupees.toString() : '0',
    );
    final maxDiscCtrl = TextEditingController(
      text: offer != null ? offer.maxDisc.toRupees.toString() : '0',
    );
    String applies = offer?.applies ?? 'all';
    final fromCtrl = TextEditingController(
      text: offer?.from ?? DateTime.now().toIso8601String().split('T').first,
    );
    final toCtrl = TextEditingController(
      text:
          offer?.to ??
          DateTime.now()
              .add(const Duration(days: 90))
              .toIso8601String()
              .split('T')
              .first,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadii.sheet),
        ),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                top: Gap.lg,
                left: Gap.lg,
                right: Gap.lg,
                bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + Gap.xl,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isEdit ? 'Edit Offer' : 'Create Offer',
                          style: AppText.h3,
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(sheetCtx).pop(),
                        ),
                      ],
                    ),
                    const Divider(height: 20, color: AppColors.line),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: codeCtrl,
                            textCapitalization: TextCapitalization.characters,
                            decoration: const InputDecoration(
                              labelText: 'Offer Code *',
                              hintText: 'WELCOME10',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        AppSpacing.gapWMd,
                        Expanded(
                          child: TextField(
                            controller: nameCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Display Name *',
                              hintText: 'Welcome 10%',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    AppSpacing.gapHMd,
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: discType,
                            decoration: const InputDecoration(
                              labelText: 'Discount Type',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'pct',
                                child: Text('Percentage (%)'),
                              ),
                              DropdownMenuItem(
                                value: 'amt',
                                child: Text('Flat Amount (₹)'),
                              ),
                            ],
                            onChanged: (val) {
                              if (val != null)
                                setSheetState(() => discType = val);
                            },
                          ),
                        ),
                        AppSpacing.gapWMd,
                        Expanded(
                          child: TextField(
                            controller: valueCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: discType == 'pct'
                                  ? 'Discount % *'
                                  : 'Discount ₹ *',
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    AppSpacing.gapHMd,
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: minBillCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Minimum Bill (₹)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        AppSpacing.gapWMd,
                        Expanded(
                          child: TextField(
                            controller: maxDiscCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Max Discount Cap (₹)',
                              hintText: '0 for unlimited',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    AppSpacing.gapHMd,
                    DropdownButtonFormField<String>(
                      initialValue: applies,
                      decoration: const InputDecoration(
                        labelText: 'Applies To',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'all',
                          child: Text('All Order Types'),
                        ),
                        DropdownMenuItem(
                          value: 'dinein',
                          child: Text('Dine-in only'),
                        ),
                        DropdownMenuItem(
                          value: 'takeaway',
                          child: Text('Takeaway only'),
                        ),
                        DropdownMenuItem(
                          value: 'delivery',
                          child: Text('Delivery only'),
                        ),
                        DropdownMenuItem(
                          value: 'online',
                          child: Text('Online orders only'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) setSheetState(() => applies = val);
                      },
                    ),
                    AppSpacing.gapHMd,
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: fromCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Valid From (YYYY-MM-DD)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        AppSpacing.gapWMd,
                        Expanded(
                          child: TextField(
                            controller: toCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Valid To (YYYY-MM-DD)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    AppSpacing.gapHLg,
                    Wrap(
                      spacing: Gap.sm,
                      runSpacing: Gap.sm,
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (isEdit)
                          BmbButton.danger(
                            label: 'Delete',
                            size: BmbButtonSize.md,
                            onPressed: () {
                              ref
                                  .read(bmbStateProvider.notifier)
                                  .deleteOffer(offer.id);
                              Navigator.of(sheetCtx).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Offer deleted')),
                              );
                            },
                          )
                        else
                          const SizedBox.shrink(),
                        Wrap(
                          spacing: Gap.sm,
                          runSpacing: Gap.xs,
                          children: [
                            BmbButton.outline(
                              label: 'Cancel',
                              size: BmbButtonSize.md,
                              onPressed: () => Navigator.of(sheetCtx).pop(),
                            ),
                            BmbButton.primary(
                              label: 'Save Offer',
                              size: BmbButtonSize.md,
                              onPressed: () {
                                final code = codeCtrl.text.trim().toUpperCase();
                                final name = nameCtrl.text.trim();
                                if (code.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Offer code is required'),
                                    ),
                                  );
                                  return;
                                }

                                final val =
                                    double.tryParse(valueCtrl.text) ?? 0;
                                final minB =
                                    double.tryParse(minBillCtrl.text) ?? 0;
                                final maxD =
                                    double.tryParse(maxDiscCtrl.text) ?? 0;

                                final updated = Offer(
                                  id:
                                      offer?.id ??
                                      'of_${DateTime.now().millisecondsSinceEpoch}',
                                  code: code,
                                  name: name.isNotEmpty ? name : code,
                                  type: discType,
                                  value: val,
                                  minBill: Paise.fromRupees(minB),
                                  maxDisc: Paise.fromRupees(maxD),
                                  applies: applies,
                                  active: offer?.active ?? true,
                                  from: fromCtrl.text.trim(),
                                  to: toCtrl.text.trim(),
                                  used: offer?.used ?? 0,
                                );

                                ref
                                    .read(bmbStateProvider.notifier)
                                    .saveOffer(updated);
                                Navigator.of(sheetCtx).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Offer $code saved!'),
                                    backgroundColor: AppColors.leaf,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
