import 'package:discipline_mind/model/dmt_level_model.dart';

/// Response from `POST /api/dmt-score/history`.
class DmtScoreHistoryResponse {
  final String? status;
  final DmtScoreHistoryPayload? payload;

  const DmtScoreHistoryResponse({this.status, this.payload});

  factory DmtScoreHistoryResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['payload'];
    return DmtScoreHistoryResponse(
      status: json['status']?.toString(),
      payload: raw is Map
          ? DmtScoreHistoryPayload.fromJson(Map<String, dynamic>.from(raw))
          : null,
    );
  }

  bool get isOk => (status ?? '').toLowerCase() == 'ok';
}

class DmtScoreHistoryPayload {
  final int userId;
  final DmtLevel? requestedLevel;
  final DmtLevel? currentLevel;
  final int currentTotalScore;
  final DmtScoreNextLevel? nextLevel;
  final List<DmtScoreHistoryEntry> history;

  const DmtScoreHistoryPayload({
    this.userId = 0,
    this.requestedLevel,
    this.currentLevel,
    this.currentTotalScore = 0,
    this.nextLevel,
    this.history = const [],
  });

  factory DmtScoreHistoryPayload.fromJson(Map<String, dynamic> json) {
    final rawHistory = json['history'];
    final entries = <DmtScoreHistoryEntry>[];
    if (rawHistory is List) {
      for (final item in rawHistory) {
        if (item is Map) {
          entries.add(
            DmtScoreHistoryEntry.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    final requestedRaw = json['requested_level'];
    final currentRaw = json['current_level'];
    final nextRaw = json['next_level'];

    return DmtScoreHistoryPayload(
      userId: int.tryParse(json['user_id']?.toString() ?? '') ?? 0,
      requestedLevel: requestedRaw is Map
          ? DmtLevel.fromJson(Map<String, dynamic>.from(requestedRaw))
          : null,
      currentLevel: currentRaw is Map
          ? DmtLevel.fromJson(Map<String, dynamic>.from(currentRaw))
          : null,
      currentTotalScore:
          int.tryParse(json['current_total_score']?.toString() ?? '') ?? 0,
      nextLevel: nextRaw is Map
          ? DmtScoreNextLevel.fromJson(Map<String, dynamic>.from(nextRaw))
          : null,
      history: entries,
    );
  }

  /// Level being viewed in the Analysis filter.
  DmtLevel? get displayLevel => requestedLevel ?? currentLevel;

  bool get isViewingCurrentLevel {
    final requestedId = requestedLevel?.id ?? currentLevel?.id ?? 0;
    final currentId = currentLevel?.id ?? 0;
    return requestedId > 0 && requestedId == currentId;
  }

  /// Score shown in summary — global total for current level, else last cumulative.
  int get displayScore {
    if (isViewingCurrentLevel) return currentTotalScore;
    final sorted = sortedHistory;
    if (sorted.isNotEmpty) return sorted.last.cumulativeScore;
    return currentTotalScore;
  }

  /// History sorted oldest → newest for charting.
  List<DmtScoreHistoryEntry> get sortedHistory {
    final copy = List<DmtScoreHistoryEntry>.from(history);
    copy.sort((a, b) => a.scoreDate.compareTo(b.scoreDate));
    return copy;
  }
}

class DmtScoreNextLevel extends DmtLevel {
  final int targetScore;
  final int remainingScore;

  const DmtScoreNextLevel({
    required super.id,
    required super.code,
    required super.name,
    required super.shortName,
    this.targetScore = 0,
    this.remainingScore = 0,
  });

  factory DmtScoreNextLevel.fromJson(Map<String, dynamic> json) {
    return DmtScoreNextLevel(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      code: json['code']?.toString().trim() ?? '',
      name: json['name']?.toString().trim() ?? '',
      shortName: json['short_name']?.toString().trim() ?? '',
      targetScore: int.tryParse(json['target_score']?.toString() ?? '') ?? 0,
      remainingScore:
          int.tryParse(json['remaining_score']?.toString() ?? '') ?? 0,
    );
  }

  double get progressFraction {
    if (targetScore <= 0) return 0;
    final earned = targetScore - remainingScore;
    return (earned / targetScore).clamp(0.0, 1.0);
  }
}

class DmtScoreHistoryEntry {
  final int id;
  final String scoreDate;
  final String scoreDateFormatted;
  final int dailyScore;
  final int cumulativeScore;
  final int maxScore;
  final DmtLevel? level;

  const DmtScoreHistoryEntry({
    this.id = 0,
    this.scoreDate = '',
    this.scoreDateFormatted = '',
    this.dailyScore = 0,
    this.cumulativeScore = 0,
    this.maxScore = 60,
    this.level,
  });

  factory DmtScoreHistoryEntry.fromJson(Map<String, dynamic> json) {
    final levelRaw = json['level'];
    return DmtScoreHistoryEntry(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      scoreDate: json['score_date']?.toString().trim() ?? '',
      scoreDateFormatted: json['score_date_formatted']?.toString().trim() ?? '',
      dailyScore: int.tryParse(json['daily_score']?.toString() ?? '') ?? 0,
      cumulativeScore:
          int.tryParse(json['cumulative_score']?.toString() ?? '') ?? 0,
      maxScore: int.tryParse(json['max_score']?.toString() ?? '') ?? 60,
      level: levelRaw is Map
          ? DmtLevel.fromJson(Map<String, dynamic>.from(levelRaw))
          : null,
    );
  }

  String get chartLabel {
    if (scoreDateFormatted.isNotEmpty) {
      final parts = scoreDateFormatted.split('-');
      if (parts.length >= 2) return '${parts[0]}\n${parts[1]}';
      return scoreDateFormatted;
    }
    try {
      final d = DateTime.parse(scoreDate);
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
      return '${d.day}\n${months[d.month - 1]}';
    } catch (_) {
      return scoreDate;
    }
  }
}
