import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/widgets/bmb_button.dart';
import '../../../core/widgets/bmb_card.dart';
import '../../../core/widgets/bmb_section_header.dart';
import '../controllers/role_controller.dart';
import '../../../mock/mock_state.dart';
import '../controllers/active_outlet_provider.dart';

class RolesScreen extends ConsumerStatefulWidget {
  const RolesScreen({super.key});

  @override
  ConsumerState<RolesScreen> createState() => _RolesScreenState();
}

class _RolesScreenState extends ConsumerState<RolesScreen> {
  String? _selectedRoleId;
  final Map<String, Set<String>> _rolePerms = {};

  final Map<String, List<({String key, String label, String desc})>>
  _permMatrix = {
    'POS & Billing Operations': [
      (
        key: 'pos.order',
        label: 'Create & Modify Orders',
        desc: 'Punch items and send KOTs to kitchen',
      ),
      (
        key: 'pos.discount',
        label: 'Apply Custom Discounts',
        desc: 'Authorize percentage or flat discounts on bills',
      ),
      (
        key: 'pos.settle',
        label: 'Settle Bills & Collect Tender',
        desc: 'Accept cash, UPI and card transactions',
      ),
      (
        key: 'pos.cancel',
        label: 'Void Order & Cancel Items',
        desc: 'Cancel confirmed orders with audit reason',
      ),
    ],
    'Kitchen Operations': [
      (
        key: 'kitchen.view',
        label: 'Access Kitchen Display',
        desc: 'View incoming tickets on KOT board',
      ),
      (
        key: 'kitchen.advance',
        label: 'Advance Preparation Stage',
        desc: 'Mark cooking, ready and completed stages',
      ),
      (
        key: 'kitchen.recipes',
        label: 'View Dish Formulations',
        desc: 'Access ingredient linkages and portion weights',
      ),
    ],
    'Inventory & Supply Chain': [
      (
        key: 'stock.view',
        label: 'View Inventory Levels',
        desc: 'Inspect current raw ingredient stock and unit rates',
      ),
      (
        key: 'stock.purchase',
        label: 'Record Purchase Inward',
        desc: 'Enter vendor bills and update on-hand stock',
      ),
      (
        key: 'stock.adjust',
        label: 'Wastage & Spoilage Adjustments',
        desc: 'Log manual write-offs and variance deductions',
      ),
    ],
    'Finance & Administration': [
      (
        key: 'finance.reports',
        label: 'View Reports & Analytics',
        desc: 'Access daily turnover, item ranks and GST summaries',
      ),
      (
        key: 'finance.closing',
        label: 'Authorize End-of-Day Closing',
        desc: 'Reconcile drawer cash and freeze daily shifts',
      ),
      (
        key: 'admin.settings',
        label: 'Manage Settings & Staff',
        desc: 'Configure printers, tax rates, and employee credentials',
      ),
    ],
  };

  @override
  Widget build(BuildContext context) {
    final rolesAsync = ref.watch(roleControllerProvider);
    final mockState = ref.watch(bmbStateProvider);

    return rolesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (roles) {
        if (roles.isEmpty) {
          return const Center(child: Text('No roles found.'));
        }

        _selectedRoleId ??= roles.first.id;

        // Initialize in-memory perms map
        for (final r in roles) {
          _rolePerms.putIfAbsent(r.id, () => Set<String>.from(r.permissions));
        }

        final selectedRole = roles.firstWhere(
          (r) => r.id == _selectedRoleId,
          orElse: () => roles.first,
        );

        final activePerms = _rolePerms[_selectedRoleId!] ?? {};
        final isSuperAdmin =
            selectedRole.isFullAccess || activePerms.contains('all');

        return Material(
          color: AppColors.paper,
          child: Column(
            children: [
              // Top Header Bar
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.horizontalPadding(context),
                  vertical: Gap.md,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.card,
                  border: Border(bottom: BorderSide(color: AppColors.line)),
                ),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: Gap.sm,
                  runSpacing: Gap.sm,
                  children: [
                    SizedBox(
                      width: 300,
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.plumSoft,
                              borderRadius: BorderRadius.circular(
                                AppRadii.icon,
                              ),
                            ),
                            child: const Icon(
                              Icons.lock_person,
                              color: AppColors.plum,
                              size: 20,
                            ),
                          ),
                          AppSpacing.gapWMd,
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Roles & Permissions (04)',
                                  style: AppText.h3.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'Capability matrices and operational privileges · ${ref.watch(activeOutletProvider)?.name ?? ''}',
                                  style: AppText.caption,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    BmbPrimaryButton(
                      label: 'Save Permissions',
                      icon: const Icon(Icons.save_outlined, size: 18),
                      onPressed: () async {
                        for (final r in roles) {
                          final perms = _rolePerms[r.id];
                          if (perms != null &&
                              (perms.length != r.permissions.length ||
                                  !perms.containsAll(r.permissions))) {
                            await ref
                                .read(roleControllerProvider.notifier)
                                .updateRolePermissions(r.id, perms.toList());
                          }
                        }
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Permission matrices saved successfully.',
                              ),
                              backgroundColor: AppColors.leaf,
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),

              // Main Body
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.horizontalPadding(context),
                    vertical: Gap.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Role Selector Tabs / Cards
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: roles.map((r) {
                            final isSel = r.id == _selectedRoleId;
                            return Padding(
                              padding: const EdgeInsets.only(right: Gap.md),
                              child: InkWell(
                                onTap: () =>
                                    setState(() => _selectedRoleId = r.id),
                                borderRadius: BorderRadius.circular(
                                  AppRadii.card,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: Gap.lg,
                                    vertical: Gap.md,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSel
                                        ? AppColors.plumSoft
                                        : AppColors.card,
                                    borderRadius: BorderRadius.circular(
                                      AppRadii.card,
                                    ),
                                    border: Border.all(
                                      color: isSel
                                          ? AppColors.plum
                                          : AppColors.line,
                                      width: isSel ? 2 : 1,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            r.name,
                                            style: AppText.bodyStrong.copyWith(
                                              color: isSel
                                                  ? AppColors.plum
                                                  : AppColors.ink,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          if (r.isFullAccess) ...[
                                            AppSpacing.gapWSm,
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: AppColors.plum,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                'ALL ACCESS',
                                                style: AppText.caption.copyWith(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      AppSpacing.gapHXs,
                                      Text(
                                        r.description,
                                        style: AppText.caption.copyWith(
                                          color: isSel
                                              ? AppColors.plum
                                              : AppColors.muted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      AppSpacing.gapHXxl,

                      // Permission Matrix for Selected Role
                      BmbSectionHeader(
                        title: '${selectedRole.name} Capabilities',
                        subtitle:
                            'Toggle individual capabilities for this team role',
                      ),
                      AppSpacing.gapHMd,

                      ..._permMatrix.entries.map((entry) {
                        final sectionTitle = entry.key;
                        final permissions = entry.value;

                        return Container(
                          margin: const EdgeInsets.only(bottom: Gap.lg),
                          child: BmbCard(
                            padding: const EdgeInsets.all(Gap.lg),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  sectionTitle,
                                  style: AppText.h3.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                AppSpacing.gapHMd,
                                ...permissions.map((p) {
                                  final isGranted =
                                      isSuperAdmin ||
                                      activePerms.contains(p.key);
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: Gap.xs,
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                p.label,
                                                style: AppText.bodyStrong,
                                              ),
                                              Text(
                                                p.desc,
                                                style: AppText.caption,
                                              ),
                                            ],
                                          ),
                                        ),
                                        Switch(
                                          value: isGranted,
                                          activeThumbColor: AppColors.plum,
                                          onChanged: isSuperAdmin
                                              ? null // Superadmin cannot toggle individual perms
                                              : (val) {
                                                  setState(() {
                                                    if (val) {
                                                      activePerms.add(p.key);
                                                    } else {
                                                      activePerms.remove(p.key);
                                                    }
                                                  });
                                                },
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
