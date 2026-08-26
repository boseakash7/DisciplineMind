import 'package:discipline_mind/services/api/api_url.dart';
import 'package:discipline_mind/services/app_block_preferences_service.dart';
import 'package:discipline_mind/services/notification/notification_handler.dart';
import 'package:discipline_mind/ui/auth/phone_login_screen.dart';
import 'package:discipline_mind/ui/main_home/main_home.dart';
import 'package:discipline_mind/ui/widgets/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../common/common.dart';
import '../common/device_utils.dart';
import '../model/login_reponse_model.dart';
import '../model/otp_auth_models.dart';
import '../services/api/api_reponse.dart';
import '../services/api/api_services.dart';
import '../services/local_db.dart';

class AuthController extends GetxController {
  var isLoading = false.obs;
  final ApiService apiService = Get.put(ApiService());
  final LocalStorageService storage = LocalStorageService();
  final AppBlockPreferencesService appBlockPrefs = AppBlockPreferencesService();

  /// Backend expects phone without spaces (users sometimes type "03 12 ...").
  String _normalizePhone(String phone) => phone.replaceAll(RegExp(r'\s+'), '');

  Future<void> _navigateAfterLogin() async {
    Get.offAll(() => const MainHomeScreen(initialIndex: 2));
  }

Future<void> goToHomeAfterAuth() async {
  await _navigateAfterLogin();
}
  Future<void> _syncFcmAndSubscribe(String userId) async {
    await Common.getFcmToken();
    if (Common.fcmToken.isNotEmpty) {
      await apiService.postMultipartForm(ApiUrl.fcmSync, {
        "user_id": userId,
        "device_id": DeviceUtils.getDeviceId(),
        "token": Common.fcmToken,
      });
    }
    await NotificationHandler.subscribeToTradeAlerts();
  }

  /// Call after OTP verify (existing user) or when restoring a saved session.
  Future<void> applyLoggedInUser(
    LoginResponseModel model, {
    bool navigateAfterLogin = true,
  }) async {
    final id = model.payload?.id?.toString();
    if (id == null) {
      AppToast.showToast("Something went wrong");
      return;
    }
    print("User ID (Login): $id");
    Common.userData.value = model;
    storage.saveUserSession(model);
    GetStorage().write('user_id', id);
    try {
      await _syncFcmAndSubscribe(id);
    } catch (e, stack) {
      debugPrint('[AuthController] FCM sync error: $e\n$stack');
    }
    if (navigateAfterLogin) {
      await _navigateAfterLogin();
    }
  }

  Future<bool> sendOtp(String phone) async {
    try {
      isLoading.value = true;
      final ApiResponse response = await apiService.postFormData(
        ApiUrl.sendOtpUrl,
        {"phone": _normalizePhone(phone)},
      );
      isLoading.value = false;

      if (response.isSuccess) {
        final data = Map<String, dynamic>.from(response.data as Map);
        final parsed = SendOtpResponse.fromJson(data);
        final msg = parsed.payload?.message ?? "OTP sent successfully";
        AppToast.showToast(msg);
        return true;
      }
      AppToast.showToast(response.errorMessage ?? "Failed to send OTP");
      return false;
    } catch (e, stack) {
      isLoading.value = false;
      debugPrint('[AuthController] sendOtp error: $e\n$stack');
      AppToast.showToast("Failed to send OTP. Please try again.");
      return false;
    }
  }

  Future<VerifyOtpPayload?> verifyOtp(String phone, String otp) async {
    isLoading.value = true;
    try {
      final ApiResponse response = await apiService.postFormData(
        ApiUrl.verifyOtpUrl,
        {"phone": _normalizePhone(phone), "otp": otp},
      );

      if (!response.isSuccess) {
        AppToast.showToast(response.errorMessage ?? "Invalid OTP");
        isLoading.value = false;
        return null;
      }

      final data = Map<String, dynamic>.from(response.data as Map);
      final payload = VerifyOtpResponse.fromJson(data).payload;

      if (payload == null) {
        AppToast.showToast("Something went wrong. Please try again.");
        isLoading.value = false; // failure -> spinner turant band
        return null;
      }

      AppToast.showToast("OTP verified successfully");
      return payload;
    } catch (e, stack) {
      debugPrint('[AuthController] verifyOtp error: $e\n$stack');
      AppToast.showToast("Something went wrong. Please try again.");
      isLoading.value = false;
      return null;
    }
  }

  Future<void> autoLogin() async {
    final session = storage.getUserSession();
    if (session != null && session.payload?.id != null) {
      final id = session.payload!.id.toString();
      print("User ID (Auto Login): $id");
      Common.userData.value = session;
      GetStorage().write('user_id', id);
      try {
        await _syncFcmAndSubscribe(id);
      } catch (_) {}
      await _navigateAfterLogin();
    } else {
      Get.offAll(() => PhoneLoginScreen());
    }
  }

  void signUp({
    required String fullname,
    required String email,
    required String phone,
    String? password,
    bool navigateAfterLogin = true,  
  }) async {
    try {
      isLoading.value = true;

      final fields = <String, String>{
        "fullname": fullname,
        "email": email,
        "phone": _normalizePhone(phone),
      };
      final pwd = (password ?? '').trim();
      if (pwd.isNotEmpty) {
        fields["password"] = pwd;
      }

      final ApiResponse response = await apiService.postFormData(
        ApiUrl.signUpUrl,
        fields,
      );

      isLoading.value = false;

      if (response.isSuccess) {
        final raw = response.data;
        if (raw is! Map) {
          AppToast.showToast(
            "Account created, but login failed. Please login.",
          );
          Get.offAll(() => PhoneLoginScreen());
          return;
        }

        final data = Map<String, dynamic>.from(raw);
        final loginModel = LoginResponseModel.fromJson(data);
        if (loginModel.payload?.id == null || loginModel.payload!.id!.isEmpty) {
          AppToast.showToast(
            "Account created, but login failed. Please login.",
          );
          Get.offAll(() => PhoneLoginScreen());
          return;
        }

        AppToast.showToast("Account created successfully!");
        // await applyLoggedInUser(loginModel);
         await applyLoggedInUser(loginModel, navigateAfterLogin: navigateAfterLogin);
      } else {
        AppToast.showToast(response.errorMessage ?? "Failed to create account");
      }
    } catch (e, stack) {
      isLoading.value = false;
      debugPrint('[AuthController] signUp error: $e\n$stack');
      AppToast.showToast("Failed to create account. Please try again.");
    }
  }

  void logout() {
    storage.clearLogin();
    Common.userData.value = null;
    GetStorage().remove('user_id');
    ApiService.clearPersistedSessionCookie();
    Get.offAll(() => PhoneLoginScreen());
  }
}
