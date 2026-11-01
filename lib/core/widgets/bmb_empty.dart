import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/spacing.dart';
import 'bmb_button.dart';
import 'bmb_card.dart';

/// Empty state widget requiring a title, single line of guidance, and optional primary action.
class BmbEmpty extends StatelessWidget {
  final Widget? icon;
  final String? emoji;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool asCard;

  const BmbEmpty({
    super.key,
    this.icon,
    this.emoji,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
    this.asCard = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s24,
        vertical: AppSpacing.s32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null)
            icon!
          else if (emoji != null)
            Text(emoji!, style: const TextStyle(fontSize: 40))
          else
            const Text('🍳', style: TextStyle(fontSize: 40)),
          AppSpacing.gapH16,
          Text(
            title,
            style: AppText.h3.copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          AppSpacing.gapH8,
          Text(
            description,
            style: AppText.subtitle.copyWith(color: AppColors.muted),
            textAlign: TextAlign.center,
          ),
          if (actionLabel != null && onAction != null) ...[
            AppSpacing.gapH20,
            BmbButton.primary(
              label: actionLabel!,
              onPressed: onAction,
              size: BmbButtonSize.md,
            ),
          ],
        ],
      ),
    );

    if (asCard) {
      return Center(
        child: BmbCard(
          padding: EdgeInsets.zero,
          child: SizedBox(width: double.infinity, child: content),
        ),
      );
    }

    return Center(child: content);
  }
}
