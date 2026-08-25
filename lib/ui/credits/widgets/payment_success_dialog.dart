import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../controller/credits_controller.dart';

Future<void> showPaymentSuccessDialog({
  required BuildContext context,
  required PurchaseResult result,
}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: const Color(0xCC2A2A2A),
    builder: (_) => PaymentSuccessDialog(result: result),
  );
}

class PaymentSuccessDialog extends StatelessWidget {
  final PurchaseResult result;

  const PaymentSuccessDialog({super.key, required this.result});

  static const _checkBg = Color(0xFFE8F5E9);
  static const _checkColor = Color(0xFF2E7D32);
  static const _balanceGreen = Color(0xFF2E7D32);
  static const _titleColor = Color(0xFF111827);
  static const _bodyColor = Color(0xFF4B5563);
  static const _mutedColor = Color(0xFF9CA3AF);
  static const _dividerColor = Color(0xFFE5E7EB);
  static const _buttonGradient = LinearGradient(
    colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  @override
  Widget build(BuildContext context) {
    final added = CreditsController.formatCreditsPlain(result.creditsAdded);
    final prev = CreditsController.formatCreditsPlain(result.previousBalance);
    final next = CreditsController.formatCreditsPlain(result.newBalance);

    return Dialog(
      backgroundColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 96,
              width: 120,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  ..._confetti(),
                  Container(
                    width: 68,
                    height: 68,
                    decoration: const BoxDecoration(
                      color: _checkBg,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: _checkColor,
                      size: 36,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Payment Successful!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: _titleColor,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '$added AI Credits added successfully\nto your account.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                height: 1.45,
                fontWeight: FontWeight.w500,
                color: _bodyColor,
              ),
            ),
            const SizedBox(height: 22),
            const Divider(height: 1, thickness: 1, color: _dividerColor),
            const SizedBox(height: 20),
            const Text(
              'Updated Balance',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _titleColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$next Credits',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: _balanceGreen,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '($prev + $added)',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: _mutedColor,
              ),
            ),
            const SizedBox(height: 26),
            _GreatButton(onPressed: () => Navigator.of(context).pop()),
          ],
        ),
      ),
    );
  }

  List<Widget> _confetti() {
    // Soft confetti matching the success screenshot (dots + diamonds).
    const pieces = <_ConfettiPiece>[
      _ConfettiPiece(Offset(-42, -18), Color(0xFFC4B5FD), 5, false),
      _ConfettiPiece(Offset(-28, -34), Color(0xFFF9A8D4), 4, true),
      _ConfettiPiece(Offset(-10, -40), Color(0xFF5EEAD4), 5, false),
      _ConfettiPiece(Offset(14, -38), Color(0xFFFCD34D), 4, true),
      _ConfettiPiece(Offset(36, -28), Color(0xFFA78BFA), 5, false),
      _ConfettiPiece(Offset(44, -8), Color(0xFFD1D5DB), 4, true),
      _ConfettiPiece(Offset(40, 18), Color(0xFFF9A8D4), 4, false),
      _ConfettiPiece(Offset(28, 34), Color(0xFF5EEAD4), 5, true),
      _ConfettiPiece(Offset(-36, 22), Color(0xFFFCD34D), 4, false),
      _ConfettiPiece(Offset(-46, 4), Color(0xFFA78BFA), 4, true),
      _ConfettiPiece(Offset(0, 42), Color(0xFFD1D5DB), 3, false),
      _ConfettiPiece(Offset(-18, 36), Color(0xFFC4B5FD), 4, true),
    ];

    return pieces.map((p) {
      return Transform.translate(
        offset: p.offset,
        child: Transform.rotate(
          angle: p.isDiamond ? math.pi / 4 : 0,
          child: Container(
            width: p.size,
            height: p.size,
            decoration: BoxDecoration(
              color: p.color,
              borderRadius: BorderRadius.circular(p.isDiamond ? 1.5 : p.size),
            ),
          ),
        ),
      );
    }).toList();
  }
}

class _ConfettiPiece {
  final Offset offset;
  final Color color;
  final double size;
  final bool isDiamond;

  const _ConfettiPiece(this.offset, this.color, this.size, this.isDiamond);
}

class _GreatButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _GreatButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(28),
        child: Ink(
          height: 52,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: PaymentSuccessDialog._buttonGradient,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7C3AED).withValues(alpha: 0.28),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Center(
            child: Text(
              'Great!',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
