import 'package:flutter/material.dart';

/// Strict 4pt Spacing Scale Tokens
abstract class Gap {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
  static const xxxl = 32.0;
}

/// BMB Kitchen Layout Spacing & Edge Alignment System
/// Strictly enforces the 4pt grid and single left-edge alignment.
class AppSpacing {
  AppSpacing._();

  // Backward-compatible raw constants
  static const double s4 = Gap.xs;
  static const double s8 = Gap.sm;
  static const double s12 = Gap.md;
  static const double s16 = Gap.lg;
  static const double s20 = Gap.xl;
  static const double s24 = Gap.xxl;
  static const double s32 = Gap.xxxl;

  // Screen horizontal margins (16 on phone, 24 on tablet)
  static const double screenPadPhone = Gap.lg; // 16.0
  static const double screenPadTablet = Gap.xxl; // 24.0

  // Card gaps and section spacing
  static const double cardGap = Gap.md; // 12.0
  static const double sectionGap = Gap.xxl; // 24.0

  // Card internal padding (16 on phone, 20 on tablet, 12 vertical for compact list rows)
  static const double cardPadPhone = Gap.lg; // 16.0
  static const double cardPadTablet = Gap.xl; // 20.0
  static const double cardPadRowVertical = Gap.md; // 12.0

  /// Returns responsive horizontal screen padding (16 on phone, 24 on tablet)
  static double horizontalPadding(BuildContext context) {
    return MediaQuery.of(context).size.width >= 768
        ? screenPadTablet
        : screenPadPhone;
  }

  /// Single left-edge screen padding
  static EdgeInsets screen(BuildContext context) {
    final h = horizontalPadding(context);
    return EdgeInsets.symmetric(horizontal: h, vertical: Gap.lg);
  }

  // Pre-built EdgeInsets constants
  static const EdgeInsets all4 = EdgeInsets.all(Gap.xs);
  static const EdgeInsets all8 = EdgeInsets.all(Gap.sm);
  static const EdgeInsets all12 = EdgeInsets.all(Gap.md);
  static const EdgeInsets all16 = EdgeInsets.all(Gap.lg);
  static const EdgeInsets all20 = EdgeInsets.all(Gap.xl);
  static const EdgeInsets all24 = EdgeInsets.all(Gap.xxl);
  static const EdgeInsets all32 = EdgeInsets.all(Gap.xxxl);

  static const EdgeInsets cardPaddingPhone = EdgeInsets.all(Gap.lg);
  static const EdgeInsets cardPaddingTablet = EdgeInsets.all(Gap.xl);
  static const EdgeInsets cardPaddingRow = EdgeInsets.symmetric(
    horizontal: Gap.lg,
    vertical: Gap.md,
  );

  // Vertical SizedBox gaps (CamelCase)
  static const SizedBox gapHXs = SizedBox(height: Gap.xs);
  static const SizedBox gapHSm = SizedBox(height: Gap.sm);
  static const SizedBox gapHMd = SizedBox(height: Gap.md);
  static const SizedBox gapHLg = SizedBox(height: Gap.lg);
  static const SizedBox gapHXl = SizedBox(height: Gap.xl);
  static const SizedBox gapHXxl = SizedBox(height: Gap.xxl);
  static const SizedBox gapHXxxl = SizedBox(height: Gap.xxxl);

  // Horizontal SizedBox gaps (CamelCase)
  static const SizedBox gapWXs = SizedBox(width: Gap.xs);
  static const SizedBox gapWSm = SizedBox(width: Gap.sm);
  static const SizedBox gapWMd = SizedBox(width: Gap.md);
  static const SizedBox gapWLg = SizedBox(width: Gap.lg);
  static const SizedBox gapWXl = SizedBox(width: Gap.xl);
  static const SizedBox gapWXxl = SizedBox(width: Gap.xxl);
  static const SizedBox gapWXxxl = SizedBox(width: Gap.xxxl);

  // Compatibility aliases for existing code
  static const SizedBox gapH2 = SizedBox(height: Gap.xs);
  static const SizedBox gapH4 = SizedBox(height: Gap.xs);
  static const SizedBox gapH8 = SizedBox(height: Gap.sm);
  static const SizedBox gapH12 = SizedBox(height: Gap.md);
  static const SizedBox gapH16 = SizedBox(height: Gap.lg);
  static const SizedBox gapH20 = SizedBox(height: Gap.xl);
  static const SizedBox gapH24 = SizedBox(height: Gap.xxl);
  static const SizedBox gapH32 = SizedBox(height: Gap.xxxl);

  static const SizedBox gapW4 = SizedBox(width: Gap.xs);
  static const SizedBox gapW6 = SizedBox(width: Gap.sm);
  static const SizedBox gapW8 = SizedBox(width: Gap.sm);
  static const SizedBox gapW10 = SizedBox(width: Gap.md);
  static const SizedBox gapW12 = SizedBox(width: Gap.md);
  static const SizedBox gapW16 = SizedBox(width: Gap.lg);
  static const SizedBox gapW20 = SizedBox(width: Gap.xl);
  static const SizedBox gapW24 = SizedBox(width: Gap.xxl);
  static const SizedBox gapW32 = SizedBox(width: Gap.xxxl);

  static const EdgeInsets cardPadding = EdgeInsets.all(Gap.xl);
  static const EdgeInsets cardPaddingCompact = EdgeInsets.all(Gap.lg);
  static const EdgeInsets dialogPadding = EdgeInsets.all(Gap.xxl);
  static const EdgeInsets screenPaddingPhone = EdgeInsets.symmetric(
    horizontal: Gap.lg,
    vertical: Gap.lg,
  );
  static const EdgeInsets screenPaddingTablet = EdgeInsets.symmetric(
    horizontal: Gap.xxl,
    vertical: Gap.xl,
  );
}
