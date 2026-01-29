import 'dart:io';

import 'package:block_app/block_app.dart' show BlockApp, AppBlockConfig;
import 'package:discipline_mind/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';

import 'ui/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Platform.isAndroid
      ? await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        )
      : await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
  final BlockApp blockApp = BlockApp();

  await blockApp.initialize(
    config: const AppBlockConfig(
      defaultMessage: 'This app has been blocked for productivity',
      overlayBackgroundColor: Colors.black87,
      overlayTextColor: Colors.white,
      actionButtonText: 'Close',
      autoStartService: true, // starts overlay service immediately
    ),
  );
  await GetStorage.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    FToast fToast;
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

        // 🌟 APP BAR WHITE
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent, // IMPORTANT for Material 3
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
        textTheme: GoogleFonts.nunitoTextTheme(Theme.of(context).textTheme),
      ),
      builder: (context, child) {
        fToast = FToast();
        // if you want to use context from globally instead of content we need to pass navigatorKey.currentContext!
        fToast.init(context);
        return child!;
      },
      home: SplashScreen(),
    );
  }
}
