import 'package:discipline_mind/ui/common/app_in_app_webview_screen.dart';
import 'package:discipline_mind/ui/widgets/app_toast.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class AppUrlLauncher {
  static const String termsAndConditionsUrl =
      'https://disciplinedminds.in/terms-and-conditions';
  static const String privacyPolicyUrl =
      'https://disciplinedminds.in/privacy-policy';
  static const String riskDisclosureUrl =
      'https://disciplinedminds.in/risk-disclosure';

  /// Opens the given URL in an in-app WebView screen.
  static Future<void> openInAppWebView(
    String urlString, {
    String title = 'Details',
  }) async {
    try {
      final trimmed = urlString.trim();
      if (trimmed.isEmpty) return;

      // Open directly inside embedded AppInAppWebViewScreen
      Get.to(
        () => AppInAppWebViewScreen(
          url: trimmed,
          title: title,
        ),
      );
    } catch (e, stack) {
      debugPrint('Error opening in-app web view: $e\n$stack');
      try {
        await launchUrl(
          Uri.parse(urlString.trim()),
          mode: LaunchMode.externalApplication,
        );
      } catch (_) {
        AppToast.showToast('Could not open link');
      }
    }
  }

  static Future<void> openTermsAndConditions() async {
    await openInAppWebView(
      termsAndConditionsUrl,
      title: 'Terms & Conditions',
    );
  }

  static Future<void> openPrivacyPolicy() async {
    await openInAppWebView(
      privacyPolicyUrl,
      title: 'Privacy Policy',
    );
  }

  static Future<void> openRiskDisclosure() async {
    await openInAppWebView(
      riskDisclosureUrl,
      title: 'Risk Disclosure',
    );
  }
}
