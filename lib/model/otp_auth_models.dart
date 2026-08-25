import 'login_reponse_model.dart';

class SendOtpResponse {
  final String? status;
  final SendOtpPayload? payload;

  SendOtpResponse({this.status, this.payload});

  factory SendOtpResponse.fromJson(Map<String, dynamic> json) {
    return SendOtpResponse(
      status: json['status'] as String?,
      payload: json['payload'] != null
          ? SendOtpPayload.fromJson(
              Map<String, dynamic>.from(json['payload'] as Map),
            )
          : null,
    );
  }
}

class SendOtpPayload {
  final String phone;
  final bool isOldUser;
  final String? message;

  SendOtpPayload({
    required this.phone,
    required this.isOldUser,
    this.message,
  });

  factory SendOtpPayload.fromJson(Map<String, dynamic> json) {
    return SendOtpPayload(
      phone: json['phone']?.toString() ?? '',
      isOldUser: _isOldUserFlag(json['is_old_user']),
      message: json['message'] as String?,
    );
  }
}

class VerifyOtpResponse {
  final String? status;
  final VerifyOtpPayload? payload;

  VerifyOtpResponse({this.status, this.payload});

  factory VerifyOtpResponse.fromJson(Map<String, dynamic> json) {
    return VerifyOtpResponse(
      status: json['status'] as String?,
      payload: json['payload'] != null
          ? VerifyOtpPayload.fromJson(
              Map<String, dynamic>.from(json['payload'] as Map),
            )
          : null,
    );
  }
}

class VerifyOtpPayload {
  final bool isOldUser;
  final Payload? user;

  VerifyOtpPayload({required this.isOldUser, this.user});

  factory VerifyOtpPayload.fromJson(Map<String, dynamic> json) {
    final userRaw = json['user'];
    return VerifyOtpPayload(
      isOldUser: _isOldUserFlag(json['is_old_user']),
      user: userRaw is Map<String, dynamic>
          ? Payload.fromJson(userRaw)
          : userRaw is Map
              ? Payload.fromJson(Map<String, dynamic>.from(userRaw))
              : null,
    );
  }

  /// Maps verify-otp user to the same shape used app-wide after login.
  LoginResponseModel toLoginResponseModel() {
    return LoginResponseModel(status: 'ok', payload: user);
  }
}

bool _isOldUserFlag(dynamic value) {
  if (value == null) return false;
  if (value is bool) return value;
  if (value is int) return value == 1;
  if (value is String) return value == '1' || value.toLowerCase() == 'true';
  return false;
}
