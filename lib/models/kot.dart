import 'order_line.dart';

enum KOTStatus {
  newKot('New'),
  accepted('Accepted'),
  preparing('Preparing'),
  ready('Ready'),
  completed('Done'),
  cancelled('Cancelled');

  final String label;
  const KOTStatus(this.label);

  bool get isActive => this != completed && this != cancelled;
  bool get isCooking => this == newKot || this == accepted || this == preparing;
}

class KOTStatusLog {
  final KOTStatus status;
  final int timestamp;

  const KOTStatusLog({required this.status, required this.timestamp});
}

class KOT {
  final String id;
  final int no;
  final String orderId;
  final List<OrderLine> items;
  final KOTStatus status;
  final int createdAtMs;
  final String printer;
  final List<KOTStatusLog> logs;

  const KOT({
    required this.id,
    required this.no,
    required this.orderId,
    required this.items,
    this.status = KOTStatus.newKot,
    required this.createdAtMs,
    required this.printer,
    this.logs = const [],
  });

  int elapsedMinutes(int currentMs) {
    return (currentMs - createdAtMs) ~/ 60000;
  }

  bool isLate(int currentMs, {int thresholdMinutes = 10}) {
    return status.isActive && elapsedMinutes(currentMs) >= thresholdMinutes;
  }

  KOT copyWith({
    String? id,
    int? no,
    String? orderId,
    List<OrderLine>? items,
    KOTStatus? status,
    int? createdAtMs,
    String? printer,
    List<KOTStatusLog>? logs,
  }) {
    return KOT(
      id: id ?? this.id,
      no: no ?? this.no,
      orderId: orderId ?? this.orderId,
      items: items ?? this.items,
      status: status ?? this.status,
      createdAtMs: createdAtMs ?? this.createdAtMs,
      printer: printer ?? this.printer,
      logs: logs ?? this.logs,
    );
  }
}
