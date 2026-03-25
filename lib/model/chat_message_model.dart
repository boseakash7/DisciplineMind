/// Chat message types
enum ChatMessageType {
  simpleText,
  newTradeOpportunity,
  tradeExecuted,
  agentWithButton, // e.g. "Register for Demo" button
  alertHitWithButton, // GTT or upper/lower alert hit - shows text + button to unlock
}

/// Base chat message
abstract class ChatMessage {
  final ChatMessageType type;
  final bool isFromUser;

  const ChatMessage({required this.type, this.isFromUser = false});
}

/// Simple text message
class SimpleTextMessage extends ChatMessage {
  final String text;

  const SimpleTextMessage({required this.text, super.isFromUser = false})
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
  }) : super(type: ChatMessageType.newTradeOpportunity);
}

/// Trade Executed - unlocks trading apps, button is display-only
class TradeExecutedMessage extends ChatMessage {
  final String text;
  final String buttonLabel;

  const TradeExecutedMessage({
    this.text =
        'Trading App is unlocked. Let me know once u set your Trade as per the above Instructions by clicking on the below button',
    this.buttonLabel = 'Trade Executed',
  }) : super(type: ChatMessageType.tradeExecuted);
}

/// Alert hit (GTT or upper/lower) - text + button to acknowledge and unlock apps
class AlertHitWithButtonMessage extends ChatMessage {
  final String text;
  final String buttonLabel;

  const AlertHitWithButtonMessage({
    required this.text,
    this.buttonLabel = 'Trade Executed',
  }) : super(type: ChatMessageType.alertHitWithButton);
}

/// Parse API message JSON into ChatMessage.
/// Uses message_type + entity_type to decide: entity_type "trade" = trade card.
ChatMessage chatMessageFromJson(Map<String, dynamic> json) {
  final messageType = (json['message_type'] ?? json['type'] ?? '').toString();
  final entityType = (json['entity_type'] ?? '').toString();
  final message = (json['message'] ?? '').toString();
  final payload = json['payload'];

  final isTrade =
      (entityType == 'trade' || messageType == 'trade') &&
      payload != null &&
      payload is Map;

  final isAlertButton =
      messageType == 'button' && entityType == 'alert';

  if (isAlertButton) {
    final p = payload != null && payload is Map
        ? Map<String, dynamic>.from(payload)
        : <String, dynamic>{};
    final buttonLabel =
        (p['button_label'] ?? p['buttonLabel'] ?? 'Trade Executed').toString();
    return AlertHitWithButtonMessage(
      text: message.isNotEmpty ? message : 'Your alert has been triggered.',
      buttonLabel: buttonLabel,
    );
  }

  if (isTrade) {
    final p = Map<String, dynamic>.from(payload);
    final header = (p['header'] ?? '').toString();
    final symbol = (p['symbol'] ?? '').toString();
    final exchange = (p['exchange'] ?? '').toString();
    final entryPrice = (p['entry_price'] ?? '').toString();
    final stopLoss = (p['stop_loss'] ?? '').toString();
    final takeProfit = (p['take_profit'] ?? '').toString();
    final currentPrice = (p['current_price'] ?? '').toString();
    final action = (p['action'] ?? '').toString();

    return NewTradeOpportunityMessage(
      analystInfo: exchange.isNotEmpty
          ? 'TRADE SIGNAL - $exchange'
          : 'TRADE SIGNAL',
      instrument: header,
      contract: symbol,
      stopLoss: stopLoss,
      entryRange: entryPrice,
      frr: takeProfit,
      rtt: currentPrice,
      lotNumbers: const [1, 1, 1, 1],
      action: action,
      exchange: exchange,
    );
  }

  return SimpleTextMessage(
    text: message.isNotEmpty ? message : 'Unknown message',
  );
}
