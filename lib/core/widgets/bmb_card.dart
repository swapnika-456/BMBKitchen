import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_shadows.dart';
import '../theme/spacing.dart';

/// Standard rounded card with 20px radius.
/// Enforces: Surface gets EITHER a shadow OR a 1px line border — never both, never neither.
class BmbCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color backgroundColor;
  final bool hasBorder;
  final Color? borderColor;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  const BmbCard({
    super.key,
    required this.child,
    this.padding,
    this.backgroundColor = AppColors.card,
    this.hasBorder = false,
    this.borderColor,
    this.onTap,
    this.width,
    this.height,
  });

  /// Variant with 1px line border and zero shadow
  const BmbCard.bordered({
    super.key,
    required this.child,
    this.padding,
    this.backgroundColor = AppColors.card,
    this.borderColor,
    this.onTap,
    this.width,
    this.height,
  }) : hasBorder = true;

  /// Variant for compact lists (12 vertical padding)
  const BmbCard.compact({
    super.key,
    required this.child,
    this.backgroundColor = AppColors.card,
    this.hasBorder = false,
    this.borderColor,
    this.onTap,
    this.width,
    this.height,
  }) : padding = AppSpacing.cardPaddingRow;

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 768;
    final effectivePadding =
        padding ??
        (isTablet ? AppSpacing.cardPaddingTablet : AppSpacing.cardPaddingPhone);

    // Rule: Either shadow OR 1px border. Never both, never neither.
    final border = hasBorder
        ? Border.all(color: borderColor ?? AppColors.line, width: 1.0)
        : null;
    final shadows = hasBorder ? null : AppShadows.card;

    Widget content = Container(
      width: width,
      height: height,
      padding: effectivePadding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppRadii.cardRadius,
        border: border,
        boxShadow: shadows,
      ),
      child: child,
    );

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        borderRadius: AppRadii.cardRadius,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadii.cardRadius,
          child: content,
        ),
      );
    }

    return content;
  }
}
