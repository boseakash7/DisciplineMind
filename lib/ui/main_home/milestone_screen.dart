import 'package:flutter/material.dart';

class MilestoneScreen extends StatelessWidget {
  const MilestoneScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Milestones')),
    body: const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.emoji_events_outlined, size: 68),
            SizedBox(height: 16),
            Text(
              'Your learning milestones',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 8),
            Text(
              'Your guided videos and progress will appear here.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ),
  );
}
