import 'dart:io';

import 'package:app_limiter/app_limiter.dart';
import 'package:block_app/block_app.dart';
import 'package:discipline_mind/common/common.dart';
import 'package:discipline_mind/services/api/api_reponse.dart';
import 'package:discipline_mind/services/api/api_url.dart';
import 'package:discipline_mind/ui/widgets/app_toast.dart';
import 'package:get/get.dart';

import '../common/device_utils.dart';
import '../model/instrument_api_model.dart';
import '../model/instrument_detail_model.dart';
import '../model/user_alert_model.dart';
import '../services/api/api_services.dart';

class AlertController extends GetxController {
  var savedAlerts = <UserAlerts>[].obs;
  final ApiService apiService = Get.find<ApiService>();
  var isQuoteLoading = false.obs;
  var instrumentData = Rxn<InstrumentData>();
  var instruments = <Payload>[].obs;
  var isLoading = false.obs;
  var isSavingAlert = false.obs;
  var isUserAlertLoading = false.obs;
  final BlockApp _blockApp = BlockApp();
  static const BINANCE_PACKAGE = "com.binance.dev";
  @override
  void onInit() {
    super.onInit();
    fetchInstruments("");
    fetchUserAlerts(Common.userData.value!.payload!.id!);
    syncFcmToken();
  }

  void fetchInstruments(String query) async {
    try {
      isLoading.value = true;

      ApiResponse response = await apiService.get(
        ApiUrl.searchInstrument,
        queryParameters: {"query": query.isEmpty ? " " : query},
      );

      if (response.isSuccess) {
        final model = InstrumentApiModel.fromJson(response.data);
        instruments.assignAll(model.payload ?? []);
      } else {
        instruments.clear();
      }

      isLoading.value = false;
    } catch (e) {
      instruments.clear();
      isLoading.value = false;
    }
  }

  Future<void> syncFcmToken() async {
    try {
      final deviceId = DeviceUtils.getDeviceId();
      ApiResponse response = await apiService.postFormData(ApiUrl.fcmSync, {
        "user_id": Common.userData.value!.payload!.id!.toString(),
        "device_id": deviceId,
        "token": Common.fcmToken.toString(),
      });

      if (response.isSuccess) {
        // AppToast.showToast("FCM Token Synced Successfully ✅");
      } else {
        // AppToast.showToast(response.errorMessage ?? "Sync Failed ❌");
      }
    } catch (e) {
      // AppToast.showToast("Error: $e");
    }
  }

  Future<void> createAlert({
    required String instrument,
    required String price,
    required double currentPrice,
  }) async {
    try {
      isSavingAlert.value = true;
      final AppLimiter limiter = AppLimiter();
      // ---------------- API CALL ----------------
      final response = await apiService.postFormData(ApiUrl.createAlertUrl, {
        'user_id': Common.userData.value!.payload!.id.toString(),
        'instrument': instrument,
        'price': price,
        'current_price': currentPrice.toString(),
      });

      if (response.isSuccess) {
        AppToast.showToast("Alert created successfully");

        // ---------------- BLOCK BINANCE APP ----------------
        bool success = false;

        if (Platform.isAndroid) {
          success = await _blockApp.blockApp(BINANCE_PACKAGE);
        } else if (Platform.isIOS) {
          // ✅ iOS Block Flow

          // 1. Request ScreenTime Permission
          final permissionGranted = await limiter.requestIosPermission();

          if (!permissionGranted) {
            AppToast.showToast("iOS permission required to block apps");
            return;
          }

          // 2. Block App (ScreenTime Restriction)
          await limiter.blockAndUnblockIOSApp();

          success = true;
        }
        if (success) {
          AppToast.showToast("Binance app has been blocked");
        } else {
          AppToast.showToast("Failed to block Binance app");
        }
        fetchUserAlerts(Common.userData.value!.payload!.id!);
      } else {
        AppToast.showToast(response.errorMessage ?? "Failed to create alert");
      }
    } catch (e) {
      AppToast.showToast("Error: ${e.toString()}");
    } finally {
      isSavingAlert.value = false;
    }
  }

  // Future<void> createAlert({
  //   required String instrument,
  //   required String price,
  //   required double currentPrice,
  // }) async {
  //   try {
  //     isSavingAlert.value = true;

  //     final response = await apiService.postFormData(ApiUrl.createAlertUrl, {
  //       'user_id': Common.userData.value!.payload!.id.toString(),
  //       'instrument': instrument,
  //       'price': price,
  //       'current_price': currentPrice.toString(),
  //     });
  //     final success = await _blockApp.blockApp(BINANCE_PACKAGE);
  //     if (response.isSuccess) {
  //       AppToast.showToast("Alert created successfully");

  //       final success = await _blockApp.blockApp(BINANCE_PACKAGE);
  //       if (success) {
  //         AppToast.showToast("Binance app has been blocked");
  //       } else {
  //         AppToast.showToast("Failed to block Binance app");
  //       }
  //       fetchUserAlerts(Common.userData.value!.payload!.id!);
  //     } else {
  //       AppToast.showToast(response.errorMessage ?? "Failed to create alert");
  //     }
  //   } catch (e) {
  //     AppToast.showToast("Error: ${e.toString()}");
  //   } finally {
  //     isSavingAlert.value = false;
  //   }
  // }

  // Future<void> createAlert({
  //   required String instrument,
  //   required String price,
  //   required double currentPrice,
  // }) async {
  //   final userId = Common.userData.value!.payload!.id!;
  //   try {
  //     isSavingAlert.value = true;

  //     ApiResponse response = await apiService
  //         .postFormData(ApiUrl.createAlertUrl, {
  //           "user_id": userId.toString(),
  //           "instrument": instrument,
  //           "price": price,
  //           "current_price": currentPrice.toString(),
  //         });

  //     isSavingAlert.value = false;

  //     if (response.isSuccess) {
  //       AppToast.showToast("Alert saved successfully!");
  //       fetchUserAlerts(userId);
  //     } else {
  //       AppToast.showToast(response.errorMessage ?? "Failed to save alert");
  //     }
  //   } catch (e) {
  //     isSavingAlert.value = false;
  //     AppToast.showToast("Error: ${e.toString()}");
  //   }
  // }
  Future<bool> checkBlockAppPermissions() async {
    // ✅ iOS Permission Flow
    if (Platform.isIOS) {
      final AppLimiter limiter = AppLimiter();
      final granted = await limiter.requestIosPermission();

      if (!granted) {
        AppToast.showToast("iOS ScreenTime permission required");
        return false;
      }

      return true;
    }

    // ✅ Android Permission Flow (Same as before)
    final permissions = await _blockApp.checkPermissions();

    final overlayGranted = permissions['hasOverlayPermission'] ?? false;
    final usageGranted = permissions['hasUsageStatsPermission'] ?? false;

    if (!overlayGranted) {
      await _blockApp.requestOverlayPermission();
    }

    if (!usageGranted) {
      await _blockApp.requestUsageStatsPermission();
    }

    final updatedPermissions = await _blockApp.checkPermissions();

    return (updatedPermissions['hasOverlayPermission'] ?? false) &&
        (updatedPermissions['hasUsageStatsPermission'] ?? false);
  }

  // Future<bool> checkBlockAppPermissions() async {
  //   final permissions = await _blockApp.checkPermissions();
  //   final overlayGranted = permissions['hasOverlayPermission'] ?? false;
  //   final usageGranted = permissions['hasUsageStatsPermission'] ?? false;

  //   if (!overlayGranted) {
  //     await _blockApp.requestOverlayPermission();
  //   }
  //   if (!usageGranted) {
  //     await _blockApp.requestUsageStatsPermission();
  //   }

  //   final updatedPermissions = await _blockApp.checkPermissions();
  //   return (updatedPermissions['hasOverlayPermission'] ?? false) &&
  //       (updatedPermissions['hasUsageStatsPermission'] ?? false);
  // }

  Future<void> deleteAlert(String alertId) async {
    try {
      isUserAlertLoading.value = true;

      ApiResponse response = await apiService.postFormData(ApiUrl.deleteAlert, {
        "id": alertId,
      });

      if (response.isSuccess) {
        AppToast.showToast("Alert deleted");
        if (Platform.isAndroid) {
          final BlockApp blockApp = BlockApp();

          final success = await blockApp.unblockApp(BINANCE_PACKAGE);

          if (success) {
            AppToast.showToast("Binance unblocked");
          } else {
            AppToast.showToast("Failed to unblock Binance");
          }
        } else {
          final AppLimiter limiter = AppLimiter();
          await limiter.blockAndUnblockIOSApp();
        }

        fetchUserAlerts(Common.userData.value!.payload!.id!);
      } else {
        AppToast.showToast("Failed to delete alert");
      }

      isUserAlertLoading.value = false;
    } catch (e) {
      isUserAlertLoading.value = false;
      AppToast.showToast("Failed to delete alert");
    }
  }

  void fetchUserAlerts(String userId) async {
    try {
      isUserAlertLoading.value = true;

      ApiResponse response = await apiService.postFormData(
        ApiUrl.getAlertsByUser,
        {"user_id": userId},
      );

      if (response.isSuccess) {
        final model = UserAlertModel.fromJson(response.data);
        savedAlerts.assignAll(model.payload ?? []);
      } else {
        savedAlerts.clear();
      }

      isUserAlertLoading.value = false;
    } catch (e) {
      savedAlerts.clear();
      isUserAlertLoading.value = false;
    }
  }

  Future<void> fetchInstrumentQuote(String instrument) async {
    try {
      isQuoteLoading.value = true;

      ApiResponse response = await apiService.get(
        ApiUrl.quoteUrl,
        queryParameters: {"instrument": instrument},
      );

      isQuoteLoading.value = false;

      if (response.isSuccess) {
        final model = InstrumentDetailModel.fromJson(response.data);
        final data = model.payload?.instruments?[instrument];

        if (data != null) {
          instrumentData.value = data;
          // livePrice.value = data.lastPrice ?? 0.0;
        } else {
          // livePrice.value = 0.0;
          AppToast.showToast("Instrument not found in response");
          // Get.snackbar("Error", "Instrument not found in response");
        }
      } else {
        AppToast.showToast(response.errorMessage ?? "Quote fetch failed");
      }
    } catch (e) {
      isQuoteLoading.value = false;
      AppToast.showToast(e.toString());
    }
  }

  // void addAlert(
  //   String symbol,
  //   String company,
  //   String targetPrice,
  //   double currentPrice,
  // ) {
  //   savedAlerts.add(
  //     StockAlert(
  //       symbol: symbol,
  //       company: company,
  //       targetPrice: double.parse(targetPrice),
  //       currentPrice: currentPrice,
  //     ),
  //   );
  // }
}
