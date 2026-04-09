import 'dart:io';

import 'package:discipline_mind/services/api/api_url.dart';
import 'package:discipline_mind/services/app_block_preferences_service.dart';
import 'package:discipline_mind/services/notification/notification_handler.dart';
import 'package:discipline_mind/services/trading_block_bootstrap.dart';
import 'package:discipline_mind/ui/main_home/main_home.dart';
import 'package:discipline_mind/ui/onboarding/post_login_trading_block_screen.dart';
import 'package:discipline_mind/ui/settings/app_block_settings_screen.dart';
import 'package:discipline_mind/ui/widgets/app_toast.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../common/common.dart';
import '../common/device_utils.dart';
import '../model/login_reponse_model.dart';
import '../services/api/api_reponse.dart';
import '../services/api/api_services.dart';
import '../services/local_db.dart';
import '../ui/auth/login_screen.dart';

class AuthController extends GetxController {
  var isLoading = false.obs;
  final ApiService apiService = Get.put(ApiService());
  final LocalStorageService storage = LocalStorageService();
  final AppBlockPreferencesService appBlockPrefs = AppBlockPreferencesService();

  Future<void> _navigateAfterLogin() async {
    final userId = Common.userData.value?.payload?.id?.toString();
    if (userId == null) {
      Get.offAll(() => MainHomeScreen(initialIndex: 2));
      return;
    }
    if (Platform.isAndroid && !await hasAndroidTradingBlockPermissions()) {
      Get.offAll(() => const PostLoginTradingBlockScreen());
      return;
    }
    if (appBlockPrefs.isSetupComplete(userId: userId)) {
      Get.offAll(() => MainHomeScreen(initialIndex: 2));
    } else {
      Get.offAll(() => const AppBlockSettingsScreen(isFirstSetup: true));
    }
  }

  void login(String email, String password, {bool isAutoLogin = false}) async {
    try {
      isLoading.value = true;

      // Call API
      ApiResponse response = await apiService.postFormData(ApiUrl.loginUrl, {
        "email": email,
        "password": password,
      });

      isLoading.value = false;

      if (response.isSuccess) {
        final userModel = LoginResponseModel.fromJson(response.data);
        Common.userData.value = userModel;
        if (!isAutoLogin) {
          storage.saveLogin(email, password);
        }
        // Store user_id for overlay to check alerts
        if (userModel.payload?.id != null) {
          GetStorage().write('user_id', userModel.payload!.id.toString());
        }

        // Sync FCM token with multipart (same as Postman) so backend saves to DB
        await Common.getFcmToken();
        if (Common.fcmToken.isNotEmpty) {
          await apiService.postMultipartForm(ApiUrl.fcmSync, {
            "user_id": userModel.payload!.id.toString(),
            "device_id": DeviceUtils.getDeviceId(),
            "token": Common.fcmToken,
          });
        }

        // Subscribe to trade_alerts notifications topic
        await NotificationHandler.subscribeToTradeAlerts();

        await _navigateAfterLogin();
      } else {
        AppToast.showToast(response.errorMessage ?? "Something went wrong");
        if (isAutoLogin) {
          // Auto-login failed -> clear saved creds and route to login.
          storage.clearLogin();
          GetStorage().remove('user_id');
          Get.offAll(() => LoginScreen());
        }
      }
    } catch (e) {
      isLoading.value = false;
      AppToast.showToast(e.toString());
      if (isAutoLogin) {
        storage.clearLogin();
        GetStorage().remove('user_id');
        Get.offAll(() => LoginScreen());
      }
    }
  }

  void autoLogin() {
    if (storage.hasLoginData()) {
      login(storage.getEmail()!, storage.getPassword()!, isAutoLogin: true);
    } else {
      Get.offAll(() => LoginScreen());
    }
  }

  void signUp({
    required String fullname,
    required String email,
    required String password,
    required String phone,
  }) async {
    try {
      isLoading.value = true;

      // Call API
      ApiResponse response = await apiService.postFormData(ApiUrl.signUpUrl, {
        "fullname": fullname,
        "email": email,
        "password": password,
        "phone": phone,
      });

      isLoading.value = false;

      if (response.isSuccess) {
        AppToast.showToast("Account created successfully!");
        // Navigate to login screen after signup
        Get.back();
      } else {
        AppToast.showToast(response.errorMessage ?? "Failed to create account");
      }
    } catch (e) {
      isLoading.value = false;
      AppToast.showToast(e.toString());
    }
  }

  void resetPassword() {
    Get.snackbar("Email Sent", "Check your inbox for the reset link.");
  }

  void logout() {
    storage.clearLogin();
    GetStorage().remove('user_id');
    Get.offAll(() => LoginScreen());
  }
}
