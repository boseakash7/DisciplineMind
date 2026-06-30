import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class ThemeService {
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  ThemeService._internal();

  final GetStorage _box = GetStorage();
  final String _themeKey = 'theme_mode';

  final RxBool _isDarkMode = RxBool(true);

  bool get isDarkMode => _isDarkMode.value;

  ThemeMode get themeMode {
    final saved = _box.read(_themeKey);
    if (saved == 'light') {
      _isDarkMode.value = false;
      return ThemeMode.light;
    } else {
      _isDarkMode.value = true;
      return ThemeMode.dark;
    }
  }

  void switchTheme() {
    final newIsDark = !_isDarkMode.value;
    _isDarkMode.value = newIsDark;

    _box.write(_themeKey, newIsDark ? 'dark' : 'light');
    Get.changeThemeMode(newIsDark ? ThemeMode.dark : ThemeMode.light);

    _updateStatusBar(newIsDark);
  }

  void loadSavedTheme() {
    final saved = _box.read(_themeKey);
    final isDark = saved != 'light';
    _isDarkMode.value = isDark;
    _updateStatusBar(isDark);
  }

  void _updateStatusBar(bool isDark) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        // icon/text color of status bar
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        // for iOS
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: isDark ? Colors.black : Colors.white,
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
      ),
    );
  }
}