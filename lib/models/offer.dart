import '../core/money/paise.dart';

class Offer {
  final String id;
  final String code;
  final String name;
  final String type; // "pct" or "amt"
  final double value;
  final Paise minBill;
  final Paise maxDisc;
  final String applies; // "all", "dinein", "takeaway", "delivery", "online"
  final bool active;
  final String from;
  final String to;
  final int used;

  const Offer({
    required this.id,
    required this.code,
    required this.name,
    required this.type,
    required this.value,
    this.minBill = const Paise(0),
    this.maxDisc = const Paise(0),
    this.applies = 'all',
    this.active = true,
    required this.from,
    required this.to,
    this.used = 0,
  });

  /// Calculates the discount on a given subtotal.
  /// Returns 0 if subtotal < minBill.
  Paise calculateDiscount(Paise subtotal) {
    if (subtotal < minBill) return const Paise(0);

    Paise rawDiscount;
    if (type == 'pct') {
      rawDiscount = subtotal * (value / 100.0);
    } else {
      rawDiscount = Paise.fromRupees(value);
    }

    if (maxDisc > const Paise(0) && rawDiscount > maxDisc) {
      return maxDisc;
    }
    return rawDiscount > subtotal ? subtotal : rawDiscount;
  }

  Offer copyWith({
    String? id,
    String? code,
    String? name,
    String? type,
    double? value,
    Paise? minBill,
    Paise? maxDisc,
    String? applies,
    bool? active,
    String? from,
    String? to,
    int? used,
  }) {
    return Offer(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      type: type ?? this.type,
      value: value ?? this.value,
      minBill: minBill ?? this.minBill,
      maxDisc: maxDisc ?? this.maxDisc,
      applies: applies ?? this.applies,
      active: active ?? this.active,
      from: from ?? this.from,
      to: to ?? this.to,
      used: used ?? this.used,
    );
  }
}
