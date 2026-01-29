// import 'package:flutter/material.dart';

// import 'ios_block_service.dart';

// class IOSBlockPage extends StatefulWidget {
//   const IOSBlockPage({super.key});

//   @override
//   State<IOSBlockPage> createState() => _IOSBlockPageState();
// }

// class _IOSBlockPageState extends State<IOSBlockPage> {
//   final IOSBlockService _service = IOSBlockService();
//   bool _blocked = false;
//   bool _loading = true;

//   @override
//   void initState() {
//     super.initState();
//     _load();
//   }

//   Future<void> _load() async {
//     _blocked = await _service.isBlocked();
//     setState(() => _loading = false);
//   }

//   Future<void> _toggle() async {
//     setState(() => _loading = true);
//     await _service.toggleBlock();
//     _blocked = !_blocked;
//     setState(() => _loading = false);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('iOS App Blocking')),
//       body: _loading
//           ? const Center(child: CircularProgressIndicator())
//           : ListTile(
//               leading: const Icon(Icons.play_circle_fill, color: Colors.red),
//               title: const Text('Blocked Apps'),
//               subtitle: const Text('Managed by Screen Time'),
//               trailing: Switch(value: _blocked, onChanged: (_) => _toggle()),
//             ),
//     );
//   }
// }
