class Vendor {
  final String id;
  final String? organizationId;
  final String? vendorNo;
  final String vendorName;
  final String? contactPerson;
  final String? phone;
  final String? gstin;
  final String? category;
  final String? address;
  final String? paymentTerms;
  final bool isActive;
  final dynamic createdBy;
  final dynamic updatedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Vendor({
    required this.id,
    this.organizationId,
    this.vendorNo,
    required this.vendorName,
    this.contactPerson,
    this.phone,
    this.gstin,
    this.category,
    this.address,
    this.paymentTerms,
    this.isActive = true,
    this.createdBy,
    this.updatedBy,
    this.createdAt,
    this.updatedAt,
  });

  factory Vendor.fromJson(Map<String, dynamic> json) {
    return Vendor(
      id: _parseId(json['_id'] ?? json['id']),
      organizationId: _parseId(json['organizationId']),
      vendorNo: json['vendorNo']?.toString(),
      vendorName: json['vendorName']?.toString() ?? '',
      contactPerson: json['contactPerson']?.toString(),
      phone: json['phone']?.toString(),
      gstin: json['gstin']?.toString(),
      category: json['category']?.toString(),
      address: json['address']?.toString(),
      paymentTerms: json['paymentTerms']?.toString(),
      isActive: json['isActive'] as bool? ?? true,
      createdBy: json['createdBy'],
      updatedBy: json['updatedBy'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  static String _parseId(dynamic idVal) {
    if (idVal == null) return '';
    if (idVal is String) return idVal;
    if (idVal is Map && idVal.containsKey('_id')) return idVal['_id'].toString();
    if (idVal is Map && idVal.containsKey('\$oid')) return idVal['\$oid'].toString();
    return idVal.toString();
  }

  Vendor copyWith({
    String? id,
    String? organizationId,
    String? vendorNo,
    String? vendorName,
    String? contactPerson,
    String? phone,
    String? gstin,
    String? category,
    String? address,
    String? paymentTerms,
    bool? isActive,
  }) {
    return Vendor(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      vendorNo: vendorNo ?? this.vendorNo,
      vendorName: vendorName ?? this.vendorName,
      contactPerson: contactPerson ?? this.contactPerson,
      phone: phone ?? this.phone,
      gstin: gstin ?? this.gstin,
      category: category ?? this.category,
      address: address ?? this.address,
      paymentTerms: paymentTerms ?? this.paymentTerms,
      isActive: isActive ?? this.isActive,
      createdBy: createdBy,
      updatedBy: updatedBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
