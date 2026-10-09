import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:discipline_mind/common/ThemeService.dart';
import 'package:discipline_mind/common/app_colors.dart';
import 'package:discipline_mind/common/common.dart';
import 'package:discipline_mind/controller/alert_controller.dart';
import 'package:discipline_mind/controller/chat_controller.dart';
import 'package:discipline_mind/firebase_options.dart';
import 'package:discipline_mind/services/notification/notification_handler.dart';
import 'package:discipline_mind/services/native_app_block_service.dart';
import 'package:discipline_mind/services/trading_block_bootstrap.dart';
import 'package:discipline_mind/ui/onboarding/post_login_trading_block_screen.dart';
import 'package:discipline_mind/ui/android_app_block/blocked_app_overlay_page.dart';
import 'package:discipline_mind/ui/main_home/main_home.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';

import 'ui/splash_screen.dart';

/// Top-level background message handler for FCM
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
  } catch (_) {}
  if (kDebugMode) {
    debugPrint('FCM background message received: ${message.messageId}, data: ${message.data}');
  }

  // If message has no notification payload (e.g. data-only FCM payload sent by backend),
  // Android system will not show it automatically. We must display it via FlutterLocalNotificationsPlugin.
  if (message.notification == null && message.data.isNotEmpty) {
    try {
      final localNotifications = FlutterLocalNotificationsPlugin();
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidSettings);
      await localNotifications.initialize(initSettings);

      final data = message.data;
      final title = data['title']?.toString() ?? 'Zeno AI';
      final body = data['body']?.toString() ??
          data['message']?.toString() ??
          'You have a new alert update';

      final type = (data['type'] ?? data['notification_type'] ?? data['event'] ?? '').toString().toLowerCase();
      final isTradeOpportunity = type == 'new_trade_opportunity' || data['is_new_trade_opportunity']?.toString().toLowerCase() == 'true';
      final channelId = isTradeOpportunity ? 'zeno_ai_trade_opportunities' : 'zeno_ai_alerts';
      final channelName = isTradeOpportunity ? 'Trade Opportunities' : 'Price Alerts';

      await localNotifications.show(
        message.hashCode,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            channelName,
            channelDescription: 'Notifications for alerts and opportunities',
            importance: Importance.max,
            priority: Priority.max,
            icon: '@mipmap/ic_launcher',
            playSound: true,
            sound: isTradeOpportunity ? const RawResourceAndroidNotificationSound('trade_opportunity') : null,
          ),
        ),
        payload: jsonEncode(data),
      );
    } catch (e) {
      debugPrint('[FCM Background] Failed to show local notification: $e');
    }
  }
}

/// Top-level entrypoint for native overlay FlutterEngine
@pragma('vm:entry-point')
void mainOverlay() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isAndroid) {
    await GetStorage.init();
  }
  runApp(const OverlayApp());
}

class OverlayApp extends StatelessWidget {
  const OverlayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF7C3AED)),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const BlockedAppOverlayPage(),
    );
  }
}

void _onAppResumed() {
  if (!Platform.isAndroid) return;
  try {
    const MethodChannel(
      'com.discipline_mind/app_lifecycle',
    ).invokeMethod<void>('hideBlockOverlay');
  } catch (_) {}
  unawaited(checkAndStartTradingBlockIfPermitted());
}

void _refreshUserAlertsOnNotification({int attempt = 0}) {
  final userId = Common.userData.value?.payload?.id?.toString();
  if (userId == null || userId.isEmpty) {
    if (attempt < 6) {
      Future.delayed(Duration(milliseconds: 350 + attempt * 250), () {
        _refreshUserAlertsOnNotification(attempt: attempt + 1);
      });
    }
    return;
  }

  final alertController = Get.isRegistered<AlertController>()
      ? Get.find<AlertController>()
      : Get.put(AlertController(), permanent: true);
  final chatController = Get.isRegistered<ChatController>()
      ? Get.find<ChatController>()
      : Get.put(ChatController(), permanent: true);

  if (NotificationHandler.dmtScoreAutoOpenPending) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.offAll(() => MainHomeScreen(initialIndex: 2));
    });
    Future.delayed(const Duration(milliseconds: 350), () {
      chatController.loadNewMessages(silent: true);
    });
  }

  alertController.fetchUserAlerts(userId);
  chatController.loadNewMessages(silent: true);
}

void _showImmediateNotificationMessage(Map<String, dynamic> data) {
  _showImmediateNotificationMessageWithRetry(data);
}

void _showImmediateNotificationMessageWithRetry(
  Map<String, dynamic> data, {
  int attempt = 0,
}) {
  final type =
      (data['type'] ??
              data['notification_type'] ??
              data['event'] ??
              data['category'] ??
              '')
          .toString()
          .trim()
          .toLowerCase();
  if (type != 'mind_control_guard_deactivated') return;

  final userId = Common.userData.value?.payload?.id?.toString();
  if (userId == null || userId.isEmpty) {
    if (attempt < 6) {
      Future.delayed(Duration(milliseconds: 350 + attempt * 250), () {
        _showImmediateNotificationMessageWithRetry(data, attempt: attempt + 1);
      });
    }
    return;
  }

  final chatController = Get.isRegistered<ChatController>()
      ? Get.find<ChatController>()
      : Get.put(ChatController(), permanent: true);
  chatController.addMindControlGuardDeactivatedMessage(
    notificationKey: data['_notification_key']?.toString() ?? '',
    messageId:
        (data['message_id'] ??
                data['messageId'] ??
                data['id'] ??
                data['notification_id'] ??
                '')
            .toString(),
    timestamp: (data['timestamp'] ?? data['created_at'] ?? '').toString(),
  );
}

void _refreshChatOnAppResumed() {
  final userId = Common.userData.value?.payload?.id?.toString();
  if (userId == null || userId.isEmpty) return;
  if (!Get.isRegistered<ChatController>()) return;
  unawaited(Get.find<ChatController>().loadNewMessages(silent: true));
}

bool _initialMessageCheckDone = false;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    if (kReleaseMode) {
      debugPrint('FlutterError: ${details.exception} ${details.stack}');
    }
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  ErrorWidget.builder = (FlutterErrorDetails details) => Material(
    child: Container(
      color: Colors.white,
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: TextStyle(fontSize: 18, color: Colors.grey[800]),
              textAlign: TextAlign.center,
            ),
            if (kDebugMode) ...[
              const SizedBox(height: 12),
              Text(
                '${details.exception}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                textAlign: TextAlign.center,
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    ),
  );

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('Firebase.initializeApp warning/error: $e');
    }
  }

  try {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e) {
    if (kDebugMode) {
      debugPrint('FirebaseMessaging.onBackgroundMessage error: $e');
    }
  }

  await GetStorage.init();

  if (Platform.isAndroid) {
    final blockService = NativeAppBlockService();
    final blocked = await blockService.getBlockedApps();
    if (blocked.isNotEmpty) {
      await blockService.startBlockingService();
    }
    unawaited(checkAndStartTradingBlockIfPermitted());
  }

  NotificationHandler.onNotificationReceived = _refreshUserAlertsOnNotification;
  NotificationHandler.onNotificationDataReceived =
      _showImmediateNotificationMessage;

  runApp(const MyApp());

  WidgetsBinding.instance.addPostFrameCallback((_) async {
    try {
      await NotificationHandler.initialize();
    } catch (e) {
      if (kDebugMode) debugPrint('NotificationHandler init: $e');
    }
  });
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _onAppResumed();
      _refreshChatOnAppResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Safe Google Fonts fallback
    TextTheme textTheme;
    try {
      textTheme = GoogleFonts.nunitoTextTheme(Theme.of(context).textTheme);
    } catch (_) {
      textTheme = Theme.of(context).textTheme;
    }

    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Zeno AI',
      theme: _lightTheme(textTheme),
      darkTheme: _darkTheme(textTheme),
      themeMode: ThemeService().themeMode, // ← This enables theme switching
      builder: (context, child) {
        final fToast = FToast();
        fToast.init(context);
        if (!_initialMessageCheckDone) {
          _initialMessageCheckDone = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            NotificationHandler.onAppReady();
          });
        }
        return child!;
      },
      home: SplashScreen(),
      getPages: [
        GetPage(
          name: '/appBlockingOverlay',
          page: () => const BlockedAppOverlayPage(),
        ),
      ],
    );
  }

  ThemeData _lightTheme(TextTheme textTheme) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.lightBackground,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.lightSurface,
        foregroundColor: AppColors.lightTextPrimary,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.lightTextPrimary),
        titleTextStyle: TextStyle(
          color: AppColors.lightTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightSurface,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      textTheme: textTheme,
    );
  }

  ThemeData _darkTheme(TextTheme textTheme) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.darkTextPrimary,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.darkTextPrimary),
        titleTextStyle: TextStyle(
          color: AppColors.darkTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      textTheme: textTheme,
    );
  }
}
