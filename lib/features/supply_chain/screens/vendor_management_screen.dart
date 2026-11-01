import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/widgets/bmb_button.dart';
import '../../../core/widgets/bmb_card.dart';
import '../../../core/widgets/bmb_empty_state.dart';
import '../../../core/widgets/bmb_screen_header.dart';
import '../../../core/widgets/bmb_tag.dart';
import '../../../core/widgets/lifecycle_list_view.dart';
import '../../../models/vendor.dart';
import '../../auth/controllers/auth_controller.dart';
import '../providers/vendor_providers.dart';

class VendorManagementScreen extends ConsumerStatefulWidget {
  const VendorManagementScreen({super.key});

  @override
  ConsumerState<VendorManagementScreen> createState() =>
      _VendorManagementScreenState();
}

class _VendorManagementScreenState
    extends ConsumerState<VendorManagementScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'All';
  bool _showInactive = false;

  bool _canWrite(String? role) {
    return role == 'owner' || role == 'admin' || role == 'cto';
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).value;
    final role = user?.role;
    final canWrite = _canWrite(role);

    if (_showInactive && !canWrite) {
      _showInactive = false;
    }

    final asyncVendors = _showInactive
        ? ref.watch(inactiveVendorsProvider)
        : ref.watch(activeVendorsProvider);

    return Material(
      color: AppColors.paper,
      child: Column(
        children: [
          BmbScreenHeader(
            title: 'Vendor Management',
            subtitle: _showInactive ? 'Inactive Vendors' : 'Active Vendors',
            icon: Icons.local_shipping_outlined,
            iconBg: AppColors.tandoorSoft,
            iconColor: AppColors.tandoor,
            trailing: canWrite && !_showInactive
                ? BmbButton.primary(
                    label: 'Add Vendor',
                    size: BmbButtonSize.sm,
                    icon: const Icon(Icons.add, size: 16),
                    onPressed: () => _openVendorSheet(context, null),
                  )
                : null,
          ),
          Expanded(
            child: asyncVendors.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Error loading vendors', style: AppText.h3),
                    AppSpacing.gapHSm,
                    Text(err.toString(), style: AppText.body),
                    AppSpacing.gapHMd,
                    BmbButton.outline(
                      label: 'Retry',
                      size: BmbButtonSize.md,
                      onPressed: () {
                        if (_showInactive) {
                          ref.read(inactiveVendorsProvider.notifier).refresh();
                        } else {
                          ref.read(activeVendorsProvider.notifier).refresh();
                        }
                      },
                    ),
                  ],
                ),
              ),
              data: (vendors) {
                final categories = {'All'};
                for (final v in vendors) {
                  if (v.category != null && v.category!.isNotEmpty) {
                    categories.add(v.category!);
                  }
                }

                if (!_selectedCategory.contains('All') &&
                    !categories.contains(_selectedCategory)) {
                  _selectedCategory = 'All';
                }

                final filtered = vendors.where((v) {
                  if (_selectedCategory != 'All' && v.category != _selectedCategory) {
                    return false;
                  }
                  if (_searchQuery.trim().isEmpty) return true;
                  final q = _searchQuery.toLowerCase();
                  return v.vendorName.toLowerCase().contains(q) ||
                      (v.contactPerson?.toLowerCase().contains(q) ?? false) ||
                      (v.phone?.contains(q) ?? false) ||
                      (v.vendorNo?.toLowerCase().contains(q) ?? false);
                }).toList();

                return Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.horizontalPadding(context),
                        vertical: Gap.md,
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  onChanged: (v) =>
                                      setState(() => _searchQuery = v),
                                  decoration: InputDecoration(
                                    hintText:
                                        'Search by name, contact, phone, or ID...',
                                    prefixIcon:
                                        const Icon(Icons.search, size: 20),
                                    filled: true,
                                    fillColor: AppColors.card,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(AppRadii.input),
                                      borderSide:
                                          const BorderSide(color: AppColors.line),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(AppRadii.input),
                                      borderSide:
                                          const BorderSide(color: AppColors.line),
                                    ),
                                  ),
                                ),
                              ),
                              if (canWrite) ...[
                                AppSpacing.gapWMd,
                                TextButton(
                                  onPressed: () => setState(
                                      () => _showInactive = !_showInactive),
                                  child: Text(_showInactive
                                      ? 'View Active'
                                      : 'View Inactive'),
                                ),
                              ],
                            ],
                          ),
                          AppSpacing.gapHSm,
                          SizedBox(
                            height: 40,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: categories.length,
                              separatorBuilder: (_, __) => AppSpacing.gapWSm,
                              itemBuilder: (context, index) {
                                final cat = categories.elementAt(index);
                                final isSelected = cat == _selectedCategory;
                                return ChoiceChip(
                                  label: Text(cat),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    if (selected) {
                                      setState(() => _selectedCategory = cat);
                                    }
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: filtered.isEmpty
                          ? const BmbEmptyState(
                              title: 'No vendors found',
                              description: 'Try adjusting your filters or add a new vendor.',
                            )
                          : _showInactive
                              ? _buildInactiveList(filtered, canWrite)
                              : _buildActiveGrid(filtered, canWrite),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInactiveList(List<Vendor> vendors, bool canWrite) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.horizontalPadding(context),
      ),
      child: LifecycleListView<Vendor>(
        title: 'Vendor',
        items: vendors
            .map(
              (v) => LifecycleItem(
                data: v,
                title: v.vendorName,
                subtitle: v.vendorNo ?? v.category ?? 'Vendor',
                isActive: false,
              ),
            )
            .toList(),
        showInactive: true,
        onToggleView: () => setState(() => _showInactive = false),
        onCreate: () => _openVendorSheet(context, null),
        onEdit: (v) {},
        onDeactivate: (v) {},
        canHardDelete: canWrite,
        onRestore: (v) async {
          try {
            await ref
                .read(inactiveVendorsProvider.notifier)
                .restoreVendor(v.id);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Vendor restored successfully')),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to restore: $e')),
              );
            }
          }
        },
        onHardDelete: (v) async {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Delete Permanently?'),
              content: Text(
                  'Are you sure you want to permanently delete ${v.vendorName}? This cannot be undone.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text(
                    'Delete',
                    style: TextStyle(color: AppColors.chilli),
                  ),
                ),
              ],
            ),
          );

          if (confirm == true) {
            try {
              await ref
                  .read(inactiveVendorsProvider.notifier)
                  .hardDeleteVendor(v.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Vendor permanently deleted')),
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to delete: $e')),
                );
              }
            }
          }
        },
      ),
    );
  }

  Widget _buildActiveGrid(List<Vendor> vendors, bool canWrite) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount =
            width >= 960 ? 3 : (width >= 620 ? 2 : 1);

        return GridView.builder(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.horizontalPadding(context),
            vertical: Gap.md,
          ),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: Gap.md,
            mainAxisSpacing: Gap.md,
            mainAxisExtent: 220,
          ),
          itemCount: vendors.length,
          itemBuilder: (context, index) {
            final vendor = vendors[index];
            return _buildVendorCard(context, vendor, canWrite);
          },
        );
      },
    );
  }

  Widget _buildVendorCard(BuildContext context, Vendor vendor, bool canWrite) {
    return InkWell(
      onTap: () => _showVendorDetails(context, vendor, canWrite),
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: BmbCard(
        padding: const EdgeInsets.all(Gap.md),
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
                        vendor.vendorName,
                        style: AppText.h3.copyWith(fontWeight: FontWeight.w800),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      AppSpacing.gapHXs,
                      Text(
                        vendor.vendorNo ?? 'New Vendor',
                        style: AppText.caption.copyWith(color: AppColors.muted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (vendor.category != null && vendor.category!.isNotEmpty) ...[
                  AppSpacing.gapWSm,
                  BmbTag(
                    label: vendor.category!,
                    variant: BmbTagVariant.blue,
                  ),
                ],
              ],
            ),
            const Divider(height: 16, color: AppColors.line),
            if (vendor.contactPerson != null && vendor.contactPerson!.isNotEmpty) ...[
              _buildInfoRow('Contact', vendor.contactPerson!),
              AppSpacing.gapHXs,
            ],
            if (vendor.phone != null && vendor.phone!.isNotEmpty) ...[
              _buildInfoRow('Phone', vendor.phone!),
              AppSpacing.gapHXs,
            ],
            if (vendor.gstin != null && vendor.gstin!.isNotEmpty) ...[
              _buildInfoRow('GSTIN', vendor.gstin!),
              AppSpacing.gapHXs,
            ],
            if (vendor.paymentTerms != null && vendor.paymentTerms!.isNotEmpty) ...[
              _buildInfoRow('Terms', vendor.paymentTerms!),
            ],
            const Spacer(),
            if (canWrite)
              BmbButton.outline(
                label: 'Edit Vendor',
                size: BmbButtonSize.sm,
                expanded: true,
                onPressed: () => _openVendorSheet(context, vendor),
              ),
          ],
        ),
      ),
    );
  }

  void _showVendorDetails(BuildContext context, Vendor vendor, bool canWrite) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.sheet)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(Gap.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    vendor.vendorName,
                    style: AppText.h2,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
            if (vendor.vendorNo != null)
              Text('ID: ${vendor.vendorNo}', style: AppText.caption),
            const Divider(height: Gap.xl),
            if (vendor.contactPerson != null && vendor.contactPerson!.isNotEmpty) ...[
              _buildDetailRow('Contact Person', vendor.contactPerson!),
              AppSpacing.gapHMd,
            ],
            if (vendor.phone != null && vendor.phone!.isNotEmpty) ...[
              _buildDetailRow('Phone', vendor.phone!),
              AppSpacing.gapHMd,
            ],
            if (vendor.gstin != null && vendor.gstin!.isNotEmpty) ...[
              _buildDetailRow('GSTIN', vendor.gstin!),
              AppSpacing.gapHMd,
            ],
            if (vendor.category != null && vendor.category!.isNotEmpty) ...[
              _buildDetailRow('Category', vendor.category!),
              AppSpacing.gapHMd,
            ],
            if (vendor.address != null && vendor.address!.isNotEmpty) ...[
              _buildDetailRow('Address', vendor.address!),
              AppSpacing.gapHMd,
            ],
            if (vendor.paymentTerms != null && vendor.paymentTerms!.isNotEmpty) ...[
              _buildDetailRow('Payment Terms', vendor.paymentTerms!),
              AppSpacing.gapHMd,
            ],
            AppSpacing.gapHLg,
            if (canWrite)
              Row(
                children: [
                  Expanded(
                    child: BmbButton.outline(
                      label: 'Edit',
                      size: BmbButtonSize.md,
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _openVendorSheet(context, vendor);
                      },
                    ),
                  ),
                  AppSpacing.gapWMd,
                  Expanded(
                    child: BmbButton.danger(
                      label: 'Deactivate',
                      size: BmbButtonSize.md,
                      onPressed: () async {
                        try {
                          await ref
                              .read(activeVendorsProvider.notifier)
                              .deactivateVendor(vendor.id);
                          if (ctx.mounted) {
                            Navigator.of(ctx).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Vendor deactivated')),
                            );
                          }
                        } catch (e) {
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(content: Text('Failed: $e')),
                            );
                          }
                        }
                      },
                    ),
                  ),
                ],
              ),
            AppSpacing.gapHLg,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.caption.copyWith(color: AppColors.muted)),
        AppSpacing.gapHXs,
        Text(value, style: AppText.bodyStrong),
      ],
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

  void _openVendorSheet(BuildContext context, Vendor? vendor) {
    final isEdit = vendor != null;
    final nameCtrl = TextEditingController(text: vendor?.vendorName ?? '');
    final contactCtrl = TextEditingController(text: vendor?.contactPerson ?? '');
    final phoneCtrl = TextEditingController(text: vendor?.phone ?? '');
    final gstinCtrl = TextEditingController(text: vendor?.gstin ?? '');
    final catCtrl = TextEditingController(text: vendor?.category ?? '');
    final addrCtrl = TextEditingController(text: vendor?.address ?? '');
    final termsCtrl = TextEditingController(text: vendor?.paymentTerms ?? '');

    String? serverError;

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
                        Expanded(
                          child: Text(
                            isEdit ? 'Edit Vendor' : 'Add Supplier',
                            style: AppText.h3,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(sheetCtx).pop(),
                        ),
                      ],
                    ),
                    const Divider(height: 20, color: AppColors.line),
                    if (serverError != null) ...[
                      Text(
                        serverError!,
                        style: const TextStyle(color: AppColors.chilli),
                      ),
                      AppSpacing.gapHSm,
                    ],
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Vendor / Company Name *',
                        hintText: 'e.g. Metro Cash & Carry',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    AppSpacing.gapHMd,
                    LayoutBuilder(
                      builder: (context, c) {
                        final isSmall = c.maxWidth < 460;
                        if (isSmall) {
                          return Column(
                            children: [
                              TextField(
                                controller: contactCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Contact Person',
                                  hintText: 'e.g. Murugan K',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              AppSpacing.gapHMd,
                              TextField(
                                controller: phoneCtrl,
                                keyboardType: TextInputType.phone,
                                decoration: const InputDecoration(
                                  labelText: 'Phone Number',
                                  hintText: 'e.g. 9841022334',
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
                                controller: contactCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Contact Person',
                                  hintText: 'e.g. Murugan K',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            AppSpacing.gapWMd,
                            Expanded(
                              child: TextField(
                                controller: phoneCtrl,
                                keyboardType: TextInputType.phone,
                                decoration: const InputDecoration(
                                  labelText: 'Phone Number',
                                  hintText: 'e.g. 9841022334',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    AppSpacing.gapHMd,
                    LayoutBuilder(
                      builder: (context, c) {
                        final isSmall = c.maxWidth < 460;
                        if (isSmall) {
                          return Column(
                            children: [
                              TextField(
                                controller: gstinCtrl,
                                textCapitalization: TextCapitalization.characters,
                                onChanged: (val) {
                                  final upper = val.toUpperCase();
                                  if (upper != val) {
                                    gstinCtrl.value = gstinCtrl.value.copyWith(
                                      text: upper,
                                      selection: TextSelection.collapsed(
                                          offset: upper.length),
                                    );
                                  }
                                },
                                decoration: const InputDecoration(
                                  labelText: 'GSTIN (Tax ID)',
                                  hintText: '33AAAAA0000A1Z5',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              AppSpacing.gapHMd,
                              TextField(
                                controller: catCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Category',
                                  hintText: 'e.g. Groceries, Poultry, Dairy',
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
                                controller: gstinCtrl,
                                textCapitalization: TextCapitalization.characters,
                                onChanged: (val) {
                                  final upper = val.toUpperCase();
                                  if (upper != val) {
                                    gstinCtrl.value = gstinCtrl.value.copyWith(
                                      text: upper,
                                      selection: TextSelection.collapsed(
                                          offset: upper.length),
                                    );
                                  }
                                },
                                decoration: const InputDecoration(
                                  labelText: 'GSTIN (Tax ID)',
                                  hintText: '33AAAAA0000A1Z5',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            AppSpacing.gapWMd,
                            Expanded(
                              child: TextField(
                                controller: catCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Category',
                                  hintText: 'e.g. Groceries, Poultry, Dairy',
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
                      controller: addrCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Address / Market Location',
                        hintText: 'e.g. Koyambedu Wholesale Market, Chennai',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    AppSpacing.gapHMd,
                    TextField(
                      controller: termsCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Payment Terms',
                        hintText: 'e.g. Net 7 days, Weekly settlement',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    AppSpacing.gapHLg,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        BmbButton.outline(
                          label: 'Cancel',
                          size: BmbButtonSize.md,
                          onPressed: () => Navigator.of(sheetCtx).pop(),
                        ),
                        AppSpacing.gapWMd,
                        BmbButton.primary(
                          label: 'Save Vendor',
                          size: BmbButtonSize.md,
                          onPressed: () async {
                            final name = nameCtrl.text.trim();
                            if (name.isEmpty) {
                              setSheetState(() {
                                serverError = 'Vendor name is required';
                              });
                              return;
                            }

                            final data = {
                              'vendorName': name,
                              if (contactCtrl.text.trim().isNotEmpty)
                                'contactPerson': contactCtrl.text.trim(),
                              if (phoneCtrl.text.trim().isNotEmpty)
                                'phone': phoneCtrl.text.trim(),
                              if (gstinCtrl.text.trim().isNotEmpty)
                                'gstin': gstinCtrl.text.trim().toUpperCase(),
                              if (catCtrl.text.trim().isNotEmpty)
                                'category': catCtrl.text.trim(),
                              if (addrCtrl.text.trim().isNotEmpty)
                                'address': addrCtrl.text.trim(),
                              if (termsCtrl.text.trim().isNotEmpty)
                                'paymentTerms': termsCtrl.text.trim(),
                            };

                            try {
                              if (isEdit) {
                                await ref
                                    .read(activeVendorsProvider.notifier)
                                    .updateVendor(vendor.id, data);
                              } else {
                                await ref
                                    .read(activeVendorsProvider.notifier)
                                    .createVendor(data);
                              }
                              if (sheetCtx.mounted) {
                                Navigator.of(sheetCtx).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Vendor ${isEdit ? "updated" : "created"} successfully!'),
                                    backgroundColor: AppColors.leaf,
                                  ),
                                );
                              }
                            } catch (e) {
                              setSheetState(() {
                                serverError = e.toString();
                              });
                            }
                          },
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
