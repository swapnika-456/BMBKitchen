class Integration {
  final String id;
  final String organizationId;
  final String name;
  final String category; // "Aggregator" | "Payments" | "Messaging" | "Accounting" | "Reputation"
  final String status; // "connected" | "not_connected"
  final String note;
  final DateTime? connectedSince;
  final String? createdBy;
  final String? updatedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Integration({
    required this.id,
    this.organizationId = '',
    required this.name,
    String? category,
    String? cat,
    this.status = 'not_connected',
    this.note = '',
    this.connectedSince,
    this.createdBy,
    this.updatedBy,
    this.createdAt,
    this.updatedAt,
    String? since,
  }) : category = category ?? cat ?? 'Aggregator';

  bool get isConnected => status == 'connected';

  // Backwards compatibility with legacy mock references
  String get cat => category;
  String get since => connectedSince != null
      ? '${connectedSince!.year}-${connectedSince!.month.toString().padLeft(2, '0')}-${connectedSince!.day.toString().padLeft(2, '0')}'
      : '';

  factory Integration.fromJson(Map<String, dynamic> json) {
    return Integration(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      organizationId: json['organizationId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString() ?? json['cat']?.toString() ?? 'Aggregator',
      status: json['status']?.toString() ?? 'not_connected',
      note: json['note']?.toString() ?? '',
      connectedSince: json['connectedSince'] != null
          ? DateTime.tryParse(json['connectedSince'].toString())
          : null,
      createdBy: json['createdBy']?.toString(),
      updatedBy: json['updatedBy']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) '_id': id,
      if (organizationId.isNotEmpty) 'organizationId': organizationId,
      'name': name,
      'category': category,
      'status': status,
      'note': note,
      if (connectedSince != null) 'connectedSince': connectedSince!.toIso8601String(),
      if (createdBy != null) 'createdBy': createdBy,
      if (updatedBy != null) 'updatedBy': updatedBy,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  Integration copyWith({
    String? id,
    String? organizationId,
    String? name,
    String? category,
    String? status,
    String? note,
    DateTime? connectedSince,
    String? createdBy,
    String? updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? cat,
    String? since,
  }) {
    return Integration(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      name: name ?? this.name,
      category: category ?? cat ?? this.category,
      status: status ?? this.status,
      note: note ?? this.note,
      connectedSince: connectedSince ?? this.connectedSince,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class LegacyMockSupportTicket {
  final String id;
  final String no; // TKT-0001
  final String subject;
  final String cat;
  final String priority; // Low, Medium, High
  final String details;
  final String status; // Open, In progress, Closed
  final int at;
  final String by;
  final String outlet;

  const LegacyMockSupportTicket({
    required this.id,
    required this.no,
    required this.subject,
    required this.cat,
    this.priority = 'Medium',
    this.details = '',
    this.status = 'Open',
    required this.at,
    required this.by,
    required this.outlet,
  });

  LegacyMockSupportTicket copyWith({
    String? id,
    String? no,
    String? subject,
    String? cat,
    String? priority,
    String? details,
    String? status,
    int? at,
    String? by,
    String? outlet,
  }) {
    return LegacyMockSupportTicket(
      id: id ?? this.id,
      no: no ?? this.no,
      subject: subject ?? this.subject,
      cat: cat ?? this.cat,
      priority: priority ?? this.priority,
      details: details ?? this.details,
      status: status ?? this.status,
      at: at ?? this.at,
      by: by ?? this.by,
      outlet: outlet ?? this.outlet,
    );
  }
}

class LegacyMockSubscriptionInvoice {
  final String no;
  final String date;
  final dynamic amt;
  final String status;

  const LegacyMockSubscriptionInvoice({
    required this.no,
    required this.date,
    required this.amt,
    required this.status,
  });
}
