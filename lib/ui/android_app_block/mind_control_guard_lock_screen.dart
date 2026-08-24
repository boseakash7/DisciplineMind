import 'package:flutter/material.dart';

/// Mind Control Guard lock screen shown over blocked trading apps.
class MindControlGuardLockScreen extends StatelessWidget {
  final bool hasActiveTrade;
  final VoidCallback onWillControl;
  final VoidCallback onSkip;

  const MindControlGuardLockScreen({
    super.key,
    required this.hasActiveTrade,
    required this.onWillControl,
    required this.onSkip,
  });

  static const _navy = Color(0xFF16161D);
  static const _purple = Color(0xFF7C3AED);
  static const _purpleBright = Color(0xFF8B5CF6);
  static const _purpleDeep = Color(0xFF5B21B6);
  static const _blue = Color(0xFF3B82F6);
  static const _secondary = Color(0xFF4B5563);
  static const _line = Color(0xFFD8B4FE);
  static const _cardBg = Color(0xFFFAF8FF);
  static const _cardBorder = Color(0xFFEDE9FE);
  static const _iconCircle = Color(0xFFF3EEFF);
  static const _statusIconBg = Color(0xFFEEF2FF);

  static const _brainAsset = 'assets/no_bg_icon.png';

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return ColoredBox(
      color: Colors.white,
      child: Stack(
        children: [
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 280,
            child: CustomPaint(painter: _LockScreenBackdropPainter()),
          ),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        const Text(
                          'MIND CONTROL GUARD',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _navy,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _linedLabel(
                          child: const Text(
                            'is Active',
                            style: TextStyle(
                              color: _purple,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _brainBadge(),
                        const SizedBox(height: 14),
                        _poweredBy(),
                        const SizedBox(height: 28),
                        _statusSection(),
                        const SizedBox(height: 20),
                        Container(width: 56, height: 1, color: _line),
                        const SizedBox(height: 20),
                        _infoCard(),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(20, 10, 20, 14 + bottomInset),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: _controlButton(),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: _skipButton(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _brainBadge() {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(
          color: const Color(0xFFE9DDFC),
          width: 2,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: ClipOval(
        child: Image.asset(
          _brainAsset,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Icon(
            Icons.psychology_rounded,
            size: 56,
            color: _purple,
          ),
        ),
      ),
    );
  }

  Widget _poweredBy() {
    return Row(
      children: [
        Expanded(child: _fadeLine(toRight: true)),
        const SizedBox(width: 14),
        const Text(
          'Powered by ',
          style: TextStyle(
            color: _secondary,
            fontSize: 13,
            fontWeight: FontWeight.w400,
          ),
        ),
        const Text(
          'zeno',
          style: TextStyle(
            color: _navy,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            gradient: const LinearGradient(colors: [_blue, _purpleBright]),
          ),
          child: const Text(
            'AI',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(child: _fadeLine(toRight: false)),
      ],
    );
  }

  Widget _statusSection() {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
            color: _statusIconBg,
            shape: BoxShape.circle,
          ),
          child: Icon(
            hasActiveTrade
                ? Icons.bolt_rounded
                : Icons.hourglass_empty_rounded,
            color: _purple,
            size: 38,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          hasActiveTrade ? 'Trade is active' : 'No new signal yet',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _purple,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          hasActiveTrade
              ? 'from the Analyst — stick to the plan'
              : 'from the Analyst',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _navy,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _infoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: _iconCircle,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.gps_fixed_rounded,
              color: _purple,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _cardTitle(),
                const SizedBox(height: 6),
                _cardBody(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardTitle() {
    if (hasActiveTrade) {
      return Text.rich(
        TextSpan(
          style: const TextStyle(
            color: _navy,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            height: 1.35,
          ),
          children: [
            const TextSpan(text: 'Protect the '),
            TextSpan(
              text: 'live trade',
              style: const TextStyle(
                color: _purpleDeep,
                fontWeight: FontWeight.w800,
              ),
            ),
            const TextSpan(text: '.'),
          ],
        ),
      );
    }
    return Text.rich(
      TextSpan(
        style: const TextStyle(
          color: _navy,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          height: 1.35,
        ),
        children: [
          const TextSpan(text: 'Save yourself\nfrom '),
          TextSpan(
            text: 'FOMO',
            style: const TextStyle(
              color: _purpleDeep,
              fontWeight: FontWeight.w800,
            ),
          ),
          const TextSpan(text: '.'),
        ],
      ),
    );
  }

  Widget _cardBody() {
    if (hasActiveTrade) {
      return Text.rich(
        TextSpan(
          style: const TextStyle(
            color: _secondary,
            fontSize: 13,
            fontWeight: FontWeight.w400,
            height: 1.45,
          ),
          children: [
            const TextSpan(text: "Stay with the "),
            TextSpan(
              text: "Analyst's plan",
              style: const TextStyle(
                color: _purpleDeep,
                fontWeight: FontWeight.w700,
              ),
            ),
            const TextSpan(text: ",\nnot the next candle."),
          ],
        ),
      );
    }
    return Text.rich(
      TextSpan(
        style: const TextStyle(
          color: _secondary,
          fontSize: 13,
          fontWeight: FontWeight.w400,
          height: 1.45,
        ),
        children: [
          const TextSpan(text: 'Mind control traders\nwait for '),
          TextSpan(
            text: 'right signal',
            style: const TextStyle(
              color: _purpleDeep,
              fontWeight: FontWeight.w700,
            ),
          ),
          const TextSpan(text: ', not the noise.'),
        ],
      ),
    );
  }

  Widget _controlButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onWillControl,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          height: 62,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(colors: [_blue, _purpleBright]),
            boxShadow: const [
              BoxShadow(
                color: Color(0x337C3AED),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shield_outlined, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'I WILL CONTROL',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _skipButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onSkip,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          height: 62,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _purpleBright, width: 1.5),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'SKIP',
                style: TextStyle(
                  color: _navy,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  letterSpacing: 0.6,
                ),
              ),
              SizedBox(width: 6),
              Icon(Icons.arrow_forward_rounded, color: _purple, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _linedLabel({required Widget child}) {
    return Row(
      children: [
        Expanded(child: _fadeLine(toRight: true)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: child,
        ),
        Expanded(child: _fadeLine(toRight: false)),
      ],
    );
  }

  /// Short line that fades out at the outer end.
  /// [toRight] = true means the solid end is on the right (near text)
  /// and fades toward the left edge.
  Widget _fadeLine({required bool toRight}) {
    return Container(
      height: 1,
      constraints: const BoxConstraints(maxWidth: 80),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: toRight
              ? [_line.withValues(alpha: 0), _line]
              : [_line, _line.withValues(alpha: 0)],
        ),
      ),
    );
  }
}

class _LockScreenBackdropPainter extends CustomPainter {
  const _LockScreenBackdropPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final candle = Paint()
      ..color = const Color(0x22A78BFA)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    void stick(double x, double top, double bodyH) {
      canvas.drawLine(
        Offset(x, top - 8),
        Offset(x, top + bodyH + 8),
        candle,
      );
      canvas.drawRect(Rect.fromLTWH(x - 5, top, 10, bodyH), candle);
    }

    stick(22, 118, 38);
    stick(42, 98, 58);
    stick(62, 128, 28);
    stick(size.width - 62, 124, 36);
    stick(size.width - 42, 92, 64);
    stick(size.width - 22, 132, 24);

    final wave = Paint()
      ..color = const Color(0x1EC4B5FD)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    for (final y in [size.height * 0.72, size.height * 0.80]) {
      final path = Path()..moveTo(0, y);
      path.cubicTo(
        size.width * 0.25,
        y - 16,
        size.width * 0.5,
        y + 18,
        size.width,
        y - 4,
      );
      canvas.drawPath(path, wave);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
