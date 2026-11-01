import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_text.dart';
import '../theme/spacing.dart';

class BmbTabItem {
  final String key;
  final String label;
  final int? count;
  final Color? countBadgeColor;

  const BmbTabItem({
    required this.key,
    required this.label,
    this.count,
    this.countBadgeColor,
  });
}

/// Horizontal scrolling pill tabs matching prototype .tabs
class BmbTabs extends StatelessWidget {
  final List<BmbTabItem> tabs;
  final String selectedKey;
  final ValueChanged<String> onTabSelected;

  const BmbTabs({
    super.key,
    required this.tabs,
    required this.selectedKey,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tabs.map((tab) {
          final isSelected = tab.key == selectedKey;

          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.s8),
            child: InkWell(
              onTap: () => onTabSelected(tab.key),
              borderRadius: AppRadii.pillRadius,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.ink : AppColors.card,
                  borderRadius: AppRadii.pillRadius,
                  border: Border.all(
                    color: isSelected ? AppColors.ink : AppColors.line,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      tab.label,
                      style: AppText.button.copyWith(
                        fontSize: 13,
                        color: isSelected ? Colors.white : AppColors.ink,
                      ),
                    ),
                    if (tab.count != null && tab.count! > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color:
                              tab.countBadgeColor ??
                              (isSelected
                                  ? AppColors.tandoor
                                  : AppColors.tandoorSoft),
                          borderRadius: AppRadii.pillRadius,
                        ),
                        child: Text(
                          '${tab.count}',
                          style: AppText.caption.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? Colors.white
                                : AppColors.tandoor,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
