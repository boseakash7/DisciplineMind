// import 'package:flutter/material.dart';
// import 'ios_permission_page.dart';
// import 'ios_block_page.dart';
// import 'ios_block_service.dart';

// class IOSSplashHandler {
//   static Future<void> navigate(BuildContext context) async {
//     final service = IOSBlockService();
//     final granted = await service.requestPermission();

//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(
//         builder: (_) =>
//             granted ? const IOSBlockPage() : const IOSPermissionPage(),
//       ),
//     );
//   }
// }
