import '../../model/login_reponse_model.dart';

class V2LoginResponseModel {
  String? status;
  V2UserPayload? payload;

  V2LoginResponseModel({this.status, this.payload});

  V2LoginResponseModel.fromJson(Map<String, dynamic> json) {
    status = json['status']?.toString();
    payload = json['payload'] != null
        ? V2UserPayload.fromJson(Map<String, dynamic>.from(json['payload'] as Map))
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

  LoginResponseModel toLoginResponseModel() {
    return LoginResponseModel(
      status: status,
      payload: payload != null
          ? Payload(
              id: payload?.id,
              fullName: payload?.fullName,
              phone: payload?.phone,
              email: payload?.email,
              createdAt: payload?.createdAt,
            )
          : null,
    );
  }
}

class V2UserPayload {
  String? id;
  String? fullName;
  String? phone;
  String? email;
  String? dmtLevelId;
  String? dmtLevelCode;
  String? createdAt;

  V2UserPayload({
    this.id,
    this.fullName,
    this.phone,
    this.email,
    this.dmtLevelId,
    this.dmtLevelCode,
    this.createdAt,
  });

  V2UserPayload.fromJson(Map<String, dynamic> json) {
    id = json['id']?.toString();
    fullName = json['full_name']?.toString() ?? json['fullname']?.toString();
    phone = json['phone']?.toString();
    email = json['email']?.toString();
    dmtLevelId = json['dmt_level_id']?.toString();
    dmtLevelCode = json['dmt_level_code']?.toString();
    createdAt = json['created_at']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['full_name'] = fullName;
    data['phone'] = phone;
    data['email'] = email;
    data['dmt_level_id'] = dmtLevelId;
    data['dmt_level_code'] = dmtLevelCode;
    data['created_at'] = createdAt;
    return data;
  }
}
