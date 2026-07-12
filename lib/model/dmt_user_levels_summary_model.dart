import 'package:discipline_mind/model/dmt_level_model.dart';
import 'package:discipline_mind/model/dmt_score_history_model.dart'
    show DmtScoreNextLevel, parseDmtScoreFromKeys;

/// Response from `POST /api/dmt-level/user-levels-summary`.
class DmtUserLevelsSummaryResponse {
  final String? status;
  final DmtUserLevelsSummaryPayload? payload;

  const DmtUserLevelsSummaryResponse({this.status, this.payload});

  factory DmtUserLevelsSummaryResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['payload'];
    return DmtUserLevelsSummaryResponse(
      status: json['status']?.toString(),
      payload: raw is Map
          ? DmtUserLevelsSummaryPayload.fromJson(
              Map<String, dynamic>.from(raw),
            )
          : null,
    );
  }

  bool get isOk => (status ?? '').toLowerCase() == 'ok';
}

class DmtUserLevelsSummaryPayload {
  final int userId;
  final double currentScore;
  final DmtLevel? currentLevel;
  final DmtScoreNextLevel? nextLevel;
  final List<DmtUserLevelSummaryItem> levels;

  const DmtUserLevelsSummaryPayload({
    this.userId = 0,
    this.currentScore = 0,
    this.currentLevel,
    this.nextLevel,
    this.levels = const [],
  });

  factory DmtUserLevelsSummaryPayload.fromJson(Map<String, dynamic> json) {
    final rawLevels = json['levels'];
    final items = <DmtUserLevelSummaryItem>[];
    if (rawLevels is List) {
      for (final item in rawLevels) {
        if (item is Map) {
          items.add(
            DmtUserLevelSummaryItem.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    final currentRaw = json['current_level'];
    final nextRaw = json['next_level'];

    return DmtUserLevelsSummaryPayload(
      userId: int.tryParse(json['user_id']?.toString() ?? '') ?? 0,
      currentScore: parseDmtScoreFromKeys(json, const [
        'current_score',
        'current_total_score',
        'level_total_score',
      ]),
      currentLevel: currentRaw is Map
          ? DmtLevel.fromJson(Map<String, dynamic>.from(currentRaw))
          : null,
      nextLevel: nextRaw is Map
          ? DmtScoreNextLevel.fromJson(Map<String, dynamic>.from(nextRaw))
          : null,
      levels: items,
    );
  }

  DmtUserLevelSummaryItem? levelByCode(String code) {
    final upper = code.toUpperCase();
    for (final level in levels) {
      if (level.code.toUpperCase() == upper) return level;
    }
    return null;
  }

  DmtUserLevelSummaryItem? levelById(int id) {
    for (final level in levels) {
      if (level.id == id) return level;
    }
    return null;
  }
}

class DmtUserLevelSummaryItem {
  final int id;
  final String code;
  final String name;
  final String shortName;
  final int minimumScore;
  final bool isCurrent;
  final bool isUnlocked;
  final int totalTrades;
  final int totalWins;
  final double tradeAccuracy;
  final String tradeAccuracyText;
  final double? totalAverageReturnPercentage;
  final double? totalMctAverageReturnPercentage;
  final double levelTotalScore;
  final DmtScoreNextLevel? nextLevel;
  final List<DmtLevelScoreHistoryEntry> scoreHistory;

  const DmtUserLevelSummaryItem({
    this.id = 0,
    this.code = '',
    this.name = '',
    this.shortName = '',
    this.minimumScore = 0,
    this.isCurrent = false,
    this.isUnlocked = false,
    this.totalTrades = 0,
    this.totalWins = 0,
    this.tradeAccuracy = 0,
    this.tradeAccuracyText = '',
    this.totalAverageReturnPercentage,
    this.totalMctAverageReturnPercentage,
    this.levelTotalScore = 0,
    this.nextLevel,
    this.scoreHistory = const [],
  });

  factory DmtUserLevelSummaryItem.fromJson(Map<String, dynamic> json) {
    final rawHistory = json['score_history'];
    final history = <DmtLevelScoreHistoryEntry>[];
    if (rawHistory is List) {
      for (final item in rawHistory) {
        if (item is Map) {
          history.add(
            DmtLevelScoreHistoryEntry.fromJson(
              Map<String, dynamic>.from(item),
            ),
          );
        }
      }
    }

    final nextRaw = json['next_level'];

    return DmtUserLevelSummaryItem(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      code: json['code']?.toString().trim() ?? '',
      name: json['name']?.toString().trim() ?? '',
      shortName: json['short_name']?.toString().trim() ?? '',
      minimumScore:
          int.tryParse(json['minimum_score']?.toString() ?? '') ?? 0,
      isCurrent: json['is_current'] == true ||
          json['is_current']?.toString() == '1' ||
          json['is_current']?.toString().toLowerCase() == 'true',
      isUnlocked: json['is_unlocked'] == true ||
          json['is_unlocked']?.toString() == '1' ||
          json['is_unlocked']?.toString().toLowerCase() == 'true',
      totalTrades: int.tryParse(json['total_trades']?.toString() ?? '') ?? 0,
      totalWins: int.tryParse(json['total_wins']?.toString() ?? '') ?? 0,
      tradeAccuracy:
          double.tryParse(json['trade_accuracy']?.toString() ?? '') ?? 0,
      tradeAccuracyText: json['trade_accuracy_text']?.toString().trim() ?? '',
      totalAverageReturnPercentage: _parseDouble(
        json['total_average_return_percentage'],
      ),
      totalMctAverageReturnPercentage: _parseDouble(
        json['total_mct_average_return_percentage'],
      ),
      levelTotalScore: parseDmtScoreFromKeys(json, const [
        'level_total_score',
        'current_score',
      ]),
      nextLevel: nextRaw is Map
          ? DmtScoreNextLevel.fromJson(Map<String, dynamic>.from(nextRaw))
          : null,
      scoreHistory: history,
    );
  }

  String get displayLabel =>
      name.isNotEmpty ? name : (shortName.isNotEmpty ? shortName : code);

  String get displayTotalAverageReturn =>
      _formatReturnPercent(totalAverageReturnPercentage);

  String get displayTotalMctAverageReturn =>
      _formatReturnPercent(totalMctAverageReturnPercentage);

  bool get canExpand => isUnlocked || isCurrent;

  List<DmtLevelScoreHistoryEntry> get sortedScoreHistory {
    final copy = List<DmtLevelScoreHistoryEntry>.from(scoreHistory);
    copy.sort((a, b) => a.scoreDate.compareTo(b.scoreDate));
    return copy;
  }
}

class DmtLevelScoreHistoryEntry {
  final int id;
  final String scoreDate;
  final String scoreDateFormatted;
  final double dailyScore;
  final double levelCumulativeScore;
  final int maxScore;

  const DmtLevelScoreHistoryEntry({
    this.id = 0,
    this.scoreDate = '',
    this.scoreDateFormatted = '',
    this.dailyScore = 0,
    this.levelCumulativeScore = 0,
    this.maxScore = 60,
  });

  factory DmtLevelScoreHistoryEntry.fromJson(Map<String, dynamic> json) {
    return DmtLevelScoreHistoryEntry(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      scoreDate: json['score_date']?.toString().trim() ?? '',
      scoreDateFormatted: json['score_date_formatted']?.toString().trim() ?? '',
      dailyScore: parseDmtScoreFromKeys(json, const ['daily_score']),
      levelCumulativeScore: parseDmtScoreFromKeys(json, const [
        'level_cumulative_score',
        'cumulative_score',
      ]),
      maxScore: int.tryParse(json['max_score']?.toString() ?? '') ?? 60,
    );
  }

  String get chartDateLabel {
    if (scoreDateFormatted.isNotEmpty) {
      final parts = scoreDateFormatted.split('-');
      if (parts.length >= 2) {
        return '${parts[0]}-${parts[1].toUpperCase()}';
      }
      return scoreDateFormatted.toUpperCase();
    }
    try {
      final d = DateTime.parse(scoreDate);
      const months = [
        'JAN',
        'FEB',
        'MAR',
        'APR',
        'MAY',
        'JUN',
        'JUL',
        'AUG',
        'SEP',
        'OCT',
        'NOV',
        'DEC',
      ];
      final day = d.day.toString().padLeft(2, '0');
      return '$day-${months[d.month - 1]}';
    } catch (_) {
      return scoreDate;
    }
  }
}

String _formatReturnPercent(double? value) {
  if (value == null) return '—';
  return '${value.toStringAsFixed(2)}%';
}

double? _parseDouble(dynamic v) {
  if (v == null) return null;
  return double.tryParse(v.toString());
}
