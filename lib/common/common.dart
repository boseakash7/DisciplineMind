import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';

import '../model/login_reponse_model.dart';
import '../services/local_db.dart';
import '../ui/auth/login_screen.dart';

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

  static void logout() {
    storage.clearLogin();
    Get.offAll(() => LoginScreen());
  }
}
