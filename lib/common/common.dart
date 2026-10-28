import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../controller/alert_controller.dart';
import '../controller/chat_controller.dart';
import '../model/login_reponse_model.dart';
import '../services/api/api_services.dart';
import '../services/api/api_config.dart';
import '../services/api/api_url.dart';
import '../services/local_db.dart';
import '../services/notification/notification_handler.dart';
import '../ui/auth/phone_login_screen.dart';

class Common {
  static LocalStorageService storage = LocalStorageService();
  static Rx<LoginResponseModel?> userData = Rx<LoginResponseModel?>(null);
  void setUser(LoginResponseModel data) {
    userData.value = data;
  }

  static String fcmToken = "";
  static bool _isLoggingOut = false;
  static final RxBool isLoggingOut = false.obs;
  LoginResponseModel? get currentUser => userData.value;
  static Future<void> getFcmToken() async {
    try {
      String? token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        fcmToken = token;
        print("fcm token=$token");
      }
    } catch (e) {
      fcmToken = "";
    }
  }

  /// Invalidate the backend session before clearing the local session.
  ///
  /// Local logout must still complete when the request fails, so this is
  /// intentionally best-effort.
  static Future<void> notifyBackendLogout() async {
    final userId =
        userData.value?.payload?.id?.toString() ??
        GetStorage().read('user_id')?.toString();
    if (userId == null || userId.isEmpty) return;

    final requestUrl = ApiConfig.buildUrl(ApiUrl.logoutUrl);
    debugPrint('[Logout API] POST $requestUrl');
    try {
      final response = await ApiService().postFormData(
        ApiUrl.logoutUrl,
        {'user_id': userId},
      );
      debugPrint(
        '[Logout API] Response: success=${response.isSuccess}, '
        'data=${response.data}, error=${response.errorMessage}',
      );
    } catch (_) {
      debugPrint('[Logout API] Request failed');
      // ApiService already converts request failures to ApiResponse errors.
      // Never block local logout because the backend is unavailable.
    }
  }

  static Future<void> logout() async {
    if (_isLoggingOut) return;
    _isLoggingOut = true;
    isLoggingOut.value = true;

    try {
      await notifyBackendLogout();
      await NotificationHandler.unsubscribeFromTradeAlerts();
      if (Get.isRegistered<ChatController>()) {
        Get.find<ChatController>().reset();
      }
      if (Get.isRegistered<AlertController>()) {
        Get.find<AlertController>().clear();
      }
      Get.deleteAll(force: true);
      storage.clearLogin();
      userData.value = null;
      GetStorage().remove('user_id');
      ApiService.clearPersistedSessionCookie();
    } finally {
      isLoggingOut.value = false;
      _isLoggingOut = false;
    }

    Get.offAll(() => PhoneLoginScreen());
  }
}
