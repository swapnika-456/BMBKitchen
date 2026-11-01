import '../core/money/paise.dart';

class IndentLine {
  final String ing;
  final double qty;
  final String unit;

  const IndentLine({required this.ing, required this.qty, this.unit = ''});
}

class CentralKitchenIndent {
  final String id;
  final String indentNo;
  final String fromOutlet;
  final String toKitchen;
  final String item;
  final double qty;
  final String unit;
  final String status; // 'Requested', 'Approved', 'Dispatched', 'Received'
  final int requestedAt;
  final String note;
  final List<IndentLine> lines;
  final Paise value;

  const CentralKitchenIndent({
    required this.id,
    required this.indentNo,
    required this.fromOutlet,
    required this.toKitchen,
    this.item = '',
    this.qty = 0,
    this.unit = '',
    this.status = 'Requested',
    required this.requestedAt,
    this.note = '',
    this.lines = const [],
    this.value = const Paise(0),
  });

  CentralKitchenIndent copyWith({
    String? id,
    String? indentNo,
    String? fromOutlet,
    String? toKitchen,
    String? item,
    double? qty,
    String? unit,
    String? status,
    int? requestedAt,
    String? note,
    List<IndentLine>? lines,
    Paise? value,
  }) {
    return CentralKitchenIndent(
      id: id ?? this.id,
      indentNo: indentNo ?? this.indentNo,
      fromOutlet: fromOutlet ?? this.fromOutlet,
      toKitchen: toKitchen ?? this.toKitchen,
      item: item ?? this.item,
      qty: qty ?? this.qty,
      unit: unit ?? this.unit,
      status: status ?? this.status,
      requestedAt: requestedAt ?? this.requestedAt,
      note: note ?? this.note,
      lines: lines ?? this.lines,
      value: value ?? this.value,
    );
  }
}
