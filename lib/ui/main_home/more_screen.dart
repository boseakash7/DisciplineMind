import 'package:discipline_mind/common/app_colors.dart';
import 'package:discipline_mind/common/common.dart';
import 'package:discipline_mind/ui/android_app_block/app_usage_stats_page.dart';
import 'package:discipline_mind/ui/main_home/alert_main.dart';
import 'package:discipline_mind/ui/settings/app_block_settings_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'More',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textBlack,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Manage your account and app preferences',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 18),
              _tile(
                icon: Icons.notifications_outlined,
                title: 'Price Alerts',
                subtitle: 'Manage your alert list and statuses',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AlertsMainScreen()),
                  );
                },
              ),
              const SizedBox(height: 10),
              _tile(
                icon: Icons.shield_outlined,
                title: 'Blocked Apps',
                subtitle: 'Choose which trading app should stay locked',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AppBlockSettingsScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
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
              const SizedBox(height: 10),
              _tile(
                icon: Icons.logout,
                title: 'Logout',
                subtitle: 'Sign out from your account',
                danger: true,
                onTap: Common.logout,
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
  }) {
    final borderColor = danger ? Colors.red.shade200 : Colors.grey.shade300;
    final iconBg = danger ? Colors.red.shade50 : AppColors.primary.withOpacity(0.1);
    final iconColor = danger ? Colors.red.shade600 : AppColors.primary;
    final titleColor = danger ? Colors.red.shade700 : AppColors.textBlack;

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
              color: Colors.black.withOpacity(0.03),
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
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14.5,
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
                color: danger ? Colors.red.shade400 : Colors.grey.shade500,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
