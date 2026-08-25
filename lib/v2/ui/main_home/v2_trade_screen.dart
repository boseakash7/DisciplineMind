import 'package:flutter/material.dart';
import '../../../ui/main_home/trade_screen.dart';

class V2TradesScreen extends StatelessWidget {
  const V2TradesScreen({super.key, this.onMonkkTap, this.isActive = true});

  final VoidCallback? onMonkkTap;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return TradesScreen(
      onMonkkTap: onMonkkTap,
      isActive: isActive,
    );
  }
}
