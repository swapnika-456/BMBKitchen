import '../core/money/paise.dart';

class Expense {
  final String id;
  final String date;
  final String cat; // Rent, Electricity, Gas, Salary & wages, etc.
  final String desc;
  final String payee;
  final String mode; // Cash, UPI, Card, Bank transfer, Cheque
  final Paise amt;
  final String by; // Staff ID
  final String outlet;

  const Expense({
    required this.id,
    required this.date,
    required this.cat,
    required this.desc,
    this.payee = '',
    this.mode = 'Cash',
    required this.amt,
    required this.by,
    required this.outlet,
  });

  bool get isCash => mode == 'Cash';

  Expense copyWith({
    String? id,
    String? date,
    String? cat,
    String? desc,
    String? payee,
    String? mode,
    Paise? amt,
    String? by,
    String? outlet,
  }) {
    return Expense(
      id: id ?? this.id,
      date: date ?? this.date,
      cat: cat ?? this.cat,
      desc: desc ?? this.desc,
      payee: payee ?? this.payee,
      mode: mode ?? this.mode,
      amt: amt ?? this.amt,
      by: by ?? this.by,
      outlet: outlet ?? this.outlet,
    );
  }
}
