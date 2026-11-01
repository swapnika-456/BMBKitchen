import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/widgets/bmb_card.dart';
import '../../../core/widgets/bmb_screen_header.dart';
import '../../../core/widgets/bmb_tag.dart';
import '../../../models/integration.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../integrations/controllers/integration_controller.dart';

class IntegrationsScreen extends ConsumerStatefulWidget {
  const IntegrationsScreen({super.key});

  @override
  ConsumerState<IntegrationsScreen> createState() => _IntegrationsScreenState();
}

class _IntegrationsScreenState extends ConsumerState<IntegrationsScreen> {
  String _formatDate(DateTime? dt) {
    if (dt == null) return '-';
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final m = months[dt.month - 1];
    final d = dt.day.toString().padLeft(2, '0');
    final y = dt.year;
    return '$d $m $y';
  }

  bool _isAllowedRole() {
    final user = ref.watch(authControllerProvider).value;
    final role = user?.role.toLowerCase() ?? '';
    return role == 'owner' || role == 'admin' || role == 'cto';
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAllowedRole()) {
      return _buildAccessRestrictedView();
    }

    final asyncState = ref.watch(integrationControllerProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: asyncState.when(
        loading: () => _buildLoadingSkeleton(),
        error: (err, _) => _buildErrorState(err.toString()),
        data: (state) => _buildContent(context, state),
      ),
    );
  }

  Widget _buildAccessRestrictedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Gap.xl),
        child: BmbCard(
          padding: const EdgeInsets.all(Gap.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.lock_outline_rounded,
                size: 56,
                color: AppColors.muted,
              ),
              const SizedBox(height: Gap.md),
              Text(
                'Access Restricted',
                style: AppText.h2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Gap.sm),
              Text(
                'Staff members do not have access to this screen.\n'
                'Only Organization Owners, Admins, and CTOs can view and manage integrations.',
                style: AppText.bodyMedium.copyWith(color: AppColors.muted),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Gap.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const BmbScreenHeader(
            title: 'Integrations',
            subtitle: 'Loading third-party integrations...',
          ),
          const SizedBox(height: Gap.lg),
          ...List.generate(
            3,
            (idx) => Padding(
              padding: const EdgeInsets.only(bottom: Gap.lg),
              child: BmbCard(
                padding: const EdgeInsets.all(Gap.lg),
                child: SizedBox(
                  height: 120,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.tandoor,
                      strokeWidth: 2,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Gap.xl),
        child: BmbCard(
          padding: const EdgeInsets.all(Gap.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: AppColors.chilli,
              ),
              const SizedBox(height: Gap.md),
              Text(
                'Failed to load integrations',
                style: AppText.h3,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Gap.sm),
              Text(
                message,
                style: AppText.caption.copyWith(color: AppColors.muted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Gap.lg),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.tandoor,
                  foregroundColor: Colors.white,
                ),
                onPressed: () =>
                    ref.read(integrationControllerProvider.notifier).refresh(),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, IntegrationState state) {
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final cardHeight = 210.0 * textScale;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallMobile = constraints.maxWidth < 640;
        final isTablet =
            constraints.maxWidth >= 640 && constraints.maxWidth < 1024;
        final gridCrossAxisCount = isSmallMobile ? 1 : (isTablet ? 2 : 3);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(Gap.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BmbScreenHeader(
                title: 'Integrations',
                subtitle:
                    '${state.connectedCount} of ${state.totalCount} connected to third-party services',
              ),
              const SizedBox(height: Gap.md),

              // Persistent Note Banner
              _buildNoteBanner(),
              const SizedBox(height: Gap.lg),

              // Feedback alerts
              if (state.errorMessage != null) ...[
                _buildAlertBanner(
                  state.errorMessage!,
                  isError: true,
                  onDismiss: () => ref
                      .read(integrationControllerProvider.notifier)
                      .clearErrorMessage(),
                ),
                const SizedBox(height: Gap.md),
              ],
              if (state.successMessage != null) ...[
                _buildAlertBanner(
                  state.successMessage!,
                  isError: false,
                  onDismiss: () => ref
                      .read(integrationControllerProvider.notifier)
                      .clearSuccessMessage(),
                ),
                const SizedBox(height: Gap.md),
              ],

              // Empty State
              if (state.integrations.isEmpty)
                _buildEmptyState(state)
              else ...[
                // Category sections
                ...state.groupedByCategory.entries.map((entry) {
                  final categoryName = entry.key;
                  final categoryIntegrations = entry.value;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Text(
                            categoryName.toUpperCase(),
                            style: AppText.caption.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.1,
                              color: AppColors.muted,
                            ),
                          ),
                          const SizedBox(width: Gap.sm),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.line.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${categoryIntegrations.length}',
                              style: AppText.caption.copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Gap.sm),
                      GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: gridCrossAxisCount,
                          crossAxisSpacing: Gap.md,
                          mainAxisSpacing: Gap.md,
                          mainAxisExtent: cardHeight,
                        ),
                        itemCount: categoryIntegrations.length,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (context, idx) {
                          final item = categoryIntegrations[idx];
                          return _buildIntegrationCard(item, state);
                        },
                      ),
                      const SizedBox(height: Gap.lg),
                    ],
                  );
                }),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildNoteBanner() {
    return BmbCard(
      padding: const EdgeInsets.all(Gap.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.muted,
            size: 20,
          ),
          const SizedBox(width: Gap.sm),
          Expanded(
            child: Text(
              'This records the connection status only. Credentials and syncing aren\'t part of this API.',
              style: AppText.bodyMedium.copyWith(
                color: AppColors.muted,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertBanner(
    String message, {
    required bool isError,
    required VoidCallback onDismiss,
  }) {
    final bgColor = isError
        ? AppColors.chilli.withValues(alpha: 0.12)
        : AppColors.leaf.withValues(alpha: 0.12);
    final fgColor = isError ? AppColors.chilli : AppColors.leaf;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Gap.md, vertical: Gap.sm),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: fgColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: fgColor,
            size: 18,
          ),
          const SizedBox(width: Gap.sm),
          Expanded(
            child: Text(
              message,
              style: AppText.caption.copyWith(color: fgColor),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 16, color: fgColor),
            onPressed: onDismiss,
            splashRadius: 16,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(IntegrationState state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Gap.xxl),
        child: BmbCard(
          padding: const EdgeInsets.all(Gap.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.extension_off_outlined,
                size: 56,
                color: AppColors.muted,
              ),
              const SizedBox(height: Gap.md),
              Text(
                'No integrations yet',
                style: AppText.h3,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Gap.sm),
              Text(
                'Default third-party integrations (Aggregators, Payments, Messaging, Accounting, Reputation) have not been seeded.',
                style: AppText.bodyMedium.copyWith(color: AppColors.muted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Gap.lg),
              ElevatedButton.icon(
                key: const Key('setup_defaults_button'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.tandoor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: Gap.lg,
                    vertical: Gap.md,
                  ),
                ),
                onPressed: state.isSeeding
                    ? null
                    : () => ref
                        .read(integrationControllerProvider.notifier)
                        .seedDefaults(),
                icon: state.isSeeding
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.playlist_add_check_rounded, size: 18),
                label: Text(
                  state.isSeeding ? 'Setting up...' : 'Set up defaults',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIntegrationCard(Integration item, IntegrationState state) {
    final isLoading = state.actionLoadingId == item.id;

    return BmbCard(
      padding: const EdgeInsets.all(Gap.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  item.name,
                  style: AppText.h3.copyWith(fontSize: 15),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: Gap.xs),
              BmbTag.grey(item.category),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              item.isConnected
                  ? const BmbTag.green('Connected')
                  : const BmbTag.grey('Not connected'),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Text(
              item.note.isNotEmpty ? item.note : 'No notes available',
              style: AppText.caption.copyWith(color: AppColors.muted),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (item.isConnected) ...[
            const SizedBox(height: 4),
            Text(
              'Connected since: ${_formatDate(item.connectedSince)}',
              style: AppText.caption.copyWith(
                color: AppColors.muted,
                fontSize: 11,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: Gap.sm),
          if (item.isConnected)
            OutlinedButton(
              key: Key('disconnect_btn_${item.id}'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.chilli,
                side: BorderSide(color: AppColors.chilli.withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(vertical: 6),
                visualDensity: VisualDensity.compact,
              ),
              onPressed:
                  isLoading ? null : () => _showDisconnectConfirmDialog(item),
              child: isLoading
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.chilli,
                      ),
                    )
                  : const Text('Disconnect'),
            )
          else
            ElevatedButton(
              key: Key('connect_btn_${item.id}'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.tandoor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 6),
                visualDensity: VisualDensity.compact,
              ),
              onPressed:
                  isLoading ? null : () => _showConnectConfirmDialog(item),
              child: isLoading
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Mark as connected'),
            ),
        ],
      ),
    );
  }

  void _showConnectConfirmDialog(Integration item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Connect ${item.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mark ${item.name} as connected?',
              style: AppText.bodyMedium,
            ),
            const SizedBox(height: Gap.md),
            Container(
              padding: const EdgeInsets.all(Gap.sm),
              decoration: BoxDecoration(
                color: AppColors.line.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Note: This records the connection status only. Credentials and syncing aren\'t part of this API.',
                style: AppText.caption.copyWith(color: AppColors.muted),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.tandoor,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ref
                  .read(integrationControllerProvider.notifier)
                  .connect(item.id);
            },
            child: const Text('Mark as connected'),
          ),
        ],
      ),
    );
  }

  void _showDisconnectConfirmDialog(Integration item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Disconnect ${item.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to disconnect ${item.name}?',
              style: AppText.bodyMedium,
            ),
            const SizedBox(height: Gap.md),
            Container(
              padding: const EdgeInsets.all(Gap.sm),
              decoration: BoxDecoration(
                color: AppColors.line.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Note: This records the connection status only. Credentials and syncing aren\'t part of this API.',
                style: AppText.caption.copyWith(color: AppColors.muted),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.chilli,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ref
                  .read(integrationControllerProvider.notifier)
                  .disconnect(item.id);
            },
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );
  }
}
