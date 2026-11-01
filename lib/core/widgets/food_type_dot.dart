import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum FoodType { veg, nonveg, egg, unknown }

/// Statutory food type marker: 16×16 container with 12px symbol.
/// Strictly enforces no raw colors outside AppColors.
class FoodTypeDot extends StatelessWidget {
  final FoodType type;
  final double size;

  const FoodTypeDot({super.key, required this.type, this.size = 16.0});

  @override
  Widget build(BuildContext context) {
    Color borderColor;
    Widget inner;

    switch (type) {
      case FoodType.veg:
        borderColor = AppColors.leaf;
        inner = Center(
          child: Container(
            width: size * 0.45,
            height: size * 0.45,
            decoration: const BoxDecoration(
              color: AppColors.leaf,
              shape: BoxShape.circle,
            ),
          ),
        );
        break;
      case FoodType.nonveg:
        borderColor = AppColors.chilli;
        inner = Center(
          child: CustomPaint(
            size: Size(size * 0.5, size * 0.5),
            painter: _TrianglePainter(color: AppColors.chilli),
          ),
        );
        break;
      case FoodType.egg:
        borderColor = AppColors.amber;
        inner = Center(
          child: CustomPaint(
            size: Size(size * 0.5, size * 0.5),
            painter: _DiamondPainter(color: AppColors.amber),
          ),
        );
        break;
      case FoodType.unknown:
        borderColor = AppColors.line;
        inner = const SizedBox.shrink();
        break;
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: inner,
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;

  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TrianglePainter oldDelegate) =>
      oldDelegate.color != color;
}

class _DiamondPainter extends CustomPainter {
  final Color color;

  _DiamondPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height / 2)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(0, size.height / 2)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _DiamondPainter oldDelegate) =>
      oldDelegate.color != color;
}
