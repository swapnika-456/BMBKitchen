import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_text.dart';
import '../theme/spacing.dart';

enum BmbButtonVariant { primary, outline, green, danger, ghost }

enum BmbButtonSize { sm, md, lg }

/// Touch-first button with min 48px touch target, haptic feedback,
/// and smooth 0.97 scale-down press animation.
class BmbButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final BmbButtonVariant variant;
  final BmbButtonSize size;
  final Widget? icon;
  final bool isLoading;
  final bool expanded;

  const BmbButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = BmbButtonVariant.primary,
    this.size = BmbButtonSize.md,
    this.icon,
    this.isLoading = false,
    this.expanded = false,
  });

  const BmbButton.primary({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = BmbButtonSize.md,
    this.icon,
    this.isLoading = false,
    this.expanded = false,
  }) : variant = BmbButtonVariant.primary;

  const BmbButton.outline({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = BmbButtonSize.md,
    this.icon,
    this.isLoading = false,
    this.expanded = false,
  }) : variant = BmbButtonVariant.outline;

  const BmbButton.green({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = BmbButtonSize.md,
    this.icon,
    this.isLoading = false,
    this.expanded = false,
  }) : variant = BmbButtonVariant.green;

  const BmbButton.danger({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = BmbButtonSize.md,
    this.icon,
    this.isLoading = false,
    this.expanded = false,
  }) : variant = BmbButtonVariant.danger;

  const BmbButton.ghost({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = BmbButtonSize.md,
    this.icon,
    this.isLoading = false,
    this.expanded = false,
  }) : variant = BmbButtonVariant.ghost;

  @override
  State<BmbButton> createState() => _BmbButtonState();
}

class _BmbButtonState extends State<BmbButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.97,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.reverse();
    }
  }

  void _onTapCancel() {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null && !widget.isLoading;

    Color bg;
    Color fg;
    Border? border;

    switch (widget.variant) {
      case BmbButtonVariant.primary:
        bg = isEnabled ? AppColors.tandoor : AppColors.tandoorSoft;
        fg = isEnabled ? Colors.white : AppColors.muted;
        break;
      case BmbButtonVariant.outline:
        bg = AppColors.card;
        fg = isEnabled ? AppColors.ink : AppColors.muted;
        border = Border.all(color: isEnabled ? AppColors.line : AppColors.line);
        break;
      case BmbButtonVariant.green:
        bg = isEnabled ? AppColors.leaf : AppColors.leafSoft;
        fg = isEnabled ? Colors.white : AppColors.muted;
        break;
      case BmbButtonVariant.danger:
        bg = isEnabled ? AppColors.chilliSoft : AppColors.paper;
        fg = isEnabled ? AppColors.chilli : AppColors.muted;
        border = Border.all(
          color: isEnabled ? AppColors.chilli : AppColors.line,
        );
        break;
      case BmbButtonVariant.ghost:
        bg = Colors.transparent;
        fg = isEnabled ? AppColors.muted : AppColors.line;
        break;
    }

    double minHeight;
    EdgeInsets padding;
    TextStyle textStyle;

    switch (widget.size) {
      case BmbButtonSize.sm:
        minHeight = 40.0;
        padding = const EdgeInsets.symmetric(
          horizontal: Gap.md,
          vertical: Gap.sm,
        );
        textStyle = AppText.caption.copyWith(
          color: fg,
          fontWeight: FontWeight.w600,
        );
        break;
      case BmbButtonSize.md:
        minHeight = 48.0;
        padding = const EdgeInsets.symmetric(
          horizontal: Gap.lg,
          vertical: Gap.md,
        );
        textStyle = AppText.bodyStrong.copyWith(color: fg);
        break;
      case BmbButtonSize.lg:
        minHeight = 56.0;
        padding = const EdgeInsets.symmetric(
          horizontal: Gap.xl,
          vertical: Gap.lg,
        );
        textStyle = AppText.bodyStrong.copyWith(color: fg, fontSize: 15);
        break;
    }

    Widget content = Row(
      mainAxisSize: widget.expanded ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.isLoading)
          Padding(
            padding: const EdgeInsets.only(right: Gap.sm),
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(fg),
              ),
            ),
          )
        else if (widget.icon != null) ...[
          widget.icon!,
          AppSpacing.gapWSm,
        ],
        Flexible(
          child: Text(
            widget.label,
            style: textStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    Widget button = GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: isEnabled
          ? () {
              HapticFeedback.selectionClick();
              widget.onPressed?.call();
            }
          : null,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            constraints: BoxConstraints(minHeight: minHeight),
            padding: padding,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: AppRadii.buttonRadius,
              border: border,
              boxShadow:
                  (widget.variant == BmbButtonVariant.primary && isEnabled)
                  ? [
                      BoxShadow(
                        color: AppColors.tandoor.withValues(alpha: 0.20),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: child,
          ),
        ),
        child: content,
      ),
    );

    if (widget.expanded) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
}

/// Canonical Primary Button (tandoor brand, 48px or 56px height)
class BmbPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool isLoading;
  final bool expanded;
  final bool isLarge; // 56px for POS primary actions

  const BmbPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.expanded = false,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    return BmbButton(
      label: label,
      onPressed: onPressed,
      variant: BmbButtonVariant.primary,
      size: isLarge ? BmbButtonSize.lg : BmbButtonSize.md,
      icon: icon,
      isLoading: isLoading,
      expanded: expanded,
    );
  }
}

/// Canonical Secondary Button (outline with line border, ink text, 48px height)
class BmbSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool isLoading;
  final bool expanded;

  const BmbSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.expanded = false,
  });

  @override
  Widget build(BuildContext context) {
    return BmbButton(
      label: label,
      onPressed: onPressed,
      variant: BmbButtonVariant.outline,
      size: BmbButtonSize.md,
      icon: icon,
      isLoading: isLoading,
      expanded: expanded,
    );
  }
}

/// Canonical Text Button (borderless ghost button)
class BmbTextButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final Color? color;

  const BmbTextButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return BmbButton(
      label: label,
      onPressed: onPressed,
      variant: BmbButtonVariant.ghost,
      size: BmbButtonSize.sm,
      icon: icon,
    );
  }
}
