import 'dart:io';

import 'package:discipline_mind/common/common.dart';
import 'package:discipline_mind/services/app_block_preferences_service.dart';
import 'package:discipline_mind/services/native_app_block_service.dart';

/// Whether overlay + usage access are granted (required to use blocking on Android).
Future<bool> hasAndroidTradingBlockPermissions() async {
  if (!Platform.isAndroid) return true;
  final p = await NativeAppBlockService().checkPermissions();
  return p['hasOverlayPermission'] == true &&
      p['hasUsageStatsPermission'] == true;
}

/// Applies selected-app blocking + foreground service (Android).
/// Same building blocks as GTT / alert flows.
Future<void> applyAndroidTradingAppBlock() async {
  if (!Platform.isAndroid) return;
  final blockService = NativeAppBlockService();
  final prefs = AppBlockPreferencesService();
  final userId = Common.userData.value?.payload?.id?.toString();
  if (userId != null && userId.isNotEmpty) {
    await blockService.saveUserIdForOverlay(userId);
  }
  final packages = userId != null && userId.isNotEmpty
      ? prefs.getSelectedPackages(userId: userId)
      : <String>[];
  if (packages.isEmpty) return;
  for (final package in packages) {
    await blockService.blockApp(package);
  }
  try {
    await blockService.startBlockingService();
  } catch (e) {
    print('[TradingBlockBootstrap] startBlockingService failed: $e');
  }
}
