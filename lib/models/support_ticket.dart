/// Support Ticket model corresponding to SupportTicketSchema in BMB_KITCHEN_BACKEND_API_8
class SupportTicket {
  final String id;
  final String organizationId;
  final String outletId;
  final String outletName;
  final String ticketNo;
  final String subject;
  final String category;
  final String priority;
  final String details;
  final String status;
  final String? raisedBy;
  final String? raisedByName;
  final bool isActive;
  final String? createdBy;
  final String? updatedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const SupportTicket({
    required this.id,
    required this.organizationId,
    required this.outletId,
    this.outletName = '',
    required this.ticketNo,
    required this.subject,
    this.category = 'Other',
    this.priority = 'Medium',
    this.details = '',
    this.status = 'Open',
    this.raisedBy,
    this.raisedByName,
    this.isActive = true,
    this.createdBy,
    this.updatedBy,
    this.createdAt,
    this.updatedAt,
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    String outId = '';
    String outName = '';
    final rawOutlet = json['outletId'];
    if (rawOutlet is Map) {
      outId = (rawOutlet['_id'] ?? rawOutlet['id'] ?? '').toString();
      outName = (rawOutlet['name'] ?? rawOutlet['code'] ?? '').toString();
    } else if (rawOutlet != null) {
      outId = rawOutlet.toString();
    }

    String? raisedId;
    String? raisedName;
    final rawRaised = json['raisedBy'];
    if (rawRaised is Map) {
      raisedId = (rawRaised['_id'] ?? rawRaised['id'] ?? '').toString();
      raisedName = (rawRaised['userName'] ?? rawRaised['name'] ?? rawRaised['email'])?.toString();
    } else if (rawRaised != null) {
      raisedId = rawRaised.toString();
    }

    return SupportTicket(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      organizationId: (json['organizationId'] ?? '').toString(),
      outletId: outId,
      outletName: outName,
      ticketNo: (json['ticketNo'] ?? '').toString(),
      subject: (json['subject'] ?? '').toString(),
      category: (json['category'] ?? 'Other').toString(),
      priority: (json['priority'] ?? 'Medium').toString(),
      details: (json['details'] ?? '').toString(),
      status: (json['status'] ?? 'Open').toString(),
      raisedBy: raisedId,
      raisedByName: raisedName,
      isActive: json['isActive'] ?? true,
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

  /// Shared payload helper for server requests (creation)
  Map<String, dynamic> toServerPayload() {
    return {
      'outletId': outletId,
      'subject': subject.trim(),
      if (category.isNotEmpty) 'category': category,
      if (priority.isNotEmpty) 'priority': priority,
      if (details.isNotEmpty) 'details': details.trim(),
    };
  }

  Map<String, dynamic> toJson() => toServerPayload();

  SupportTicket copyWith({
    String? id,
    String? organizationId,
    String? outletId,
    String? outletName,
    String? ticketNo,
    String? subject,
    String? category,
    String? priority,
    String? details,
    String? status,
    String? raisedBy,
    String? raisedByName,
    bool? isActive,
    String? createdBy,
    String? updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SupportTicket(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      outletId: outletId ?? this.outletId,
      outletName: outletName ?? this.outletName,
      ticketNo: ticketNo ?? this.ticketNo,
      subject: subject ?? this.subject,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      details: details ?? this.details,
      status: status ?? this.status,
      raisedBy: raisedBy ?? this.raisedBy,
      raisedByName: raisedByName ?? this.raisedByName,
      isActive: isActive ?? this.isActive,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isOpen => status == 'Open';
  bool get isInProgress => status == 'In progress';
  bool get isClosed => status == 'Closed';

  /// Next sequential status in the workflow
  String? get nextStatus {
    switch (status) {
      case 'Open':
        return 'In progress';
      case 'In progress':
        return 'Closed';
      case 'Closed':
        return 'Open'; // Reopen option
      default:
        return null;
    }
  }

  String? get nextActionLabel {
    switch (status) {
      case 'Open':
        return 'Start Progress';
      case 'In progress':
        return 'Close Ticket';
      case 'Closed':
        return 'Reopen Ticket';
      default:
        return null;
    }
  }
}
