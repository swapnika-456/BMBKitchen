class TaxRate {
  final String id;
  final String name;
  final double percentage;
  final bool isActive;

  const TaxRate({
    required this.id,
    required this.name,
    required this.percentage,
    this.isActive = false,
  });

  factory TaxRate.fromJson(Map<String, dynamic> json) {
    return TaxRate(
      id: _parseId(json['_id']),
      name: json['name'] as String? ?? '',
      percentage: (json['percentage'] as num?)?.toDouble() ??
          (json['rate'] as num?)?.toDouble() ??
          0.0,
      isActive: json['isActive'] as bool? ??
          json['isDefault'] as bool? ??
          false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'percentage': percentage,
      'isActive': isActive,
    };
  }

  TaxRate copyWith({
    String? id,
    String? name,
    double? percentage,
    bool? isActive,
  }) {
    return TaxRate(
      id: id ?? this.id,
      name: name ?? this.name,
      percentage: percentage ?? this.percentage,
      isActive: isActive ?? this.isActive,
    );
  }

  static String _parseId(dynamic idVal) {
    if (idVal == null) return '';
    if (idVal is String) return idVal;
    if (idVal is Map && idVal['_id'] != null) return idVal['_id'].toString();
    return idVal.toString();
  }
}

class TaxSettings {
  final String id;
  final String organizationId;
  final String mode; // "exclusive" or "inclusive"
  final double serviceCharge; // percentage, e.g. 5.0
  final bool scOnDinein; // service charge restricted to dine-in
  final List<TaxRate> rates;

  const TaxSettings({
    this.id = '',
    required this.organizationId,
    this.mode = 'exclusive',
    this.serviceCharge = 0.0,
    this.scOnDinein = true,
    required this.rates,
  });

  factory TaxSettings.fromJson(Map<String, dynamic> json) {
    var ratesList = json['rates'] as List?;
    return TaxSettings(
      id: _parseId(json['_id']),
      organizationId: _parseId(json['organizationId']),
      mode: json['mode'] as String? ?? 'exclusive',
      serviceCharge: (json['serviceCharge'] as num?)?.toDouble() ?? 0.0,
      scOnDinein: json['scOnDinein'] as bool? ?? true,
      rates: ratesList != null
          ? ratesList
                .map((e) => TaxRate.fromJson(e as Map<String, dynamic>))
                .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'organizationId': organizationId,
      'mode': mode,
      'serviceCharge': serviceCharge,
      'scOnDinein': scOnDinein,
      'rates': rates.map((r) => r.toJson()).toList(),
    };
  }

  TaxRate get defaultRate => rates.firstWhere(
    (r) => r.isActive,
    orElse: () => rates.isNotEmpty
        ? rates.first
        : const TaxRate(
            id: '',
            name: 'GST 5%',
            percentage: 5.0,
            isActive: true,
          ),
  );

  TaxSettings copyWith({
    String? id,
    String? organizationId,
    String? mode,
    double? serviceCharge,
    bool? scOnDinein,
    List<TaxRate>? rates,
  }) {
    return TaxSettings(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      mode: mode ?? this.mode,
      serviceCharge: serviceCharge ?? this.serviceCharge,
      scOnDinein: scOnDinein ?? this.scOnDinein,
      rates: rates ?? this.rates,
    );
  }

  static String _parseId(dynamic idVal) {
    if (idVal == null) return '';
    if (idVal is String) return idVal;
    if (idVal is Map && idVal['_id'] != null) return idVal['_id'].toString();
    return idVal.toString();
  }
}
