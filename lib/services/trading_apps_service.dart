import 'package:discipline_mind/ui/widgets/broker_catalog.dart';
import 'package:discipline_mind/constants/blocked_apps.dart';
import 'package:discipline_mind/model/trading_app_model.dart';
import 'package:discipline_mind/services/api/api_config.dart';
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

  /// The bundled broker catalogue as [TradingApp] rows.
  ///
  /// GTT flags are unknown offline, so they stay false and the short GTT
  /// dialog is used until the API answers.
  List<TradingApp> _bundledApps() {
    var id = 0;
    return kBrokerCatalog.map((b) {
      id += 1;
      return TradingApp(
        id: id.toString(),
        name: b.name,
        packageName: b.packageName,
        isTarget: false,
        isStoploss: false,
        isGtt: false,
      );
    }).toList();
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
      var response = await api.get(ApiUrl.tradingApps);
      if (!response.isSuccess) {
        // Fallback to absolute base URL if relative path 404s on v2test
        response = await api.get(
          ApiUrl.tradingApps,
          environment: ApiEnvironment.phase5,
        );
      }

      final list = <TradingApp>[];
      if (response.isSuccess && response.data is Map) {
        final map = Map<String, dynamic>.from(response.data as Map);
        final payload = map['payload'];
        if (payload is List) {
          for (final item in payload) {
            if (item is Map) {
              list.add(TradingApp.fromJson(Map<String, dynamic>.from(item)));
            }
          }
        }
      }

      // If network fails or empty, populate with default supported apps
      if (list.isEmpty) {
        // Offline fallback: the full bundled catalogue, so every broker
        // the picker offers is still selectable without the API.
        list.addAll(_bundledApps());
      }

      apps.assignAll(list.where((a) => a.packageName.isNotEmpty).toList());
      // Union with the bundled catalogue. A short API response must not shrink
      // the native monitored set below the brokers setup can still offer.
      final monitored = <String>{
        ...blockedTradingAppPackages,
        ...apps.map((e) => e.packageName),
      };
      await _blockService.setMonitoredTradingApps(monitored.toList());
      return apps.isNotEmpty;
    } catch (e) {
      lastError.value = e.toString();
      if (apps.isEmpty) {
        // Offline fallback: the full bundled catalogue, so every broker
        // the picker offers is still selectable without the API.
        apps.assignAll(_bundledApps());
      }
      return apps.isNotEmpty;
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
