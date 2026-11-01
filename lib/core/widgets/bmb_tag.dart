import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_text.dart';

enum BmbTagVariant { green, red, amber, blue, orange, plum, grey }

/// Fully-rounded (99px) status pill / badge matching prototype .tag classes
class BmbTag extends StatelessWidget {
  final String label;
  final BmbTagVariant variant;
  final Widget? icon;
  final VoidCallback? onTap;

  const BmbTag({
    super.key,
    required this.label,
    this.variant = BmbTagVariant.grey,
    this.icon,
    this.onTap,
  });

  const BmbTag.green(this.label, {super.key, this.icon, this.onTap})
    : variant = BmbTagVariant.green;

  const BmbTag.red(this.label, {super.key, this.icon, this.onTap})
    : variant = BmbTagVariant.red;

  const BmbTag.amber(this.label, {super.key, this.icon, this.onTap})
    : variant = BmbTagVariant.amber;

  const BmbTag.blue(this.label, {super.key, this.icon, this.onTap})
    : variant = BmbTagVariant.blue;

  const BmbTag.orange(this.label, {super.key, this.icon, this.onTap})
    : variant = BmbTagVariant.orange;

  const BmbTag.plum(this.label, {super.key, this.icon, this.onTap})
    : variant = BmbTagVariant.plum;

  const BmbTag.grey(this.label, {super.key, this.icon, this.onTap})
    : variant = BmbTagVariant.grey;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;

    switch (variant) {
      case BmbTagVariant.green:
        bg = AppColors.leafSoft;
        fg = AppColors.leaf;
        break;
      case BmbTagVariant.red:
        bg = AppColors.chilliSoft;
        fg = AppColors.chilli;
        break;
      case BmbTagVariant.amber:
        bg = AppColors.amberSoft;
        fg = const Color(0xFF96650B);
        break;
      case BmbTagVariant.blue:
        bg = AppColors.blueSoft;
        fg = AppColors.blue;
        break;
      case BmbTagVariant.orange:
        bg = AppColors.tandoorSoft;
        fg = AppColors.tandoor;
        break;
      case BmbTagVariant.plum:
        bg = AppColors.plumSoft;
        fg = AppColors.plum;
        break;
      case BmbTagVariant.grey:
        bg = AppColors.badgeGrey;
        fg = AppColors.muted;
        break;
    }

    Widget pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
      decoration: BoxDecoration(color: bg, borderRadius: AppRadii.pillRadius),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[icon!, const SizedBox(width: 4)],
          Flexible(
            child: Text(
              label,
              style: AppText.tag.copyWith(color: fg),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: AppRadii.pillRadius,
        child: pill,
      );
    }
    return pill;
  }
}
