import 'v2_user_model.dart';

class V2SendOtpResponse {
  final String? status;
  final V2SendOtpPayload? payload;

  V2SendOtpResponse({this.status, this.payload});

  factory V2SendOtpResponse.fromJson(Map<String, dynamic> json) {
    return V2SendOtpResponse(
      status: json['status'] as String?,
      payload: json['payload'] != null
          ? V2SendOtpPayload.fromJson(
              Map<String, dynamic>.from(json['payload'] as Map),
            )
          : null,
    );
  }
}

class V2SendOtpPayload {
  final String phone;
  final bool isOldUser;
  final String? message;

  V2SendOtpPayload({
    required this.phone,
    required this.isOldUser,
    this.message,
  });

  factory V2SendOtpPayload.fromJson(Map<String, dynamic> json) {
    return V2SendOtpPayload(
      phone: json['phone']?.toString() ?? '',
      isOldUser: _isOldUserFlag(json['is_old_user']),
      message: json['message'] as String?,
    );
  }
}

class V2VerifyOtpResponse {
  final String? status;
  final V2VerifyOtpPayload? payload;

  V2VerifyOtpResponse({this.status, this.payload});

  factory V2VerifyOtpResponse.fromJson(Map<String, dynamic> json) {
    return V2VerifyOtpResponse(
      status: json['status'] as String?,
      payload: json['payload'] != null
          ? V2VerifyOtpPayload.fromJson(
              Map<String, dynamic>.from(json['payload'] as Map),
            )
          : null,
    );
  }
}

class V2VerifyOtpPayload {
  final bool isOldUser;
  final V2UserPayload? user;

  V2VerifyOtpPayload({required this.isOldUser, this.user});

  factory V2VerifyOtpPayload.fromJson(Map<String, dynamic> json) {
    final userRaw = json['user'];
    return V2VerifyOtpPayload(
      isOldUser: _isOldUserFlag(json['is_old_user']),
      user: userRaw is Map<String, dynamic>
          ? V2UserPayload.fromJson(userRaw)
          : userRaw is Map
              ? V2UserPayload.fromJson(Map<String, dynamic>.from(userRaw))
              : null,
    );
  }

  V2LoginResponseModel toLoginResponseModel() {
    return V2LoginResponseModel(status: 'ok', payload: user);
  }
}

bool _isOldUserFlag(dynamic value) {
  if (value == null) return false;
  if (value is bool) return value;
  if (value is int) return value == 1;
  if (value is String) return value == '1' || value.toLowerCase() == 'true';
  return false;
}
