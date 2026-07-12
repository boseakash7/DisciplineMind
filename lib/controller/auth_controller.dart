import 'dart:io';

import 'package:discipline_mind/services/api/api_url.dart';
import 'package:discipline_mind/services/app_block_preferences_service.dart';
import 'package:discipline_mind/services/notification/notification_handler.dart';
import 'package:discipline_mind/services/trading_block_bootstrap.dart';
import 'package:discipline_mind/ui/auth/phone_login_screen.dart';
import 'package:discipline_mind/ui/main_home/main_home.dart';
import 'package:discipline_mind/ui/onboarding/post_login_trading_block_screen.dart';
import 'package:discipline_mind/ui/settings/app_block_settings_screen.dart';
import 'package:discipline_mind/ui/widgets/app_toast.dart';
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
  Future<void> applyLoggedInUser(LoginResponseModel model) async {
    final id = model.payload?.id?.toString();
    if (id == null) {
      AppToast.showToast("Something went wrong");
      return;
    }
    Common.userData.value = model;
    storage.saveUserSession(model);
    GetStorage().write('user_id', id);
    try {
      await _syncFcmAndSubscribe(id);
    } catch (e) {
      AppToast.showError(e);
    }
    await _navigateAfterLogin();
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
    } catch (e) {
      isLoading.value = false;
      AppToast.showError(e);
      return false;
    }
  }

  Future<VerifyOtpPayload?> verifyOtp(String phone, String otp) async {
    try {
      isLoading.value = true;
      final ApiResponse response = await apiService.postFormData(
        ApiUrl.verifyOtpUrl,
        {"phone": _normalizePhone(phone), "otp": otp},
      );
      isLoading.value = false;

      if (!response.isSuccess) {
        AppToast.showToast(response.errorMessage ?? "Invalid OTP");
        return null;
      }
      final data = Map<String, dynamic>.from(response.data as Map);
      return VerifyOtpResponse.fromJson(data).payload;
    } catch (e) {
      isLoading.value = false;
      AppToast.showError(e);
      return null;
    }
  }

  Future<void> autoLogin() async {
    final session = storage.getUserSession();
    if (session != null && session.payload?.id != null) {
      Common.userData.value = session;
      GetStorage().write('user_id', session.payload!.id.toString());
      try {
        await _syncFcmAndSubscribe(session.payload!.id.toString());
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
        await applyLoggedInUser(loginModel);
      } else {
        AppToast.showToast(response.errorMessage ?? "Failed to create account");
      }
    } catch (e) {
      isLoading.value = false;
      AppToast.showError(e);
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
