class LoginResponseModel {
  String? status;
  Payload? payload;

  LoginResponseModel({this.status, this.payload});

  LoginResponseModel.fromJson(Map<String, dynamic> json) {
    status = json['status']?.toString();
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
  int? dmtLevelId;
  String? dmtLevelCode;
  bool? isMindControllActive;

  Payload({
    this.id,
    this.fullName,
    this.phone,
    this.email,
    this.createdAt,
    this.tradingSetupType,
    this.dmtLevelId,
    this.dmtLevelCode,
    this.isMindControllActive,
  });

  Payload.fromJson(Map<String, dynamic> json) {
    id = json['id']?.toString();
    fullName = json['full_name']?.toString();
    phone = json['phone']?.toString();
    email = json['email']?.toString();
    createdAt = json['created_at']?.toString();
    tradingSetupType = json['trading_setup_type']?.toString();
    dmtLevelId = int.tryParse(json['dmt_level_id']?.toString() ?? '');
    dmtLevelCode = json['dmt_level_code']?.toString();
    isMindControllActive = _asBool(json['is_mind_controll_active']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['full_name'] = fullName;
    data['phone'] = phone;
    data['email'] = email;
    data['created_at'] = createdAt;
    data['trading_setup_type'] = tradingSetupType;
    data['dmt_level_id'] = dmtLevelId;
    data['dmt_level_code'] = dmtLevelCode;
    if (isMindControllActive != null) {
      data['is_mind_controll_active'] = isMindControllActive! ? 1 : 0;
    }
    return data;
  }
}

bool _asBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final normalized = value?.toString().trim().toLowerCase();
  return normalized == '1' || normalized == 'true';
}
