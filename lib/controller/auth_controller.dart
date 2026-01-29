import 'package:discipline_mind/services/api/api_url.dart';
import 'package:discipline_mind/ui/main_home/main_home.dart';
import 'package:discipline_mind/ui/widgets/app_toast.dart';
import 'package:get/get.dart';

import '../common/common.dart';
import '../model/login_reponse_model.dart';
import '../services/api/api_reponse.dart';
import '../services/api/api_services.dart';
import '../services/local_db.dart';
import '../ui/auth/login_screen.dart';

class AuthController extends GetxController {
  var isLoading = false.obs;
  final ApiService apiService = Get.put(ApiService());
  final LocalStorageService storage = LocalStorageService();
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

        Get.offAll(() => MainHomeScreen());
      } else {
        AppToast.showToast(response.errorMessage ?? "Something went wrong");
      }
    } catch (e) {
      isLoading.value = false;
      AppToast.showToast(e.toString());
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
}
