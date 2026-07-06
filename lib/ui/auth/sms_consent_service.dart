import 'dart:async';
import 'package:flutter/services.dart';

class SmsConsentService {
  static const _methodChannel = MethodChannel('sms_consent/method');
  static const _eventChannel = EventChannel('sms_consent/event');

  StreamSubscription? _subscription;

  Future<void> startListening({
    required void Function(String otp) onOtpReceived,
    void Function(Object error)? onError,
    int otpLength = 4,
  }) async {
    await _methodChannel.invokeMethod('startListening');

    _subscription?.cancel();
    _subscription = _eventChannel.receiveBroadcastStream().listen(
      (dynamic smsBody) {
        if (smsBody == null) return;
        final otp = _extractOtp(smsBody.toString(), otpLength);
        if (otp != null) onOtpReceived(otp);
      },
      onError: (error) => onError?.call(error),
    );
  }

  Future<void> stopListening() async {
    await _subscription?.cancel();
    _subscription = null;
    try {
      await _methodChannel.invokeMethod('stopListening');
    } catch (_) {}
  }

  String? _extractOtp(String smsBody, int otpLength) {
    final regex = RegExp(r'\d{' + otpLength.toString() + r'}');
    return regex.firstMatch(smsBody)?.group(0);
  }
}