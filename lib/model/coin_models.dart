/// Data transfer objects for the coin purchase APIs.
///
/// Every amount the backend sends is in **paise**. Converting to rupees
/// happens here and nowhere else, so no caller can divide by 100 twice.
library;

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString().trim() ?? '') ?? 0;
}

String _asString(Object? value) => value?.toString().trim() ?? '';

Map<String, dynamic>? _asMap(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : null;

/// Rupee text for an amount in paise, without trailing `.00`.
String formatPaise(int paise) {
  final rupees = paise / 100;
  final text = rupees.truncateToDouble() == rupees
      ? rupees.toInt().toString()
      : rupees.toStringAsFixed(2);
  return '₹$text';
}

/// A purchasable coin package.
class CoinPackage {
  const CoinPackage({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.coins,
    required this.pricePaise,
    required this.currency,
  });

  final int id;
  final String code;
  final String name;
  final String description;
  final int coins;
  final int pricePaise;
  final String currency;

  /// Whole-rupee price, for UI that works in rupees.
  int get priceRupees => (pricePaise / 100).round();

  factory CoinPackage.fromJson(Map<String, dynamic> json) => CoinPackage(
    id: _asInt(json['id']),
    code: _asString(json['code']),
    name: _asString(json['name']),
    description: _asString(json['description']),
    coins: _asInt(json['coins']),
    pricePaise: _asInt(json['price_paise']),
    currency: _asString(json['currency']).isEmpty
        ? 'INR'
        : _asString(json['currency']),
  );
}

/// Coupon as returned by the apply/create endpoints.
class CoinCoupon {
  const CoinCoupon({
    required this.id,
    required this.code,
    required this.discountType,
    required this.discountValue,
  });

  final int id;
  final String code;

  /// `percentage` or `flat`, as sent by the backend.
  final String discountType;
  final num discountValue;

  bool get isPercentage => discountType.toLowerCase() == 'percentage';

  /// Short label for a chip, e.g. `10% OFF` or `₹200 OFF`.
  String get badgeLabel {
    if (discountValue <= 0) return code;
    if (isPercentage) {
      final v = discountValue == discountValue.roundToDouble()
          ? discountValue.toInt().toString()
          : discountValue.toString();
      return '$v% OFF';
    }
    return '${formatPaise(discountValue.toInt())} OFF';
  }

  factory CoinCoupon.fromJson(Map<String, dynamic> json) => CoinCoupon(
    id: _asInt(json['id']),
    code: _asString(json['code']),
    discountType: _asString(json['discount_type']),
    discountValue: json['discount_value'] is num
        ? json['discount_value'] as num
        : num.tryParse(_asString(json['discount_value'])) ?? 0,
  );
}

/// Result of `POST /coin-coupons/apply`. Preview only — no order is created.
class CoinCouponPreview {
  const CoinCouponPreview({
    required this.package,
    required this.coupon,
    required this.originalAmountPaise,
    required this.discountPaise,
    required this.finalAmountPaise,
    required this.currency,
  });

  final CoinPackage? package;
  final CoinCoupon? coupon;
  final int originalAmountPaise;
  final int discountPaise;
  final int finalAmountPaise;
  final String currency;

  factory CoinCouponPreview.fromJson(Map<String, dynamic> json) {
    final packageJson = _asMap(json['package']);
    final couponJson = _asMap(json['coupon']);
    return CoinCouponPreview(
      package: packageJson == null ? null : CoinPackage.fromJson(packageJson),
      coupon: couponJson == null ? null : CoinCoupon.fromJson(couponJson),
      originalAmountPaise: _asInt(json['original_amount_paise']),
      discountPaise: _asInt(json['discount_paise']),
      finalAmountPaise: _asInt(json['final_amount_paise']),
      currency: _asString(json['currency']).isEmpty
          ? 'INR'
          : _asString(json['currency']),
    );
  }
}

/// Result of `POST /coin-orders/create`; everything Razorpay Checkout needs.
class CoinOrder {
  const CoinOrder({
    required this.coinOrderId,
    required this.razorpayOrderId,
    required this.razorpayKeyId,
    required this.razorpayMode,
    required this.amountPaise,
    required this.currency,
    required this.coins,
    required this.package,
    required this.coupon,
    required this.checkoutName,
    required this.checkoutDescription,
  });

  final int coinOrderId;
  final String razorpayOrderId;
  final String razorpayKeyId;
  final String razorpayMode;
  final int amountPaise;
  final String currency;
  final int coins;
  final CoinPackage? package;
  final CoinCoupon? coupon;
  final String checkoutName;
  final String checkoutDescription;

  bool get isUsable =>
      razorpayOrderId.isNotEmpty && razorpayKeyId.isNotEmpty && amountPaise > 0;

  factory CoinOrder.fromJson(Map<String, dynamic> json) {
    final checkout = _asMap(json['checkout']) ?? const <String, dynamic>{};
    final packageJson = _asMap(json['package']);
    final couponJson = _asMap(json['coupon']);
    return CoinOrder(
      coinOrderId: _asInt(json['coin_order_id']),
      razorpayOrderId: _asString(json['razorpay_order_id']),
      razorpayKeyId: _asString(json['razorpay_key_id']),
      razorpayMode: _asString(json['razorpay_mode']),
      amountPaise: _asInt(json['amount_paise']),
      currency: _asString(json['currency']).isEmpty
          ? 'INR'
          : _asString(json['currency']),
      coins: _asInt(json['coins']),
      package: packageJson == null ? null : CoinPackage.fromJson(packageJson),
      coupon: couponJson == null ? null : CoinCoupon.fromJson(couponJson),
      checkoutName: _asString(checkout['name']),
      checkoutDescription: _asString(checkout['description']),
    );
  }
}

/// Lifecycle of a coin order, per the API docs.
enum CoinOrderStatus {
  /// Backend order created; checkout may still be pending.
  created,

  /// Signature verified; waiting on Razorpay capture before coins land.
  verifiedPendingCapture,

  /// Captured and credited.
  paid,

  /// Order or payment failed.
  failed,

  /// Anything the backend adds later.
  unknown;

  static CoinOrderStatus parse(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'created':
        return CoinOrderStatus.created;
      case 'verified_pending_capture':
        return CoinOrderStatus.verifiedPendingCapture;
      case 'paid':
        return CoinOrderStatus.paid;
      case 'failed':
        return CoinOrderStatus.failed;
      default:
        return CoinOrderStatus.unknown;
    }
  }

  /// Coins are only guaranteed credited once the order is `paid`.
  bool get isCredited => this == CoinOrderStatus.paid;

  /// Still moving: keep polling rather than declaring success or failure.
  bool get isPending =>
      this == CoinOrderStatus.created ||
      this == CoinOrderStatus.verifiedPendingCapture;
}

/// Result of `POST /coin-orders/verify`.
class CoinVerifyResult {
  const CoinVerifyResult({
    required this.coinOrderId,
    required this.status,
    required this.message,
  });

  final int coinOrderId;
  final CoinOrderStatus status;
  final String message;

  factory CoinVerifyResult.fromJson(Map<String, dynamic> json) =>
      CoinVerifyResult(
        coinOrderId: _asInt(json['coin_order_id']),
        status: CoinOrderStatus.parse(_asString(json['status'])),
        message: _asString(json['message']),
      );
}

/// One row of the coin ledger.
class CoinTransaction {
  const CoinTransaction({
    required this.id,
    required this.coins,
    required this.transactionType,
    required this.source,
    required this.coinOrderId,
    required this.balanceBefore,
    required this.balanceAfter,
    required this.createdAt,
  });

  final int id;
  final int coins;

  /// `credit` or `debit`.
  final String transactionType;
  final String source;
  final int coinOrderId;
  final int balanceBefore;
  final int balanceAfter;
  final DateTime createdAt;

  bool get isCredit => transactionType.toLowerCase() != 'debit';

  /// Signed amount, so history can render `+100` / `-150`.
  int get signedCoins => isCredit ? coins.abs() : -coins.abs();

  factory CoinTransaction.fromJson(Map<String, dynamic> json) =>
      CoinTransaction(
        id: _asInt(json['id']),
        coins: _asInt(json['coins']),
        transactionType: _asString(json['transaction_type']),
        source: _asString(json['source']),
        coinOrderId: _asInt(json['coin_order_id']),
        balanceBefore: _asInt(json['balance_before']),
        balanceAfter: _asInt(json['balance_after']),
        // `created_at` is Unix seconds.
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          _asInt(json['created_at']) * 1000,
        ),
      );
}

/// Result of `GET /coins/wallet`.
class CoinWallet {
  const CoinWallet({
    required this.userId,
    required this.coinBalance,
    required this.transactions,
  });

  final int userId;
  final int coinBalance;
  final List<CoinTransaction> transactions;

  static const CoinWallet empty = CoinWallet(
    userId: 0,
    coinBalance: 0,
    transactions: <CoinTransaction>[],
  );

  factory CoinWallet.fromJson(Map<String, dynamic> json) {
    final rows = json['transactions'];
    return CoinWallet(
      userId: _asInt(json['user_id']),
      coinBalance: _asInt(json['coin_balance']),
      transactions: rows is List
          ? rows
                .whereType<Map>()
                .map((e) => CoinTransaction.fromJson(Map<String, dynamic>.from(e)))
                .toList()
          : const <CoinTransaction>[],
    );
  }
}

/// One row of `GET /coin-orders/history`.
class CoinOrderHistoryItem {
  const CoinOrderHistoryItem({
    required this.id,
    required this.packageName,
    required this.coins,
    required this.originalAmountPaise,
    required this.discountPaise,
    required this.finalAmountPaise,
    required this.currency,
    required this.razorpayOrderId,
    required this.razorpayPaymentId,
    required this.status,
    required this.failureReason,
    required this.paidAt,
    required this.createdAt,
  });

  final int id;
  final String packageName;
  final int coins;
  final int originalAmountPaise;
  final int discountPaise;
  final int finalAmountPaise;
  final String currency;
  final String razorpayOrderId;
  final String razorpayPaymentId;
  final CoinOrderStatus status;
  final String? failureReason;
  final DateTime? paidAt;
  final DateTime createdAt;

  factory CoinOrderHistoryItem.fromJson(Map<String, dynamic> json) {
    DateTime? at(Object? value) {
      final seconds = _asInt(value);
      if (seconds <= 0) return null;
      return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
    }

    final reason = _asString(json['failure_reason']);
    return CoinOrderHistoryItem(
      id: _asInt(json['id']),
      packageName: _asString(json['package_name']),
      coins: _asInt(json['coins']),
      originalAmountPaise: _asInt(json['original_amount_paise']),
      discountPaise: _asInt(json['discount_paise']),
      finalAmountPaise: _asInt(json['final_amount_paise']),
      currency: _asString(json['currency']).isEmpty
          ? 'INR'
          : _asString(json['currency']),
      razorpayOrderId: _asString(json['razorpay_order_id']),
      razorpayPaymentId: _asString(json['razorpay_payment_id']),
      status: CoinOrderStatus.parse(_asString(json['status'])),
      failureReason: reason.isEmpty || reason == 'null' ? null : reason,
      paidAt: at(json['paid_at']),
      createdAt: at(json['created_at']) ?? DateTime.now(),
    );
  }
}

/// Razorpay public config from `GET /config/keys`.
class RazorpayConfig {
  const RazorpayConfig({required this.keyId, required this.mode});

  final String keyId;
  final String mode;

  bool get isUsable => keyId.isNotEmpty;

  static const RazorpayConfig empty = RazorpayConfig(keyId: '', mode: '');

  factory RazorpayConfig.fromJson(Map<String, dynamic> json) => RazorpayConfig(
    keyId: _asString(json['razorpay_key_id']),
    mode: _asString(json['razorpay_mode']),
  );
}
