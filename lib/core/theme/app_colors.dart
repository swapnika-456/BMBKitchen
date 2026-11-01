import 'package:flutter/material.dart';

/// BMB Kitchen Color Tokens
/// Preserves exact prototype palette with soft tints for friendly touch surfaces.
class AppColors {
  AppColors._();

  // Core neutrals
  static const Color ink = Color(0xFF1F1B16); // primary text
  static const Color paper = Color(0xFFF7F4EF); // app canvas background
  static const Color card = Color(0xFFFFFFFF); // card surface
  static const Color line = Color(0xFFE7E1D8); // borders / dividers
  static const Color muted = Color(0xFF7A7266); // secondary text

  // Brand / Action
  static const Color tandoor = Color(0xFFD9480F); // brand / primary action
  static const Color tandoorDark = Color(0xFFB93A08); // pressed / active state
  static const Color tandoorSoft = Color(0xFFFDEDE4); // soft tinted background

  // Orange Gradients (Modern energetic fiery orange gradient)
  static const LinearGradient orangeGradient = LinearGradient(
    colors: [Color(0xFFE8590C), Color(0xFFFF922B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient orangeGradientVertical = LinearGradient(
    colors: [Color(0xFFE8590C), Color(0xFFFF922B)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient orangeGradientSoft = LinearGradient(
    colors: [Color(0xFFFDEDE4), Color(0xFFFFF4EE)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Functional semantic colors & tints
  static const Color leaf = Color(0xFF2B8A3E); // success / veg marker
  static const Color leafSoft = Color(0xFFE6F4EA);

  static const Color chilli = Color(
    0xFFC92A2A,
  ); // destructive / non-veg / late KOT
  static const Color chilliSoft = Color(0xFFFDECEC);

  static const Color amber = Color(
    0xFFE8A013,
  ); // warning / delayed KOT / egg marker
  static const Color amberSoft = Color(0xFFFBF3DE);

  static const Color blue = Color(0xFF1971C2); // info / reserved table
  static const Color blueSoft = Color(0xFFE7F1FA);

  static const Color plum = Color(0xFF6741D9); // special / online order
  static const Color plumSoft = Color(0xFFEFEAFB);

  // Structural accents
  static const Color inputFill = Color(0xFFFBFAF7);
  static const Color badgeGrey = Color(0xFFEFEAE2);
  static const Color dividerLight = Color(0xFFF3EFE8);
}
