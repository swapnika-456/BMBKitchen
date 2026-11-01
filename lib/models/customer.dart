import '../core/money/paise.dart';

class Customer {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String addr;
  final int visits;
  final Paise spend;
  final int points;
  final String since;
  final String notes;

  const Customer({
    required this.id,
    required this.name,
    required this.phone,
    this.email = '',
    this.addr = '',
    this.visits = 0,
    this.spend = const Paise(0),
    this.points = 0,
    required this.since,
    this.notes = '',
  });

  Customer copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? addr,
    int? visits,
    Paise? spend,
    int? points,
    String? since,
    String? notes,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      addr: addr ?? this.addr,
      visits: visits ?? this.visits,
      spend: spend ?? this.spend,
      points: points ?? this.points,
      since: since ?? this.since,
      notes: notes ?? this.notes,
    );
  }
}
