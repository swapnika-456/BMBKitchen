import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_text.dart';
import '../theme/spacing.dart';

/// Reusable responsive screen header built to deliver a modern, premium title arrangement:
/// - Screen title is clean, bold and never truncated.
/// - Automatically formats and cleans internal wireframe numbering (e.g. " (18)") for a polished consumer feel.
/// - Subtitle sits comfortably beneath the title in muted typography.
/// - Trailing actions adapt responsively using a fluid Wrap to prevent alignment gaps or mobile overflow.
class BmbScreenHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? iconBg;
  final Color? iconColor;
  final Widget? trailing;

  const BmbScreenHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.iconBg,
    this.iconColor,
    this.trailing,
  });

  /// Cleans any trailing internal module number like " (18)" or " (21)" for elegant presentation.
  String get _displayTitle {
    final clean = title.replaceAll(RegExp(r'\s*\(\d+\)$'), '').trim();
    return clean.isNotEmpty ? clean : title;
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 680;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.horizontalPadding(context),
        vertical: Gap.md,
      ),
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: isWide ? _buildWideLayout(context) : _buildNarrowLayout(context),
    );
  }

  Widget _buildWideLayout(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: iconBg ?? AppColors.tandoorSoft,
                    borderRadius: BorderRadius.circular(AppRadii.icon),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor ?? AppColors.tandoor,
                    size: 20,
                  ),
                ),
                AppSpacing.gapWMd,
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _displayTitle,
                      style: AppText.h2.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.visible,
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle!,
                        style: AppText.caption.copyWith(
                          color: AppColors.muted,
                          fontSize: 12.5,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.visible,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[
          AppSpacing.gapWMd,
          Flexible(fit: FlexFit.loose, child: trailing!),
        ],
      ],
    );
  }

  Widget _buildNarrowLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: iconBg ?? AppColors.tandoorSoft,
                  borderRadius: BorderRadius.circular(AppRadii.icon),
                ),
                child: Icon(
                  icon,
                  color: iconColor ?? AppColors.tandoor,
                  size: 18,
                ),
              ),
              AppSpacing.gapWSm,
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _displayTitle,
                    style: AppText.h3.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.visible,
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: AppText.caption.copyWith(
                        color: AppColors.muted,
                        fontSize: 12,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.visible,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        if (trailing != null) ...[
          AppSpacing.gapHMd,
          Container(alignment: Alignment.centerLeft, child: trailing!),
        ],
      ],
    );
  }
}
