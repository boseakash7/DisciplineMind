import 'dart:convert';
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

  static const AndroidNotificationChannel _defaultChannel = AndroidNotificationChannel(
    'discipline_mind_alerts',
    'Price Alerts',
    description: 'Notifications for price alerts',
    importance: Importance.high,
    playSound: true,
  );
  static const AndroidNotificationChannel _tradeOpportunityChannel =
      AndroidNotificationChannel(
        'discipline_mind_trade_opportunities',
        'Trade Opportunities',
        description: 'Notifications for new trade opportunities',
        importance: Importance.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('trade_opportunity'),
      );

  /// Called when a notification is received (foreground, background tap, or opened from terminated).
  static void Function()? onNotificationReceived;

  // Set when user taps a DMT score notification (or opens it from terminated state).
  // ChatScreen reads this flag to auto-open the DMT score popup.
  static bool _dmtScoreAutoOpenPending = false;
  static String? _dmtScoreAutoOpenScoreDate;

  static bool get dmtScoreAutoOpenPending => _dmtScoreAutoOpenPending;

  static String? get dmtScoreAutoOpenScoreDate => _dmtScoreAutoOpenScoreDate;

  static void clearDmtScoreAutoOpen() {
    _dmtScoreAutoOpenPending = false;
    _dmtScoreAutoOpenScoreDate = null;
  }

  static void _maybeMarkDmtScoreAutoOpen(Map<String, dynamic> data) {
    final type = (data['type'] ??
            data['notification_type'] ??
            data['category'] ??
            '')
        .toString()
        .toLowerCase();
    if (type != 'dmt_score') return;
    _dmtScoreAutoOpenPending = true;
    _dmtScoreAutoOpenScoreDate =
        data['score_date']?.toString() ?? data['scoreDate']?.toString();
  }

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
          ?.createNotificationChannel(_defaultChannel);
      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(_tradeOpportunityChannel);
    }
    _localInited = true;
  }

  static void _onNotificationTapped(NotificationResponse response) {
    // Local notifications provide the payload on tap.
    try {
      final payload = response.payload;
      if (payload != null && payload.isNotEmpty) {
        final decoded = jsonDecode(payload);
        if (decoded is Map) {
          _maybeMarkDmtScoreAutoOpen(
            decoded.map((k, v) => MapEntry(k.toString(), v)),
          );
        }
      }
    } catch (_) {
      // Ignore payload parse issues.
    }
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
      _logNotificationData(source: 'onMessageOpenedApp', message: message);
      _maybeMarkDmtScoreAutoOpen(message.data);
      onNotificationReceived?.call();
    });
    _firebaseInited = true;
  }

  /// When app is in foreground, FCM does not show system notification on Android — show local instead.
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    _logNotificationData(source: 'onMessage', message: message);
    onNotificationReceived?.call();

    if (Platform.isAndroid) {
      final notification = message.notification;
      final title = notification?.title ?? 'Monkk AI';
      final body = notification?.body ?? 'You have a new alert update';
      final isTradeOpportunity = _isNewTradeOpportunity(message);
      final channel = isTradeOpportunity
          ? _tradeOpportunityChannel
          : _defaultChannel;

      await _localNotifications.show(
        message.hashCode,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            sound: isTradeOpportunity
                ? const RawResourceAndroidNotificationSound(
                    'trade_opportunity',
                  )
                : null,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: jsonEncode(message.data),
      );
    }
  }

  bool _isNewTradeOpportunity(RemoteMessage message) {
    final data = message.data;
    final type =
        (data['type'] ??
                data['notification_type'] ??
                data['event'] ??
                data['category'] ??
                '')
            .toString()
            .toLowerCase();
    final isTradeFlag =
        data['is_new_trade_opportunity']?.toString().toLowerCase();

    return type == 'new_trade_opportunity' || isTradeFlag == 'true';
  }

  void _logNotificationData({
    required String source,
    required RemoteMessage message,
  }) {
    if (!kDebugMode) return;
    final isTrade = _isNewTradeOpportunity(message);
    debugPrint(
      'FCM[$source] messageId=${message.messageId} '
      'title=${message.notification?.title} '
      'body=${message.notification?.body} '
      'isTradeOpportunity=$isTrade '
      'data=${message.data}',
    );
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
        _logNotificationData(source: 'getInitialMessage', message: message);
        _maybeMarkDmtScoreAutoOpen(message.data);
        onNotificationReceived?.call();
      }
    });
  }

  static const String tradeAlertsTopic = 'trade_alerts';
  static const String dmtScoreTopic = 'dmt_score';

  /// Subscribe to FCM topics. Call on login.
  static Future<void> subscribeToTradeAlerts() async {
    try {
      await FirebaseMessaging.instance.subscribeToTopic(tradeAlertsTopic);
      await FirebaseMessaging.instance.subscribeToTopic(dmtScoreTopic);
      if (kDebugMode) {
        debugPrint('Subscribed to FCM topics: $tradeAlertsTopic, $dmtScoreTopic');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Subscribe to FCM topics failed: $e');
    }
  }

  /// Unsubscribe from FCM topics. Call on logout.
  static Future<void> unsubscribeFromTradeAlerts() async {
    try {
      await FirebaseMessaging.instance.unsubscribeFromTopic(tradeAlertsTopic);
      await FirebaseMessaging.instance.unsubscribeFromTopic(dmtScoreTopic);
      if (kDebugMode) {
        debugPrint(
          'Unsubscribed from FCM topics: $tradeAlertsTopic, $dmtScoreTopic',
        );
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Unsubscribe from FCM topics failed: $e');
    }
  }
}
