// import 'package:app_limiter/app_limiter.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class IOSBlockService {
//   static const _ytKey = 'ios_youtube_blocked';
//   final AppLimiter _limiter = AppLimiter();

//   /// Request Screen Time permission
//   Future<bool> requestPermission() async {
//     return await _limiter.requestIosPermission();
//   }

//   /// Toggle app blocking (Apple handles app selection UI)
//   Future<void> toggleBlock() async {
//     await _limiter.blockAndUnblockIOSApp();
//     final prefs = await SharedPreferences.getInstance();
//     final current = prefs.getBool(_ytKey) ?? false;
//     await prefs.setBool(_ytKey, !current);
//   }

//   Future<bool> isBlocked() async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.getBool(_ytKey) ?? false;
//   }
// }
