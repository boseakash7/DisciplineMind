/// Chat message types
enum ChatMessageType {
  simpleText,
  aiWaiting, // Backend AI status bubble (`message_type: ai_msgs`)
  newTradeOpportunity,
  tradeExecutionPrompt,
  tradeExecuted,
  agentWithButton, // e.g. "Register for Demo" button
  alertHitWithButton, // GTT or upper/lower alert hit - shows text + button to unlock
  dmtScore, // Daily discipline analysis score card
  tradeSignal, // Process overview / Market signal card with quick actions
}

/// Base chat message
abstract class ChatMessage {
  final ChatMessageType type;
  final bool isFromUser;
  final String messageId;
  final bool isUnread;
  /// Backend control key: show action buttons only when this is null.
  final dynamic actionTaken;

  const ChatMessage({
    required this.type,
    this.isFromUser = false,
    this.messageId = '',
    this.isUnread = false,
    this.actionTaken,
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
    super.messageId,
    super.isUnread,
    super.actionTaken,
  }) : super(type: ChatMessageType.agentWithButton);
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
  final String tradeId; // ID of the trade
  /// Previous SL value from payload key `old_stop_loss_history` (edit flow).
  final String oldStopLoss;
  /// Outer API `message` when [entity_type] is trade (e.g. instructions).
  final String apiMessage;

  /// Outer API `button_type` when [message_type] is button (e.g. open_app_button).
  final String buttonType;
  /// Preferred trade card title from payload `name`.
  final String tradeName;
  /// Preferred trade card subtitle from payload `symbol`.
  final String tradeSymbol;

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
    this.oldStopLoss = '',
    this.apiMessage = '',
    this.buttonType = '',
    this.tradeName = '',
    this.tradeSymbol = '',
    super.messageId,
    super.isUnread,
    super.actionTaken,
  }) : super(type: ChatMessageType.newTradeOpportunity);
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
  }) : super(type: ChatMessageType.tradeExecutionPrompt);
}

/// Daily DMT discipline score card (`message_type: dmt_score`).
class DmtScoreMessage extends ChatMessage {
  final String headline;
  final String scoreDate;
  final String instructionsScore;
  final String commitmentScore;
  final String patienceScore;
  final String consistencyScore;
  final String dmtTotalScore;
  final String dmtMaxScore;

  const DmtScoreMessage({
    this.headline = 'DMT Score',
    this.scoreDate = '',
    this.instructionsScore = '0',
    this.commitmentScore = '0',
    this.patienceScore = '0',
    this.consistencyScore = '0',
    this.dmtTotalScore = '0',
    this.dmtMaxScore = '60',
    super.messageId,
    super.isUnread,
    super.actionTaken,
  }) : super(type: ChatMessageType.dmtScore);
}

/// Trade Signal / Market Overview message with day range and quick actions
class TradeSignalMessage extends ChatMessage {
  final String headline;
  final String signalId;
  final String userId;
  final String processId;
  final String instrument;
  final String exchange;
  final String tradingsymbol;
  final String openPrice;
  final String currentPrice;
  final String dayLow;
  final String dayHigh;
  final String previousClose;
  final String gapPercent;
  final String changePercent;
  final String sequenceNo;
  final String status;
  final String createdAt;
  final String timestamp;

  const TradeSignalMessage({
    required this.headline,
    this.signalId = '',
    this.userId = '',
    this.processId = '',
    this.instrument = '',
    this.exchange = '',
    this.tradingsymbol = '',
    this.openPrice = '',
    this.currentPrice = '',
    this.dayLow = '',
    this.dayHigh = '',
    this.previousClose = '',
    this.gapPercent = '',
    this.changePercent = '',
    this.sequenceNo = '',
    this.status = '',
    this.createdAt = '',
    this.timestamp = '',
    super.messageId,
    super.isUnread,
    super.actionTaken,
  }) : super(type: ChatMessageType.tradeSignal);
}

/// Alert hit (GTT or upper/lower) - text + button to acknowledge and unlock apps
class AlertHitWithButtonMessage extends ChatMessage {
  final String text;
  final String buttonLabel;
  final String buttonType;
  final String tradeId;
  final bool isGttHit;
  final bool isSlHit;
  final bool isTargetHit;
  final String status;
  final String targetHitPrice;
  final NewTradeOpportunityMessage? tradeData;

  const AlertHitWithButtonMessage({
    required this.text,
    this.buttonLabel = 'Trade Executed',
    this.buttonType = '',
    this.tradeId = '',
    this.isGttHit = false,
    this.isSlHit = false,
    this.isTargetHit = false,
    this.status = '',
    this.targetHitPrice = '',
    this.tradeData,
    super.messageId,
    super.isUnread,
    super.actionTaken,
  }) : super(type: ChatMessageType.alertHitWithButton);
}

String _targetHitPriceFromPayload(Map<String, dynamic> p, {bool isSlHit = false}) {
  final hitPrice = p['hit_price'] ?? p['user_hit_price'];
  if (hitPrice != null && hitPrice.toString().trim().isNotEmpty && hitPrice.toString().trim() != 'null') {
    return hitPrice.toString().trim();
  }

  final keys = isSlHit
      ? ['lower_price', 'stop_loss', 'price']
      : ['upper_price', 'gtt_price', 'take_profit', 'price'];
  for (final key in keys) {
    final v = p[key];
    if (v != null && v.toString().trim().isNotEmpty && v.toString().trim() != 'null') {
      return v.toString().trim();
    }
  }
  final trade = p['trade'];
  if (trade is Map) {
    final tp = Map<String, dynamic>.from(trade);
    final tradeKeys = isSlHit
        ? ['stop_loss', 'current_price', 'entry_price']
        : ['take_profit', 'current_price', 'entry_price'];
    for (final key in tradeKeys) {
      final v = tp[key];
      if (v != null && v.toString().trim().isNotEmpty && v.toString().trim() != 'null') {
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
  final payload = json['payload'];
  final payloadMap = payload is Map<String, dynamic>
      ? payload
      : (payload is Map ? Map<String, dynamic>.from(payload) : null);
  final payloadTradeMap = payloadMap?['trade'] is Map
      ? Map<String, dynamic>.from(payloadMap!['trade'] as Map)
      : null;
  final relatedTradeId = (payloadMap?['trade_id'] ??
          payloadMap?['id'] ??
          payloadTradeMap?['trade_id'] ??
          payloadTradeMap?['id'] ??
          payloadTradeMap?['trade_uid'] ??
          '')
      .toString();

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
      ),
    ];
  }

  /// Backend AI waiting/status messages — animated thinking / status bubble.
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
      ),
    ];
  }

  if (messageType == 'dmt_score' || entityType == 'dmt_score') {
    final p = payloadMap ?? <String, dynamic>{};
    return [
      DmtScoreMessage(
        headline: message.isNotEmpty ? message : 'DMT Score',
        scoreDate: (p['score_date'] ?? '').toString(),
        instructionsScore: (p['instructions_score'] ?? '0').toString(),
        commitmentScore: (p['commitment_score'] ?? '0').toString(),
        patienceScore: (p['patience_score'] ?? '0').toString(),
        consistencyScore: (p['consistency_score'] ?? '0').toString(),
        dmtTotalScore: (p['dmt_total_score'] ?? '0').toString(),
        dmtMaxScore: (p['dmt_max_score'] ?? '60').toString(),
        messageId: messageId,
        isUnread: isUnread,
        actionTaken: actionTaken,
      ),
    ];
  }

  if (messageType == 'trade_signal' || entityType == 'trade_signal') {
    final p = payloadMap ?? <String, dynamic>{};
    return [
      TradeSignalMessage(
        headline: message.isNotEmpty ? message : 'Market Overview',
        signalId: (p['id'] ?? '').toString(),
        userId: (p['user_id'] ?? '').toString(),
        processId: (p['v2test_trading_process_id'] ?? '').toString(),
        instrument: (p['instrument'] ?? 'Nifty 50').toString(),
        exchange: (p['exchange'] ?? 'NSE').toString(),
        tradingsymbol:
            (p['tradingsymbol'] ?? p['instrument'] ?? 'NIFTY 50').toString(),
        openPrice: (p['open_price'] ?? '').toString(),
        currentPrice: (p['current_price'] ?? '').toString(),
        dayLow: (p['day_low'] ?? '').toString(),
        dayHigh: (p['day_high'] ?? '').toString(),
        previousClose: (p['previous_close'] ?? '').toString(),
        gapPercent: (p['gap_percent'] ?? '').toString(),
        changePercent: (p['change_percent'] ?? '').toString(),
        sequenceNo: (p['sequence_no'] ?? '').toString(),
        status: (p['status'] ?? '').toString(),
        createdAt: (p['created_at'] ?? '').toString(),
        timestamp: (json['timestamp'] ?? '').toString(),
        messageId: messageId,
        isUnread: isUnread,
        actionTaken: actionTaken,
      ),
    ];
  }

  if (isAlertButton) {
    final p = payload != null && payload is Map
        ? Map<String, dynamic>.from(payload)
        : <String, dynamic>{};
    final buttonType = (json['button_type'] ?? '').toString();
    final hitType = (p['hit_type'] ?? '').toString().toLowerCase().trim();
    final pStatus = (p['status'] ?? '').toString().toLowerCase().trim();
    final tradeMap = p['trade'] is Map ? Map<String, dynamic>.from(p['trade'] as Map) : null;
    final tradeStatus = (tradeMap?['status'] ?? '').toString().toLowerCase().trim();
    final jsonStatus = (json['status'] ?? '').toString().toLowerCase().trim();
    final lowerMessage = message.toLowerCase();

    final isGttHit = p['gtt_price'] != null ||
        hitType == 'gtt' ||
        tradeStatus.contains('gtt') ||
        pStatus.contains('gtt') ||
        lowerMessage.contains('gtt hit') ||
        lowerMessage.contains('gtt is hit');

    final isSlHit = !isGttHit && (
        hitType == 'lower' ||
        hitType.contains('sl') ||
        tradeStatus == 'hit_lower' ||
        tradeStatus.contains('lower') ||
        tradeStatus.contains('sl') ||
        pStatus == 'hit_lower' ||
        jsonStatus == 'hit_lower' ||
        lowerMessage.contains('sl is hit') ||
        lowerMessage.contains('sl hit') ||
        lowerMessage.contains('stop loss')
    );

    final isTargetHit = !isGttHit && !isSlHit && (
        hitType == 'upper' ||
        hitType.contains('target') ||
        tradeStatus == 'hit_upper' ||
        tradeStatus.contains('upper') ||
        tradeStatus.contains('target') ||
        pStatus == 'hit_upper' ||
        jsonStatus == 'hit_upper' ||
        lowerMessage.contains('target order') ||
        lowerMessage.contains('target hit') ||
        lowerMessage.contains('target is hit') ||
        buttonType == 'trade_executed'
    );

    String buttonLabel;
    if (p['button_label'] != null && p['button_label'].toString().trim().isNotEmpty) {
      buttonLabel = p['button_label'].toString().trim();
    } else if (isSlHit) {
      buttonLabel = 'Yes! SL is hit';
    } else if (isGttHit) {
      buttonLabel = 'Yes! GTT is hit';
    } else if (isTargetHit || buttonType == 'trade_executed') {
      buttonLabel = 'Yes! Target is hit';
    } else {
      buttonLabel = 'Trade Executed';
    }
    final tradeId = (p['trade_id'] ?? p['id'] ?? '').toString();

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
      final oldStopLoss = (tp['old_stop_loss_history'] ?? '').toString();
      final action = (tp['action'] ?? '').toString();
      final tradeId =
          (p['trade_id'] ?? tp['trade_id'] ?? tp['id'] ?? tp['trade_uid'] ?? '')
              .toString();
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
        tradeId: tradeId,
        oldStopLoss: oldStopLoss,
        apiMessage: message.trim(),
        buttonType: buttonTypeOuter,
        tradeName: name,
        tradeSymbol: symbol,
        messageId: messageId,
        isUnread: isUnread,
        actionTaken: actionTaken,
      );
    }

    return [
      AlertHitWithButtonMessage(
        text: message.isNotEmpty ? message : 'Your alert has been triggered.',
        buttonLabel: buttonLabel,
        buttonType: buttonType,
        tradeId: tradeId,
        isGttHit: isGttHit,
        isSlHit: isSlHit,
        isTargetHit: isTargetHit,
        status: status,
        targetHitPrice: _targetHitPriceFromPayload(p, isSlHit: isSlHit),
        tradeData: tradeData,
        messageId: messageId,
        isUnread: isUnread,
        actionTaken: actionTaken,
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
    final oldStopLoss = (p['old_stop_loss_history'] ?? '').toString();
    final action = (p['action'] ?? '').toString();
    final tradeId = (p['trade_id'] ?? p['id'] ?? p['trade_uid'] ?? '')
        .toString();
    final analystFromPayload = (p['analyst_info'] ?? p['analystInfo'] ?? '')
        .toString()
        .trim();
    final apiMessage = message.trim();

    final parsed = <ChatMessage>[];
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
      oldStopLoss: oldStopLoss,
      apiMessage: apiMessage,
      buttonType: buttonTypeOuter,
      tradeName: name,
      tradeSymbol: symbol,
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
    ),
  ];
}

bool _isTradePromptAction(String action) {
  final a = action.toLowerCase();
  // Edit flow has its own dedicated UI (edit_button), so avoid generic prompt.
  return a == 'add' || a == 'update';
}

/// Backward-compatible helper when callers expect a single message.
ChatMessage chatMessageFromJson(Map<String, dynamic> json) {
  final parsed = chatMessagesFromJson(json);
  return parsed.first;
}
