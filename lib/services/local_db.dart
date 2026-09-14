import 'dart:convert';

import 'package:get_storage/get_storage.dart';

import '../model/login_reponse_model.dart';

class LocalStorageService {
  final GetStorage _box = GetStorage();

  static const String emailKey = "email";
  static const String passwordKey = "password";
  static const String userSessionKey = "user_session_json";

  /// Persisted after OTP verify (or legacy email login).
  void saveUserSession(LoginResponseModel model) {
    _box.write(userSessionKey, jsonEncode(model.toJson()));
  }

  LoginResponseModel? getUserSession() {
    final raw = _box.read(userSessionKey);
    if (raw is! String || raw.isEmpty) return null;
    try {
      return LoginResponseModel.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  bool hasLoginData() {
    final s = getUserSession();
    return s?.payload?.id != null;
  }

  /// CLEAR STORAGE (LOGOUT)
  void clearLogin() {
    _box.remove(emailKey);
    _box.remove(passwordKey);
    _box.remove(userSessionKey);
  }
}
