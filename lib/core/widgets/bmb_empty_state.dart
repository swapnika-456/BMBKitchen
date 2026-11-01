import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_text.dart';
import '../theme/spacing.dart';
import 'bmb_button.dart';

/// Actionable Empty State widget adhering strictly to Phase 3 requirements.
/// Centered 40px icon, h2 title, caption guidance, and optional primary action.
class BmbEmptyState extends StatelessWidget {
  final Widget? icon;
  final String? emoji;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;

  const BmbEmptyState({
    super.key,
    this.icon,
    this.emoji,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Gap.xxl,
          vertical: Gap.xxxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.paper,
                borderRadius: BorderRadius.circular(AppRadii.icon),
                border: Border.all(color: AppColors.line),
              ),
              child:
                  icon ??
                  Text(emoji ?? '🍳', style: const TextStyle(fontSize: 28)),
            ),
            AppSpacing.gapHLg,
            Text(
              title,
              style: AppText.h2.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            AppSpacing.gapHSm,
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Text(
                description,
                style: AppText.caption.copyWith(color: AppColors.muted),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              AppSpacing.gapHXl,
              BmbPrimaryButton(label: actionLabel!, onPressed: onAction),
            ],
          ],
        ),
      ),
    );
  }
}
