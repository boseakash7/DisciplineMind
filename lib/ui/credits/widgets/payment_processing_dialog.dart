import 'package:flutter/material.dart';

import '../../../common/credits_colors.dart';
import '../../../controller/credits_controller.dart';

/// Shown when Razorpay confirmed the payment but the capture webhook has not
/// credited the coins yet.
///
/// Deliberately framed as reassurance rather than an error: the money is safe
/// and no further action is needed from the user.
Future<void> showPaymentProcessingDialog({
  required BuildContext context,
  required PurchaseResult result,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (ctx) => _PaymentProcessingDialog(result: result),
  );
}

class _PaymentProcessingDialog extends StatelessWidget {
  const _PaymentProcessingDialog({required this.result});

  final PurchaseResult result;

  @override
  Widget build(BuildContext context) {
    final coins = CreditsController.formatCreditsPlain(result.coinsExpected);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        decoration: BoxDecoration(
          color: CreditsColors.cardBg,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _ProcessingBadge(),
            const SizedBox(height: 20),
            const Text(
              'Payment received',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: CreditsColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'We have confirmed your payment of ₹${result.amountPaid}.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13.5,
                height: 1.5,
                color: CreditsColors.textSecondary,
              ),
            ),
            const SizedBox(height: 18),

            // The one fact that resolves the user's anxiety.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                color: CreditsColors.lightPurple,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: CreditsColors.lightPurpleBorder),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    size: 20,
                    color: CreditsColors.purple,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.45,
                          color: CreditsColors.textPrimary,
                        ),
                        children: [
                          TextSpan(
                            text: '$coins AI Credits ',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const TextSpan(
                            text: 'will be added to your balance shortly.',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  size: 13,
                  color: CreditsColors.textSecondary,
                ),
                SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Nothing else is needed from you.',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: CreditsColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: CreditsColors.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: CreditsColors.purple.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(14),
                    child: const Center(
                      child: Text(
                        'Got it',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
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
    );
  }
}

/// Animated ring around a tick, signalling "in progress" without a spinner
/// that would imply the user has to wait on this screen.
class _ProcessingBadge extends StatefulWidget {
  const _ProcessingBadge();

  @override
  State<_ProcessingBadge> createState() => _ProcessingBadgeState();
}

class _ProcessingBadgeState extends State<_ProcessingBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 78,
      height: 78,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 78,
            height: 78,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFFF3EEFF), Color(0xFFE8F1FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          SizedBox(
            width: 70,
            height: 70,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => CircularProgressIndicator(
                value: null,
                strokeWidth: 2.4,
                backgroundColor: Colors.white,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  CreditsColors.purple,
                ),
              ),
            ),
          ),
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 26,
              color: CreditsColors.success,
            ),
          ),
        ],
      ),
    );
  }
}
