/// Response from `GET /api/dmt-levels`.
class DmtLevelsResponse {
  final String? status;
  final List<DmtLevel> payload;

  const DmtLevelsResponse({
    this.status,
    this.payload = const [],
  });

  factory DmtLevelsResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['payload'];
    final levels = <DmtLevel>[];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map) {
          levels.add(DmtLevel.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }
    return DmtLevelsResponse(
      status: json['status']?.toString(),
      payload: levels,
    );
  }

  bool get isOk => (status ?? '').toLowerCase() == 'ok';
}

/// Single DMT level row (Believe Mode, Achieve Purple, etc.).
class DmtLevel {
  final int id;
  final String code;
  final String name;
  final String shortName;

  const DmtLevel({
    required this.id,
    required this.code,
    required this.name,
    required this.shortName,
  });

  factory DmtLevel.fromJson(Map<String, dynamic> json) {
    return DmtLevel(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      code: json['code']?.toString().trim() ?? '',
      name: json['name']?.toString().trim() ?? '',
      shortName: json['short_name']?.toString().trim() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'name': name,
        'short_name': shortName,
      };
  String get displayLabel =>
      name.isNotEmpty ? name : (shortName.isNotEmpty ? shortName : code);

  bool get isValid => id > 0 && displayLabel.isNotEmpty;
}
