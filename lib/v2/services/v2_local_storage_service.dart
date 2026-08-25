import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import '../models/v2_user_model.dart';

class V2LocalStorageService {
  static const String _userSessionKey = 'v2_user_session';
  static const String _userIdKey = 'v2_user_id';
  final GetStorage _storage = GetStorage();

  void saveUserSession(V2LoginResponseModel model) {
    final raw = jsonEncode(model.toJson());
    _storage.write(_userSessionKey, raw);
    if (model.payload?.id != null) {
      _storage.write(_userIdKey, model.payload!.id.toString());
    }
  }

  V2LoginResponseModel? getUserSession() {
    final raw = _storage.read<String>(_userSessionKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return V2LoginResponseModel.fromJson(decoded);
      }
      if (decoded is Map) {
        return V2LoginResponseModel.fromJson(
          Map<String, dynamic>.from(decoded),
        );
      }
    } catch (_) {}
    return null;
  }

  String? getUserId() {
    return _storage.read<String>(_userIdKey);
  }

  void clearLogin() {
    _storage.remove(_userSessionKey);
    _storage.remove(_userIdKey);
  }
}
