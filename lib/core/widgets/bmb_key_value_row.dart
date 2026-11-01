import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/spacing.dart';

/// Standardized Label/Value row for receipts, bills, reports, and detail sheets.
/// Label is Flexible with ellipsis; Value never wraps and uses tabular numeric or bodyStrong.
class BmbKeyValueRow extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;
  final Color? valueColor;
  final bool isNumeric;
  final bool isMuted;

  const BmbKeyValueRow({
    super.key,
    required this.label,
    required this.value,
    this.labelStyle,
    this.valueStyle,
    this.valueColor,
    this.isNumeric = false,
    this.isMuted = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveLabelStyle = (labelStyle ?? AppText.label).copyWith(
      color: isMuted ? AppColors.muted : AppColors.ink,
    );

    final effectiveValueStyle =
        (valueStyle ?? (isNumeric ? AppText.numeric : AppText.bodyStrong))
            .copyWith(color: valueColor ?? AppColors.ink);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Gap.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              label,
              style: effectiveLabelStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          AppSpacing.gapWMd,
          Text(
            value,
            style: effectiveValueStyle,
            maxLines: 1,
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }
}
