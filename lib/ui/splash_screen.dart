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

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  final AuthController authController = Get.put(AuthController());
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Animation Setup
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _scaleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );

    _animationController.forward();

    // App initialization with delay
    if (!Get.isRegistered<TradingAppsService>()) {
      Get.put(TradingAppsService(), permanent: true);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestNotificationPermission();
      Get.find<TradingAppsService>().refresh();

      // Minimum splash duration
      Future.delayed(const Duration(milliseconds: 2500), () {
        if (mounted) {
          authController.autoLogin();
        }
      });
    });
  }

  Future<void> _requestNotificationPermission() async {
    try {
      await NotificationHandler.requestPermissions();
    } catch (e) {
      debugPrint('Permission request failed: $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated Logo
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: child,
                  ),
                );
              },
              child: Image.asset(
                "assets/logo.png",
                height: 100,
              ),
            ),

            const SizedBox(height: 20),

            // Text(
            //   "Discipline Mind",
            //   style: theme.textTheme.headlineMedium?.copyWith(
            //     fontWeight: FontWeight.bold,
            //     color: isDark ? Colors.white : AppColors.textBlack,
            //   ),
            // ),

            // const SizedBox(height: 8),

            // Text(
            //   "Stay Focused. Stay Strong.",
            //   style: theme.textTheme.bodyMedium?.copyWith(
            //     color: isDark ? Colors.white70 : AppColors.textGrey,
            //   ),
            // ),

            // const SizedBox(height: 40),
Image.asset("assets/dotgif.gif",height: 100,color: theme.primaryColor,),
            // CircularProgressIndicator(
            //   color: theme.primaryColor,
            // ),
          ],
        ),
      ),
    );
  }
}