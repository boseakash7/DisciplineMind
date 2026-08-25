import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../common/v2_app_colors.dart';
import '../../controllers/v2_auth_controller.dart';
import '../../../ui/android_app_block/app_usage_stats_page.dart';
import '../../../ui/main_home/alert_main.dart';
import '../../../ui/settings/app_block_settings_screen.dart';
import '../../../ui/version_selector_screen.dart';

class V2MoreScreen extends StatelessWidget {
  const V2MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final V2AuthController authController = Get.isRegistered<V2AuthController>()
        ? Get.find<V2AuthController>()
        : Get.put(V2AuthController());

    return Scaffold(
      backgroundColor: V2AppColors.backgroundGray,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.auto_awesome_rounded, color: V2AppColors.primary, size: 20),
            SizedBox(width: 8),
            Text(
              "ZENO AI More",
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: V2AppColors.textBlack,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Settings & Preferences',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: V2AppColors.textBlack,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Manage your ZENO AI account and app preferences',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 20),
              _tile(
                icon: Icons.notifications_outlined,
                title: 'Price Alerts',
                subtitle: 'Manage your price alert list and notifications',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AlertsMainScreen()),
                  );
                },
              ),
              const SizedBox(height: 12),
              _tile(
                icon: Icons.shield_outlined,
                title: 'Blocked Apps',
                subtitle: 'Choose which trading apps stay locked for discipline',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AppBlockSettingsScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _tile(
                icon: Icons.analytics_outlined,
                title: 'App Tracking',
                subtitle: 'View tracked usage and blocking activity',
                onTap: () {
                  if (defaultTargetPlatform == TargetPlatform.android) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AppUsageStatsPage(),
                      ),
                    );
                    return;
                  }
                  Get.snackbar(
                    'Not Available',
                    'App tracking is available on Android only',
                  );
                },
              ),
              const SizedBox(height: 12),
              _tile(
                icon: Icons.swap_horiz_rounded,
                title: 'Switch App Version',
                subtitle: 'Switch between Classic (v1) and ZENO AI (v2)',
                accent: true,
                onTap: () {
                  Get.offAll(() => const AppVersionSelectorScreen());
                },
              ),
              const SizedBox(height: 12),
              _tile(
                icon: Icons.logout,
                title: 'Logout',
                subtitle: 'Sign out from your ZENO AI account',
                danger: true,
                onTap: authController.logout,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool danger = false,
    bool accent = false,
  }) {
    final borderColor = danger
        ? Colors.red.shade200
        : accent
            ? V2AppColors.primary.withValues(alpha: 0.35)
            : const Color(0xFFE2E8F0);
    final iconBg = danger
        ? Colors.red.shade50
        : accent
            ? V2AppColors.primary.withValues(alpha: 0.12)
            : const Color(0xFFF1F5F9);
    final iconColor = danger
        ? Colors.red.shade600
        : accent
            ? V2AppColors.primaryDark
            : V2AppColors.primary;
    final titleColor = danger
        ? Colors.red.shade700
        : accent
            ? V2AppColors.primaryDark
            : V2AppColors.textBlack;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: danger ? Colors.red.shade400 : Colors.grey.shade400,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
