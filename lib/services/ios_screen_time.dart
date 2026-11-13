import 'package:flutter/services.dart';

class IosScreenTime {
  static const _channel = MethodChannel('screen_time');
  static Future<bool> requestPermission() async {
    try {
      return await _channel.invokeMethod<bool>('requestPermission') ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> isAuthorized() async {
    try {
      return await _channel.invokeMethod<bool>('isAuthorized') ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> showAppPicker() async {
    try {
      return await _channel.invokeMethod<bool>('showAppPicker') ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> hasSelectedApps() async {
    try {
      return await _channel.invokeMethod<bool>('hasSelectedApps') ?? false;
    } catch (_) {
      return false;
    }
  }
  static Future<bool> blockSelectedApps() async {
    try {
      return await _channel.invokeMethod<bool>('enableRestrictions') ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> enableRestrictions() async {
    try {
      return await _channel.invokeMethod<bool>('enableRestrictions') ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> unblockAll() async {
    try {
      return await _channel.invokeMethod<bool>('unblockAll') ?? true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> blockApp([String? bundleId]) async {
    try {
      return await _channel.invokeMethod<bool>('blockApp') ?? false;
    } catch (_) {
      return false;
    }
  }
}
