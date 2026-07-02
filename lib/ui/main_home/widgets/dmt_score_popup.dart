import 'package:discipline_mind/common/app_colors.dart';
import 'package:discipline_mind/ui/main_home/widgets/dmt_score_card.dart';
import 'package:flutter/material.dart';

/// Testing only: set `true` to run inner reveal animation on every popup open.
/// Set `false` for production (animate only when [showDmtScorePopup] gets `animateReveal: true`).
const bool kDmtScoreAlwaysAnimate = false;

/// Opens DMT score analysis popup (fixed size; inner data animates only).
Future<void> showDmtScorePopup(
  BuildContext context, {
  required String scoreDate,
  required String instructionsScore,
  required String commitmentScore,
  required String patienceScore,
  required String consistencyScore,
  required String dmtTotalScore,
  required String dmtMaxScore,
  bool animateReveal = false,
}) {
  final effectiveAnimateReveal = kDmtScoreAlwaysAnimate || animateReveal;

  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'DMT Score',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 380),
    pageBuilder: (ctx, anim1, anim2) {
      return _DmtScorePopupDialog(
        scoreDate: scoreDate,
        instructionsScore: instructionsScore,
        commitmentScore: commitmentScore,
        patienceScore: patienceScore,
        consistencyScore: consistencyScore,
        dmtTotalScore: dmtTotalScore,
        dmtMaxScore: dmtMaxScore,
        animateReveal: effectiveAnimateReveal,
      );
    },
    transitionBuilder: (ctx, animation, secondaryAnimation, child) {
      final curve = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curve,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.88, end: 1).animate(curve),
          child: child,
        ),
      );
    },
  );
}

class _RowData {
  final String letter;
  final String label;
  final double score;
  final String scoreText;
  final double progressTarget;

  const _RowData({
    required this.letter,
    required this.label,
    required this.score,
    required this.scoreText,
    required this.progressTarget,
  });
}

class _DmtScorePopupDialog extends StatefulWidget {
  final String scoreDate;
  final String instructionsScore;
  final String commitmentScore;
  final String patienceScore;
  final String consistencyScore;
  final String dmtTotalScore;
  final String dmtMaxScore;
  final bool animateReveal;

  const _DmtScorePopupDialog({
    required this.scoreDate,
    required this.instructionsScore,
    required this.commitmentScore,
    required this.patienceScore,
    required this.consistencyScore,
    required this.dmtTotalScore,
    required this.dmtMaxScore,
    this.animateReveal = false,
  });

  @override
  State<_DmtScorePopupDialog> createState() => _DmtScorePopupDialogState();
}

class _DmtScorePopupDialogState extends State<_DmtScorePopupDialog> {
  static const double _popupWidth = 340;
  static const double _bodyHeight = 478;
  static const double _rowSlotHeight = 58;
  static const double _dateSlotHeight = 28;
  static const double _totalSlotHeight = 142;
  static const double _horizontalPadding = 18;

  late final List<_RowData> _rows;
  late final String _fullDate;
  late final double _totalTarget;
  late final String _maxText;

  String _dateText = '';
  late List<double> _circleScales;
  late List<double> _rowProgress;
  late List<double> _rowScores;
  late List<bool> _rowBarVisible;
  late List<bool> _rowScoreVisible;
  double _totalDisplayed = 0;
  bool _showTotalSection = false;

  bool _sequenceStarted = false;

  @override
  void initState() {
    super.initState();
    _fullDate = DmtScoreCard.formatScoreDate(widget.scoreDate);
    _totalTarget = DmtScoreCard.parseScore(widget.dmtTotalScore);
    _maxText = DmtScoreCard.formatScore(widget.dmtMaxScore);
    _rows = [
      _RowData(
        letter: 'I',
        label: 'Process',
        score: DmtScoreCard.parseScore(widget.instructionsScore),
        scoreText: DmtScoreCard.formatScore(widget.instructionsScore),
        progressTarget: DmtScoreCard.progressFraction(
          DmtScoreCard.parseScore(widget.instructionsScore),
        ),
      ),
      _RowData(
        letter: 'C',
        label: 'Commitment',
        score: DmtScoreCard.parseScore(widget.commitmentScore),
        scoreText: DmtScoreCard.formatScore(widget.commitmentScore),
        progressTarget: DmtScoreCard.progressFraction(
          DmtScoreCard.parseScore(widget.commitmentScore),
        ),
      ),
      _RowData(
        letter: 'P',
        label: 'Patience',
        score: DmtScoreCard.parseScore(widget.patienceScore),
        scoreText: DmtScoreCard.formatScore(widget.patienceScore),
        progressTarget: DmtScoreCard.progressFraction(
          DmtScoreCard.parseScore(widget.patienceScore),
        ),
      ),
      _RowData(
        letter: 'C',
        label: 'Consistency',
        score: DmtScoreCard.parseScore(widget.consistencyScore),
        scoreText: DmtScoreCard.formatScore(widget.consistencyScore),
        progressTarget: DmtScoreCard.progressFraction(
          DmtScoreCard.parseScore(widget.consistencyScore),
        ),
      ),
    ];
    _resetAnimatedState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.animateReveal) {
        _runRevealSequence();
      } else {
        _applyFinalState();
      }
    });
  }

  void _resetAnimatedState() {
    _circleScales = List.filled(_rows.length, 0);
    _rowProgress = List.filled(_rows.length, 0);
    _rowScores = List.filled(_rows.length, 0);
    _rowBarVisible = List.filled(_rows.length, false);
    _rowScoreVisible = List.filled(_rows.length, false);
    _dateText = _fullDate;
    _totalDisplayed = 0;
    _showTotalSection = false;
  }

  void _applyFinalState() {
    setState(() {
      _dateText = _fullDate;
      for (var i = 0; i < _rows.length; i++) {
        _circleScales[i] = 1;
        _rowProgress[i] = _rows[i].progressTarget;
        _rowScores[i] = _rows[i].score;
        _rowBarVisible[i] = true;
        _rowScoreVisible[i] = true;
      }
      _totalDisplayed = _totalTarget;
      _showTotalSection = true;
    });
  }

  Future<void> _runRevealSequence() async {
    if (_sequenceStarted) return;
    _sequenceStarted = true;

    for (var r = 0; r < _rows.length; r++) {
      if (!mounted) return;
      final row = _rows[r];

      await _animateSteps(
        steps: 18,
        delayMs: 16,
        onTick: (t) => setState(() => _circleScales[r] = t),
        curve: Curves.easeOutBack,
      );

      if (!mounted) return;
      setState(() => _rowBarVisible[r] = true);

      await _animateValue(
        from: 0,
        to: row.progressTarget,
        durationMs: 520,
        onTick: (v) => setState(() => _rowProgress[r] = v),
      );

      if (!mounted) return;
      setState(() => _rowScoreVisible[r] = true);

      await _animateValue(
        from: 0,
        to: row.score,
        durationMs: 460,
        asInteger: true,
        onTick: (v) => setState(() => _rowScores[r] = v),
      );

      await Future<void>.delayed(const Duration(milliseconds: 80));
    }

    if (!mounted) return;
    setState(() => _showTotalSection = true);

    await _animateValue(
      from: 0,
      to: _totalTarget,
      durationMs: 800,
      asInteger: true,
      onTick: (v) => setState(() => _totalDisplayed = v),
    );
  }

  Future<void> _animateSteps({
    required int steps,
    required int delayMs,
    required ValueChanged<double> onTick,
    Curve curve = Curves.easeOutCubic,
  }) async {
    for (var s = 0; s <= steps; s++) {
      if (!mounted) return;
      onTick(curve.transform(s / steps));
      await Future<void>.delayed(Duration(milliseconds: delayMs));
    }
  }

  Future<void> _animateValue({
    required double from,
    required double to,
    required int durationMs,
    required ValueChanged<double> onTick,
    bool asInteger = false,
  }) async {
    if (asInteger) {
      final target = to.round();
      if (target <= 0) {
        onTick(0);
        return;
      }
      final stepDelay = (durationMs / target).round().clamp(12, 120);
      for (var v = 1; v <= target; v++) {
        if (!mounted) return;
        onTick(v.toDouble());
        await Future<void>.delayed(Duration(milliseconds: stepDelay));
      }
      return;
    }

    const stepCount = 28;
    final stepDelay = (durationMs / stepCount).round();
    for (var s = 0; s <= stepCount; s++) {
      if (!mounted) return;
      final t = Curves.easeOutCubic.transform(s / stepCount);
      onTick(from + (to - from) * t);
      await Future<void>.delayed(Duration(milliseconds: stepDelay));
    }
  }

  String _formatScore(double value) {
    return value.round().toString();
  }

  String _rowScoreLabel(int index) {
    if (!widget.animateReveal) return _formatScore(_rowScores[index]);
    if (!_rowScoreVisible[index]) return '';
    return _formatScore(_rowScores[index]);
  }

  bool _rowShowsBar(int index) {
    if (!widget.animateReveal) return true;
    return _rowBarVisible[index];
  }

  bool _showsTotalSection() {
    if (!widget.animateReveal) return true;
    return _showTotalSection;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalLabel = '${_formatScore(_totalDisplayed)}/$_maxText';

    // 👇 Theme-aware colors
    final popupBg = isDark ? const Color(0xFF232327) : Colors.white;
    final popupBorderColor = isDark ? Colors.white12 : AppColors.textBlack;
    final dateColor = isDark ? Colors.white : AppColors.textBlack;
    final labelColor = isDark ? Colors.white60 : AppColors.textGrey;
    final scoreColor = isDark ? Colors.white : AppColors.textGrey;
    final trackColor = isDark
        ? AppColors.primary.withOpacity(0.30)
        : AppColors.primary.withOpacity(0.25);
    final totalTitleColor = isDark ? Colors.white70 : AppColors.textGrey;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: _popupWidth,
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: popupBg,
            borderRadius: BorderRadius.circular(14),
           
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14,horizontal: 4),
                color: AppColors.primary,
                child: Row(
                  children: [Icon(Icons.close,color: Colors.white),
                  SizedBox(width: 10),
                    const Text(
                      'Discipline Analysis for the day',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: _bodyHeight,
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    _horizontalPadding,
                    16,
                    _horizontalPadding,
                    22,
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        height: _dateSlotHeight,
                        child: Center(
                          child: Text(
                            _dateText,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: dateColor,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...List.generate(_rows.length, (i) {
                        return SizedBox(
                          height: _rowSlotHeight,
                          child: _ScoreRowView(
                            letter: _rows[i].letter,
                            label: _rows[i].label,
                            scoreText: _rowScoreLabel(i),
                            progress: _rowProgress[i],
                            circleScale: _circleScales[i],
                            showBarAndLabel: _rowShowsBar(i),
                            isDark: isDark,
                            labelColor: labelColor,
                            scoreColor: scoreColor,
                            trackColor: trackColor,
                          ),
                        );
                      }),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: _totalSlotHeight,
                        child: _showsTotalSection()
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'DMT SCORE',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: totalTitleColor,
                                      height: 1.2,
                                    ),
                                  ),
                                  Text(
                                    'for today',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: totalTitleColor,
                                      height: 1.3,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    width: 90,
                                    height: 90,
                                    decoration: const BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        totalLabel,
                                        maxLines: 1,
                                        softWrap: false,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Outer cyan ring (hollow, theme-independent) + letter inside.
class _DoubleCircleLetter extends StatelessWidget {
  final String letter;
  final double scale;

  const _DoubleCircleLetter({required this.letter, required this.scale});

  static const double outerSize = 40;

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: scale.clamp(0.0, 1.0),
      child: Opacity(
        opacity: scale.clamp(0.0, 1.0),
        child: SizedBox(
          width: outerSize,
          height: outerSize,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 2),
            ),
            child: Center(
              child: Text(
                letter,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  height: 1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ScoreRowView extends StatelessWidget {
  final String letter;
  final String label;
  final String scoreText;
  final double progress;
  final double circleScale;
  final bool showBarAndLabel;
  final bool isDark;
  final Color labelColor;
  final Color scoreColor;
  final Color trackColor;

  const _ScoreRowView({
    required this.letter,
    required this.label,
    required this.scoreText,
    required this.progress,
    required this.circleScale,
    required this.isDark,
    required this.labelColor,
    required this.scoreColor,
    required this.trackColor,
    this.showBarAndLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: _DoubleCircleLetter.outerSize,
          height: _DoubleCircleLetter.outerSize,
          child: Center(
            child: _DoubleCircleLetter(letter: letter, scale: circleScale),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final h = constraints.maxHeight;
              final barCenterY = h / 2;
              const barHeight = 5.0;
              const labelGap = 5.0;
              if (!showBarAndLabel) {
                return const SizedBox.shrink();
              }
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    top: barCenterY - (barHeight / 2),
                    height: barHeight,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Container(color: trackColor),
                          FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: progress.clamp(0.0, 1.0),
                            child: Container(color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: barCenterY + (barHeight / 2) + labelGap,
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: labelColor,
                        fontWeight: FontWeight.w500,
                        height: 1.1,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(width: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 44, maxWidth: 56),
          child: Text(
            scoreText,
            maxLines: 1,
            softWrap: false,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: scoreText.isEmpty ? Colors.transparent : scoreColor,
              height: 1.1,
            ),
          ),
        ),
      ],
    );
  }
}