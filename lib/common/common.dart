import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../controller/alert_controller.dart';
import '../controller/chat_controller.dart';
import '../model/login_reponse_model.dart';
import '../services/api/api_services.dart';
import '../services/api/api_url.dart';
import '../services/local_db.dart';
import '../services/notification/notification_handler.dart';
import '../ui/auth/phone_login_screen.dart';
import 'device_utils.dart';

class Common {
  static LocalStorageService storage = LocalStorageService();
  static Rx<LoginResponseModel?> userData = Rx<LoginResponseModel?>(null);
  void setUser(LoginResponseModel data) {
    userData.value = data;
  }

  static String fcmToken = "";
  LoginResponseModel? get currentUser => userData.value;
  static Future<void> getFcmToken() async {
    try {
      if (Platform.isIOS) {
        String? apnsToken = await FirebaseMessaging.instance.getAPNSToken();
        int attempts = 0;
        while (apnsToken == null && attempts < 15) {
          await Future.delayed(const Duration(milliseconds: 1000));
          apnsToken = await FirebaseMessaging.instance.getAPNSToken();
          attempts++;
        }
        if (apnsToken == null) {
          debugPrint('[FCM] APNS token not available after retries. Remote notifications may be delayed or unavailable.');
        } else {
          debugPrint('[FCM] APNS token acquired: $apnsToken');
        }
      }

      String? token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        fcmToken = token;
        debugPrint("[FCM] fcm token=$token");

        // Automatically sync to backend if user is logged in
        final userId = userData.value?.payload?.id?.toString() ??
            GetStorage().read('user_id')?.toString();
        if (userId != null && userId.isNotEmpty) {
          final deviceId = DeviceUtils.getDeviceId();
          ApiService().postMultipartForm(ApiUrl.fcmSync, {
            "user_id": userId,
            "device_id": deviceId,
            "token": token,
          }).then((res) {
            debugPrint('[FCM] Auto-sync fcmSync status: ${res.isSuccess}');
          });
          NotificationHandler.subscribeToTradeAlerts();
        }
      }
    } catch (e, stack) {
      debugPrint('[FCM] Error getting FCM token: $e\n$stack');
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
