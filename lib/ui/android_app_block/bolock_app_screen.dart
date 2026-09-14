import 'package:flutter/material.dart';

class BlockedAppScreen extends StatelessWidget {
  final String blockedAppName;
  const BlockedAppScreen({super.key, required this.blockedAppName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red.shade900,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock, size: 100, color: Colors.white),
            const SizedBox(height: 20),
            Text(
              '$blockedAppName is blocked!',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // close overlay
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
              child: const Text('Go Back', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }
}
