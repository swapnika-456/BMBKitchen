import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/spacing.dart';

/// Standardized Section Header with consistent left alignment and vertical rhythm.
/// Rule 1: Section headers must never be truncated.
class BmbSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? count;
  final Widget? trailing;
  final bool isOverline;

  const BmbSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.count,
    this.trailing,
    this.isOverline = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Gap.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        isOverline ? title.toUpperCase() : title,
                        style: isOverline ? AppText.overline : AppText.h2,
                        maxLines: 2,
                        overflow: TextOverflow.visible,
                      ),
                    ),
                    if (count != null) ...[
                      AppSpacing.gapWSm,
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Gap.sm,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.paper,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: AppColors.line),
                        ),
                        child: Text(
                          count!,
                          style: AppText.caption.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  AppSpacing.gapHXs,
                  Text(
                    subtitle!,
                    style: AppText.caption,
                    maxLines: 2,
                    overflow: TextOverflow.visible,
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[AppSpacing.gapWMd, trailing!],
        ],
      ),
    );
  }
}
