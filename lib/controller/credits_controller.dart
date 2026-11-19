import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../common/common.dart';
import '../model/coin_models.dart';
import '../model/credits_models.dart';
import '../services/coin_purchase_service.dart';

/// Where the checkout currently is. Drives every spinner and status label.
enum CoinPurchaseStage {
  idle,

  /// `POST /coin-orders/create` in flight.
  creatingOrder,

  /// Razorpay Checkout is on screen.
  awaitingCheckout,

  /// `POST /coin-orders/verify` in flight.
  verifying,

  /// Signature accepted; waiting for the capture webhook to credit coins.
  confirming,
}

/// Outcome of one purchase attempt.
enum PurchaseOutcome { success, pending, failed, cancelled }

class CreditsController extends GetxController {
  CreditsController({CoinPurchaseService? service})
    : _service = service ?? CoinPurchaseService();

  static CreditsController get to {
    if (Get.isRegistered<CreditsController>()) {
      return Get.find<CreditsController>();
    }
    return Get.put(CreditsController(), permanent: true);
  }

  final CoinPurchaseService _service;
  Razorpay? _razorpay;

  /// Completes when Razorpay reports success, error or an external wallet.
  Completer<PurchaseResult>? _checkoutCompleter;

  /// Order the open checkout belongs to, so late callbacks can be ignored.
  CoinOrder? _activeOrder;

  // ------------------------------------------------------------- wallet state

  final balance = 0.obs;
  final usedThisMonth = 0.obs;
  final purchasedThisMonth = 0.obs;
  final nextDeductionDays = 0.obs;
  final believeModeWeeklyCredits = 150;

  final transactions = <CreditTransaction>[].obs;
  final orderHistory = <CoinOrderHistoryItem>[].obs;

  final isLoadingWallet = false.obs;
  final walletError = ''.obs;

  // ------------------------------------------------------------ package state

  final packages = <CreditPackage>[].obs;
  final isLoadingPackages = false.obs;
  final packagesError = ''.obs;

  /// Raw API packages, keyed by the id the UI model carries as a string.
  final Map<String, CoinPackage> _apiPackages = <String, CoinPackage>{};

  final selectedPackageId = ''.obs;

  // ------------------------------------------------------------- coupon state

  /// No list endpoint exists yet, so this stays empty and the UI hides the
  /// "select a coupon" affordance. Codes are entered manually and validated
  /// by `POST /coin-coupons/apply`.
  final coupons = <CreditCoupon>[].obs;

  final appliedCoupon = Rxn<CreditCoupon>();
  final couponError = ''.obs;
  final isApplyingCoupon = false.obs;

  /// Server-calculated price preview for the applied coupon.
  final Rxn<CoinCouponPreview> _couponPreview = Rxn<CoinCouponPreview>();

  // ----------------------------------------------------------- checkout state

  final stage = CoinPurchaseStage.idle.obs;
  final purchaseStatusText = ''.obs;

  /// True whenever a purchase is in flight, for button spinners.
  bool get isPurchasingNow => stage.value != CoinPurchaseStage.idle;

  /// Kept for the existing UI binding.
  final isPurchasing = false.obs;

  final historyFilter = 'All Transactions'.obs;

  // ----------------------------------------------------------------- lifecycle

  @override
  void onInit() {
    super.onInit();
    _initRazorpay();
    unawaited(loadAll());
  }

  @override
  void onClose() {
    _razorpay?.clear();
    _razorpay = null;
    super.onClose();
  }

  void _initRazorpay() {
    try {
      final instance = Razorpay();
      instance.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onCheckoutSuccess);
      instance.on(Razorpay.EVENT_PAYMENT_ERROR, _onCheckoutError);
      instance.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
      _razorpay = instance;
    } catch (e, stack) {
      // Razorpay has no desktop/web implementation. Checkout is blocked with a
      // clear message instead of crashing the screen.
      debugPrint('[Credits] Razorpay unavailable: $e\n$stack');
      _razorpay = null;
    }
  }

  String get _userId =>
      Common.userData.value?.payload?.id?.toString().trim() ?? '';

  // --------------------------------------------------------------- data loads

  /// Loads packages and wallet together. Safe to call on every screen open.
  Future<void> loadAll() async {
    await Future.wait([loadPackages(), refreshWallet()]);
  }

  Future<void> loadPackages() async {
    if (isLoadingPackages.value) return;
    isLoadingPackages.value = true;
    packagesError.value = '';
    try {
      final result = await _service.fetchPackages();
      if (!result.ok) {
        packagesError.value = result.message;
        return;
      }
      final apiPackages = result.data ?? const <CoinPackage>[];
      _apiPackages
        ..clear()
        ..addEntries(apiPackages.map((p) => MapEntry(p.id.toString(), p)));

      packages.assignAll(apiPackages.map(_toUiPackage));

      // Keep the current selection when it still exists, else pick the first.
      if (!_apiPackages.containsKey(selectedPackageId.value)) {
        selectedPackageId.value = packages.isEmpty ? '' : packages.first.id;
      }
      if (packages.isEmpty) {
        packagesError.value = 'No coin packages are available right now.';
      }
    } finally {
      isLoadingPackages.value = false;
    }
  }

  Future<void> refreshWallet() async {
    final userId = _userId;
    if (userId.isEmpty) {
      walletError.value = 'Please sign in to see your balance.';
      return;
    }
    if (isLoadingWallet.value) return;
    isLoadingWallet.value = true;
    walletError.value = '';
    try {
      final walletResult = await _service.fetchWallet(userId: userId);
      if (!walletResult.ok) {
        walletError.value = walletResult.message;
        return;
      }
      _applyWallet(walletResult.data ?? CoinWallet.empty);

      final historyResult = await _service.fetchOrderHistory(userId: userId);
      if (historyResult.ok) {
        orderHistory.assignAll(historyResult.data ?? const []);
      }
    } finally {
      isLoadingWallet.value = false;
    }
  }

  void _applyWallet(CoinWallet wallet) {
    balance.value = wallet.coinBalance;
    transactions.assignAll(wallet.transactions.map(_toUiTransaction));

    final now = DateTime.now();
    var used = 0;
    var purchased = 0;
    for (final t in wallet.transactions) {
      if (t.createdAt.year != now.year || t.createdAt.month != now.month) {
        continue;
      }
      if (t.isCredit) {
        purchased += t.coins.abs();
      } else {
        used += t.coins.abs();
      }
    }
    usedThisMonth.value = used;
    purchasedThisMonth.value = purchased;
  }

  CreditPackage _toUiPackage(CoinPackage p) => CreditPackage(
    id: p.id.toString(),
    credits: p.coins,
    priceInr: p.priceRupees,
    subtitle: p.description.isNotEmpty ? p.description : p.name,
  );

  CreditTransaction _toUiTransaction(CoinTransaction t) {
    final isPurchase = t.source.toLowerCase().contains('purchase');
    return CreditTransaction(
      id: t.id.toString(),
      title: t.isCredit
          ? '${CreditsController.formatCreditsPlain(t.coins.abs())} AI Credits '
                '${isPurchase ? 'Purchased' : 'Added'}'
          : '${CreditsController.formatCreditsPlain(t.coins.abs())} AI Credits '
                'Used',
      subtitle: _transactionSubtitle(t),
      date: t.createdAt,
      amount: t.signedCoins,
      type: t.isCredit
          ? (isPurchase
                ? CreditTransactionType.purchase
                : CreditTransactionType.bonus)
          : CreditTransactionType.deduction,
    );
  }

  String? _transactionSubtitle(CoinTransaction t) {
    switch (t.source.toLowerCase()) {
      case 'razorpay_purchase':
        return 'Purchase';
      case '':
        return null;
      default:
        return t.source
            .replaceAll('_', ' ')
            .split(' ')
            .map(
              (w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}',
            )
            .join(' ');
    }
  }

  // ------------------------------------------------------------ selection/UI

  CoinPackage? get selectedApiPackage => _apiPackages[selectedPackageId.value];

  CreditPackage? get selectedPackageOrNull {
    for (final p in packages) {
      if (p.id == selectedPackageId.value) return p;
    }
    return packages.isEmpty ? null : packages.first;
  }

  /// Retained for existing UI call sites. Throws only when nothing is loaded,
  /// which the screens guard against with their loading state.
  CreditPackage get selectedPackage =>
      selectedPackageOrNull ??
      (throw StateError('No coin packages loaded'));

  int get subtotalPaise =>
      _couponPreview.value?.originalAmountPaise ??
      selectedApiPackage?.pricePaise ??
      0;

  int get discountPaise => _couponPreview.value?.discountPaise ?? 0;

  int get amountToPayPaise =>
      _couponPreview.value?.finalAmountPaise ?? subtotalPaise;

  int get subtotal => (subtotalPaise / 100).round();

  int get discountAmount => (discountPaise / 100).round();

  int get amountToPay => (amountToPayPaise / 100).round();

  /// The backend has no bonus-coin coupon type, so this is always zero.
  int get bonusCredits => 0;

  int get creditsToReceive => selectedApiPackage?.coins ?? 0;

  int get lifetimeNetCredits =>
      transactions.fold<int>(0, (sum, t) => sum + t.amount);

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
      return transactions
          .where((t) => t.type == CreditTransactionType.purchase)
          .toList();
    }
    if (filter == 'Deductions') {
      return transactions
          .where((t) => t.type == CreditTransactionType.deduction)
          .toList();
    }
    return transactions.toList();
  }

  void setHistoryFilter(String filter) => historyFilter.value = filter;

  void selectPackage(String id) {
    if (selectedPackageId.value == id) return;
    selectedPackageId.value = id;
    // The preview was priced for the old package, so it no longer applies.
    final coupon = appliedCoupon.value;
    _couponPreview.value = null;
    if (coupon != null) {
      unawaited(_revalidateCoupon(coupon.code));
    }
  }

  void selectCoupon(CreditCoupon coupon) {
    unawaited(applyCouponCode(coupon.code));
  }

  void resetBuyState() {
    appliedCoupon.value = null;
    _couponPreview.value = null;
    couponError.value = '';
    isApplyingCoupon.value = false;
    stage.value = CoinPurchaseStage.idle;
    isPurchasing.value = false;
    purchaseStatusText.value = '';
    if (packages.isEmpty && !isLoadingPackages.value) {
      unawaited(loadPackages());
    }
  }

  // ------------------------------------------------------------------ coupons

  /// Validates and prices a coupon through the backend.
  ///
  /// Returns true when the coupon was accepted. The displayed discount always
  /// comes from the server, never from local arithmetic.
  Future<bool> applyCouponCode(String rawCode) async {
    final code = rawCode.trim();
    if (code.isEmpty) {
      couponError.value = 'Please enter a coupon code';
      return false;
    }
    final package = selectedApiPackage;
    if (package == null) {
      couponError.value = 'Select a package first';
      return false;
    }
    final userId = _userId;
    if (userId.isEmpty) {
      couponError.value = 'Please sign in to apply a coupon';
      return false;
    }
    if (isApplyingCoupon.value) return false;

    isApplyingCoupon.value = true;
    couponError.value = '';
    try {
      final result = await _service.applyCoupon(
        userId: userId,
        packageId: package.id,
        couponCode: code,
      );
      if (!result.ok) {
        appliedCoupon.value = null;
        _couponPreview.value = null;
        couponError.value = result.message;
        return false;
      }

      final preview = result.data!;
      _couponPreview.value = preview;
      appliedCoupon.value = _toUiCoupon(preview, code);
      couponError.value = '';
      return true;
    } finally {
      isApplyingCoupon.value = false;
    }
  }

  /// Re-prices an already applied coupon after the package changes. A coupon
  /// that no longer qualifies is dropped with the server's reason.
  Future<void> _revalidateCoupon(String code) async {
    final ok = await applyCouponCode(code);
    if (!ok) appliedCoupon.value = null;
  }

  CreditCoupon _toUiCoupon(CoinCouponPreview preview, String fallbackCode) {
    final coupon = preview.coupon;
    final code = (coupon?.code.isNotEmpty ?? false)
        ? coupon!.code
        : fallbackCode.toUpperCase();
    final saved = formatPaise(preview.discountPaise);
    return CreditCoupon(
      code: code,
      description: 'You save $saved on this package',
      type: (coupon?.isPercentage ?? false)
          ? CouponType.percent
          : CouponType.flat,
      value: coupon?.discountValue.toInt() ?? 0,
      badgeLabel: coupon?.badgeLabel ?? '$saved OFF',
    );
  }

  void removeCoupon() {
    appliedCoupon.value = null;
    _couponPreview.value = null;
    couponError.value = '';
  }

  // ----------------------------------------------------------------- checkout

  /// Runs the full purchase: create order, Razorpay Checkout, verify, confirm.
  ///
  /// Never throws. Every failure path resolves to a [PurchaseResult] the UI
  /// can render.
  Future<PurchaseResult> purchaseSelected() async {
    if (isPurchasingNow) {
      return PurchaseResult.failed('A purchase is already in progress');
    }

    final package = selectedApiPackage;
    if (package == null) {
      return PurchaseResult.failed('Please select a package');
    }
    final userId = _userId;
    if (userId.isEmpty) {
      return PurchaseResult.failed('Please sign in to buy credits');
    }
    if (_razorpay == null) {
      return PurchaseResult.failed(
        'Payments are not available on this device.',
      );
    }

    final previousBalance = balance.value;
    _setStage(CoinPurchaseStage.creatingOrder, 'Creating your order…');

    try {
      final orderResult = await _service.createOrder(
        userId: userId,
        packageId: package.id,
        couponCode: appliedCoupon.value?.code,
      );
      if (!orderResult.ok) {
        return _finish(PurchaseResult.failed(orderResult.message));
      }

      final order = orderResult.data!;
      if (!order.isUsable) {
        return _finish(
          PurchaseResult.failed('Could not start checkout. Please try again.'),
        );
      }

      final checkoutResult = await _openCheckout(order, package);
      if (checkoutResult.outcome != PurchaseOutcome.success) {
        return _finish(checkoutResult);
      }

      // Checkout succeeded; the signature still has to be verified server-side.
      return _finish(
        await _verifyAndConfirm(
          userId: userId,
          order: order,
          payment: checkoutResult,
          previousBalance: previousBalance,
        ),
      );
    } catch (e, stack) {
      debugPrint('[Credits] purchase failed: $e\n$stack');
      return _finish(
        PurchaseResult.failed('Something went wrong. Please try again.'),
      );
    }
  }

  Future<PurchaseResult> _openCheckout(
    CoinOrder order,
    CoinPackage package,
  ) async {
    final completer = Completer<PurchaseResult>();
    _checkoutCompleter = completer;
    _activeOrder = order;

    final user = Common.userData.value?.payload;
    final options = <String, dynamic>{
      'key': order.razorpayKeyId,
      'amount': order.amountPaise,
      'currency': order.currency,
      'order_id': order.razorpayOrderId,
      'name': order.checkoutName.isNotEmpty
          ? order.checkoutName
          : 'Disciplined Minds',
      'description': order.checkoutDescription.isNotEmpty
          ? order.checkoutDescription
          : package.name,
      'prefill': <String, dynamic>{
        if ((user?.phone ?? '').isNotEmpty) 'contact': user!.phone,
        if ((user?.email ?? '').isNotEmpty) 'email': user!.email,
      },
      'retry': {'enabled': true, 'max_count': 1},
    };

    _setStage(CoinPurchaseStage.awaitingCheckout, 'Opening secure checkout…');
    try {
      _razorpay!.open(options);
    } catch (e, stack) {
      debugPrint('[Credits] Razorpay open failed: $e\n$stack');
      _clearCheckout();
      return PurchaseResult.failed('Could not open the payment screen.');
    }

    return completer.future;
  }

  void _onCheckoutSuccess(PaymentSuccessResponse response) {
    final completer = _checkoutCompleter;
    if (completer == null || completer.isCompleted) return;

    final orderId = response.orderId ?? _activeOrder?.razorpayOrderId ?? '';
    final paymentId = response.paymentId ?? '';
    final signature = response.signature ?? '';

    if (paymentId.isEmpty || signature.isEmpty || orderId.isEmpty) {
      // Without all three values the backend cannot verify the signature.
      completer.complete(
        PurchaseResult.failed(
          'Payment could not be confirmed. If money was deducted it will be '
          'refunded automatically.',
        ),
      );
      return;
    }

    completer.complete(
      PurchaseResult._checkoutSucceeded(
        razorpayOrderId: orderId,
        razorpayPaymentId: paymentId,
        razorpaySignature: signature,
      ),
    );
  }

  void _onCheckoutError(PaymentFailureResponse response) {
    final completer = _checkoutCompleter;
    if (completer == null || completer.isCompleted) return;

    final cancelled = response.code == Razorpay.PAYMENT_CANCELLED;
    completer.complete(
      cancelled
          ? PurchaseResult.cancelled()
          : PurchaseResult.failed(_checkoutErrorText(response)),
    );
  }

  /// Razorpay nests the human-readable reason inside a JSON string.
  String _checkoutErrorText(PaymentFailureResponse response) {
    final raw = (response.message ?? '').trim();
    if (raw.isEmpty) return 'Payment failed. Please try again.';
    final descriptionMatch = RegExp(
      r'"description"\s*:\s*"([^"]+)"',
    ).firstMatch(raw);
    final description = descriptionMatch?.group(1)?.trim();
    if (description != null && description.isNotEmpty) return description;
    if (raw.startsWith('{')) return 'Payment failed. Please try again.';
    return raw;
  }

  void _onExternalWallet(ExternalWalletResponse response) {
    final completer = _checkoutCompleter;
    if (completer == null || completer.isCompleted) return;
    // The app has no external-wallet handling, so treat it as abandoned
    // rather than reporting a success that was never verified.
    completer.complete(PurchaseResult.cancelled());
  }

  void _clearCheckout() {
    _checkoutCompleter = null;
    _activeOrder = null;
  }

  /// Verifies the signature, then waits for the capture webhook to credit.
  Future<PurchaseResult> _verifyAndConfirm({
    required String userId,
    required CoinOrder order,
    required PurchaseResult payment,
    required int previousBalance,
  }) async {
    _clearCheckout();

    final paymentId = payment.razorpayPaymentId;
    final signature = payment.razorpaySignature;
    final orderId = payment.razorpayOrderId.isNotEmpty
        ? payment.razorpayOrderId
        : order.razorpayOrderId;

    _setStage(CoinPurchaseStage.verifying, 'Verifying your payment…');
    final verifyResult = await _service.verifyPayment(
      userId: userId,
      razorpayOrderId: orderId,
      razorpayPaymentId: paymentId,
      razorpaySignature: signature,
    );

    if (!verifyResult.ok) {
      return PurchaseResult.failed(verifyResult.message);
    }

    var status = verifyResult.data!.status;

    // Signature is valid. Coins land when Razorpay's capture webhook fires,
    // so poll rather than claiming success straight away.
    if (!status.isCredited) {
      _setStage(CoinPurchaseStage.confirming, 'Crediting your coins…');
      status = await _pollUntilPaid(
        userId: userId,
        coinOrderId: verifyResult.data!.coinOrderId == 0
            ? order.coinOrderId
            : verifyResult.data!.coinOrderId,
        fallback: status,
      );
    } else {
      await refreshWallet();
    }

    final newBalance = balance.value;
    if (status.isCredited) {
      return PurchaseResult.success(
        creditsAdded: newBalance > previousBalance
            ? newBalance - previousBalance
            : order.coins,
        previousBalance: previousBalance,
        newBalance: newBalance,
        amountPaid: (order.amountPaise / 100).round(),
        package: selectedPackageOrNull,
      );
    }

    if (status == CoinOrderStatus.failed) {
      return PurchaseResult.failed(
        'The payment could not be completed. Any amount debited will be '
        'refunded automatically.',
      );
    }

    // Verified but not yet captured. This is a normal, non-error outcome.
    return PurchaseResult.pending(
      previousBalance: previousBalance,
      newBalance: newBalance,
      amountPaid: (order.amountPaise / 100).round(),
      package: selectedPackageOrNull,
      coinsExpected: order.coins,
    );
  }

  /// Refreshes wallet and order history until the order reads `paid`.
  ///
  /// Credit is completed by Razorpay's server-to-server webhook, so a few
  /// seconds of lag is expected rather than exceptional.
  Future<CoinOrderStatus> _pollUntilPaid({
    required String userId,
    required int coinOrderId,
    required CoinOrderStatus fallback,
  }) async {
    const delays = <Duration>[
      Duration(seconds: 2),
      Duration(seconds: 3),
      Duration(seconds: 4),
      Duration(seconds: 5),
    ];

    var status = fallback;
    for (final delay in delays) {
      await Future<void>.delayed(delay);

      final historyResult = await _service.fetchOrderHistory(userId: userId);
      if (historyResult.ok) {
        final rows = historyResult.data ?? const <CoinOrderHistoryItem>[];
        orderHistory.assignAll(rows);
        for (final row in rows) {
          if (row.id == coinOrderId) {
            status = row.status;
            break;
          }
        }
      }

      if (status.isCredited || status == CoinOrderStatus.failed) break;
    }

    await refreshWallet();
    return status;
  }

  PurchaseResult _finish(PurchaseResult result) {
    _clearCheckout();
    _setStage(CoinPurchaseStage.idle, '');
    return result;
  }

  void _setStage(CoinPurchaseStage next, String statusText) {
    stage.value = next;
    purchaseStatusText.value = statusText;
    isPurchasing.value = next != CoinPurchaseStage.idle;
  }

  // ------------------------------------------------------------- formatting

  static String formatCredits(int value) {
    final formatted = formatCreditsPlain(value);
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

/// Outcome of a purchase attempt, including the non-error "still crediting"
/// case the payment docs call out.
class PurchaseResult {
  const PurchaseResult._({
    required this.outcome,
    this.error,
    this.creditsAdded = 0,
    this.previousBalance = 0,
    this.newBalance = 0,
    this.amountPaid = 0,
    this.package,
    this.coinsExpected = 0,
    this.razorpayOrderId = '',
    this.razorpayPaymentId = '',
    this.razorpaySignature = '',
  });

  final PurchaseOutcome outcome;
  final String? error;
  final int creditsAdded;
  final int previousBalance;
  final int newBalance;
  final int amountPaid;
  final CreditPackage? package;

  /// Coins the order will credit once the capture webhook lands.
  final int coinsExpected;

  // Only populated between Razorpay success and server verification.
  final String razorpayOrderId;
  final String razorpayPaymentId;
  final String razorpaySignature;

  /// True only when coins are confirmed credited.
  bool get ok => outcome == PurchaseOutcome.success;

  bool get isPending => outcome == PurchaseOutcome.pending;

  bool get isCancelled => outcome == PurchaseOutcome.cancelled;

  factory PurchaseResult.success({
    required int creditsAdded,
    required int previousBalance,
    required int newBalance,
    required int amountPaid,
    CreditPackage? package,
  }) => PurchaseResult._(
    outcome: PurchaseOutcome.success,
    creditsAdded: creditsAdded,
    previousBalance: previousBalance,
    newBalance: newBalance,
    amountPaid: amountPaid,
    package: package,
  );

  factory PurchaseResult.pending({
    required int previousBalance,
    required int newBalance,
    required int amountPaid,
    required int coinsExpected,
    CreditPackage? package,
  }) => PurchaseResult._(
    outcome: PurchaseOutcome.pending,
    previousBalance: previousBalance,
    newBalance: newBalance,
    amountPaid: amountPaid,
    coinsExpected: coinsExpected,
    package: package,
  );

  factory PurchaseResult.failed(String error) =>
      PurchaseResult._(outcome: PurchaseOutcome.failed, error: error);

  factory PurchaseResult.cancelled() =>
      const PurchaseResult._(outcome: PurchaseOutcome.cancelled);

  factory PurchaseResult._checkoutSucceeded({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) => PurchaseResult._(
    outcome: PurchaseOutcome.success,
    razorpayOrderId: razorpayOrderId,
    razorpayPaymentId: razorpayPaymentId,
    razorpaySignature: razorpaySignature,
  );
}
