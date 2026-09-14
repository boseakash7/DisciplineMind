import 'package:flutter/material.dart';

/// Color tokens for the AI Credits purchase flow (matches design screens).
class CreditsColors {
  CreditsColors._();

  static const Color purple = Color(0xFF5D3FD3);
  static const Color purpleDark = Color(0xFF7C3AED);
  static const Color blue = Color(0xFF3B82F6);
  static const Color blueText = Color(0xFF2563EB);
  static const Color lightPurple = Color(0xFFF3EEFF);
  static const Color lightPurpleBorder = Color(0xFFE0D4FF);
  static const Color success = Color(0xFF10B981);
  static const Color successBg = Color(0xFFECFDF5);
  static const Color successBorder = Color(0xFFA7F3D0);
  static const Color danger = Color(0xFFEF4444);
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color border = Color(0xFFE5E7EB);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color scaffoldBg = Color(0xFFF8F9FB);
  static const Color welcomeBg = Color(0xFFF5F0FF);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF3B82F6), Color(0xFF9333EA)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}
