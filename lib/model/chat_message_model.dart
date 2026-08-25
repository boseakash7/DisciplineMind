/// Chat message types
enum ChatMessageType {
  simpleText,
  newTradeOpportunity,
  tradeExecutionPrompt,
  tradeExecuted,
  agentWithButton, // e.g. "Register for Demo" button
  alertHitWithButton, // GTT or upper/lower alert hit - shows text + button to unlock
  dmtScore, // Daily discipline analysis score card
  aiWaiting, // Backend AI status bubble (`message_type: ai_msgs`)
}

/// Base chat message
abstract class ChatMessage {
  final ChatMessageType type;
  final bool isFromUser;
  final String messageId;
  final bool isUnread;
  /// Backend control key: show action buttons only when this is null.
  final dynamic actionTaken;
  /// Server timestamp (ISO-8601). Used for date separators and trade countdown.
  final String timestamp;

  const ChatMessage({
    required this.type,
    this.isFromUser = false,
    this.messageId = '',
    this.isUnread = false,
    this.actionTaken,
    this.timestamp = '',
  });
}

/// Simple text message
class SimpleTextMessage extends ChatMessage {
  final String text;
  final String tradeId;

  const SimpleTextMessage({
    required this.text,
    this.tradeId = '',
    super.isFromUser = false,
    super.messageId,
    super.isUnread,
    super.actionTaken,
    super.timestamp,
  })
    : super(type: ChatMessageType.simpleText);
}

/// Backend AI waiting / status bubble (`message_type: ai_msgs`).
class AiWaitingMessage extends ChatMessage {
  final String text;
  final String tradeId;

  const AiWaitingMessage({
    required this.text,
    this.tradeId = '',
    super.messageId,
    super.isUnread,
    super.actionTaken,
    super.timestamp,
  }) : super(type: ChatMessageType.aiWaiting);

  /// Presentation-only subtitle for the waiting bubble UI.
  String get subtitle {
    final t = text.toLowerCase();
    if (t.contains('waiting for your action') ||
        t.contains('confirm sl') ||
        t.contains('confirm target') ||
        t.contains('confirm the hit')) {
      return 'Waiting for your action';
    }
    if (t.contains('monitoring')) {
      return 'Monkk is monitoring';
    }
    return 'Monkk is waiting';
  }
}

/// Agent message with a button (e.g. Register for Demo)
class AgentWithButtonMessage extends ChatMessage {
  final String text;
  final String buttonLabel;

  const AgentWithButtonMessage({
    required this.text,
    required this.buttonLabel,
    super.actionTaken,
    super.messageId,
    super.isUnread,
    super.timestamp,
  })
    : super(type: ChatMessageType.agentWithButton);
}

/// New Trade Opportunity - card with trade details, clickable to open popup
class NewTradeOpportunityMessage extends ChatMessage {
  final String analystInfo; // e.g. "SEBI REG ANALYST - INH0000244567"
  final String instrument; // e.g. "SENSEX"
  final String contract; // e.g. "05 MAR 79000 PE"
  final String stopLoss; // e.g. "350"
  final String entryRange; // e.g. "390 - 400"
  final String frr; // e.g. "450"
  final String rtt; // optional
  final String frrRatio; // e.g. "1:1"
  final String rttRatio; // e.g. "Min 1:3"
  final List<int> lotNumbers; // e.g. [4, 4, 3, 1] for Stop, Entry, FRR, RTT
  final String action; // API trade action: "add", "delete", "update", etc.
  final String
  exchange; // e.g. "NSE", "CRYPTO" - concat with instrument for API
  final String tradeId; // Numeric backend trade_id / id — send this to APIs
  /// Unique `trade_uid` for local expiry tracking (`id` is often reused, e.g. "1").
  final String tradeUid;
  /// Previous SL value from payload key `old_stop_loss_history` (edit flow).
  final String oldStopLoss;
  /// Previous TP value from payload key `old_take_profit_history` (edit flow).
  final String oldTakeProfit;
  /// Previous entry from `old_entry_price_history` (GTT edit flow).
  final String oldEntryPrice;
  /// Outer API `message` when [entity_type] is trade (e.g. instructions).
  final String apiMessage;

  /// Outer API `button_type` when [message_type] is button (e.g. open_app_button).
  final String buttonType;
  /// Preferred trade card title from payload `name`.
  final String tradeName;
  /// Preferred trade card subtitle from payload `symbol`.
  final String tradeSymbol;
  /// Outer API `entry_changed` — user may edit Entry when true (GTT edit).
  final bool entryChanged;
  /// Outer API `sl_changed` — user may edit SL when true.
  final bool slChanged;
  /// Outer API `tp_changed` — user may edit Target when true.
  final bool tpChanged;

  const NewTradeOpportunityMessage({
    required this.analystInfo,
    required this.instrument,
    required this.contract,
    required this.stopLoss,
    required this.entryRange,
    required this.frr,
    this.rtt = '',
    this.frrRatio = '1:1',
    this.rttRatio = 'Min 1:3',
    this.lotNumbers = const [4, 4, 3, 1],
    this.action = '',
    this.exchange = '',
    this.tradeId = '',
    this.tradeUid = '',
    this.oldStopLoss = '',
    this.oldTakeProfit = '',
    this.oldEntryPrice = '',
    this.apiMessage = '',
    this.buttonType = '',
    this.tradeName = '',
    this.tradeSymbol = '',
    this.entryChanged = false,
    this.slChanged = true,
    this.tpChanged = true,
    super.messageId,
    super.isUnread,
    super.actionTaken,
    super.timestamp,
  }) : super(type: ChatMessageType.newTradeOpportunity);

  bool get isGttEdit =>
      buttonType == 'edit_gtt_button' ||
      action.toLowerCase() == 'editgtt';

  int get _changedLevelCount {
    var n = 0;
    if (entryChanged) n++;
    if (slChanged) n++;
    if (tpChanged) n++;
    return n;
  }

  String get _changedLevelsLabel {
    final parts = <String>[];
    if (entryChanged) parts.add('Entry');
    if (slChanged) parts.add('SL');
    if (tpChanged) parts.add('Target');
    if (parts.isEmpty) return 'levels';
    if (parts.length == 1) return parts.first;
    if (parts.length == 2) return '${parts[0]} & ${parts[1]}';
    return 'GTT';
  }

  String get levelsEditCardTitle {
    if (isGttEdit) {
      if (_changedLevelCount == 0 || _changedLevelCount == 3) return 'GTT Edited';
      return '$_changedLevelsLabel Edited';
    }
    if (slChanged && tpChanged) return 'Levels Edited';
    if (slChanged) return 'SL Edited';
    if (tpChanged) return 'Target Edited';
    return 'Levels Edited';
  }

  String get levelsEditStepLabel {
    if (isGttEdit) {
      if (_changedLevelCount == 1) {
        return '2. Intimate me once you update the $_changedLevelsLabel';
      }
      if (_changedLevelCount == 2) {
        return '2. Intimate me once you update the $_changedLevelsLabel';
      }
      return '2. Intimate me once you update the GTT';
    }
    if (slChanged && tpChanged) {
      return '2. Intimate me once you update the levels';
    }
    if (slChanged) return '2. Intimate me once you update the SL';
    if (tpChanged) return '2. Intimate me once you update the Target';
    return '2. Intimate me once you update the levels';
  }

  String get levelsEditButtonLabel {
    if (isGttEdit) {
      if (_changedLevelCount == 1) {
        if (entryChanged) return 'Entry Updated';
        if (slChanged) return 'SL Updated';
        return 'Target Updated';
      }
      if (_changedLevelCount == 2) return '$_changedLevelsLabel Updated';
      return 'GTT Edit';
    }
    if (slChanged && tpChanged) return 'Levels Updated';
    if (slChanged) return 'SL Updated';
    if (tpChanged) return 'Target Updated';
    return 'Levels Updated';
  }

  String get levelsEditDialogTitle {
    if (isGttEdit) {
      if (_changedLevelCount == 1) {
        if (entryChanged) return 'Update Entry';
        if (slChanged) return 'Update Stop Loss';
        return 'Update Target';
      }
      if (_changedLevelCount == 2) return 'Update $_changedLevelsLabel';
      return 'Update GTT';
    }
    if (slChanged && tpChanged) return 'Update Levels';
    if (slChanged) return 'Update Stop Loss';
    if (tpChanged) return 'Update Target';
    return 'Update Levels';
  }
}

/// Trade Executed - unlocks trading apps, button is display-only
class TradeExecutedMessage extends ChatMessage {
  final String text;
  final String buttonLabel;

  const TradeExecutedMessage({
    this.text = 'Trading App is unlocked.',
    this.buttonLabel = 'GTT / Levels Applied',
    super.messageId,
    super.isUnread,
    super.actionTaken,
    super.timestamp,
  }) : super(type: ChatMessageType.tradeExecuted);
}

/// Follow-up prompt shown as a separate message below a trade card.
class TradeExecutionPromptMessage extends ChatMessage {
  final String text;
  final NewTradeOpportunityMessage tradeData;

  const TradeExecutionPromptMessage({
    required this.tradeData,
    this.text = 'Trading App is unlocked.',
    super.messageId,
    super.isUnread,
    super.actionTaken,
    super.timestamp,
  }) : super(type: ChatMessageType.tradeExecutionPrompt);
}

/// Daily DMT discipline score card (`message_type: dmt_score`).
class DmtScoreMessage extends ChatMessage {
  final String headline;
  final String scoreDate;
  final String instructionsScore;
  final String commitmentScore;
  final String acceptanceScore;
  final String patienceScore;
  final String consistencyScore;
  final String dmtTotalScore;
  final String dmtMaxScore;

  /// Optional API `bonus_score` (sum of consistency + patience).
  final String bonusScore;

  /// True when API payload included `acceptance_score`.
  final bool hasAcceptanceScore;

  /// True when API `acceptance_is_na` is set (show note instead of score bar).
  final bool acceptanceIsNa;

  /// API `acceptance_note` shown when [acceptanceIsNa] is true.
  final String acceptanceNote;

  const DmtScoreMessage({
    this.headline = 'DMT Score',
    this.scoreDate = '',
    this.instructionsScore = '0',
    this.commitmentScore = '0',
    this.acceptanceScore = '0',
    this.patienceScore = '0',
    this.consistencyScore = '0',
    this.dmtTotalScore = '0',
    this.dmtMaxScore = '60',
    this.bonusScore = '0',
    this.hasAcceptanceScore = false,
    this.acceptanceIsNa = false,
    this.acceptanceNote = '',
    super.messageId,
    super.isUnread,
    super.actionTaken,
    super.timestamp,
  }) : super(type: ChatMessageType.dmtScore);
}

/// Alert hit (GTT or upper/lower) - text + button to acknowledge and unlock apps
class AlertHitWithButtonMessage extends ChatMessage {
  final String text;
  final String buttonLabel;
  final String buttonType;
  final String hitType;
  final String tradeId;
  final bool isGttHit;
  final String targetHitPrice;
  final NewTradeOpportunityMessage? tradeData;

  bool get isSlHit => _isSlHitType(hitType, buttonType: buttonType);

  const AlertHitWithButtonMessage({
    required this.text,
    this.buttonLabel = 'Trade Executed',
    this.buttonType = '',
    this.hitType = '',
    this.tradeId = '',
    this.isGttHit = false,
    this.targetHitPrice = '',
    this.tradeData,
    super.messageId,
    super.isUnread,
    super.actionTaken,
    super.timestamp,
  }) : super(type: ChatMessageType.alertHitWithButton);
}

bool _isSlHitType(String hitType, {String buttonType = ''}) {
  final t = hitType.toLowerCase().trim();
  if (t == 'lower' || t == 'sl' || t == 'stop_loss') return true;
  final btn = buttonType.toLowerCase().trim();
  return btn == 'sl_executed' ||
      btn == 'sl_hit' ||
      btn == 'stop_loss_hit' ||
      btn == 'stop_loss_executed';
}

String _tradeExecutedButtonLabel(String hitType, String buttonType) {
  if (_isSlHitType(hitType, buttonType: buttonType)) return 'Yes, SL is Hit';
  return 'Yes, Target is Hit';
}

String _targetHitPriceFromPayload(
  Map<String, dynamic> p, {
  bool isSlHit = false,
}) {
  if (isSlHit) {
    for (final key in [
      'lower_price',
      'hit_price',
      'stop_loss',
      'gtt_price',
      'price',
    ]) {
      final v = p[key];
      if (v != null && v.toString().trim().isNotEmpty) {
        return v.toString().trim();
      }
    }
    final trade = p['trade'];
    if (trade is Map) {
      final tp = Map<String, dynamic>.from(trade);
      for (final key in ['stop_loss', 'current_price', 'entry_price']) {
        final v = tp[key];
        if (v != null && v.toString().trim().isNotEmpty) {
          return v.toString().trim();
        }
      }
    }
    return '';
  }

  for (final key in ['upper_price', 'hit_price', 'gtt_price', 'price']) {
    final v = p[key];
    if (v != null && v.toString().trim().isNotEmpty) {
      return v.toString().trim();
    }
  }
  final trade = p['trade'];
  if (trade is Map) {
    final tp = Map<String, dynamic>.from(trade);
    for (final key in ['take_profit', 'current_price', 'entry_price']) {
      final v = tp[key];
      if (v != null && v.toString().trim().isNotEmpty) {
        return v.toString().trim();
      }
    }
  }
  return '';
}

/// Parse API message JSON into one or more chat messages.
/// Trade payloads can include both normal text + trade card, so we return a list.
List<ChatMessage> chatMessagesFromJson(Map<String, dynamic> json) {
  final messageType = (json['message_type'] ?? json['type'] ?? '').toString();
  final entityType = (json['entity_type'] ?? '').toString();
  final message = (json['message'] ?? '').toString();
  final messageId = (json['message_id'] ?? '').toString();
  final status = (json['message_status'] ?? '').toString().toLowerCase();
  final isUnread = status == 'unread';
  final buttonTypeOuter = (json['button_type'] ?? '').toString();
  final actionTaken = json['action_taken'];
  final outerTimestamp = (json['timestamp'] ?? '').toString();
  // Missing flags default so older edit messages still show expected fields.
  final entryChanged = json.containsKey('entry_changed')
      ? _parseBoolFlag(json['entry_changed'])
      : false;
  final slChanged = json.containsKey('sl_changed')
      ? _parseBoolFlag(json['sl_changed'])
      : true;
  final tpChanged = json.containsKey('tp_changed')
      ? _parseBoolFlag(json['tp_changed'])
      : true;
  final payload = json['payload'];
  final payloadMap = payload is Map<String, dynamic>
      ? payload
      : (payload is Map ? Map<String, dynamic>.from(payload) : null);
  final payloadTradeMap = payloadMap?['trade'] is Map
      ? Map<String, dynamic>.from(payloadMap!['trade'] as Map)
      : null;
  final relatedTradeId = _resolveTradeId(
    payloadMap ?? <String, dynamic>{},
    payloadTradeMap,
  );

  /// Trade map: [entity_type] is trade, or legacy [message_type] == trade.
  /// Button rows with [entity_type] trade (e.g. open_app_button) map here, not alert UI.
  final isTrade =
      payload != null &&
      payload is Map &&
      (entityType == 'trade' || messageType == 'trade');

  final isAlertButton = messageType == 'button' && entityType == 'alert';

  /// For `message_type: text`, always show plain text only.
  if (messageType.toLowerCase() == 'text') {
    return [
      SimpleTextMessage(
        text: message,
        tradeId: relatedTradeId,
        messageId: messageId,
        isUnread: isUnread,
        actionTaken: actionTaken,
        timestamp: outerTimestamp,
      ),
    ];
  }

  /// For `message_type: create_process` or standalone `button`
  if (messageType.toLowerCase() == 'create_process' ||
      (messageType.toLowerCase() == 'button' && !isAlertButton && !isTrade)) {
    return [
      AgentWithButtonMessage(
        text: '',
        buttonLabel: message.isNotEmpty ? message : 'CREATE A PROCESS',
        messageId: messageId,
        isUnread: isUnread,
        actionTaken: actionTaken,
        timestamp: outerTimestamp,
      ),
    ];
  }

  /// Backend AI waiting/status messages — never treat as trade cards.
  /// `message_type: ai_msgs` always wins; do not inspect `entity_type`.
  if (messageType.toLowerCase() == 'ai_msgs' ||
      messageType.toLowerCase() == 'ai_msg') {
    return [
      AiWaitingMessage(
        text: message.isNotEmpty ? message : 'Monkk is waiting',
        tradeId: relatedTradeId,
        messageId: messageId,
        isUnread: isUnread,
        actionTaken: actionTaken,
        timestamp: outerTimestamp,
      ),
    ];
  }

  if (messageType == 'dmt_score' || entityType == 'dmt_score') {
    final p = payloadMap ?? <String, dynamic>{};
    final hasAcceptance = p.containsKey('acceptance_score');
    final acceptanceIsNa = p.containsKey('acceptance_is_na')
        ? _parseBoolFlag(p['acceptance_is_na'])
        : false;
    return [
      DmtScoreMessage(
        headline: message.isNotEmpty ? message : 'DMT Score',
        scoreDate: (p['score_date'] ?? '').toString(),
        instructionsScore: (p['instructions_score'] ??
                p['process_score'] ??
                '0')
            .toString(),
        commitmentScore: (p['commitment_score'] ?? '0').toString(),
        acceptanceScore: (p['acceptance_score'] ?? '0').toString(),
        patienceScore: (p['patience_score'] ?? '0').toString(),
        consistencyScore: (p['consistency_score'] ?? '0').toString(),
        dmtTotalScore: (p['dmt_total_score'] ?? '0').toString(),
        dmtMaxScore: (p['dmt_max_score'] ?? '60').toString(),
        bonusScore: (p['bonus_score'] ?? '0').toString(),
        hasAcceptanceScore: hasAcceptance,
        acceptanceIsNa: acceptanceIsNa,
        acceptanceNote: (p['acceptance_note'] ?? '').toString().trim(),
        messageId: messageId,
        isUnread: isUnread,
        actionTaken: actionTaken,
        timestamp: outerTimestamp,
      ),
    ];
  }

  if (isAlertButton) {
    final p = payload != null && payload is Map
        ? Map<String, dynamic>.from(payload)
        : <String, dynamic>{};
    final buttonType = (json['button_type'] ?? '').toString();
    final hitType = (p['hit_type'] ?? '').toString();
    final isSlHit = _isSlHitType(hitType, buttonType: buttonType);
    final isTradeExecutedConfirm = buttonType == 'trade_executed' ||
        buttonType == 'sl_executed' ||
        buttonType == 'sl_hit' ||
        buttonType == 'stop_loss_hit' ||
        buttonType == 'stop_loss_executed' ||
        isSlHit;
    final buttonLabel = isTradeExecutedConfirm
        ? _tradeExecutedButtonLabel(hitType, buttonType)
        : (p['button_label'] ?? p['buttonLabel'] ?? 'Trade Executed').toString();
    final tradeId = _resolveTradeId(p);

    bool isGttHit = p['gtt_price'] != null;
    NewTradeOpportunityMessage? tradeData;
    if (isGttHit && p['trade'] != null && p['trade'] is Map) {
      final tp = Map<String, dynamic>.from(p['trade']);
      final header = (tp['header'] ?? '').toString();
      final name = (tp['name'] ?? '').toString();
      final symbol = (tp['symbol'] ?? '').toString();
      final exchange = (tp['exchange'] ?? '').toString();
      final entryPrice = (tp['entry_price'] ?? '').toString();
      final stopLoss = (tp['stop_loss'] ?? '').toString();
      final takeProfit = (tp['take_profit'] ?? '').toString();
      final currentPrice = (tp['current_price'] ?? '').toString();
      final action = (tp['action'] ?? '').toString();
      final preferGttHistory = buttonTypeOuter == 'edit_gtt_button' ||
          action.toLowerCase() == 'editgtt';
      final oldLevels = _resolveOldLevels(tp, preferGttHistory: preferGttHistory);
      final nestedTradeId = _resolveTradeId(p, tp);
      final nestedTradeUid = _resolveTradeUid(p, tp);
      final analystFromTrade = (tp['analyst_info'] ?? tp['analystInfo'] ?? '')
          .toString()
          .trim();

      tradeData = NewTradeOpportunityMessage(
        analystInfo: analystFromTrade.isNotEmpty
            ? analystFromTrade
            : (exchange.isNotEmpty
                  ? 'TRADE SIGNAL - $exchange'
                  : 'TRADE SIGNAL'),
        instrument: header,
        contract: symbol,
        stopLoss: stopLoss,
        entryRange: entryPrice,
        frr: takeProfit,
        rtt: currentPrice,
        lotNumbers: const [1, 1, 1, 1],
        action: action,
        exchange: exchange,
        tradeId: nestedTradeId,
        tradeUid: nestedTradeUid,
        oldStopLoss: oldLevels.oldSl,
        oldTakeProfit: oldLevels.oldTp,
        oldEntryPrice: oldLevels.oldEntry,
        apiMessage: message.trim(),
        buttonType: buttonTypeOuter,
        tradeName: name,
        tradeSymbol: symbol,
        timestamp: (tp['timestamp'] ?? outerTimestamp).toString(),
        entryChanged: entryChanged,
        slChanged: slChanged,
        tpChanged: tpChanged,
        messageId: messageId,
        isUnread: isUnread,
        actionTaken: actionTaken,
      );
    }

    final resolvedTradeId = (tradeData?.tradeId.trim().isNotEmpty ?? false)
        ? tradeData!.tradeId
        : tradeId;

    return [
      AlertHitWithButtonMessage(
        text: message.isNotEmpty ? message : 'Trading App Unlocked',
        buttonLabel: buttonLabel,
        buttonType: buttonType,
        hitType: hitType,
        tradeId: resolvedTradeId,
        isGttHit: isGttHit,
        targetHitPrice: _targetHitPriceFromPayload(p, isSlHit: isSlHit),
        tradeData: tradeData,
        messageId: messageId,
        isUnread: isUnread,
        actionTaken: actionTaken,
        timestamp: outerTimestamp,
      ),
    ];
  }

  if (isTrade) {
    final p = Map<String, dynamic>.from(payload);
    final header = (p['header'] ?? '').toString();
    final symbol = (p['symbol'] ?? '').toString();
    final name = (p['name'] ?? '').toString();
    final contract = symbol.trim().isNotEmpty ? symbol : name;
    final exchange = (p['exchange'] ?? '').toString();
    final entryPrice = (p['entry_price'] ?? '').toString();
    final stopLoss = (p['stop_loss'] ?? '').toString();
    final takeProfit = (p['take_profit'] ?? '').toString();
    final currentPrice = (p['current_price'] ?? '').toString();
    final action = (p['action'] ?? '').toString();
    final preferGttHistory = buttonTypeOuter == 'edit_gtt_button' ||
        action.toLowerCase() == 'editgtt';
    final oldLevels = _resolveOldLevels(p, preferGttHistory: preferGttHistory);
    final tradeId = _resolveTradeId(p);
    final tradeUid = _resolveTradeUid(p);
    final analystFromPayload = (p['analyst_info'] ?? p['analystInfo'] ?? '')
        .toString()
        .trim();
    final apiMessage = message.trim();

    final parsed = <ChatMessage>[];
    final tradeTimestamp = (p['timestamp'] ?? outerTimestamp).toString();
    final tradeMessage = NewTradeOpportunityMessage(
      analystInfo: analystFromPayload.isNotEmpty
          ? analystFromPayload
          : (exchange.isNotEmpty ? 'TRADE SIGNAL - $exchange' : 'TRADE SIGNAL'),
      instrument: header,
      contract: contract,
      stopLoss: stopLoss,
      entryRange: entryPrice,
      frr: takeProfit,
      rtt: currentPrice,
      lotNumbers: const [1, 1, 1, 1],
      action: action,
      exchange: exchange,
      tradeId: tradeId,
      tradeUid: tradeUid,
      oldStopLoss: oldLevels.oldSl,
      oldTakeProfit: oldLevels.oldTp,
      oldEntryPrice: oldLevels.oldEntry,
      apiMessage: apiMessage,
      buttonType: buttonTypeOuter,
      tradeName: name,
      tradeSymbol: symbol,
      timestamp: tradeTimestamp,
      entryChanged: entryChanged,
      slChanged: slChanged,
      tpChanged: tpChanged,
      messageId: messageId,
      isUnread: isUnread,
      actionTaken: actionTaken,
    );
    parsed.add(tradeMessage);
    if (_isTradePromptAction(action)) {
      parsed.add(
        TradeExecutionPromptMessage(
          tradeData: tradeMessage,
          messageId: messageId,
          isUnread: isUnread,
          actionTaken: actionTaken,
          timestamp: tradeTimestamp,
        ),
      );
    }
    return parsed;
  }

  return [
    SimpleTextMessage(
      text: message.isNotEmpty ? message : 'Unknown message',
      tradeId: relatedTradeId,
      messageId: messageId,
      isUnread: isUnread,
      actionTaken: actionTaken,
      timestamp: outerTimestamp,
    ),
  ];
}

/// Numeric `trade_id` / `id` for backend APIs (`alerts.trade_id` is INT).
String _resolveTradeId(Map<String, dynamic> p, [Map<String, dynamic>? nested]) {
  for (final map in [p, if (nested != null) nested]) {
    final tid = (map['trade_id'] ?? '').toString().trim();
    if (tid.isNotEmpty && int.tryParse(tid) != null) return tid;
  }
  for (final map in [p, if (nested != null) nested]) {
    final id = (map['id'] ?? '').toString().trim();
    if (id.isNotEmpty && int.tryParse(id) != null) return id;
  }
  for (final map in [p, if (nested != null) nested]) {
    final tid = (map['trade_id'] ?? '').toString().trim();
    if (tid.isNotEmpty) return tid;
  }
  for (final map in [p, if (nested != null) nested]) {
    final id = (map['id'] ?? '').toString().trim();
    if (id.isNotEmpty) return id;
  }
  return '';
}

/// Unique `trade_uid` for local expiry only — never send this as `trade_id`.
String _resolveTradeUid(Map<String, dynamic> p, [Map<String, dynamic>? nested]) {
  for (final map in [p, if (nested != null) nested]) {
    final uid = (map['trade_uid'] ?? '').toString().trim();
    if (uid.isNotEmpty) return uid;
  }
  return '';
}

String _historyString(dynamic value) {
  if (value == null) return '';
  final s = value.toString().trim();
  if (s.isEmpty || s.toLowerCase() == 'null') return '';
  return s;
}

String _firstHistory(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final s = _historyString(map[key]);
    if (s.isNotEmpty) return s;
  }
  return '';
}

({String oldSl, String oldTp, String oldEntry}) _resolveOldLevels(
  Map<String, dynamic> map, {
  required bool preferGttHistory,
}) {
  final slKeys = preferGttHistory
      ? ['gtt_old_stop_loss_history', 'old_stop_loss_history']
      : ['old_stop_loss_history', 'gtt_old_stop_loss_history'];
  final tpKeys = preferGttHistory
      ? ['gtt_old_take_profit_history', 'old_take_profit_history']
      : ['old_take_profit_history', 'gtt_old_take_profit_history'];
  return (
    oldSl: _firstHistory(map, slKeys),
    oldTp: _firstHistory(map, tpKeys),
    oldEntry: _firstHistory(map, ['old_entry_price_history']),
  );
}

bool _parseBoolFlag(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final s = value?.toString().toLowerCase().trim() ?? '';
  return s == 'true' || s == '1' || s == 'yes';
}

bool _isTradePromptAction(String action) {
  final a = action.toLowerCase();
  // Edit flows have dedicated UI (edit_button / edit_gtt_button).
  return a == 'add' || a == 'update';
}

/// Backward-compatible helper when callers expect a single message.
ChatMessage chatMessageFromJson(Map<String, dynamic> json) {
  final parsed = chatMessagesFromJson(json);
  return parsed.first;
}
