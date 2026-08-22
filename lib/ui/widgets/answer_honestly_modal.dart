import 'dart:ui';

import 'package:flutter/material.dart';

// ============================================================================
// ANSWER HONESTLY MODAL
// ============================================================================
// Standalone copy of the honesty modal used by the trading profile flow, so it
// can be shown from anywhere without depending on that screen's private
// widgets. Shown over a blurred + dimmed barrier.

const Color _purple = Color(0xFF4A22F4);
const Color _violet = Color(0xFF983BF4);
const Color _ink = Color(0xFF10122D);
const Color _bodyText = Color(0xFF6B6B7A);
const Color _highlight = Color(0xFF4F5DF7);

/// Shows the "Answer Honestly" modal with a blurred background barrier.
///
/// [onConfirm] runs after the modal is dismissed by the primary button.
/// [onCancel] runs after the modal is dismissed by the cancel button.
Future<void> showAnswerHonestlyModal(
  BuildContext context, {
  VoidCallback? onConfirm,
  VoidCallback? onCancel,
  bool barrierDismissible = false,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: barrierDismissible ? 'Dismiss' : null,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (_, __, ___) => const SizedBox.shrink(),
    transitionBuilder: (dialogContext, animation, _, __) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );

      return FadeTransition(
        opacity: curved,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 6 * animation.value,
            sigmaY: 6 * animation.value,
          ),
          child: Container(
            color: Colors.black.withValues(alpha: 0.35 * animation.value),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.94, end: 1).animate(curved),
              child: _AnswerHonestlyDialog(
                onConfirm: () {
                  Navigator.of(dialogContext).pop();
                  onConfirm?.call();
                },
                onCancel: () {
                  Navigator.of(dialogContext).pop();
                  onCancel?.call();
                },
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _AnswerHonestlyDialog extends StatelessWidget {
  const _AnswerHonestlyDialog({required this.onConfirm, required this.onCancel});

  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(28, 28, 28, 28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 98,
              height: 98,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFEAE6FF),
              ),
              child: const Icon(
                Icons.assignment_outlined,
                color: _purple,
                size: 58,
              ),
            ),

            const SizedBox(height: 14),

            const Text(
              'Answer Honestly',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _ink,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),

            Container(
              width: 28,
              height: 2,
              margin: const EdgeInsets.only(top: 12, bottom: 13),
              decoration: BoxDecoration(
                color: _purple,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            Text.rich(
              const TextSpan(
                children: [
                  TextSpan(
                    text: 'Please answer each question\n'
                        'carefully and truthfully.\n\n'
                        'Zeno AI will create your\n'
                        'personalized ',
                  ),
                  TextSpan(
                    text: 'Trading Profile',
                    style: TextStyle(color: _highlight),
                  ),
                  TextSpan(text: '\nbased on your responses.'),
                ],
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _bodyText,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.45,
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_purple, _violet],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x444A22F4),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: TextButton(
                  style: TextButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: onConfirm,
                  child: const Text(
                    'Ok, I Understand',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: TextButton(
                style: TextButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: onCancel,
                child: const Text(
                  'Cancel',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _bodyText,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
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
