import 'dart:io';

import 'package:app_limiter/app_limiter.dart';
import 'package:discipline_mind/common/common.dart';
import 'package:discipline_mind/constants/blocked_apps.dart';
import 'package:discipline_mind/controller/alert_controller.dart';
import 'package:discipline_mind/model/chat_message_model.dart';
import 'package:discipline_mind/services/api/api_services.dart';
import 'package:discipline_mind/services/api/api_url.dart';
import 'package:discipline_mind/services/app_block_preferences_service.dart';
import 'package:discipline_mind/services/native_app_block_service.dart';
import 'package:discipline_mind/services/trading_apps_service.dart';
import 'package:discipline_mind/ui/widgets/app_toast.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:url_launcher/url_launcher.dart';

/// Why chat is being synced — controls force vs stale-gated fetch.
enum ChatSyncReason {
  /// App returned from background.
  resume,

  /// FCM / local notification received or opened.
  notification,

  /// User switched to Chat tab.
  tabFocus,

  /// Pull-to-refresh / Sync button / explicit user action.
  manual,

  /// Generic internal refresh after an API action.
  afterAction,
}

class ChatController extends GetxController {
  final NativeAppBlockService _blockService = NativeAppBlockService();
  final AppBlockPreferencesService _prefs = AppBlockPreferencesService();

  static const _pendingSyncKey = 'chat_sync_pending';
  static const _pendingFullReloadKey = 'chat_full_reload_pending';
  static const _minSyncGap = Duration(seconds: 12);
  static const int tradeWindowSeconds = 120;

  final messages = <ChatMessage>[].obs;
  final isLoading = false.obs;
  final isRefreshing = false.obs;
  final hasMoreOlderMessages = true.obs;
  /// True when the last full load failed (e.g. no internet).
  final loadFailed = false.obs;

  DateTime? _lastSuccessfulSyncAt;
  Future<void>? _syncInFlight;

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
    loadMessages();
  }

  /// Lightweight flag for background FCM / missed syncs. Safe across isolates
  /// after [GetStorage.init].
  static void markPendingSync() {
    try {
      GetStorage().write(_pendingSyncKey, true);
    } catch (_) {}
  }

  static bool consumePendingSync() {
    try {
      final box = GetStorage();
      final pending = box.read(_pendingSyncKey) == true;
      if (pending) box.remove(_pendingSyncKey);
      return pending;
    } catch (_) {
      return false;
    }
  }

  static bool hasPendingSync() {
    try {
      return GetStorage().read(_pendingSyncKey) == true;
    } catch (_) {
      return false;
    }
  }

  /// Full message list reload (not incremental). Needed when backend deletes a trade.
  static void markPendingFullReload() {
    try {
      GetStorage().write(_pendingFullReloadKey, true);
      markPendingSync();
    } catch (_) {}
  }

  static bool consumePendingFullReload() {
    try {
      final box = GetStorage();
      final pending = box.read(_pendingFullReloadKey) == true;
      if (pending) box.remove(_pendingFullReloadKey);
      return pending;
    } catch (_) {
      return false;
    }
  }

  /// Single entry-point for chat refresh. Coalesces parallel callers and skips
  /// redundant network calls unless [force] / notification / pending / stale.
  Future<void> syncChat({
    ChatSyncReason reason = ChatSyncReason.manual,
    bool force = false,
  }) async {
    final userId = Common.userData.value?.payload?.id?.toString();
    if (userId == null || userId.isEmpty) return;

    final pending = consumePendingSync();
    final fullReload = consumePendingFullReload();
    final shouldForce = force ||
        pending ||
        fullReload ||
        reason == ChatSyncReason.resume ||
        reason == ChatSyncReason.notification ||
        reason == ChatSyncReason.manual ||
        reason == ChatSyncReason.afterAction;

    if (!shouldForce && _lastSuccessfulSyncAt != null) {
      final age = DateTime.now().difference(_lastSuccessfulSyncAt!);
      if (age < _minSyncGap) return;
    }

    if (_syncInFlight != null) {
      if (fullReload) {
        return _syncInFlight!.then(
          (_) => loadMessages(refresh: true, silent: true),
        );
      }
      return _syncInFlight!;
    }

    _syncInFlight = _runSync(
      silent: reason != ChatSyncReason.manual,
      fullReload: fullReload,
    ).whenComplete(() => _syncInFlight = null);
    return _syncInFlight!;
  }

  Future<void> _runSync({
    required bool silent,
    bool fullReload = false,
  }) async {
    if (fullReload) {
      await loadMessages(refresh: true, silent: silent);
      return;
    }
    await loadNewMessages(silent: silent);
  }

  String _lastKnownMessageId() {
    for (var i = messages.length - 1; i >= 0; i--) {
      final id = messages[i].messageId.trim();
      if (id.isNotEmpty) return id;
    }
    return '';
  }

  String _firstKnownMessageId() {
    for (var i = 0; i < messages.length; i++) {
      final id = messages[i].messageId.trim();
      if (id.isNotEmpty) return id;
    }
    return '';
  }

  List<ChatMessage> _parseDisplayMessages(dynamic payload) {
    if (payload is! List) return const <ChatMessage>[];
    final parsed = <ChatMessage>[];
    for (final item in payload) {
      if (item is Map<String, dynamic>) {
        // API returns messages oldest → newest (newest last). Chat list is the same.
        // [chatMessagesFromJson] order per row (e.g. trade card then prompt) is already
        // top-to-bottom for that row.
        parsed.addAll(chatMessagesFromJson(item));
      }
    }
    return _keepOnlyLatestAiWaitingMessage(
      _dedupeRedundantDeleteTradeButtons(parsed),
    );
  }

  List<ChatMessage> _mergeUniqueMessages({
    required List<ChatMessage> base,
    required List<ChatMessage> incoming,
    required bool prepend,
  }) {
    final existingIds = base
        .map((m) => m.messageId.trim())
        .where((id) => id.isNotEmpty)
        .toSet();

    final filteredIncoming = incoming.where((m) {
      final id = m.messageId.trim();
      if (id.isEmpty) return true;
      return !existingIds.contains(id);
    }).toList();

    final merged = prepend
        ? [...filteredIncoming, ...base]
        : [...base, ...filteredIncoming];
    // Backend replaces AI status messages; incremental sync never deletes old ones
    // locally, so always keep only the newest `ai_msgs` bubble.
    return _keepOnlyLatestAiWaitingMessage(merged);
  }

  /// Backend keeps a single live AI status message. Drop older `ai_msgs` so
  /// incremental "new messages only" sync does not leave stale bubbles.
  List<ChatMessage> _keepOnlyLatestAiWaitingMessage(List<ChatMessage> list) {
    var lastAiIndex = -1;
    for (var i = 0; i < list.length; i++) {
      if (list[i] is AiWaitingMessage) lastAiIndex = i;
    }
    if (lastAiIndex < 0) return list;

    final out = <ChatMessage>[];
    for (var i = 0; i < list.length; i++) {
      if (list[i] is AiWaitingMessage && i != lastAiIndex) continue;
      out.add(list[i]);
    }
    return out;
  }

  bool _isDeleteTradeRequestMessage(ChatMessage m) {
    if (m is! NewTradeOpportunityMessage) return false;
    if (m.action.toLowerCase() != 'delete') return false;
    // These are the two bubbles used in the delete flow (combined UI).
    return m.buttonType == 'open_app_button' || m.buttonType == 'delete_button';
  }

  bool _incomingHasDeleteTradeRequest(List<ChatMessage> incoming) {
    for (final m in incoming) {
      if (_isDeleteTradeRequestMessage(m) && m.actionTaken == null) return true;
    }
    return false;
  }

  ChatMessage _withActionTaken(ChatMessage m, dynamic actionTaken) {
    switch (m.type) {
      case ChatMessageType.simpleText:
        final x = m as SimpleTextMessage;
        return SimpleTextMessage(
          text: x.text,
          tradeId: x.tradeId,
          isFromUser: x.isFromUser,
          messageId: x.messageId,
          isUnread: x.isUnread,
          actionTaken: actionTaken,
          timestamp: x.timestamp,
        );
      case ChatMessageType.aiWaiting:
        final x = m as AiWaitingMessage;
        return AiWaitingMessage(
          text: x.text,
          tradeId: x.tradeId,
          messageId: x.messageId,
          isUnread: x.isUnread,
          actionTaken: actionTaken,
          timestamp: x.timestamp,
        );
      case ChatMessageType.agentWithButton:
        final x = m as AgentWithButtonMessage;
        return AgentWithButtonMessage(
          text: x.text,
          buttonLabel: x.buttonLabel,
          actionTaken: actionTaken,
          messageId: x.messageId,
          isUnread: x.isUnread,
          timestamp: x.timestamp,
        );
      case ChatMessageType.newTradeOpportunity:
        final x = m as NewTradeOpportunityMessage;
        return NewTradeOpportunityMessage(
          analystInfo: x.analystInfo,
          instrument: x.instrument,
          contract: x.contract,
          stopLoss: x.stopLoss,
          entryRange: x.entryRange,
          frr: x.frr,
          rtt: x.rtt,
          frrRatio: x.frrRatio,
          rttRatio: x.rttRatio,
          lotNumbers: x.lotNumbers,
          action: x.action,
          exchange: x.exchange,
          tradeId: x.tradeId,
          tradeUid: x.tradeUid,
          oldStopLoss: x.oldStopLoss,
          oldTakeProfit: x.oldTakeProfit,
          oldEntryPrice: x.oldEntryPrice,
          apiMessage: x.apiMessage,
          buttonType: x.buttonType,
          tradeName: x.tradeName,
          tradeSymbol: x.tradeSymbol,
          timestamp: x.timestamp,
          entryChanged: x.entryChanged,
          slChanged: x.slChanged,
          tpChanged: x.tpChanged,
          messageId: x.messageId,
          isUnread: x.isUnread,
          actionTaken: actionTaken,
        );
      case ChatMessageType.tradeExecutionPrompt:
        final x = m as TradeExecutionPromptMessage;
        return TradeExecutionPromptMessage(
          tradeData: x.tradeData,
          text: x.text,
          messageId: x.messageId,
          isUnread: x.isUnread,
          actionTaken: actionTaken,
          timestamp: x.timestamp,
        );
      case ChatMessageType.tradeExecuted:
        final x = m as TradeExecutedMessage;
        return TradeExecutedMessage(
          text: x.text,
          buttonLabel: x.buttonLabel,
          messageId: x.messageId,
          isUnread: x.isUnread,
          actionTaken: actionTaken,
          timestamp: x.timestamp,
        );
      case ChatMessageType.alertHitWithButton:
        final x = m as AlertHitWithButtonMessage;
        return AlertHitWithButtonMessage(
          text: x.text,
          buttonLabel: x.buttonLabel,
          buttonType: x.buttonType,
          hitType: x.hitType,
          tradeId: x.tradeId,
          isGttHit: x.isGttHit,
          targetHitPrice: x.targetHitPrice,
          tradeData: x.tradeData,
          messageId: x.messageId,
          isUnread: x.isUnread,
          actionTaken: actionTaken,
          timestamp: x.timestamp,
        );
      case ChatMessageType.dmtScore:
        final x = m as DmtScoreMessage;
        return DmtScoreMessage(
          headline: x.headline,
          scoreDate: x.scoreDate,
          instructionsScore: x.instructionsScore,
          commitmentScore: x.commitmentScore,
          acceptanceScore: x.acceptanceScore,
          patienceScore: x.patienceScore,
          consistencyScore: x.consistencyScore,
          dmtTotalScore: x.dmtTotalScore,
          dmtMaxScore: x.dmtMaxScore,
          bonusScore: x.bonusScore,
          hasAcceptanceScore: x.hasAcceptanceScore,
          acceptanceIsNa: x.acceptanceIsNa,
          acceptanceNote: x.acceptanceNote,
          messageId: x.messageId,
          isUnread: x.isUnread,
          actionTaken: actionTaken,
          timestamp: x.timestamp,
        );
    }
  }

  List<ChatMessage> _markAllActionsTaken(List<ChatMessage> list) {
    return list
        .map((m) => m.actionTaken == null ? _withActionTaken(m, 1) : m)
        .toList();
  }

  /// Fetch messages from API
  /// [refresh] - use isRefreshing (pull-to-refresh indicator)
  /// [silent] - no loader at all, use when e.g. notification received
  Future<void> loadMessages({bool refresh = false, bool silent = false}) async {
    if (!silent) {
      if (refresh) {
        isRefreshing.value = true;
      } else {
        isLoading.value = true;
      }
      loadFailed.value = false;
    }

    try {
      final userId = Common.userData.value?.payload?.id?.toString() ?? '2';
      final api = Get.isRegistered<ApiService>()
          ? Get.find<ApiService>()
          : Get.put(ApiService(), permanent: true);
      final response = await api.postMessagesForm(ApiUrl.getMessagesByUser, {
        'user_id': userId,
      });

      if (response.isSuccess && response.data != null) {
        final payload = response.data['payload'];
        final display = _parseDisplayMessages(payload);
        messages.assignAll(display);
        hasMoreOlderMessages.value = true;
        loadFailed.value = false;
        _lastSuccessfulSyncAt = DateTime.now();
      } else {
        if (!refresh && !silent) {
          messages.clear();
          loadFailed.value = true;
        }
        if (response.errorMessage != null && !silent) {
          AppToast.showToast(response.errorMessage!);
        }
      }
    } catch (e) {
      if (!refresh && !silent) {
        messages.clear();
        loadFailed.value = true;
      }
      if (!silent) AppToast.showError(e);
    } finally {
      if (!silent) {
        isLoading.value = false;
        isRefreshing.value = false;
      }
    }
  }

  /// Fetch only newly arrived messages:
  /// sends latest local `message_id` + `direction=after`.
  Future<void> loadNewMessages({bool silent = true}) async {
    if (messages.isEmpty) {
      await loadMessages(silent: silent);
      return;
    }
    if (!silent) {
      isRefreshing.value = true;
    }
    try {
      final userId = Common.userData.value?.payload?.id?.toString() ?? '2';
      final fields = <String, String>{'user_id': userId};
      final lastMessageId = _lastKnownMessageId();
      if (lastMessageId.isNotEmpty) {
        fields['message_id'] = lastMessageId;
        fields['direction'] = 'after';
      }
      final api = Get.isRegistered<ApiService>()
          ? Get.find<ApiService>()
          : Get.put(ApiService(), permanent: true);
      final response = await api.postMessagesForm(
        ApiUrl.getMessagesByUser,
        fields,
      );
      if (response.isSuccess && response.data != null) {
        final incoming = _parseDisplayMessages(response.data['payload']);
        if (incoming.isNotEmpty) {
          final base = messages.toList();
          final hasDeleteRequest = _incomingHasDeleteTradeRequest(incoming);
          final merged = _mergeUniqueMessages(
            base: hasDeleteRequest ? _markAllActionsTaken(base) : base,
            incoming: incoming,
            prepend: false,
          );
          messages.assignAll(merged);

          // After disabling old actions locally, refresh from backend so older messages
          // load with correct `action_taken` state.
          if (hasDeleteRequest) {
            Future.delayed(const Duration(milliseconds: 250), () {
              loadMessages(silent: true);
            });
          }
        }
        _lastSuccessfulSyncAt = DateTime.now();
      } else if (!silent && response.errorMessage != null) {
        AppToast.showToast(response.errorMessage!);
      }
    } catch (e) {
      if (!silent) {
        AppToast.showError(e);
      }
    } finally {
      if (!silent) {
        isRefreshing.value = false;
      }
    }
  }

  /// Fetch older messages when user scrolls up:
  /// sends earliest local `message_id` + `direction=before`.
  Future<void> loadOlderMessages() async {
    if (isRefreshing.value || !hasMoreOlderMessages.value) return;
    final firstMessageId = _firstKnownMessageId();
    if (firstMessageId.isEmpty) return;
    isRefreshing.value = true;
    try {
      final userId = Common.userData.value?.payload?.id?.toString() ?? '2';
      final fields = <String, String>{'user_id': userId};
      fields['message_id'] = firstMessageId;
      fields['direction'] = 'before';
      final api = Get.isRegistered<ApiService>()
          ? Get.find<ApiService>()
          : Get.put(ApiService(), permanent: true);
      final response = await api.postMessagesForm(
        ApiUrl.getMessagesByUser,
        fields,
      );
      if (response.isSuccess && response.data != null) {
        final incoming = _parseDisplayMessages(response.data['payload']);
        if (incoming.isNotEmpty) {
          final merged = _mergeUniqueMessages(
            base: messages.toList(),
            incoming: incoming,
            prepend: true,
          );
          messages.assignAll(merged);
        } else {
          hasMoreOlderMessages.value = false;
        }
      } else if (response.errorMessage != null) {
        AppToast.showToast(response.errorMessage!);
      }
    } catch (e) {
      AppToast.showError(e);
    } finally {
      isRefreshing.value = false;
    }
  }

  /// If the same trade has both `open_app_button` and `delete_button`, the UI
  /// already shows one combined bubble — drop the redundant `delete_button` row.
  List<ChatMessage> _dedupeRedundantDeleteTradeButtons(
    List<ChatMessage> chronological,
  ) {
    final openAppDeleteTradeIds = <String>{};
    for (final m in chronological) {
      if (m is! NewTradeOpportunityMessage) continue;
      if (m.buttonType != 'open_app_button') continue;
      if (m.action.toLowerCase() != 'delete') continue;
      if (m.tradeId.isEmpty) continue;
      openAppDeleteTradeIds.add(m.tradeId);
    }
    return chronological.where((m) {
      if (m is! NewTradeOpportunityMessage) return true;
      if (m.buttonType != 'delete_button') return true;
      if (m.action.toLowerCase() != 'delete') return true;
      if (m.tradeId.isEmpty) return true;
      return !openAppDeleteTradeIds.contains(m.tradeId);
    }).toList();
  }

  void addMessage(ChatMessage msg) {
    messages.add(msg);
  }

  Future<void> sendTextMessage(String text) async {
    final query = text.trim();
    if (query.isEmpty) return;

    addMessage(
      SimpleTextMessage(
        text: query,
        isFromUser: true,
        timestamp: DateTime.now().toUtc().toIso8601String(),
      ),
    );

    final waitingMsgId = 'ai_waiting_${DateTime.now().millisecondsSinceEpoch}';
    addMessage(
      AiWaitingMessage(
        text: 'Thinking...',
        messageId: waitingMsgId,
        timestamp: DateTime.now().toUtc().toIso8601String(),
      ),
    );

    try {
      final userId = Common.userData.value?.payload?.id?.toString() ??
          GetStorage().read<String>('user_id') ??
          '123';

      final response = await ApiService().postJson(
        ApiUrl.llmAsk,
        {
          'user_id': userId,
          'user_query': query,
        },
      );

      messages.removeWhere((m) => m.messageId == waitingMsgId);

      if (response.isSuccess && response.data != null) {
        final payload = response.data['payload'];
        if (payload is Map<String, dynamic> &&
            payload['response_markdown'] != null) {
          final replyText = payload['response_markdown'].toString();
          if (replyText.isNotEmpty) {
            addMessage(
              SimpleTextMessage(
                text: replyText,
                isFromUser: false,
                timestamp: DateTime.now().toUtc().toIso8601String(),
              ),
            );
            return;
          }
        }
      }

      final errorMsg =
          response.errorMessage ?? 'Unable to get response from AI.';
      addMessage(
        SimpleTextMessage(
          text: errorMsg,
          isFromUser: false,
          timestamp: DateTime.now().toUtc().toIso8601String(),
        ),
      );
    } catch (e) {
      messages.removeWhere((m) => m.messageId == waitingMsgId);
      addMessage(
        SimpleTextMessage(
          text: 'Error getting AI response. Please try again.',
          isFromUser: false,
          timestamp: DateTime.now().toUtc().toIso8601String(),
        ),
      );
    }
  }

  /// Called when user submits trade params from New Trade Opportunity popup.
  /// Blocks trading apps (Zerodha, Upstox, Groww).
  Future<void> onSubmitTradeParams({
    required String stopLoss,
    required String entry,
    required String frr,
    required String instrument,
    required String contract,
  }) async {
    try {
      if (Platform.isAndroid) {
        final userId = Common.userData.value?.payload?.id?.toString();
        if (userId != null) {
          await _blockService.saveUserIdForOverlay(userId);
        }
        final perms = await _blockService.checkPermissions();
        if (perms['hasOverlayPermission'] != true) {
          await _blockService.requestOverlayPermission();
        }
        if (perms['hasUsageStatsPermission'] != true) {
          await _blockService.requestUsageStatsPermission();
        }
        final selectedPackages = _selectedBlockedPackages();
        for (final package in selectedPackages) {
          await _blockService.blockApp(package);
        }
        try {
          await _blockService.startBlockingService();
        } catch (e) {
          print('[ChatController] startBlockingService failed: $e');
        }
        AppToast.showToast('Trading apps have been locked');
      } else if (Platform.isIOS) {
        final limiter = AppLimiter();
        final granted = await limiter.requestIosPermission();
        if (granted) {
          await limiter.blockAndUnblockIOSApp();
          AppToast.showToast('Trading apps have been locked');
        } else {
          AppToast.showToast('iOS permission required to block apps');
        }
      }
    } catch (e) {
      AppToast.showError(e);
    }
  }

  /// Default GTT price parsed from entry range (e.g. "390 - 400" -> "390").
  static String getDefaultGttPrice(String entryRange) {
    final match = RegExp(r'[\d.]+').firstMatch(entryRange);
    return match?.group(0) ?? '';
  }

  /// true => selected app needs GTT + SL + Target in popup (from API flags).
  bool shouldUseExtendedGttInputs() {
    final selected = _selectedBlockedPackages();
    if (selected.isEmpty) return false;
    if (Get.isRegistered<TradingAppsService>()) {
      final svc = Get.find<TradingAppsService>();
      for (final pkg in selected) {
        if (svc.requiresExtendedGttForPackage(pkg)) return true;
      }
      return false;
    }
    return selected.any(extendedGttInputPackages.contains);
  }

  /// Create GTT alert via API. Refreshes messages from backend on success.
  Future<bool> createGttAlert(
    NewTradeOpportunityMessage msg,
    String gttPrice, {
    String? stopLoss,
    String? takeProfit,
  }) async {
    if (gttPrice.trim().isEmpty) {
      AppToast.showToast('Please enter GTT price');
      return false;
    }
    try {
      final hasPermissions = await _checkBlockAppPermissions();
      if (!hasPermissions) {
        // Permission denied: do not call GTT create API.
        return false;
      }

      final userId = Common.userData.value?.payload?.id?.toString() ?? '2';
      final alertController = Get.isRegistered<AlertController>()
          ? Get.find<AlertController>()
          : Get.put(AlertController(), permanent: true);
      await alertController.fetchUserAlerts(userId);
      final hasPending = alertController.savedAlerts.any(
        (a) => (a.status ?? '').toLowerCase() == 'pending',
      );
      if (hasPending) {
        AppToast.showToast(
          'You already have a pending alert. Complete or delete it before creating another.',
        );
        return false;
      }

      final instrument = msg.exchange.isNotEmpty
          ? '${msg.exchange}:${msg.instrument}'
          : msg.instrument;
      final api = Get.isRegistered<ApiService>()
          ? Get.find<ApiService>()
          : Get.put(ApiService(), permanent: true);
      final fields = <String, String>{
        'user_id': userId,
        'instrument': instrument,
        'gtt_price': gttPrice.trim(),
        'trade_id': msg.tradeId,
      };
      if (stopLoss != null && stopLoss.trim().isNotEmpty) {
        fields['stop_loss'] = stopLoss.trim();
        // Optional compatibility key for backends aligned with alert schema.
        fields['lower_price'] = stopLoss.trim();
      }
      if (takeProfit != null && takeProfit.trim().isNotEmpty) {
        fields['take_profit'] = takeProfit.trim();
        // Optional compatibility key for backends aligned with alert schema.
        fields['upper_price'] = takeProfit.trim();
      }
      final response = await api.postFormData(ApiUrl.gttAlertCreate, fields);
      if (response.isSuccess) {
        await _applyTradingAppBlock(userId);
        AppToast.showToast('GTT alert created successfully');
        loadMessages(refresh: true);
        return true;
      } else {
        AppToast.showToast(
          response.errorMessage ?? 'Failed to create GTT alert',
        );
        return false;
      }
    } catch (e) {
      AppToast.showError(e);
      return false;
    }
  }

  Future<bool> _checkBlockAppPermissions() async {
    if (Platform.isIOS) {
      final limiter = AppLimiter();
      final granted = await limiter.requestIosPermission();
      if (!granted) {
        AppToast.showToast('iOS ScreenTime permission required');
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
        'Android overlay and usage access permissions are required to create GTT alert',
      );
    }
    return granted;
  }

  Future<void> _applyTradingAppBlock(String? userId) async {
    if (Platform.isAndroid) {
      if (userId != null && userId.isNotEmpty) {
        await _blockService.saveUserIdForOverlay(userId);
      }
      final selectedPackages = _selectedBlockedPackages();
      for (final package in selectedPackages) {
        await _blockService.blockApp(package);
      }
      try {
        await _blockService.startBlockingService();
      } catch (e) {
        print('[ChatController] startBlockingService failed: $e');
      }
      AppToast.showToast('Trading apps have been locked');
      return;
    }

    if (Platform.isIOS) {
      try {
        final limiter = AppLimiter();
        await limiter.blockAndUnblockIOSApp();
        AppToast.showToast('Trading apps have been locked');
      } catch (e) {
        print('[ChatController] iOS block failed: $e');
      }
    }
  }

  /// Submit trade executed (entry, stop loss, take profit). Uses AlertController.
  Future<bool> submitTradeExecuted({
    required NewTradeOpportunityMessage msg,
    required String entryPrice,
    required String stopLoss,
    required String takeProfit,
  }) async {
    final alertController = Get.isRegistered<AlertController>()
        ? Get.find<AlertController>()
        : Get.put(AlertController(), permanent: true);
    final entry = double.tryParse(entryPrice) ?? 0.0;
    final instrument = msg.exchange.isNotEmpty
        ? '${msg.exchange}:${msg.instrument}'
        : msg.instrument;
    final success = await alertController.createTradeAlert(
      instrument: instrument,
      upperPrice: takeProfit,
      lowerPrice: stopLoss,
      currentPrice: entry,
      tradeId: msg.tradeId,
    );
    if (success) {
      loadMessages(refresh: true);
    }
    return success;
  }

  /// POST `delete/trade` (trade_id + user_id) after user taps Trade Deleted.
  Future<void> acknowledgeTradeDeleted(NewTradeOpportunityMessage msg) async {
    final userId = Common.userData.value?.payload?.id?.toString();
    if (userId == null || userId.isEmpty) {
      AppToast.showToast('Please sign in to confirm');
      return;
    }
    if (msg.tradeId.isEmpty) {
      AppToast.showToast('Missing trade id');
      return;
    }
    try {
      final api = Get.isRegistered<ApiService>()
          ? Get.find<ApiService>()
          : Get.put(ApiService(), permanent: true);
      final response = await api.postFormData(ApiUrl.deleteTrade, {
        'trade_id': msg.tradeId,
        'user_id': userId,
      });
      if (response.isSuccess) {
        await _applyTradingAppBlock(userId);
        AppToast.showToast('Trade deleted');
        await loadMessages(refresh: true);
      } else {
        AppToast.showToast(
          response.errorMessage ?? 'Could not record trade deletion',
        );
      }
    } catch (e) {
      AppToast.showError(e);
      print('[ChatController] acknowledgeTradeDeleted failed: $e');
    }
  }

  /// POST `edit/trade` (levels) or `edit/gtt` (GTT edit) after user confirms.
  /// Fields: `trade_id`, `user_id`, optional `new_entry`, `new_sl`, `new_tp`.
  Future<void> acknowledgeSlTrailed(
    NewTradeOpportunityMessage msg, {
    String? newEntry,
    String? newSl,
    String? newTarget,
  }) async {
    final userId = Common.userData.value?.payload?.id?.toString();
    if (userId == null || userId.isEmpty) {
      AppToast.showToast('Please sign in to confirm');
      return;
    }
    if (msg.tradeId.isEmpty) {
      AppToast.showToast('Missing trade id');
      return;
    }
    try {
      final api = Get.isRegistered<ApiService>()
          ? Get.find<ApiService>()
          : Get.put(ApiService(), permanent: true);
      final fields = <String, String>{
        'trade_id': msg.tradeId,
        'user_id': userId,
      };
      final trimmedEntry = (newEntry ?? '').trim();
      if (trimmedEntry.isNotEmpty) {
        fields['new_entry'] = trimmedEntry;
      }
      final trimmedSl = (newSl ?? '').trim();
      if (trimmedSl.isNotEmpty) {
        fields['new_sl'] = trimmedSl;
      }
      final trimmedTarget = (newTarget ?? '').trim();
      if (trimmedTarget.isNotEmpty) {
        fields['new_tp'] = trimmedTarget;
      }
      final endpoint = msg.isGttEdit ? ApiUrl.editGtt : ApiUrl.editTrade;
      final response = await api.postFormData(endpoint, fields);
      if (response.isSuccess) {
        await _applyTradingAppBlock(userId);
        AppToast.showToast(
          msg.isGttEdit ? 'GTT updated' : 'Levels updated',
        );
        await loadMessages(refresh: true);
      } else {
        AppToast.showToast(
          response.errorMessage ?? 'Could not record update confirmation',
        );
      }
    } catch (e) {
      AppToast.showError(e);
      print('[ChatController] acknowledgeSlTrailed failed: $e');
    }
  }

  /// POST `trade/gtt-missed` (user_id + trade_id) after user taps GTT Missed.
  Future<void> acknowledgeGttMissed(AlertHitWithButtonMessage msg) async {
    final userId = Common.userData.value?.payload?.id?.toString();
    if (userId == null || userId.isEmpty) {
      AppToast.showToast('Please sign in to confirm');
      return;
    }
    final tradeId = msg.tradeId.trim().isNotEmpty
        ? msg.tradeId.trim()
        : (msg.tradeData?.tradeId.trim() ?? '');
    if (tradeId.isEmpty) {
      AppToast.showToast('Missing trade id');
      return;
    }
    try {
      final api = Get.isRegistered<ApiService>()
          ? Get.find<ApiService>()
          : Get.put(ApiService(), permanent: true);
      final response = await api.postFormData(ApiUrl.gttMissed, {
        'user_id': userId,
        'trade_id': tradeId,
      });
      if (response.isSuccess) {
        await _applyTradingAppBlock(userId);
        AppToast.showToast('GTT marked as missed');
        await loadMessages(refresh: true);
      } else {
        AppToast.showToast(
          response.errorMessage ?? 'Could not record GTT missed',
        );
      }
    } catch (e) {
      AppToast.showError(e);
      print('[ChatController] acknowledgeGttMissed failed: $e');
    }
  }

  /// POST `trade/executed` after user confirms target hit (optional [hitPrice]).
  Future<void> acknowledgeTradeExecuted(
    AlertHitWithButtonMessage msg, {
    String? hitPrice,
  }) async {
    final userId = Common.userData.value?.payload?.id?.toString();
    if (userId == null || userId.isEmpty) {
      AppToast.showToast('Please sign in to confirm');
      return;
    }
    if (msg.tradeId.isEmpty) {
      AppToast.showToast('Missing trade id');
      return;
    }
    final trimmedPrice = (hitPrice ?? '').trim();
    if (trimmedPrice.isEmpty) {
      AppToast.showToast('Please enter hit price');
      return;
    }
    if (double.tryParse(trimmedPrice) == null) {
      AppToast.showToast('Please enter a valid price');
      return;
    }
    try {
      final api = Get.isRegistered<ApiService>()
          ? Get.find<ApiService>()
          : Get.put(ApiService(), permanent: true);
      final response = await api.postFormData(ApiUrl.tradeExecuted, {
        'trade_id': msg.tradeId,
        'user_id': userId,
        'user_hit_price': trimmedPrice,
      });
      if (response.isSuccess) {
        AppToast.showToast('Trade execution confirmed');
        await loadMessages(refresh: true);
      } else {
        AppToast.showToast(
          response.errorMessage ?? 'Could not confirm trade execution',
        );
      }
    } catch (e) {
      AppToast.showError(e);
      print('[ChatController] acknowledgeTradeExecuted failed: $e');
    }
  }

  Future<bool> _launchTradingPackageWithUrlLauncher(String packageName) async {
    final candidateUris = <Uri>[
      // Android intent URI that targets package directly.
      Uri.parse('intent://#Intent;package=$packageName;end'),
      // Alternate app URI format used by Android app links.
      Uri.parse('android-app://$packageName'),
    ];
    for (final uri in candidateUris) {
      try {
        final ok = await launchUrl(
          uri,
          mode: LaunchMode.externalNonBrowserApplication,
        );
        if (ok) return true;
      } catch (_) {}
    }
    return false;
  }

  /// Stable key per chat bubble so open-app → follow-up gating survives refresh.
  String tradingAppStepKey(ChatMessage msg) {
    final id = msg.messageId.trim();
    if (id.isNotEmpty) return '${id}_${msg.type.name}';
    if (msg is NewTradeOpportunityMessage) {
      final tradeId = msg.tradeId.trim();
      if (tradeId.isNotEmpty) {
        return 'trade_${tradeId}_${msg.buttonType}_${msg.action}';
      }
    }
    if (msg is TradeExecutionPromptMessage) {
      final tradeId = msg.tradeData.tradeId.trim();
      if (tradeId.isNotEmpty) return 'prompt_$tradeId';
    }
    if (msg is AlertHitWithButtonMessage) {
      final tradeId = msg.tradeId.trim();
      if (tradeId.isNotEmpty) return 'alert_$tradeId';
    }
    return 'msg_${msg.type.name}_${identityHashCode(msg)}';
  }

  bool hasOpenedTradingApp(ChatMessage msg, Set<String> openedKeys) {
    return openedKeys.contains(tradingAppStepKey(msg));
  }

  bool canTapFollowUpAction(ChatMessage msg, Set<String> openedKeys) {
    if (msg.actionTaken != null) return false;
    return hasOpenedTradingApp(msg, openedKeys);
  }

  Future<void> openTradingApp() async {
    try {
      if (Platform.isAndroid) {
        final selectedPackages = _selectedBlockedPackages();
        for (final package in selectedPackages) {
          await _blockService.unblockApp(package);
        }
        // Overlay channel can be absent in some builds; launch should still proceed.
        await _blockService.unblockAndClose(selectedPackages);
        await _blockService.stopBlockingService();
        var launched = false;
        for (final package in selectedPackages) {
          final aliases = tradingAppLaunchAliases[package] ?? [package];
          for (final candidate in aliases) {
            final ok = await _launchTradingPackageWithUrlLauncher(candidate);
            if (ok) {
              launched = true;
              break;
            }
          }
          if (launched) {
            break;
          }
        }
        if (!launched) {
          AppToast.showToast('Selected trading app is not installed/enabled');
        }
        AppToast.showToast('Trading apps unlocked');
      } else if (Platform.isIOS) {
        final limiter = AppLimiter();
        await limiter.blockAndUnblockIOSApp();
        AppToast.showToast('Trading apps unlocked');
      }
    } catch (e) {
      print('[ChatController] openTradingApp failed: $e');
    }
  }

  /// Prevents a second full reload if the 120s timer rebuilds before backend
  /// has dropped the trade.
  final _expiryRefreshRequested = <String>{};

  /// Old payload `id` is often reused (e.g. "1") across new trades.
  static bool _isLegacyReusableTradeId(String id) {
    if (id.length >= 8) return false;
    return int.tryParse(id) != null;
  }

  static String _expiryKey(NewTradeOpportunityMessage msg) {
    final uid = msg.tradeUid.trim();
    if (uid.isNotEmpty) return uid;
    final id = msg.tradeId.trim();
    if (id.isNotEmpty && !_isLegacyReusableTradeId(id)) return id;
    final messageId = msg.messageId.trim();
    if (messageId.isNotEmpty) return messageId;
    return '${msg.tradeId}_${msg.timestamp}';
  }

  /// ISO-8601 or unix seconds/millis.
  static DateTime? parseMessageTime(String timestamp) {
    final raw = timestamp.trim();
    if (raw.isEmpty) return null;
    final iso = DateTime.tryParse(raw);
    if (iso != null) return iso.toUtc();
    final n = int.tryParse(raw);
    if (n == null) return null;
    if (n > 9999999999) {
      return DateTime.fromMillisecondsSinceEpoch(n, isUtc: true);
    }
    return DateTime.fromMillisecondsSinceEpoch(n * 1000, isUtc: true);
  }

  /// After 120s, reload chat so backend can drop the trade and send its text.
  void onTradeCountdownExpired(NewTradeOpportunityMessage msg) {
    if (!isTimedTradeAction(msg.action)) return;
    final id = _expiryKey(msg);
    if (id.trim().isEmpty) return;
    if (!_expiryRefreshRequested.add(id)) return;
    loadMessages(refresh: true, silent: true);
  }

  /// Only new trades (`add`) have a 120s apply window. Edit flows are not timed out.
  static bool isTimedTradeAction(String action) =>
      action.toLowerCase() == 'add';

  /// Add / edit / editGtt / update — show edit-specific UI (not expiry).
  static bool isEditTradeAction(String action) {
    final a = action.toLowerCase();
    return a == 'edit' || a == 'editgtt' || a == 'update';
  }

  /// Called when Trade Executed message is received. Unlocks trading apps.
  Future<void> onTradeExecuted() async {
    try {
      if (Platform.isAndroid) {
        final selectedPackages = _selectedBlockedPackages();
        for (final package in selectedPackages) {
          await _blockService.unblockApp(package);
        }
        await _blockService.unblockAndClose(selectedPackages);
        await _blockService.stopBlockingService();
        AppToast.showToast('Trading apps unlocked');
      } else if (Platform.isIOS) {
        final limiter = AppLimiter();
        await limiter.blockAndUnblockIOSApp();
        AppToast.showToast('Trading apps unlocked');
      }
    } catch (e) {
      print('[ChatController] onTradeExecuted failed: $e');
    }
  }
}
