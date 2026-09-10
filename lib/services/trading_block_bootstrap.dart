import 'dart:io';

import 'package:discipline_mind/common/common.dart';
import 'package:discipline_mind/constants/blocked_apps.dart';
import 'package:discipline_mind/services/app_block_preferences_service.dart';
import 'package:discipline_mind/services/native_app_block_service.dart';
import 'package:discipline_mind/services/trading_apps_service.dart';
import 'package:get/get.dart';

import 'package:get_storage/get_storage.dart';

/// Whether overlay + usage access are granted (required to use blocking on Android).
Future<bool> hasAndroidTradingBlockPermissions() async {
  if (!Platform.isAndroid) return true;
  final p = await NativeAppBlockService().checkPermissions();
  return p['hasOverlayPermission'] == true &&
      p['hasUsageStatsPermission'] == true;
}

String resolveBrokerPackageName(String? name) {
  if (name == null || name.isEmpty) return 'com.zerodha.kite3';
  final lower = name.toLowerCase().trim();
  if (lower.contains('zerodha') || lower.contains('kite')) return 'com.zerodha.kite3';
  if (lower.contains('upstox')) return 'in.upstox.app';
  if (lower.contains('groww')) return 'com.nextbillion.groww';
  if (lower.contains('angel')) return 'com.msf.angelmobile';
  if (lower.contains('dhan')) return 'co.dhan';
  return 'com.zerodha.kite3';
}

/// Checks permissions and starts the blocking service immediately if permitted.
/// Safe to call frequently (e.g. on resume, login, permission callbacks).
Future<bool> checkAndStartTradingBlockIfPermitted({String? explicitUserId}) async {
  if (!Platform.isAndroid) return false;
  final blockService = NativeAppBlockService();
  final userId = explicitUserId ??
      Common.userData.value?.payload?.id?.toString() ??
      GetStorage().read<String>('user_id');

  // Must have a logged-in user
  if (userId == null || userId.isEmpty) return false;

  // Save userId to native SharedPreferences so overlay has it immediately
  await blockService.saveUserIdForOverlay(userId);

  final perms = await blockService.checkPermissions();
  final hasOverlay = perms['hasOverlayPermission'] == true;
  final hasUsage = perms['hasUsageStatsPermission'] == true;

  if (hasOverlay && hasUsage) {
    await applyAndroidTradingAppBlock(explicitUserId: userId);
    return true;
  }
  return false;
}

/// Applies selected-app blocking + foreground service (Android).
/// Same building blocks as GTT / alert flows.
Future<void> applyAndroidTradingAppBlock({String? explicitUserId}) async {
  if (!Platform.isAndroid) return;
  final blockService = NativeAppBlockService();
  final prefs = AppBlockPreferencesService();
  final userId = explicitUserId ??
      Common.userData.value?.payload?.id?.toString() ??
      GetStorage().read<String>('user_id');
  if (userId != null && userId.isNotEmpty) {
    await blockService.saveUserIdForOverlay(userId);
  }

  // Sync monitored trading apps with native layer
  final monitored = blockedTradingAppPackages.toSet();
  if (Get.isRegistered<TradingAppsService>()) {
    final svc = Get.find<TradingAppsService>();
    monitored.addAll(svc.apps.map((e) => e.packageName));
  }
  try {
    await blockService.setMonitoredTradingApps(monitored.toList());
  } catch (_) {}

  var packages = userId != null && userId.isNotEmpty
      ? prefs.getSelectedPackages(userId: userId)
      : <String>[];

  // If no package explicitly selected, check if user has a stored brokerage
  if (packages.isEmpty && userId != null && userId.isNotEmpty) {
    final savedBrokerage = GetStorage().read<String>('mct_brokerage_$userId');
    if (savedBrokerage != null && savedBrokerage.isNotEmpty) {
      final pkg = resolveBrokerPackageName(savedBrokerage);
      if (pkg.isNotEmpty) {
        await prefs.saveSelectedPackage(userId: userId, packageName: pkg);
        packages = [pkg];
      }
    }
  }

  // If still empty (e.g. fresh login before broker selection), fallback to
  // default monitored trading apps so protection is immediately active.
  if (packages.isEmpty) {
    packages = List<String>.from(blockedTradingAppPackages);
  }

  // Ensure switching selection does not keep old apps blocked.
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
