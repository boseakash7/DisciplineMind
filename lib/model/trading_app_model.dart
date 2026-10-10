/// Trading app row from `GET /api/trading-apps`.
class TradingApp {
  TradingApp({
    required this.id,
    required this.name,
    required this.packageName,
    required this.isTarget,
    required this.isStoploss,
    required this.isGtt,
    this.createdAt,
  });

  final String id;
  final String name;
  final String packageName;
  final bool isTarget;
  final bool isStoploss;
  final bool isGtt;
  final String? createdAt;

  factory TradingApp.fromJson(Map<String, dynamic> json) {
    return TradingApp(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      packageName: json['package_name']?.toString() ?? '',
      isTarget: _parseFlag(json['is_target']),
      isStoploss: _parseFlag(json['is_stoploss']),
      isGtt: _parseFlag(json['is_gtt']),
      createdAt: json['created_at']?.toString(),
    );
  }

  static bool _parseFlag(dynamic v) {
    if (v == true) return true;
    if (v == false) return false;
    final s = v?.toString().toLowerCase().trim();
    return s == '1' || s == 'true';
  }

  /// Grow-like flow: GTT dialog collects SL + target (from API flags).
  bool get requiresExtendedGttForm => isGtt && isTarget && isStoploss;
}
