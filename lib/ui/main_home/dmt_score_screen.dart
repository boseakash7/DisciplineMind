import 'dart:math' as math;

import 'package:discipline_mind/ui/main_home/widgets/dmt_score_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Testing: `true` = reveal + bonus flow on every open.
const bool kDmtScoreAlwaysAnimate = true;

/// Exact tokens sampled / matched from score UI mock.
class _C {
  static const navy = Color(0xFF161B3C);
  static const navySoft = Color(0xFF3A4060);
  static const blue = Color(0xFF1B6BF9);
  static const blueMid = Color(0xFF3B86F8);
  static const blueDark = Color(0xFF1557D6);
  static const barBlueStart = Color(0xFF1871F9);
  static const barBlueEnd = Color(0xFF199CF9);
  static const blueSoft = Color(0xFFEEF4FF);
  static const blueBanner = Color(0xFFF0F7FD);
  static const ringTrack = Color(0xFFD9E6F8);
  static const barTrack = Color(0xFFE4EDF8);
  static const green = Color(0xFF2FAE5A);
  static const bonusCardBg = Color(0xFFF5F8FC);
  static const danger = Color(0xFFE53935);
  static const grey = Color(0xFF6B728A);
  static const greyLight = Color(0xFF9AA3B5);
  static const divider = Color(0xFFE8EDF4);
  static const cardBorder = Color(0xFFE6ECF3);
}

/// Opens the full-screen MCT score screen with optional fast reveal + bonus flow.
Future<void> showDmtScorePopup(
  BuildContext context, {
  required String scoreDate,
  required String instructionsScore,
  required String commitmentScore,
  required String acceptanceScore,
  required String patienceScore,
  required String consistencyScore,
  required String dmtTotalScore,
  required String dmtMaxScore,
  bool hasAcceptanceScore = false,
  bool acceptanceIsNa = false,
  String acceptanceNote = '',
  bool animateReveal = false,
}) {
  final effectiveAnimate = kDmtScoreAlwaysAnimate || animateReveal;

  return Navigator.of(context).push<void>(
    PageRouteBuilder<void>(
      opaque: true,
      barrierDismissible: false,
      transitionDuration: const Duration(milliseconds: 260),
      reverseTransitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (ctx, animation, secondaryAnimation) {
        return DmtScoreScreen(
          scoreDate: scoreDate,
          instructionsScore: instructionsScore,
          commitmentScore: commitmentScore,
          acceptanceScore: acceptanceScore,
          patienceScore: patienceScore,
          consistencyScore: consistencyScore,
          dmtTotalScore: dmtTotalScore,
          dmtMaxScore: dmtMaxScore,
          hasAcceptanceScore: hasAcceptanceScore,
          acceptanceIsNa: acceptanceIsNa,
          acceptanceNote: acceptanceNote,
          animateReveal: effectiveAnimate,
        );
      },
      transitionsBuilder: (ctx, animation, secondaryAnimation, child) {
        final curve = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curve,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.03),
              end: Offset.zero,
            ).animate(curve),
            child: child,
          ),
        );
      },
    ),
  );
}

class _BonusItem {
  final String letter;
  final String title;
  final String description;
  final double points;

  const _BonusItem({
    required this.letter,
    required this.title,
    required this.description,
    required this.points,
  });
}

class _RowData {
  final String letter;
  final String label;
  final double score;
  final double max;
  final bool showAsNa;
  final String naLabel;

  const _RowData({
    required this.letter,
    required this.label,
    required this.score,
    required this.max,
    this.showAsNa = false,
    this.naLabel = 'N/A',
  });

  double get progress =>
      showAsNa ? 0 : DmtScoreCard.progressFraction(score, max);
}

class DmtScoreScreen extends StatefulWidget {
  final String scoreDate;
  final String instructionsScore;
  final String commitmentScore;
  final String acceptanceScore;
  final String patienceScore;
  final String consistencyScore;
  final String dmtTotalScore;
  final String dmtMaxScore;
  final bool hasAcceptanceScore;
  final bool acceptanceIsNa;
  final String acceptanceNote;
  final bool animateReveal;

  const DmtScoreScreen({
    super.key,
    required this.scoreDate,
    required this.instructionsScore,
    required this.commitmentScore,
    required this.acceptanceScore,
    required this.patienceScore,
    required this.consistencyScore,
    required this.dmtTotalScore,
    required this.dmtMaxScore,
    this.hasAcceptanceScore = false,
    this.acceptanceIsNa = false,
    this.acceptanceNote = '',
    this.animateReveal = false,
  });

  @override
  State<DmtScoreScreen> createState() => _DmtScoreScreenState();
}

class _DmtScoreScreenState extends State<DmtScoreScreen>
    with TickerProviderStateMixin {
  late final String _dateText;
  late final double _maxScore;
  late final double _categoryMax;
  late final List<_RowData> _rows;
  late final List<_BonusItem> _bonuses;
  late final double _baseTotal;
  late final double _bonusTotal;
  late final double _finalTotal;

  late List<double> _rowProgress;
  late List<double> _rowScores;
  late List<double> _rowCircleScale;
  late List<String> _rowNaTexts;
  double _totalDisplayed = 0;
  double _ringProgress = 0;

  bool _showBonusCard = false;
  bool _showBonusPopup = false;
  bool _showExcellentBadge = false;
  bool _showConfetti = false;
  bool _sequenceStarted = false;

  late final AnimationController _bonusCardCtrl;
  late final AnimationController _confettiCtrl;
  late final Animation<double> _bonusCardAnim;

  @override
  void initState() {
    super.initState();
    _dateText = DmtScoreCard.formatScoreDate(widget.scoreDate);
    _maxScore = DmtScoreCard.parseScore(widget.dmtMaxScore);
    final effectiveMax = _maxScore > 0 ? _maxScore : 60.0;
    _categoryMax = DmtScoreCard.categoryMax(effectiveMax);

    final process = DmtScoreCard.parseScore(widget.instructionsScore);
    final commitment = DmtScoreCard.parseScore(widget.commitmentScore);
    final acceptance = DmtScoreCard.parseScore(widget.acceptanceScore);
    final patience = DmtScoreCard.parseScore(widget.patienceScore);
    final consistency = DmtScoreCard.parseScore(widget.consistencyScore);
    final apiTotal = DmtScoreCard.parseScore(widget.dmtTotalScore);

    // Base bars: Process + Commitment (+ Acceptance only if API sent it).
    // Bonuses: consistency_score + patience_score → popup, then added after Got it.
    _rows = [
      _RowData(letter: 'P', label: 'Process', score: process, max: _categoryMax),
      _RowData(
        letter: 'C',
        label: 'Commitment',
        score: commitment,
        max: _categoryMax,
      ),
      if (widget.hasAcceptanceScore || widget.acceptanceIsNa)
        _RowData(
          letter: 'A',
          label: 'Acceptance',
          score: acceptance,
          max: _categoryMax,
          showAsNa: widget.acceptanceIsNa || acceptance == 0,
          naLabel: widget.acceptanceNote.trim().isNotEmpty
              ? widget.acceptanceNote.trim()
              : 'N/A',
        ),
    ];

    // Bonus popup / card: only include Consistency / Patience when non-zero.
    _bonuses = [
      if (consistency != 0)
        _BonusItem(
          letter: 'C',
          title: 'Consistency',
          description: 'You stayed consistent throughout the day.',
          points: consistency,
        ),
      if (patience != 0)
        _BonusItem(
          letter: 'P',
          title: 'Patience',
          description: 'You showed great patience and control!',
          points: patience,
        ),
    ];

    _baseTotal = process +
        commitment +
        (widget.hasAcceptanceScore ? acceptance : 0);
    _bonusTotal = consistency + patience;
    // Prefer API total (e.g. 20+5+0+7 = 32).
    _finalTotal = apiTotal > 0 ? apiTotal : _baseTotal + _bonusTotal;

    _rowProgress = List.filled(_rows.length, 0);
    _rowScores = List.filled(_rows.length, 0);
    _rowCircleScale = List.filled(_rows.length, 0);
    _rowNaTexts = List.filled(_rows.length, '');

    _bonusCardCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _bonusCardAnim = CurvedAnimation(
      parent: _bonusCardCtrl,
      curve: Curves.easeOutCubic,
    );
    _confettiCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.animateReveal) {
        _runRevealSequence();
      } else {
        _applyFinalState();
      }
    });
  }

  @override
  void dispose() {
    _bonusCardCtrl.dispose();
    _confettiCtrl.dispose();
    super.dispose();
  }

  void _applyFinalState() {
    setState(() {
      for (var i = 0; i < _rows.length; i++) {
        _rowCircleScale[i] = 1;
        _rowProgress[i] = _rows[i].progress;
        _rowScores[i] = _rows[i].score;
        _rowNaTexts[i] = _rows[i].showAsNa ? _rows[i].naLabel : '';
      }
      _totalDisplayed = _finalTotal;
      _ringProgress =
          (_finalTotal / (_maxScore > 0 ? _maxScore : 60)).clamp(0.0, 1.0);
      _showBonusCard = _bonusTotal != 0;
      _showExcellentBadge = _bonusTotal > 0;
      _showBonusPopup = false;
    });
    if (_bonusTotal != 0) _bonusCardCtrl.value = 1;
  }

  Future<void> _runRevealSequence() async {
    if (_sequenceStarted) return;
    _sequenceStarted = true;

    for (var r = 0; r < _rows.length; r++) {
      if (!mounted) return;
      final row = _rows[r];
      await _tween(
        durationMs: 100,
        curve: Curves.easeOutBack,
        onTick: (t) => setState(() => _rowCircleScale[r] = t),
      );
      if (row.showAsNa) {
        setState(() {
          _rowProgress[r] = 0;
          _rowScores[r] = 0;
          _rowNaTexts[r] = '';
        });
        await _typeText(
          text: row.naLabel,
          durationMs: (row.naLabel.length * 28).clamp(400, 1400),
          onTick: (partial) => setState(() => _rowNaTexts[r] = partial),
        );
        continue;
      }
      await Future.wait([
        _tween(
          durationMs: 200,
          onTick: (t) => setState(() => _rowProgress[r] = row.progress * t),
        ),
        _countTo(
          to: row.score,
          durationMs: 180,
          onTick: (v) => setState(() => _rowScores[r] = v),
        ),
      ]);
    }

    if (!mounted) return;
    await Future.wait([
      _tween(
        durationMs: 260,
        onTick: (t) {
          setState(() {
            _ringProgress =
                (_baseTotal / (_maxScore > 0 ? _maxScore : 60)).clamp(0.0, 1.0) *
                    t;
          });
        },
      ),
      _countTo(
        to: _baseTotal,
        durationMs: 260,
        onTick: (v) => setState(() => _totalDisplayed = v),
      ),
    ]);

    if (!mounted) return;
    if (_bonusTotal != 0) {
      await Future<void>.delayed(const Duration(milliseconds: 140));
      if (!mounted) return;
      setState(() => _showBonusPopup = true);
    }
  }

  Future<void> _onGotIt() async {
    setState(() => _showBonusPopup = false);
    await Future<void>.delayed(const Duration(milliseconds: 80));
    if (!mounted) return;

    setState(() {
      _showBonusCard = true;
      _showExcellentBadge = true;
      _showConfetti = true;
    });
    _bonusCardCtrl.forward(from: 0);
    _confettiCtrl.forward(from: 0);

    final from = _totalDisplayed;
    final ringFrom = _ringProgress;
    final ringTo =
        (_finalTotal / (_maxScore > 0 ? _maxScore : 60)).clamp(0.0, 1.0);

    await _tween(
      durationMs: 360,
      onTick: (t) {
        setState(() {
          _ringProgress = ringFrom + (ringTo - ringFrom) * t;
          _totalDisplayed = from + (_finalTotal - from) * t;
        });
      },
    );
    if (!mounted) return;
    setState(() => _totalDisplayed = _finalTotal);
  }

  Future<void> _tween({
    required int durationMs,
    required ValueChanged<double> onTick,
    Curve curve = Curves.easeOutCubic,
  }) async {
    const steps = 12;
    final delay = (durationMs / steps).round().clamp(6, 30);
    for (var s = 0; s <= steps; s++) {
      if (!mounted) return;
      onTick(curve.transform(s / steps));
      await Future<void>.delayed(Duration(milliseconds: delay));
    }
  }

  Future<void> _countTo({
    required double to,
    required int durationMs,
    required ValueChanged<double> onTick,
  }) async {
    final target = to.round();
    if (target == 0) {
      onTick(0);
      return;
    }
    if (target < 0) {
      final steps = target.abs();
      final delay = (durationMs / steps).round().clamp(5, 22);
      for (var v = -1; v >= target; v--) {
        if (!mounted) return;
        onTick(v.toDouble());
        await Future<void>.delayed(Duration(milliseconds: delay));
      }
      return;
    }
    final delay = (durationMs / target).round().clamp(5, 22);
    for (var v = 1; v <= target; v++) {
      if (!mounted) return;
      onTick(v.toDouble());
      await Future<void>.delayed(Duration(milliseconds: delay));
    }
  }

  Future<void> _typeText({
    required String text,
    required int durationMs,
    required ValueChanged<String> onTick,
  }) async {
    if (text.isEmpty) {
      onTick('');
      return;
    }
    final delay = (durationMs / text.length).round().clamp(12, 40);
    final buffer = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      if (!mounted) return;
      buffer.write(text[i]);
      onTick(buffer.toString());
      await Future<void>.delayed(Duration(milliseconds: delay));
    }
  }

  @override
  Widget build(BuildContext context) {
    final footerText = (_showBonusCard && _bonusTotal != 0)
        ? 'You earned ${DmtScoreCard.formatSignedBonus(_bonusTotal)} bonus points today!\nGreat going!'
        : 'Good Discipline! Keep it up.';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  _Header(onClose: () => Navigator.of(context).pop()),
                  const Divider(height: 1, thickness: 1, color: _C.divider),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _C.cardBorder, width: 1),
                        ),
                        child: Column(
                          children: [
                            _DateRow(date: _dateText),
                            const SizedBox(height: 16),
                            _BreakdownSection(
                              rows: _rows,
                              progress: _rowProgress,
                              scores: _rowScores,
                              circleScales: _rowCircleScale,
                              naTexts: _rowNaTexts,
                            ),
                            if (_showBonusCard) ...[
                              const SizedBox(height: 12),
                              SizeTransition(
                                sizeFactor: _bonusCardAnim,
                                alignment: Alignment.topCenter,
                                child: FadeTransition(
                                  opacity: _bonusCardAnim,
                                  child: _BonusParametersCard(
                                    bonuses: _bonuses,
                                    total: _bonusTotal,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            const Divider(
                              height: 1,
                              thickness: 1,
                              color: _C.divider,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'MCT SCORE',
                              style: TextStyle(
                                color: _C.navy,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                                height: 1.1,
                              ),
                            ),
                            const Text(
                              'for today',
                              style: TextStyle(
                                color: _C.navySoft,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: Center(
                                child: _TotalRing(
                                  total: _totalDisplayed,
                                  ringProgress: _ringProgress,
                                  showConfetti: _showConfetti,
                                  confetti: _confettiCtrl,
                                ),
                              ),
                            ),
                            if (_showExcellentBadge) ...[
                              const SizedBox(height: 4),
                              _ExcellentBadge(),
                            ],
                            const SizedBox(height: 10),
                            _FooterBanner(
                              text: footerText,
                              centered: true,
                              showIcon: !(_showBonusCard && _bonusTotal != 0),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_showBonusPopup)
              Positioned.fill(
                child: _BonusEarnedOverlay(
                  bonuses: _bonuses,
                  onGotIt: _onGotIt,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final VoidCallback onClose;

  const _Header({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _C.cardBorder),
              ),
              child: const Icon(
                Icons.calendar_month_outlined,
                color: _C.blue,
                size: 18,
              ),
            ),
            const Expanded(
              child: Text(
                'MCT Score for Today',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _C.navy,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
            ),
            IconButton(
              onPressed: onClose,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              icon: const Icon(Icons.close, color: _C.navy, size: 22),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateRow extends StatelessWidget {
  final String date;

  const _DateRow({required this.date});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.calendar_today_outlined, size: 14, color: _C.blue),
        const SizedBox(width: 6),
        Text(
          date,
          style: const TextStyle(
            color: _C.navy,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

// ─── Breakdown ────────────────────────────────────────────────────────────────

class _BreakdownSection extends StatelessWidget {
  final List<_RowData> rows;
  final List<double> progress;
  final List<double> scores;
  final List<double> circleScales;
  final List<String> naTexts;

  const _BreakdownSection({
    required this.rows,
    required this.progress,
    required this.scores,
    required this.circleScales,
    required this.naTexts,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(rows.length, (i) {
        return Padding(
          padding: EdgeInsets.only(bottom: i == rows.length - 1 ? 0 : 22),
          child: _ScoreRow(
            letter: rows[i].letter,
            label: rows[i].label,
            progress: progress[i],
            score: scores[i],
            circleScale: circleScales[i],
            showAsNa: rows[i].showAsNa,
            naLabel: rows[i].showAsNa
                ? (naTexts.length > i ? naTexts[i] : '')
                : rows[i].naLabel,
          ),
        );
      }),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  final String letter;
  final String label;
  final double progress;
  final double score;
  final double circleScale;
  final bool showAsNa;
  final String naLabel;

  const _ScoreRow({
    required this.letter,
    required this.label,
    required this.progress,
    required this.score,
    required this.circleScale,
    this.showAsNa = false,
    this.naLabel = 'N/A',
  });

  @override
  Widget build(BuildContext context) {
    final scoreText = showAsNa ? naLabel : DmtScoreCard.formatNumber(score);
    final isNeg = !showAsNa && DmtScoreCard.isNegative(score);
    final scoreColor = isNeg ? _C.danger : _C.navy;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Transform.scale(
          scale: circleScale.clamp(0.0, 1.12),
          child: Opacity(
            opacity: circleScale.clamp(0.0, 1.0),
            child: _OutlinedLetter(letter: letter, size: 36),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: _C.navy,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 7),
              if (showAsNa)
                Text(
                  scoreText.isEmpty ? ' ' : scoreText,
                  style: TextStyle(
                    color: scoreColor,
                    fontSize: naLabel.length > 8 || scoreText.length > 8
                        ? 12
                        : 15,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: _ProgressBar(
                        progress: progress,
                        isNegative: isNeg,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      scoreText,
                      style: TextStyle(
                        color: scoreColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        height: 1,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final double progress;
  final bool isNegative;

  const _ProgressBar({
    required this.progress,
    this.isNegative = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 7,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: _C.barTrack),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress.clamp(0.0, 1.0),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: isNegative
                        ? const [Color(0xFFEF9A9A), _C.danger]
                        : const [
                            _C.barBlueStart,
                            _C.barBlueStart,
                            _C.barBlueEnd,
                          ],
                    stops: isNegative
                        ? null
                        : const [0.0, 0.82, 1.0],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Outlined circle + blue letter (matches mock — not filled).
class _OutlinedLetter extends StatelessWidget {
  final String letter;
  final double size;

  const _OutlinedLetter({required this.letter, this.size = 32});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: _C.blue, width: 1.6),
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: TextStyle(
          color: _C.blue,
          fontSize: size * 0.40,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }
}

// ─── Bonus parameters ─────────────────────────────────────────────────────────

class _BonusParametersCard extends StatelessWidget {
  final List<_BonusItem> bonuses;
  final double total;

  const _BonusParametersCard({
    required this.bonuses,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: _C.bonusCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.cardBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: _C.blue, size: 14),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Bonus Parameters',
                  style: TextStyle(
                    color: _C.blue,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                DmtScoreCard.formatSignedBonus(total),
                style: TextStyle(
                  color: total < 0 ? _C.danger : _C.green,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...bonuses.map(
            (b) => Padding(
              padding: const EdgeInsets.only(top: 3, left: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      b.title,
                      style: const TextStyle(
                        color: _C.navySoft,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    DmtScoreCard.formatSignedBonus(b.points),
                    style: TextStyle(
                      color: b.points < 0 ? _C.danger : _C.green,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Ring ─────────────────────────────────────────────────────────────────────

class _TotalRing extends StatelessWidget {
  final double total;
  final double ringProgress;
  final bool showConfetti;
  final AnimationController confetti;

  const _TotalRing({
    required this.total,
    required this.ringProgress,
    required this.showConfetti,
    required this.confetti,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = math.min(constraints.maxWidth, constraints.maxHeight);
        // Keep ring large like the mock (dominant visual).
        final ring = side.clamp(160.0, 200.0);
        return SizedBox(
          width: ring + 36,
          height: ring + 36,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              if (showConfetti)
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: confetti,
                    builder: (_, __) => CustomPaint(
                      painter: _BurstConfettiPainter(progress: confetti.value),
                    ),
                  ),
                ),
              SizedBox(
                width: ring,
                height: ring,
                child: CustomPaint(
                  painter: _RingPainter(progress: ringProgress),
                  child: Center(
                    child: Text(
                      DmtScoreCard.formatNumber(total),
                      style: TextStyle(
                        color: total < 0 ? _C.danger : _C.navy,
                        fontSize: ring * 0.30,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;

  _RingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final stroke = size.shortestSide * 0.065;
    final radius = (size.shortestSide - stroke) / 2;

    final track = Paint()
      ..color = _C.ringTrack
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    final fill = Paint()
      ..shader = const LinearGradient(
        colors: [_C.blueMid, _C.blue],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, track);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress.clamp(0.0, 1.0),
      false,
      fill,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.progress != progress;
}

class _BurstConfettiPainter extends CustomPainter {
  final double progress;

  _BurstConfettiPainter({required this.progress});

  static const _colors = [
    Color(0xFF1B6BF9),
    Color(0xFFFBBF24),
    Color(0xFFF472B6),
    Color(0xFF34D399),
    Color(0xFFFF8A65),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final rnd = math.Random(7);
    final cx = size.width / 2;
    final cy = size.height / 2;
    final t = Curves.easeOut.transform(progress.clamp(0.0, 1.0));
    final fade = (1.0 - progress).clamp(0.0, 1.0);

    for (var i = 0; i < 26; i++) {
      final angle = (i / 26) * math.pi * 2 + rnd.nextDouble() * 0.35;
      final dist = size.shortestSide * 0.38 + rnd.nextDouble() * 18;
      final x = cx + math.cos(angle) * dist * t;
      final y = cy + math.sin(angle) * dist * t;
      final paint = Paint()
        ..color = _colors[i % _colors.length].withValues(alpha: fade);
      final w = 2.5 + rnd.nextDouble() * 2.5;
      final h = 4.5 + rnd.nextDouble() * 3.5;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(angle + t);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: w, height: h),
          const Radius.circular(1),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _BurstConfettiPainter old) =>
      old.progress != progress;
}

class _ExcellentBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: _C.blueSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.blue.withValues(alpha: 0.35)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome, size: 12, color: _C.blue),
          SizedBox(width: 5),
          Text(
            'Excellent Discipline!',
            style: TextStyle(
              color: _C.blue,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Footer ───────────────────────────────────────────────────────────────────

class _FooterBanner extends StatelessWidget {
  final String text;
  final bool centered;
  final bool showIcon;

  const _FooterBanner({
    required this.text,
    this.centered = false,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    final textStyle = const TextStyle(
      color: _C.blue,
      fontSize: 14,
      fontWeight: FontWeight.w600,
      height: 1.35,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _C.blueBanner,
        borderRadius: BorderRadius.circular(12),
      ),
      child: centered
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (showIcon) ...[
                  const Icon(Icons.auto_awesome, color: _C.blue, size: 16),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    text,
                    textAlign: TextAlign.center,
                    style: textStyle,
                  ),
                ),
              ],
            )
          : Row(
              children: [
                if (showIcon) ...[
                  const Icon(Icons.auto_awesome, color: _C.blue, size: 16),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(text, style: textStyle),
                ),
              ],
            ),
    );
  }
}

// ─── Bonus earned overlay ─────────────────────────────────────────────────────

class _BonusEarnedOverlay extends StatefulWidget {
  final List<_BonusItem> bonuses;
  final VoidCallback onGotIt;

  const _BonusEarnedOverlay({
    required this.bonuses,
    required this.onGotIt,
  });

  @override
  State<_BonusEarnedOverlay> createState() => _BonusEarnedOverlayState();
}

class _BonusEarnedOverlayState extends State<_BonusEarnedOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final AnimationController _giftCtrl;
  late final AnimationController _confettiCtrl;
  late final Animation<double> _scale;
  late final Animation<double> _fade;
  late final Animation<double> _giftBounce;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _giftCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
    _confettiCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    );
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack);
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    // Gentle continuous bounce while popup stays open.
    _giftBounce = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.12), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.12, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _giftCtrl, curve: Curves.easeInOut));
    _ctrl.forward();
    _giftCtrl.repeat();
    _loopConfetti();
  }

  Future<void> _loopConfetti() async {
    await Future<void>.delayed(const Duration(milliseconds: 80));
    while (mounted) {
      await _confettiCtrl.forward(from: 0);
      if (!mounted) return;
      await Future<void>.delayed(const Duration(milliseconds: 220));
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _giftCtrl.dispose();
    _confettiCtrl.dispose();
    super.dispose();
  }

  String get _subtitle {
    final names = widget.bonuses.map((b) => b.title).toList();
    if (names.isEmpty) return 'You earned a bonus today';
    if (names.length == 1) return 'You earned bonus for\n${names.first}';
    return 'You earned bonus for\n${names.join(' and ')}';
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: Container(
        color: Colors.black.withValues(alpha: 0.50),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.88, end: 1).animate(_scale),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            clipBehavior: Clip.none,
            elevation: 16,
            shadowColor: Colors.black38,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 150,
                    width: 180,
                    child: _GiftHero(
                      bounce: _giftBounce,
                      confetti: _confettiCtrl,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Bonus Earned!',
                    style: TextStyle(
                      color: _C.blue,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _subtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF2F3548),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ...List.generate(widget.bonuses.length, (i) {
                    final b = widget.bonuses[i];
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: i == widget.bonuses.length - 1 ? 0 : 10,
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                        decoration: BoxDecoration(
                          color: _C.blueBanner,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _C.cardBorder),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _OutlinedLetter(letter: b.letter, size: 36),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    b.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: _C.navy,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    b.description,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFF4A5168),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            SizedBox(
                              width: 48,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 1),
                                child: Text(
                                  DmtScoreCard.formatSignedBonus(b.points),
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    color: b.points < 0 ? _C.danger : _C.blue,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                    decoration: BoxDecoration(
                      color: _C.blueBanner,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _C.cardBorder),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 36,
                          height: 36,
                          child: Center(
                            child: Icon(
                              Icons.auto_awesome,
                              color: _C.blue,
                              size: 20,
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Bonus for maintaining discipline throughout the day.',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Color(0xFF4A5168),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              height: 1.3,
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        SizedBox(width: 48),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFF4CA3FF),
                            Color(0xFF1B6BF9),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _C.blue.withValues(alpha: 0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: widget.onGotIt,
                          borderRadius: BorderRadius.circular(14),
                          child: const Center(
                            child: Text(
                              'Got it!',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GiftHero extends StatelessWidget {
  final Animation<double> bounce;
  final AnimationController confetti;

  const _GiftHero({
    required this.bounce,
    required this.confetti,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([bounce, confetti]),
      builder: (context, _) {
        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _BurstConfettiPainter(progress: confetti.value),
              ),
            ),
            Transform.scale(
              scale: bounce.value,
              child: CustomPaint(
                size: const Size(112, 112),
                painter: _GiftBoxPainter(),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GiftBoxPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final boxTop = h * 0.38;
    final boxPaint = Paint()..color = const Color(0xFFF7FAFD);
    final border = Paint()
      ..color = const Color(0xFFD5E2F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    final box = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.14, boxTop, w * 0.72, h * 0.50),
      const Radius.circular(5),
    );
    canvas.drawRRect(box, boxPaint);
    canvas.drawRRect(box, border);

    final lid = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.10, h * 0.28, w * 0.80, h * 0.13),
      const Radius.circular(4),
    );
    canvas.drawRRect(lid, boxPaint);
    canvas.drawRRect(lid, border);

    final ribbon = Paint()..color = _C.blue;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.45, boxTop, w * 0.10, h * 0.50),
        const Radius.circular(1.5),
      ),
      ribbon,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.45, h * 0.28, w * 0.10, h * 0.13),
        const Radius.circular(1.5),
      ),
      ribbon,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.14, h * 0.54, w * 0.72, h * 0.08),
        const Radius.circular(1.5),
      ),
      ribbon,
    );

    final bow = Paint()..color = _C.blueDark;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.38, h * 0.22),
        width: w * 0.20,
        height: h * 0.13,
      ),
      bow,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.62, h * 0.22),
        width: w * 0.20,
        height: h * 0.13,
      ),
      bow,
    );
    canvas.drawCircle(Offset(w * 0.5, h * 0.24), w * 0.055, ribbon);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
