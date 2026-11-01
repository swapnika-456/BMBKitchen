import '../core/money/paise.dart';

class StockItem {
  final String id;
  final String name;
  final String unit; // kg, ltr, piece, etc.
  final double qty;
  final double min;
  final Paise rate; // purchase rate per unit
  final String cat;
  final String vendor; // vendor ID

  const StockItem({
    required this.id,
    required this.name,
    required this.unit,
    required this.qty,
    required this.min,
    required this.rate,
    required this.cat,
    required this.vendor,
  });

  bool get isLow => qty <= min;

  Paise get totalValue => rate * qty;

  StockItem copyWith({
    String? id,
    String? name,
    String? unit,
    double? qty,
    double? min,
    Paise? rate,
    String? cat,
    String? vendor,
  }) {
    return StockItem(
      id: id ?? this.id,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      qty: qty ?? this.qty,
      min: min ?? this.min,
      rate: rate ?? this.rate,
      cat: cat ?? this.cat,
      vendor: vendor ?? this.vendor,
    );
  }
}

class StockMovement {
  final String id;
  final String date;
  final String ing; // Stock item ID
  final double qty; // positive or negative
  final String reason;
  final String type; // "Wastage", "Addition", "Adjustment"
  final String by; // Staff ID
  final String outlet;
  final Paise value;

  const StockMovement({
    required this.id,
    required this.date,
    required this.ing,
    required this.qty,
    required this.reason,
    required this.type,
    required this.by,
    required this.outlet,
    required this.value,
  });
}
