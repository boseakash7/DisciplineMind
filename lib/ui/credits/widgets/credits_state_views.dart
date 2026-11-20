import 'package:flutter/material.dart';

import '../../../common/credits_colors.dart';

/// Shared empty / error / loading presentation for the AI Credits flow.
///
/// Keeping these in one place means every surface in the flow fails and loads
/// the same way, instead of each screen inventing its own spinner.

// ---------------------------------------------------------------- shimmer

/// Sweeping highlight used by the skeleton placeholders.
class CreditsShimmer extends StatefulWidget {
  const CreditsShimmer({super.key, required this.child, this.enabled = true});

  final Widget child;
  final bool enabled;

  @override
  State<CreditsShimmer> createState() => _CreditsShimmerState();
}

class _CreditsShimmerState extends State<CreditsShimmer>
    with SingleTickerProviderStateMixin {
  // Eager: build returns early when disabled, so a lazy field would first be
  // read inside dispose().
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            // Slide a soft highlight band across the placeholder.
            final slide = (_controller.value * 2) - 0.5;
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: const [
                Color(0xFFEDEFF3),
                Color(0xFFF7F8FA),
                Color(0xFFEDEFF3),
              ],
              stops: [
                (slide - 0.3).clamp(0.0, 1.0),
                slide.clamp(0.0, 1.0),
                (slide + 0.3).clamp(0.0, 1.0),
              ],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// A single neutral block used to compose skeletons.
class CreditsSkeletonBox extends StatelessWidget {
  const CreditsSkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.radius = 6,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFEDEFF3),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Placeholder stack shaped like the real package cards, so the layout does
/// not jump when the API responds.
class CreditsPackageSkeleton extends StatelessWidget {
  const CreditsPackageSkeleton({super.key, this.count = 4});

  final int count;

  @override
  Widget build(BuildContext context) {
    return CreditsShimmer(
      child: Column(
        children: [
          for (var i = 0; i < count; i++)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              height: 78,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: CreditsColors.border),
              ),
              child: Row(
                children: [
                  const CreditsSkeletonBox(width: 22, height: 22, radius: 11),
                  const SizedBox(width: 12),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      CreditsSkeletonBox(width: 120, height: 13),
                      SizedBox(height: 8),
                      CreditsSkeletonBox(width: 86, height: 10),
                    ],
                  ),
                  const Spacer(),
                  const CreditsSkeletonBox(width: 54, height: 16),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Placeholder rows for the transaction history list.
class CreditsHistorySkeleton extends StatelessWidget {
  const CreditsHistorySkeleton({super.key, this.count = 6});

  final int count;

  @override
  Widget build(BuildContext context) {
    return CreditsShimmer(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        physics: const NeverScrollableScrollPhysics(),
        children: [
          const CreditsSkeletonBox(width: 110, height: 12),
          const SizedBox(height: 14),
          for (var i = 0; i < count; i++)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: CreditsColors.border),
              ),
              child: Row(
                children: [
                  const CreditsSkeletonBox(width: 38, height: 38, radius: 12),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      CreditsSkeletonBox(width: 150, height: 12),
                      SizedBox(height: 8),
                      CreditsSkeletonBox(width: 96, height: 10),
                    ],
                  ),
                  const Spacer(),
                  const CreditsSkeletonBox(width: 46, height: 14),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------- state view

/// Visual weight of a [CreditsStateView].
enum CreditsStateTone { neutral, error, success }

/// Illustrated empty / error state card.
///
/// One component for "nothing here yet", "that request failed" and
/// "you're all set", so the flow never drops to a bare line of grey text.
class CreditsStateView extends StatelessWidget {
  const CreditsStateView({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.tone = CreditsStateTone.neutral,
    this.primaryLabel,
    this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String message;
  final CreditsStateTone tone;
  final String? primaryLabel;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  /// Tighter spacing, for use inside a scrolling column.
  final bool compact;

  Color get _accent => switch (tone) {
    CreditsStateTone.neutral => CreditsColors.purple,
    CreditsStateTone.error => CreditsColors.danger,
    CreditsStateTone.success => CreditsColors.success,
  };

  List<Color> get _halo => switch (tone) {
    CreditsStateTone.neutral => const [Color(0xFFF3EEFF), Color(0xFFE8F1FF)],
    CreditsStateTone.error => const [Color(0xFFFEF2F2), Color(0xFFFFF1F1)],
    CreditsStateTone.success => const [Color(0xFFECFDF5), Color(0xFFEFFCF6)],
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: 22,
        vertical: compact ? 24 : 34,
      ),
      decoration: BoxDecoration(
        color: CreditsColors.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: CreditsColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Layered halo so the icon reads as an illustration, not a glyph.
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: _halo,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: _accent.withValues(alpha: 0.16),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, size: 26, color: _accent),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: CreditsColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: CreditsColors.textSecondary,
            ),
          ),
          if (primaryLabel != null && onPrimary != null) ...[
            const SizedBox(height: 20),
            SizedBox(
              height: 44,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: tone == CreditsStateTone.neutral
                      ? CreditsColors.primaryGradient
                      : null,
                  color: tone == CreditsStateTone.neutral ? null : _accent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: _accent.withValues(alpha: 0.26),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onPrimary,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 26),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.refresh_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            primaryLabel!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
          if (secondaryLabel != null && onSecondary != null) ...[
            const SizedBox(height: 4),
            TextButton(
              onPressed: onSecondary,
              child: Text(
                secondaryLabel!,
                style: const TextStyle(
                  color: CreditsColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
