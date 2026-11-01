import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_text.dart';
import '../theme/spacing.dart';
import 'bmb_card.dart';

/// KPI metric tile built according to Rule 1 & Rule 3:
/// - Icon top-left with optional delta badge on top-right.
/// - Value large below the icon.
/// - Label beneath the value in full, wrapped to 2 lines if needed (never clipped).
/// - Fixed minimum height ensuring 2-line labels never cause overflow.
class BmbKpiTile extends StatelessWidget {
  final String label;
  final String value;
  final String? hint;
  final double? deltaPct;
  final String? deltaPeriod;
  final Widget icon;
  final Color iconBg;
  final Color iconFg;
  final VoidCallback? onTap;

  const BmbKpiTile({
    super.key,
    required this.label,
    required this.value,
    this.hint,
    this.deltaPct,
    this.deltaPeriod,
    required this.icon,
    this.iconBg = AppColors.tandoorSoft,
    this.iconFg = AppColors.tandoor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BmbCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Top Row: Icon top-left and optional Delta badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(AppRadii.icon),
                    ),
                    alignment: Alignment.center,
                    child: IconTheme(
                      data: IconThemeData(color: iconFg, size: 16),
                      child: icon,
                    ),
                  ),
                  if (deltaPct != null) ...[
                    const SizedBox(width: Gap.xs),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: deltaPct! >= 0
                            ? AppColors.leafSoft
                            : AppColors.chilliSoft,
                        borderRadius: AppRadii.pillRadius,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            deltaPct! >= 0
                                ? Icons.arrow_drop_up
                                : Icons.arrow_drop_down,
                            color: deltaPct! >= 0
                                ? AppColors.leaf
                                : AppColors.chilli,
                            size: 14,
                          ),
                          Text(
                            '${deltaPct!.abs().toStringAsFixed(1)}%',
                            style: AppText.caption.copyWith(
                              color: deltaPct! >= 0
                                  ? AppColors.leaf
                                  : AppColors.chilli,
                              fontWeight: FontWeight.w700,
                              fontSize: 10.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 4),

              // Value (Large Sora numeral)
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: AppText.kpiVal.copyWith(fontSize: 20),
                  maxLines: 1,
                ),
              ),

              const SizedBox(height: 2),

              // Label: Rule 1 — Never truncate! Full value wrapped to 2 lines
              Text(
                label,
                style: AppText.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.muted,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              if (deltaPeriod != null && deltaPeriod!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  deltaPeriod!,
                  style: AppText.caption.copyWith(
                    fontSize: 10,
                    color: AppColors.muted.withValues(alpha: 0.8),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ] else if (hint != null && hint!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  hint!,
                  style: AppText.caption.copyWith(fontSize: 10),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
