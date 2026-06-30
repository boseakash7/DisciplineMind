import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../common/app_colors.dart';
import '../../controller/auth_controller.dart';
import '../../services/notification/notification_handler.dart';
import '../../services/trading_apps_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthController authController = Get.put(AuthController());

  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<TradingAppsService>()) {
      Get.put(TradingAppsService(), permanent: true);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestNotificationPermission();
      // Start auth immediately; avoids extra splash delay.
      authController.autoLogin();
      Get.find<TradingAppsService>().refresh();
    });
  }

  Future<void> _requestNotificationPermission() async {
    try {
      await NotificationHandler.requestPermissions();
    } catch (e, s) {
      debugPrint('Permission request failed: $e');
      debugPrintStack(stackTrace: s);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset("assets/logo.png",height: 100),
            const SizedBox(height: 20),

            const Text(
              "Monkk AI",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppColors.textBlack,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              "Stay Focused. Stay Strong.",
              style: TextStyle(fontSize: 14, color: AppColors.textGrey),
            ),

            const SizedBox(height: 40),

            const CircularProgressIndicator(color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
