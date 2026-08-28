import 'dart:io';

import 'package:app_limiter/app_limiter.dart';
import 'package:discipline_mind/common/common.dart';
import 'package:discipline_mind/services/api/api_reponse.dart';
import 'package:discipline_mind/services/api/api_url.dart';
import 'package:discipline_mind/services/app_block_preferences_service.dart';
import 'package:discipline_mind/services/native_app_block_service.dart';
import 'package:discipline_mind/ui/widgets/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../common/device_utils.dart';
import '../controller/chat_controller.dart';
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
  final AppBlockPreferencesService _prefs = AppBlockPreferencesService();

  List<String> _selectedBlockedPackages() {
    final userId = Common.userData.value?.payload?.id?.toString();
    if (userId == null || userId.isEmpty) {
      return [];
    }
    return _prefs.getSelectedPackages(userId: userId);
  }
  @override
  void onInit() {
    super.onInit();
    fetchInstruments("");
    final userId = Common.userData.value?.payload?.id;
    if (userId != null && userId.isNotEmpty) {
      fetchUserAlerts(userId);
    }
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
    } catch (e, stack) {
      debugPrint('[AlertController] fetchInstruments error: $e\n$stack');
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
    } catch (e, stack) {
      debugPrint('[AlertController] syncFcmToken error: $e\n$stack');
    }
  }

  /// Create 1 trade alert with upper_price and lower_price (no price).
  /// Returns true on success.
  Future<bool> createTradeAlert({
    required String instrument,
    required String upperPrice,
    required String lowerPrice,
    required double currentPrice,
    String? tradeId,
  }) async {
    try {
      isSavingAlert.value = true;
      final userId = Common.userData.value?.payload?.id;
      if (userId == null) {
        AppToast.showToast("Please log in to create an alert");
        return false;
      }
      final hasPermissions = await checkBlockAppPermissions();
      if (!hasPermissions) {
        // Permission denied: do not call alert/create API.
        return false;
      }
      await fetchUserAlerts(userId.toString());
      final hasPending =
          // false;
          savedAlerts.any((a) => (a.status ?? '').toLowerCase() == 'pending');
      if (hasPending) {
        AppToast.showToast(
          "You have a pending trade. Complete or delete it before adding a new one.",
        );
        return false;
      }
      final response = await apiService.postFormData(ApiUrl.createAlertUrl, {
        'user_id': userId.toString(),
        'instrument': instrument,
        'upper_price': upperPrice,
        'lower_price': lowerPrice,
        'current_price': currentPrice.toString(),
        if (tradeId != null && tradeId.isNotEmpty) 'trade_id': tradeId,
      });

      if (response.isSuccess) {
        AppToast.showToast("Alert created successfully");
        fetchUserAlerts(userId.toString());
        // Block trading apps
        if (Platform.isAndroid) {
          await _blockService.saveUserIdForOverlay(userId.toString());
          final selectedPackages = _selectedBlockedPackages();
          for (final package in selectedPackages) {
            await _blockService.blockApp(package);
          }
          try {
            await _blockService.startBlockingService();
          } catch (e) {
            print('[AlertController] Failed to start blocking service: $e');
          }
          AppToast.showToast("Mind Control Guard is Activated");
        } else if (Platform.isIOS) {
          final limiter = AppLimiter();
          final granted = await limiter.requestIosPermission();
          if (granted) {
            await limiter.blockAndUnblockIOSApp();
            AppToast.showToast("Mind Control Guard is Activated");
          }
        }
        return true;
      } else {
        AppToast.showToast(response.errorMessage ?? "Failed to create alert");
        return false;
      }
    } catch (e, stack) {
      debugPrint('[AlertController] createTradeAlert error: $e\n$stack');
      AppToast.showToast("Failed to create alert. Please try again.");
      return false;
    } finally {
      isSavingAlert.value = false;
    }
  }

  /// Max number of instruments user can have alerts for.
  static const int maxAlertInstruments = 2;

  int _uniqueInstrumentCount() {
    final keys = <String>{};
    for (final a in savedAlerts) {
      keys.add("${a.exchange}:${a.tradingsymbol}");
    }
    return keys.length;
  }

  bool hasAlertForInstrument(String instrument) {
    return savedAlerts.any(
      (a) =>
          "${a.exchange}:${a.tradingsymbol}".toLowerCase() ==
          instrument.toLowerCase(),
    );
  }

  bool canAddAlert(String instrument) {
    if (hasAlertForInstrument(instrument)) return false;
    return _uniqueInstrumentCount() < maxAlertInstruments;
  }

  /// Create 2 alerts at once: upper (above current) and lower (below current).
  Future<bool> createAlertPair({
    required String instrument,
    required String upperPrice,
    required String lowerPrice,
    required double currentPrice,
    String? tradeId,
  }) async {
    try {
      isSavingAlert.value = true;
      final userId = Common.userData.value?.payload?.id;
      if (userId == null) {
        AppToast.showToast("Please log in to create an alert");
        return false;
      }
      final hasPermissions = await checkBlockAppPermissions();
      if (!hasPermissions) {
        // Permission denied: do not call alert/create API.
        return false;
      }

      await fetchUserAlerts(userId.toString());
      if (hasAlertForInstrument(instrument)) {
        AppToast.showToast("You already have an alert for this instrument.");
        return false;
      }
      if (_uniqueInstrumentCount() >= maxAlertInstruments) {
        AppToast.showToast(
          "You can only create $maxAlertInstruments alerts. Delete one to add new.",
        );
        return false;
      }
      final AppLimiter limiter = AppLimiter();

      // Create upper alert (price above current)
      final respUpper = await apiService.postFormData(ApiUrl.createAlertUrl, {
        'user_id': userId.toString(),
        'instrument': instrument,
        'price': upperPrice,
        'current_price': currentPrice.toString(),
        if (tradeId != null && tradeId.isNotEmpty) 'trade_id': tradeId,
      });
      // Create lower alert (price below current)
      final respLower = await apiService.postFormData(ApiUrl.createAlertUrl, {
        'user_id': userId.toString(),
        'instrument': instrument,
        'price': lowerPrice,
        'current_price': currentPrice.toString(),
        if (tradeId != null && tradeId.isNotEmpty) 'trade_id': tradeId,
      });

      bool success = false;
      if (Platform.isAndroid) {
        await _blockService.saveUserIdForOverlay(userId.toString());
        final selectedPackages = _selectedBlockedPackages();
        for (final package in selectedPackages) {
          final ok = await _blockService.blockApp(package);
          if (ok) success = true;
        }
        try {
          await _blockService.startBlockingService();
        } catch (e) {
          print('[AlertController] Failed to start blocking service: $e');
        }
      } else if (Platform.isIOS) {
        try {
          await limiter.blockAndUnblockIOSApp();
          success = true;
        } catch (e) {
          print('[AlertController] iOS block failed: $e');
          success = false;
        }
      }

      if (success) {
        AppToast.showToast(
          "Mind Control Guard is Activated",
        );
      }
      final alertsCreated = respUpper.isSuccess && respLower.isSuccess;
      if (alertsCreated) {
        AppToast.showToast("Alerts created successfully");
        fetchUserAlerts(userId.toString());
        if (Get.isRegistered<ChatController>()) {
          Get.find<ChatController>().loadMessages(refresh: true);
        }
      } else {
        AppToast.showToast(
          respUpper.errorMessage ??
              respLower.errorMessage ??
              "Failed to create alerts",
        );
      }
      return alertsCreated;
    } catch (e, stack) {
      debugPrint('[AlertController] createAlertPair error: $e\n$stack');
      AppToast.showToast("Failed to create alerts. Please try again.");
      return false;
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
    final granted =
        (updated['hasOverlayPermission'] ?? false) &&
        (updated['hasUsageStatsPermission'] ?? false);
    if (!granted) {
      AppToast.showToast(
        "Android overlay and usage access permissions are required to create alerts",
      );
    }
    return granted;
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
          final selectedPackages = _selectedBlockedPackages();
          for (final package in selectedPackages) {
            await _blockService.unblockApp(package);
          }
          AppToast.showToast("Mind Control Guard is Deactivated");
        } else {
          final AppLimiter limiter = AppLimiter();
          await limiter.blockAndUnblockIOSApp();
        }
        final uid = Common.userData.value?.payload?.id;
        if (uid != null && uid.isNotEmpty) {
          fetchUserAlerts(uid);
        }
      } else {
        AppToast.showToast("Failed to delete alert");
      }
      isUserAlertLoading.value = false;
    } catch (e, stack) {
      debugPrint('[AlertController] deleteAlerts error: $e\n$stack');
      isUserAlertLoading.value = false;
      AppToast.showToast("Failed to delete alert. Please try again.");
    }
  }

  Future<void> fetchUserAlerts(String userId) async {
    try {
      isUserAlertLoading.value = true;

      var response = await apiService.postFormData(
        ApiUrl.getAlertsByUser,
        {"user_id": userId},
      );
      if (!response.isSuccess) {
        response = await apiService.postFormData(
          'https://api.disciplinedminds.in/api/alert/get-by-user-id',
          {"user_id": userId},
        );
      }

      if (response.isSuccess) {
        final model = UserAlertModel.fromJson(response.data);
        savedAlerts.assignAll(model.payload ?? []);
      } else {
        savedAlerts.clear();
      }

      isUserAlertLoading.value = false;
    } catch (e, stack) {
      debugPrint('[AlertController] fetchUserAlerts error: $e\n$stack');
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
    } catch (e, stack) {
      isQuoteLoading.value = false;
      debugPrint('[AlertController] getQuote error: $e\n$stack');
      AppToast.showToast("Failed to fetch quote. Please try again.");
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
