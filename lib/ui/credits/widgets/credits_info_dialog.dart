import 'package:flutter/material.dart';
import 'package:discipline_mind/ui/widgets/app_motion.dart';

import '../../../common/credits_colors.dart';
import '../../../controller/credits_controller.dart';

/// "About AI Credits" explainer, opened from the info icon on the credits
/// screen.
///
/// Everything it states is derived from real app behaviour - the Believe Mode
/// figure comes from the controller rather than being written into the copy.
Future<void> showCreditsInfoDialog({
  required BuildContext context,
  required int weeklyBelieveModeCredits,
  VoidCallback? onBuyCredits,
}) {
  return showAppDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (ctx) => _CreditsInfoDialog(
      weeklyBelieveModeCredits: weeklyBelieveModeCredits,
      onBuyCredits: onBuyCredits,
    ),
  );
}

class _CreditsInfoDialog extends StatelessWidget {
  const _CreditsInfoDialog({
    required this.weeklyBelieveModeCredits,
    this.onBuyCredits,
  });

  final int weeklyBelieveModeCredits;
  final VoidCallback? onBuyCredits;

  @override
  Widget build(BuildContext context) {
    final weekly = CreditsController.formatCreditsPlain(
      weeklyBelieveModeCredits,
    );

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 26, vertical: 24),
      child: Container(
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
            _Header(onClose: () => Navigator.of(context).pop()),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'What AI Credits are for',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                      color: CreditsColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _FeatureList(weekly: weekly),
                  const SizedBox(height: 16),
                  const _FootNote(
                    text:
                        'Credits are only spent on Zeno AI features. Blocking '
                        'and your trade alerts always keep working.',
                  ),
                  const SizedBox(height: 20),
                  _PrimaryButton(
                    label: 'Got it',
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  if (onBuyCredits != null) ...[
                    const SizedBox(height: 2),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onBuyCredits!();
                      },
                      child: const Text(
                        'Buy more credits',
                        style: TextStyle(
                          color: CreditsColors.purple,
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Gradient banner with the badge, title and a close affordance.
class _Header extends StatelessWidget {
  const _Header({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 18, 10, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF3EEFF), Color(0xFFE8F1FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.topRight,
            child: InkWell(
              onTap: onClose,
              borderRadius: BorderRadius.circular(20),
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(
                  Icons.close_rounded,
                  size: 20,
                  color: CreditsColors.textSecondary,
                ),
              ),
            ),
          ),
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: CreditsColors.purple.withValues(alpha: 0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              size: 28,
              color: CreditsColors.purple,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'About AI Credits',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: CreditsColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              'Credits power the Zeno AI features that keep your trading '
              'disciplined.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: CreditsColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureList extends StatelessWidget {
  const _FeatureList({required this.weekly});

  final String weekly;

  @override
  Widget build(BuildContext context) {
    final rows = <({IconData icon, String title, String body})>[
      (
        icon: Icons.shield_moon_outlined,
        title: 'Believe Mode',
        body: '$weekly credits are used each week it stays active.',
      ),
      (
        icon: Icons.forum_outlined,
        title: 'Chat insights',
        body: 'Ask Zeno AI about any trade, signal or market move.',
      ),
      (
        icon: Icons.insights_rounded,
        title: 'Discipline analysis',
        body: 'Your DMT score and the reviews behind it.',
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: CreditsColors.scaffoldBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CreditsColors.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0)
              const Divider(height: 1, thickness: 1, color: Color(0xFFEDEFF3)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: CreditsColors.lightPurple,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(
                      rows[i].icon,
                      size: 19,
                      color: CreditsColors.purple,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rows[i].title,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: CreditsColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          rows[i].body,
                          style: const TextStyle(
                            fontSize: 12.5,
                            height: 1.4,
                            color: CreditsColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FootNote extends StatelessWidget {
  const _FootNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: CreditsColors.successBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CreditsColors.successBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.verified_user_outlined,
            size: 18,
            color: CreditsColors.success,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                height: 1.45,
                color: Color(0xFF065F46),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
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
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
