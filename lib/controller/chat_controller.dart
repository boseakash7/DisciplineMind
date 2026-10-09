import 'dart:async';
import 'dart:io';

import 'package:app_limiter/app_limiter.dart';
import 'package:discipline_mind/common/common.dart';
import 'package:discipline_mind/constants/blocked_apps.dart';
import 'package:discipline_mind/controller/alert_controller.dart';
import 'package:discipline_mind/controller/trading_process_controller.dart';
import 'package:discipline_mind/model/chat_message_model.dart';
import 'package:discipline_mind/services/api/api_config.dart';
import 'package:discipline_mind/services/api/api_services.dart';
import 'package:discipline_mind/services/api/api_url.dart';
import 'package:discipline_mind/services/app_block_preferences_service.dart';
import 'package:discipline_mind/services/app_diagnostic_logger.dart';
import 'package:discipline_mind/services/native_app_block_service.dart';
import 'package:discipline_mind/services/trading_apps_service.dart';
import 'package:discipline_mind/ui/widgets/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatController extends GetxController {
  final NativeAppBlockService _blockService = NativeAppBlockService();
  final AppBlockPreferencesService _prefs = AppBlockPreferencesService();

  bool _isActionTakenValue(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is num) return value != 0;
    final normalized = value.toString().trim().toLowerCase();
    return normalized.isNotEmpty &&
        normalized != '0' &&
        normalized != 'false' &&
        normalized != 'null';
  }

  bool _isEditActionMessage(ChatMessage msg) {
    final trade = msg is NewTradeOpportunityMessage
        ? msg
        : (msg is TradeExecutionPromptMessage ? msg.tradeData : null);
    if (trade == null) return false;
    final action = trade.action.toLowerCase();
    final buttonType = trade.buttonType.toLowerCase();
    if (action == 'delete') return false;
    return action == 'edit' ||
        action == 'editgtt' ||
        action == 'update' ||
        buttonType.contains('edit') ||
        trade.slChanged ||
        trade.tpChanged ||
        trade.oldStopLoss.trim().isNotEmpty ||
        trade.oldTakeProfit.trim().isNotEmpty;
  }

  bool _isDeleteActionMessage(ChatMessage msg) {
    final trade = msg is NewTradeOpportunityMessage
        ? msg
        : (msg is TradeExecutionPromptMessage ? msg.tradeData : null);
    return trade?.action.toLowerCase() == 'delete';
  }

  bool isTradeExpired(NewTradeOpportunityMessage msg) {
    // App-side trade expiry is intentionally disabled. The backend will own
    // trade expiration and decide whether an action is still valid.
    return false;
  }

  /// Add / edit / editGtt / update — show edit-specific UI (not expiry).
  static bool isEditTradeAction(String action) {
    final a = action.toLowerCase();
    return a == 'edit' || a == 'editgtt' || a == 'update';
  }

  final messages = <ChatMessage>[].obs;
  final _localVoiceMessages = <VoiceMessage>[];
  final isLoading = false.obs;
  final isRefreshing = false.obs;
  final hasMoreOlderMessages = true.obs;

  String? currentUserId;
  int _emptyLoadRetryCount = 0;
  int _sessionVersion = 0;
  int _loadVersion = 0;
  Worker? _userWorker;

  bool _isCurrentSession(String userId, int version) =>
      !isClosed && _sessionVersion == version && _resolvedUserId == userId;

  String? get _resolvedUserId {
    final fromModel = Common.userData.value?.payload?.id?.toString();
    if (fromModel != null && fromModel.isNotEmpty) return fromModel;
    final fromStorage = GetStorage().read('user_id')?.toString();
    if (fromStorage != null && fromStorage.isNotEmpty) return fromStorage;
    return null;
  }

  String _processStateForLog() {
    if (!Get.isRegistered<TradingProcessController>()) {
      return 'UNKNOWN (process controller not loaded)';
    }

    final controller = Get.find<TradingProcessController>();
    if (controller.isLoading.value) return 'CHECKING';
    final process = controller.currentProcess.value;
    if (process == null) {
      final error = controller.errorMessage.value.toLowerCase();
      if (error.contains('no active process')) return 'NOT_CREATED';
      return error.isEmpty ? 'UNKNOWN (not checked)' : 'UNKNOWN (fetch failed)';
    }
    return 'CREATED (ID: ${process.id})';
  }

  Map<String, dynamic> _messageSummaryForLog(ChatMessage message) {
    String content = '';
    if (message is SimpleTextMessage) {
      content = message.text;
    } else if (message is VoiceMessage) {
      content = message.text;
    } else if (message is AiWaitingMessage) {
      content = message.text;
    } else if (message is AgentWithButtonMessage) {
      content = message.text;
    } else if (message is TradeExecutedMessage) {
      content = message.text;
    } else if (message is TradeExecutionPromptMessage) {
      content = message.text;
    } else if (message is AlertHitWithButtonMessage) {
      content = message.text;
    } else if (message is MctPlanMessage) {
      content = message.message.isNotEmpty ? message.message : message.body;
    } else if (message is DmtScoreMessage) {
      content = message.headline;
    } else if (message is TradeSignalMessage) {
      content = message.headline;
    } else if (message is NewTradeOpportunityMessage) {
      content = message.apiMessage.isNotEmpty
          ? message.apiMessage
          : '${message.instrument} ${message.contract}'.trim();
    }

    return {
      'Message ID': message.messageId,
      'Type': message.type.name,
      if (message.timestamp.isNotEmpty) 'Timestamp': message.timestamp,
      if (content.isNotEmpty) 'Content': content,
    };
  }

  void reset() {
    _sessionVersion++;
    _loadVersion++;
    _localVoiceMessages.clear();
    messages.clear();
    _pendingMindControlGuardNotifications.clear();
    _shownMindControlGuardNotificationKeys.clear();
    _takenActionMessageIds.clear();
    _takenActionTradeIds.clear();
    _supersededActionKeys.clear();
    currentUserId = null;
    isLoading.value = false;
    isRefreshing.value = false;
    hasMoreOlderMessages.value = true;
    _emptyLoadRetryCount = 0;
    update();
  }

  List<String> _selectedBlockedPackages() {
    final userId = _resolvedUserId;
    if (userId == null || userId.isEmpty) {
      return [];
    }
    return _prefs.getSelectedPackages(userId: userId);
  }

  @override
  void onInit() {
    super.onInit();
    _userWorker = ever(Common.userData, (_) {
      final userId = Common.userData.value?.payload?.id?.toString();
      if (userId == currentUserId) return;
      reset();
      if (userId != null && userId.isNotEmpty) loadMessages();
    });
    loadMessages();
  }

  @override
  void onClose() {
    _userWorker?.dispose();
    _sessionVersion++;
    super.onClose();
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

  /// Keeps backend/local AI waiting messages at the end of the feed.
  ///
  /// Do not collapse older AI rows here. A backend `ai_msgs` row is a real
  /// chat event and may be followed by an app-side LLM response. Removing the
  /// older row makes it disappear until the next full app restart.
  List<ChatMessage> _removeAiAfterGuardDeactivation(List<ChatMessage> list) {
    final lastNonAiIndex = list.lastIndexWhere(
      (m) => m.type != ChatMessageType.aiWaiting,
    );
    if (lastNonAiIndex >= 0 &&
        _isGuardDeactivatedMessage(list[lastNonAiIndex])) {
      // Guard deactivation is terminal for this chat burst. Do not move an
      // older/backend waiting bubble after the status message.
      return list.where((m) => m.type != ChatMessageType.aiWaiting).toList();
    }

    return list;
  }

  /// Normalize history after API merges. The backend payload order is not
  /// trusted during tab/lifecycle refreshes, so timestamped rows are sorted
  /// oldest-to-newest while preserving the original order for equal times.
  /// Waiting status rows are moved to the end by
  /// [_removeAiAfterGuardDeactivation] and the split below.
  List<ChatMessage> _normalizeMessageOrder(List<ChatMessage> list) {
    final normalized = _removeAiAfterGuardDeactivation(list);
    final waiting = normalized
        .where((m) => m.type == ChatMessageType.aiWaiting)
        .toList();
    final indexed = normalized
        .where((m) => m.type != ChatMessageType.aiWaiting)
        .toList()
        .asMap()
        .entries
        .map((entry) => (index: entry.key, message: entry.value))
        .toList();

    indexed.sort((a, b) {
      final aTime = parseMessageTime(a.message.timestamp);
      final bTime = parseMessageTime(b.message.timestamp);
      if (aTime == null && bTime == null) {
        return a.index.compareTo(b.index);
      }
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      final timeOrder = aTime.compareTo(bTime);
      return timeOrder == 0 ? a.index.compareTo(b.index) : timeOrder;
    });

    return [...indexed.map((entry) => entry.message), ...waiting];
  }

  final Set<String> _takenActionMessageIds = <String>{};
  final Set<String> _takenActionTradeIds = <String>{};
  // Older rows disabled by a newer delete request. Include the row identity
  // because the backend can reuse a message_id for the delete update.
  final Set<String> _supersededActionKeys = <String>{};
  final Map<String, SimpleTextMessage> _pendingMindControlGuardNotifications =
      {};
  final Set<String> _shownMindControlGuardNotificationKeys = <String>{};

  bool isActionTakenFor(ChatMessage msg) {
    if (_isActionTakenValue(msg.actionTaken)) return true;
    final mId = msg.messageId.trim();
    if (mId.isNotEmpty && _takenActionMessageIds.contains(mId)) return true;
    final supersededKey = _supersededActionKey(msg);
    if (supersededKey.isNotEmpty &&
        _supersededActionKeys.contains(supersededKey)) {
      return true;
    }
    final tId = msg is NewTradeOpportunityMessage
        ? msg.tradeId.trim()
        : (msg is TradeExecutionPromptMessage
              ? msg.tradeData.tradeId.trim()
              : '');
    // A later edit for the same trade is a new action instance. Its message
    // id, rather than the earlier trade-level action, controls its state.
    if (!_isEditActionMessage(msg) &&
        !_isDeleteActionMessage(msg) &&
        tId.isNotEmpty &&
        _takenActionTradeIds.contains(tId)) {
      return true;
    }
    return false;
  }

  List<ChatMessage> _applyLocallyTakenActions(List<ChatMessage> list) {
    if (_takenActionMessageIds.isEmpty &&
        _takenActionTradeIds.isEmpty &&
        _supersededActionKeys.isEmpty)
      return list;
    final result = list.toList();
    for (int i = 0; i < result.length; i++) {
      final m = result[i];
      if (m.actionTaken == null) {
        final mId = m.messageId.trim();
        final tId = m is NewTradeOpportunityMessage
            ? m.tradeId.trim()
            : (m is TradeExecutionPromptMessage
                  ? m.tradeData.tradeId.trim()
                  : '');
        final actionTakenLocally =
            (mId.isNotEmpty && _takenActionMessageIds.contains(mId)) ||
            _supersededActionKeys.contains(_supersededActionKey(m)) ||
            (!_isEditActionMessage(m) &&
                !_isDeleteActionMessage(m) &&
                tId.isNotEmpty &&
                _takenActionTradeIds.contains(tId));
        if (actionTakenLocally) {
          result[i] = _withActionTaken(m, 1);
        }
      }
    }
    return result;
  }

  String _supersededActionKey(ChatMessage m) {
    final messageId = m.messageId.trim();
    if (messageId.isEmpty) return '';
    if (m is NewTradeOpportunityMessage) {
      return '$messageId|${m.action.trim().toLowerCase()}|'
          '${m.buttonType.trim().toLowerCase()}|${m.tradeId.trim()}';
    }
    if (m is TradeExecutionPromptMessage) {
      final trade = m.tradeData;
      return '$messageId|${trade.action.trim().toLowerCase()}|'
          '${trade.buttonType.trim().toLowerCase()}|${trade.tradeId.trim()}';
    }
    return '$messageId|${m.type.name}';
  }

  ({List<ChatMessage> messages, Set<String> fomoDeleteKeys, bool hasFomoDelete})
  _parseDisplayMessagesWithControls(dynamic payload) {
    if (payload is! List) {
      return (
        messages: const <ChatMessage>[],
        fomoDeleteKeys: <String>{},
        hasFomoDelete: false,
      );
    }

    final parsed = <ChatMessage>[];
    final fomoDeleteKeys = <String>{};
    var hasFomoDelete = false;
    for (final item in payload) {
      if (item is Map<String, dynamic>) {
        hasFomoDelete = hasFomoDelete || _isFomoDeleteMessage(item);
        final controlKeys = _fomoDeleteKeys(item);
        if (controlKeys.isNotEmpty) {
          fomoDeleteKeys.addAll(controlKeys);
        }
        // API returns messages oldest → newest (newest last). Chat list is the same.
        // [chatMessagesFromJson] order per row (e.g. trade card then prompt) is already
        // top-to-bottom for that row.
        parsed.addAll(chatMessagesFromJson(item));
      }
    }
    final deduped = _dedupeRedundantDeleteTradeButtons(parsed);
    return (
      messages: _normalizeMessageOrder(_applyLocallyTakenActions(deduped)),
      fomoDeleteKeys: fomoDeleteKeys,
      hasFomoDelete: hasFomoDelete,
    );
  }

  List<ChatMessage> _parseDisplayMessages(dynamic payload) {
    return _parseDisplayMessagesWithControls(payload).messages;
  }

  Set<String> _fomoDeleteKeys(Map<String, dynamic> json) {
    if (!_isFomoDeleteMessage(json)) return const <String>{};

    final keys = <String>{};
    void addKey(dynamic value) {
      final key = value?.toString().trim() ?? '';
      if (key.isNotEmpty && key.toLowerCase() != 'null') keys.add(key);
    }

    // The server may identify the original trade by row id, trade_uid, or
    // message id depending on which API version produced the update.
    addKey(json['message_id']);
    final payload = json['payload'];
    if (payload is Map) {
      final p = Map<String, dynamic>.from(payload);
      for (final key in const [
        'id',
        'trade_id',
        'trade_uid',
        'message_id',
        'tradeId',
        'tradeUid',
      ]) {
        addKey(p[key]);
      }
      final trade = p['trade'];
      if (trade is Map) {
        final t = Map<String, dynamic>.from(trade);
        for (final key in const [
          'id',
          'trade_id',
          'trade_uid',
          'message_id',
          'tradeId',
          'tradeUid',
        ]) {
          addKey(t[key]);
        }
      }
    }
    return keys;
  }

  bool _isFomoDeleteMessage(Map<String, dynamic> json) {
    final type = (json['message_type'] ?? json['type'] ?? '')
        .toString()
        .trim()
        .toLowerCase();
    return type == 'fomo_delete';
  }

  List<ChatMessage> _activeLocalLlmMessages() {
    if (!hasActiveLocalLlmRequest) return const <ChatMessage>[];

    return messages.where((message) {
      final id = message.messageId.trim();
      return id.startsWith('local_text_') ||
          id.startsWith('local_voice_') ||
          id.startsWith('ai_waiting_') ||
          id.startsWith('voice_waiting_');
    }).toList();
  }

  bool _isLocalMessageId(String id) {
    return id.startsWith('local_text_') ||
        id.startsWith('local_voice_') ||
        id.startsWith('ai_waiting_') ||
        id.startsWith('voice_waiting_');
  }

  String? _messageContentKey(ChatMessage message) {
    if (message is SimpleTextMessage) {
      return 'text|${message.isFromUser}|${message.tradeId.trim()}|'
          '${message.text.trim()}';
    }
    if (message is VoiceMessage) {
      return 'voice|${message.isFromUser}|${message.text.trim().toLowerCase()}';
    }
    return null;
  }

  bool _isLocalApiDuplicate(ChatMessage first, ChatMessage second) {
    if (first.type != second.type || first.isFromUser != second.isFromUser) {
      return false;
    }

    final firstId = first.messageId.trim();
    final secondId = second.messageId.trim();
    final firstIsLocal = firstId.isEmpty || _isLocalMessageId(firstId);
    final secondIsLocal = secondId.isEmpty || _isLocalMessageId(secondId);
    if (firstIsLocal == secondIsLocal) return false;

    final firstKey = _messageContentKey(first);
    final secondKey = _messageContentKey(second);
    if (firstKey == null || firstKey != secondKey) return false;

    final firstTime = parseMessageTime(first.timestamp);
    final secondTime = parseMessageTime(second.timestamp);
    if (firstTime == null || secondTime == null) return false;
    return firstTime.difference(secondTime).abs() <= const Duration(minutes: 5);
  }

  /// Removes a persisted message's temporary local copy. The persisted row is
  /// preferred because it has the server id and timestamp.
  List<ChatMessage> _dedupeMessages(Iterable<ChatMessage> source) {
    final result = <ChatMessage>[];
    for (final message in source) {
      final messageId = message.messageId.trim();
      var duplicateIndex = -1;
      for (var i = 0; i < result.length; i++) {
        final existing = result[i];
        final existingId = existing.messageId.trim();
        if (messageId.isNotEmpty &&
            existingId.isNotEmpty &&
            messageId == existingId &&
            message.type == existing.type) {
          duplicateIndex = i;
          break;
        }
        if (_isLocalApiDuplicate(existing, message)) {
          duplicateIndex = i;
          break;
        }
      }

      if (duplicateIndex < 0) {
        result.add(message);
        continue;
      }

      final existing = result[duplicateIndex];
      final existingId = existing.messageId.trim();
      final existingIsLocal =
          existingId.isEmpty || _isLocalMessageId(existingId);
      final currentIsPersisted =
          messageId.isNotEmpty && !_isLocalMessageId(messageId);
      if (existingIsLocal && currentIsPersisted) {
        result[duplicateIndex] = message;
      }
    }
    return result;
  }

  bool get hasActiveLocalLlmRequest => messages.any((message) {
    return _isLocalLlmWaitingMessage(message);
  });

  bool _isLocalLlmWaitingMessage(ChatMessage message) {
    if (message.type != ChatMessageType.aiWaiting) return false;
    final id = message.messageId.trim();
    return id.startsWith('ai_waiting_') || id.startsWith('voice_waiting_');
  }

  /// Messages used by the feed. Keep all rows in [messages] for history and
  /// refreshes, but render only one AI waiting/status row at a time. During a
  /// local LLM request, the current local `Thinking...` row wins; otherwise
  /// the newest backend AI status row is shown.
  List<ChatMessage> get displayMessages {
    final latestWaitingIndex = hasActiveLocalLlmRequest
        ? messages.lastIndexWhere(_isLocalLlmWaitingMessage)
        : messages.lastIndexWhere(
            (message) => message.type == ChatMessageType.aiWaiting,
          );
    if (latestWaitingIndex < 0) return messages.toList();

    return messages
        .asMap()
        .entries
        .where((entry) {
          if (entry.value.type != ChatMessageType.aiWaiting) return true;
          return entry.key == latestWaitingIndex;
        })
        .map((entry) => entry.value)
        .toList();
  }

  bool _isGuardDeactivatedMessage(ChatMessage message) {
    if (message is! SimpleTextMessage) return false;
    if (message.isGuardDeactivated) return true;
    final text = message.text.toLowerCase();
    return text.contains('mind control guard') && text.contains('deactivat');
  }

  bool _isMarketStatusMessage(ChatMessage message) {
    if (message is! SimpleTextMessage || message.isFromUser) return false;
    final text = message.text.toLowerCase();
    return text.contains('market is closed') ||
        text.contains('market is live') ||
        text.contains('mind control guard is auto deactivated') ||
        text.contains('mind control guard is activated');
  }

  bool _containsMarketStatusMessage(Iterable<ChatMessage> list) =>
      list.any(_isMarketStatusMessage);

  bool _containsGuardDeactivatedMessage(Iterable<ChatMessage> list) =>
      list.any(_isGuardDeactivatedMessage);

  void _discardGuardActionFallback() {
    _pendingMindControlGuardNotifications.clear();
  }

  List<ChatMessage> _mergeUniqueMessages({
    required List<ChatMessage> base,
    required List<ChatMessage> incoming,
    required bool prepend,
  }) {
    final incomingHasMarketStatus = _containsMarketStatusMessage(incoming);
    final incomingHasGuardDeactivated = _containsGuardDeactivatedMessage(
      incoming,
    );
    // A delete update may reuse the original message id. Replace that old
    // row instead of treating the pending delete confirmation as a duplicate.
    final deleteUpdateIds = incoming
        .where(_isDeleteTradeRequestMessage)
        .map((m) => m.messageId.trim())
        .where((id) => id.isNotEmpty)
        .toSet();
    final mergeBase = base.where((m) {
      if (incomingHasMarketStatus && m is TradeExecutedMessage) return false;
      if (incomingHasGuardDeactivated && _isGuardDeactivatedMessage(m)) {
        return false;
      }
      final id = m.messageId.trim();
      return id.isEmpty || !deleteUpdateIds.contains(id);
    }).toList();

    final existingMessageKeys = mergeBase
        .map((m) => '${m.messageId.trim()}|${m.type.name}')
        .where((key) => !key.startsWith('|'))
        .toSet();

    final filteredIncoming = incoming.where((m) {
      final id = m.messageId.trim();
      if (id.isEmpty) return true;
      return !existingMessageKeys.contains('${id}|${m.type.name}');
    }).toList();

    if (incomingHasMarketStatus || incomingHasGuardDeactivated) {
      _discardGuardActionFallback();
    }

    List<ChatMessage> combined;
    if (prepend) {
      combined = [...filteredIncoming, ...mergeBase];
    } else {
      // Keep older AI status rows. They are persisted chat events, not
      // replaceable placeholders; only the active local request row is
      // removed by sendTextMessage/sendVoiceMessage when its response arrives.
      combined = [...mergeBase, ...filteredIncoming];
    }
    return _normalizeMessageOrder(
      _dedupeMessages(_dedupeRedundantDeleteTradeButtons(combined)),
    );
  }

  bool _isDeleteTradeRequestMessage(ChatMessage m) {
    if (m is! NewTradeOpportunityMessage) return false;
    if (m.action.toLowerCase() != 'delete') return false;
    // These are the two bubbles used in the delete flow (combined UI).
    return m.buttonType == 'open_app_button' || m.buttonType == 'delete_button';
  }

  bool _incomingHasDeleteTradeRequest(List<ChatMessage> incoming) {
    for (final m in incoming) {
      if (_isDeleteTradeRequestMessage(m) &&
          !_isActionTakenValue(m.actionTaken)) {
        return true;
      }
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
          animateResponse: x.animateResponse,
          isGuardDeactivated: x.isGuardDeactivated,
          isFromUser: x.isFromUser,
          messageId: x.messageId,
          isUnread: x.isUnread,
          sendFailed: x.sendFailed,
          actionTaken: actionTaken,
          timestamp: x.timestamp,
        );
      case ChatMessageType.voiceMessage:
        final x = m as VoiceMessage;
        return VoiceMessage(
          durationSeconds: x.durationSeconds,
          text: x.text,
          isFromUser: x.isFromUser,
          messageId: x.messageId,
          isUnread: x.isUnread,
          sendFailed: x.sendFailed,
          actionTaken: actionTaken,
          timestamp: x.timestamp,
        );
      case ChatMessageType.aiWaiting:
        final x = m as AiWaitingMessage;
        return AiWaitingMessage(
          text: x.text,
          heading: x.heading,
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
          messageId: x.messageId,
          isUnread: x.isUnread,
          actionTaken: actionTaken,
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
          oldStopLoss: x.oldStopLoss,
          apiMessage: x.apiMessage,
          buttonType: x.buttonType,
          tradeName: x.tradeName,
          tradeSymbol: x.tradeSymbol,
          messageId: x.messageId,
          isUnread: x.isUnread,
          actionTaken: actionTaken,
          timestamp: x.timestamp,
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
          tradeId: x.tradeId,
          isGttHit: x.isGttHit,
          isSlHit: x.isSlHit,
          isTargetHit: x.isTargetHit,
          status: x.status,
          targetHitPrice: x.targetHitPrice,
          tradeData: x.tradeData,
          messageId: x.messageId,
          isUnread: x.isUnread,
          actionTaken: actionTaken,
          timestamp: x.timestamp,
        );
      case ChatMessageType.mctPlan:
        final x = m as MctPlanMessage;
        return MctPlanMessage(
          heading: x.heading,
          message: x.message,
          title: x.title,
          body: x.body,
          sections: x.sections,
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
          mctAnalysisTitle: x.mctAnalysisTitle,
          mctAnalysisBody: x.mctAnalysisBody,
          mctAnalysisSections: x.mctAnalysisSections,
          messageId: x.messageId,
          isUnread: x.isUnread,
          actionTaken: actionTaken,
          timestamp: x.timestamp,
        );
      case ChatMessageType.tradeSignal:
        final x = m as TradeSignalMessage;
        return TradeSignalMessage(
          headline: x.headline,
          signalId: x.signalId,
          userId: x.userId,
          processId: x.processId,
          instrument: x.instrument,
          exchange: x.exchange,
          tradingsymbol: x.tradingsymbol,
          openPrice: x.openPrice,
          currentPrice: x.currentPrice,
          dayLow: x.dayLow,
          dayHigh: x.dayHigh,
          previousClose: x.previousClose,
          gapPercent: x.gapPercent,
          changePercent: x.changePercent,
          sequenceNo: x.sequenceNo,
          status: x.status,
          createdAt: x.createdAt,
          timestamp: x.timestamp,
          messageId: x.messageId,
          isUnread: x.isUnread,
          actionTaken: actionTaken,
        );
    }
  }

  List<ChatMessage> _markAllActionsTaken(List<ChatMessage> list) {
    return list.map((m) {
      if (m.actionTaken != null) return m;

      // Keep older rows in the feed, but remember their disabled state so the
      // silent full refresh cannot re-enable their buttons.
      final messageId = m.messageId.trim();
      if (messageId.isNotEmpty) {
        _supersededActionKeys.add(_supersededActionKey(m));
      }
      return _withActionTaken(m, 1);
    }).toList();
  }

  /// Fetch messages from API
  /// [refresh] - use isRefreshing (pull-to-refresh indicator)
  /// [silent] - no loader at all, use when e.g. notification received
  Future<void> loadMessages({
    bool refresh = false,
    bool silent = false,
    bool force = false,
  }) async {
    final userId = _resolvedUserId;
    if (userId == null || userId.isEmpty) {
      reset();
      return;
    }

    if (currentUserId != null && currentUserId != userId) {
      reset();
      force = true;
    }
    currentUserId = userId;
    final sessionVersion = _sessionVersion;
    final loadVersion = ++_loadVersion;
    bool isCurrentLoad() =>
        _isCurrentSession(userId, sessionVersion) &&
        _loadVersion == loadVersion;

    if (!silent) {
      if (refresh) {
        isRefreshing.value = true;
      } else {
        isLoading.value = true;
      }
    }

    try {
      final api = Get.isRegistered<ApiService>()
          ? Get.find<ApiService>()
          : Get.put(ApiService(), permanent: true);
      final response = await api.postMessagesForm(ApiUrl.getMessagesByUser, {
        'user_id': userId,
      });
      if (!isCurrentLoad()) return;

      if (response.isSuccess && response.data != null) {
        final payload = response.data['payload'];
        final parsedDisplay = _parseDisplayMessages(payload);
        if (_containsMarketStatusMessage(parsedDisplay)) {
          _discardGuardActionFallback();
        }
        final display = _withPendingMindControlGuardNotifications(
          parsedDisplay,
        );
        messages.assignAll(
          _normalizeMessageOrder(
            _dedupeMessages([
              ...display,
              ..._activeLocalLlmMessages(),
              ..._localVoiceMessages,
            ]),
          ),
        );
        hasMoreOlderMessages.value = true;

        if (messages.isEmpty && _emptyLoadRetryCount < 3) {
          _emptyLoadRetryCount++;
          Future.delayed(const Duration(milliseconds: 2000), () {
            if (isCurrentLoad() && messages.isEmpty) {
              loadMessages(silent: true);
            }
          });
        } else if (messages.isNotEmpty) {
          _emptyLoadRetryCount = 0;
        }
      } else {
        if (!refresh) {
          messages.clear();
        }
        if (response.errorMessage != null) {
          AppToast.showToast(response.errorMessage!);
        }
      }
    } catch (e, stack) {
      if (!isCurrentLoad()) return;
      debugPrint('[ChatController] loadMessages error: $e\n$stack');
      if (!refresh && !silent) messages.clear();
      if (!silent) AppToast.showToast('Unable to load chat. Please try again.');
    } finally {
      if (isCurrentLoad()) {
        isLoading.value = false;
        isRefreshing.value = false;
      }
    }
  }

  /// Fetch only newly arrived messages:
  /// sends latest local `message_id` + `direction=after`.
  Future<void> loadNewMessages({bool silent = true}) async {
    final userId = _resolvedUserId;
    if (userId == null || userId.isEmpty) {
      reset();
      return;
    }

    if (currentUserId != userId) {
      await loadMessages(silent: silent, force: true);
      return;
    }

    if (messages.isEmpty) {
      await loadMessages(silent: silent);
      return;
    }
    final sessionVersion = _sessionVersion;
    if (!silent) {
      isRefreshing.value = true;
    }
    try {
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
      if (!_isCurrentSession(userId, sessionVersion)) return;
      if (response.isSuccess && response.data != null) {
        final parsed = _parseDisplayMessagesWithControls(
          response.data['payload'],
        );
        final incoming = parsed.messages;
        if (incoming.isNotEmpty) {
          unawaited(
            AppDiagnosticLogger.logNewMessages(
              userId: userId,
              messages: incoming.map(_messageSummaryForLog).toList(),
              processState: _processStateForLog(),
            ),
          );
          final base = messages.toList();
          final hasDeleteRequest = _incomingHasDeleteTradeRequest(incoming);
          final merged = _mergeUniqueMessages(
            base: hasDeleteRequest ? _markAllActionsTaken(base) : base,
            incoming: incoming,
            prepend: false,
          );
          messages.assignAll(merged);

          // A newly received fomo_delete updates an older server row. Refresh
          // the complete conversation once, silently, so the server remains
          // the source of truth for the final chat contents.
          if (parsed.hasFomoDelete) {
            await loadMessages(silent: true);
          }

          // After disabling old actions locally, refresh from backend so older messages
          // load with correct `action_taken` state.
          if (hasDeleteRequest) {
            Future.delayed(const Duration(milliseconds: 250), () {
              if (_isCurrentSession(userId, sessionVersion)) {
                loadMessages(silent: true);
              }
            });
          }
        }
      } else if (!silent && response.errorMessage != null) {
        AppToast.showToast(response.errorMessage!);
      }
    } catch (e, stack) {
      if (!_isCurrentSession(userId, sessionVersion)) return;
      debugPrint('[ChatController] loadNewMessages error: $e\n$stack');
      if (!silent) {
        AppToast.showToast('Failed to load new messages. Please try again.');
      }
    } finally {
      if (_isCurrentSession(userId, sessionVersion) && !silent) {
        isRefreshing.value = false;
      }
    }
  }

  /// Fetch older messages when user scrolls up:
  /// sends earliest local `message_id` + `direction=before`.
  Future<void> loadOlderMessages() async {
    if (isRefreshing.value || !hasMoreOlderMessages.value) return;
    final userId = _resolvedUserId;
    if (userId == null || currentUserId != userId) return;
    final sessionVersion = _sessionVersion;
    final firstMessageId = _firstKnownMessageId();
    if (firstMessageId.isEmpty) return;
    isRefreshing.value = true;
    try {
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
      if (!_isCurrentSession(userId, sessionVersion)) return;
      if (response.isSuccess && response.data != null) {
        final parsed = _parseDisplayMessagesWithControls(
          response.data['payload'],
        );
        final incoming = parsed.messages;
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
    } catch (e, stack) {
      if (!_isCurrentSession(userId, sessionVersion)) return;
      debugPrint('[ChatController] loadOlderMessages error: $e\n$stack');
      AppToast.showToast('Failed to load older messages. Please try again.');
    } finally {
      if (_isCurrentSession(userId, sessionVersion)) {
        isRefreshing.value = false;
      }
    }
  }

  /// Keep every server row. Older action rows are disabled locally when a new
  /// delete request arrives; removing them would make the old message/button
  /// disappear from the chat history.
  List<ChatMessage> _dedupeRedundantDeleteTradeButtons(
    List<ChatMessage> chronological,
  ) {
    return chronological;
  }

  void _loadSampleMessages() {
    messages.assignAll([
      const SimpleTextMessage(text: 'Hello'),
      const SimpleTextMessage(text: 'I am Zeno AI Agent.'),
      const SimpleTextMessage(text: 'Hi', isFromUser: true),
      const SimpleTextMessage(text: 'Hi'),
    ]);
  }

  void addMessage(ChatMessage msg) {
    messages.assignAll(
      _normalizeMessageOrder(_dedupeMessages([...messages, msg])),
    );
  }

  /// Shows the guard-deactivated message immediately when its push event is
  /// received. Keep it pending until the API catches up so a refresh cannot
  /// remove the instant message.
  void addMindControlGuardDeactivatedMessage({
    String notificationKey = '',
    String messageId = '',
    String timestamp = '',
  }) {
    if (_containsMarketStatusMessage(messages) ||
        _containsGuardDeactivatedMessage(messages)) {
      return;
    }

    final cleanKey = notificationKey.trim();
    final cleanMessageId = messageId.trim();
    final cleanTimestamp = timestamp.trim();
    final dedupeKey = cleanKey.isNotEmpty
        ? cleanKey
        : (cleanMessageId.isNotEmpty
              ? 'message:$cleanMessageId'
              : (cleanTimestamp.isNotEmpty ? 'time:$cleanTimestamp' : ''));

    if (dedupeKey.isNotEmpty &&
        !_shownMindControlGuardNotificationKeys.add(dedupeKey)) {
      return;
    }
    if (cleanMessageId.isNotEmpty &&
        messages.any((m) => m.messageId.trim() == cleanMessageId)) {
      return;
    }

    final message = SimpleTextMessage(
      text: 'Mind Control Guard is Deactivated.',
      isGuardDeactivated: true,
      messageId: cleanMessageId,
      isUnread: false,
      timestamp: cleanTimestamp.isNotEmpty
          ? cleanTimestamp
          : DateTime.now().toUtc().toIso8601String(),
    );
    if (dedupeKey.isNotEmpty) {
      _pendingMindControlGuardNotifications[dedupeKey] = message;
    }
    addMessage(message);
  }

  List<ChatMessage> _withPendingMindControlGuardNotifications(
    List<ChatMessage> display,
  ) {
    if (_containsMarketStatusMessage(display) ||
        _containsGuardDeactivatedMessage(display)) {
      _discardGuardActionFallback();
      return display;
    }
    if (_pendingMindControlGuardNotifications.isEmpty) return display;
    final result = display.toList();
    final displayIds = result
        .map((m) => m.messageId.trim())
        .where((id) => id.isNotEmpty)
        .toSet();
    final pending = <String, SimpleTextMessage>{};
    for (final entry in _pendingMindControlGuardNotifications.entries) {
      final message = entry.value;
      final id = message.messageId.trim();
      if (id.isNotEmpty && displayIds.contains(id)) continue;
      pending[entry.key] = message;
      result.add(message);
    }
    _pendingMindControlGuardNotifications
      ..clear()
      ..addAll(pending);
    return result;
  }

  String _llmAskUrl() {
    return '${ApiConfig.getBaseUrl(ApiUrl.llmAsk)}${ApiUrl.llmAsk}';
  }

  void _markMessageSendFailed(String messageId) {
    if (messageId.isEmpty) return;
    for (var i = 0; i < messages.length; i++) {
      final message = messages[i];
      if (message.messageId != messageId) continue;
      if (message is SimpleTextMessage) {
        messages[i] = SimpleTextMessage(
          text: message.text,
          tradeId: message.tradeId,
          isGuardDeactivated: message.isGuardDeactivated,
          isFromUser: message.isFromUser,
          messageId: message.messageId,
          isUnread: message.isUnread,
          sendFailed: true,
          actionTaken: message.actionTaken,
          timestamp: message.timestamp,
        );
      } else if (message is VoiceMessage) {
        final failedMessage = VoiceMessage(
          durationSeconds: message.durationSeconds,
          text: message.text,
          isFromUser: message.isFromUser,
          messageId: message.messageId,
          isUnread: message.isUnread,
          sendFailed: true,
          actionTaken: message.actionTaken,
          timestamp: message.timestamp,
        );
        messages[i] = failedMessage;
        for (var j = 0; j < _localVoiceMessages.length; j++) {
          if (_localVoiceMessages[j].messageId == message.messageId) {
            _localVoiceMessages[j] = failedMessage;
            break;
          }
        }
      }
    }
    messages.refresh();
  }

  Future<bool> sendTextMessage(String text) async {
    final query = text.trim();
    if (query.isEmpty) return false;

    final localMessageId =
        'local_text_${DateTime.now().microsecondsSinceEpoch}';
    addMessage(
      SimpleTextMessage(
        text: query,
        isFromUser: true,
        messageId: localMessageId,
        timestamp: DateTime.now().toUtc().toIso8601String(),
      ),
    );

    final waitingMsgId = 'ai_waiting_${DateTime.now().microsecondsSinceEpoch}';
    addMessage(AiWaitingMessage(text: 'Thinking...', messageId: waitingMsgId));

    try {
      final userId =
          Common.userData.value?.payload?.id?.toString() ??
          GetStorage().read<String>('user_id') ??
          '123';

      final response = await ApiService().postJson(_llmAskUrl(), {
        'user_id': userId,
        'user_query': query,
      });

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
                isUnread: true,
                animateResponse: true,
                timestamp: DateTime.now().toUtc().toIso8601String(),
              ),
            );
            return true;
          }
        }
      }

      final errorMsg =
          response.errorMessage ?? 'Unable to get response from AI.';
      debugPrint('[ChatController] sendTextMessage failed: $errorMsg');
      _markMessageSendFailed(localMessageId);
      return false;
    } catch (e) {
      messages.removeWhere((m) => m.messageId == waitingMsgId);
      debugPrint('[ChatController] sendTextMessage error: $e');
      _markMessageSendFailed(localMessageId);
      return false;
    }
  }

  /// Uploads a recorded voice note directly to the voice-chat API.
  /// The backend handles the audio processing and returns the assistant reply.
  Future<bool> sendVoiceMessage(
    String filePath, {
    required int durationSeconds,
  }) async {
    final userId = _resolvedUserId;
    if (userId == null || userId.isEmpty) {
      AppToast.showToast('Please sign in again before sending a voice message');
      return false;
    }

    final waitingMsgId =
        'voice_waiting_${DateTime.now().millisecondsSinceEpoch}';
    final localVoiceMessage = VoiceMessage(
      durationSeconds: durationSeconds,
      messageId: 'local_voice_${DateTime.now().microsecondsSinceEpoch}',
      timestamp: DateTime.now().toIso8601String(),
    );
    _localVoiceMessages.add(localVoiceMessage);
    addMessage(localVoiceMessage);
    addMessage(AiWaitingMessage(text: 'Thinking...', messageId: waitingMsgId));

    try {
      final response = await ApiService().postMultipartFile(
        ApiUrl.voiceChatAsk,
        {'user_id': userId},
        fileField: 'audio_file',
        filePath: filePath,
      );

      messages.removeWhere((m) => m.messageId == waitingMsgId);

      if (response.isSuccess && response.data != null) {
        final payload = response.data['payload'];
        if (payload is Map<String, dynamic>) {
          final replyText = payload['response_markdown']?.toString().trim();
          if (replyText != null && replyText.isNotEmpty) {
            addMessage(
              SimpleTextMessage(
                text: replyText,
                isFromUser: false,
                isUnread: true,
                animateResponse: true,
                timestamp: DateTime.now().toUtc().toIso8601String(),
              ),
            );
            return true;
          }
        }
      }

      final errorMsg =
          response.errorMessage ?? 'Unable to process the voice message.';
      debugPrint('[ChatController] sendVoiceMessage failed: $errorMsg');
      _markMessageSendFailed(localVoiceMessage.messageId);
      return false;
    } catch (e, stack) {
      debugPrint('[ChatController] sendVoiceMessage error: $e\n$stack');
      messages.removeWhere((m) => m.messageId == waitingMsgId);
      _markMessageSendFailed(localVoiceMessage.messageId);
      return false;
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
        AppToast.showToast('Mind Control Guard is Activated');
      } else if (Platform.isIOS) {
        final limiter = AppLimiter();
        final granted = await limiter.requestIosPermission();
        if (granted) {
          await limiter.blockAndUnblockIOSApp();
          AppToast.showToast('Mind Control Guard is Activated');
        } else {
          AppToast.showToast('iOS permission required to block apps');
        }
      }
    } catch (e, stack) {
      debugPrint('[ChatController] blockTradingAppsNow error: $e\n$stack');
      AppToast.showToast('Something went wrong. Please try again.');
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
    if (isTradeExpired(msg)) {
      AppToast.showToast('This trade has expired');
      return false;
    }
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
      if (isTradeExpired(msg)) {
        AppToast.showToast('This trade has expired');
        return false;
      }
      final response = await api.postFormData(ApiUrl.gttAlertCreate, fields);
      if (response.isSuccess) {
        markActionTaken(tradeId: msg.tradeId, messageId: msg.messageId);
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
    } catch (e, stack) {
      debugPrint('[ChatController] createGttAlert error: $e\n$stack');
      AppToast.showToast('Failed to create GTT alert. Please try again.');
      return false;
    }
  }

  /// Submit GTT value for a TradeSignalMessage.
  Future<bool> submitTradeSignalGtt({
    required TradeSignalMessage msg,
    required String gttPrice,
  }) async {
    if (gttPrice.trim().isEmpty) {
      AppToast.showToast('Please enter GTT price');
      return false;
    }
    try {
      final hasPermissions = await _checkBlockAppPermissions();
      if (!hasPermissions) {
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

      final tradeId = msg.signalId.isNotEmpty
          ? msg.signalId
          : (msg.messageId.isNotEmpty ? msg.messageId : '7');
      final currentPriceClean = msg.currentPrice.replaceAll(',', '').trim();
      final symbol = msg.tradingsymbol.isNotEmpty
          ? msg.tradingsymbol
          : msg.instrument;
      final instrument = msg.exchange.isNotEmpty
          ? '${msg.exchange}:$symbol'
          : symbol;
      final api = Get.isRegistered<ApiService>()
          ? Get.find<ApiService>()
          : Get.put(ApiService(), permanent: true);
      final fields = <String, String>{
        'user_id': userId,
        'trade_id': tradeId,
        'gtt_price': gttPrice.trim(),
        'current_price': currentPriceClean.isNotEmpty
            ? currentPriceClean
            : '0.00',
        if (instrument.isNotEmpty) 'instrument': instrument,
        if (msg.processId.isNotEmpty)
          'v2test_trading_process_id': msg.processId,
      };
      final response = await api.postFormData(ApiUrl.gttAlertCreate, fields);
      if (response.isSuccess) {
        _markSignalActionTaken(msg);
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
    } catch (e, stack) {
      debugPrint('[ChatController] submitTradeSignalGtt error: $e\n$stack');
      AppToast.showToast('Failed to create GTT alert. Please try again.');
      return false;
    }
  }

  /// Submit Upper & Lower levels for a TradeSignalMessage.
  Future<bool> submitTradeSignalLevels({
    required TradeSignalMessage msg,
    required String upperPrice,
    required String lowerPrice,
  }) async {
    if (upperPrice.trim().isEmpty || lowerPrice.trim().isEmpty) {
      AppToast.showToast('Please enter both Upper and Lower values');
      return false;
    }
    try {
      final hasPermissions = await _checkBlockAppPermissions();
      if (!hasPermissions) {
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

      final tradeId = msg.signalId.isNotEmpty
          ? msg.signalId
          : (msg.messageId.isNotEmpty ? msg.messageId : '7');
      final currentPriceClean = msg.currentPrice.replaceAll(',', '').trim();
      final symbol = msg.tradingsymbol.isNotEmpty
          ? msg.tradingsymbol
          : msg.instrument;
      final instrument = msg.exchange.isNotEmpty
          ? '${msg.exchange}:$symbol'
          : symbol;
      final api = Get.isRegistered<ApiService>()
          ? Get.find<ApiService>()
          : Get.put(ApiService(), permanent: true);
      final fields = <String, String>{
        'user_id': userId,
        'trade_id': tradeId,
        'current_price': currentPriceClean.isNotEmpty
            ? currentPriceClean
            : '0.00',
        'upper_price': upperPrice.trim(),
        'lower_price': lowerPrice.trim(),
        if (instrument.isNotEmpty) 'instrument': instrument,
      };
      final response = await api.postFormData(ApiUrl.createAlertUrl, fields);
      if (response.isSuccess) {
        _markSignalActionTaken(msg);
        await _applyTradingAppBlock(userId);
        AppToast.showToast('Alert created successfully');
        loadMessages(refresh: true);
        return true;
      } else {
        AppToast.showToast(response.errorMessage ?? 'Failed to create alert');
        return false;
      }
    } catch (e, stack) {
      debugPrint('[ChatController] submitTradeSignalLevels error: $e\n$stack');
      AppToast.showToast('Failed to create alert. Please try again.');
      return false;
    }
  }

  void markActionTaken({String? tradeId, String? messageId}) {
    final cleanTradeId = (tradeId ?? '').trim();
    final cleanMsgId = (messageId ?? '').trim();
    if (cleanTradeId.isEmpty && cleanMsgId.isEmpty) return;

    if (cleanTradeId.isNotEmpty) _takenActionTradeIds.add(cleanTradeId);
    if (cleanMsgId.isNotEmpty) _takenActionMessageIds.add(cleanMsgId);

    for (int i = 0; i < messages.length; i++) {
      final m = messages[i];
      bool match = false;
      if (cleanMsgId.isNotEmpty && m.messageId.trim() == cleanMsgId) {
        match = true;
      } else if (cleanMsgId.isEmpty && cleanTradeId.isNotEmpty) {
        if (m is NewTradeOpportunityMessage && m.tradeId.trim() == cleanTradeId)
          match = true;
        if (m is TradeExecutionPromptMessage &&
            m.tradeData.tradeId.trim() == cleanTradeId)
          match = true;
        if (m is AlertHitWithButtonMessage && m.tradeId.trim() == cleanTradeId)
          match = true;
        if (m is SimpleTextMessage && m.tradeId.trim() == cleanTradeId)
          match = true;
        if (m is TradeSignalMessage &&
            (m.signalId.trim() == cleanTradeId ||
                m.messageId.trim() == cleanTradeId))
          match = true;
      }
      if (match) {
        messages[i] = _withActionTaken(m, 1);
      }
    }
    messages.refresh();
  }

  void _markSignalActionTaken(TradeSignalMessage msg) {
    markActionTaken(
      tradeId: msg.signalId.isNotEmpty ? msg.signalId : null,
      messageId: msg.messageId.isNotEmpty ? msg.messageId : null,
    );
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
      AppToast.showToast('Mind Control Guard is Activated');
      return;
    }

    if (Platform.isIOS) {
      try {
        final limiter = AppLimiter();
        await limiter.blockAndUnblockIOSApp();
        AppToast.showToast('Mind Control Guard is Activated');
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
      markActionTaken(tradeId: msg.tradeId, messageId: msg.messageId);
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
        markActionTaken(tradeId: msg.tradeId, messageId: msg.messageId);
        await _applyTradingAppBlock(userId);
        AppToast.showToast('Trade deleted');
        await loadMessages(refresh: true);
      } else {
        AppToast.showToast(
          response.errorMessage ?? 'Could not record trade deletion',
        );
      }
    } catch (e, stack) {
      debugPrint('[ChatController] acknowledgeTradeDeleted error: $e\n$stack');
      AppToast.showToast('Something went wrong. Please try again.');
    }
  }

  /// POST `edit/trade` (trade_id + user_id) after user taps SL Trailed.
  Future<void> acknowledgeSlTrailed(
    NewTradeOpportunityMessage msg, {
    String? newEntry,
    String? newSl,
    String? newTp,
    bool isGttEdit = false,
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
      final trimmedTp = (newTp ?? '').trim();
      if (trimmedTp.isNotEmpty) {
        fields['new_tp'] = trimmedTp;
        fields['new_take_profit'] = trimmedTp;
        fields['new_target'] = trimmedTp;
      }
      final endpoint = isGttEdit ? ApiUrl.editGtt : ApiUrl.editTrade;
      final response = await api.postFormData(endpoint, fields);
      if (response.isSuccess) {
        markActionTaken(tradeId: msg.tradeId, messageId: msg.messageId);
        await _applyTradingAppBlock(userId);
        AppToast.showToast(isGttEdit ? 'GTT updated' : 'SL trailed');
        await loadMessages(refresh: true);
      } else {
        AppToast.showToast(
          response.errorMessage ?? 'Could not record SL trail confirmation',
        );
      }
    } catch (e, stack) {
      debugPrint('[ChatController] acknowledgeSlTrailed error: $e\n$stack');
      AppToast.showToast('Something went wrong. Please try again.');
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
        markActionTaken(tradeId: tradeId, messageId: msg.messageId);
        loadMessages(refresh: true);
      } else {
        AppToast.showToast(
          response.errorMessage ?? 'Could not mark GTT as missed',
        );
      }
    } catch (e) {
      AppToast.showToast('Something went wrong. Please try again.');
      debugPrint('[ChatController] acknowledgeGttMissed failed: $e');
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
        for (int i = 0; i < messages.length; i++) {
          final m = messages[i];
          if (m is AlertHitWithButtonMessage &&
              (m.messageId == msg.messageId || m.tradeId == msg.tradeId)) {
            messages[i] = _withActionTaken(m, 1);
          }
        }
        messages.refresh();
        AppToast.showToast('Trade execution confirmed');
        await loadMessages(refresh: true);
      } else {
        AppToast.showToast(
          response.errorMessage ?? 'Could not confirm trade execution',
        );
      }
    } catch (e, stack) {
      debugPrint('[ChatController] acknowledgeTradeExecuted error: $e\n$stack');
      AppToast.showToast('Something went wrong. Please try again.');
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

  /// Unblock trading apps and open the first selected broker app (Android).
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
        AppToast.showToast('Mind Control Guard is Deactivated');
      } else if (Platform.isIOS) {
        final limiter = AppLimiter();
        await limiter.blockAndUnblockIOSApp();
        AppToast.showToast('Mind Control Guard is Deactivated');
      }
    } catch (e) {
      print('[ChatController] openTradingApp failed: $e');
    }
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
        AppToast.showToast('Mind Control Guard is Deactivated');
      } else if (Platform.isIOS) {
        final limiter = AppLimiter();
        await limiter.blockAndUnblockIOSApp();
        AppToast.showToast('Mind Control Guard is Deactivated');
      }
    } catch (e) {
      print('[ChatController] onTradeExecuted failed: $e');
    }
  }

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
}
