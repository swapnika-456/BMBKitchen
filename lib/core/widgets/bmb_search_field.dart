import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_text.dart';
import '../theme/spacing.dart';

/// Standardized Search Field with constrained height, clear button, and input radius.
class BmbSearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final String hintText;
  final bool autofocus;

  const BmbSearchField({
    super.key,
    required this.controller,
    this.onChanged,
    this.onClear,
    this.hintText = 'Search...',
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final hasText = value.text.isNotEmpty;

        return TextField(
          controller: controller,
          autofocus: autofocus,
          onChanged: onChanged,
          style: AppText.body,
          decoration: InputDecoration(
            isDense: true,
            hintText: hintText,
            hintStyle: AppText.label.copyWith(color: AppColors.muted),
            prefixIcon: const Padding(
              padding: EdgeInsets.symmetric(horizontal: Gap.md),
              child: Icon(Icons.search, size: 20, color: AppColors.muted),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 40,
              minHeight: 40,
            ),
            suffixIcon: hasText
                ? IconButton(
                    icon: const Icon(
                      Icons.clear,
                      size: 18,
                      color: AppColors.muted,
                    ),
                    onPressed: () {
                      controller.clear();
                      onChanged?.call('');
                      onClear?.call();
                    },
                  )
                : null,
            suffixIconConstraints: const BoxConstraints(
              minWidth: 40,
              minHeight: 40,
            ),
            filled: true,
            fillColor: AppColors.card,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: Gap.lg,
              vertical: Gap.md,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.input),
              borderSide: const BorderSide(color: AppColors.line, width: 1.0),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.input),
              borderSide: const BorderSide(color: AppColors.line, width: 1.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.input),
              borderSide: const BorderSide(
                color: AppColors.tandoor,
                width: 1.5,
              ),
            ),
          ),
        );
      },
    );
  }
}
