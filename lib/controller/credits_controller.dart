import 'package:get/get.dart';

import '../model/credits_models.dart';

class CreditsController extends GetxController {
  static CreditsController get to {
    if (Get.isRegistered<CreditsController>()) {
      return Get.find<CreditsController>();
    }
    return Get.put(CreditsController(), permanent: true);
  }

  final balance = 250.obs;
  final usedThisMonth = 300.obs;
  final purchasedThisMonth = 2000.obs;
  final believeModeWeeklyCredits = 150;
  final nextDeductionDays = 6.obs;

  final packages = <CreditPackage>[
    const CreditPackage(
      id: 'pkg_700',
      credits: 700,
      priceInr: 1100,
      subtitle: 'Best for getting started',
    ),
    const CreditPackage(
      id: 'pkg_1000',
      credits: 1000,
      priceInr: 1300,
      subtitle: 'Most popular choice',
    ),
    const CreditPackage(
      id: 'pkg_1500',
      credits: 1500,
      priceInr: 1600,
      subtitle: 'Great value',
    ),
    const CreditPackage(
      id: 'pkg_2000',
      credits: 2000,
      priceInr: 2000,
      subtitle: 'Best value',
      badge: '20% More Value',
    ),
  ].obs;

  final coupons = <CreditCoupon>[
    const CreditCoupon(
      code: 'ZENO200',
      description: '₹200 off on minimum purchase',
      type: CouponType.flat,
      value: 200,
      minPurchaseInr: 500,
      badgeLabel: '₹200 OFF',
    ),
    const CreditCoupon(
      code: 'WELCOME10',
      description: '10% off on minimum purchase',
      type: CouponType.percent,
      value: 10,
      minPurchaseInr: 500,
      badgeLabel: '10% OFF',
    ),
    const CreditCoupon(
      code: 'BONUS500',
      description: 'Get 500 bonus AI Credits',
      type: CouponType.bonusCredits,
      value: 500,
      badgeLabel: '500 BONUS',
    ),
    const CreditCoupon(
      code: 'TRADE50',
      description: '₹50 off on minimum purchase',
      type: CouponType.flat,
      value: 50,
      minPurchaseInr: 500,
      badgeLabel: '₹50 OFF',
    ),
  ].obs;

  final selectedPackageId = 'pkg_2000'.obs;
  final appliedCoupon = Rxn<CreditCoupon>();
  final couponError = ''.obs;
  final isPurchasing = false.obs;
  final historyFilter = 'All Transactions'.obs;

  final transactions = <CreditTransaction>[].obs;

  @override
  void onInit() {
    super.onInit();
    _seedHistory();
  }

  CreditPackage get selectedPackage =>
      packages.firstWhere((p) => p.id == selectedPackageId.value);

  int get subtotal => selectedPackage.priceInr;

  int get discountAmount {
    final coupon = appliedCoupon.value;
    if (coupon == null) return 0;
    return coupon.discountFor(subtotal);
  }

  int get amountToPay => (subtotal - discountAmount).clamp(0, subtotal);

  int get bonusCredits {
    final coupon = appliedCoupon.value;
    if (coupon == null) return 0;
    return coupon.bonusCreditsFor(selectedPackage.credits);
  }

  int get creditsToReceive => selectedPackage.credits + bonusCredits;

  int get lifetimeNetCredits {
    return transactions.fold<int>(0, (sum, t) => sum + t.amount);
  }

  List<CreditsMonthGroup> get groupedHistory {
    final filtered = _filteredTransactions();
    final map = <String, List<CreditTransaction>>{};
    final order = <String>[];

    for (final t in filtered) {
      final label = _monthYearLabel(t.date);
      if (!map.containsKey(label)) {
        map[label] = [];
        order.add(label);
      }
      map[label]!.add(t);
    }

    return order
        .map((l) => CreditsMonthGroup(label: l, transactions: map[l]!))
        .toList();
  }

  List<CreditTransaction> _filteredTransactions() {
    final filter = historyFilter.value;
    if (filter == 'Purchases') {
      return transactions.where((t) => t.type == CreditTransactionType.purchase).toList();
    }
    if (filter == 'Deductions') {
      return transactions.where((t) => t.type == CreditTransactionType.deduction).toList();
    }
    return transactions.toList();
  }

  void selectPackage(String id) {
    selectedPackageId.value = id;
    // Re-validate coupon against new package price
    final coupon = appliedCoupon.value;
    if (coupon != null &&
        coupon.minPurchaseInr != null &&
        subtotal < coupon.minPurchaseInr!) {
      appliedCoupon.value = null;
      couponError.value = 'Coupon not valid for this package';
    } else {
      couponError.value = '';
    }
  }

  void selectCoupon(CreditCoupon coupon) {
    appliedCoupon.value = coupon;
    couponError.value = '';
  }

  bool applyCouponCode(String rawCode) {
    final code = rawCode.trim().toUpperCase();
    if (code.isEmpty) {
      couponError.value = 'Please enter a coupon code';
      return false;
    }

    CreditCoupon? match;
    for (final c in coupons) {
      if (c.code.toUpperCase() == code) {
        match = c;
        break;
      }
    }

    if (match == null) {
      couponError.value = 'Invalid coupon code';
      return false;
    }

    if (match.minPurchaseInr != null && subtotal < match.minPurchaseInr!) {
      couponError.value =
          'Minimum purchase of ₹${match.minPurchaseInr} required';
      return false;
    }

    appliedCoupon.value = match;
    couponError.value = '';
    return true;
  }

  void removeCoupon() {
    appliedCoupon.value = null;
    couponError.value = '';
  }

  void resetBuyState() {
    selectedPackageId.value = 'pkg_2000';
    appliedCoupon.value = null;
    couponError.value = '';
    isPurchasing.value = false;
  }

  Future<PurchaseResult> purchaseSelected() async {
    if (isPurchasing.value) {
      return PurchaseResult.failed('Purchase already in progress');
    }

    isPurchasing.value = true;
    await Future<void>.delayed(const Duration(milliseconds: 900));

    final previousBalance = balance.value;
    final added = creditsToReceive;
    final paid = amountToPay;
    final pkg = selectedPackage;
    final coupon = appliedCoupon.value;

    balance.value = previousBalance + added;
    purchasedThisMonth.value += pkg.credits;

    final title = '${pkg.formattedCredits} AI Credits Purchased';
    transactions.insert(
      0,
      CreditTransaction(
        id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        subtitle: coupon != null ? 'Coupon ${coupon.code}' : 'Purchase',
        date: DateTime.now(),
        amount: added,
        type: CreditTransactionType.purchase,
      ),
    );

    isPurchasing.value = false;

    return PurchaseResult.success(
      creditsAdded: added,
      previousBalance: previousBalance,
      newBalance: balance.value,
      amountPaid: paid,
      package: pkg,
    );
  }

  void setHistoryFilter(String filter) {
    historyFilter.value = filter;
  }

  void _seedHistory() {
    transactions.assignAll([
      CreditTransaction(
        id: 'h1',
        title: 'Week 2 - Believe Mode Deduction',
        subtitle: null,
        date: DateTime(2025, 5, 12, 10, 30),
        amount: -150,
        type: CreditTransactionType.deduction,
      ),
      CreditTransaction(
        id: 'h2',
        title: 'Week 1 - Believe Mode Deduction',
        subtitle: null,
        date: DateTime(2025, 5, 5, 10, 30),
        amount: -150,
        type: CreditTransactionType.deduction,
      ),
      CreditTransaction(
        id: 'h3',
        title: '2,000 AI Credits Purchased',
        subtitle: 'Purchase',
        date: DateTime(2025, 5, 1, 14, 20),
        amount: 2000,
        type: CreditTransactionType.purchase,
      ),
      CreditTransaction(
        id: 'h4',
        title: '1,000 AI Credits Purchased',
        subtitle: 'Purchase',
        date: DateTime(2025, 4, 20, 11, 15),
        amount: 1000,
        type: CreditTransactionType.purchase,
      ),
      CreditTransaction(
        id: 'h5',
        title: 'Week 4 - Believe Mode Deduction',
        subtitle: null,
        date: DateTime(2025, 4, 28, 10, 30),
        amount: -150,
        type: CreditTransactionType.deduction,
      ),
      CreditTransaction(
        id: 'h6',
        title: 'Welcome Credits',
        subtitle: 'Bonus',
        date: DateTime(2025, 4, 1, 9, 0),
        amount: 500,
        type: CreditTransactionType.bonus,
      ),
    ]);
  }

  static String formatCredits(int value) {
    final abs = value.abs();
    final s = abs.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    final formatted = buf.toString();
    if (value < 0) return '-$formatted';
    if (value > 0) return '+$formatted';
    return formatted;
  }

  static String formatCreditsPlain(int value) {
    final s = value.abs().toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  static String _monthYearLabel(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  static String formatDateTime(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final h = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final m = date.minute.toString().padLeft(2, '0');
    final amPm = date.hour >= 12 ? 'PM' : 'AM';
    return '${months[date.month - 1]} ${date.day}, ${date.year} · $h:$m $amPm';
  }
}

class PurchaseResult {
  final bool ok;
  final String? error;
  final int creditsAdded;
  final int previousBalance;
  final int newBalance;
  final int amountPaid;
  final CreditPackage? package;

  const PurchaseResult._({
    required this.ok,
    this.error,
    this.creditsAdded = 0,
    this.previousBalance = 0,
    this.newBalance = 0,
    this.amountPaid = 0,
    this.package,
  });

  factory PurchaseResult.success({
    required int creditsAdded,
    required int previousBalance,
    required int newBalance,
    required int amountPaid,
    required CreditPackage package,
  }) {
    return PurchaseResult._(
      ok: true,
      creditsAdded: creditsAdded,
      previousBalance: previousBalance,
      newBalance: newBalance,
      amountPaid: amountPaid,
      package: package,
    );
  }

  factory PurchaseResult.failed(String error) =>
      PurchaseResult._(ok: false, error: error);
}
