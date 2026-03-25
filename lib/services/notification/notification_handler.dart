import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Handles FCM and local notifications: shows notification when app is open (foreground)
/// and triggers callback to refresh data (e.g. user alerts).
class NotificationHandler {
  NotificationHandler._();

  static final NotificationHandler _instance = NotificationHandler._();
  static NotificationHandler get instance => _instance;

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  bool _localInited = false;
  bool _firebaseInited = false;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'discipline_mind_alerts',
    'Price Alerts',
    description: 'Notifications for price alerts',
    importance: Importance.high,
    playSound: true,
  );

  /// Called when a notification is received (foreground, background tap, or opened from terminated).
  static void Function()? onNotificationReceived;

  /// Initialize FCM and local notifications. Call from main() after Firebase.initializeApp().
  static Future<void> initialize() async {
    final handler = instance;

    await handler._initLocalNotifications();
    await handler._initFirebaseMessaging();
    await handler._requestPermissions();
  }

  /// Call after first frame when Get/context is ready (e.g. for getInitialMessage).
  static void onAppReady() {
    instance._checkInitialMessage();
  }

  /// Request notification permission (FCM + Android 13+). Call from splash screen.
  static Future<void> requestPermissions() async {
    final handler = instance;
    // Ensure local notifications are initialized before asking Android runtime permission.
    await handler._initLocalNotifications();
    // Ensure FCM is ready as well (safe no-op if already initialized).
    await handler._initFirebaseMessaging();
    await handler._requestPermissions();
  }

  Future<void> _initLocalNotifications() async {
    if (_localInited) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestSoundPermission: true,
      requestBadgePermission: true,
    );
    const settings = InitializationSettings(android: android, iOS: darwin);

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    if (Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(_channel);
    }
    _localInited = true;
  }

  static void _onNotificationTapped(NotificationResponse response) {
    onNotificationReceived?.call();
  }

  Future<void> _initFirebaseMessaging() async {
    if (_firebaseInited) return;
    // Show notification when app is in foreground (Android: we show via local; iOS: system can show)
    if (Platform.isIOS) {
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
            alert: true,
            badge: true,
            sound: true,
          );
    }

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      onNotificationReceived?.call();
    });
    _firebaseInited = true;
  }

  /// When app is in foreground, FCM does not show system notification on Android — show local instead.
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    onNotificationReceived?.call();

    if (Platform.isAndroid) {
      final notification = message.notification;
      final title = notification?.title ?? 'Discipline Mind';
      final body = notification?.body ?? 'You have a new alert update';

      await _localNotifications.show(
        message.hashCode,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data.toString(),
      );
    }
  }

  Future<void> _requestPermissions() async {
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    debugPrint('FCM permission status: ${settings.authorizationStatus}');

    if (Platform.isAndroid) {
      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidPlugin == null) {
        debugPrint('Android notifications plugin is null');
        return;
      }

      final enabled = await androidPlugin.areNotificationsEnabled() ?? true;
      debugPrint('Notifications enabled before request: $enabled');

      if (!enabled) {
        final granted = await androidPlugin.requestNotificationsPermission();
        debugPrint('Android runtime permission result: $granted');
      }

      final enabledAfter =
          await androidPlugin.areNotificationsEnabled() ?? false;
      debugPrint('Notifications enabled after request: $enabledAfter');
    }
  }

  void _checkInitialMessage() {
    FirebaseMessaging.instance.getInitialMessage().then((
      RemoteMessage? message,
    ) {
      if (message != null) {
        onNotificationReceived?.call();
      }
    });
  }

  static const String tradeAlertsTopic = 'trade_alerts';

  /// Subscribe to trade_alerts topic. Call on login.
  static Future<void> subscribeToTradeAlerts() async {
    try {
      await FirebaseMessaging.instance.subscribeToTopic(tradeAlertsTopic);
    } catch (e) {
      if (kDebugMode) debugPrint('Subscribe to trade_alerts failed: $e');
    }
  }

  /// Unsubscribe from trade_alerts topic. Call on logout.
  static Future<void> unsubscribeFromTradeAlerts() async {
    try {
      await FirebaseMessaging.instance.unsubscribeFromTopic(tradeAlertsTopic);
    } catch (e) {
      if (kDebugMode) debugPrint('Unsubscribe from trade_alerts failed: $e');
    }
  }
}
