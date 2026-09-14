import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors — matching the Create a Process palette
  static const Color primary = Color(0xFF4A22F4);
  static const Color primaryViolet = Color(0xFF983BF4);
  static const Color primaryBlue = Color(0xFF2B4BF2);
  static const Color primaryGreen = Color(0xFF208052);
  static const Color lightGreen = Color(0xFFF0FAF6);
  static const Color actionRed = Color(0xFFCC3B4D);
  static const Color bordercolor = Color(0xFFE2E0E9);

  // Light Theme
  static const Color lightBackground = Colors.white;
  static const Color lightSurface = Colors.white;
  static const Color lightTextPrimary = Color(0xFF10122D);
  static const Color lightTextSecondary = Color(0xFF70717F);
  static const Color lightBorder = Color(0xFFE2E0E9);

  // Dark Theme
  static const Color darkBackground = Color(0xFF12151B);
  static const Color darkSurface = Color(0xFF1E222A);
  static const Color darkTextPrimary = Colors.white;
  static const Color darkTextSecondary = Color(0xFFB0B0B0);
  static const Color darkBorder = Color(0xFF424242);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryViolet],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // Legacy Support (to avoid breaking old code)
  static const Color backgroundGray = Color(0xFFF8F9FA);
  static const Color textBlack = lightTextPrimary;
  static const Color textGrey = lightTextSecondary;
  static const Color white = Colors.white;
}