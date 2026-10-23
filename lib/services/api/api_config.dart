import 'package:discipline_mind/common/common.dart';
import 'package:get_storage/get_storage.dart';

enum ApiEnvironment { v2Test, phase5 }

class ApiConfig {
  // Previous production URLs (kept commented for reference):
  // static const String _legacyV2TestUrl =
  //     "https://api.disciplinedminds.in/api/v2test/";
  // static const String _legacyPhase5Url = "https://api.disciplinedminds.in/api/";

  static const String _v2TestUrl =
      "https://staging-api.disciplinedminds.in/api/v2test/";
  static const String _phase5Url =
      "https://staging-api.disciplinedminds.in/api/";

  static String get v2TestBaseUrl => _v2TestUrl;
  static String get phase5BaseUrl => _phase5Url;

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
    // These endpoints previously used the /api/ family explicitly and must
    // keep that routing after centralization.
    const phase5Endpoints = [
      'voice-chat/ask',
      'diagnostic/upload-log',
      'notification/today',
    ];
    final isPhase5 = phase5Endpoints.any((e) => endpoint.contains(e));
    if (isPhase5) return _phase5Url;

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

  /// Builds every API URL from the centralized staging base URLs.
  ///
  /// [environment] is used only by intentional fallback calls that need to
  /// target a specific API generation.
  static String buildUrl(String endpoint, {ApiEnvironment? environment}) {
    // Keep compatibility for any non-API absolute URL passed by a caller.
    if (endpoint.startsWith('http://') || endpoint.startsWith('https://')) {
      return endpoint;
    }

    final baseUrl = switch (environment) {
      ApiEnvironment.v2Test => _v2TestUrl,
      ApiEnvironment.phase5 => _phase5Url,
      null => getBaseUrl(endpoint),
    };
    final normalizedEndpoint = endpoint.startsWith('/')
        ? endpoint.substring(1)
        : endpoint;
    return '$baseUrl$normalizedEndpoint';
  }

  static String get baseUrl => getBaseUrl("");

  static Map<String, String> defaultHeaders = {
    "Content-Type": "application/json",
  };
}
