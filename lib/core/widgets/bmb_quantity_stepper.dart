import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_text.dart';

/// Touch-friendly quantity stepper with tabular numeric display.
class BmbQuantityStepper extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;
  final bool isCompact;

  const BmbQuantityStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 1,
    this.max = 99,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final btnSize = isCompact ? 32.0 : 40.0;
    final iconSize = isCompact ? 16.0 : 18.0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(AppRadii.button),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Decrement
          InkWell(
            onTap: value > min ? () => onChanged(value - 1) : null,
            borderRadius: BorderRadius.horizontal(
              left: Radius.circular(AppRadii.button - 1),
            ),
            child: SizedBox(
              width: btnSize,
              height: btnSize,
              child: Icon(
                Icons.remove,
                size: iconSize,
                color: value > min ? AppColors.ink : AppColors.muted,
              ),
            ),
          ),

          // Value
          Container(
            constraints: BoxConstraints(minWidth: isCompact ? 28 : 36),
            alignment: Alignment.center,
            child: Text(
              value.toString(),
              style: AppText.numeric.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
          ),

          // Increment
          InkWell(
            onTap: value < max ? () => onChanged(value + 1) : null,
            borderRadius: BorderRadius.horizontal(
              right: Radius.circular(AppRadii.button - 1),
            ),
            child: SizedBox(
              width: btnSize,
              height: btnSize,
              child: Icon(
                Icons.add,
                size: iconSize,
                color: value < max ? AppColors.tandoor : AppColors.muted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
