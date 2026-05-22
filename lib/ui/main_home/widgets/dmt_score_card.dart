/// Helpers for DMT score UI (popup + chat).
class DmtScoreCard {
  DmtScoreCard._();

  /// Max points per discipline row.
  static const double kDmtCategoryMaxScore = 15;

  static String formatScoreDate(String raw) {
    try {
      final d = DateTime.parse(raw);
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
      return '$day-${months[d.month - 1]}-${d.year}';
    } catch (_) {
      return raw;
    }
  }

  static String formatScore(String raw) {
    final v = double.tryParse(raw);
    if (v == null) return raw;
    if (v == v.roundToDouble()) return v.round().toString();
    return v.toStringAsFixed(1);
  }

  static double parseScore(String raw) => double.tryParse(raw) ?? 0;

  static double progressFraction(
    double score, [
    double max = kDmtCategoryMaxScore,
  ]) {
    if (max <= 0) return 0;
    return (score / max).clamp(0.0, 1.0);
  }
}
