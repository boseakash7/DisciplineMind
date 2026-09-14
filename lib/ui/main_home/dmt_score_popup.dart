import 'package:flutter/material.dart';
import 'package:discipline_mind/common/app_colors.dart';

class _DmtColors {
  static Color dialogBg(bool isDark) =>
      isDark ? const Color(0xFF1E222A) : Colors.white;

  static Color textPrimary(bool isDark) => isDark ? Colors.white : Colors.black87;

  static Color textSecondary(bool isDark) =>
      isDark ? Colors.white70 : Colors.grey.shade700;

  static Color textMuted(bool isDark) =>
      isDark ? Colors.white38 : Colors.grey.shade500;

  static Color trackBg(bool isDark) =>
      isDark ? Colors.white12 : Colors.grey.shade200;
}

class DmtCategoryResult {
  const DmtCategoryResult({
    required this.label,
    required this.icon,
    required this.score,
  });

  final String label;
  final IconData icon;
  final int score;
}

Future<void> showDmtScorePopup(
  BuildContext context, {
  required String scoreDate,
  required int instructionsScore,
  required int commitmentScore,
  required int patienceScore,
  required int consistencyScore,
  required int dmtTotalScore,
  required int dmtMaxScore,
  bool animateReveal = false,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _DmtScorePopup(
      scoreDate: scoreDate,
      instructionsScore: instructionsScore,
      commitmentScore: commitmentScore,
      patienceScore: patienceScore,
      consistencyScore: consistencyScore,
      dmtTotalScore: dmtTotalScore,
      dmtMaxScore: dmtMaxScore,
      animateReveal: animateReveal,
    ),
  );
}

class _DmtScorePopup extends StatefulWidget {
  const _DmtScorePopup({
    required this.scoreDate,
    required this.instructionsScore,
    required this.commitmentScore,
    required this.patienceScore,
    required this.consistencyScore,
    required this.dmtTotalScore,
    required this.dmtMaxScore,
    required this.animateReveal,
  });

  final String scoreDate;
  final int instructionsScore;
  final int commitmentScore;
  final int patienceScore;
  final int consistencyScore;
  final int dmtTotalScore;
  final int dmtMaxScore;
  final bool animateReveal;

  @override
  State<_DmtScorePopup> createState() => _DmtScorePopupState();
}

class _DmtScorePopupState extends State<_DmtScorePopup>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.animateReveal ? 1200 : 1),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double get _percent =>
      widget.dmtMaxScore == 0 ? 0 : widget.dmtTotalScore / widget.dmtMaxScore;

  String get _verdict {
    final p = _percent;
    if (p >= 0.8) return 'Excellent Discipline';
    if (p >= 0.6) return 'Good Progress';
    if (p >= 0.4) return 'Needs Improvement';
    return 'High Risk Mindset';
  }

  Color _verdictColor() {
    final p = _percent;
    if (p >= 0.8) return const Color(0xFF2ECC71);
    if (p >= 0.6) return AppColors.primary;
    if (p >= 0.4) return const Color(0xFFF39C12);
    return const Color(0xFFE74C3C);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categories = [
      DmtCategoryResult(
        label: 'Instructions',
        icon: Icons.rule,
        score: widget.instructionsScore,
      ),
      DmtCategoryResult(
        label: 'Commitment',
        icon: Icons.flag,
        score: widget.commitmentScore,
      ),
      DmtCategoryResult(
        label: 'Patience',
        icon: Icons.hourglass_bottom,
        score: widget.patienceScore,
      ),
      DmtCategoryResult(
        label: 'Consistency',
        icon: Icons.repeat,
        score: widget.consistencyScore,
      ),
    ];

    final approxCategoryMax =
        widget.dmtMaxScore > 0 ? widget.dmtMaxScore / categories.length : 1.0;

    return Dialog(
      backgroundColor: _DmtColors.dialogBg(isDark),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            final animatedPercent = _percent * _animation.value;
            final animatedTotal = (widget.dmtTotalScore * _animation.value).round();
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Discipline Mind Score',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _DmtColors.textPrimary(isDark),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.scoreDate,
                  style: TextStyle(
                    fontSize: 12,
                    color: _DmtColors.textMuted(isDark),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: 140,
                  height: 140,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 140,
                        height: 140,
                        child: CircularProgressIndicator(
                          value: animatedPercent.clamp(0, 1),
                          strokeWidth: 10,
                          backgroundColor: _DmtColors.trackBg(isDark),
                          valueColor: AlwaysStoppedAnimation<Color>(_verdictColor()),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${(animatedPercent * 100).round()}%',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: _DmtColors.textPrimary(isDark),
                            ),
                          ),
                          Text(
                            '$animatedTotal / ${widget.dmtMaxScore}',
                            style: TextStyle(
                              fontSize: 12,
                              color: _DmtColors.textSecondary(isDark),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: _verdictColor().withOpacity(isDark ? 0.22 : 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _verdict,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _verdictColor(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ...categories.map((c) {
                  final ratio = approxCategoryMax == 0
                      ? 0.0
                      : (c.score / approxCategoryMax).clamp(0.0, 1.0);
                  final animatedRatio = ratio * _animation.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(c.icon, size: 16, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                c.label,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: _DmtColors.textPrimary(isDark),
                                ),
                              ),
                            ),
                            Text(
                              '${c.score}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _DmtColors.textPrimary(isDark),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: animatedRatio,
                            minHeight: 6,
                            backgroundColor: _DmtColors.trackBg(isDark),
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text(
                      'OK',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}