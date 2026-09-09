class LoginResponseModel {
  String? status;
  Payload? payload;

  LoginResponseModel({this.status, this.payload});

  LoginResponseModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    payload = json['payload'] != null
        ? Payload.fromJson(json['payload'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    if (payload != null) {
      data['payload'] = payload!.toJson();
    }
    return data;
  }
}

class Payload {
  String? id;
  String? fullName;
  String? phone;
  String? email;
  String? createdAt;
  String? tradingSetupType;

  Payload({
    this.id,
    this.fullName,
    this.phone,
    this.email,
    this.createdAt,
    this.tradingSetupType,
  });

  Payload.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    fullName = json['full_name'];
    phone = json['phone'];
    email = json['email'];
    createdAt = json['created_at'];
    tradingSetupType = json['trading_setup_type'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['full_name'] = fullName;
    data['phone'] = phone;
    data['email'] = email;
    data['created_at'] = createdAt;
    data['trading_setup_type'] = tradingSetupType;
    return data;
  }
}
