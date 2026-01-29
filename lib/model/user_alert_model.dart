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
  String? userId;
  String? exchange;
  String? tradingsymbol;
  String? currentPrice;
  String? price;
  String? status;
  String? createdAt;

  UserAlerts({
    this.id,
    this.userId,
    this.exchange,
    this.tradingsymbol,
    this.currentPrice,
    this.price,
    this.status,
    this.createdAt,
  });

  UserAlerts.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    userId = json['user_id'];
    exchange = json['exchange'];
    tradingsymbol = json['tradingsymbol'];
    currentPrice = json['current_price'];
    price = json['price'];
    status = json['status'];
    createdAt = json['created_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['user_id'] = userId;
    data['exchange'] = exchange;
    data['tradingsymbol'] = tradingsymbol;
    data['current_price'] = currentPrice;
    data['price'] = price;
    data['status'] = status;
    data['created_at'] = createdAt;
    return data;
  }
}
