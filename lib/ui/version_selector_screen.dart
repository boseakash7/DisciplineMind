import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../common/app_colors.dart';
import '../v2/common/v2_app_colors.dart';
import '../v2/ui/splash/v2_splash_screen.dart';
import 'splash_screen.dart';

class AppVersionSelectorScreen extends StatelessWidget {
  const AppVersionSelectorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 30),
              // App Logo / Avatar
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, Color(0xFF0288D1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.psychology,
                  size: 48,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                "Disciplined Minds",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Select which engine version you want to launch",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 36),

              // Option 1: Old Version (v1)
              _buildVersionCard(
                context: context,
                versionTag: "VERSION 1 (CLASSIC)",
                title: "Old Version",
                subtitle: "Original backend APIs, trading blocks, alerts and chat.",
                badgeColor: Colors.grey.shade700,
                icon: Icons.history_toggle_off_rounded,
                accentColor: const Color(0xFF4A5568),
                onTap: () {
                  Get.to(() => const SplashScreen());
                },
              ),

              const SizedBox(height: 20),

              // Option 2: ZENO AI (v2 Test)
              _buildVersionCard(
                context: context,
                versionTag: "ZENO AI (V2 ENGINE)",
                title: "ZENO AI",
                subtitle: "New intelligent backend with Multi-Auth, Phone OTP & fast APIs.",
                badgeColor: V2AppColors.primaryDark,
                icon: Icons.auto_awesome_rounded,
                accentColor: V2AppColors.primary,
                isRecommended: true,
                onTap: () {
                  Get.to(() => const V2SplashScreen());
                },
              ),

              const Spacer(),
              const Text(
                "You can switch between versions anytime.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVersionCard({
    required BuildContext context,
    required String versionTag,
    required String title,
    required String subtitle,
    required Color badgeColor,
    required IconData icon,
    required Color accentColor,
    bool isRecommended = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isRecommended ? const Color(0xFFF5F3FF) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isRecommended ? V2AppColors.primary.withValues(alpha: 0.6) : const Color(0xFFE2E8F0),
            width: isRecommended ? 1.8 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isRecommended
                  ? V2AppColors.primary.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.03),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isRecommended
                    ? V2AppColors.primary.withValues(alpha: 0.15)
                    : const Color(0xFFE2E8F0),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: accentColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          versionTag,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: badgeColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      if (isRecommended) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDE9FE),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: V2AppColors.primary.withValues(alpha: 0.4)),
                          ),
                          child: const Text(
                            "NEW",
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: V2AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF94A3B8),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
