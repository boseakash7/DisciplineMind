import 'package:discipline_mind/common/app_colors.dart';
import 'package:discipline_mind/common/common.dart';
import 'package:discipline_mind/services/app_block_preferences_service.dart';
import 'package:discipline_mind/services/native_app_block_service.dart';
import 'package:discipline_mind/services/trading_apps_service.dart';
import 'package:discipline_mind/services/trading_block_bootstrap.dart';
import 'package:discipline_mind/ui/main_home/main_home.dart';
import 'package:discipline_mind/ui/widgets/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AppBlockSettingsScreen extends StatefulWidget {
  const AppBlockSettingsScreen({super.key, this.isFirstSetup = false});

  final bool isFirstSetup;

  @override
  State<AppBlockSettingsScreen> createState() => _AppBlockSettingsScreenState();
}

class _AppBlockSettingsScreenState extends State<AppBlockSettingsScreen> {
  final AppBlockPreferencesService _prefs = AppBlockPreferencesService();
  final NativeAppBlockService _blockService = NativeAppBlockService();
  bool _isSaving = false;

  /// Single selected package from API list.
  String? _selectedPackage;

  String? get _userId => Common.userData.value?.payload?.id?.toString();

  TradingAppsService get _tradingApps {
    if (!Get.isRegistered<TradingAppsService>()) {
      Get.put(TradingAppsService(), permanent: true);
    }
    return Get.find<TradingAppsService>();
  }

  @override
  void initState() {
    super.initState();
    final userId = _userId;
    if (userId != null) {
      _selectedPackage = _prefs.getSelectedPackage(userId: userId);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadApps());
  }

  Future<void> _loadApps() async {
    await _tradingApps.refresh();
    if (!mounted) return;
    final userId = _userId;
    if (userId == null) return;
    final saved = _prefs.getSelectedPackage(userId: userId);
    if (saved != null &&
        _tradingApps.apps.any((a) => a.packageName == saved)) {
      setState(() => _selectedPackage = saved);
    } else if (_selectedPackage != null &&
        _tradingApps.apps.every((a) => a.packageName != _selectedPackage)) {
      setState(() => _selectedPackage = null);
    }
  }

  Future<void> _onSave() async {
    final userId = _userId;
    if (userId == null) {
      AppToast.showToast('User not found. Please login again.');
      return;
    }
    if (_selectedPackage == null || _selectedPackage!.isEmpty) {
      AppToast.showToast('Please select one trading app');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final previousPackage = _prefs.getSelectedPackage(userId: userId);
      final nextPackage = _selectedPackage!;

      // If user switched broker app, immediately remove old app from block list.
      if (previousPackage != null &&
          previousPackage.isNotEmpty &&
          previousPackage != nextPackage) {
        await _blockService.unblockApp(previousPackage);
        await _blockService.unblockAndClose([previousPackage]);
      }

      await _prefs.saveSelectedPackage(
        userId: userId,
        packageName: nextPackage,
      );
      await applyAndroidTradingAppBlock();
      if (widget.isFirstSetup) {
        Get.offAll(() => const MainHomeScreen(initialIndex: 2));
      } else {
        AppToast.showToast('Trading app updated');
        Get.back();
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title =
        widget.isFirstSetup ? 'Select trading app' : 'Blocked trading app';
    final subtitle = widget.isFirstSetup
        ? 'Choose one broker app to lock. You can change it later in settings.'
        : 'Choose one broker app to lock when alerts or GTT are active.';

    return WillPopScope(
      onWillPop: () async => !widget.isFirstSetup,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: !widget.isFirstSetup,
          title: Text(title),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Obx(() {
                    final svc = _tradingApps;
                    if (svc.isLoading.value && svc.apps.isEmpty) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                    if (svc.apps.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              svc.lastError.value ??
                                  'Could not load apps. Check your connection.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: _loadApps,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      );
                    }
                    return ListView(
                      children: svc.apps.map((app) {
                        final selected =
                            _selectedPackage == app.packageName;
                        return Card(
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: selected
                                  ? AppColors.primary
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: RadioListTile<String>(
                            value: app.packageName,
                            groupValue: _selectedPackage,
                            activeColor: AppColors.primary,
                            title: Text(app.name),
                            subtitle: Text(
                              app.packageName,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            onChanged: (v) {
                              if (v != null) {
                                setState(() => _selectedPackage = v);
                              }
                            },
                          ),
                        );
                      }).toList(),
                    );
                  }),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isSaving ? null : _onSave,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(widget.isFirstSetup ? 'CONTINUE' : 'SAVE'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
