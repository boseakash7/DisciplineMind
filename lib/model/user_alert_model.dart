class UserAlertModel {
  String? status;
  List<UserAlerts>? payload;

  UserAlertModel({this.status, this.payload});

  UserAlertModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    if (json['payload'] != null) {
      payload = <UserAlerts>[];
      json['payload'].forEach((v) {
        payload!.add(UserAlerts.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    if (payload != null) {
      data['payload'] = payload!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class UserAlerts {
  String? id;
  String? tradeId;
  String? userId;
  String? exchange;
  String? tradingsymbol;
  String? currentPrice;
  String? upperPrice;
  String? lowerPrice;
  String? gttPrice;
  String? status;
  String? createdAt;

  UserAlerts({
    this.id,
    this.tradeId,
    this.userId,
    this.exchange,
    this.tradingsymbol,
    this.currentPrice,
    this.upperPrice,
    this.lowerPrice,
    this.gttPrice,
    this.status,
    this.createdAt,
  });

  UserAlerts.fromJson(Map<String, dynamic> json) {
    id = json['id']?.toString();
    tradeId = json['trade_id']?.toString();
    userId = json['user_id']?.toString();
    exchange = json['exchange']?.toString();
    tradingsymbol = json['tradingsymbol']?.toString();
    currentPrice = json['current_price']?.toString();
    upperPrice = json['upper_price']?.toString();
    lowerPrice = json['lower_price']?.toString();
    gttPrice = json['gtt_price']?.toString();
    status = json['status']?.toString();
    createdAt = json['created_at']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['trade_id'] = tradeId;
    data['user_id'] = userId;
    data['exchange'] = exchange;
    data['tradingsymbol'] = tradingsymbol;
    data['current_price'] = currentPrice;
    data['upper_price'] = upperPrice;
    data['lower_price'] = lowerPrice;
    data['gtt_price'] = gttPrice;
    data['status'] = status;
    data['created_at'] = createdAt;
    return data;
  }
}
