import 'package:flutter/material.dart';
import '../../../ui/main_home/chat_screen.dart';

class V2ChatScreen extends StatelessWidget {
  const V2ChatScreen({super.key, this.onMonkkTap, this.isActive = true});

  final VoidCallback? onMonkkTap;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return ChatScreen(
      onMonkkTap: onMonkkTap,
      isActive: isActive,
      showLeadingIcon: false,
    );
  }
}
