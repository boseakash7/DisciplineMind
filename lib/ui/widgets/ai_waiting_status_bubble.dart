import 'dart:math' as math;

import 'package:discipline_mind/common/app_colors.dart';
import 'package:flutter/material.dart';

/// Premium reusable AI waiting bubble.
/// Pass different [text] / [subtitle] for each waiting state.
class AiWaitingStatusBubble extends StatefulWidget {
  const AiWaitingStatusBubble({
    super.key,
    required this.text,
    this.subtitle = 'Zeno AI is analyzing',
    this.showAvatar = false,
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

  List<InlineSpan> _parseFormattedSpans(String raw, Color textColor) {
    final List<InlineSpan> spans = [];
    final tagRegex = RegExp(
      r'(?:<b>(.*?)<\/b>|<strong>(.*?)<\/strong>|\*\*(.*?)\*\*)',
      caseSensitive: false,
      dotAll: true,
    );

    int lastMatchEnd = 0;
    for (final match in tagRegex.allMatches(raw)) {
      if (match.start > lastMatchEnd) {
        spans.add(
          TextSpan(
            text: raw.substring(lastMatchEnd, match.start),
            style: TextStyle(
              fontSize: 13.5,
              color: textColor,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        );
      }

      final boldText = match.group(1) ?? match.group(2) ?? match.group(3) ?? '';
      spans.add(
        TextSpan(
          text: boldText,
          style: TextStyle(
            fontSize: 13.5,
            color: textColor,
            fontWeight: FontWeight.w800,
            height: 1.4,
          ),
        ),
      );

      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < raw.length) {
      spans.add(
        TextSpan(
          text: raw.substring(lastMatchEnd),
          style: TextStyle(
            fontSize: 13.5,
            color: textColor,
            fontWeight: FontWeight.w500,
            height: 1.4,
          ),
        ),
      );
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isUserAction = widget.subtitle.toLowerCase().contains('your action');
    final cardBg = isDark ? const Color(0xFF1E222A) : Colors.white;
    final borderCol = isDark ? const Color(0xFF2C3240) : const Color(0xFFE5E7EB);
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF1F2937);
    final subTextColor = isDark ? Colors.white60 : Colors.grey.shade600;

    String cleanSubtitle = widget.subtitle.trim();
    if (cleanSubtitle.isEmpty ||
        cleanSubtitle.toLowerCase() == 'monkk is waiting' ||
        cleanSubtitle.toLowerCase() == 'ai is waiting') {
      cleanSubtitle = 'Zeno AI is analyzing';
    }

    return FadeTransition(
      opacity: CurvedAnimation(parent: _enter, curve: Curves.easeOut),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: _enter, curve: Curves.easeOutCubic)),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12, top: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.showAvatar) ...[
                _AnimatedAvatar(pulse: _pulse),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: AnimatedBuilder(
                  animation: Listenable.merge([_pulse, _shimmer]),
                  builder: (context, _) {
                    return Container(
                      constraints: const BoxConstraints(maxWidth: 360),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDark ? 0.2 : 0.04,
                            ),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Stack(
                          children: [
                            Container(
                              padding: const EdgeInsets.fromLTRB(14, 11, 14, 13),
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: borderCol),
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
                                        color: isUserAction
                                            ? subTextColor
                                            : AppColors.primary,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        cleanSubtitle,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.2,
                                          color: subTextColor,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      _PremiumThinkingDots(
                                        controller: _dots,
                                        color: isUserAction
                                            ? subTextColor
                                            : AppColors.primary,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  RichText(
                                    text: TextSpan(
                                      children: _parseFormattedSpans(
                                        widget.text,
                                        primaryTextColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Soft ambient shimmer
                            Positioned.fill(
                              child: IgnorePointer(
                                child: Transform.translate(
                                  offset: Offset(
                                    -160 + (_shimmer.value * 460),
                                    0,
                                  ),
                                  child: Container(
                                    width: 80,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                        colors: [
                                          Colors.white.withValues(alpha: 0.0),
                                          (isDark
                                                  ? Colors.white.withValues(alpha: 0.06)
                                                  : Colors.purple.withValues(alpha: 0.08)),
                                          Colors.white.withValues(alpha: 0.0),
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
        return Transform.scale(scale: scale, child: child);
      },
      child: Image.asset(
        'assets/ai_chat.png',
        width: 28,
        height: 28,
        fit: BoxFit.contain,
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
