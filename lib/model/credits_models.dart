enum CouponType { flat, percent, bonusCredits }

enum CreditTransactionType { purchase, deduction, bonus }

class CreditPackage {
  final String id;
  final int credits;
  final int priceInr;
  final String subtitle;
  final String? badge;

  const CreditPackage({
    required this.id,
    required this.credits,
    required this.priceInr,
    required this.subtitle,
    this.badge,
  });

  String get formattedCredits {
    final s = credits.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  String get formattedPrice => '₹$priceInr';
}

class CreditCoupon {
  final String code;
  final String description;
  final CouponType type;
  final int value;
  final int? minPurchaseInr;
  final String badgeLabel;

  const CreditCoupon({
    required this.code,
    required this.description,
    required this.type,
    required this.value,
    this.minPurchaseInr,
    required this.badgeLabel,
  });

  int discountFor(int subtotalInr) {
    switch (type) {
      case CouponType.flat:
        return value.clamp(0, subtotalInr);
      case CouponType.percent:
        return ((subtotalInr * value) / 100).round().clamp(0, subtotalInr);
      case CouponType.bonusCredits:
        return 0;
    }
  }

  int bonusCreditsFor(int packageCredits) {
    if (type == CouponType.bonusCredits) return value;
    return 0;
  }
}

class CreditTransaction {
  final String id;
  final String title;
  final String? subtitle;
  final DateTime date;
  final int amount;
  final CreditTransactionType type;

  const CreditTransaction({
    required this.id,
    required this.title,
    this.subtitle,
    required this.date,
    required this.amount,
    required this.type,
  });

  bool get isCredit => amount > 0;
}

class CreditsMonthGroup {
  final String label;
  final List<CreditTransaction> transactions;

  const CreditsMonthGroup({
    required this.label,
    required this.transactions,
  });
}
