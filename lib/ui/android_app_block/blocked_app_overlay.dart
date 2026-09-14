import 'package:flutter/material.dart';

/// Custom overlay shown when user tries to open a blocked app (Zerodha, Upstox, Groww).
/// Used in AppBlockConfig.customOverlayBuilder so the user sees this page instead of the app home.
class BlockedAppOverlay extends StatelessWidget {
  final String packageName;

  const BlockedAppOverlay({super.key, required this.packageName});

  static String _appDisplayName(String package) {
    switch (package) {
      case 'com.zerodha.kite3':
        return 'Zerodha Kite';
      case 'in.upstox.app':
        return 'Upstox';
      case 'com.nextbillion.groww':
        return 'Groww';
      default:
        return 'This app';
    }
  }

  @override
  Widget build(BuildContext context) {
    final appName = _appDisplayName(packageName);
    return Material(
      color: Colors.black87,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock, size: 80, color: Colors.white),
                const SizedBox(height: 24),
                Text(
                  '$appName is blocked',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Stay focused on your goals. This app is blocked while your price alert is active.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 14,
                    ),
                  ),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
