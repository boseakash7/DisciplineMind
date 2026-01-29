import 'package:block_app/block_app.dart';
import 'package:flutter/material.dart';
import 'app_block_page.dart';

class PermissionGatePage extends StatefulWidget {
  const PermissionGatePage({super.key});

  @override
  State<PermissionGatePage> createState() => _PermissionGatePageState();
}

class _PermissionGatePageState extends State<PermissionGatePage> {
  final BlockApp _blockApp = BlockApp();

  bool overlayGranted = false;
  bool usageGranted = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final permissions = await _blockApp.checkPermissions();
    setState(() {
      overlayGranted = permissions['hasOverlayPermission'] ?? false;
      usageGranted = permissions['hasUsageStatsPermission'] ?? false;
    });
  }

  Future<void> _requestOverlay() async {
    await _blockApp.requestOverlayPermission();
    _check();
  }

  Future<void> _requestUsage() async {
    await _blockApp.requestUsageStatsPermission();
    _check();
  }

  void _continue() {
    if (!overlayGranted || !usageGranted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const AppBlockPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allGranted = overlayGranted && usageGranted;

    return Scaffold(
      appBar: AppBar(title: const Text('Permissions Required')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _tile(
              title: 'Display Over Apps',
              granted: overlayGranted,
              onTap: _requestOverlay,
            ),
            const SizedBox(height: 16),
            _tile(
              title: 'Usage Access',
              granted: usageGranted,
              onTap: _requestUsage,
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: allGranted ? _continue : null,
                child: const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile({
    required String title,
    required bool granted,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: granted ? Colors.green : Colors.red),
      ),
      child: Row(
        children: [
          Icon(granted ? Icons.check_circle : Icons.error,
              color: granted ? Colors.green : Colors.red),
          const SizedBox(width: 12),
          Expanded(child: Text(title)),
          ElevatedButton(
            onPressed: granted ? null : onTap,
            child: Text(granted ? 'Granted' : 'Allow'),
          )
        ],
      ),
    );
  }
}
