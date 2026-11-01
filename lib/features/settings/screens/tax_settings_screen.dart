import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/widgets/bmb_button.dart';
import '../../../core/widgets/bmb_card.dart';
import '../../../core/widgets/bmb_section_header.dart';
import '../../../core/widgets/bmb_tag.dart';
import '../../../core/widgets/bmb_skeleton.dart';
import '../controllers/tax_settings_controller.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../models/tax_settings.dart';
import '../../../core/money/paise.dart';

class TaxSettingsScreen extends ConsumerStatefulWidget {
  const TaxSettingsScreen({super.key});

  @override
  ConsumerState<TaxSettingsScreen> createState() => _TaxSettingsScreenState();
}

class _TaxSettingsScreenState extends ConsumerState<TaxSettingsScreen> {
  String? _mode;
  double? _serviceCharge;
  bool? _scOnDinein;
  final TextEditingController _scController = TextEditingController();
  String? _scError;
  bool _isSaving = false;
  bool _isSavingRate = false;
  String? _activeRateModalError;

  @override
  void dispose() {
    _scController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(taxSettingsControllerProvider);
      state.whenData((settings) {
        if (settings != null) {
          setState(() {
            _mode = settings.mode;
            _serviceCharge = settings.serviceCharge;
            _scOnDinein = settings.scOnDinein;
            final scValue = settings.serviceCharge;
            _scController.text = scValue == scValue.truncateToDouble()
                ? scValue.toInt().toString()
                : scValue.toString();
          });
        }
      });
    });
  }

  void _syncLocalState(TaxSettings settings) {
    if (_mode == null) {
      _mode = settings.mode;
      _serviceCharge = settings.serviceCharge;
      _scOnDinein = settings.scOnDinein;
      final scValue = settings.serviceCharge;
      _scController.text = scValue == scValue.truncateToDouble()
          ? scValue.toInt().toString()
          : scValue.toString();
    }
  }

  bool _hasChanges(TaxSettings settings) {
    if (_mode == null) return false;
    return _mode != settings.mode ||
        _serviceCharge != settings.serviceCharge ||
        _scOnDinein != settings.scOnDinein;
  }

  @override
  Widget build(BuildContext context) {
    final taxSettingsAsync = ref.watch(taxSettingsControllerProvider);
    final user = ref.watch(authControllerProvider).value;
    final isStaff = user?.role == 'staff';

    return PopScope(
      canPop:
          taxSettingsAsync.value == null ||
          !_hasChanges(taxSettingsAsync.value!),
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Discard changes?', style: AppText.h3),
            content: Text(
              'You have unsaved changes. Are you sure you want to discard them?',
              style: AppText.body,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              BmbButton(
                label: 'Discard',
                variant: BmbButtonVariant.danger,
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
          ),
        );
        if (confirm == true && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Material(
        color: AppColors.paper,
        child: taxSettingsAsync.when(
          loading: () => _buildSkeleton(),
          error: (err, stack) => _buildErrorState(err.toString()),
          data: (settings) {
            if (settings == null) {
              return _buildEmptyState(isStaff);
            }

            _syncLocalState(settings);

            return Column(
              children: [
                _buildHeader(isStaff),
                if (isStaff) _buildStaffNote(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.horizontalPadding(context),
                      vertical: Gap.lg,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildChargingRulesSection(settings, isStaff),
                        AppSpacing.gapHXxl,
                        _buildRatesSection(settings, isStaff),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return Column(
      children: [
        Container(
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
              const BmbSkeleton(
                width: 36,
                height: 36,
                borderRadius: BorderRadius.all(Radius.circular(AppRadii.icon)),
              ),
              AppSpacing.gapWMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    BmbSkeleton(width: 120, height: 20),
                    AppSpacing.gapHXs,
                    BmbSkeleton(width: 200, height: 14),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: EdgeInsets.all(AppSpacing.horizontalPadding(context)),
            children: const [
              BmbSkeleton(
                height: 400,
                width: double.infinity,
                borderRadius: const BorderRadius.all(
                  Radius.circular(AppRadii.card),
                ),
              ),
              AppSpacing.gapHXxl,
              BmbSkeleton(
                height: 200,
                width: double.infinity,
                borderRadius: const BorderRadius.all(
                  Radius.circular(AppRadii.card),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(String err) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.chilli),
          AppSpacing.gapHMd,
          Text('Failed to load settings', style: AppText.h3),
          AppSpacing.gapHSm,
          Text(err, style: AppText.caption.copyWith(color: AppColors.chilli)),
          AppSpacing.gapHLg,
          BmbSecondaryButton(
            label: 'Retry',
            onPressed: () => ref.invalidate(taxSettingsControllerProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffNote() {
    return Container(
      width: double.infinity,
      color: AppColors.badgeGrey,
      padding: const EdgeInsets.symmetric(vertical: Gap.sm, horizontal: Gap.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock_outline, size: 14, color: AppColors.muted),
          AppSpacing.gapWSm,
          Text(
            'Staff view: Tax settings are read-only.',
            style: AppText.caption,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isStaff) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.percent, size: 48, color: AppColors.muted),
          AppSpacing.gapHMd,
          Text('No Tax Settings Found', style: AppText.h3),
          AppSpacing.gapHSm,
          Text(
            'Tax settings have not been configured for this organization.',
            style: AppText.caption,
          ),
          AppSpacing.gapHLg,
          if (!isStaff)
            BmbPrimaryButton(
              label: 'Set up taxes',
              onPressed: () async {
                final success = await ref
                    .read(taxSettingsControllerProvider.notifier)
                    .createTaxSettings();
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tax settings created successfully'),
                      backgroundColor: AppColors.leaf,
                    ),
                  );
                }
              },
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isStaff) {
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
              color: AppColors.leafSoft,
              borderRadius: BorderRadius.circular(AppRadii.icon),
            ),
            child: const Icon(Icons.percent, color: AppColors.leaf, size: 20),
          ),
          AppSpacing.gapWMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tax Settings',
                  style: AppText.h3.copyWith(fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'GST slabs, service charge rules & calculation models',
                  style: AppText.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChargingRulesSection(TaxSettings settings, bool isStaff) {
    final defaultRate = settings.defaultRate;
    final subtotal = 1000.0;
    final scPct = _serviceCharge ?? 0.0;
    final isDineInOn = _scOnDinein ?? true;
    // Server rule (#50A): service charge = % of subtotal (dine-in only if the dine-in switch is on)
    final scAmount = isDineInOn ? subtotal * (scPct / 100.0) : 0.0;

    double gstAmount = 0.0;
    double total = 0.0;

    if (_mode == 'inclusive') {
      // Inclusive: entered price includes tax, GST = base * rate / (100 + rate) and total = base + SC.
      gstAmount =
          subtotal *
          (defaultRate.percentage / (100.0 + defaultRate.percentage));
      total = subtotal + scAmount;
    } else {
      // Exclusive (#50A): taxable = subtotal + service charge - discounts (discount = 0 for sample);
      // tax = tax percent of taxable; total = taxable + tax
      final taxableAmount = subtotal + scAmount;
      gstAmount = taxableAmount * (defaultRate.percentage / 100.0);
      total = taxableAmount + gstAmount;
    }

    final hasChanges = _hasChanges(settings);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BmbCard(
          padding: const EdgeInsets.all(Gap.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Charging rules', style: AppText.h3),
              AppSpacing.gapHLg,
              const Divider(height: 1, color: AppColors.line),
              AppSpacing.gapHLg,

              Text('Tax mode', style: AppText.bodyStrong),
              AppSpacing.gapHSm,
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'exclusive', label: Text('Exclusive')),
                    ButtonSegment(value: 'inclusive', label: Text('Inclusive')),
                  ],
                  selected: {_mode ?? 'exclusive'},
                  onSelectionChanged: isStaff
                      ? null
                      : (Set<String> newSelection) {
                          setState(() => _mode = newSelection.first);
                        },
                  style: SegmentedButton.styleFrom(
                    selectedBackgroundColor: AppColors.tandoorSoft,
                    selectedForegroundColor: AppColors.tandoor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadii.input),
                    ),
                  ),
                ),
              ),
              AppSpacing.gapHXs,
              Text(
                _mode == 'inclusive'
                    ? 'Inclusive: item prices already include tax.'
                    : 'Exclusive: tax is added on top of the item price.',
                style: AppText.caption,
              ),

              AppSpacing.gapHLg,
              Text('Service charge (%)', style: AppText.bodyStrong),
              AppSpacing.gapHSm,
              TextFormField(
                controller: _scController,
                readOnly: isStaff,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  suffixText: '%',
                  errorText: _scError,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadii.input),
                    borderSide: const BorderSide(color: AppColors.line),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadii.input),
                    borderSide: const BorderSide(color: AppColors.tandoor),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: Gap.md,
                    vertical: Gap.sm,
                  ),
                ),
                onChanged: (v) {
                  setState(() {
                    if (v.isEmpty) {
                      _serviceCharge = 0.0;
                      _scError = null;
                      return;
                    }
                    final parsed = double.tryParse(v);
                    if (parsed == null || parsed < 0 || parsed > 20) {
                      _scError = 'Must be between 0 and 20';
                      _serviceCharge = parsed ?? 0.0;
                    } else {
                      _scError = null;
                      _serviceCharge = parsed;
                    }
                  });
                },
              ),
              AppSpacing.gapHXs,
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 14,
                    color: AppColors.muted,
                  ),
                  AppSpacing.gapWXs,
                  Expanded(
                    child: Text(
                      'Service charge is voluntary in India — CCPA guidelines restrict making it mandatory.',
                      style: AppText.caption.copyWith(color: AppColors.muted),
                    ),
                  ),
                ],
              ),

              AppSpacing.gapHLg,
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Dine-in only', style: AppText.bodyStrong),
                        AppSpacing.gapHXs,
                        Text(
                          'Do not apply service charge to takeaway or delivery',
                          style: AppText.caption,
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _scOnDinein ?? true,
                    activeTrackColor: AppColors.leaf,
                    onChanged: isStaff
                        ? null
                        : (v) => setState(() => _scOnDinein = v),
                  ),
                ],
              ),

              AppSpacing.gapHLg,
              const Divider(height: 1, color: AppColors.line),
              AppSpacing.gapHLg,

              Text('Sample bill of ₹1,000', style: AppText.bodyStrong),
              AppSpacing.gapHLg,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Subtotal', style: AppText.body),
                  Text('₹1,000.00', style: AppText.bodyStrong),
                ],
              ),
              AppSpacing.gapHMd,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Service charge', style: AppText.body),
                  Text(
                    Paise.fromRupees(scAmount).inr,
                    style: AppText.bodyStrong,
                  ),
                ],
              ),
              AppSpacing.gapHMd,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _mode == 'inclusive'
                        ? 'GST ${defaultRate.percentage.toStringAsFixed(defaultRate.percentage.truncateToDouble() == defaultRate.percentage ? 0 : 1)}% (included)'
                        : 'GST ${defaultRate.percentage.toStringAsFixed(defaultRate.percentage.truncateToDouble() == defaultRate.percentage ? 0 : 1)}%',
                    style: AppText.body,
                  ),
                  Text(
                    Paise.fromRupees(gstAmount).inr,
                    style: AppText.bodyStrong,
                  ),
                ],
              ),
              AppSpacing.gapHMd,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total', style: AppText.bodyStrong),
                  Text(Paise.fromRupees(total).inr, style: AppText.bodyStrong),
                ],
              ),

              if (!isStaff) ...[
                AppSpacing.gapHLg,
                SizedBox(
                  width: double.infinity,
                  child: BmbPrimaryButton(
                    label: _isSaving ? 'Saving...' : 'Save changes',
                    onPressed: (hasChanges && !_isSaving && _scError == null)
                        ? () => _saveTaxSettings(settings)
                        : null,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRatesSection(TaxSettings settings, bool isStaff) {
    // Sort rates: Default first, then by percentage
    final sortedRates = List<TaxRate>.from(settings.rates)
      ..sort((a, b) {
        if (a.isActive && !b.isActive) return -1;
        if (!a.isActive && b.isActive) return 1;
        return a.percentage.compareTo(b.percentage);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const BmbSectionHeader(
              title: 'GST Slabs',
              subtitle: 'Active tax rate categories',
            ),
            if (!isStaff)
              TextButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Tax Rate'),
                style: TextButton.styleFrom(foregroundColor: AppColors.tandoor),
                onPressed: _showAddRateModal,
              ),
          ],
        ),
        AppSpacing.gapHMd,
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sortedRates.length,
          separatorBuilder: (context, index) => const SizedBox(height: Gap.sm),
          itemBuilder: (context, index) {
            final rate = sortedRates[index];
            final isDefault = rate.isActive;

            return BmbCard(
              padding: const EdgeInsets.all(Gap.md),
              backgroundColor: isDefault
                  ? AppColors.tandoorSoft
                  : AppColors.card,
              child: Row(
                children: [
                  _buildRateIcon(rate, isDefault),
                  AppSpacing.gapWMd,
                  Expanded(child: _buildRateDetails(rate, isDefault)),
                  if (!isDefault && !isStaff)
                    TextButton(
                      child: Text(
                        'Make default',
                        style: AppText.bodyStrong.copyWith(
                          color: AppColors.tandoor,
                        ),
                      ),
                      onPressed: () =>
                          _confirmSetDefault(settings.defaultRate, rate),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRateIcon(TaxRate rate, bool isDefault) {
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isDefault ? AppColors.tandoorSoft : AppColors.badgeGrey,
        borderRadius: BorderRadius.circular(AppRadii.icon),
      ),
      child: Text(
        '${rate.percentage.toStringAsFixed(rate.percentage.truncateToDouble() == rate.percentage ? 0 : 1)}%',
        style: AppText.numeric.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: isDefault ? AppColors.tandoor : AppColors.ink,
        ),
      ),
    );
  }

  Widget _buildRateDetails(TaxRate rate, bool isDefault) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: Gap.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(rate.name, style: AppText.bodyStrong),
            if (isDefault)
              const BmbTag(label: 'Default', variant: BmbTagVariant.orange),
          ],
        ),
        AppSpacing.gapHXs,
        Text(
          'CGST: ${(rate.percentage / 2).toStringAsFixed(1)}% · SGST: ${(rate.percentage / 2).toStringAsFixed(1)}%',
          style: AppText.caption.copyWith(color: AppColors.muted),
        ),
      ],
    );
  }

  void _saveTaxSettings(TaxSettings settings) async {
    setState(() => _isSaving = true);

    final modeChanged = _mode != settings.mode ? _mode : null;
    final scChanged = _serviceCharge != settings.serviceCharge
        ? _serviceCharge
        : null;
    final scDineinChanged = _scOnDinein != settings.scOnDinein
        ? _scOnDinein
        : null;

    final success = await ref
        .read(taxSettingsControllerProvider.notifier)
        .updateTaxSettings(
          mode: modeChanged,
          serviceCharge: scChanged,
          scOnDinein: scDineinChanged,
        );

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tax settings updated successfully.'),
            backgroundColor: AppColors.leaf,
          ),
        );
      }
    }
  }

  void _confirmSetDefault(TaxRate oldRate, TaxRate newRate) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Change Default Rate?', style: AppText.h3),
        content: Text(
          'Are you sure you want to change the default tax rate from ${oldRate.percentage}% to ${newRate.percentage}%?',
          style: AppText.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          BmbButton(
            label: 'Confirm',
            variant: BmbButtonVariant.primary,
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await ref
          .read(taxSettingsControllerProvider.notifier)
          .setDefaultTaxRate(newRate.id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Default tax rate updated.'),
            backgroundColor: AppColors.leaf,
          ),
        );
      }
    }
  }

  void _showAddRateModal() {
    String name = '';
    String percentageStr = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadii.card),
        ),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: AppSpacing.horizontalPadding(ctx),
                right: AppSpacing.horizontalPadding(ctx),
                top: Gap.xl,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Add Tax Rate', style: AppText.h3),
                  AppSpacing.gapHLg,
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Rate Name (e.g. GST 28%)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadii.input),
                        borderSide: const BorderSide(color: AppColors.line),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadii.input),
                        borderSide: const BorderSide(color: AppColors.tandoor),
                      ),
                    ),
                    onChanged: (v) => name = v,
                  ),
                  AppSpacing.gapHMd,
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Percentage (e.g. 28)',
                      suffixText: '%',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadii.input),
                        borderSide: const BorderSide(color: AppColors.line),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadii.input),
                        borderSide: const BorderSide(color: AppColors.tandoor),
                      ),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (v) => percentageStr = v,
                  ),
                  if (_activeRateModalError != null) ...[
                    AppSpacing.gapHSm,
                    Text(
                      _activeRateModalError!,
                      style: AppText.caption.copyWith(color: AppColors.chilli),
                    ),
                  ],
                  AppSpacing.gapHLg,
                  SizedBox(
                    width: double.infinity,
                    child: BmbPrimaryButton(
                      label: _isSavingRate ? 'Adding...' : 'Add Rate',
                      onPressed: _isSavingRate
                          ? null
                          : () async {
                              final pct = double.tryParse(percentageStr);
                              if (name.trim().isEmpty ||
                                  pct == null ||
                                  pct < 0) {
                                setModalState(() {
                                  _activeRateModalError =
                                      'Please enter a valid name and positive percentage.';
                                });
                                return;
                              }

                              setModalState(() {
                                _activeRateModalError = null;
                                _isSavingRate = true;
                              });

                              final success = await ref
                                  .read(taxSettingsControllerProvider.notifier)
                                  .addTaxRate(
                                    name: name.trim(),
                                    percentage: pct,
                                  );

                              if (mounted) {
                                setModalState(() {
                                  _isSavingRate = false;
                                });
                                Navigator.pop(ctx);
                                if (success) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Tax rate added.'),
                                      backgroundColor: AppColors.leaf,
                                    ),
                                  );
                                }
                              }
                            },
                    ),
                  ),
                  AppSpacing.gapHXxl,
                ],
              ),
            );
          },
        );
      },
    );
  }
}
