import 'dart:io';
import 'dart:math';

import 'package:discipline_mind/common/app_keys.dart';
import 'package:get_storage/get_storage.dart';

class DeviceUtils {
  static final GetStorage _box = GetStorage();

  static String getDeviceId() {
    String? id = _box.read(AppKeys.deviceIdKey);
    if (id == null) {
      id = _generateRandomId();
      _box.write(AppKeys.deviceIdKey, id);
    }
    return id;
  }

  static String _generateRandomId({int length = 16}) {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final rand = Random();
    return List.generate(
      length,
      (index) => chars[rand.nextInt(chars.length)],
    ).join();
  }

  static Future<void> resetIds() async {
    await _box.remove(AppKeys.deviceIdKey);
  }

  static String getPlatform() => Platform.isAndroid ? "android" : "ios";
}
