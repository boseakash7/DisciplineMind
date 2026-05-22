import 'package:discipline_mind/common/common.dart';
import 'package:discipline_mind/model/dmt_level_model.dart';
import 'package:discipline_mind/model/dmt_user_hit_trades_model.dart';
import 'package:discipline_mind/services/api/api_services.dart';
import 'package:discipline_mind/services/api/api_url.dart';
import 'package:get/get.dart';

/// Loads DMT levels and user hit-trades for the Trades tab.
class DmtLevelsService extends GetxService {
  static const int _fallbackTotalTrades = 120;
  static const int _fallbackTotalWins = 97;
  static const String _fallbackAccuracy = '80.33 %';
  static const String _fallbackFrr = 'FRR - 25%';
  static const String _fallbackRtt = 'RTT - 97 %';

  final RxList<DmtLevel> levels = <DmtLevel>[].obs;
  final Rxn<DmtLevel> selectedLevel = Rxn<DmtLevel>();
  final Rxn<DmtUserHitTradesPayload> hitTrades = Rxn<DmtUserHitTradesPayload>();

  final RxBool isLoadingLevels = false.obs;
  final RxBool isLoadingTrades = false.obs;
  final RxnString levelsError = RxnString();
  final RxnString tradesError = RxnString();

  bool _levelsRefreshInFlight = false;
  bool _tradesFetchInFlight = false;
  int? _lastFetchedLevelId;

  /// Overview stats — API values with UI fallbacks when response not loaded.
  int get displayTotalTrades {
    final payload = hitTrades.value;
    if (payload != null) return payload.totalTrades;
    if (isLoadingTrades.value) return 0;
    return _fallbackTotalTrades;
  }

  int get displayTotalWins {
    final payload = hitTrades.value;
    if (payload != null) return payload.totalWins;
    if (isLoadingTrades.value) return 0;
    return _fallbackTotalWins;
  }

  /// From API `trade_accuracy_text` / `trade_accuracy`, else computed, else fallback.
  String get displayTradeAccuracy {
    final payload = hitTrades.value;
    if (payload != null) {
      final accuracy = payload.displayTradeAccuracy;
      if (accuracy.isNotEmpty) return accuracy;
      return '0%';
    }
    if (isLoadingTrades.value) return '0%';
    return _fallbackAccuracy;
  }

  /// 0–100 for the accuracy ring animation.
  double get displayTradeAccuracyPercent {
    final payload = hitTrades.value;
    if (payload != null) {
      return payload.tradeAccuracyPercentValue ?? 0;
    }
    if (isLoadingTrades.value) return 0;
    return 80.33;
  }

  String get displayFrr => _fallbackFrr;
  String get displayRtt => _fallbackRtt;

  List<DmtHitTrade> get displayTrades =>
      hitTrades.value?.trades ?? const <DmtHitTrade>[];

  /// True after a successful `user-hit-trades` response (including empty `trades`).
  bool get hasLoadedHitTrades => hitTrades.value != null;

  @override
  void onInit() {
    super.onInit();
    ever(selectedLevel, (DmtLevel? level) {
      if (level != null) {
        fetchUserHitTrades(level.id);
      }
    });
  }

  DmtLevel? levelById(int id) {
    for (final level in levels) {
      if (level.id == id) return level;
    }
    return null;
  }

  void selectById(int? id) {
    if (id == null) return;
    selectedLevel.value = levelById(id);
  }

  void selectLevel(DmtLevel level) {
    selectedLevel.value = level;
  }

  Future<bool> refreshLevels() async {
    if (_levelsRefreshInFlight) return levels.isNotEmpty;
    _levelsRefreshInFlight = true;
    isLoadingLevels.value = true;
    levelsError.value = null;

    try {
      final api = _api();
      final response = await api.get(ApiUrl.dmtLevels);
      if (!response.isSuccess || response.data is! Map) {
        levelsError.value =
            response.errorMessage ?? 'Could not load DMT levels';
        return false;
      }

      final parsed = DmtLevelsResponse.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );

      if (!parsed.isOk && parsed.payload.isEmpty) {
        levelsError.value = 'No DMT levels available';
        return false;
      }

      final valid = parsed.payload.where((l) => l.isValid).toList();
      levels.assignAll(valid);
      _ensureLevelSelection();
      return levels.isNotEmpty;
    } catch (e) {
      levelsError.value = e.toString();
      return false;
    } finally {
      isLoadingLevels.value = false;
      _levelsRefreshInFlight = false;
    }
  }

  Future<bool> fetchUserHitTrades(int levelId) async {
    final userId = Common.userData.value?.payload?.id?.toString();
    if (userId == null || userId.isEmpty) {
      tradesError.value = 'Please log in to view trades';
      return false;
    }

    if (_tradesFetchInFlight && _lastFetchedLevelId == levelId) {
      return hitTrades.value != null;
    }

    _tradesFetchInFlight = true;
    _lastFetchedLevelId = levelId;
    isLoadingTrades.value = true;
    tradesError.value = null;
    hitTrades.value = null;

    try {
      final response = await _api().postFormData(ApiUrl.dmtLevelUserHitTrades, {
        'user_id': userId,
        'level_id': levelId.toString(),
      });

      if (!response.isSuccess || response.data is! Map) {
        tradesError.value =
            response.errorMessage ?? 'Could not load trade details';
        hitTrades.value = null;
        return false;
      }

      final parsed = DmtUserHitTradesResponse.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );

      if (parsed.payload == null) {
        tradesError.value = 'No trade data for this level';
        hitTrades.value = null;
        return false;
      }

      hitTrades.value = parsed.payload;
      final apiLevel = parsed.payload!.level;
      if (apiLevel != null && apiLevel.isValid) {
        selectedLevel.value = levelById(apiLevel.id) ?? apiLevel;
      }
      return true;
    } catch (e) {
      tradesError.value = e.toString();
      hitTrades.value = null;
      return false;
    } finally {
      isLoadingTrades.value = false;
      _tradesFetchInFlight = false;
    }
  }

  void _ensureLevelSelection() {
    if (levels.isEmpty) {
      selectedLevel.value = null;
      return;
    }
    final current = selectedLevel.value;
    if (current != null && levelById(current.id) != null) return;
    selectedLevel.value = levels.first;
  }

  Future<void> ensureLoaded() async {
    if (levels.isEmpty) {
      await refreshLevels();
    } else if (selectedLevel.value != null) {
      await fetchUserHitTrades(selectedLevel.value!.id);
    }
  }

  /// Backward-compatible alias for level list refresh.
  Future<bool> refresh() => refreshLevels();

  ApiService _api() {
    return Get.isRegistered<ApiService>()
        ? Get.find<ApiService>()
        : Get.put(ApiService(), permanent: true);
  }
}
