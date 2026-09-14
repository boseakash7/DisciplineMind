import 'package:flutter/services.dart';

class BlockController {
  static const _channel = MethodChannel('app_blocker_channel');

  static Future<void> update(bool enabled, List<String> blockedApps) async {
    await _channel.invokeMethod("update", {
      "enabled": enabled,
      "blocked": blockedApps,
    });
  }
}
