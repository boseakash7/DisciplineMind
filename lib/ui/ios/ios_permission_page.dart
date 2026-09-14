// import 'package:discipline_mind/ui/ios/ios_block_page.dart';
// import 'package:flutter/material.dart';

// import 'ios_block_service.dart';

// class IOSPermissionPage extends StatelessWidget {
//   const IOSPermissionPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final service = IOSBlockService();

//     return Scaffold(
//       appBar: AppBar(title: const Text('iOS Permission')),
//       body: Center(
//         child: ElevatedButton(
//           child: const Text('Allow Screen Time Access'),
//           onPressed: () async {
//             final granted = await service.requestPermission();
//             if (granted && context.mounted) {
//               Navigator.pushReplacement(
//                 context,
//                 MaterialPageRoute(builder: (_) => const IOSBlockPage()),
//               );
//             }
//           },
//         ),
//       ),
//     );
//   }
// }
