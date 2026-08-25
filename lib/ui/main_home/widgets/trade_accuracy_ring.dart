import 'package:discipline_mind/common/app_colors.dart';
import 'package:flutter/material.dart';

/// Circular ring that animates fill to [percent] (0–100).
class TradeAccuracyRing extends StatelessWidget {
  const TradeAccuracyRing({
    super.key,
    required this.percent,
    this.size = 40,
    this.strokeWidth = 6,
    this.duration = const Duration(milliseconds: 900),
  });

  final double percent;
  final double size;
  final double strokeWidth;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final target = (percent / 100).clamp(0.0, 1.0);

    return TweenAnimationBuilder<double>(
      key: ValueKey<double>(target),
      tween: Tween<double>(begin: 0, end: target),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return SizedBox(
          height: size,
          width: size,
          child: CircularProgressIndicator(
            value: value,
            strokeWidth: strokeWidth,
            backgroundColor: Colors.grey.shade300,
            color: AppColors.primary,
            strokeCap: StrokeCap.round,
          ),
        );
      },
    );
  }
}
