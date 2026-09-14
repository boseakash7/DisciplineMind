import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

import 'ui/android_app_block/blocked_app_overlay_page.dart';

/// Minimal entrypoint for overlay engine - no Firebase, GetX, or SplashScreen.
/// Shows only BlockedAppOverlayPage for fast, reliable overlay display.
@pragma('vm:entry-point')
void main() async {
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
