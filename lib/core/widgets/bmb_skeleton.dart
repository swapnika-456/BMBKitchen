import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/spacing.dart';

/// Shimmer skeleton loader for realistic reviewable loading states
class BmbSkeleton extends StatefulWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const BmbSkeleton({super.key, this.width, this.height, this.borderRadius});

  const BmbSkeleton.box({
    super.key,
    required double this.width,
    required double this.height,
    double radius = AppRadii.input,
  }) : borderRadius = const BorderRadius.all(Radius.circular(AppRadii.input));

  const BmbSkeleton.card({super.key, this.width, this.height = 120.0})
    : borderRadius = AppRadii.cardRadius;

  @override
  State<BmbSkeleton> createState() => _BmbSkeletonState();
}

class _BmbSkeletonState extends State<BmbSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _animation = Tween<double>(
      begin: 0.35,
      end: 0.85,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: AppColors.line.withValues(alpha: _animation.value),
          borderRadius: widget.borderRadius ?? AppRadii.cardRadius,
        ),
      ),
    );
  }
}

/// Helper to render a multi-card loading shimmer list
class BmbSkeletonList extends StatelessWidget {
  final int count;
  final double itemHeight;

  const BmbSkeletonList({super.key, this.count = 4, this.itemHeight = 90.0});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      separatorBuilder: (context, index) => AppSpacing.gapH12,
      itemBuilder: (context, index) => BmbSkeleton.card(height: itemHeight),
    );
  }
}
