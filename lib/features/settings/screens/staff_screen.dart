import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/widgets/bmb_button.dart';
import '../../../core/widgets/bmb_card.dart';
import '../../../core/widgets/bmb_empty_state.dart';
import '../../../core/widgets/bmb_search_field.dart';
import '../../../core/widgets/bmb_tag.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/role_controller.dart';
import '../controllers/staff_controller.dart';
import '../../../services/api/auth_api_service.dart';

class StaffScreen extends ConsumerStatefulWidget {
  const StaffScreen({super.key});

  @override
  ConsumerState<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends ConsumerState<StaffScreen> {
  String? _inviteRole = 'staff';
  String? _generatedLink;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.value;
    final isPrivileged =
        user != null &&
        (user.role == 'owner' || user.role == 'admin' || user.role == 'cto');

    final rolesAsync = ref.watch(roleControllerProvider);
    final staffAsync = ref.watch(staffListProvider);
    final staffFilter = ref.watch(staffFilterProvider);

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
                          color: AppColors.blueSoft,
                          borderRadius: BorderRadius.circular(AppRadii.icon),
                        ),
                        child: const Icon(
                          Icons.people,
                          color: AppColors.blue,
                          size: 20,
                        ),
                      ),
                      AppSpacing.gapWMd,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'User & Staff Management (03)',
                              style: AppText.h3.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Role-based team access',
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
              ],
            ),
          ),

          // Main Scrollable Area
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.horizontalPadding(context),
                vertical: Gap.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Invite Staff Section (Only for privileged users)
                  if (isPrivileged) ...[
                    BmbCard(
                      padding: const EdgeInsets.all(Gap.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.blueSoft,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.person_add_alt_1,
                                  color: AppColors.blue,
                                  size: 24,
                                ),
                              ),
                              AppSpacing.gapWMd,
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Invite Staff',
                                    style: AppText.h3.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Generate an invitation link for your staff',
                                    style: AppText.caption,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          AppSpacing.gapHLg,
                          Text(
                            'Staff Role',
                            style: AppText.label.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          AppSpacing.gapHXs,
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: Gap.md,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.paper,
                              borderRadius: BorderRadius.circular(
                                AppRadii.input,
                              ),
                              border: Border.all(color: AppColors.line),
                            ),
                            child: rolesAsync.when(
                              data: (roles) {
                                final customRoles = roles
                                    .where((r) => r.isActive)
                                    .toList();

                                final items = [
                                  const DropdownMenuItem(
                                    value: 'admin',
                                    child: Text('Admin'),
                                  ),
                                  const DropdownMenuItem(
                                    value: 'cto',
                                    child: Text('CTO'),
                                  ),
                                  const DropdownMenuItem(
                                    value: 'staff',
                                    child: Text('Staff'),
                                  ),
                                  if (customRoles.isNotEmpty)
                                    const DropdownMenuItem(
                                      value: 'header',
                                      enabled: false,
                                      child: Divider(),
                                    ),
                                  ...customRoles.map(
                                    (r) => DropdownMenuItem(
                                      value: 'custom_${r.id}',
                                      child: Text(r.name),
                                    ),
                                  ),
                                ];

                                return DropdownButton<String>(
                                  value: _inviteRole,
                                  isExpanded: true,
                                  underline: const SizedBox(),
                                  icon: const Icon(
                                    Icons.keyboard_arrow_down,
                                    color: AppColors.muted,
                                  ),
                                  items: items,
                                  onChanged: (v) {
                                    if (v != null && v != 'header')
                                      setState(() => _inviteRole = v);
                                  },
                                );
                              },
                              loading: () => const Center(
                                child: CircularProgressIndicator(),
                              ),
                              error: (_, __) =>
                                  const Text('Failed to load roles'),
                            ),
                          ),
                          AppSpacing.gapHMd,
                          SizedBox(
                            width: double.infinity,
                            child: BmbPrimaryButton(
                              label: 'Generate Invitation Link',
                              icon: const Icon(Icons.link, size: 18),
                              onPressed: () {
                                if (user == null || user.organizationId.isEmpty)
                                  return;
                                rolesAsync.whenData((roles) {
                                  final roleVal = _inviteRole ?? 'staff';
                                  String finalRole = 'staff';
                                  String specificRoleParam = '';

                                  if (roleVal == 'admin' ||
                                      roleVal == 'cto' ||
                                      roleVal == 'staff') {
                                    finalRole = roleVal;
                                  } else if (roleVal.startsWith('custom_')) {
                                    finalRole = 'staff';
                                    specificRoleParam =
                                        '&specificRole=${roleVal.substring(7)}';
                                  }

                                  const baseUrl = 'https://bmbkitchen.app/join';
                                  setState(() {
                                    _generatedLink =
                                        '$baseUrl?orgId=${user.organizationId}&role=$finalRole$specificRoleParam';
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Invitation link generated!',
                                      ),
                                      backgroundColor: AppColors.leaf,
                                    ),
                                  );
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (_generatedLink != null) ...[
                      AppSpacing.gapHMd,
                      BmbCard(
                        padding: const EdgeInsets.all(Gap.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.blueSoft,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.link,
                                    color: AppColors.blue,
                                    size: 24,
                                  ),
                                ),
                                AppSpacing.gapWMd,
                                Text(
                                  'Invitation Link',
                                  style: AppText.h3.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            AppSpacing.gapHLg,
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.paper,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.line),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.link,
                                    color: AppColors.muted,
                                    size: 20,
                                  ),
                                  AppSpacing.gapWSm,
                                  Expanded(
                                    child: Text(
                                      _generatedLink!,
                                      style: AppText.body.copyWith(
                                        color: AppColors.blue,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  AppSpacing.gapWSm,
                                  BmbPrimaryButton(
                                    label: 'Copy',
                                    icon: const Icon(Icons.copy, size: 16),
                                    onPressed: () async {
                                      await Clipboard.setData(
                                        ClipboardData(text: _generatedLink!),
                                      );
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Link copied to clipboard',
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                            AppSpacing.gapHMd,
                            Row(
                              children: [
                                Expanded(
                                  child: BmbPrimaryButton(
                                    label: 'Share',
                                    icon: const Icon(Icons.send, size: 16),
                                    onPressed: () {
                                      Share.share(
                                        'Join our organization on BMB Kitchen:\n$_generatedLink',
                                      );
                                    },
                                  ),
                                ),
                                AppSpacing.gapWMd,
                                Expanded(
                                  child: BmbButton(
                                    label: 'New Link',
                                    icon: const Icon(Icons.refresh, size: 16),
                                    onPressed: () {
                                      setState(() {
                                        _generatedLink = null;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                    AppSpacing.gapHLg,
                  ],

                  // Search Field
                  BmbSearchField(
                    controller: _searchController,
                    hintText: 'Search staff by name or email...',
                    onChanged: (val) {
                      ref
                          .read(staffFilterProvider.notifier)
                          .updateFilter(
                            staffFilter.copyWith(
                              search: val.trim().toLowerCase(),
                            ),
                          );
                    },
                  ),

                  AppSpacing.gapHMd,

                  // Role Filter Chips
                  staffAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (err, stack) => Text('Error: $err'),
                    data: (staffMembers) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Staff Members (${staffMembers.length})',
                            style: AppText.h3.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          AppSpacing.gapHSm,
                          Text('All team members', style: AppText.caption),
                          AppSpacing.gapHMd,

                          rolesAsync.when(
                            data: (roles) {
                              return SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    ChoiceChip(
                                      label: const Text('All Roles'),
                                      selected: staffFilter.role == null,
                                      onSelected: (s) {
                                        if (s) {
                                          ref
                                              .read(
                                                staffFilterProvider.notifier,
                                              )
                                              .updateFilter(
                                                staffFilter.copyWith(
                                                  role: const Wrapped(null),
                                                ),
                                              );
                                        }
                                      },
                                      showCheckmark: false,
                                    ),
                                    ...roles.map((r) {
                                      final isSel = staffFilter.role == r.id;
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          left: Gap.sm,
                                        ),
                                        child: ChoiceChip(
                                          label: Text(r.name),
                                          selected: isSel,
                                          onSelected: (s) {
                                            if (s) {
                                              ref
                                                  .read(
                                                    staffFilterProvider
                                                        .notifier,
                                                  )
                                                  .updateFilter(
                                                    staffFilter.copyWith(
                                                      role: Wrapped(r.id),
                                                    ),
                                                  );
                                            }
                                          },
                                          showCheckmark: false,
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              );
                            },
                            loading: () => const SizedBox(),
                            error: (_, __) => const SizedBox(),
                          ),

                          AppSpacing.gapHLg,

                          if (staffMembers.isEmpty)
                            const BmbEmptyState(
                              title: 'No staff members found',
                              description:
                                  'Try adjusting your role filter or search query.',
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: staffMembers.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: Gap.sm),
                              itemBuilder: (context, index) {
                                final member = staffMembers[index];
                                final roleName =
                                    rolesAsync.value
                                        ?.where((r) => r.id == member.role)
                                        .firstOrNull
                                        ?.name ??
                                    member.role;

                                BmbTagVariant tagVariant = BmbTagVariant.grey;
                                switch (roleName.toLowerCase()) {
                                  case 'manager':
                                  case 'owner':
                                    tagVariant = BmbTagVariant.plum;
                                    break;
                                  case 'cashier':
                                    tagVariant = BmbTagVariant.green;
                                    break;
                                  case 'captain':
                                    tagVariant = BmbTagVariant.blue;
                                    break;
                                  case 'chef':
                                    tagVariant = BmbTagVariant.orange;
                                    break;
                                }

                                  return BmbCard(
                                    padding: AppSpacing.cardPaddingRow,
                                    child: Row(
                                      children: [
                                        // Avatar Initials
                                        Container(
                                          width: 42,
                                          height: 42,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: member.isActive ? AppColors.blueSoft : AppColors.line,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Text(
                                            member.name.isNotEmpty
                                                ? member.name[0].toUpperCase()
                                                : '?',
                                            style: AppText.h3.copyWith(
                                              color: member.isActive ? AppColors.blue : AppColors.muted,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        AppSpacing.gapWMd,

                                        // Staff Details
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Flexible(
                                                    child: Text(
                                                      member.name,
                                                      style: AppText.bodyStrong.copyWith(
                                                        decoration: member.isActive ? null : TextDecoration.lineThrough,
                                                        color: member.isActive ? AppColors.ink : AppColors.muted,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  AppSpacing.gapWSm,
                                                  BmbTag(
                                                    label: roleName,
                                                    variant: tagVariant,
                                                  ),
                                                  if (!member.isActive) ...[
                                                    AppSpacing.gapWSm,
                                                    const BmbTag(label: 'Inactive', variant: BmbTagVariant.red),
                                                  ],
                                                ],
                                              ),
                                              AppSpacing.gapHXs,
                                              Text(
                                                member.email,
                                                style: AppText.caption,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),

                                        // Actions Menu
                                        if (isPrivileged && member.id != user?.id && !(member.role == 'owner' && user?.role != 'owner'))
                                          PopupMenuButton<String>(
                                            icon: const Icon(Icons.more_vert, color: AppColors.muted),
                                            onSelected: (val) => _handleUserAction(context, ref, val, member),
                                            itemBuilder: (ctx) => [
                                              if (member.isActive) ...[
                                                const PopupMenuItem(
                                                  value: 'role',
                                                  child: Text('Change role'),
                                                ),
                                                const PopupMenuItem(
                                                  value: 'deactivate',
                                                  child: Text('Deactivate'),
                                                ),
                                              ] else ...[
                                                const PopupMenuItem(
                                                  value: 'recover',
                                                  child: Text('Recover'),
                                                ),
                                              ],
                                              const PopupMenuItem(
                                                value: 'delete',
                                                child: Text('Delete permanently', style: TextStyle(color: AppColors.chilli)),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                  );
                                },
                            ),
                            if (staffMembers.length % ref.watch(staffFilterProvider).limit == 0 && staffMembers.isNotEmpty) ...[
                              AppSpacing.gapHMd,
                              Center(
                                child: TextButton(
                                  onPressed: () {
                                    ref.read(staffListProvider.notifier).loadMore();
                                  },
                                  child: const Text('Load More'),
                                ),
                              ),
                            ],
                        ],
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

  Future<void> _handleUserAction(BuildContext context, WidgetRef ref, String action, var member) async {
    final apiService = ref.read(authApiServiceProvider);

    if (action == 'deactivate') {
      final res = await apiService.deactivateUser(member.id);
      _showResult(res.message);
      print('Deactivate response: ${res.data}');
      ref.invalidate(staffListProvider);
    } else if (action == 'recover') {
      final res = await apiService.recoverUser(member.id);
      _showResult(res.message);
      print('Recover response: ${res.data}');
      ref.invalidate(staffListProvider);
    } else if (action == 'delete') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Delete User'),
          content: Text('Are you sure you want to permanently delete ${member.name}?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: AppColors.chilli))),
          ],
        ),
      );
      if (confirm == true) {
        final res = await apiService.deleteUser(member.id);
        _showResult(res.message);
        print('Delete response: ${res.data}');
        ref.invalidate(staffListProvider);
      }
    } else if (action == 'role') {
      _showRoleDialog(context, ref, member);
    }
  }

  void _showResult(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _showRoleDialog(BuildContext context, WidgetRef ref, var member) {
    String selectedRole = member.role;
    
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Change Role'),
              content: DropdownButton<String>(
                value: selectedRole,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  DropdownMenuItem(value: 'cto', child: Text('CTO')),
                  DropdownMenuItem(value: 'staff', child: Text('Staff')),
                ],
                onChanged: (v) {
                  if (v != null) setDialogState(() => selectedRole = v);
                },
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final apiService = ref.read(authApiServiceProvider);
                    final res = await apiService.updateUserRole(member.id, selectedRole);
                    _showResult(res.message);
                    print('Update Role response: ${res.data}');
                    ref.invalidate(staffListProvider);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
