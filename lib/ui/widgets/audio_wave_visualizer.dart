import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

class AudioWaveVisualizer extends StatefulWidget {
  const AudioWaveVisualizer({
    super.key,
    required this.amplitude,
    this.barCount = 26,
    this.height = 36.0,
    this.barWidth = 3.2,
    this.activeColor = const Color(0xFF8E8E93),
  });

  /// Current normalized audio amplitude from 0.0 (silence) to 1.0 (loud).
  final double amplitude;

  /// Number of vertical bars in the waveform.
  final int barCount;

  /// Maximum height of the visualizer container.
  final double height;

  /// Width of each bar.
  final double barWidth;

  /// Bar color.
  final Color activeColor;

  @override
  State<AudioWaveVisualizer> createState() => _AudioWaveVisualizerState();
}

class _AudioWaveVisualizerState extends State<AudioWaveVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  Timer? _historyTimer;
  final List<double> _amplitudeHistory = [];

  @override
  void initState() {
    super.initState();
    _amplitudeHistory.addAll(List.filled(widget.barCount, 0.0));
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();

    _historyTimer = Timer.periodic(const Duration(milliseconds: 55), (_) {
      if (!mounted) return;
      setState(() {
        _amplitudeHistory.removeAt(0);
        _amplitudeHistory.add(widget.amplitude);
      });
    });
  }

  @override
  void didUpdateWidget(AudioWaveVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.barCount != oldWidget.barCount) {
      _amplitudeHistory.clear();
      _amplitudeHistory.addAll(List.filled(widget.barCount, widget.amplitude));
    }
  }

  @override
  void dispose() {
    _historyTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return SizedBox(
          height: widget.height,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(widget.barCount, (index) {
              final amp = _amplitudeHistory[index].clamp(0.0, 1.0);
              final isSilence = amp <= 0.05;

              double barHeight = 3.0; // Straight line on silence

              if (!isSilence) {
                final phase =
                    (_animController.value * 2 * math.pi) + (index * 0.35);
                final waveFactor = 0.5 + 0.5 * math.sin(phase);

                final maxHeight = widget.height - 4;
                const minHeight = 4.0;

                barHeight = minHeight +
                    (maxHeight - minHeight) * amp * (0.55 + 0.45 * waveFactor);
                barHeight = barHeight.clamp(3.0, widget.height);
              }

              return AnimatedContainer(
                duration: const Duration(milliseconds: 50),
                width: widget.barWidth,
                height: barHeight,
                decoration: BoxDecoration(
                  color: isSilence
                      ? widget.activeColor.withValues(alpha: 0.35)
                      : widget.activeColor,
                  borderRadius: BorderRadius.circular(widget.barWidth),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
