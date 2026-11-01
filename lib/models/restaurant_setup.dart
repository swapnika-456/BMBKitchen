class RestaurantSetup {
  final String legal;
  final String brand;
  final String gstin;
  final String fssai;
  final String email;
  final String phone;
  final String address;
  final String openTime;
  final String closeTime;
  final String currency;
  final String billPrefix;
  final String footer;

  const RestaurantSetup({
    required this.legal,
    required this.brand,
    required this.gstin,
    required this.fssai,
    required this.email,
    required this.phone,
    required this.address,
    required this.openTime,
    required this.closeTime,
    this.currency = 'INR',
    this.billPrefix = 'BMB',
    this.footer = 'Thank you. Visit again!',
  });

  RestaurantSetup copyWith({
    String? legal,
    String? brand,
    String? gstin,
    String? fssai,
    String? email,
    String? phone,
    String? address,
    String? openTime,
    String? closeTime,
    String? currency,
    String? billPrefix,
    String? footer,
  }) {
    return RestaurantSetup(
      legal: legal ?? this.legal,
      brand: brand ?? this.brand,
      gstin: gstin ?? this.gstin,
      fssai: fssai ?? this.fssai,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      openTime: openTime ?? this.openTime,
      closeTime: closeTime ?? this.closeTime,
      currency: currency ?? this.currency,
      billPrefix: billPrefix ?? this.billPrefix,
      footer: footer ?? this.footer,
    );
  }
}
