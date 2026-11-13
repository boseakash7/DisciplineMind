import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../controller/alert_controller.dart';
import '../controller/chat_controller.dart';
import '../model/login_reponse_model.dart';
import '../services/api/api_services.dart';
import '../services/local_db.dart';
import '../services/notification/notification_handler.dart';
import '../ui/auth/phone_login_screen.dart';

import '../common/device_utils.dart';
import '../services/api/api_url.dart';

class Common {
  static LocalStorageService storage = LocalStorageService();
  static Rx<LoginResponseModel?> userData = Rx<LoginResponseModel?>(null);
  void setUser(LoginResponseModel data) {
    userData.value = data;
  }

  static String apnsToken = "";
  static String fcmToken = "";
  LoginResponseModel? get currentUser => userData.value;

  /// Fetch APNs and FCM tokens and automatically sync to server if user is logged in
  static Future<String?> getFcmToken() async {
    try {
      if (Platform.isIOS) {
        String? apns = await FirebaseMessaging.instance.getAPNSToken();
        if (apns == null) {
          print("⏳ [Common] Waiting for iOS APNs token...");
          for (var i = 0; i < 15; i++) {
            await Future.delayed(const Duration(milliseconds: 800));
            apns = await FirebaseMessaging.instance.getAPNSToken();
            if (apns != null && apns.isNotEmpty) break;
          }
        }
        if (apns != null && apns.isNotEmpty) {
          apnsToken = apns;
          final storage = GetStorage();
          await storage.write('ios_apns_token', apns);
          print("========================================");
          print("🔥 [Common] iOS APNs Token: $apns");
          print("========================================");
        } else {
          print("⚠️ [Common] APNs Token is not yet available; deferring FCM fetch to onTokenRefresh.");
          return null;
        }
      }

      String? token = await FirebaseMessaging.instance.getToken().timeout(
        const Duration(seconds: 10),
        onTimeout: () => null,
      );

      if (token != null && token.isNotEmpty) {
        fcmToken = token;
        final storage = GetStorage();
        await storage.write('fcm_token', token);
        print("🔥 [Common] FCM Token: $token");
        await syncFcmTokenToServer(token);
        return token;
      }
    } catch (e) {
      print("getFcmToken error: $e");
    }
    return null;
  }

  static bool _fcmSyncInFlight = false;
  static String? _lastSyncedToken;

  /// Syncs FCM token to server DB for currently logged-in user
  static Future<void> syncFcmTokenToServer([String? tokenToSync]) async {
    final token = tokenToSync ?? fcmToken;
    if (token.isEmpty) return;
    final userId = Common.userData.value?.payload?.id?.toString() ??
        GetStorage().read<String>('user_id');
    if (userId == null || userId.isEmpty) return;
    if (_fcmSyncInFlight || _lastSyncedToken == token) return;
    _fcmSyncInFlight = true;

    try {
      final api = Get.isRegistered<ApiService>()
          ? Get.find<ApiService>()
          : ApiService();
      final res = await api.postMultipartForm(ApiUrl.fcmSync, {
        "user_id": userId,
        "device_id": DeviceUtils.getDeviceId(),
        "token": token,
      });
      if (res.isSuccess) {
        _lastSyncedToken = token;
      }
      print("✅ [Common] Synced FCM token to server for user $userId (isSuccess: ${res.isSuccess})");
      await NotificationHandler.subscribeToTradeAlerts();
    } catch (e) {
      print("❌ [Common] Failed to sync FCM token to server: $e");
    } finally {
      _fcmSyncInFlight = false;
    }
  }

  static void logout() async {
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
    Get.offAll(() => PhoneLoginScreen());
  }
}
