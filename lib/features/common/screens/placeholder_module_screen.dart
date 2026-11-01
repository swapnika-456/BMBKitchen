import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/widgets/bmb_button.dart';
import '../../../core/widgets/bmb_card.dart';
import '../../../core/widgets/bmb_tag.dart';

class PlaceholderModuleScreen extends StatelessWidget {
  final String title;
  final String description;
  final String phase; // "Phase 1", "Phase 2", "Phase 3"
  final IconData icon;

  const PlaceholderModuleScreen({
    super.key,
    required this.title,
    required this.description,
    this.phase = 'Phase 2',
    this.icon = Icons.construction_outlined,
  });

  @override
  Widget build(BuildContext context) {
    final isPhase1 = phase == 'Phase 1';
    final tagVariant = isPhase1
        ? BmbTagVariant.orange
        : phase == 'Phase 2'
        ? BmbTagVariant.blue
        : BmbTagVariant.plum;

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        child: BmbCard(
          padding: const EdgeInsets.all(AppSpacing.s32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.tandoorSoft,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, size: 32, color: AppColors.tandoor),
              ),
              AppSpacing.gapH20,
              BmbTag(label: phase.toUpperCase(), variant: tagVariant),
              AppSpacing.gapH12,
              Text(title, style: AppText.h2, textAlign: TextAlign.center),
              AppSpacing.gapH8,
              Text(
                description,
                style: AppText.subtitle.copyWith(color: AppColors.muted),
                textAlign: TextAlign.center,
              ),
              AppSpacing.gapH24,
              const Divider(),
              AppSpacing.gapH16,
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  BmbButton.outline(
                    label: 'Return to Dashboard',
                    onPressed: () => context.go('/dashboard'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
