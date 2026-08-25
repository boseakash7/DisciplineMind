import 'package:discipline_mind/controller/chat_controller.dart';
import 'package:discipline_mind/services/dmt_levels_service.dart';
import 'package:discipline_mind/services/dmt_score_history_service.dart';
import 'package:discipline_mind/services/dmt_user_levels_summary_service.dart';
import 'package:get/get.dart';

/// Reloads tab data after offline failures or when the app resumes online.
class AppDataRefreshService extends GetxService {
  bool _refreshInFlight = false;

  DmtLevelsService get _levelsService {
    return Get.isRegistered<DmtLevelsService>()
        ? Get.find<DmtLevelsService>()
        : Get.put(DmtLevelsService(), permanent: true);
  }

  DmtUserLevelsSummaryService get _summaryService {
    return Get.isRegistered<DmtUserLevelsSummaryService>()
        ? Get.find<DmtUserLevelsSummaryService>()
        : Get.put(DmtUserLevelsSummaryService(), permanent: true);
  }

  DmtScoreHistoryService get _historyService {
    return Get.isRegistered<DmtScoreHistoryService>()
        ? Get.find<DmtScoreHistoryService>()
        : Get.put(DmtScoreHistoryService(), permanent: true);
  }

  bool get _needsLevelsRefresh {
    final levels = _levelsService;
    return levels.levels.isEmpty || levels.levelsError.value != null;
  }

  bool get _needsSummaryRefresh {
    final summary = _summaryService;
    return summary.summaryPayload.value == null || summary.error.value != null;
  }

  bool get _needsAnalysisRefresh {
    final history = _historyService;
    return history.historyPayload.value == null ||
        history.error.value != null ||
        history.returnsError.value != null ||
        history.selectedLevel.value == null;
  }

  bool get _needsTradesRefresh {
    final levels = _levelsService;
    return !levels.hasLoadedHitTrades || levels.tradesError.value != null;
  }

  bool get hasPendingTabData =>
      _needsLevelsRefresh ||
      _needsSummaryRefresh ||
      _needsAnalysisRefresh ||
      _needsTradesRefresh;

  Future<void> refreshAllTabs({
    bool force = true,
    bool includeChat = true,
  }) async {
    if (_refreshInFlight) return;
    _refreshInFlight = true;
    try {
      final levels = _levelsService;
      final summary = _summaryService;
      final history = _historyService;

      await levels.refreshLevels(force: force);
      await Future.wait([
        summary.fetchSummary(force: force),
        history.refreshTabData(force: force),
      ]);

      final level = levels.selectedLevel.value;
      if (level != null &&
          (!levels.hasLoadedHitTrades || levels.tradesError.value != null)) {
        await levels.fetchUserHitTrades(level.id, force: force);
      }

      if (includeChat && Get.isRegistered<ChatController>()) {
        await Get.find<ChatController>().syncChat(
          reason: ChatSyncReason.afterAction,
        );
      }
    } finally {
      _refreshInFlight = false;
    }
  }

  Future<void> refreshIfNeeded({
    bool force = true,
    bool includeChat = true,
  }) async {
    if (!hasPendingTabData && !includeChat) return;
    if (!hasPendingTabData && includeChat) {
      if (Get.isRegistered<ChatController>()) {
        await Get.find<ChatController>().syncChat(
          reason: ChatSyncReason.resume,
        );
      }
      return;
    }
    await refreshAllTabs(force: force, includeChat: includeChat);
  }
}
