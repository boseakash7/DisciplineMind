import 'dart:io';

import 'package:discipline_mind/common/common.dart';
import 'package:discipline_mind/constants/blocked_apps.dart';
import 'package:discipline_mind/services/app_block_preferences_service.dart';
import 'package:discipline_mind/services/native_app_block_service.dart';
import 'package:discipline_mind/services/trading_apps_service.dart';
import 'package:get/get.dart';

/// Whether overlay + usage access are granted (required to use blocking on Android).
Future<bool> hasAndroidTradingBlockPermissions() async {
  if (!Platform.isAndroid) return true;
  final p = await NativeAppBlockService().checkPermissions();
  return p['hasOverlayPermission'] == true &&
      p['hasUsageStatsPermission'] == true;
}

/// Re-apply selected apps + start service after login / resume.
/// No-op if user not logged in or setup incomplete (avoids clearing block list).
Future<void> ensureAndroidTradingBlockRunning() async {
  if (!Platform.isAndroid) return;
  final userId = Common.userData.value?.payload?.id?.toString();
  if (userId == null || userId.isEmpty) return;
  final prefs = AppBlockPreferencesService();
  if (!prefs.isSetupComplete(userId: userId)) return;
  if (!await hasAndroidTradingBlockPermissions()) return;
  await applyAndroidTradingAppBlock();
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
  if (packages.isEmpty) {
    // No app selected => clear known blocked trading apps and stop service.
    final known = blockedTradingAppPackages.toSet();
    if (Get.isRegistered<TradingAppsService>()) {
      final svc = Get.find<TradingAppsService>();
      known.addAll(svc.apps.map((e) => e.packageName));
    }
    for (final package in known) {
      await blockService.unblockApp(package);
    }
    await blockService.unblockAndClose(known.toList());
    await blockService.stopBlockingService();
    return;
  }

  // Ensure switching selection does not keep old app blocked.
  final selectedSet = packages.toSet();
  final known = blockedTradingAppPackages.toSet();
  if (Get.isRegistered<TradingAppsService>()) {
    final svc = Get.find<TradingAppsService>();
    known.addAll(svc.apps.map((e) => e.packageName));
  }
  final toUnblock = known.where((p) => !selectedSet.contains(p)).toList();
  for (final package in toUnblock) {
    await blockService.unblockApp(package);
  }
  if (toUnblock.isNotEmpty) {
    await blockService.unblockAndClose(toUnblock);
  }

  for (final package in selectedSet) {
    await blockService.blockApp(package);
  }
  try {
    await blockService.startBlockingService();
  } catch (e) {
    print('[TradingBlockBootstrap] startBlockingService failed: $e');
  }
}
