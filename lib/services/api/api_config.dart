import 'package:discipline_mind/common/common.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String _defaultApiUrl =
      "https://api.disciplinedminds.in/api/v2test/";
  static const String _defaultPhase5ApiUrl =
      "https://api.disciplinedminds.in/api/";

  /// Each flavor has its own Dart define file. The values are currently the
  /// same for staging and production and can be changed independently later.
  static const String _v2TestUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: _defaultApiUrl,
  );
  static const String _phase5Url = String.fromEnvironment(
    'PHASE5_API_BASE_URL',
    defaultValue: _defaultPhase5ApiUrl,
  );

  static String? activeSetupType;

  static bool get isZenoAi {
    String? setupType =
        activeSetupType ?? Common.userData.value?.payload?.tradingSetupType;
    if (setupType == null) {
      final storedData = GetStorage().read<Map<String, dynamic>>('userData');
      if (storedData != null && storedData['payload'] != null) {
        setupType = storedData['payload']['trading_setup_type']?.toString();
      }
    }
    return setupType == 'zeno_ai_signals';
  }

  static String getBaseUrl(String endpoint) {
    // These APIs are core to the new flow and must ALWAYS use v2test
    const v2Endpoints = [
      'user/send-otp',
      'user/verify-otp',
      'user/register',
      'user/login',
      'process/setup',
      'process/fetch',
      'process/edit',
      'user/mind-control-active',
    ];

    final isV2 = v2Endpoints.any((e) => endpoint.contains(e));
    if (isV2) return _v2TestUrl;

    return isZenoAi ? _phase5Url : _v2TestUrl;
  }

  static String get baseUrl => getBaseUrl("");

  static Map<String, String> defaultHeaders = {
    "Content-Type": "application/json",
  };

  static String get flavor => const String.fromEnvironment(
    'APP_FLAVOR',
    defaultValue: kReleaseMode ? 'production' : 'staging',
  );
}
