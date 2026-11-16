import 'package:discipline_mind/ui/android_app_block/mind_control_guard_consent_screen.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MindControlGuardConsent {
  static const _acceptedKey = 'mct_guard_consent_accepted';

  static Future<bool> isAccepted() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      return preferences.getBool(_acceptedKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Shows the acknowledgement once before iOS Screen Time protection starts.
  static Future<bool> ensureAccepted() async {
    if (await isAccepted()) return true;
    if (Get.context == null) return false;

    final accepted = await Get.to<bool>(
      () => MindControlGuardConsentScreen(
        onAgree: () => Get.back(result: true),
        onCancel: () => Get.back(result: false),
      ),
      fullscreenDialog: true,
    );
    if (accepted != true) return false;

    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setBool(_acceptedKey, true);
      return true;
    } catch (_) {
      return false;
    }
  }
}
