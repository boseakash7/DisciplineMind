class TradingProcessResponse {
  final String status;
  final String? message;
  final TradingProcessData? payload;

  TradingProcessResponse({
    required this.status,
    this.message,
    this.payload,
  });

  factory TradingProcessResponse.fromJson(Map<String, dynamic> json) {
    return TradingProcessResponse(
      status: json['status']?.toString() ?? '',
      message: json['message']?.toString(),
      payload: json['payload'] != null && json['payload'] is Map<String, dynamic>
          ? TradingProcessData.fromJson(json['payload'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'status': status,
        if (message != null) 'message': message,
        if (payload != null) 'payload': payload?.toJson(),
      };
}

class TradingProcessData {
  final String id;
  final String userId;
  final String tradingSegment;
  final String instrument;
  final String tradingCapital;
  final String tradesPerDay;
  final String maxRiskPercent;
  final String maxRiskAmount;
  final String marketEntryTime;
  final String brokingApp;
  final String permissionOverlayEnabled;
  final String permissionUsageStatsEnabled;
  final String termsAccepted;
  final String status;
  final String createdAt;
  final String updatedAt;
  final int isMindControllActive;

  TradingProcessData({
    required this.id,
    required this.userId,
    required this.tradingSegment,
    required this.instrument,
    required this.tradingCapital,
    required this.tradesPerDay,
    required this.maxRiskPercent,
    required this.maxRiskAmount,
    required this.marketEntryTime,
    required this.brokingApp,
    required this.permissionOverlayEnabled,
    required this.permissionUsageStatsEnabled,
    required this.termsAccepted,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.isMindControllActive,
  });

  factory TradingProcessData.fromJson(Map<String, dynamic> json) {
    return TradingProcessData(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      tradingSegment: json['trading_segment']?.toString() ?? '',
      instrument: json['instrument']?.toString() ?? '',
      tradingCapital: json['trading_capital']?.toString() ?? '0',
      tradesPerDay: json['trades_per_day']?.toString() ?? '1',
      maxRiskPercent: json['max_risk_percent']?.toString() ?? '0',
      maxRiskAmount: json['max_risk_amount']?.toString() ?? '0',
      marketEntryTime: json['market_entry_time']?.toString() ?? '',
      brokingApp: json['broking_app']?.toString() ?? '',
      permissionOverlayEnabled:
          json['permission_overlay_enabled']?.toString() ?? '0',
      permissionUsageStatsEnabled:
          json['permission_usage_stats_enabled']?.toString() ?? '0',
      termsAccepted: json['terms_accepted']?.toString() ?? '0',
      status: json['status']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
      isMindControllActive: json['is_mind_controll_active'] != null
          ? int.tryParse(json['is_mind_controll_active'].toString()) ?? 0
          : 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'trading_segment': tradingSegment,
        'instrument': instrument,
        'trading_capital': tradingCapital,
        'trades_per_day': tradesPerDay,
        'max_risk_percent': maxRiskPercent,
        'max_risk_amount': maxRiskAmount,
        'market_entry_time': marketEntryTime,
        'broking_app': brokingApp,
        'permission_overlay_enabled': permissionOverlayEnabled,
        'permission_usage_stats_enabled': permissionUsageStatsEnabled,
        'terms_accepted': termsAccepted,
        'status': status,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'is_mind_controll_active': isMindControllActive,
      };

  TradingProcessData copyWith({
    String? id,
    String? userId,
    String? tradingSegment,
    String? instrument,
    String? tradingCapital,
    String? tradesPerDay,
    String? maxRiskPercent,
    String? maxRiskAmount,
    String? marketEntryTime,
    String? brokingApp,
    String? permissionOverlayEnabled,
    String? permissionUsageStatsEnabled,
    String? termsAccepted,
    String? status,
    String? createdAt,
    String? updatedAt,
    int? isMindControllActive,
  }) {
    return TradingProcessData(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      tradingSegment: tradingSegment ?? this.tradingSegment,
      instrument: instrument ?? this.instrument,
      tradingCapital: tradingCapital ?? this.tradingCapital,
      tradesPerDay: tradesPerDay ?? this.tradesPerDay,
      maxRiskPercent: maxRiskPercent ?? this.maxRiskPercent,
      maxRiskAmount: maxRiskAmount ?? this.maxRiskAmount,
      marketEntryTime: marketEntryTime ?? this.marketEntryTime,
      brokingApp: brokingApp ?? this.brokingApp,
      permissionOverlayEnabled:
          permissionOverlayEnabled ?? this.permissionOverlayEnabled,
      permissionUsageStatsEnabled:
          permissionUsageStatsEnabled ?? this.permissionUsageStatsEnabled,
      termsAccepted: termsAccepted ?? this.termsAccepted,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isMindControllActive: isMindControllActive ?? this.isMindControllActive,
    );
  }
}
