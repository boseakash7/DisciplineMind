import 'package:flutter/material.dart';

/// Circular ring that animates fill to [percent] (0–100) with optional center text.
class TradeAccuracyRing extends StatelessWidget {
  const TradeAccuracyRing({
    super.key,
    required this.percent,
    this.size = 56,
    this.strokeWidth = 6,
    this.duration = const Duration(milliseconds: 900),
    this.color,
    this.trackColor,
    this.textColor,
    this.showText = true,
  });

  final double percent;
  final double size;
  final double strokeWidth;
  final Duration duration;
  final Color? color;
  final Color? trackColor;
  final Color? textColor;
  final bool showText;

  @override
  Widget build(BuildContext context) {
    final target = (percent / 100).clamp(0.0, 1.0);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final effectiveTrack = trackColor ?? (isDark ? const Color(0xFF38354A) : const Color(0xFFE5E2F4));
    final effectiveColor = color ?? const Color(0xFF6D28D9);
    final effectiveTextColor = textColor ?? (isDark ? Colors.white : const Color(0xFF221B66));

    return TweenAnimationBuilder<double>(
      key: ValueKey<double>(target),
      tween: Tween<double>(begin: 0, end: target),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        final displayInt = (value * 100).round();
        return SizedBox(
          height: size,
          width: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: value,
                strokeWidth: strokeWidth,
                backgroundColor: effectiveTrack,
                color: effectiveColor,
                strokeCap: StrokeCap.round,
              ),
              if (showText)
                Text(
                  '$displayInt%',
                  style: TextStyle(
                    fontSize: size * 0.24,
                    fontWeight: FontWeight.w700,
                    color: effectiveTextColor,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}