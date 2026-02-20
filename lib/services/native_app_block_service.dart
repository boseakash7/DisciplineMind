import 'dart:io';

import 'package:flutter/services.dart';

/// Native app blocking - no package dependency.
/// Uses platform channels to communicate with Kotlin code in the app.
class NativeAppBlockService {
  static const _channel = MethodChannel('com.discipline_mind/app_block_manager');
  static const _overlayChannel = MethodChannel('com.discipline_mind/app_blocking_overlay');

  /// Block an app by package name.
  Future<bool> blockApp(String packageName) async {
    if (!Platform.isAndroid) return false;
    try {
      return (await _channel.invokeMethod<bool>('blockApp', {
        'packageName': packageName,
      })) ??
          false;
    } catch (e) {
      print('[NativeAppBlock] blockApp failed: $e');
      return false;
    }
  }

  /// Unblock an app by package name.
  Future<bool> unblockApp(String packageName) async {
    if (!Platform.isAndroid) return false;
    try {
      return (await _channel.invokeMethod<bool>('unblockApp', {
        'packageName': packageName,
      })) ??
          false;
    } catch (e) {
      print('[NativeAppBlock] unblockApp failed: $e');
      return false;
    }
  }

  /// Get list of blocked package names.
  Future<List<String>> getBlockedApps() async {
    if (!Platform.isAndroid) return [];
    try {
      final result = await _channel.invokeMethod<List<dynamic>>('getBlockedApps');
      return result?.map((e) => e.toString()).toList() ?? [];
    } catch (e) {
      print('[NativeAppBlock] getBlockedApps failed: $e');
      return [];
    }
  }

  /// Check if app is blocked.
  Future<bool> isAppBlocked(String packageName) async {
    if (!Platform.isAndroid) return false;
    try {
      return (await _channel.invokeMethod<bool>('isAppBlocked', {
        'packageName': packageName,
      })) ??
          false;
    } catch (e) {
      print('[NativeAppBlock] isAppBlocked failed: $e');
      return false;
    }
  }

  /// Start the foreground blocking service.
  Future<bool> startBlockingService() async {
    if (!Platform.isAndroid) return false;
    try {
      return (await _channel.invokeMethod<bool>('startBlockingService')) ?? false;
    } catch (e) {
      print('[NativeAppBlock] startBlockingService failed: $e');
      return false;
    }
  }

  /// Stop the blocking service.
  Future<bool> stopBlockingService() async {
    if (!Platform.isAndroid) return false;
    try {
      return (await _channel.invokeMethod<bool>('stopBlockingService')) ?? false;
    } catch (e) {
      print('[NativeAppBlock] stopBlockingService failed: $e');
      return false;
    }
  }

  /// Check overlay and usage stats permissions.
  Future<Map<String, bool>> checkPermissions() async {
    if (!Platform.isAndroid) {
      return {'hasOverlayPermission': false, 'hasUsageStatsPermission': false};
    }
    try {
      final result =
          await _channel.invokeMethod<Map<Object?, Object?>>('checkPermissions');
      return {
        'hasOverlayPermission': result?['hasOverlayPermission'] == true,
        'hasUsageStatsPermission': result?['hasUsageStatsPermission'] == true,
      };
    } catch (e) {
      print('[NativeAppBlock] checkPermissions failed: $e');
      return {'hasOverlayPermission': false, 'hasUsageStatsPermission': false};
    }
  }

  /// Request overlay (display over other apps) permission.
  Future<void> requestOverlayPermission() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('requestOverlayPermission');
    } catch (e) {
      print('[NativeAppBlock] requestOverlayPermission failed: $e');
    }
  }

  /// Get usage stats for blocked apps (opens, opens when blocked, usage time).
  Future<List<Map<String, dynamic>>> getBlockedAppUsageStats() async {
    if (!Platform.isAndroid) return [];
    try {
      final result = await _channel.invokeMethod<List<dynamic>>('getBlockedAppUsageStats');
      return result
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [];
    } catch (e) {
      print('[NativeAppBlock] getBlockedAppUsageStats failed: $e');
      return [];
    }
  }

  /// Save userId for native overlay (used for alert check / auto-unblock).
  Future<void> saveUserIdForOverlay(String userId) async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('saveUserIdForOverlay', {'userId': userId});
    } catch (e) {
      print('[NativeAppBlock] saveUserIdForOverlay failed: $e');
    }
  }

  /// Request usage stats permission.
  Future<void> requestUsageStatsPermission() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('requestUsageStatsPermission');
    } catch (e) {
      print('[NativeAppBlock] requestUsageStatsPermission failed: $e');
    }
  }

  /// Close the blocking overlay (when user switches to our app).
  Future<bool> closeOverlay() async {
    if (!Platform.isAndroid) return false;
    try {
      return (await _overlayChannel.invokeMethod<bool>('closeOverlay')) ?? false;
    } catch (e) {
      print('[NativeAppBlock] closeOverlay failed: $e');
      return false;
    }
  }

  /// Get current blocked app package (from overlay engine).
  Future<String?> getCurrentBlockedApp() async {
    if (!Platform.isAndroid) return null;
    try {
      final result =
          await _overlayChannel.invokeMethod<String>('getCurrentBlockedApp');
      return (result != null && result.isNotEmpty) ? result : null;
    } catch (e) {
      print('[NativeAppBlock] getCurrentBlockedApp failed: $e');
      return null;
    }
  }

  /// Unblock packages and close overlay (force unblock from overlay).
  Future<bool> unblockAndClose(List<String> packages) async {
    if (!Platform.isAndroid) return false;
    try {
      return (await _overlayChannel.invokeMethod<bool>('unblockAndClose', {
        'packages': packages,
      })) ??
          false;
    } catch (e) {
      print('[NativeAppBlock] unblockAndClose failed: $e');
      return false;
    }
  }
}
