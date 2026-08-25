import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../../common/common.dart';
import '../common/v2_common.dart';
import '../config/v2_api_config.dart';
import '../models/v2_otp_models.dart';
import '../models/v2_user_model.dart';
import '../services/v2_api_response.dart';
import '../services/v2_api_service.dart';
import '../services/v2_local_storage_service.dart';
import '../ui/auth/v2_login_screen.dart';
import '../ui/main_home/v2_main_home.dart';
import '../ui/widgets/v2_widgets.dart';

class V2AuthController extends GetxController {
  final isLoading = false.obs;
  final V2ApiService apiService = Get.isRegistered<V2ApiService>()
      ? Get.find<V2ApiService>()
      : Get.put(V2ApiService(), permanent: true);
  final V2LocalStorageService storage = V2LocalStorageService();

  String _normalizePhone(String phone) => phone.replaceAll(RegExp(r'\s+'), '');

  /// Set logged in user and navigate to v2 home
  Future<void> applyLoggedInUser(V2LoginResponseModel model) async {
    final id = model.payload?.id?.toString();
    if (id == null || id.isEmpty) {
      V2Toast.showToast("Login failed: missing user ID");
      return;
    }
    V2Common.userData.value = model;
    Common.userData.value = model.toLoginResponseModel();
    storage.saveUserSession(model);
    GetStorage().write('user_id', id);
    Get.offAll(() => const V2MainHomeScreen());
  }

  /// Auto login on app launch
  Future<void> autoLogin() async {
    try {
      final session = storage.getUserSession();
      if (session != null && session.payload?.id != null) {
        final id = session.payload!.id.toString();
        V2Common.userData.value = session;
        Common.userData.value = session.toLoginResponseModel();
        GetStorage().write('user_id', id);
        Get.offAll(() => const V2MainHomeScreen());
      } else {
        Get.offAll(() => const V2LoginScreen());
      }
    } catch (e) {
      if (kDebugMode) debugPrint("V2 autoLogin error: $e");
      Get.offAll(() => const V2LoginScreen());
    }
  }

  /// Send OTP to phone number
  Future<V2SendOtpPayload?> sendOtp(String phone) async {
    try {
      isLoading.value = true;
      final V2ApiResponse response = await apiService.postFormData(
        V2ApiConfig.sendOtpUrl,
        {"phone": _normalizePhone(phone)},
      );
      isLoading.value = false;

      if (response.isSuccess) {
        final data = Map<String, dynamic>.from(response.data as Map);
        final parsed = V2SendOtpResponse.fromJson(data);
        final msg = parsed.payload?.message ?? "OTP sent successfully";
        V2Toast.showToast(msg);
        return parsed.payload;
      }
      V2Toast.showToast(response.errorMessage ?? "Failed to send OTP");
      return null;
    } catch (e) {
      isLoading.value = false;
      V2Toast.showError(e);
      return null;
    }
  }

  /// Verify OTP
  Future<V2VerifyOtpPayload?> verifyOtp(String phone, String otp) async {
    try {
      isLoading.value = true;
      final V2ApiResponse response = await apiService.postFormData(
        V2ApiConfig.verifyOtpUrl,
        {
          "phone": _normalizePhone(phone),
          "otp": otp.trim(),
        },
      );
      isLoading.value = false;

      if (!response.isSuccess) {
        V2Toast.showToast(response.errorMessage ?? "Invalid OTP");
        return null;
      }

      final data = Map<String, dynamic>.from(response.data as Map);
      return V2VerifyOtpResponse.fromJson(data).payload;
    } catch (e) {
      isLoading.value = false;
      V2Toast.showError(e);
      return null;
    }
  }

  /// Login with email & password
  Future<bool> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      isLoading.value = true;
      final V2ApiResponse response = await apiService.postFormData(
        V2ApiConfig.loginUrl,
        {
          "email": email.trim(),
          "password": password.trim(),
        },
      );
      isLoading.value = false;

      if (response.isSuccess) {
        final data = Map<String, dynamic>.from(response.data as Map);
        final loginModel = V2LoginResponseModel.fromJson(data);
        if (loginModel.payload?.id != null) {
          V2Toast.showToast("Login successful!");
          await applyLoggedInUser(loginModel);
          return true;
        }
      }
      V2Toast.showToast(response.errorMessage ?? "Login failed. Check credentials.");
      return false;
    } catch (e) {
      isLoading.value = false;
      V2Toast.showError(e);
      return false;
    }
  }

  /// Register new user
  Future<bool> register({
    required String fullname,
    required String email,
    required String password,
    required String phone,
  }) async {
    try {
      isLoading.value = true;
      final V2ApiResponse response = await apiService.postFormData(
        V2ApiConfig.registerUrl,
        {
          "fullname": fullname.trim(),
          "email": email.trim(),
          "password": password.trim(),
          "phone": _normalizePhone(phone),
        },
      );
      isLoading.value = false;

      if (response.isSuccess) {
        final data = Map<String, dynamic>.from(response.data as Map);
        final loginModel = V2LoginResponseModel.fromJson(data);
        if (loginModel.payload?.id != null) {
          V2Toast.showToast("Account created successfully!");
          await applyLoggedInUser(loginModel);
          return true;
        }
      }
      V2Toast.showToast(response.errorMessage ?? "Registration failed");
      return false;
    } catch (e) {
      isLoading.value = false;
      V2Toast.showError(e);
      return false;
    }
  }

  /// Logout
  void logout() {
    storage.clearLogin();
    V2Common.userData.value = null;
    Common.userData.value = null;
    GetStorage().remove('user_id');
    V2ApiService.clearPersistedSessionCookie();
    Get.offAll(() => const V2LoginScreen());
  }
}
