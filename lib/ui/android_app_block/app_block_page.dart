import 'package:block_app/block_app.dart';
import 'package:flutter/material.dart';

const String YOUTUBE_PACKAGE = "com.google.android.youtube";

class AppBlockPage extends StatefulWidget {
  const AppBlockPage({super.key});

  @override
  State<AppBlockPage> createState() => _AppBlockPageState();
}

class _AppBlockPageState extends State<AppBlockPage> {
  final BlockApp _blockApp = BlockApp();
  bool isBlocked = false;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final blockedApps = await _blockApp.getBlockedApps();

    setState(() {
      isBlocked = blockedApps.contains(YOUTUBE_PACKAGE);
      loading = false;
    });
  }

  Future<void> _toggle() async {
    setState(() => loading = true);

    bool success;
    if (isBlocked) {
      success = await _blockApp.unblockApp(YOUTUBE_PACKAGE);
    } else {
      success = await _blockApp.blockApp(YOUTUBE_PACKAGE);
    }

    if (success) {
      setState(() {
        isBlocked = !isBlocked;
        loading = false;
      });
    } else {
      setState(() => loading = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Action failed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Blocked Apps')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListTile(
              leading: const Icon(
                Icons.play_circle_fill,
                size: 48,
                color: Colors.red,
              ),
              title: const Text(
                'YouTube',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              // subtitle: const Text(YOUTUBE_PACKAGE),
              trailing: Switch(
                value: isBlocked,
                activeThumbColor: Colors.red,
                onChanged: (_) => _toggle(),
              ),
            ),
    );
  }
}
