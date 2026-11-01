import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/widgets/bmb_button.dart';
import '../../../core/widgets/bmb_card.dart';
import '../../../core/widgets/bmb_empty_state.dart';
import '../../../core/widgets/bmb_tag.dart';
import '../../../models/subscription.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../subscription/controllers/subscription_controller.dart';
import '../controllers/outlet_controller.dart';

class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    final role = user?.role.toLowerCase() ?? '';
    final isStaff = role == 'staff';

    // Staff has no access to this screen per PDF role specification
    if (isStaff) {
      return Scaffold(
        backgroundColor: AppColors.paper,
        appBar: AppBar(
          title: const Text('Subscription'),
          backgroundColor: AppColors.card,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 54, color: AppColors.muted),
                const SizedBox(height: 16),
                Text('Access Restricted', style: AppText.h2),
                const SizedBox(height: 8),
                Text(
                  'Subscription management is restricted to Owner, Admin, and CTO accounts only.',
                  style: AppText.body.copyWith(color: AppColors.muted),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final subAsync = ref.watch(subscriptionControllerProvider);
    final notifier = ref.read(subscriptionControllerProvider.notifier);

    final outletsAsync = ref.watch(outletControllerProvider);
    final activeOutletsCount = (outletsAsync.value ?? [])
        .where((o) => o.isActive)
        .length;

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => notifier.refresh(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTopBar(context, ref),
              Expanded(
                child: subAsync.when(
                  data: (state) => _buildContent(
                    context,
                    state,
                    activeOutletsCount,
                    notifier,
                  ),
                  loading: () => _buildLoadingSkeleton(),
                  error: (err, _) => _buildErrorState(err.toString(), notifier),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, WidgetRef ref) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.horizontalPadding(context),
        vertical: Gap.md,
      ),
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.blueSoft,
              borderRadius: BorderRadius.circular(AppRadii.icon),
            ),
            child: const Icon(Icons.card_membership, color: AppColors.blue, size: 20),
          ),
          AppSpacing.gapWMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Subscription',
                  style: AppText.h3.copyWith(fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Plan details, outlet limits & billing invoices (#109-#113)',
                  style: AppText.caption.copyWith(color: AppColors.muted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            tooltip: 'Refresh subscription',
            onPressed: () => ref.read(subscriptionControllerProvider.notifier).refresh(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    SubscriptionState state,
    int activeOutletsCount,
    SubscriptionController notifier,
  ) {
    if (!state.hasSubscription) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 40),
          const BmbEmptyState(
            icon: Icon(Icons.credit_card_off_outlined, size: 40, color: AppColors.muted),
            title: 'No subscription yet',
            description:
                'Your organization does not have an active subscription record. Contact support to initialize a plan.',
          ),
          if (kSubscriptionWriteEnabled) ...[
            const SizedBox(height: 20),
            Center(
              child: BmbPrimaryButton(
                label: 'Create Subscription',
                onPressed: () {},
              ),
            ),
          ],
        ],
      );
    }

    final sub = state.subscription!;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.horizontalPadding(context),
        vertical: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Current Plan Overview Card
          _buildPlanCard(context, sub),
          const SizedBox(height: 16),

          // Outlet Usage Information Card
          _buildOutletUsageCard(context, sub, activeOutletsCount),
          const SizedBox(height: 20),

          // Invoice History Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Billing Invoices (#113)',
                style: AppText.h3.copyWith(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              if (kSubscriptionWriteEnabled)
                TextButton.icon(
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Invoice'),
                  onPressed: () {},
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Invoice History List
          _buildInvoiceList(context, state.invoices),
        ],
      ),
    );
  }

  Widget _buildPlanCard(BuildContext context, Subscription sub) {
    return BmbCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${sub.plan} Plan',
                        style: AppText.h2.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${sub.price.toStringAsFixed(2)} / ${sub.cycle}',
                        style: AppText.h3.copyWith(
                          color: AppColors.leaf,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(sub.status),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 14),

            // Metadata Grid
            Wrap(
              spacing: 24,
              runSpacing: 12,
              children: [
                _buildMetaItem(
                  'Started On',
                  sub.startedAt != null ? _formatDate(sub.startedAt!) : 'N/A',
                  Icons.calendar_today_outlined,
                ),
                _buildMetaItem(
                  'Renews At',
                  sub.renewsAt != null ? _formatDate(sub.renewsAt!) : 'N/A',
                  Icons.event_repeat_outlined,
                ),
                _buildMetaItem(
                  'Billing Cycle',
                  sub.cycle.toUpperCase(),
                  Icons.sync_outlined,
                ),
                _buildMetaItem(
                  'Outlets Included',
                  '${sub.outletsIncluded} Outlets',
                  Icons.storefront_outlined,
                ),
              ],
            ),

            if (kSubscriptionWriteEnabled) ...[
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: BmbSecondaryButton(
                  label: 'Change Plan',
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  onPressed: () {},
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOutletUsageCard(
    BuildContext context,
    Subscription sub,
    int activeCount,
  ) {
    final maxAllowed = sub.outletsIncluded;
    final ratio = maxAllowed > 0 ? (activeCount / maxAllowed).clamp(0.0, 1.0) : 0.0;
    final isFull = activeCount >= maxAllowed;

    return BmbCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.store_mall_directory_outlined, size: 20, color: AppColors.ink),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Using $activeCount of $maxAllowed outlets',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
                BmbTag(
                  label: 'Informational',
                  variant: BmbTagVariant.grey,
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 8,
                backgroundColor: AppColors.line,
                color: isFull ? AppColors.amber : AppColors.leaf,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Active outlets configured: $activeCount. Plan limit: $maxAllowed. Outlet limit verification is informational per current backend rules.',
              style: AppText.caption.copyWith(color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceList(
    BuildContext context,
    List<SubscriptionInvoice> invoices,
  ) {
    if (invoices.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadii.card),
          border: Border.all(color: AppColors.line),
        ),
        child: const Center(
          child: Text(
            'No billing invoices recorded yet.',
            style: TextStyle(fontSize: 13, color: AppColors.muted),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: invoices.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final inv = invoices[index];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppRadii.card),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.inputFill,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.receipt_long_outlined, size: 18, color: AppColors.ink),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      inv.invoiceNo,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      inv.date != null ? _formatDate(inv.date!) : 'Date not specified',
                      style: const TextStyle(fontSize: 11, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${inv.amount.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  _buildInvoiceStatusChip(inv.status),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(String status) {
    BmbTagVariant variant;
    switch (status.toLowerCase()) {
      case 'active':
        variant = BmbTagVariant.green;
        break;
      case 'expired':
        variant = BmbTagVariant.amber;
        break;
      case 'cancelled':
        variant = BmbTagVariant.grey;
        break;
      default:
        variant = BmbTagVariant.grey;
    }
    return BmbTag(label: status.toUpperCase(), variant: variant);
  }

  Widget _buildInvoiceStatusChip(String status) {
    BmbTagVariant variant;
    switch (status.toLowerCase()) {
      case 'paid':
        variant = BmbTagVariant.green;
        break;
      case 'pending':
        variant = BmbTagVariant.amber;
        break;
      case 'failed':
        variant = BmbTagVariant.red;
        break;
      default:
        variant = BmbTagVariant.grey;
    }
    return BmbTag(label: status.toUpperCase(), variant: variant);
  }

  Widget _buildMetaItem(String label, String value, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.muted),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
            Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          height: 180,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppRadii.card),
            border: Border.all(color: AppColors.line),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppRadii.card),
            border: Border.all(color: AppColors.line),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          height: 120,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppRadii.card),
            border: Border.all(color: AppColors.line),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(String error, SubscriptionController notifier) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.tandoor),
            const SizedBox(height: 12),
            Text('Failed to load subscription', style: AppText.h3),
            const SizedBox(height: 6),
            Text(
              error,
              style: AppText.caption.copyWith(color: AppColors.muted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            BmbPrimaryButton(
              label: 'Try Again',
              icon: const Icon(Icons.refresh, size: 18),
              onPressed: () => notifier.refresh(),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}
