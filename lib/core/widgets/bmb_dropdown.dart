import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_text.dart';
import '../theme/spacing.dart';

/// Standardized Dropdown Field matching BmbTextField form controls.
class BmbDropdown<T> extends StatelessWidget {
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? label;
  final String? hint;
  final Widget? prefixIcon;

  const BmbDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.label,
    this.hint,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    Widget dropdown = Container(
      height: 48.0,
      padding: const EdgeInsets.symmetric(horizontal: Gap.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadii.input),
        border: Border.all(color: AppColors.line, width: 1.0),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down,
            size: 20,
            color: AppColors.muted,
          ),
          hint: hint != null
              ? Text(
                  hint!,
                  style: AppText.label.copyWith(color: AppColors.muted),
                )
              : null,
          style: AppText.body,
          dropdownColor: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadii.input),
        ),
      ),
    );

    if (label != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label!, style: AppText.label),
          AppSpacing.gapHXs,
          dropdown,
        ],
      );
    }

    return dropdown;
  }
}
