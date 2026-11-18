import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'api/api_services.dart';

class IosScreenTime {
  /// Local button interactions; not broker launch counts or usage duration.
  static Future<Map<String, dynamic>> getGuardUsageStats() async {
    final result = await _channel.invokeMapMethod<String, dynamic>('getGuardUsageStats');
    return result ?? <String, dynamic>{};
  }

  static Future<bool>? _guardReturnForResume;

  static void beginResume() => _guardReturnForResume = null;

  static Future<bool> isGuardReturnForResume() =>
      _guardReturnForResume ??= consumeGuardChatRequest();

  static Future<void> syncGuardState(String userId) async {
    try {
      final response = await ApiService().postFormData('app/state', {'user_id': userId});
      final data = response.data;
      if (!response.isSuccess || data is! Map || data['payload'] is! Map) return;
      final payload = data['payload'] as Map;
      await _channel.invokeMethod<void>('syncGuardState', {
        'userId': userId,
        'state': payload['state']?.toString() ?? '',
        'tradeId': payload['trade_id']?.toString() ?? '',
      });
    } catch (error) {
      debugPrint('[MindControlGuard] State sync failed: $error');
    }
  }
  static const _channel = MethodChannel('screen_time');
  static Future<bool> consumeGuardChatRequest() async {
    try {
      return await _channel.invokeMethod<bool>('consumeGuardChatRequest') ?? false;
    } catch (error) {
      debugPrint('[MindControlGuard] Screen Time call failed: $error');
      return false;
    }
  }

  static Future<bool> requestPermission() async {
    try {
      return await _channel.invokeMethod<bool>('requestPermission') ?? false;
    } catch (error) {
      debugPrint('[MindControlGuard] Screen Time call failed: $error');
      return false;
    }
  }

  static Future<bool> isAuthorized() async {
    try {
      return await _channel.invokeMethod<bool>('isAuthorized') ?? false;
    } catch (error) {
      debugPrint('[MindControlGuard] Screen Time call failed: $error');
      return false;
    }
  }

  static Future<bool> showAppPicker() async {
    try {
      return await _channel.invokeMethod<bool>('showAppPicker') ?? false;
    } catch (error) {
      debugPrint('[MindControlGuard] Screen Time call failed: $error');
      return false;
    }
  }

  static Future<bool> hasSelectedApps() async {
    try {
      return await _channel.invokeMethod<bool>('hasSelectedApps') ?? false;
    } catch (error) {
      debugPrint('[MindControlGuard] Screen Time call failed: $error');
      return false;
    }
  }

  /// Reuse the saved Family Controls selection, showing Apple's picker only
  /// once when no app tokens have been saved yet.
  static Future<bool> ensureSelectedApps() async {
    if (!await isAuthorized()) return false;
    if (await hasSelectedApps()) return true;
    final picked = await showAppPicker();
    return picked && await hasSelectedApps();
  }

  static Future<bool> blockSelectedApps() async {
    try {
      return await _channel.invokeMethod<bool>('enableRestrictions') ?? false;
    } catch (error) {
      debugPrint('[MindControlGuard] Screen Time call failed: $error');
      return false;
    }
  }

  static Future<bool> enableRestrictions() async {
    try {
      return await _channel.invokeMethod<bool>('enableRestrictions') ?? false;
    } catch (error) {
      debugPrint('[MindControlGuard] Screen Time call failed: $error');
      return false;
    }
  }

  static Future<bool> restoreRestrictionsAfterSkip() async {
    try {
      return await _channel.invokeMethod<bool>('restoreRestrictionsAfterSkip') ??
          false;
    } catch (error) {
      debugPrint('[MindControlGuard] Screen Time call failed: $error');
      return false;
    }
  }

  static Future<bool> allowSelectedAppsTemporarily() async {
    try {
      return await _channel.invokeMethod<bool>('allowSelectedAppsTemporarily') ??
          false;
    } catch (error) {
      debugPrint('[MindControlGuard] Screen Time call failed: $error');
      return false;
    }
  }

  static Future<bool> unblockAll() async {
    try {
      return await _channel.invokeMethod<bool>('unblockAll') ?? false;
    } catch (error) {
      debugPrint('[MindControlGuard] Screen Time call failed: $error');
      return false;
    }
  }

  static Future<bool> blockApp([String? bundleId]) async {
    try {
      return await _channel.invokeMethod<bool>('blockApp') ?? false;
    } catch (error) {
      debugPrint('[MindControlGuard] Screen Time call failed: $error');
      return false;
    }
  }
}
