/// Helpers for DMT score UI (popup + chat).
class DmtScoreCard {
  DmtScoreCard._();

  /// Max points per core discipline row (Process / Commitment / Acceptance).
  /// Derived as [dmtMaxScore] / 3 when available; this is the default.
  static const double kDmtCategoryMaxScore = 20;

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
    return formatNumber(v);
  }

  /// Whole number when possible; keeps minus for negatives.
  static String formatNumber(double v) {
    if (v == v.roundToDouble()) return v.round().toString();
    return v.toStringAsFixed(1);
  }

  /// Bonus / delta label: `+7`, `+0`, or `-10`.
  static String formatSignedBonus(double v) {
    if (v > 0) return '+${formatNumber(v)}';
    if (v == 0) return '+0';
    return formatNumber(v);
  }

  static double parseScore(String raw) => double.tryParse(raw) ?? 0;

  /// Bar fill 0–1. Negatives use absolute value for red fill width.
  static double progressFraction(
    double score, [
    double max = kDmtCategoryMaxScore,
  ]) {
    if (max <= 0) return 0;
    return (score.abs() / max).clamp(0.0, 1.0);
  }

  static bool isNegative(double score) => score < 0;

  /// Per-category max from overall max (typically 60 → 20).
  static double categoryMax(double overallMax) {
    if (overallMax <= 0) return kDmtCategoryMaxScore;
    return overallMax / 3;
  }
}
