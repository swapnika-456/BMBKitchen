class NotificationChannels {
  final bool whatsapp;
  final bool sms;
  final bool email;

  const NotificationChannels({
    this.whatsapp = true,
    this.sms = false,
    this.email = true,
  });

  NotificationChannels copyWith({
    bool? whatsapp,
    bool? sms,
    bool? email,
  }) {
    return NotificationChannels(
      whatsapp: whatsapp ?? this.whatsapp,
      sms: sms ?? this.sms,
      email: email ?? this.email,
    );
  }

  factory NotificationChannels.fromJson(Map<String, dynamic> json) {
    return NotificationChannels(
      whatsapp: json['whatsapp'] == true,
      sms: json['sms'] == true,
      email: json['email'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'whatsapp': whatsapp,
      'sms': sms,
      'email': email,
    };
  }
}

class NotificationEvents {
  final bool billShare;
  final bool orderReady;
  final bool lowStock;
  final bool dayClosing;
  final bool newOnline;
  final bool offerBlast;

  const NotificationEvents({
    this.billShare = true,
    this.orderReady = true,
    this.lowStock = true,
    this.dayClosing = true,
    this.newOnline = true,
    this.offerBlast = false,
  });

  NotificationEvents copyWith({
    bool? billShare,
    bool? orderReady,
    bool? lowStock,
    bool? dayClosing,
    bool? newOnline,
    bool? offerBlast,
  }) {
    return NotificationEvents(
      billShare: billShare ?? this.billShare,
      orderReady: orderReady ?? this.orderReady,
      lowStock: lowStock ?? this.lowStock,
      dayClosing: dayClosing ?? this.dayClosing,
      newOnline: newOnline ?? this.newOnline,
      offerBlast: offerBlast ?? this.offerBlast,
    );
  }

  factory NotificationEvents.fromJson(Map<String, dynamic> json) {
    return NotificationEvents(
      billShare: json['billShare'] == true,
      orderReady: json['orderReady'] == true,
      lowStock: json['lowStock'] == true,
      dayClosing: json['dayClosing'] == true,
      newOnline: json['newOnline'] == true,
      offerBlast: json['offerBlast'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'billShare': billShare,
      'orderReady': orderReady,
      'lowStock': lowStock,
      'dayClosing': dayClosing,
      'newOnline': newOnline,
      'offerBlast': offerBlast,
    };
  }
}

class NotificationSettings {
  final String id;
  final String organizationId;
  final NotificationChannels channels;
  final NotificationEvents events;
  final String? createdBy;
  final String? updatedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const NotificationSettings({
    required this.id,
    required this.organizationId,
    this.channels = const NotificationChannels(),
    this.events = const NotificationEvents(),
    this.createdBy,
    this.updatedBy,
    this.createdAt,
    this.updatedAt,
  });

  factory NotificationSettings.defaultSettings(String organizationId) {
    return NotificationSettings(
      id: '',
      organizationId: organizationId,
      channels: const NotificationChannels(),
      events: const NotificationEvents(),
    );
  }

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    String orgId = '';
    final rawOrg = json['organizationId'];
    if (rawOrg is Map) {
      orgId = (rawOrg['_id'] ?? rawOrg['id'] ?? '').toString();
    } else if (rawOrg != null) {
      orgId = rawOrg.toString();
    }

    String? createdById;
    final rawCreated = json['createdBy'];
    if (rawCreated is Map) {
      createdById = (rawCreated['_id'] ?? rawCreated['id'])?.toString();
    } else if (rawCreated != null) {
      createdById = rawCreated.toString();
    }

    String? updatedById;
    final rawUpdated = json['updatedBy'];
    if (rawUpdated is Map) {
      updatedById = (rawUpdated['_id'] ?? rawUpdated['id'])?.toString();
    } else if (rawUpdated != null) {
      updatedById = rawUpdated.toString();
    }

    DateTime? createdDate;
    if (json['createdAt'] != null) {
      createdDate = DateTime.tryParse(json['createdAt'].toString());
    }

    DateTime? updatedDate;
    if (json['updatedAt'] != null) {
      updatedDate = DateTime.tryParse(json['updatedAt'].toString());
    }

    final rawChannels = json['channels'];
    final channels = rawChannels is Map<String, dynamic>
        ? NotificationChannels.fromJson(rawChannels)
        : const NotificationChannels();

    final rawEvents = json['events'];
    final events = rawEvents is Map<String, dynamic>
        ? NotificationEvents.fromJson(rawEvents)
        : const NotificationEvents();

    return NotificationSettings(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      organizationId: orgId,
      channels: channels,
      events: events,
      createdBy: createdById,
      updatedBy: updatedById,
      createdAt: createdDate,
      updatedAt: updatedDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) '_id': id,
      'organizationId': organizationId,
      'channels': channels.toJson(),
      'events': events.toJson(),
      if (createdBy != null) 'createdBy': createdBy,
      if (updatedBy != null) 'updatedBy': updatedBy,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  NotificationSettings copyWith({
    String? id,
    String? organizationId,
    NotificationChannels? channels,
    NotificationEvents? events,
    String? createdBy,
    String? updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NotificationSettings(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      channels: channels ?? this.channels,
      events: events ?? this.events,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
