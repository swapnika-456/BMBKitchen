import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_text.dart';
import '../theme/spacing.dart';
import 'bmb_bottom_sheet.dart';
import 'bmb_button.dart';
import 'bmb_text_field.dart';

const String kMockManagerPin = '1234';

/// Reusable manager PIN verification sheet.
/// Protects discounts, order/KOT cancellations, and day reopening.
class ManagerPinSheet extends StatefulWidget {
  final String actionTitle;
  final String? subtitle;
  final bool requireReason;
  final String reasonLabel;
  final String reasonHint;

  const ManagerPinSheet({
    super.key,
    required this.actionTitle,
    this.subtitle,
    this.requireReason = false,
    this.reasonLabel = 'Reason',
    this.reasonHint = 'Enter mandatory reason',
  });

  /// Static helper to open the sheet and verify PIN.
  /// Returns a record with success boolean and optional reason.
  static Future<({bool success, String? reason})> verify({
    required BuildContext context,
    required String actionTitle,
    String? subtitle,
    bool requireReason = false,
    String reasonLabel = 'Reason',
    String reasonHint = 'Enter mandatory reason',
  }) async {
    final result = await showBmbModal<({bool success, String? reason})>(
      context: context,
      title: actionTitle,
      child: ManagerPinSheet(
        actionTitle: actionTitle,
        subtitle: subtitle,
        requireReason: requireReason,
        reasonLabel: reasonLabel,
        reasonHint: reasonHint,
      ),
    );

    return result ?? (success: false, reason: null);
  }

  @override
  State<ManagerPinSheet> createState() => _ManagerPinSheetState();
}

class _ManagerPinSheetState extends State<ManagerPinSheet> {
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _pinController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() {
      _errorMessage = null;
    });

    final enteredPin = _pinController.text.trim();
    final reason = _reasonController.text.trim();

    if (widget.requireReason && reason.isEmpty) {
      setState(() {
        _errorMessage = 'Reason is mandatory for this action.';
      });
      HapticFeedback.vibrate();
      return;
    }

    if (enteredPin != kMockManagerPin) {
      setState(() {
        _errorMessage = 'Wrong manager PIN. (Demo PIN: 1234)';
      });
      HapticFeedback.vibrate();
      return;
    }

    Navigator.of(
      context,
    ).pop((success: true, reason: reason.isEmpty ? null : reason));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.subtitle != null) ...[
          Text(
            widget.subtitle!,
            style: AppText.caption.copyWith(color: AppColors.muted),
          ),
          AppSpacing.gapH16,
        ],
        if (_errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.chilliSoft,
              borderRadius: BorderRadius.circular(AppRadii.input),
              border: Border.all(
                color: AppColors.chilli.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  color: AppColors.chilli,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: AppText.caption.copyWith(
                      color: AppColors.chilli,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.gapH16,
        ],
        if (widget.requireReason) ...[
          BmbTextField(
            label: widget.reasonLabel,
            hint: widget.reasonHint,
            controller: _reasonController,
            autofocus: true,
          ),
          AppSpacing.gapH16,
        ],
        BmbTextField(
          label: 'Manager PIN (4 digits)',
          hint: 'Demo PIN 1234',
          controller: _pinController,
          obscureText: true,
          keyboardType: TextInputType.number,
          autofocus: !widget.requireReason,
          onEditingComplete: _submit,
        ),
        AppSpacing.gapH24,
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            BmbButton.outline(
              label: 'Cancel',
              onPressed: () =>
                  Navigator.of(context).pop((success: false, reason: null)),
              size: BmbButtonSize.md,
            ),
            AppSpacing.gapW12,
            BmbButton.primary(
              label: 'Confirm Approval',
              onPressed: _submit,
              size: BmbButtonSize.md,
            ),
          ],
        ),
      ],
    );
  }
}
