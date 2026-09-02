import 'package:discipline_mind/common/common.dart';
import 'package:discipline_mind/model/trading_process_model.dart';
import 'package:discipline_mind/services/api/api_services.dart';
import 'package:discipline_mind/services/api/api_url.dart';
import 'package:discipline_mind/ui/widgets/app_toast.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

class TradingProcessController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();

  final Rx<TradingProcessData?> currentProcess = Rx<TradingProcessData?>(null);
  final RxBool isLoading = false.obs;
  final RxBool isUpdating = false.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    final uid = Common.userData.value?.payload?.id?.toString();
    if (uid != null && uid.isNotEmpty) {
      fetchProcess(userId: uid);
    }
  }

  /// Fetch user process details
  Future<TradingProcessData?> fetchProcess({String? userId}) async {
    final effectiveUserId = userId ?? Common.userData.value?.payload?.id?.toString();
    if (effectiveUserId == null || effectiveUserId.isEmpty) {
      errorMessage.value = 'User not logged in';
      return null;
    }

    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response = await _apiService.postFormData(
        ApiUrl.processFetch,
        {'user_id': effectiveUserId},
      );

      if (response.isSuccess && response.data != null) {
        final dynamic raw = response.data;
        if (raw is Map<String, dynamic>) {
          final res = TradingProcessResponse.fromJson(raw);
          if (res.status == 'ok' && res.payload != null) {
            currentProcess.value = res.payload;
            return res.payload;
          } else {
            errorMessage.value = res.message ?? 'No active process found';
          }
        }
      } else {
        errorMessage.value = response.errorMessage ?? 'Failed to fetch process';
      }
    } catch (e) {
      debugPrint('[TradingProcessController] fetchProcess error: $e');
      errorMessage.value = 'Error fetching process details';
    } finally {
      isLoading.value = false;
    }
    return currentProcess.value;
  }

  /// Edit / Update existing process
  Future<bool> editProcess({
    required String processId,
    required String tradingSegment,
    required String instrument,
    required String tradingCapital,
    required String tradesPerDay,
    required String maxRiskPercent,
    required String marketEntryTime,
    required String brokingApp,
    String permissionOverlayEnabled = '1',
    String permissionUsageStatsEnabled = '1',
    String termsAccepted = '1',
    String? userId,
  }) async {
    final effectiveUserId = userId ?? Common.userData.value?.payload?.id?.toString();
    if (effectiveUserId == null || effectiveUserId.isEmpty) {
      AppToast.showToast('User not authenticated');
      return false;
    }

    try {
      isUpdating.value = true;

      final fields = {
        'user_id': effectiveUserId,
        'process_id': processId,
        'trading_segment': tradingSegment.toLowerCase(),
        'instrument': instrument,
        'trading_capital': tradingCapital,
        'trades_per_day': tradesPerDay,
        'max_risk_percent': maxRiskPercent,
        'market_entry_time': marketEntryTime,
        'broking_app': brokingApp.toLowerCase(),
        'permission_overlay_enabled': permissionOverlayEnabled,
        'permission_usage_stats_enabled': permissionUsageStatsEnabled,
        'terms_accepted': termsAccepted,
      };

      final response = await _apiService.postFormData(
        ApiUrl.processEdit,
        fields,
      );

      if (response.isSuccess && response.data != null) {
        final dynamic raw = response.data;
        if (raw is Map<String, dynamic>) {
          final res = TradingProcessResponse.fromJson(raw);
          if (res.status == 'ok' && res.payload != null) {
            currentProcess.value = res.payload;
            AppToast.showToast('Process updated successfully!');
            return true;
          } else {
            AppToast.showToast(res.message ?? 'Failed to update process');
            return false;
          }
        }
      }

      AppToast.showToast(response.errorMessage ?? 'Failed to update process');
      return false;
    } catch (e) {
      debugPrint('[TradingProcessController] editProcess error: $e');
      AppToast.showToast('Error updating process');
      return false;
    } finally {
      isUpdating.value = false;
    }
  }

  /// Activate Mind Control
  Future<bool> activateMindControl() async {
    final effectiveUserId = Common.userData.value?.payload?.id?.toString();
    if (effectiveUserId == null || effectiveUserId.isEmpty) {
      AppToast.showToast('User not authenticated');
      return false;
    }

    try {
      isUpdating.value = true;
      final response = await _apiService.postFormData(
        ApiUrl.mindControlActive,
        {
          'user_id': effectiveUserId,
          'is_mind_controll_active': 'true',
        },
      );

      if (response.isSuccess) {
        if (currentProcess.value != null) {
          currentProcess.value = currentProcess.value!.copyWith(isMindControllActive: 1);
        }
        AppToast.showToast('Mind Control activated successfully!');
        return true;
      }

      AppToast.showToast(response.errorMessage ?? 'Failed to activate mind control');
      return false;
    } catch (e) {
      debugPrint('[TradingProcessController] activateMindControl error: $e');
      AppToast.showToast('Error activating mind control');
      return false;
    } finally {
      isUpdating.value = false;
    }
  }
}
