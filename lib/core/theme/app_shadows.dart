import 'package:flutter/material.dart';

/// Single Canonical Shadow System
/// Surface gets EITHER a shadow OR a 1px line border — never both, never neither.
abstract class AppShadows {
  /// Canonical soft 2-layer card shadow: 0 1px 2px rgba(31,27,22,.04) + 0 8px 24px rgba(31,27,22,.06)
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color.fromRGBO(31, 27, 22, 0.04),
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
    BoxShadow(
      color: Color.fromRGBO(31, 27, 22, 0.06),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];

  /// Modal / Bottom sheet elevation shadow
  static const List<BoxShadow> sheet = [
    BoxShadow(
      color: Color.fromRGBO(31, 27, 22, 0.12),
      blurRadius: 32,
      offset: Offset(0, -4),
    ),
  ];

  // Backward compatibility alias
  static const List<BoxShadow> elevated = card;
  static const List<BoxShadow> modal = sheet;
}
