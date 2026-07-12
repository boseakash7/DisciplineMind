import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

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

  static String fcmToken = "";
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

  static void logout() async {
    await NotificationHandler.unsubscribeFromTradeAlerts();
    storage.clearLogin();
    userData.value = null;
    GetStorage().remove('user_id');
    ApiService.clearPersistedSessionCookie();
    Get.offAll(() => PhoneLoginScreen());
  }
}
