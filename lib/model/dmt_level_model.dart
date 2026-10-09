import 'package:flutter/material.dart';

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

/// Single DMT level row (Believe Mode, Apply Mode, Leap Mode, etc.).
class DmtLevel {
  final int id;
  final String code;
  final String name;
  final String shortName;
  final String tagline;
  final String colorHex;
  final String disabledColorHex;
  final String icon;
  final int minimumScore;
  final int maximumScore;

  const DmtLevel({
    required this.id,
    required this.code,
    required this.name,
    required this.shortName,
    this.tagline = '',
    this.colorHex = '',
    this.disabledColorHex = '',
    this.icon = '',
    this.minimumScore = 0,
    this.maximumScore = 0,
  });

  factory DmtLevel.fromJson(Map<String, dynamic> json) {
    return DmtLevel(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      code: json['code']?.toString().trim() ?? '',
      name: json['name']?.toString().trim() ?? '',
      shortName: json['short_name']?.toString().trim() ?? '',
      tagline: json['tagline']?.toString().trim() ?? '',
      colorHex: json['color']?.toString().trim() ?? '',
      disabledColorHex: json['disabled_color']?.toString().trim() ?? '',
      icon: json['icon']?.toString().trim() ?? '',
      minimumScore: int.tryParse(json['minimum_score']?.toString() ?? '') ?? 0,
      maximumScore: int.tryParse(json['maximum_score']?.toString() ?? '') ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'name': name,
        'short_name': shortName,
        'tagline': tagline,
        'color': colorHex,
        'disabled_color': disabledColorHex,
        'icon': icon,
        'minimum_score': minimumScore,
        'maximum_score': maximumScore,
      };

  Color get parsedColor {
    if (colorHex.isEmpty) return const Color(0xFF7E57C2);
    try {
      var hex = colorHex.replaceAll('#', '').trim();
      if (hex.length == 6) hex = 'FF$hex';
      return Color(int.parse(hex, radix: 16));
    } catch (_) {
      return const Color(0xFF7E57C2);
    }
  }

  Color get parsedDisabledColor {
    if (disabledColorHex.isEmpty) return const Color(0xFF9E9E9E);
    try {
      var hex = disabledColorHex.replaceAll('#', '').trim();
      if (hex.length == 6) hex = 'FF$hex';
      return Color(int.parse(hex, radix: 16));
    } catch (_) {
      return const Color(0xFF9E9E9E);
    }
  }

  String get displayLabel =>
      name.isNotEmpty ? name : (shortName.isNotEmpty ? shortName : code);

  bool get isValid => id > 0 && displayLabel.isNotEmpty;
}
