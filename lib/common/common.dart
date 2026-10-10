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

class Common {
  static LocalStorageService storage = LocalStorageService();
  static Rx<LoginResponseModel?> userData = Rx<LoginResponseModel?>(null);
  void setUser(LoginResponseModel data) {
    userData.value = data;
  }

  static String apnsToken = "";
  static String fcmToken = "";
  LoginResponseModel? get currentUser => userData.value;
  static Future<void> getFcmToken() async {
    try {
      if (Platform.isIOS) {
        String? apns = await FirebaseMessaging.instance.getAPNSToken();
        if (apns == null) {
          for (var i = 0; i < 8; i++) {
            await Future.delayed(const Duration(milliseconds: 600));
            apns = await FirebaseMessaging.instance.getAPNSToken();
            if (apns != null) break;
          }
        }
        if (apns != null) {
          apnsToken = apns;
          final storage = GetStorage();
          await storage.write('ios_apns_token', apns);
          print("========================================");
          print("🔥 [Common] iOS APNs Token: $apns");
          print("========================================");
        }
      }
      String? token = await FirebaseMessaging.instance.getToken().timeout(
        const Duration(seconds: 8),
        onTimeout: () => null,
      );
      if (token != null) {
        fcmToken = token;
        final storage = GetStorage();
        await storage.write('fcm_token', token);
        print("🔥 [Common] FCM Token: $token");
      }
    } catch (e) {
      print("getFcmToken error: $e");
      fcmToken = "";
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
