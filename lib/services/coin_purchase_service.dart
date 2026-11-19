import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../model/coin_models.dart';
import 'api/api_reponse.dart';
import 'api/api_services.dart';
import 'api/api_url.dart';

/// Typed result wrapper so callers never have to unwrap `payload` themselves.
class CoinResult<T> {
  const CoinResult._({required this.ok, this.data, this.error});

  final bool ok;
  final T? data;
  final String? error;

  factory CoinResult.success(T data) => CoinResult._(ok: true, data: data);

  factory CoinResult.failure(String error) =>
      CoinResult._(ok: false, error: error);

  /// Error text safe to show the user.
  String get message => error ?? 'Something went wrong. Please try again.';
}

/// Thin, stateless wrapper over the coin purchase endpoints.
///
/// The shared [ApiService] already unwraps `{"status":"ok","payload":…}` and
/// turns `"status":"nok"` into an error carrying the payload string, so this
/// layer only has to pull `payload` out and map it onto a model.
class CoinPurchaseService {
  CoinPurchaseService({ApiService? api}) : _injected = api;

  final ApiService? _injected;

  ApiService get _api =>
      _injected ??
      (Get.isRegistered<ApiService>()
          ? Get.find<ApiService>()
          : Get.put(ApiService(), permanent: true));

  /// Pulls `payload` out of a successful envelope.
  static Object? _payloadOf(ApiResponse<dynamic> response) {
    final data = response.data;
    if (data is Map) return data['payload'];
    return null;
  }

  static CoinResult<T> _map<T>(
    ApiResponse<dynamic> response,
    String context,
    T Function(Object? payload) build,
  ) {
    if (!response.isSuccess) {
      return CoinResult<T>.failure(
        response.errorMessage ?? 'Something went wrong. Please try again.',
      );
    }
    try {
      return CoinResult<T>.success(build(_payloadOf(response)));
    } catch (e, stack) {
      debugPrint('[CoinPurchaseService] $context parse failed: $e\n$stack');
      return CoinResult<T>.failure('Unexpected response from server.');
    }
  }

  /// `GET /config/keys` — fallback source for the Razorpay public key.
  Future<CoinResult<RazorpayConfig>> fetchRazorpayConfig() async {
    final response = await _api.get(ApiUrl.configKeys);
    return _map(response, 'config/keys', (payload) {
      if (payload is! Map) return RazorpayConfig.empty;
      return RazorpayConfig.fromJson(Map<String, dynamic>.from(payload));
    });
  }

  /// `GET /coin-packages` — active packages only.
  Future<CoinResult<List<CoinPackage>>> fetchPackages() async {
    final response = await _api.get(ApiUrl.coinPackages);
    return _map(response, 'coin-packages', (payload) {
      if (payload is! List) return const <CoinPackage>[];
      return payload
          .whereType<Map>()
          .map((e) => CoinPackage.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    });
  }

  /// `POST /coin-coupons/apply` — price preview, creates no order.
  Future<CoinResult<CoinCouponPreview>> applyCoupon({
    required String userId,
    required int packageId,
    required String couponCode,
  }) async {
    final response = await _api.postJson(ApiUrl.coinCouponsApply, {
      'user_id': _numericUserId(userId),
      'package_id': packageId,
      'coupon_code': couponCode.trim(),
    });
    return _map(response, 'coin-coupons/apply', (payload) {
      if (payload is! Map) {
        throw const FormatException('coupon preview payload is not an object');
      }
      return CoinCouponPreview.fromJson(Map<String, dynamic>.from(payload));
    });
  }

  /// `POST /coin-orders/create`.
  ///
  /// Amount, coin count and discount are deliberately not sent — the backend
  /// recalculates them, so the client cannot influence the price.
  Future<CoinResult<CoinOrder>> createOrder({
    required String userId,
    required int packageId,
    String? couponCode,
  }) async {
    final code = couponCode?.trim() ?? '';
    final response = await _api.postJson(ApiUrl.coinOrdersCreate, {
      'user_id': _numericUserId(userId),
      'package_id': packageId,
      if (code.isNotEmpty) 'coupon_code': code,
    });
    return _map(response, 'coin-orders/create', (payload) {
      if (payload is! Map) {
        throw const FormatException('order payload is not an object');
      }
      return CoinOrder.fromJson(Map<String, dynamic>.from(payload));
    });
  }

  /// `POST /coin-orders/verify` — send the three Razorpay success values.
  Future<CoinResult<CoinVerifyResult>> verifyPayment({
    required String userId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    final response = await _api.postJson(ApiUrl.coinOrdersVerify, {
      'user_id': _numericUserId(userId),
      'razorpay_order_id': razorpayOrderId,
      'razorpay_payment_id': razorpayPaymentId,
      'razorpay_signature': razorpaySignature,
    });
    return _map(response, 'coin-orders/verify', (payload) {
      if (payload is! Map) {
        throw const FormatException('verify payload is not an object');
      }
      return CoinVerifyResult.fromJson(Map<String, dynamic>.from(payload));
    });
  }

  /// `GET /coins/wallet?user_id=` — balance plus ledger.
  Future<CoinResult<CoinWallet>> fetchWallet({required String userId}) async {
    final response = await _api.get(
      ApiUrl.coinsWallet,
      queryParameters: {'user_id': userId},
    );
    return _map(response, 'coins/wallet', (payload) {
      if (payload is! Map) return CoinWallet.empty;
      return CoinWallet.fromJson(Map<String, dynamic>.from(payload));
    });
  }

  /// `GET /coin-orders/history?user_id=`.
  Future<CoinResult<List<CoinOrderHistoryItem>>> fetchOrderHistory({
    required String userId,
  }) async {
    final response = await _api.get(
      ApiUrl.coinOrdersHistory,
      queryParameters: {'user_id': userId},
    );
    return _map(response, 'coin-orders/history', (payload) {
      if (payload is! List) return const <CoinOrderHistoryItem>[];
      return payload
          .whereType<Map>()
          .map(
            (e) => CoinOrderHistoryItem.fromJson(Map<String, dynamic>.from(e)),
          )
          .toList();
    });
  }

  /// The API examples send `user_id` as a number. Pass an int when the stored
  /// id is numeric, and fall back to the raw string otherwise.
  static Object _numericUserId(String userId) =>
      int.tryParse(userId.trim()) ?? userId.trim();
}
