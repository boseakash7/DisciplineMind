import 'package:flutter/services.dart';

class IosScreenTime {
  static const _channel = MethodChannel('screen_time');

  static Future<bool> requestPermission() async {
    return await _channel.invokeMethod('requestPermission');
  }

  static Future<void> blockApp(String bundleId) async {
    await _channel.invokeMethod('blockApp', {'bundleId': bundleId});
  }

  static Future<void> unblockAll() async {
    await _channel.invokeMethod('unblockAll');
  }
}
