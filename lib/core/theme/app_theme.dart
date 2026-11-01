import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_radii.dart';
import 'spacing.dart';

/// AppTheme configuration for BMB Kitchen
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.interTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.paper,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.tandoor,
        onPrimary: Colors.white,
        secondary: AppColors.ink,
        onSecondary: Colors.white,
        error: AppColors.chilli,
        onError: Colors.white,
        surface: AppColors.card,
        onSurface: AppColors.ink,
      ),
      textTheme: baseTextTheme.apply(
        bodyColor: AppColors.ink,
        displayColor: AppColors.ink,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.line,
        thickness: 1,
        space: 1,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: AppRadii.cardRadius),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadii.dialogRadius),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadii.sheetRadius),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputFill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s16,
          vertical: AppSpacing.s12,
        ),
        hintStyle: const TextStyle(color: AppColors.muted, fontSize: 13.5),
        border: OutlineInputBorder(
          borderRadius: AppRadii.inputRadius,
          borderSide: const BorderSide(color: AppColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadii.inputRadius,
          borderSide: const BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadii.inputRadius,
          borderSide: const BorderSide(color: AppColors.tandoor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadii.inputRadius,
          borderSide: const BorderSide(color: AppColors.chilli),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadii.inputRadius,
          borderSide: const BorderSide(color: AppColors.chilli, width: 1.5),
        ),
      ),
    );
  }
}
