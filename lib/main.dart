import 'dart:async';
import 'dart:io';

import 'package:discipline_mind/common/common.dart';
import 'package:discipline_mind/controller/alert_controller.dart';
import 'package:discipline_mind/controller/chat_controller.dart';
import 'package:discipline_mind/firebase_options.dart';
import 'package:discipline_mind/services/app_data_refresh_service.dart';
import 'package:discipline_mind/services/notification/notification_handler.dart';
import 'package:discipline_mind/services/trading_block_bootstrap.dart';
import 'package:discipline_mind/ui/onboarding/post_login_trading_block_screen.dart';
import 'package:discipline_mind/ui/android_app_block/blocked_app_overlay_page.dart';
import 'package:discipline_mind/ui/main_home/main_home.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';

import 'ui/splash_screen.dart';
import 'ui/version_selector_screen.dart';

void _onAppResumed() {
  if (!Platform.isAndroid) return;
  try {
    const MethodChannel('com.discipline_mind/app_lifecycle')
        .invokeMethod<void>('hideBlockOverlay');
  } catch (_) {}
}

/// Logged-in Android users cannot use the app without overlay + usage access.
Future<void> _enforceAndroidTradingPermissionsIfLoggedIn() async {
  if (!Platform.isAndroid) return;
  final uid = Common.userData.value?.payload?.id?.toString();
  if (uid == null || uid.isEmpty) return;
  if (await hasAndroidTradingBlockPermissions()) return;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    Get.offAll(() => const PostLoginTradingBlockScreen());
  });
}

void _refreshUserAlertsOnNotification({int attempt = 0}) {
  final userId = Common.userData.value?.payload?.id?.toString();
  // When app is opened from a killed state via notification, autoLogin may not
  // have restored the session yet. Retry briefly so the refresh still happens.
  if (userId == null || userId.isEmpty) {
    ChatController.markPendingSync();
    if (attempt < 6) {
      Future.delayed(Duration(milliseconds: 350 + attempt * 250), () {
        _refreshUserAlertsOnNotification(attempt: attempt + 1);
      });
    }
    return;
  }

  // Ensure controllers exist so refresh never no-ops.
  final alertController = Get.isRegistered<AlertController>()
      ? Get.find<AlertController>()
      : Get.put(AlertController(), permanent: true);
  final chatController = Get.isRegistered<ChatController>()
      ? Get.find<ChatController>()
      : Get.put(ChatController(), permanent: true);

  // If this notification was a DMT score or trade hit tap/open, ensure we land on Chat tab.
  final openChat = NotificationHandler.dmtScoreAutoOpenPending ||
      NotificationHandler.tradeHitAutoOpenPending;
  debugPrint(
    'FCM_NAV openChat=$openChat '
    'dmt=${NotificationHandler.dmtScoreAutoOpenPending} '
    'tradeHit=${NotificationHandler.tradeHitAutoOpenPending}',
  );
  if (openChat) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('FCM_NAV navigating to Chat tab (index 2)');
      Get.offAll(() => MainHomeScreen(initialIndex: 2));
    });
    if (NotificationHandler.tradeHitAutoOpenPending) {
      NotificationHandler.clearTradeHitAutoOpen();
    }
  }

  alertController.fetchUserAlerts(userId);
  // One coalesced sync — covers notification + any simultaneous resume call.
  unawaited(
    chatController.syncChat(reason: ChatSyncReason.notification, force: true),
  );
}

void _refreshChatOnAppResumed() {
  if (!Get.isRegistered<ChatController>()) {
    // Ensure controller exists so resume sync never no-ops after login.
    final userId = Common.userData.value?.payload?.id?.toString();
    if (userId == null || userId.isEmpty) return;
    Get.put(ChatController(), permanent: true);
  }
  // Every resume: one check for new messages (not notification-only).
  // Coalesce still prevents a duplicate if notification sync is already in-flight.
  unawaited(
    Get.find<ChatController>().syncChat(
      reason: ChatSyncReason.resume,
      force: true,
    ),
  );
}

/// After minimize → reopen: reload stale tab data and chat when online again.
void _refreshDataOnAppResumed() {
  final userId = Common.userData.value?.payload?.id?.toString();
  if (userId == null || userId.isEmpty) return;

  _refreshChatOnAppResumed();

  final refresh = Get.isRegistered<AppDataRefreshService>()
      ? Get.find<AppDataRefreshService>()
      : Get.put(AppDataRefreshService(), permanent: true);
  // Tabs only — chat already handled above (avoids double chat API).
  unawaited(refresh.refreshIfNeeded(force: true, includeChat: false));
}

bool _initialMessageCheckDone = false;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Surface errors in release (otherwise blank screen with no message)
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    if (kReleaseMode) {
      debugPrint('FlutterError: ${details.exception} ${details.stack}');
    }
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

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await GetStorage.init();
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    if (kDebugMode) debugPrint('Dotenv load warning: $e');
  }

  // Must be registered before runApp; background isolate only sets a pending flag.
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Do NOT start AppBlockingService here — MethodChannel is not ready before runApp().
  // Service is started from DisciplineApplication (native) + ensureAndroidTradingBlockRunning after login.

  // Register callback as early as possible so notification open events
  // (especially from killed state) don't miss the handler.
  NotificationHandler.onNotificationReceived = _refreshUserAlertsOnNotification;

  runApp(const MyApp());

  // Init notifications after first frame so release startup is not blocked
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
      _enforceAndroidTradingPermissionsIfLoggedIn();
      // Ensure block service is running after resume / first frame channel ready.
      unawaited(ensureAndroidTradingBlockRunning());
      _refreshDataOnAppResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Safe theme: Google Fonts can fail in release (font not found / load error)
    TextTheme textTheme;
    try {
      textTheme = GoogleFonts.nunitoTextTheme(Theme.of(context).textTheme);
    } catch (_) {
      textTheme = Theme.of(context).textTheme;
    }

    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Discipline Mind',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          background: Colors.white,
          surface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        useMaterial3: true,
        textTheme: textTheme,
      ),
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
      home: const AppVersionSelectorScreen(),
      // Route for native overlay when user opens a blocked app
      getPages: [
        GetPage(
          name: '/appBlockingOverlay',
          page: () => const BlockedAppOverlayPage(),
        ),
      ],
    );
  }
}
