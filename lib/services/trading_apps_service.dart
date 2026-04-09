import 'package:discipline_mind/constants/blocked_apps.dart';
import 'package:discipline_mind/model/trading_app_model.dart';
import 'package:discipline_mind/services/api/api_services.dart';
import 'package:discipline_mind/services/api/api_url.dart';
import 'package:discipline_mind/services/native_app_block_service.dart';
import 'package:get/get.dart';

/// Loads and caches trading apps from backend (`trading-apps`).
class TradingAppsService extends GetxService {
  final RxList<TradingApp> apps = <TradingApp>[].obs;
  final RxBool isLoading = false.obs;
  final RxnString lastError = RxnString();
  final NativeAppBlockService _blockService = NativeAppBlockService();
  bool _refreshInFlight = false;

  TradingApp? byPackageName(String packageName) {
    for (final a in apps) {
      if (a.packageName == packageName) return a;
    }
    return null;
  }

  String displayNameForPackage(String packageName) {
    return byPackageName(packageName)?.name ?? packageName;
  }

  /// Uses API flags when available; falls back to [extendedGttInputPackages].
  bool requiresExtendedGttForPackage(String packageName) {
    final app = byPackageName(packageName);
    if (app != null) return app.requiresExtendedGttForm;
    return extendedGttInputPackages.contains(packageName);
  }

  Future<bool> refresh() async {
    if (_refreshInFlight) return apps.isNotEmpty;
    _refreshInFlight = true;
    isLoading.value = true;
    lastError.value = null;
    try {
      final api = Get.isRegistered<ApiService>()
          ? Get.find<ApiService>()
          : Get.put(ApiService(), permanent: true);
      final response = await api.get(ApiUrl.tradingApps);
      if (response.isSuccess && response.data is Map) {
        final map = Map<String, dynamic>.from(response.data as Map);
        final payload = map['payload'];
        if (payload is List) {
          final list = <TradingApp>[];
          for (final item in payload) {
            if (item is Map) {
              list.add(
                TradingApp.fromJson(Map<String, dynamic>.from(item)),
              );
            }
          }
          apps.assignAll(
            list.where((a) => a.packageName.isNotEmpty).toList(),
          );
          await _blockService.setMonitoredTradingApps(
            apps.map((e) => e.packageName).toList(),
          );
          return apps.isNotEmpty;
        }
      }
      lastError.value = response.errorMessage ?? 'Could not load trading apps';
      return false;
    } catch (e) {
      lastError.value = e.toString();
      return false;
    } finally {
      isLoading.value = false;
      _refreshInFlight = false;
    }
  }

  Future<void> ensureLoaded() async {
    if (apps.isNotEmpty) return;
    await refresh();
  }
}
