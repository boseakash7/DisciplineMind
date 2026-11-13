// import 'dart:convert';
// import 'dart:io';

// import 'package:discipline_mind/common/common.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// /// Top-level background message handler required by Firebase for background & terminated state.
// @pragma('vm:entry-point')
// Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   try {
//     await Firebase.initializeApp();
//   } catch (_) {}
//   if (kDebugMode) {
//     debugPrint('🔥 [FCM Background] messageId=${message.messageId} data=${message.data}');
//   }
// }

// /// Handles FCM and local notifications: shows notification when app is open (foreground)
// /// and triggers callback to refresh data (e.g. user alerts).
// class NotificationHandler {
//   NotificationHandler._();

//   static final NotificationHandler _instance = NotificationHandler._();
//   static NotificationHandler get instance => _instance;

//   final FlutterLocalNotificationsPlugin _localNotifications =
//       FlutterLocalNotificationsPlugin();
//   bool _localInited = false;
//   bool _firebaseInited = false;

//   static const AndroidNotificationChannel _defaultChannel = AndroidNotificationChannel(
//     'zeno_ai_alerts',
//     'Price Alerts',
//     description: 'Notifications for price alerts',
//     importance: Importance.high,
//     playSound: true,
//   );
//   static const AndroidNotificationChannel _tradeOpportunityChannel =
//       AndroidNotificationChannel(
//         'zeno_ai_trade_opportunities',
//         'Trade Opportunities',
//         description: 'Notifications for new trade opportunities',
//         importance: Importance.high,
//         playSound: true,
//         sound: RawResourceAndroidNotificationSound('trade_opportunity'),
//       );

//   /// Called when a notification is received (foreground, background tap, or opened from terminated).
//   static void Function()? onNotificationReceived;

//   // Set when user taps a DMT score notification (or opens it from terminated state).
//   // ChatScreen reads this flag to auto-open the DMT score popup.
//   static bool _dmtScoreAutoOpenPending = false;
//   static String? _dmtScoreAutoOpenScoreDate;

//   static bool get dmtScoreAutoOpenPending => _dmtScoreAutoOpenPending;

//   static String? get dmtScoreAutoOpenScoreDate => _dmtScoreAutoOpenScoreDate;

//   static void clearDmtScoreAutoOpen() {
//     _dmtScoreAutoOpenPending = false;
//     _dmtScoreAutoOpenScoreDate = null;
//   }

//   static void _maybeMarkDmtScoreAutoOpen(Map<String, dynamic> data) {
//     final type = (data['type'] ??
//             data['notification_type'] ??
//             data['category'] ??
//             '')
//         .toString()
//         .toLowerCase();
//     if (type != 'dmt_score') return;
//     _dmtScoreAutoOpenPending = true;
//     _dmtScoreAutoOpenScoreDate =
//         data['score_date']?.toString() ?? data['scoreDate']?.toString();
//   }

//   /// Initialize FCM and local notifications. Call from main() after Firebase.initializeApp().
//   static Future<void> initialize() async {
//     final handler = instance;

//     await handler._initLocalNotifications();
//     await handler._initFirebaseMessaging();
//     await handler._requestPermissions();
//   }

//   /// Call after first frame when Get/context is ready (e.g. for getInitialMessage).
//   static void onAppReady() {
//     instance._checkInitialMessage();
//   }

//   /// Request notification permission (FCM + Android 13+). Call from splash screen.
//   static Future<void> requestPermissions() async {
//     final handler = instance;
//     // Ensure local notifications are initialized before asking Android runtime permission.
//     await handler._initLocalNotifications();
//     // Ensure FCM is ready as well (safe no-op if already initialized).
//     await handler._initFirebaseMessaging();
//     await handler._requestPermissions();
//   }

//   Future<void> _initLocalNotifications() async {
//     if (_localInited) return;
//     const android = AndroidInitializationSettings('@mipmap/ic_launcher');
//     const darwin = DarwinInitializationSettings(
//       requestAlertPermission: true,
//       requestSoundPermission: true,
//       requestBadgePermission: true,
//     );
//     const settings = InitializationSettings(android: android, iOS: darwin);

//     await _localNotifications.initialize(
//       settings,
//       onDidReceiveNotificationResponse: _onNotificationTapped,
//     );

//     if (Platform.isAndroid) {
//       await _localNotifications
//           .resolvePlatformSpecificImplementation<
//             AndroidFlutterLocalNotificationsPlugin
//           >()
//           ?.createNotificationChannel(_defaultChannel);
//       await _localNotifications
//           .resolvePlatformSpecificImplementation<
//             AndroidFlutterLocalNotificationsPlugin
//           >()
//           ?.createNotificationChannel(_tradeOpportunityChannel);
//     }
//     _localInited = true;
//   }

//   static void _onNotificationTapped(NotificationResponse response) {
//     // Local notifications provide the payload on tap.
//     try {
//       final payload = response.payload;
//       if (payload != null && payload.isNotEmpty) {
//         final decoded = jsonDecode(payload);
//         if (decoded is Map) {
//           _maybeMarkDmtScoreAutoOpen(
//             decoded.map((k, v) => MapEntry(k.toString(), v)),
//           );
//         }
//       }
//     } catch (_) {
//       // Ignore payload parse issues.
//     }
//     onNotificationReceived?.call();
//   }

//   Future<void> _initFirebaseMessaging() async {
//     if (_firebaseInited) return;
//     // Show notification when app is in foreground (Android: we show via local; iOS: system can show)
//     if (Platform.isIOS) {
//       await FirebaseMessaging.instance
//           .setForegroundNotificationPresentationOptions(
//             alert: true,
//             badge: true,
//             sound: true,
//           );
//     }

//     // Set background handler
//     FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

//     FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
//     FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
//       _logNotificationData(source: 'onMessageOpenedApp', message: message);
//       _maybeMarkDmtScoreAutoOpen(message.data);
//       onNotificationReceived?.call();
//     });

//     FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
//       debugPrint('🔥 [NotificationHandler] onTokenRefresh: $newToken');
//       Common.fcmToken = newToken;
//       await Common.syncFcmTokenToServer(newToken);
//     });

//     _firebaseInited = true;
//   }

//   /// When app is in foreground, ensure notifications are displayed as banners on both iOS and Android.
//   Future<void> _handleForegroundMessage(RemoteMessage message) async {
//     _logNotificationData(source: 'onMessage', message: message);
//     onNotificationReceived?.call();

//     final notification = message.notification;
//     final data = message.data;
//     final title = notification?.title ?? data['title']?.toString() ?? 'Zeno AI';
//     final body = notification?.body ??
//         data['body']?.toString() ??
//         data['message']?.toString() ??
//         'You have a new alert update';

//     final shouldShowLocal = Platform.isAndroid || (Platform.isIOS && notification == null);

//     if (shouldShowLocal) {
//       final isTradeOpportunity = _isNewTradeOpportunity(message);
//       final channel = isTradeOpportunity
//           ? _tradeOpportunityChannel
//           : _defaultChannel;

//       await _localNotifications.show(
//         message.hashCode,
//         title,
//         body,
//         NotificationDetails(
//           android: AndroidNotificationDetails(
//             channel.id,
//             channel.name,
//             channelDescription: channel.description,
//             importance: Importance.high,
//             priority: Priority.high,
//             icon: '@mipmap/ic_launcher',
//             playSound: true,
//             sound: isTradeOpportunity
//                 ? const RawResourceAndroidNotificationSound(
//                     'trade_opportunity',
//                   )
//                 : null,
//           ),
//           iOS: const DarwinNotificationDetails(
//             presentAlert: true,
//             presentBadge: true,
//             presentSound: true,
//           ),
//         ),
//         payload: jsonEncode(message.data),
//       );
//     }
//   }

//   bool _isNewTradeOpportunity(RemoteMessage message) {
//     final data = message.data;
//     final type =
//         (data['type'] ??
//                 data['notification_type'] ??
//                 data['event'] ??
//                 data['category'] ??
//                 '')
//             .toString()
//             .toLowerCase();
//     final isTradeFlag =
//         data['is_new_trade_opportunity']?.toString().toLowerCase();

//     return type == 'new_trade_opportunity' || isTradeFlag == 'true';
//   }

//   void _logNotificationData({
//     required String source,
//     required RemoteMessage message,
//   }) {
//     if (!kDebugMode) return;
//     final isTrade = _isNewTradeOpportunity(message);
//     debugPrint(
//       'FCM[$source] messageId=${message.messageId} '
//       'title=${message.notification?.title} '
//       'body=${message.notification?.body} '
//       'isTradeOpportunity=$isTrade '
//       'data=${message.data}',
//     );
//   }

//   /// Request iOS notification permission and generate/fetch APNs token with safe retries
//   static Future<String?> requestAndGetApnsToken() async {
//     if (!Platform.isIOS) return null;
//     try {
//       final settings = await FirebaseMessaging.instance.requestPermission(
//         alert: true,
//         badge: true,
//         sound: true,
//       );
//       if (settings.authorizationStatus == AuthorizationStatus.authorized ||
//           settings.authorizationStatus == AuthorizationStatus.provisional) {
//         String? apnsToken;
//         for (var i = 0; i < 15; i++) {
//           apnsToken = await FirebaseMessaging.instance.getAPNSToken();
//           if (apnsToken != null && apnsToken.isNotEmpty) break;
//           await Future.delayed(const Duration(milliseconds: 800));
//         }
//         if (apnsToken != null && apnsToken.isNotEmpty) {
//           debugPrint('========================================');
//           debugPrint('🔥 [NotificationHandler] APNs Token: $apnsToken');
//           debugPrint('========================================');
//         }
//         return apnsToken;
//       }
//     } catch (e) {
//       debugPrint('[NotificationHandler] requestAndGetApnsToken error: $e');
//     }
//     return null;
//   }

//   Future<void> _requestPermissions() async {
//     final settings = await FirebaseMessaging.instance.requestPermission(
//       alert: true,
//       badge: true,
//       sound: true,
//     );

//     debugPrint('FCM permission status: ${settings.authorizationStatus}');

//     if (Platform.isIOS) {
//       await _localNotifications
//           .resolvePlatformSpecificImplementation<
//             IOSFlutterLocalNotificationsPlugin
//           >()
//           ?.requestPermissions(
//             alert: true,
//             badge: true,
//             sound: true,
//           );
//       final apns = await NotificationHandler.requestAndGetApnsToken();
//       if (apns != null && apns.isNotEmpty) {
//         await Common.getFcmToken();
//       } else {
//         await Common.getFcmToken();
//       }
//     }

//     if (Platform.isAndroid) {
//       final androidPlugin = _localNotifications
//           .resolvePlatformSpecificImplementation<
//             AndroidFlutterLocalNotificationsPlugin
//           >();

//       if (androidPlugin != null) {
//         final enabled = await androidPlugin.areNotificationsEnabled() ?? true;
//         if (!enabled) {
//           await androidPlugin.requestNotificationsPermission();
//         }
//       }
//       await Common.getFcmToken();
//     }
//   }

//   void _checkInitialMessage() {
//     FirebaseMessaging.instance.getInitialMessage().then((
//       RemoteMessage? message,
//     ) {
//       if (message != null) {
//         _logNotificationData(source: 'getInitialMessage', message: message);
//         _maybeMarkDmtScoreAutoOpen(message.data);
//         onNotificationReceived?.call();
//       
//     });
//   }

//   static const String tradeAlertsTopic = 'trade_alerts';
//   static const String dmtScoreTopic = 'dmt_score';

//   /// Subscribe to FCM topics. Call on login.
//   static Future<void> subscribeToTradeAlerts() async {
//     try {
//       await FirebaseMessaging.instance.subscribeToTopic(tradeAlertsTopic);
//       await FirebaseMessaging.instance.subscribeToTopic(dmtScoreTopic);
//       if (kDebugMode) {
//         debugPrint('Subscribed to FCM topics: $tradeAlertsTopic, $dmtScoreTopic');
//       }
//     } catch (e) {
//       if (kDebugMode) debugPrint('Subscribe to FCM topics failed: $e');
//     }
//   }

//   /// Unsubscribe from FCM topics. Call on logout.
//   static Future<void> unsubscribeFromTradeAlerts() async {
//     try {
//       await FirebaseMessaging.instance.unsubscribeFromTopic(tradeAlertsTopic);
//       await FirebaseMessaging.instance.unsubscribeFromTopic(dmtScoreTopic);
//       if (kDebugMode) {
//         debugPrint(
//           'Unsubscribed from FCM topics: $tradeAlertsTopic, $dmtScoreTopic',
//         );
//       }
//     } catch (e) {
//       if (kDebugMode) debugPrint('Unsubscribe from FCM topics failed: $e');
//     }
//   }
// }


import 'dart:convert';
import 'dart:io';
 
import 'package:discipline_mind/common/common.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
 
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  await Firebase.initializeApp();
  debugPrint('Background FCM: ${message.messageId}');
}
 
class NotificationHandler {
  NotificationHandler._();
 
  static final NotificationHandler instance =
      NotificationHandler._();
 
  final FirebaseMessaging _messaging =
      FirebaseMessaging.instance;
 
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
 
  bool _localInited = false;
  bool _firebaseInited = false;
 
  static void Function()? onNotificationReceived;
 
  static bool _dmtScoreAutoOpenPending = false;
  static String? _dmtScoreAutoOpenScoreDate;
 
  static bool get dmtScoreAutoOpenPending =>
      _dmtScoreAutoOpenPending;
 
  static String? get dmtScoreAutoOpenScoreDate =>
      _dmtScoreAutoOpenScoreDate;
 
  static void clearDmtScoreAutoOpen() {
    _dmtScoreAutoOpenPending = false;
    _dmtScoreAutoOpenScoreDate = null;
  }
 
  static void _markDmtScore(Map<String, dynamic> data) {
    final type = (data['type'] ??
            data['notification_type'] ??
            data['category'] ??
            '')
        .toString()
        .toLowerCase();
 
    if (type != 'dmt_score') return;
 
    _dmtScoreAutoOpenPending = true;
    _dmtScoreAutoOpenScoreDate =
        data['score_date']?.toString() ??
        data['scoreDate']?.toString();
  }
 
  static const AndroidNotificationChannel _defaultChannel =
      AndroidNotificationChannel(
    'zeno_ai_alerts',
    'Price Alerts',
    description: 'Notifications for price alerts',
    importance: Importance.high,
    playSound: true,
  );
 
  static const AndroidNotificationChannel
      _tradeOpportunityChannel =
      AndroidNotificationChannel(
    'zeno_ai_trade_opportunities',
    'Trade Opportunities',
    description: 'Notifications for new trade opportunities',
    importance: Importance.high,
    playSound: true,
    sound: RawResourceAndroidNotificationSound(
      'trade_opportunity',
    ),
  );
 
  static const String tradeAlertsTopic = 'trade_alerts';
  static const String dmtScoreTopic = 'dmt_score';
 
  static Future<void> initialize() async {
    final handler = instance;
 
    await handler._initLocalNotifications();
    await handler._initFirebaseMessaging();
    await handler._requestPermissions();
  }
 
  static Future<void> requestPermissions() async {
    final handler = instance;
    await handler._initLocalNotifications();
    await handler._initFirebaseMessaging();
    await handler._requestPermissions();
  }
 
  Future<void> _initLocalNotifications() async {
    if (_localInited) return;
 
    const android = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
 
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
 
    await _local.initialize(
      const InitializationSettings(
        android: android,
        iOS: ios,
      ),
      onDidReceiveNotificationResponse:
          _onLocalNotificationTapped,
    );
 
    if (Platform.isAndroid) {
      final plugin = _local
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
 
      await plugin?.createNotificationChannel(
        _defaultChannel,
      );
 
      await plugin?.createNotificationChannel(
        _tradeOpportunityChannel,
      );
    }
 
    _localInited = true;
  }
 
  static void _onLocalNotificationTapped(
    NotificationResponse response,
  ) {
    try {
      final payload = response.payload;
 
      if (payload != null && payload.isNotEmpty) {
        final decoded = jsonDecode(payload);
 
        if (decoded is Map) {
          _markDmtScore(
            Map<String, dynamic>.from(decoded),
          );
        }
      }
    } catch (e) {
      debugPrint('Notification tap error: $e');
    }
 
    onNotificationReceived?.call();
  }
 
  Future<void> _initFirebaseMessaging() async {
    if (_firebaseInited) return;
 
    if (Platform.isIOS) {
      await _messaging
          .setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
 
    FirebaseMessaging.onMessage.listen(
      _handleForegroundMessage,
    );
 
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint(
        'Notification opened: ${message.data}',
      );
 
      _markDmtScore(message.data);
      onNotificationReceived?.call();
    });
 
    _messaging.onTokenRefresh.listen((token) async {
      debugPrint('FCM token refreshed');
 
      await _syncFcmToken(token);
    });
 
    _firebaseInited = true;
  }
 
  Future<void> _requestPermissions() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
 
    debugPrint(
      'Notification permission: '
      '${settings.authorizationStatus}',
    );
 
    if (Platform.isAndroid) {
      final plugin = _local
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
 
      await plugin?.requestNotificationsPermission();
 
      await refreshFcmToken();
      return;
    }
 
    if (Platform.isIOS) {
      if (settings.authorizationStatus ==
              AuthorizationStatus.authorized ||
          settings.authorizationStatus ==
              AuthorizationStatus.provisional) {
        await refreshFcmToken();
      }
    }
  }
 
  Future<String?> _waitForApnsToken() async {
    if (!Platform.isIOS) return null;
 
    for (int attempt = 0; attempt < 20; attempt++) {
      try {
        final token = await _messaging.getAPNSToken();
 
        if (token != null && token.isNotEmpty) {
          debugPrint('APNs token available');
          return token;
        }
      } catch (e) {
        debugPrint('APNs error: $e');
      }
 
      await Future.delayed(
        const Duration(seconds: 1),
      );
    }
 
    debugPrint('APNs token not available');
    return null;
  }
 
  static Future<String?> requestAndGetApnsToken() async {
    return instance._waitForApnsToken();
  }
 
  Future<void> refreshFcmToken() async {
    try {
      if (Platform.isIOS) {
        final apns = await _waitForApnsToken();
 
        if (apns == null) {
          debugPrint(
            'iOS APNs missing. Check push capabilities.',
          );
          return;
        }
      }
 
      final token = await _messaging.getToken();
 
      if (token == null || token.isEmpty) {
        debugPrint('FCM token unavailable');
        return;
      }
 
      debugPrint('FCM token available');
      await _syncFcmToken(token);
    } catch (e) {
      debugPrint('FCM token error: $e');
    }
  }
 
  Future<void> _syncFcmToken(String token) async {
    try {
      Common.fcmToken = token;
      await Common.syncFcmTokenToServer(token);
 
      debugPrint('FCM token sync method completed');
    } catch (e) {
      debugPrint('FCM token sync error: $e');
    }
  }
 
  Future<void> _handleForegroundMessage(
    RemoteMessage message,
  ) async {
    debugPrint(
      'Foreground notification: ${message.data}',
    );
 
    onNotificationReceived?.call();
 
    final notification = message.notification;
    final data = message.data;
 
    // iOS automatically presents notification payloads
    // using the foreground presentation options.
    // Avoid duplicate local notifications.
    if (Platform.isIOS && notification != null) {
      return;
    }
 
    final title =
        notification?.title ??
        data['title']?.toString() ??
        'Zeno AI';
 
    final body =
        notification?.body ??
        data['body']?.toString() ??
        data['message']?.toString() ??
        'You have a new alert';
 
    final isTrade = _isTradeOpportunity(message);
 
    final channel = isTrade
        ? _tradeOpportunityChannel
        : _defaultChannel;
 
    await _local.show(
      DateTime.now()
          .millisecondsSinceEpoch
          .remainder(2147483647),
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          playSound: true,
          sound: isTrade
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
      payload: jsonEncode(data),
    );
  }
 
  bool _isTradeOpportunity(RemoteMessage message) {
    final data = message.data;
 
    final type = (data['type'] ??
            data['notification_type'] ??
            data['event'] ??
            data['category'] ??
            '')
        .toString()
        .toLowerCase();
 
    final flag = data['is_new_trade_opportunity']
        ?.toString()
        .toLowerCase();
 
    return type == 'new_trade_opportunity' ||
        flag == 'true';
  }
 
  static void onAppReady() {
    FirebaseMessaging.instance
        .getInitialMessage()
        .then((message) {
      if (message == null) return;
 
      _markDmtScore(message.data);
      onNotificationReceived?.call();
    });
  }
 
  static Future<void> subscribeToTradeAlerts() async {
    try {
      await FirebaseMessaging.instance
          .subscribeToTopic(tradeAlertsTopic);
 
      await FirebaseMessaging.instance
          .subscribeToTopic(dmtScoreTopic);
 
      debugPrint('FCM topics subscribed');
    } catch (e) {
      debugPrint('FCM topic subscription error: $e');
    }
  }
 
  static Future<void> unsubscribeFromTradeAlerts() async {
    try {
      await FirebaseMessaging.instance
          .unsubscribeFromTopic(tradeAlertsTopic);
 
      await FirebaseMessaging.instance
          .unsubscribeFromTopic(dmtScoreTopic);
 
      debugPrint('FCM topics unsubscribed');
    } catch (e) {
      debugPrint('FCM unsubscribe error: $e');
    }
  }
}
