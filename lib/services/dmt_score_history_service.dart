import 'package:discipline_mind/common/common.dart';
import 'package:discipline_mind/model/dmt_level_model.dart';
import 'package:discipline_mind/model/dmt_score_history_model.dart';
import 'package:discipline_mind/model/dmt_user_return_percentages_model.dart';
import 'package:discipline_mind/services/api/api_services.dart';
import 'package:discipline_mind/services/api/api_url.dart';
import 'package:discipline_mind/services/dmt_levels_service.dart';
import 'package:get/get.dart';

/// Loads Analysis tab data (score history + return percentages).
class DmtScoreHistoryService extends GetxService {
  final Rxn<DmtScoreHistoryPayload> historyPayload = Rxn<DmtScoreHistoryPayload>();
  final Rxn<DmtUserReturnPercentagesPayload> returnsPayload =
      Rxn<DmtUserReturnPercentagesPayload>();
  final Rxn<DmtLevel> selectedLevel = Rxn<DmtLevel>();

  final RxBool isLoading = false.obs;
  final RxBool isLoadingReturns = false.obs;
  final RxnString error = RxnString();
  final RxnString returnsError = RxnString();

  bool _fetchInFlight = false;
  bool _returnsFetchInFlight = false;
  int? _lastHistoryLevelId;
  int? _lastReturnLevelId;
  bool _bootstrapped = false;

  DmtLevelsService get _levelsService {
    return Get.isRegistered<DmtLevelsService>()
        ? Get.find<DmtLevelsService>()
        : Get.put(DmtLevelsService(), permanent: true);
  }

  Future<bool> fetchHistory({int? levelId, bool force = false}) async {
    final userId = Common.userData.value?.payload?.id?.toString();
    if (userId == null || userId.isEmpty) {
      error.value = 'Please log in to view your score history';
      return false;
    }

    final effectiveLevelId = levelId ?? selectedLevel.value?.id;

    if (!force &&
        _fetchInFlight &&
        _lastHistoryLevelId == effectiveLevelId) {
      return historyPayload.value != null;
    }

    _fetchInFlight = true;
    _lastHistoryLevelId = effectiveLevelId;
    isLoading.value = true;
    error.value = null;

    try {
      final fields = <String, String>{'user_id': userId};
      if (effectiveLevelId != null && effectiveLevelId > 0) {
        fields['level_id'] = effectiveLevelId.toString();
      }

      final response = await _api().postFormData(
        ApiUrl.dmtScoreHistory,
        fields,
      );

      if (!response.isSuccess || response.data is! Map) {
        error.value =
            response.errorMessage ?? 'Could not load score history';
        historyPayload.value = null;
        return false;
      }

      final parsed = DmtScoreHistoryResponse.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );

      if (!parsed.isOk || parsed.payload == null) {
        error.value = 'No score history available';
        historyPayload.value = null;
        return false;
      }

      historyPayload.value = parsed.payload;
      _syncSelectedLevel(parsed.payload!);
      return true;
    } catch (e) {
      error.value = e.toString();
      historyPayload.value = null;
      return false;
    } finally {
      isLoading.value = false;
      _fetchInFlight = false;
    }
  }

  void _syncSelectedLevel(DmtScoreHistoryPayload payload) {
    final requested = payload.requestedLevel;
    if (requested != null && requested.isValid) {
      selectedLevel.value =
          _levelsService.levelById(requested.id) ?? requested;
      return;
    }
    final current = payload.currentLevel;
    if (current != null && current.isValid && selectedLevel.value == null) {
      selectedLevel.value = _levelsService.levelById(current.id) ?? current;
    }
  }

  Future<bool> fetchReturnPercentages(int levelId, {bool force = false}) async {
    final userId = Common.userData.value?.payload?.id?.toString();
    if (userId == null || userId.isEmpty) {
      returnsError.value = 'Please log in to view returns';
      return false;
    }

    if (!force &&
        _returnsFetchInFlight &&
        _lastReturnLevelId == levelId) {
      return returnsPayload.value != null;
    }

    _returnsFetchInFlight = true;
    _lastReturnLevelId = levelId;
    isLoadingReturns.value = true;
    returnsError.value = null;

    try {
      final response = await _api().postFormData(
        ApiUrl.dmtLevelUserReturnPercentages,
        {
          'user_id': userId,
          'level_id': levelId.toString(),
        },
      );

      if (!response.isSuccess || response.data is! Map) {
        returnsError.value =
            response.errorMessage ?? 'Could not load return data';
        returnsPayload.value = null;
        return false;
      }

      final parsed = DmtUserReturnPercentagesResponse.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );

      if (!parsed.isOk || parsed.payload == null) {
        returnsError.value = 'No return data available';
        returnsPayload.value = null;
        return false;
      }

      returnsPayload.value = parsed.payload;
      return true;
    } catch (e) {
      returnsError.value = e.toString();
      returnsPayload.value = null;
      return false;
    } finally {
      isLoadingReturns.value = false;
      _returnsFetchInFlight = false;
    }
  }

  Future<void> selectLevelById(int? levelId) async {
    if (levelId == null) return;
    final level = _levelsService.levelById(levelId);
    if (level == null) return;
    selectedLevel.value = level;
    await fetchHistory(levelId: levelId, force: true);
    await fetchReturnPercentages(levelId, force: true);
  }

  Future<void> _bootstrapCurrentLevel() async {
    if (_bootstrapped) return;
    _bootstrapped = true;

    await _levelsService.refreshLevels();

    final ok = await fetchHistory(force: true);
    if (!ok) return;

    final current = historyPayload.value?.currentLevel;
    if (current == null || !current.isValid) return;

    selectedLevel.value = _levelsService.levelById(current.id) ?? current;
    await fetchHistory(levelId: current.id, force: true);
    await fetchReturnPercentages(current.id, force: true);
  }

  Future<void> ensureLoaded() async {
    if (!_bootstrapped || selectedLevel.value == null) {
      await _bootstrapCurrentLevel();
      return;
    }

    final levelId = selectedLevel.value!.id;
    if (historyPayload.value == null) {
      await fetchHistory(levelId: levelId);
    }
    if (returnsPayload.value == null) {
      await fetchReturnPercentages(levelId);
    }
  }

  Future<void> refreshTabData() async {
    await _levelsService.refreshLevels();
    final levelId =
        selectedLevel.value?.id ?? historyPayload.value?.currentLevel?.id;
    if (levelId != null && levelId > 0) {
      await fetchHistory(levelId: levelId, force: true);
      await fetchReturnPercentages(levelId, force: true);
    } else {
      await _bootstrapCurrentLevel();
    }
  }

  ApiService _api() {
    return Get.isRegistered<ApiService>()
        ? Get.find<ApiService>()
        : Get.put(ApiService(), permanent: true);
  }
}
