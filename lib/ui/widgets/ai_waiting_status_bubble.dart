import 'dart:math' as math;

import 'package:discipline_mind/common/app_colors.dart';
import 'package:flutter/material.dart';

/// Premium reusable AI waiting bubble.
/// Pass different [text] / [subtitle] for each waiting state.
class AiWaitingStatusBubble extends StatefulWidget {
  const AiWaitingStatusBubble({
    super.key,
    required this.text,
    this.subtitle = 'Monkk is waiting',
    this.showAvatar = true,
  });

  final String text;
  final String subtitle;
  final bool showAvatar;

  @override
  State<AiWaitingStatusBubble> createState() => _AiWaitingStatusBubbleState();
}

class _AiWaitingStatusBubbleState extends State<AiWaitingStatusBubble>
    with TickerProviderStateMixin {
  late final AnimationController _pulse;
  late final AnimationController _shimmer;
  late final AnimationController _dots;
  late final AnimationController _enter;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
    _dots = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    )..forward();
  }

  @override
  void dispose() {
    _pulse.dispose();
    _shimmer.dispose();
    _dots.dispose();
    _enter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isUserAction = widget.subtitle.toLowerCase().contains('your action');

    return FadeTransition(
      opacity: CurvedAnimation(parent: _enter, curve: Curves.easeOut),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.12),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: _enter, curve: Curves.easeOutCubic)),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10, top: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (widget.showAvatar) ...[
                _AnimatedAvatar(pulse: _pulse),
                const SizedBox(width: 10),
              ],
              Flexible(
                child: AnimatedBuilder(
                  animation: Listenable.merge([_pulse, _shimmer]),
                  builder: (context, _) {
                    return Container(
                      constraints: const BoxConstraints(maxWidth: 320),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          children: [
                            Container(
                              padding: const EdgeInsets.fromLTRB(
                                14,
                                11,
                                14,
                                12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.grey.shade200,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isUserAction
                                            ? Icons.touch_app_outlined
                                            : Icons.auto_awesome,
                                        size: 13,
                                        color: Colors.grey.shade500,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        widget.subtitle,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.15,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      _PremiumThinkingDots(
                                        controller: _dots,
                                        color: isUserAction
                                            ? Colors.grey.shade500
                                            : AppColors.primary,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 7),
                                  Text(
                                    widget.text,
                                    style: TextStyle(
                                      color: Colors.grey.shade800,
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Soft neutral shimmer
                            Positioned.fill(
                              child: IgnorePointer(
                                child: Transform.translate(
                                  offset: Offset(
                                    -140 + (_shimmer.value * 400),
                                    0,
                                  ),
                                  child: Container(
                                    width: 70,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                        colors: [
                                          Colors.white.withOpacity(0.0),
                                          Colors.grey.shade100.withOpacity(0.7),
                                          Colors.white.withOpacity(0.0),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedAvatar extends StatelessWidget {
  const _AnimatedAvatar({required this.pulse});

  final AnimationController pulse;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (context, child) {
        final scale = 1.0 + (pulse.value * 0.04);
        final ringOpacity = 0.10 + (pulse.value * 0.12);
        return SizedBox(
          width: 40,
          height: 40,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.scale(
                scale: scale,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withOpacity(ringOpacity),
                  ),
                ),
              ),
              child!,
            ],
          ),
        );
      },
      child: Container(
        width: 34,
        height: 34,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primary,
        ),
        child: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
      ),
    );
  }
}

class _PremiumThinkingDots extends StatelessWidget {
  const _PremiumThinkingDots({
    required this.controller,
    required this.color,
  });

  final AnimationController controller;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        Widget dot(int i) {
          final t = (controller.value + (i * 0.22)) % 1.0;
          final bounce = math.sin(t * math.pi);
          final y = -3.0 * bounce;
          final opacity = 0.35 + (0.65 * bounce);
          final scale = 0.8 + (0.3 * bounce);
          return Transform.translate(
            offset: Offset(0, y),
            child: Transform.scale(
              scale: scale,
              child: Opacity(
                opacity: opacity,
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                  ),
                ),
              ),
            ),
          );
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            dot(0),
            const SizedBox(width: 3.5),
            dot(1),
            const SizedBox(width: 3.5),
            dot(2),
          ],
        );
      },
    );
  }
}
