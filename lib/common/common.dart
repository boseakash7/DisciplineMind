import 'dart:async';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../controller/alert_controller.dart';
import '../controller/chat_controller.dart';
import '../model/login_reponse_model.dart';
import '../services/api/api_services.dart';
import '../services/api/api_config.dart';
import '../services/local_db.dart';
import '../services/native_app_block_service.dart';
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

  static Future<String?>? _tokenRequest;
  static DateTime? _nextTokenAttempt;

  /// Share registration across startup, login and screen refreshes.
  static Future<String?> getFcmToken() async {
    final token = await (_tokenRequest ??= _fetchFcmToken());
    _tokenRequest = null;
    if (token != null) {
      await syncFcmTokenToServer(token);
      await NotificationHandler.subscribeToTradeAlerts();
    }
    return token;
  }

  static Future<String?> _fetchFcmToken() async {
    if (fcmToken.isNotEmpty) return fcmToken;
    if (_nextTokenAttempt != null &&
        DateTime.now().isBefore(_nextTokenAttempt!)) {
      return null;
    }
    try {
      if (Platform.isIOS) {
        final apns = await NotificationHandler.requestAndGetApnsToken();
        if (apns == null || apns.isEmpty) return null;
        apnsToken = apns;
        await GetStorage().write('ios_apns_token', apns);
      }
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return null;
      fcmToken = token;
      await GetStorage().write('fcm_token', token);
      return token;
    } catch (e) {
      print('[FCM] Registration unavailable; retry deferred: $e');
      return null;
    } finally {
      // Do not hammer registration when Firebase returns a server error.
      _nextTokenAttempt = DateTime.now().add(const Duration(minutes: 1));
    }
  }

  static bool _fcmSyncInFlight = false;
  static String? _lastSyncedToken;

  /// Syncs FCM token to server DB for currently logged-in user
  static Future<void> syncFcmTokenToServer([String? tokenToSync]) async {
    final token = tokenToSync ?? fcmToken;
    if (token.isEmpty) return;
    final userId =
        Common.userData.value?.payload?.id?.toString() ??
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
      print(
        "✅ [Common] Synced FCM token to server for user $userId (isSuccess: ${res.isSuccess})",
      );
      await NotificationHandler.subscribeToTradeAlerts();
    } catch (e) {
      print("❌ [Common] Failed to sync FCM token to server: $e");
    } finally {
      _fcmSyncInFlight = false;
    }
  }

  static Future<void> logout() async {
    // Clear local auth state and navigate before waiting on Firebase or native
    // cleanup. Those platform calls can stall when the device is offline.
    try {
      if (Get.isRegistered<ChatController>()) {
        Get.find<ChatController>().reset();
      }
      if (Get.isRegistered<AlertController>()) {
        Get.find<AlertController>().clear();
      }
    } catch (_) {}

    storage.clearLogin();
    userData.value = null;
    GetStorage().remove('user_id');
    ApiService.clearPersistedSessionCookie();
    ApiConfig.activeSetupType = null;

    try {
      await Get.deleteAll(force: true);
    } catch (_) {}

    Get.offAll(() => PhoneLoginScreen());

    // Best-effort cleanup must never keep the user on the signed-in screen.
    unawaited(
      NotificationHandler.unsubscribeFromTradeAlerts()
          .timeout(const Duration(seconds: 3))
          .catchError((Object error) {
            print('[Common] FCM topic cleanup timed out or failed: $error');
          }),
    );
    unawaited(
      NativeAppBlockService()
          .stopBlockingService()
          .timeout(const Duration(seconds: 3))
          .catchError((Object error) {
            print(
              '[Common] Blocking service cleanup timed out or failed: $error',
            );
            return false;
          }),
    );
  }
}
