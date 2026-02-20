import 'dart:io';

import 'package:app_limiter/app_limiter.dart';
import 'package:discipline_mind/common/common.dart';
import 'package:discipline_mind/services/api/api_reponse.dart';
import 'package:discipline_mind/services/api/api_url.dart';
import 'package:discipline_mind/services/native_app_block_service.dart';
import 'package:discipline_mind/ui/widgets/app_toast.dart';
import 'package:get/get.dart';

import '../common/device_utils.dart';
import '../constants/blocked_apps.dart';
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
  final NativeAppBlockService _blockService = NativeAppBlockService();

  /// Trading apps to block when user sets a price alert (Zerodha Kite, Upstox, Groww)
  static const List<String> BLOCKED_TRADING_APP_PACKAGES =
      blockedTradingAppPackages;
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
      await Common.getFcmToken();
      final userId = Common.userData.value?.payload?.id?.toString();
      final token = Common.fcmToken;
      if (userId == null || userId.isEmpty || token.isEmpty) {
        return;
      }
      final deviceId = DeviceUtils.getDeviceId();
      // Use multipart/form-data to match Postman --form so backend saves FCM in DB
      ApiResponse response = await apiService.postMultipartForm(
        ApiUrl.fcmSync,
        {"user_id": userId, "device_id": deviceId, "token": token},
      );

      if (response.isSuccess) {
        // AppToast.showToast("FCM Token Synced Successfully ✅");
      } else {
        // AppToast.showToast(response.errorMessage ?? "Sync Failed ❌");
      }
    } catch (e) {
      // AppToast.showToast("Error: $e");
    }
  }

  /// Create 2 alerts at once: upper (above current) and lower (below current).
  Future<void> createAlertPair({
    required String instrument,
    required String upperPrice,
    required String lowerPrice,
    required double currentPrice,
  }) async {
    try {
      isSavingAlert.value = true;
      final userId = Common.userData.value?.payload?.id;
      if (userId == null) {
        AppToast.showToast("Please log in to create an alert");
        return;
      }
      await fetchUserAlerts(userId.toString());
      if (savedAlerts.isNotEmpty) {
        AppToast.showToast(
          "You already have active alerts. Delete them to add new ones.",
        );
        return;
      }
      final AppLimiter limiter = AppLimiter();

      // Create upper alert (price above current)
      final respUpper = await apiService.postFormData(ApiUrl.createAlertUrl, {
        'user_id': userId.toString(),
        'instrument': instrument,
        'price': upperPrice,
        'current_price': currentPrice.toString(),
      });
      // Create lower alert (price below current)
      final respLower = await apiService.postFormData(ApiUrl.createAlertUrl, {
        'user_id': userId.toString(),
        'instrument': instrument,
        'price': lowerPrice,
        'current_price': currentPrice.toString(),
      });

      bool success = false;
      if (Platform.isAndroid) {
        await _blockService.saveUserIdForOverlay(userId.toString());
        final perms = await _blockService.checkPermissions();
        if (perms['hasOverlayPermission'] != true) {
          await _blockService.requestOverlayPermission();
        }
        if (perms['hasUsageStatsPermission'] != true) {
          await _blockService.requestUsageStatsPermission();
        }
        for (final package in BLOCKED_TRADING_APP_PACKAGES) {
          final ok = await _blockService.blockApp(package);
          if (ok) success = true;
        }
        try {
          await _blockService.startBlockingService();
        } catch (e) {
          print('[AlertController] Failed to start blocking service: $e');
        }
      } else if (Platform.isIOS) {
        final permissionGranted = await limiter.requestIosPermission();
        if (!permissionGranted) {
          AppToast.showToast("iOS permission required to block apps");
          return;
        }
        await limiter.blockAndUnblockIOSApp();
        success = true;
      }

      if (success) {
        AppToast.showToast(
          "Trading apps (Zerodha, Upstox, Groww) have been blocked",
        );
      }
      if (respUpper.isSuccess && respLower.isSuccess) {
        AppToast.showToast("Alerts created successfully");
        fetchUserAlerts(userId.toString());
      } else {
        AppToast.showToast(
          respUpper.errorMessage ??
              respLower.errorMessage ??
              "Failed to create alerts",
        );
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

    final permissions = await _blockService.checkPermissions();
    final overlayGranted = permissions['hasOverlayPermission'] ?? false;
    final usageGranted = permissions['hasUsageStatsPermission'] ?? false;

    if (!overlayGranted) {
      await _blockService.requestOverlayPermission();
    }
    if (!usageGranted) {
      await _blockService.requestUsageStatsPermission();
    }

    final updated = await _blockService.checkPermissions();
    return (updated['hasOverlayPermission'] ?? false) &&
        (updated['hasUsageStatsPermission'] ?? false);
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
    await deleteAlerts([alertId]);
  }

  Future<void> deleteAlerts(List<String> alertIds) async {
    if (alertIds.isEmpty) return;
    try {
      isUserAlertLoading.value = true;
      bool allSuccess = true;
      for (final id in alertIds) {
        final response = await apiService.postFormData(ApiUrl.deleteAlert, {
          "id": id,
        });
        if (!response.isSuccess) allSuccess = false;
      }
      if (allSuccess) {
        AppToast.showToast("Alert${alertIds.length > 1 ? 's' : ''} deleted");
        if (Platform.isAndroid) {
          for (final package in BLOCKED_TRADING_APP_PACKAGES) {
            await _blockService.unblockApp(package);
          }
          AppToast.showToast("Trading apps unblocked");
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

  Future<void> fetchUserAlerts(String userId) async {
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
