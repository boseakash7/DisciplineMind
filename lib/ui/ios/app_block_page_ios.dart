import 'package:flutter/material.dart';

import '../../services/ios_screen_time.dart';

class AppBlockIOSPage extends StatefulWidget {
  const AppBlockIOSPage({super.key});

  @override
  State<AppBlockIOSPage> createState() => _AppBlockIOSPageState();
}

class _AppBlockIOSPageState extends State<AppBlockIOSPage> {
  bool granted = false;
  bool blocked = false;

  final youtubeBundleId = "com.google.ios.youtube";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('iOS App Block')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () async {
                granted = await IosScreenTime.requestPermission();
                setState(() {});
              },
              child: const Text('Request Screen Time Permission'),
            ),

            const SizedBox(height: 24),

            SwitchListTile(
              title: const Text('Block YouTube'),
              subtitle: Text(youtubeBundleId),
              value: blocked,
              onChanged: !granted
                  ? null
                  : (v) async {
                      if (v) {
                        await IosScreenTime.blockApp(youtubeBundleId);
                      } else {
                        await IosScreenTime.unblockAll();
                      }
                      setState(() => blocked = v);
                    },
            ),
          ],
        ),
      ),
    );
  }
}
