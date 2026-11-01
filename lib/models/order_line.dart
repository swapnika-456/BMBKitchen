import '../core/money/paise.dart';

/// Snapshot of an item on an order ticket.
/// Unit price and names are snapshotted at time of sale so later menu changes
/// never alter running or historical bills.
class OrderLine {
  final String sig; // Unique configuration signature for stacking
  final String itemId;
  final String name;
  final int qty;
  final String? variant;
  final List<String> addons;
  final Paise unitPrice;
  final String note;
  final int? kotNo;

  const OrderLine({
    required this.sig,
    required this.itemId,
    required this.name,
    required this.qty,
    this.variant,
    this.addons = const [],
    required this.unitPrice,
    this.note = '',
    this.kotNo,
  });

  bool get isSent => kotNo != null;

  Paise get lineTotal => unitPrice * qty;

  static String generateSig({
    required String itemId,
    String? variant,
    List<String> addons = const [],
    String note = '',
  }) {
    final sortedAddons = [...addons]..sort();
    return '$itemId|${variant ?? ''}|${sortedAddons.join(',')}|${note.trim()}';
  }

  OrderLine copyWith({
    String? sig,
    String? itemId,
    String? name,
    int? qty,
    String? variant,
    List<String>? addons,
    Paise? unitPrice,
    String? note,
    int? kotNo,
  }) {
    return OrderLine(
      sig: sig ?? this.sig,
      itemId: itemId ?? this.itemId,
      name: name ?? this.name,
      qty: qty ?? this.qty,
      variant: variant ?? this.variant,
      addons: addons ?? this.addons,
      unitPrice: unitPrice ?? this.unitPrice,
      note: note ?? this.note,
      kotNo: kotNo ?? this.kotNo,
    );
  }
}
