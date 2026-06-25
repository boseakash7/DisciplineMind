import 'package:discipline_mind/model/dmt_level_model.dart';

/// Response from `POST /api/dmt-level/user-return-percentages`.
class DmtUserReturnPercentagesResponse {
  final String? status;
  final DmtUserReturnPercentagesPayload? payload;

  const DmtUserReturnPercentagesResponse({this.status, this.payload});

  factory DmtUserReturnPercentagesResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['payload'];
    return DmtUserReturnPercentagesResponse(
      status: json['status']?.toString(),
      payload: raw is Map
          ? DmtUserReturnPercentagesPayload.fromJson(
              Map<String, dynamic>.from(raw),
            )
          : null,
    );
  }

  bool get isOk => (status ?? '').toLowerCase() == 'ok';
}

class DmtUserReturnPercentagesPayload {
  final int userId;
  final DmtLevel? level;
  final String? scoreDate;
  final int totalRecords;
  final double averageReturnPercentage;
  final String averageReturnPercentageText;
  final List<DmtTradeReturn> returns;

  const DmtUserReturnPercentagesPayload({
    this.userId = 0,
    this.level,
    this.scoreDate,
    this.totalRecords = 0,
    this.averageReturnPercentage = 0,
    this.averageReturnPercentageText = '',
    this.returns = const [],
  });

  factory DmtUserReturnPercentagesPayload.fromJson(Map<String, dynamic> json) {
    final rawReturns = json['returns'];
    final items = <DmtTradeReturn>[];
    if (rawReturns is List) {
      for (final item in rawReturns) {
        if (item is Map) {
          items.add(DmtTradeReturn.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    final levelRaw = json['level'];
    return DmtUserReturnPercentagesPayload(
      userId: int.tryParse(json['user_id']?.toString() ?? '') ?? 0,
      level: levelRaw is Map
          ? DmtLevel.fromJson(Map<String, dynamic>.from(levelRaw))
          : null,
      scoreDate: json['score_date']?.toString(),
      totalRecords: int.tryParse(json['total_records']?.toString() ?? '') ?? 0,
      averageReturnPercentage:
          double.tryParse(json['average_return_percentage']?.toString() ?? '') ??
          0,
      averageReturnPercentageText:
          json['average_return_percentage_text']?.toString().trim() ?? '',
      returns: items,
    );
  }

  String get displayAverageReturn => averageReturnPercentageText.isNotEmpty
      ? averageReturnPercentageText
      : '${averageReturnPercentage.toStringAsFixed(2)}%';

  /// Returns grouped by date (avg % per day), oldest → newest.
  List<DmtDailyReturn> get returnsByDate {
    final grouped = <String, List<DmtTradeReturn>>{};
    for (final item in returns) {
      final key = item.date.isNotEmpty ? item.date : item.dateFormatted;
      if (key.isEmpty) continue;
      grouped.putIfAbsent(key, () => []).add(item);
    }

    final daily = <DmtDailyReturn>[];
    for (final entry in grouped.entries) {
      final trades = entry.value;
      if (trades.isEmpty) continue;
      final total = trades.fold<double>(
        0,
        (sum, t) => sum + t.returnPercentage,
      );
      daily.add(
        DmtDailyReturn(
          date: entry.key,
          dateFormatted: trades.first.dateFormatted,
          returnPercentage: total / trades.length,
          tradeCount: trades.length,
        ),
      );
    }

    daily.sort((a, b) => a.date.compareTo(b.date));
    return daily;
  }
}

class DmtDailyReturn {
  final String date;
  final String dateFormatted;
  final double returnPercentage;
  final int tradeCount;

  const DmtDailyReturn({
    this.date = '',
    this.dateFormatted = '',
    this.returnPercentage = 0,
    this.tradeCount = 0,
  });
}

class DmtTradeReturn {
  final int alertId;
  final int tradeId;
  final String date;
  final String dateFormatted;
  final String exchange;
  final String tradingsymbol;
  final double upperPrice;
  final double hitPrice;
  final double returnPercentage;
  final int hitAt;
  final int createdAt;

  const DmtTradeReturn({
    this.alertId = 0,
    this.tradeId = 0,
    this.date = '',
    this.dateFormatted = '',
    this.exchange = '',
    this.tradingsymbol = '',
    this.upperPrice = 0,
    this.hitPrice = 0,
    this.returnPercentage = 0,
    this.hitAt = 0,
    this.createdAt = 0,
  });

  factory DmtTradeReturn.fromJson(Map<String, dynamic> json) {
    return DmtTradeReturn(
      alertId: int.tryParse(json['alert_id']?.toString() ?? '') ?? 0,
      tradeId: int.tryParse(json['trade_id']?.toString() ?? '') ?? 0,
      date: json['date']?.toString().trim() ?? '',
      dateFormatted: json['date_formatted']?.toString().trim() ?? '',
      exchange: json['exchange']?.toString().trim() ?? '',
      tradingsymbol: json['tradingsymbol']?.toString().trim() ?? '',
      upperPrice: double.tryParse(json['upper_price']?.toString() ?? '') ?? 0,
      hitPrice: double.tryParse(json['hit_price']?.toString() ?? '') ?? 0,
      returnPercentage:
          double.tryParse(json['return_percentage']?.toString() ?? '') ?? 0,
      hitAt: int.tryParse(json['hit_at']?.toString() ?? '') ?? 0,
      createdAt: int.tryParse(json['created_at']?.toString() ?? '') ?? 0,
    );
  }
}
