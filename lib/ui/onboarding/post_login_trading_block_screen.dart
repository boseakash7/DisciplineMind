import 'dart:io';

import 'package:discipline_mind/common/app_colors.dart';
import 'package:discipline_mind/common/common.dart';
import 'package:discipline_mind/services/app_block_preferences_service.dart';
import 'package:discipline_mind/services/native_app_block_service.dart';
import 'package:discipline_mind/services/trading_block_bootstrap.dart';
import 'package:discipline_mind/ui/main_home/main_home.dart';
import 'package:discipline_mind/ui/settings/app_block_settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// ============================================================================
// POST LOGIN TRADING BLOCK SCREEN
//
// This used to show the "Permission 1 / Permission 2" screens directly.
// That UI now lives inside TradingProcessScreen (steps 5 & 6), so this
// screen is just a lightweight redirect: it checks whether the user has
// already finished the Mind Control Trading setup and/or already granted
// the required Android permissions, applies the app block if it can, and
// routes the user to the right place — without showing any permission UI
// itself.
// ============================================================================
class PostLoginTradingBlockScreen extends StatefulWidget {
  const PostLoginTradingBlockScreen({super.key});

  @override
  State<PostLoginTradingBlockScreen> createState() =>
      _PostLoginTradingBlockScreenState();
}

class _PostLoginTradingBlockScreenState
    extends State<PostLoginTradingBlockScreen> {
  final _blockService = NativeAppBlockService();
  final _prefs = AppBlockPreferencesService();

  String? get _userId => Common.userData.value?.payload?.id?.toString();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolveAndRedirect());
  }

  Future<void> _resolveAndRedirect() async {
    final userId = _userId;

    // No logged-in user id — nothing to set up, just go home.
    if (userId == null || userId.isEmpty) {
      Get.offAll(() => const MainHomeScreen(initialIndex: 2));
      return;
    }

    // Off-Android there's no overlay/usage-stats permission concept at all.
    if (!Platform.isAndroid) {
      if (_prefs.isSetupComplete(userId: userId)) {
        Get.offAll(() => const MainHomeScreen(initialIndex: 2));
      } else {
        Get.offAll(() => const AppBlockSettingsScreen(isFirstSetup: true));
      }
      return;
    }

    // On Android: if the required permissions are already granted (e.g. the
    // user granted them earlier via the TradingProcessScreen flow), (re)apply
    // the block and continue as normal.
    final permissions = await _blockService.checkPermissions();
    final hasOverlay = permissions['hasOverlayPermission'] == true;
    final hasUsage = permissions['hasUsageStatsPermission'] == true;

    if (hasOverlay && hasUsage) {
      await applyAndroidTradingAppBlock();
    }

    if (!mounted) return;

    if (_prefs.isSetupComplete(userId: userId)) {
      Get.offAll(() => const MainHomeScreen(initialIndex: 2));
    } else {
      // Permissions (if still missing) will be requested as part of the
      // TradingProcessScreen setup flow, not here.
      Get.offAll(() => const AppBlockSettingsScreen(isFirstSetup: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}