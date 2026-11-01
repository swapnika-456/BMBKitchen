import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/widgets/bmb_button.dart';
import '../../../core/widgets/bmb_card.dart';
import '../../../core/widgets/bmb_key_value_row.dart';
import '../../../core/widgets/bmb_section_header.dart';
import '../../../mock/mock_state.dart';
import '../controllers/active_outlet_provider.dart';
import '../../../models/restaurant_setup.dart';

class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  late TextEditingController _brandController;
  late TextEditingController _legalController;
  late TextEditingController _gstinController;
  late TextEditingController _fssaiController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _prefixController;
  late TextEditingController _footerController;

  @override
  void initState() {
    super.initState();
    final setup = ref.read(bmbStateProvider).setup;
    _brandController = TextEditingController(text: setup.brand);
    _legalController = TextEditingController(text: setup.legal);
    _gstinController = TextEditingController(text: setup.gstin);
    _fssaiController = TextEditingController(text: setup.fssai);
    _phoneController = TextEditingController(text: setup.phone);
    _emailController = TextEditingController(text: setup.email);
    _addressController = TextEditingController(text: setup.address);
    _prefixController = TextEditingController(text: setup.billPrefix);
    _footerController = TextEditingController(text: setup.footer);
  }

  @override
  void dispose() {
    _brandController.dispose();
    _legalController.dispose();
    _gstinController.dispose();
    _fssaiController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _prefixController.dispose();
    _footerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bmbStateProvider);
    final isTablet = MediaQuery.of(context).size.width >= 900;

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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.tandoorSoft,
                          borderRadius: BorderRadius.circular(AppRadii.icon),
                        ),
                        child: const Icon(
                          Icons.storefront,
                          color: AppColors.tandoor,
                          size: 20,
                        ),
                      ),
                      AppSpacing.gapWMd,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Restaurant Setup (02)',
                              style: AppText.h3.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Legal entity, tax registration & live bill format · ${ref.watch(activeOutletProvider)?.name ?? ''}',
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
                AppSpacing.gapWMd,
                BmbPrimaryButton(
                  label: 'Save Changes',
                  icon: const Icon(Icons.save_outlined, size: 18),
                  onPressed: _saveSettings,
                ),
              ],
            ),
          ),

          // Main Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.horizontalPadding(context),
                vertical: Gap.lg,
              ),
              child: isTablet
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 58, child: _buildForm()),
                        AppSpacing.gapWXxl,
                        Expanded(flex: 42, child: _buildLiveReceiptPreview()),
                      ],
                    )
                  : Column(
                      children: [
                        _buildForm(),
                        AppSpacing.gapHXxl,
                        _buildLiveReceiptPreview(),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const BmbSectionHeader(
          title: 'Brand & Legal Identity',
          subtitle: 'Official business credentials printed on tax invoices',
        ),
        AppSpacing.gapHMd,

        BmbCard(
          padding: const EdgeInsets.all(Gap.lg),
          child: Column(
            children: [
              _field('Brand Name', _brandController, 'e.g. Biryani & More'),
              AppSpacing.gapHMd,
              _field(
                'Legal Entity Name',
                _legalController,
                'e.g. BMB Foods Private Limited',
              ),
              AppSpacing.gapHMd,
              Row(
                children: [
                  Expanded(
                    child: _field(
                      'GSTIN',
                      _gstinController,
                      '15-character GSTIN',
                    ),
                  ),
                  AppSpacing.gapWMd,
                  Expanded(
                    child: _field(
                      'FSSAI License',
                      _fssaiController,
                      '14-digit FSSAI',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        AppSpacing.gapHXxl,

        const BmbSectionHeader(
          title: 'Contact & Location',
          subtitle: 'Store location and customer support lines',
        ),
        AppSpacing.gapHMd,

        BmbCard(
          padding: const EdgeInsets.all(Gap.lg),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _field(
                      'Primary Phone',
                      _phoneController,
                      '+91 98765 43210',
                    ),
                  ),
                  AppSpacing.gapWMd,
                  Expanded(
                    child: _field(
                      'Support Email',
                      _emailController,
                      'support@bmbkitchen.in',
                    ),
                  ),
                ],
              ),
              AppSpacing.gapHMd,
              _field(
                'Full Store Address',
                _addressController,
                'Premises, Street, City, State, PIN',
                maxLines: 2,
              ),
            ],
          ),
        ),

        AppSpacing.gapHXxl,

        const BmbSectionHeader(
          title: 'Invoice & Thermal Printing',
          subtitle: 'Numbering sequence and custom receipt footer notes',
        ),
        AppSpacing.gapHMd,

        BmbCard(
          padding: const EdgeInsets.all(Gap.lg),
          child: Column(
            children: [
              _field('Bill Number Prefix', _prefixController, 'e.g. BMB'),
              AppSpacing.gapHMd,
              _field(
                'Receipt Footer Message',
                _footerController,
                'e.g. Thank you! Visit again!',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _field(
    String label,
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.label.copyWith(fontWeight: FontWeight.w600)),
        AppSpacing.gapHXs,
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: AppText.body,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: AppColors.card,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: Gap.md,
              vertical: Gap.sm,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.input),
              borderSide: const BorderSide(color: AppColors.line),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.input),
              borderSide: const BorderSide(color: AppColors.line),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLiveReceiptPreview() {
    final brand = _brandController.text.trim().isEmpty
        ? 'Biryani & More'
        : _brandController.text.trim();
    final legal = _legalController.text.trim();
    final gstin = _gstinController.text.trim();
    final fssai = _fssaiController.text.trim();
    final address = _addressController.text.trim();
    final phone = _phoneController.text.trim();
    final prefix = _prefixController.text.trim().isEmpty
        ? 'BMB'
        : _prefixController.text.trim();
    final footer = _footerController.text.trim().isEmpty
        ? 'Thank you! Visit again!'
        : _footerController.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const BmbSectionHeader(
          title: 'Live Receipt Preview',
          subtitle: 'Real-time 80mm ESC/POS thermal print layout',
        ),
        AppSpacing.gapHMd,

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(Gap.lg),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadii.card),
            border: Border.all(color: AppColors.line, width: 1),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(31, 27, 22, 0.05),
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                brand.toUpperCase(),
                style: AppText.h2.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              if (legal.isNotEmpty) ...[
                AppSpacing.gapHXs,
                Text(
                  legal,
                  style: AppText.caption.copyWith(color: AppColors.muted),
                ),
              ],
              if (address.isNotEmpty) ...[
                AppSpacing.gapHXs,
                Text(
                  address,
                  style: AppText.caption.copyWith(color: AppColors.muted),
                  textAlign: TextAlign.center,
                ),
              ],
              if (phone.isNotEmpty) ...[
                AppSpacing.gapHXs,
                Text(
                  'Tel: $phone',
                  style: AppText.caption.copyWith(color: AppColors.muted),
                ),
              ],
              if (gstin.isNotEmpty) ...[
                AppSpacing.gapHXs,
                Text(
                  'GSTIN: $gstin',
                  style: AppText.caption.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
              if (fssai.isNotEmpty) ...[
                AppSpacing.gapHXs,
                Text('FSSAI: $fssai', style: AppText.caption),
              ],

              const Divider(height: 24, thickness: 1, color: AppColors.ink),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Bill: $prefix-2026-0042',
                    style: AppText.caption.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Table: T-04',
                    style: AppText.caption.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Date: 17 Sep 2026 14:30', style: AppText.caption),
                  Text('Cashier: Admin', style: AppText.caption),
                ],
              ),

              const Divider(height: 20, thickness: 1, color: AppColors.line),

              // Mock Items
              Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Text(
                      'Item',
                      style: AppText.caption.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Qty',
                      textAlign: TextAlign.center,
                      style: AppText.caption.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Amount',
                      textAlign: TextAlign.right,
                      style: AppText.caption.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Gap.xs),
              Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Text('Dum Biryani (Full)', style: AppText.caption),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '2',
                      textAlign: TextAlign.center,
                      style: AppText.caption,
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      '₹640.00',
                      textAlign: TextAlign.right,
                      style: AppText.caption,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Gap.xs),
              Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Text('Garlic Naan', style: AppText.caption),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '3',
                      textAlign: TextAlign.center,
                      style: AppText.caption,
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      '₹210.00',
                      textAlign: TextAlign.right,
                      style: AppText.caption,
                    ),
                  ),
                ],
              ),

              const Divider(height: 20, thickness: 1, color: AppColors.line),

              BmbKeyValueRow(
                label: 'Subtotal',
                value: '₹850.00',
                isNumeric: true,
              ),
              AppSpacing.gapHXs,
              BmbKeyValueRow(
                label: 'CGST (2.5%)',
                value: '₹21.25',
                isNumeric: true,
              ),
              AppSpacing.gapHXs,
              BmbKeyValueRow(
                label: 'SGST (2.5%)',
                value: '₹21.25',
                isNumeric: true,
              ),
              const Divider(height: 16, thickness: 1, color: AppColors.ink),
              BmbKeyValueRow(
                label: 'NET PAYABLE',
                value: '₹892.50',
                isNumeric: true,
                labelStyle: AppText.bodyStrong.copyWith(
                  fontWeight: FontWeight.w800,
                ),
                valueStyle: AppText.numeric.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),

              const Divider(height: 24, thickness: 1, color: AppColors.ink),

              Text(
                footer,
                style: AppText.caption.copyWith(
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _saveSettings() {
    final updated = RestaurantSetup(
      legal: _legalController.text.trim(),
      brand: _brandController.text.trim(),
      gstin: _gstinController.text.trim(),
      fssai: _fssaiController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      openTime: ref.read(bmbStateProvider).setup.openTime,
      closeTime: ref.read(bmbStateProvider).setup.closeTime,
      billPrefix: _prefixController.text.trim(),
      footer: _footerController.text.trim(),
    );

    ref.read(bmbStateProvider.notifier).updateSetup(updated);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Restaurant setup saved successfully.'),
        backgroundColor: AppColors.leaf,
      ),
    );
  }
}
