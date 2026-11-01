class AppNotification {
  final String id;
  final String organizationId;
  final String? outletId;
  final String eventKey; // billShare | orderReady | lowStock | dayClosing | newOnline | offerBlast | general
  final String title;
  final String message;
  final String? relatedEntityType;
  final String? relatedEntityId;
  final List<String> readBy; // list of user ids
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AppNotification({
    required this.id,
    this.organizationId = '',
    this.outletId,
    this.eventKey = 'general',
    this.title = '',
    this.message = '',
    this.relatedEntityType,
    this.relatedEntityId,
    this.readBy = const [],
    this.createdBy,
    this.createdAt,
    this.updatedAt,
    // Backwards-compatibility legacy parameters
    String? type,
    String? text,
    int? at,
    bool? read,
  }) : super();

  // Convenience constructor supporting legacy mock usages
  factory AppNotification.legacy({
    required String id,
    required String type,
    required String text,
    required int at,
    bool read = false,
  }) {
    return AppNotification(
      id: id,
      eventKey: type,
      title: type.toUpperCase(),
      message: text,
      createdAt: DateTime.fromMillisecondsSinceEpoch(at),
      readBy: read ? ['read_user'] : const [],
    );
  }

  // Legacy getters for backward compatibility with mock_state.dart
  String get type => eventKey;
  String get text => message;
  int get at => createdAt?.millisecondsSinceEpoch ?? 0;
  bool get read => readBy.isNotEmpty;

  bool isReadBy(String? userId) {
    if (userId == null || userId.isEmpty) return readBy.isNotEmpty;
    return readBy.contains(userId);
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    String orgId = '';
    final rawOrg = json['organizationId'];
    if (rawOrg is Map) {
      orgId = (rawOrg['_id'] ?? rawOrg['id'] ?? '').toString();
    } else if (rawOrg != null) {
      orgId = rawOrg.toString();
    }

    String? outlet;
    final rawOutlet = json['outletId'];
    if (rawOutlet is Map) {
      outlet = (rawOutlet['_id'] ?? rawOutlet['id'] ?? '').toString();
    } else if (rawOutlet != null) {
      outlet = rawOutlet.toString();
    }

    String? createdById;
    final rawCreated = json['createdBy'];
    if (rawCreated is Map) {
      createdById = (rawCreated['_id'] ?? rawCreated['id'])?.toString();
    } else if (rawCreated != null) {
      createdById = rawCreated.toString();
    }

    List<String> parsedReadBy = [];
    final rawReadBy = json['readBy'];
    if (rawReadBy is List) {
      for (final item in rawReadBy) {
        if (item is Map) {
          final uid = (item['_id'] ?? item['id'])?.toString();
          if (uid != null && uid.isNotEmpty) parsedReadBy.add(uid);
        } else if (item != null) {
          parsedReadBy.add(item.toString());
        }
      }
    }

    DateTime? createdDate;
    if (json['createdAt'] != null) {
      createdDate = DateTime.tryParse(json['createdAt'].toString());
    } else if (json['at'] is int) {
      createdDate = DateTime.fromMillisecondsSinceEpoch(json['at'] as int);
    }

    DateTime? updatedDate;
    if (json['updatedAt'] != null) {
      updatedDate = DateTime.tryParse(json['updatedAt'].toString());
    }

    final rawEventKey = (json['eventKey'] ?? json['type'] ?? 'general').toString();
    final rawTitle = (json['title'] ?? '').toString();
    final rawMessage = (json['message'] ?? json['text'] ?? '').toString();

    return AppNotification(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      organizationId: orgId,
      outletId: outlet,
      eventKey: rawEventKey,
      title: rawTitle.isNotEmpty ? rawTitle : rawEventKey.toUpperCase(),
      message: rawMessage,
      relatedEntityType: json['relatedEntityType']?.toString(),
      relatedEntityId: json['relatedEntityId']?.toString(),
      readBy: parsedReadBy,
      createdBy: createdById,
      createdAt: createdDate,
      updatedAt: updatedDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) '_id': id,
      'organizationId': organizationId,
      if (outletId != null) 'outletId': outletId,
      'eventKey': eventKey,
      'title': title,
      'message': message,
      if (relatedEntityType != null) 'relatedEntityType': relatedEntityType,
      if (relatedEntityId != null) 'relatedEntityId': relatedEntityId,
      'readBy': readBy,
      if (createdBy != null) 'createdBy': createdBy,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  AppNotification copyWith({
    String? id,
    String? organizationId,
    String? outletId,
    String? eventKey,
    String? title,
    String? message,
    String? relatedEntityType,
    String? relatedEntityId,
    List<String>? readBy,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    // Legacy support
    String? type,
    String? text,
    int? at,
    bool? read,
  }) {
    return AppNotification(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      outletId: outletId ?? this.outletId,
      eventKey: eventKey ?? type ?? this.eventKey,
      title: title ?? this.title,
      message: message ?? text ?? this.message,
      relatedEntityType: relatedEntityType ?? this.relatedEntityType,
      relatedEntityId: relatedEntityId ?? this.relatedEntityId,
      readBy: readBy ?? (read != null ? (read ? ['read_user'] : const []) : this.readBy),
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? (at != null ? DateTime.fromMillisecondsSinceEpoch(at) : this.createdAt),
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
