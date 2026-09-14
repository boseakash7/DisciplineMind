import 'package:flutter/material.dart';

import '../../../common/credits_colors.dart';
import '../../../model/credits_models.dart';

class CreditPackageCard extends StatelessWidget {
  final CreditPackage package;
  final bool selected;
  final VoidCallback onTap;

  const CreditPackageCard({
    super.key,
    required this.package,
    required this.selected,
    required this.onTap,
  });

  static const _selectedGradient = LinearGradient(
    colors: [Color(0xFFE8F1FF), Color(0xFFF0E7FF)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  @override
  Widget build(BuildContext context) {
    final hasBadge = package.badge != null;
    // Last package (with badge) is taller to fit the extra content.
    final cardHeight = hasBadge ? 102.0 : 78.0;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        margin: const EdgeInsets.only(bottom: 10),
        height: cardHeight,
        decoration: BoxDecoration(
          gradient: selected ? _selectedGradient : null,
          color: selected ? null : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? CreditsColors.purple : CreditsColors.border,
            width: selected ? 1.6 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: CreditsColors.purple.withValues(alpha: 0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(14, 0, 14, hasBadge ? 26 : 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _RadioDot(selected: selected),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${package.formattedCredits} AI Credits',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: CreditsColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          package.subtitle,
                          style: const TextStyle(
                            fontSize: 12,
                            color: CreditsColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    package.formattedPrice,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? CreditsColors.purple
                          : CreditsColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            // Badge always visible on packages that have one (selected or not).
            if (hasBadge)
              Positioned(
                right: 12,
                bottom: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: CreditsColors.lightPurple,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: CreditsColors.purple.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    package.badge!,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: CreditsColors.purple,
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

class _RadioDot extends StatelessWidget {
  final bool selected;

  const _RadioDot({required this.selected});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? CreditsColors.purple : Colors.transparent,
        border: Border.all(
          color: selected ? CreditsColors.purple : const Color(0xFFCBD5E1),
          width: 2,
        ),
      ),
      child: selected
          ? const Center(
              child: Icon(Icons.circle, size: 8, color: Colors.white),
            )
          : null,
    );
  }
}
