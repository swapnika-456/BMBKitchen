import '../core/money/paise.dart';

class LoyaltyTier {
  final String name;
  final Paise minSpend;

  const LoyaltyTier({required this.name, required this.minSpend});
}

class LoyaltySettings {
  final bool active;
  final Paise earnPer; // spend block in Paise (e.g. ₹100 = 10000 paise)
  final int points; // points earned per block (e.g. 5)
  final Paise redeemValue; // 1 point = ₹1
  final int minRedeem; // min points to redeem (e.g. 100)
  final int expiryDays;
  final List<LoyaltyTier> tiers;

  const LoyaltySettings({
    this.active = true,
    this.earnPer = const Paise(10000), // ₹100
    this.points = 5,
    this.redeemValue = const Paise(100), // ₹1
    this.minRedeem = 100,
    this.expiryDays = 365,
    this.tiers = const [
      LoyaltyTier(name: 'Silver', minSpend: Paise(0)),
      LoyaltyTier(name: 'Gold', minSpend: Paise(500000)), // ₹5,000
      LoyaltyTier(name: 'Platinum', minSpend: Paise(1500000)), // ₹15,000
    ],
  });

  String getTierForSpend(Paise spend) {
    final sorted = [...tiers]..sort((a, b) => b.minSpend.compareTo(a.minSpend));
    for (final tier in sorted) {
      if (spend >= tier.minSpend) return tier.name;
    }
    return 'Silver';
  }

  LoyaltySettings copyWith({
    bool? active,
    Paise? earnPer,
    int? points,
    Paise? redeemValue,
    int? minRedeem,
    int? expiryDays,
    List<LoyaltyTier>? tiers,
  }) {
    return LoyaltySettings(
      active: active ?? this.active,
      earnPer: earnPer ?? this.earnPer,
      points: points ?? this.points,
      redeemValue: redeemValue ?? this.redeemValue,
      minRedeem: minRedeem ?? this.minRedeem,
      expiryDays: expiryDays ?? this.expiryDays,
      tiers: tiers ?? this.tiers,
    );
  }
}
