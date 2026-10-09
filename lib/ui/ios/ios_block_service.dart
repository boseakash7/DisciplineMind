import 'dart:io';
import 'package:app_limiter/app_limiter.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IOSBlockService {
  static const _activeKey = 'ios_trading_app_blocked';
  final AppLimiter _limiter = AppLimiter();

  /// Request Apple Screen Time / FamilyControls permission
  Future<bool> requestPermission() async {
    if (!Platform.isIOS) return false;
    try {
      final granted = await _limiter.requestIosPermission();
      if (granted) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('ios_screen_time_granted', true);
      }
      return granted;
    } catch (e) {
      debugPrint('[IOSBlockService] requestPermission error: $e');
      return false;
    }
  }

  /// Toggle app blocking / shield via Apple FamilyControls
  Future<bool> toggleBlock() async {
    if (!Platform.isIOS) return false;
    try {
      await _limiter.blockAndUnblockIOSApp();
      final prefs = await SharedPreferences.getInstance();
      final current = prefs.getBool(_activeKey) ?? false;
      await prefs.setBool(_activeKey, !current);
      return true;
    } catch (e) {
      debugPrint('[IOSBlockService] toggleBlock error: $e');
      return false;
    }
  }

  /// Activate app blocking on iOS
  Future<bool> activateBlock() async {
    if (!Platform.isIOS) return false;
    try {
      await _limiter.blockAndUnblockIOSApp();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_activeKey, true);
      return true;
    } catch (e) {
      debugPrint('[IOSBlockService] activateBlock error: $e');
      return false;
    }
  }

  Future<bool> isBlocked() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_activeKey) ?? false;
  }
}
