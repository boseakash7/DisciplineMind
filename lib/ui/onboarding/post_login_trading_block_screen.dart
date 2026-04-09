import 'dart:io';

import 'package:discipline_mind/common/app_colors.dart';
import 'package:discipline_mind/common/common.dart';
import 'package:discipline_mind/services/app_block_preferences_service.dart';
import 'package:discipline_mind/services/native_app_block_service.dart';
import 'package:discipline_mind/services/trading_block_bootstrap.dart';
import 'package:discipline_mind/ui/main_home/main_home.dart';
import 'package:discipline_mind/ui/settings/app_block_settings_screen.dart';
import 'package:discipline_mind/ui/widgets/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Android: overlay + usage access are required to use the app while logged in.
class PostLoginTradingBlockScreen extends StatefulWidget {
  const PostLoginTradingBlockScreen({super.key});

  @override
  State<PostLoginTradingBlockScreen> createState() =>
      _PostLoginTradingBlockScreenState();
}

class _PostLoginTradingBlockScreenState
    extends State<PostLoginTradingBlockScreen>
    with WidgetsBindingObserver {
  final _blockService = NativeAppBlockService();
  final _prefs = AppBlockPreferencesService();
  bool _busy = false;
  bool _hasOverlay = false;
  bool _hasUsage = false;

  String? get _userId => Common.userData.value?.payload?.id?.toString();

  bool get _allPermissionsGranted => _hasOverlay && _hasUsage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshPermissions();
    }
  }

  Future<void> _refreshPermissions() async {
    if (!Platform.isAndroid) return;
    final p = await _blockService.checkPermissions();
    if (!mounted) return;
    setState(() {
      _hasOverlay = p['hasOverlayPermission'] == true;
      _hasUsage = p['hasUsageStatsPermission'] == true;
    });
  }

  Future<void> _openPermissionSettings() async {
    final p = await _blockService.checkPermissions();
    if (p['hasOverlayPermission'] != true) {
      await _blockService.requestOverlayPermission();
    }
    if (p['hasUsageStatsPermission'] != true) {
      await _blockService.requestUsageStatsPermission();
    }
    await _refreshPermissions();
  }

  Future<void> _continue() async {
    final userId = _userId;
    if (userId == null || userId.isEmpty) {
      Get.offAll(() => const MainHomeScreen(initialIndex: 2));
      return;
    }

    setState(() => _busy = true);
    try {
      if (Platform.isAndroid) {
        final updated = await _blockService.checkPermissions();
        final ok =
            (updated['hasOverlayPermission'] ?? false) &&
            (updated['hasUsageStatsPermission'] ?? false);
        if (!mounted) return;
        setState(() {
          _hasOverlay = updated['hasOverlayPermission'] == true;
          _hasUsage = updated['hasUsageStatsPermission'] == true;
        });
        if (!ok) {
          AppToast.showToast(
            'Please allow both permissions above before continuing.',
          );
          return;
        }
        await applyAndroidTradingAppBlock();
      }

      if (_prefs.isSetupComplete(userId: userId)) {
        Get.offAll(() => const MainHomeScreen(initialIndex: 2));
      } else {
        Get.offAll(() => const AppBlockSettingsScreen(isFirstSetup: true));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!Platform.isAndroid) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final userId = _userId;
        if (userId != null && _prefs.isSetupComplete(userId: userId)) {
          Get.offAll(() => const MainHomeScreen(initialIndex: 2));
        } else if (userId != null) {
          Get.offAll(() => const AppBlockSettingsScreen(isFirstSetup: true));
        } else {
          Get.offAll(() => const MainHomeScreen(initialIndex: 2));
        }
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trading app lock'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'These permissions are required every time you use the app. '
                'They are the same ones used for GTT and alerts:',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade800,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              _bullet('Display over other apps — to show the block screen'),
              _bullet('Usage access — to detect when a trading app opens'),
              const SizedBox(height: 20),
              Text(
                'After you continue, your selected trading apps will be blocked by default. '
                'They only unlock when you tap Open Trading APP in chat.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 20),
              _permissionRow(
                granted: _hasOverlay,
                label: 'Display over other apps',
              ),
              const SizedBox(height: 8),
              _permissionRow(granted: _hasUsage, label: 'Usage access'),
              if (!_allPermissionsGranted) ...[
                const SizedBox(height: 12),
                Text(
                  'You must allow both before you can continue.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.orange.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _busy ? null : _openPermissionSettings,
                  child: const Text('Open permission settings'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: (_busy || !_allPermissionsGranted)
                      ? null
                      : _continue,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: Colors.grey.shade400,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _busy
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _allPermissionsGranted
                              ? 'Continue'
                              : 'Continue (grant permissions first)',
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _permissionRow({required bool granted, required String label}) {
    return Row(
      children: [
        Icon(
          granted ? Icons.check_circle : Icons.radio_button_unchecked,
          color: granted ? Colors.green : Colors.grey,
          size: 22,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              color: granted ? Colors.green.shade800 : Colors.grey.shade700,
              fontWeight: granted ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.primary,
              height: 1.3,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade800,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
