import 'dart:async';
import 'dart:io';

import 'package:discipline_mind/common/ThemeService.dart';
import 'package:discipline_mind/common/app_colors.dart';
import 'package:discipline_mind/common/common.dart';
import 'package:discipline_mind/ui/main_home/alert_main.dart';
import 'package:discipline_mind/ui/main_home/process_detail_screen.dart';
import 'package:discipline_mind/services/app_diagnostic_logger.dart';
import 'package:discipline_mind/services/app_url_launcher.dart';
import 'package:discipline_mind/services/app_block_preferences_service.dart';
import 'package:discipline_mind/services/native_app_block_service.dart';
import 'package:discipline_mind/services/trading_block_bootstrap.dart';
import 'package:discipline_mind/controller/trading_process_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:discipline_mind/ui/widgets/app_toast.dart';
import 'package:share_plus/share_plus.dart';

import 'mct_lessons_screen.dart';

class _TradingAppOption {
  const _TradingAppOption({
    required this.value,
    required this.label,
    required this.packageName,
    required this.logo,
    required this.logoColor,
  });

  final String value;
  final String label;
  final String packageName;
  final String logo;
  final Color logoColor;
}

const _supportedTradingApps = [
  _TradingAppOption(
    value: 'zerodha',
    label: 'Zerodha Kite',
    packageName: 'com.zerodha.kite3',
    logo: 'K',
    logoColor: Color(0xFFF15B35),
  ),
  _TradingAppOption(
    value: 'upstox',
    label: 'Upstox',
    packageName: 'in.upstox.app',
    logo: 'U',
    logoColor: Color(0xFF5B35A5),
  ),
  _TradingAppOption(
    value: 'groww',
    label: 'Groww',
    packageName: 'com.nextbillion.groww',
    logo: 'G',
    logoColor: Color(0xFF28B9A7),
  ),
];

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  Future<void> _shareDiagnosticLog(BuildContext context) async {
    try {
      final path = await AppDiagnosticLogger.getLogFilePath();
      if (path == null || !await File(path).exists()) {
        AppToast.showToast('Diagnostic log file is not available.');
        return;
      }
      await SharePlus.instance.share(ShareParams(files: [XFile(path)]));
    } catch (_) {
      AppToast.showToast('Unable to share diagnostic log.');
    }
  }

  TradingProcessController _processController() {
    return Get.isRegistered<TradingProcessController>()
        ? Get.find<TradingProcessController>()
        : Get.put(TradingProcessController());
  }

  String _tradingAppLabel(String raw) {
    final normalized = raw.trim().toLowerCase();
    if (normalized == 'zerodha' ||
        normalized == 'kite' ||
        normalized == 'zerodha_kite') {
      return 'Zerodha Kite';
    }
    if (normalized == 'upstox') return 'Upstox';
    if (normalized == 'groww') return 'Groww';
    return raw.trim().isEmpty ? 'Not selected' : raw;
  }

  Future<void> _showTradingAppPicker(
    BuildContext context,
    TradingProcessController controller,
  ) async {
    if (controller.currentProcess.value == null) {
      await controller.fetchProcess();
    }
    if (!context.mounted) return;

    final process = controller.currentProcess.value;
    if (process == null) {
      AppToast.showToast('Trading process is not available');
      return;
    }

    final savedBroker = process.brokingApp.trim().toLowerCase();
    final currentValue = savedBroker == 'zerodha_kite' || savedBroker == 'kite'
        ? 'zerodha'
        : savedBroker;
    final selectedValue = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final isDark = Theme.of(sheetContext).brightness == Brightness.dark;
        final surface = isDark ? AppColors.darkSurface : Colors.white;
        final primaryText = isDark
            ? AppColors.darkTextPrimary
            : AppColors.lightTextPrimary;
        final secondaryText = isDark
            ? AppColors.darkTextSecondary
            : Colors.grey.shade600;

        return SafeArea(
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(22),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: secondaryText.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Change trading app',
                  style: TextStyle(
                    color: primaryText,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Choose the app you use for trading.',
                  style: TextStyle(color: secondaryText, fontSize: 13),
                ),
                const SizedBox(height: 12),
                ..._supportedTradingApps.map((app) {
                  final selected = app.value == currentValue;
                  return GestureDetector(
                    onTap: () => Navigator.pop(sheetContext, app.value),
                    child: Container(
                      width: double.infinity,
                      height: 48,
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: selected
                            ? (isDark
                                  ? AppColors.primary.withValues(alpha: 0.14)
                                  : const Color(0xFFFBF8FF))
                            : surface,
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(
                          color: selected
                              ? AppColors.primary
                              : (isDark
                                    ? AppColors.darkBorder
                                    : const Color(0xFFE2E0E9)),
                          width: selected ? 1.2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          _buildTradingAppLogo(app),
                          const SizedBox(width: 11),
                          Expanded(
                            child: Text(
                              app.label,
                              style: TextStyle(
                                color: primaryText,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Icon(
                            selected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            color: selected
                                ? AppColors.primary
                                : (isDark
                                      ? Colors.white38
                                      : const Color(0xFF85838F)),
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );

    if (selectedValue == null || selectedValue == currentValue) return;
    if (!context.mounted) return;
    final selectedApp = _supportedTradingApps.firstWhere(
      (app) => app.value == selectedValue,
    );
    final userId = Common.userData.value?.payload?.id?.toString();
    if (userId == null || userId.isEmpty) return;

    final rootNavigator = Navigator.of(context, rootNavigator: true);
    unawaited(
      showDialog<void>(
        context: context,
        useRootNavigator: true,
        barrierDismissible: false,
        builder: (_) => PopScope(
          canPop: false,
          child: Center(
            child: Semantics(
              label: 'Updating selected trading app',
              liveRegion: true,
              child: CircularProgressIndicator(),
            ),
          ),
        ),
      ),
    );

    try {
      // Keep the loader visible for both the API request and the native
      // app-blocking changes that follow it.
      final updated = await controller.updateBrokingApp(selectedApp.value);
      if (!updated) return;

      final preferences = AppBlockPreferencesService();
      final previousPackage = preferences.getSelectedPackage(userId: userId);
      await preferences.saveSelectedPackage(
        userId: userId,
        packageName: selectedApp.packageName,
      );
      await GetStorage().write('mct_brokerage_$userId', selectedApp.value);

      if (Platform.isAndroid) {
        final blockService = NativeAppBlockService();
        if (previousPackage != null &&
            previousPackage.isNotEmpty &&
            previousPackage != selectedApp.packageName) {
          await blockService.unblockApp(previousPackage);
          await blockService.unblockAndClose([previousPackage]);
        }
        await applyAndroidTradingAppBlock(explicitUserId: userId);
      }
    } catch (_) {
      AppToast.showToast('Unable to update trading app. Please try again.');
    } finally {
      if (rootNavigator.canPop()) rootNavigator.pop();
    }
  }

  Widget _buildTradingAppLogo(_TradingAppOption app) {
    return Container(
      width: 27,
      height: 27,
      decoration: BoxDecoration(
        color: app.logoColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(
        app.logo,
        style: TextStyle(
          color: app.logoColor,
          fontSize: 14,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildTradingAppTile(BuildContext context) {
    final controller = _processController();
    return Obx(() {
      final process = controller.currentProcess.value;
      final currentApp = process == null
          ? 'Not selected'
          : _tradingAppLabel(process.brokingApp);
      return _buildTile(
        icon: Icons.swap_horiz_rounded,
        title: 'Trading App',
        subtitle: controller.isUpdating.value
            ? 'Updating...'
            : 'Currently using $currentApp',
        isLoading: controller.isUpdating.value,
        onTap: () => _showTradingAppPicker(context, controller),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      //   This makes it reactive
      final isDark = ThemeService().isDarkMode;

      return Scaffold(
        backgroundColor: isDark
            ? AppColors.darkBackground
            : AppColors.lightBackground,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'More',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Manage your account and app preferences',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 24),

                _buildTile(
                  icon: Icons.alt_route_rounded,
                  title: 'Trading Process',
                  subtitle:
                      'View and update your active trading rules & limits',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ProcessDetailScreen(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _buildTradingAppTile(context),
                const SizedBox(height: 12),
                _buildTile(
                  icon: Icons.play_lesson_outlined,
                  title: 'MCT Lessons',
                  subtitle: '5 Non-Negotiable Rules for discipline',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MctLessonsScreen()),
                  ),
                ),
                const SizedBox(height: 12),
                _buildTile(
                  icon: Icons.notifications_outlined,
                  title: 'Price Alerts',
                  subtitle: 'Manage your alert list and statuses',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AlertsMainScreen()),
                  ),
                ),
                const SizedBox(height: 12),

                _buildTile(
                  icon: Icons.description_outlined,
                  title: 'Terms & Conditions',
                  subtitle: 'Read our terms and conditions',
                  onTap: AppUrlLauncher.openTermsAndConditions,
                ),
                const SizedBox(height: 12),

                _buildTile(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy Policy',
                  subtitle: 'Read our privacy policy',
                  onTap: AppUrlLauncher.openPrivacyPolicy,
                ),
                const SizedBox(height: 12),

                // Theme Switcher — hidden while the app is light-theme only.
                // _themeTile(isDark: isDark) kept below (unused) so the
                // switcher can be re-enabled later without rebuilding it.
                _buildTile(
                  icon: Icons.share_outlined,
                  title: 'Share Diagnostic Log',
                  subtitle: 'Send recent app logs via WhatsApp, email, etc.',
                  onTap: () => _shareDiagnosticLog(context),
                ),
                const SizedBox(height: 12),

                _buildTile(
                  icon: Icons.logout,
                  title: 'Logout',
                  subtitle: Common.isLoggingOut.value
                      ? 'Signing out...'
                      : 'Sign out from your account',
                  danger: true,
                  isLoading: Common.isLoggingOut.value,
                  onTap: () {
                    Common.logout();
                  },
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  static Future<void> _launchUrlString(String urlStr) async {
    await AppUrlLauncher.openInAppWebView(urlStr);
  }

  // Regular menu tile
  Widget _buildTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool danger = false,
    bool isLoading = false,
  }) {
    final isDark = ThemeService().isDarkMode;

    final bgColor = isDark ? AppColors.darkSurface : Colors.white;
    final borderColor = danger
        ? Colors.red.shade200
        : (isDark ? AppColors.darkBorder : Colors.grey.shade300);

    final iconBg = danger
        ? Colors.red.shade50
        : AppColors.primary.withOpacity(0.1);

    final iconColor = danger ? Colors.red.shade600 : AppColors.primary;
    final titleColor = danger
        ? Colors.red.shade700
        : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary);

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: isLoading ? null : onTap,
      child: Ink(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              if (isLoading)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: danger ? Colors.red.shade600 : AppColors.primary,
                  ),
                )
              else
                Icon(
                  Icons.chevron_right_rounded,
                  color: danger ? Colors.red.shade400 : Colors.grey.shade500,
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Beautiful Theme Tile with Switch
  Widget _themeTile({required bool isDark}) {
    final cardBg = isDark ? AppColors.darkSurface : Colors.white;
    final cardBorder = isDark ? AppColors.darkBorder : Colors.grey.shade300;
    final titleCol = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final subtitleCol = isDark
        ? AppColors.darkTextSecondary
        : Colors.grey.shade600;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => ThemeService().switchTheme(),
      child: Ink(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                height: 38,
                width: 38,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Appearance',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: titleCol,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isDark ? 'Dark mode is on' : 'Light mode is on',
                      style: TextStyle(fontSize: 12.5, color: subtitleCol),
                    ),
                  ],
                ),
              ),
              Transform.scale(
                scale: 0.85,
                child: Switch.adaptive(
                  value: isDark,
                  activeColor: AppColors.primary,
                  onChanged: (_) => ThemeService().switchTheme(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
