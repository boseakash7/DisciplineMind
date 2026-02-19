import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Handles FCM and local notifications: shows notification when app is open (foreground)
/// and triggers callback to refresh data (e.g. user alerts).
class NotificationHandler {
  NotificationHandler._();

  static final NotificationHandler _instance = NotificationHandler._();
  static NotificationHandler get instance => _instance;

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

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
    await instance._requestPermissions();
  }

  Future<void> _initLocalNotifications() async {
    const android = AndroidInitializationSettings('ic_launcher');
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestSoundPermission: true,
      requestBadgePermission: true,
    );
    const settings = InitializationSettings(
      android: android,
      iOS: darwin,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    if (Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);
    }
  }

  static void _onNotificationTapped(NotificationResponse response) {
    onNotificationReceived?.call();
  }

  Future<void> _initFirebaseMessaging() async {
    // Show notification when app is in foreground (Android: we show via local; iOS: system can show)
    if (Platform.isIOS) {
      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      onNotificationReceived?.call();
    });
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
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
  }

  void _checkInitialMessage() {
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        onNotificationReceived?.call();
      }
    });
  }
}
