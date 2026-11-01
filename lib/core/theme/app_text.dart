import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Strict Typography System
/// Single typography ramp defined once with Sora (headings/numbers) & Inter (body/UI).
class AppText {
  AppText._();

  static const List<FontFeature> tabularFigures = [
    FontFeature.tabularFigures(),
  ];

  // --- Canonical Ramp (Phase 0 Specification) ---

  /// Grand total, KPI hero value (Sora 28px, 700 weight, 1.15 line-height)
  static final TextStyle displayNum = GoogleFonts.sora(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.15,
    color: AppColors.ink,
    fontFeatures: tabularFigures,
  );

  /// Screen title (Sora 22px, 700 weight, 1.25 line-height)
  static final TextStyle h1 = GoogleFonts.sora(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.25,
    letterSpacing: -0.3,
    color: AppColors.ink,
  );

  /// Section / card title (Sora 18px, 600 weight, 1.3 line-height)
  static final TextStyle h2 = GoogleFonts.sora(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: -0.2,
    color: AppColors.ink,
  );

  /// List item title, table name (Sora 15px, 600 weight, 1.35 line-height)
  static final TextStyle h3 = GoogleFonts.sora(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.35,
    color: AppColors.ink,
  );

  /// Primary body (Inter 15px, 400 weight, 1.45 line-height)
  static final TextStyle bodyLg = GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.45,
    color: AppColors.ink,
  );

  /// Default body (Inter 14px, 400 weight, 1.45 line-height)
  static final TextStyle body = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.45,
    color: AppColors.ink,
  );

  /// Values in label/value rows (Inter 14px, 600 weight, 1.45 line-height)
  static final TextStyle bodyStrong = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.45,
    color: AppColors.ink,
  );

  /// Field labels, secondary text (Inter 13px, 500 weight, 1.35 line-height)
  static final TextStyle label = GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.35,
    color: AppColors.muted,
  );

  /// Meta, timestamps, helper text (Inter 12px, 500 weight, 1.3 line-height)
  static final TextStyle caption = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.3,
    color: AppColors.muted,
  );

  /// Uppercase section eyebrows (Inter 11px, 600 weight, 1.2 line-height, +0.4 letterSpacing)
  static final TextStyle overline = GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 0.4,
    color: AppColors.muted,
  );

  /// Any money or count value with tabular figures (Sora 14px, 600 weight, 1.3 line-height)
  static final TextStyle numeric = GoogleFonts.sora(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: AppColors.ink,
    fontFeatures: tabularFigures,
  );

  // --- Aliases for Seamless Backward Compatibility ---
  static TextStyle get kpiVal => displayNum;
  static TextStyle get grandTotal =>
      displayNum.copyWith(color: AppColors.tandoorDark);
  static TextStyle get priceBold =>
      numeric.copyWith(fontSize: 15, fontWeight: FontWeight.w700);
  static TextStyle get numLg => displayNum.copyWith(fontSize: 18);
  static TextStyle get numMd => numeric;
  static TextStyle get numSm =>
      numeric.copyWith(fontSize: 12, fontWeight: FontWeight.w500);
  static TextStyle get subtitle => label;
  static TextStyle get sectionLabel => overline;
  static TextStyle get button => bodyStrong;
  static TextStyle get buttonLg => bodyStrong.copyWith(fontSize: 15);
  static TextStyle get tag => caption.copyWith(fontWeight: FontWeight.w600);
  static TextStyle get bodyMedium =>
      bodyStrong.copyWith(fontWeight: FontWeight.w500);
  static TextStyle get bodyBold => bodyStrong;
}
