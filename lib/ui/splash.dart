// import 'dart:io';

// import 'package:block_app/block_app.dart';
// import 'package:discipline_mind/ui/ios/ios_splash_handler.dart';
// import 'package:discipline_mind/ui/android_app_block/permisson_get_page.dart';
// import 'package:flutter/material.dart';

// import 'android_app_block/app_block_page.dart';

// class SplashScreen extends StatefulWidget {
//   const SplashScreen({super.key});

//   @override
//   State<SplashScreen> createState() => _SplashScreenState();
// }

// class _SplashScreenState extends State<SplashScreen> {
//   final BlockApp _blockApp = BlockApp();

//   @override
//   void initState() {
//     super.initState();
//     _start();
//   }

//   Future<void> _start() async {
//     await Future.delayed(const Duration(seconds: 1));

//     if (!mounted) return;

//     /// ---------------- ANDROID ----------------
//     if (Platform.isAndroid) {
//       final permissions = await _blockApp.checkPermissions();

//       final hasPermissions =
//           (permissions['hasOverlayPermission'] ?? false) &&
//           (permissions['hasUsageStatsPermission'] ?? false);

//       if (!mounted) return;

//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(
//           builder: (_) => hasPermissions
//               ? const AppBlockPage()
//               : const PermissionGatePage(),
//         ),
//       );
//       return;
//     }
//     if (Platform.isIOS) {
//       if (Platform.isIOS) {
//         // await IOSSplashHandler.navigate(context);
//         return;
//       }

//       // Navigator.pushReplacement(
//       //   context,
//       //   MaterialPageRoute(builder: (_) => const AppBlockPage()),
//       // );
//       return;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return const Scaffold(
//       backgroundColor: Colors.black,
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.lock, size: 90, color: Colors.white),
//             SizedBox(height: 20),
//             Text(
//               'Monkk AI',
//               style: TextStyle(
//                 color: Colors.white,
//                 fontSize: 26,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             SizedBox(height: 20),
//             CircularProgressIndicator(color: Colors.white),
//           ],
//         ),
//       ),
//     );
//   }
// }
