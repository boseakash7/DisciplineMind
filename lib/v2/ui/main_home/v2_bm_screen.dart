import 'package:flutter/material.dart';
import '../../../ui/main_home/bm_screen.dart';

class V2BmScreen extends StatelessWidget {
  const V2BmScreen({super.key, this.onMonkkTap, this.isActive = true});

  final VoidCallback? onMonkkTap;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return BmScreen(
      onMonkkTap: onMonkkTap,
      isActive: isActive,
    );
  }
}
