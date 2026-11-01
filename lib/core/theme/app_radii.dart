import 'package:flutter/material.dart';

/// Corner Radii System Tokens
abstract class AppRadii {
  static const double card = 20.0;
  static const double tile = 18.0;
  static const double button = 16.0;
  static const double input = 14.0;
  static const double icon = 14.0;
  static const double sheet = 28.0; // top corners only
  static const double pill = 999.0;

  // BorderRadius helpers
  static const BorderRadius cardRadius = BorderRadius.all(
    Radius.circular(card),
  );
  static const BorderRadius tileRadius = BorderRadius.all(
    Radius.circular(tile),
  );
  static const BorderRadius buttonRadius = BorderRadius.all(
    Radius.circular(button),
  );
  static const BorderRadius inputRadius = BorderRadius.all(
    Radius.circular(input),
  );
  static const BorderRadius iconRadius = BorderRadius.all(
    Radius.circular(icon),
  );
  static const BorderRadius sheetRadius = BorderRadius.vertical(
    top: Radius.circular(sheet),
  );
  static const BorderRadius dialogRadius = BorderRadius.all(
    Radius.circular(sheet),
  );
  static const BorderRadius pillRadius = BorderRadius.all(
    Radius.circular(pill),
  );

  // Backward compatibility
  static const double buttonLg = 16.0;
  static const double buttonSm = 12.0;
  static const double iconSquircle = 14.0;
  static const BorderRadius buttonLgRadius = BorderRadius.all(
    Radius.circular(button),
  );
  static const BorderRadius buttonSmRadius = BorderRadius.all(
    Radius.circular(12.0),
  );
  static const BorderRadius iconSquircleRadius = BorderRadius.all(
    Radius.circular(icon),
  );
}
