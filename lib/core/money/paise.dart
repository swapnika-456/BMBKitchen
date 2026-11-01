import 'package:intl/intl.dart';

/// Immutable value object representing Indian currency in integer Paise.
/// Prevents floating-point precision issues in financial calculations.
class Paise implements Comparable<Paise> {
  final int value;

  const Paise(this.value);

  const Paise.zero() : value = 0;

  factory Paise.fromRupees(num rupees) => Paise((rupees * 100).round());

  double get toRupees => value / 100.0;
  int get inRupees => value ~/ 100;
  bool get isZero => value == 0;
  bool get isNegative => value < 0;
  bool get isPositive => value > 0;

  Paise abs() => Paise(value.abs());

  Paise operator +(Paise other) => Paise(value + other.value);
  Paise operator -(Paise other) => Paise(value - other.value);
  Paise operator *(num factor) => Paise((value * factor).round());
  Paise operator /(num divisor) {
    if (divisor == 0) return const Paise(0);
    return Paise((value / divisor).round());
  }

  Paise operator -() => Paise(-value);

  bool operator <(Paise other) => value < other.value;
  bool operator <=(Paise other) => value <= other.value;
  bool operator >(Paise other) => value > other.value;
  bool operator >=(Paise other) => value >= other.value;

  @override
  int compareTo(Paise other) => value.compareTo(other.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Paise && other.value == value);

  @override
  int get hashCode => value.hashCode;

  /// Rounds to the nearest Rupee (nearest 100 paise).
  /// Returns a record with the rounded total and the exact adjustment.
  ({Paise rounded, Paise adjustment}) roundToRupee() {
    final roundedVal = (toRupees.round()) * 100;
    final roundedPaise = Paise(roundedVal);
    final adjustmentPaise = roundedPaise - this;
    return (rounded: roundedPaise, adjustment: adjustmentPaise);
  }

  /// Formatted as Indian Rupees with 2 decimals, e.g. ₹1,12,400.00 or ₹220.00
  String get inr {
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    );
    return formatter.format(toRupees);
  }

  /// Formatted as whole Indian Rupees without decimals, e.g. ₹1,12,400
  String get inr0 {
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );
    return formatter.format(toRupees);
  }

  /// Formatted with +/- sign prefix
  String get inrWithSign {
    final sign = isPositive ? '+' : (isNegative ? '-' : '');
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    );
    return '$sign${formatter.format(toRupees.abs())}';
  }

  @override
  String toString() => inr;
}
