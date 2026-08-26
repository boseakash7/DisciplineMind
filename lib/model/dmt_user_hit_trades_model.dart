import 'dmt_level_model.dart';

/// Response from `POST /api/dmt-level/user-hit-trades`.
class DmtUserHitTradesResponse {
  final String? status;
  final DmtUserHitTradesPayload? payload;

  const DmtUserHitTradesResponse({this.status, this.payload});

  factory DmtUserHitTradesResponse.fromJson(Map<String, dynamic> json) {
    final rawPayload = json['payload'];
    return DmtUserHitTradesResponse(
      status: json['status']?.toString(),
      payload: rawPayload is Map
          ? DmtUserHitTradesPayload.fromJson(
              Map<String, dynamic>.from(rawPayload),
            )
          : null,
    );
  }

  bool get isOk => (status ?? '').toLowerCase() == 'ok';
}

class DmtUserHitTradesPayload {
  final DmtLevel? level;
  final int totalTrades;
  final int totalWins;
  final double? tradeAccuracy;
  final String tradeAccuracyText;
  final dynamic totalAverageReturnPercentage;
  final dynamic totalMctAverageReturnPercentage;
  final List<DmtHitTrade> trades;

  const DmtUserHitTradesPayload({
    this.level,
    this.totalTrades = 0,
    this.totalWins = 0,
    this.tradeAccuracy,
    this.tradeAccuracyText = '',
    this.totalAverageReturnPercentage = 0,
    this.totalMctAverageReturnPercentage = 0,
    this.trades = const [],
  });

  factory DmtUserHitTradesPayload.fromJson(Map<String, dynamic> json) {
    final rawTrades = json['trades'];
    final list = <DmtHitTrade>[];
    if (rawTrades is List) {
      for (final item in rawTrades) {
        if (item is Map) {
          list.add(DmtHitTrade.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    final levelRaw = json['level'];
    return DmtUserHitTradesPayload(
      level: levelRaw is Map
          ? DmtLevel.fromJson(Map<String, dynamic>.from(levelRaw))
          : null,
      totalTrades: _parseInt(json['total_trades']),
      totalWins: _parseInt(json['total_wins']),
      tradeAccuracy: _parseDouble(json['trade_accuracy']),
      tradeAccuracyText: json['trade_accuracy_text']?.toString().trim() ?? '',
      totalAverageReturnPercentage: json['total_average_return_percentage'] ?? 0,
      totalMctAverageReturnPercentage: json['total_mct_average_return_percentage'] ?? 0,
      trades: list,
    );
  }

  /// Fallback win rate when API omits accuracy fields (0–100).
  double? get computedAccuracyPercent {
    if (totalTrades <= 0) return null;
    return (totalWins / totalTrades) * 100;
  }

  /// Accuracy as 0–100 for progress UI.
  double? get tradeAccuracyPercentValue {
    if (tradeAccuracy != null) {
      return tradeAccuracy!.clamp(0.0, 100.0);
    }
    if (tradeAccuracyText.isNotEmpty) {
      final parsed = double.tryParse(
        tradeAccuracyText.replaceAll('%', '').trim(),
      );
      if (parsed != null) return parsed.clamp(0.0, 100.0);
    }
    return computedAccuracyPercent?.clamp(0.0, 100.0);
  }

  /// Label for overview, e.g. `25%`.
  String get displayTradeAccuracy {
    if (tradeAccuracyText.isNotEmpty) return tradeAccuracyText;
    if (tradeAccuracy != null) {
      final v = tradeAccuracy!;
      if (v == v.roundToDouble()) return '${v.round()}%';
      return '${v.toStringAsFixed(1)}%';
    }
    final computed = computedAccuracyPercent;
    if (computed != null) {
      return '${computed.toStringAsFixed(2)}%';
    }
    return '';
  }
}

class DmtHitTrade {
  final int alertId;
  final int tradeId;
  final int dmtLevelId;
  final String dmtLevelCode;
  final String exchange;
  final String tradingsymbol;
  final double? currentPrice;
  final double? upperPrice;
  final double? lowerPrice;
  final double? gttPrice;
  final String hitType;
  final double? hitPrice;
  final double? returnPercentage;
  final String hitAtFormatted;
  final String status;
  final String createdAtFormatted;
  final DmtHitTradeDetail? trade;

  const DmtHitTrade({
    this.alertId = 0,
    this.tradeId = 0,
    this.dmtLevelId = 0,
    this.dmtLevelCode = '',
    this.exchange = '',
    this.tradingsymbol = '',
    this.currentPrice,
    this.upperPrice,
    this.lowerPrice,
    this.gttPrice,
    this.hitType = '',
    this.hitPrice,
    this.returnPercentage,
    this.hitAtFormatted = '',
    this.status = '',
    this.createdAtFormatted = '',
    this.trade,
  });

  factory DmtHitTrade.fromJson(Map<String, dynamic> json) {
    final tradeRaw = json['trade'];
    return DmtHitTrade(
      alertId: _parseInt(json['alert_id']),
      tradeId: _parseInt(json['trade_id']),
      dmtLevelId: _parseInt(json['dmt_level_id']),
      dmtLevelCode: json['dmt_level_code']?.toString() ?? '',
      exchange: json['exchange']?.toString() ?? '',
      tradingsymbol: json['tradingsymbol']?.toString() ?? '',
      currentPrice: _parseDouble(json['current_price']),
      upperPrice: _parseDouble(json['upper_price']),
      lowerPrice: _parseDouble(json['lower_price']),
      gttPrice: _parseDouble(json['gtt_price']),
      hitType: json['hit_type']?.toString() ?? '',
      hitPrice: _parseDouble(json['hit_price']),
      returnPercentage: _parseDouble(json['return_percentage']),
      hitAtFormatted: json['hit_at_formatted']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      createdAtFormatted: json['created_at_formatted']?.toString() ?? '',
      trade: tradeRaw is Map
          ? DmtHitTradeDetail.fromJson(Map<String, dynamic>.from(tradeRaw))
          : null,
    );
  }

  String get displayTitle {
    final t = trade;
    if (t != null && t.header.isNotEmpty) return t.header;
    if (tradingsymbol.isNotEmpty) return tradingsymbol;
    return 'Trade';
  }

  String get displayDate {
    if (hitAtFormatted.isNotEmpty) return formatTradeTabDate(hitAtFormatted);
    if (createdAtFormatted.isNotEmpty) {
      return formatTradeTabDate(createdAtFormatted);
    }
    return '';
  }

  String get displayHitAt => formatTradeTabDate(hitAtFormatted);

  String get displayCreatedAt => formatTradeTabDate(createdAtFormatted);

  /// Return % from API, or estimated from entry → hit when API omits it.
  double? get returnPercent {
    if (returnPercentage != null) return returnPercentage;
    final entry = trade?.entryPrice;
    final hit = hitPrice;
    if (entry == null || hit == null || entry == 0) return null;
    final direction = (trade?.direction ?? 'buy').toLowerCase();
    final diff = hit - entry;
    final signed = direction == 'sell' ? -diff : diff;
    return (signed / entry) * 100;
  }

  bool get isProfitable {
    final pct = returnPercent;
    if (pct != null) return pct >= 0;
    return hitType.toLowerCase() == 'upper';
  }

  String get displayReturn {
    final pct = returnPercent;
    if (pct == null) return '—';
    return '${pct.toStringAsFixed(2)}%';
  }
}

class DmtHitTradeDetail {
  final int id;
  final String tradeUid;
  final String header;
  final String symbol;
  final String name;
  final String exchange;
  final double? entryPrice;
  final String direction;
  final double? stopLoss;
  final double? takeProfit;
  final double? currentPrice;
  final String status;

  const DmtHitTradeDetail({
    this.id = 0,
    this.tradeUid = '',
    this.header = '',
    this.symbol = '',
    this.name = '',
    this.exchange = '',
    this.entryPrice,
    this.direction = '',
    this.stopLoss,
    this.takeProfit,
    this.currentPrice,
    this.status = '',
  });

  factory DmtHitTradeDetail.fromJson(Map<String, dynamic> json) {
    return DmtHitTradeDetail(
      id: _parseInt(json['id']),
      tradeUid: json['trade_uid']?.toString() ?? '',
      header: json['header']?.toString() ?? '',
      symbol: json['symbol']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      exchange: json['exchange']?.toString() ?? '',
      entryPrice: _parseDouble(json['entry_price']),
      direction: json['direction']?.toString() ?? '',
      stopLoss: _parseDouble(json['stop_loss']),
      takeProfit: _parseDouble(json['take_profit']),
      currentPrice: _parseDouble(json['current_price']),
      status: json['status']?.toString() ?? '',
    );
  }
}

/// Trades tab date: day + month + optional time, e.g. `22-May 11:19 AM` (year removed).
String formatTradeTabDate(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return trimmed;

  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  String monthLabel(String month) {
    if (month.length < 2) return month;
    return '${month[0].toUpperCase()}${month.substring(1).toLowerCase()}';
  }

  String withTime(String datePart, String? timePart) {
    final time = timePart?.trim() ?? '';
    if (time.isEmpty) return datePart;
    return '$datePart $time';
  }

  // e.g. 22-May-2026 11:19 AM
  final namedMonth = RegExp(
    r'^(\d{1,2})-([A-Za-z]+)-\d{4}(?:\s+(.+))?$',
  ).firstMatch(trimmed);
  if (namedMonth != null) {
    final day = namedMonth.group(1)!.padLeft(2, '0');
    final datePart = '$day-${monthLabel(namedMonth.group(2)!)}';
    return withTime(datePart, namedMonth.group(3));
  }

  // e.g. 22-05-2026 11:19 AM
  final numericMonth = RegExp(
    r'^(\d{1,2})-(\d{1,2})-\d{4}(?:\s+(.+))?$',
  ).firstMatch(trimmed);
  if (numericMonth != null) {
    final day = numericMonth.group(1)!.padLeft(2, '0');
    final monthIndex = int.tryParse(numericMonth.group(2)!) ?? 0;
    if (monthIndex >= 1 && monthIndex <= 12) {
      final datePart = '$day-${months[monthIndex - 1]}';
      return withTime(datePart, numericMonth.group(3));
    }
  }

  try {
    final parsed = DateTime.parse(trimmed);
    final day = parsed.day.toString().padLeft(2, '0');
    final datePart = '$day-${months[parsed.month - 1]}';
    final hour = parsed.hour;
    final minute = parsed.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour % 12 == 0 ? 12 : hour % 12;
    return '$datePart $hour12:$minute $period';
  } catch (_) {
    return trimmed.replaceAll(RegExp(r'-\d{4}'), '').trim();
  }
}

int _parseInt(dynamic v) => int.tryParse(v?.toString() ?? '') ?? 0;

double? _parseDouble(dynamic v) {
  if (v == null) return null;
  return double.tryParse(v.toString());
}
