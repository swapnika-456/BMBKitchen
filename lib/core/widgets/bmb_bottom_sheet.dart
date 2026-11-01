import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_text.dart';
import '../theme/spacing.dart';

/// Responsive modal helper:
/// Opens as a bottom sheet with 28px top radii on phones,
/// or as a centered dialog with 28px radii on tablets.
Future<T?> showBmbModal<T>({
  required BuildContext context,
  required Widget child,
  String? title,
  bool isDismissible = true,
  double? maxWidth,
}) {
  final isTablet = MediaQuery.sizeOf(context).width >= 600;

  if (isTablet) {
    return showDialog<T>(
      context: context,
      barrierDismissible: isDismissible,
      builder: (dialogContext) => Dialog(
        backgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadii.dialogRadius,
        ),
        child: Container(
          width: maxWidth ?? 480,
          padding: AppSpacing.all24,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (title != null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(title, style: AppText.h3)),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.muted),
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      tooltip: 'Close',
                    ),
                  ],
                ),
                const Divider(color: AppColors.line),
                AppSpacing.gapH16,
              ],
              Flexible(child: SingleChildScrollView(child: child)),
            ],
          ),
        ),
      ),
    );
  }

  return showModalBottomSheet<T>(
    context: context,
    isDismissible: isDismissible,
    isScrollControlled: true,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(borderRadius: AppRadii.sheetRadius),
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
      ),
      child: SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight:
                MediaQuery.of(context).size.height * 0.85, // prevent overflow
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s20,
              vertical: AppSpacing.s16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: AppSpacing.s12),
                    decoration: BoxDecoration(
                      color: AppColors.line,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                if (title != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(title, style: AppText.h3)),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppColors.muted),
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        tooltip: 'Close',
                      ),
                    ],
                  ),
                  const Divider(color: AppColors.line),
                  AppSpacing.gapH12,
                ],
                Flexible(child: SingleChildScrollView(child: child)),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
