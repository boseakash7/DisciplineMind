import 'package:flutter/material.dart';
import '../../../ui/main_home/analysis_screen.dart';

class V2AnalysisScreen extends StatelessWidget {
  const V2AnalysisScreen({super.key, this.onMonkkTap, this.isActive = true});

  final VoidCallback? onMonkkTap;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return AnalysisScreen(
      onMonkkTap: onMonkkTap,
      isActive: isActive,
    );
  }
}
