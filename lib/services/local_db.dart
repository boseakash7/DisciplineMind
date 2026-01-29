import 'package:get_storage/get_storage.dart';

class LocalStorageService {
  final GetStorage _box = GetStorage();

  /// KEYS
  static const String emailKey = "email";
  static const String passwordKey = "password";

  /// SAVE LOGIN DATA
  void saveLogin(String email, String password) {
    _box.write(emailKey, email);
    _box.write(passwordKey, password);
  }

  /// GET SAVED EMAIL
  String? getEmail() {
    return _box.read(emailKey);
  }

  /// GET SAVED PASSWORD
  String? getPassword() {
    return _box.read(passwordKey);
  }

  /// CHECK IF LOGIN EXISTS
  bool hasLoginData() {
    return getEmail() != null && getPassword() != null;
  }

  /// CLEAR STORAGE (LOGOUT)
  void clearLogin() {
    _box.remove(emailKey);
    _box.remove(passwordKey);
  }
}
