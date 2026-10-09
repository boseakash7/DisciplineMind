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

  static final List<TradingApp> defaultSupportedApps = [
    TradingApp(
      id: '1',
      name: 'Groww',
      packageName: 'com.nextbillion.groww',
      isTarget: true,
      isStoploss: true,
      isGtt: true,
    ),
    TradingApp(
      id: '2',
      name: 'Zerodha',
      packageName: 'com.zerodha.kite3',
      isTarget: false,
      isStoploss: false,
      isGtt: true,
    ),
    TradingApp(
      id: '3',
      name: 'Angel One',
      packageName: 'com.msf.angelmobile',
      isTarget: false,
      isStoploss: false,
      isGtt: true,
    ),
    TradingApp(
      id: '4',
      name: 'ICICI Direct',
      packageName: 'com.icicidirect.mobile',
      isTarget: false,
      isStoploss: false,
      isGtt: true,
    ),
    TradingApp(
      id: '5',
      name: 'Upstox',
      packageName: 'in.upstox.app',
      isTarget: false,
      isStoploss: false,
      isGtt: true,
    ),
    TradingApp(
      id: '6',
      name: 'Kotak Neo',
      packageName: 'com.kotak.neo',
      isTarget: false,
      isStoploss: false,
      isGtt: true,
    ),
    TradingApp(
      id: '7',
      name: 'HDFC Securities',
      packageName: 'com.hdfcsec.trade',
      isTarget: false,
      isStoploss: false,
      isGtt: true,
    ),
    TradingApp(
      id: '8',
      name: 'SBI Securities',
      packageName: 'com.sbi.smartmobile',
      isTarget: false,
      isStoploss: false,
      isGtt: true,
    ),
    TradingApp(
      id: '9',
      name: 'Dhan',
      packageName: 'co.dhan',
      isTarget: false,
      isStoploss: false,
      isGtt: true,
    ),
    TradingApp(
      id: '10',
      name: 'Motilal Oswal',
      packageName: 'com.moti.moconnect',
      isTarget: false,
      isStoploss: false,
      isGtt: true,
    ),
    TradingApp(
      id: '11',
      name: 'Paytm Money',
      packageName: 'com.paytmmoney',
      isTarget: false,
      isStoploss: false,
      isGtt: true,
    ),
    TradingApp(
      id: '12',
      name: 'INDmoney',
      packageName: 'com.indmoney',
      isTarget: false,
      isStoploss: false,
      isGtt: true,
    ),
    TradingApp(
      id: '13',
      name: 'Sharekhan',
      packageName: 'com.sharekhan.corporate',
      isTarget: false,
      isStoploss: false,
      isGtt: true,
    ),
    TradingApp(
      id: '14',
      name: 'Axis Securities',
      packageName: 'com.axis.direct',
      isTarget: false,
      isStoploss: false,
      isGtt: true,
    ),
    TradingApp(
      id: '15',
      name: 'IIFL Securities',
      packageName: 'com.iifl.touch',
      isTarget: false,
      isStoploss: false,
      isGtt: true,
    ),
    TradingApp(
      id: '16',
      name: '5paisa',
      packageName: 'com.fivepaisa.trade',
      isTarget: false,
      isStoploss: false,
      isGtt: true,
    ),
    TradingApp(
      id: '17',
      name: 'Choice',
      packageName: 'com.choiceequitybroking.finox',
      isTarget: false,
      isStoploss: false,
      isGtt: true,
    ),
    TradingApp(
      id: '18',
      name: 'Geojit',
      packageName: 'com.geojit.selfie',
      isTarget: false,
      isStoploss: false,
      isGtt: true,
    ),
    TradingApp(
      id: '19',
      name: 'Mirae Asset',
      packageName: 'mstock.miraeasset',
      isTarget: false,
      isStoploss: false,
      isGtt: true,
    ),
    TradingApp(
      id: '20',
      name: 'Sahi',
      packageName: 'com.sahi.app',
      isTarget: false,
      isStoploss: false,
      isGtt: true,
    ),
  ];

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
        response = await api.get('https://api.disciplinedminds.in/api/trading-apps');
      }

      final list = <TradingApp>[];
      if (response.isSuccess && response.data is Map) {
        final map = Map<String, dynamic>.from(response.data as Map);
        final payload = map['payload'];
        if (payload is List) {
          for (final item in payload) {
            if (item is Map) {
              list.add(
                TradingApp.fromJson(Map<String, dynamic>.from(item)),
              );
            }
          }
        }
      }

      // Merge defaults if not present in API result
      final existingPkgs = list.map((a) => a.packageName.toLowerCase()).toSet();
      final existingNames = list.map((a) => a.name.toLowerCase()).toSet();
      for (final defApp in defaultSupportedApps) {
        if (!existingPkgs.contains(defApp.packageName.toLowerCase()) &&
            !existingNames.contains(defApp.name.toLowerCase())) {
          list.add(defApp);
        }
      }

      apps.assignAll(
        list.where((a) => a.packageName.isNotEmpty).toList(),
      );
      await _blockService.setMonitoredTradingApps(
        apps.map((e) => e.packageName).toList(),
      );
      return apps.isNotEmpty;
    } catch (e) {
      lastError.value = e.toString();
      if (apps.isEmpty) {
        apps.assignAll(defaultSupportedApps);
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
