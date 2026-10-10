import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:discipline_mind/controller/auth_controller.dart';
import 'package:discipline_mind/services/notification/notification_handler.dart';
import 'package:discipline_mind/services/trading_apps_service.dart';
import 'package:discipline_mind/ui/auth/phone_login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  final AuthController authController = Get.isRegistered<AuthController>()
      ? Get.find<AuthController>()
      : Get.put(AuthController());
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  bool _hasNavigated = false;

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
      try {
        Get.find<TradingAppsService>().refresh();
      } catch (_) {}

      // Minimum splash duration
      Future.delayed(const Duration(milliseconds: 2500), () {
        _triggerNavigation();
      });

      // Safety fallback: if app hasn't transitioned by 4.5 seconds, force route to login
      Future.delayed(const Duration(milliseconds: 4500), () {
        if (!_hasNavigated && mounted) {
          debugPrint('[SplashScreen] Safety fallback timer triggered');
          _hasNavigated = true;
          Get.offAll(() => PhoneLoginScreen());
        }
      });
    });
  }

  void _triggerNavigation() async {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;
    try {
      await authController.autoLogin();
    } catch (e) {
      debugPrint('[SplashScreen] Navigation error: $e');
      if (mounted) {
        Get.offAll(() => PhoneLoginScreen());
      }
    }
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
              child: Image.asset("assets/logo.jpg", height: 100),
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