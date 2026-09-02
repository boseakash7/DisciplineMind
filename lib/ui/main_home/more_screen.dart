import 'package:discipline_mind/common/ThemeService.dart';
import 'package:discipline_mind/common/app_colors.dart';
import 'package:discipline_mind/common/common.dart';
import 'package:discipline_mind/ui/main_home/alert_main.dart';
import 'package:discipline_mind/ui/main_home/process_detail_screen.dart';
import 'package:discipline_mind/services/app_url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

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
                  subtitle: 'View and update your active trading rules & limits',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ProcessDetailScreen(),
                    ),
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
      onTap: onTap,
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

