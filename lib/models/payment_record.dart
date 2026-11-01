import '../core/money/paise.dart';

enum PaymentMode {
  cash('Cash'),
  upi('UPI'),
  card('Card'),
  credit('Credit'),
  online('Online');

  final String label;
  const PaymentMode(this.label);

  static PaymentMode fromString(String val) {
    return PaymentMode.values.firstWhere(
      (m) =>
          m.label.toLowerCase() == val.toLowerCase() ||
          m.name.toLowerCase() == val.toLowerCase(),
      orElse: () => PaymentMode.cash,
    );
  }
}

class PaymentRecord {
  final PaymentMode mode;
  final Paise amount;
  final String? reference;

  const PaymentRecord({
    required this.mode,
    required this.amount,
    this.reference,
  });

  PaymentRecord copyWith({
    PaymentMode? mode,
    Paise? amount,
    String? reference,
  }) {
    return PaymentRecord(
      mode: mode ?? this.mode,
      amount: amount ?? this.amount,
      reference: reference ?? this.reference,
    );
  }
}
