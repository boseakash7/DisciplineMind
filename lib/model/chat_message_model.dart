/// Chat message types
enum ChatMessageType {
  simpleText,
  newTradeOpportunity,
  tradeExecutionPrompt,
  tradeExecuted,
  agentWithButton, // e.g. "Register for Demo" button
  alertHitWithButton, // GTT or upper/lower alert hit - shows text + button to unlock
}

/// Base chat message
abstract class ChatMessage {
  final ChatMessageType type;
  final bool isFromUser;
  final String messageId;
  final bool isUnread;

  const ChatMessage({
    required this.type,
    this.isFromUser = false,
    this.messageId = '',
    this.isUnread = false,
  });
}

/// Simple text message
class SimpleTextMessage extends ChatMessage {
  final String text;

  const SimpleTextMessage({
    required this.text,
    super.isFromUser = false,
    super.messageId,
    super.isUnread,
  })
    : super(type: ChatMessageType.simpleText);
}

/// Agent message with a button (e.g. Register for Demo)
class AgentWithButtonMessage extends ChatMessage {
  final String text;
  final String buttonLabel;

  const AgentWithButtonMessage({required this.text, required this.buttonLabel})
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
  final String tradeId; // ID of the trade
  /// Previous SL value from payload key `old_stop_loss_history` (edit flow).
  final String oldStopLoss;
  /// Outer API `message` when [entity_type] is trade (e.g. instructions).
  final String apiMessage;

  /// Outer API `button_type` when [message_type] is button (e.g. open_app_button).
  final String buttonType;

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
    super.messageId,
    super.isUnread,
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
  }) : super(type: ChatMessageType.tradeExecutionPrompt);
}

/// Alert hit (GTT or upper/lower) - text + button to acknowledge and unlock apps
class AlertHitWithButtonMessage extends ChatMessage {
  final String text;
  final String buttonLabel;
  final bool isGttHit;
  final NewTradeOpportunityMessage? tradeData;

  const AlertHitWithButtonMessage({
    required this.text,
    this.buttonLabel = 'Trade Executed',
    this.isGttHit = false,
    this.tradeData,
    super.messageId,
    super.isUnread,
  }) : super(type: ChatMessageType.alertHitWithButton);
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
  final payload = json['payload'];

  /// Trade map: [entity_type] is trade, or legacy [message_type] == trade.
  /// Button rows with [entity_type] trade (e.g. open_app_button) map here, not alert UI.
  final isTrade =
      payload != null &&
      payload is Map &&
      (entityType == 'trade' || messageType == 'trade');

  final isAlertButton = messageType == 'button' && entityType == 'alert';

  /// Plain copy only — ignore payload / entity (e.g. alert with trade nested).
  if (messageType.toLowerCase() == 'text' &&
      buttonTypeOuter.toLowerCase() == 'no_button') {
    return [
      SimpleTextMessage(text: message, messageId: messageId, isUnread: isUnread),
    ];
  }

  if (isAlertButton) {
    final p = payload != null && payload is Map
        ? Map<String, dynamic>.from(payload)
        : <String, dynamic>{};
    final buttonLabel =
        (p['button_label'] ?? p['buttonLabel'] ?? 'Trade Executed').toString();

    bool isGttHit = p['gtt_price'] != null;
    NewTradeOpportunityMessage? tradeData;
    if (isGttHit && p['trade'] != null && p['trade'] is Map) {
      final tp = Map<String, dynamic>.from(p['trade']);
      final header = (tp['header'] ?? '').toString();
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
        messageId: messageId,
        isUnread: isUnread,
      );
    }

    return [
      AlertHitWithButtonMessage(
        text: message.isNotEmpty ? message : 'Your alert has been triggered.',
        buttonLabel: buttonLabel,
        isGttHit: isGttHit,
        tradeData: tradeData,
        messageId: messageId,
        isUnread: isUnread,
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
      messageId: messageId,
      isUnread: isUnread,
    );
    parsed.add(tradeMessage);
    if (_isTradePromptAction(action)) {
      parsed.add(
        TradeExecutionPromptMessage(
          tradeData: tradeMessage,
          messageId: messageId,
          isUnread: isUnread,
        ),
      );
    }
    return parsed;
  }

  return [
    SimpleTextMessage(
      text: message.isNotEmpty ? message : 'Unknown message',
      messageId: messageId,
      isUnread: isUnread,
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
