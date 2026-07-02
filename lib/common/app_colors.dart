import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors
  static const Color primary = Color(0xff04B6D4);
  static const Color primaryGreen = Color(0xFF00B36B);
  static const Color actionRed = Color(0xFFFF3B30);

  // Light Theme
  static const Color lightBackground = Color(0xFFF8F9FA);
  static const Color lightSurface = Colors.white;
  static const Color lightTextPrimary = Color(0xFF1F1F1F);
  static const Color lightTextSecondary = Color(0xFF757575);
  static const Color lightBorder = Color(0xFFE0E0E0);

  // Dark Theme
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkTextPrimary = Colors.white;
  static const Color darkTextSecondary = Color(0xFFB0B0B0);
  static const Color darkBorder = Color(0xFF424242);

  // Legacy Support (to avoid breaking old code)
  static const Color backgroundGray = lightBackground;
  static const Color textBlack = lightTextPrimary;
  static const Color textGrey = lightTextSecondary;
  static const Color white = Colors.white;
}