import 'package:discipline_mind/common/app_colors.dart';
import 'package:discipline_mind/common/common.dart';
import 'package:discipline_mind/services/app_block_preferences_service.dart';
import 'package:discipline_mind/services/native_app_block_service.dart';
import 'package:discipline_mind/services/trading_apps_service.dart';
import 'package:discipline_mind/services/trading_block_bootstrap.dart';
import 'package:discipline_mind/ui/main_home/main_home.dart';
import 'package:discipline_mind/ui/widgets/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  /// True once the user has manually tapped a card/radio.
  /// Prevents the async _loadApps() refresh from overwriting their choice.
  bool _userInteracted = false;

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

    // Don't override what the user already picked while the
    // network call was still in flight.
    if (_userInteracted) return;

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

  void _onSelectApp(String packageName) {
    setState(() {
      _userInteracted = true;
      _selectedPackage = packageName;
    });
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

  /// Brand color + logo asset per broker, matched by package name / app name.
  /// Falls back to [AppColors.primary] + a generic icon if unmatched.
  ({Color color, String asset}) _brandFor(String packageName, String appName) {
    final key = packageName.toLowerCase();
    final name = appName.toLowerCase();

    if (key.contains('zerodha') || name.contains('zerodha') || name.contains('kite')) {
      return (color: const Color(0xFFF6461A), asset: 'assets/ZerodhaKite.png');
    }
    if (key.contains('upstox') || name.contains('upstox')) {
      return (color: const Color(0xFF5B298C), asset: 'assets/upsocks.png');
    }
    if (key.contains('groww') || name.contains('groww')) {
      return (color: const Color(0xFF5367FF), asset: 'assets/groww.png');
    }
    return (color: AppColors.primary, asset: '');
  }

  Widget _buildAppLogo(String asset, Color brandColor) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(11),
      ),
      padding: const EdgeInsets.all(7),
      child: asset.isNotEmpty
          ? Image.asset(asset, fit: BoxFit.contain)
          : Icon(Icons.show_chart, color: brandColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final scaffoldBg = isDark ? const Color(0xFF000000) : const Color(0xFFF5F6FA);
    final cardBg = isDark ? const Color(0xFF121212) : Colors.white;
    final unselectedBorder = isDark ? Colors.white24 : Colors.grey.shade300;
    final titleColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final packageTextColor = isDark ? Colors.grey.shade500 : Colors.grey.shade600;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: scaffoldBg,
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
      child: WillPopScope(
        onWillPop: () async => !widget.isFirstSetup,
        child: Scaffold(
          backgroundColor: scaffoldBg,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Select ',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: titleColor,
                        ),
                      ),
                      Text(
                        'trading app',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Subtitle
                  Center(
                    child: Text(
                      'Choose one broker app to lock. you can\nchange it later in settings',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: subtitleColor,
                        height: 1.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 50),
                  Expanded(
                    child: Obx(() {
                      final svc = _tradingApps;
                      if (svc.isLoading.value && svc.apps.isEmpty) {
                        return Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
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
                                style: TextStyle(color: subtitleColor),
                              ),
                              const SizedBox(height: 16),
                              FilledButton(
                                onPressed: _loadApps,
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                ),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        );
                      }
                      return ListView.separated(
                        itemCount: svc.apps.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final app = svc.apps[index];
                          final selected = _selectedPackage == app.packageName;
                          final brand = _brandFor(app.packageName, app.name);

                          return InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => _onSelectApp(app.packageName),
                            child: Container(
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: selected ? brand.color : unselectedBorder,
                                  width: selected ? 1.4 : 1,
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              child: Row(
                                children: [
                                  _buildAppLogo(brand.asset, brand.color),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          app.name,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            color: titleColor,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          app.packageName,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: packageTextColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Radio<String>(
                                    value: app.packageName,
                                    groupValue: _selectedPackage,
                                    activeColor: brand.color,
                                    onChanged: (v) {
                                      if (v != null) _onSelectApp(v);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
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
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  widget.isFirstSetup ? 'CONTINUE' : 'SAVE',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward, size: 18),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}