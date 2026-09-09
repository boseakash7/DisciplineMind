import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../common/app_colors.dart';
import '../../../common/credits_colors.dart';
import '../../../controller/credits_controller.dart';
import '../ai_credits_screen.dart';

/// Tappable credits + avatar chip used in BM / Trades / Chat headers.
class CreditsHeaderAvatar extends StatelessWidget {
  const CreditsHeaderAvatar({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = CreditsController.to;

    return GestureDetector(
      onTap: () {
        Get.to(() => const AiCreditsScreen());
      },
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Obx(
            () => Text(
              'Credits: ${CreditsController.formatCreditsPlain(controller.balance.value)}',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 10),
          CircleAvatar(
            radius: 12,
            backgroundColor: Colors.grey.shade400,
            child: const Icon(Icons.person, size: 14, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

/// Shared secure-payment footer used on buy screens.
class SecurePaymentFooter extends StatelessWidget {
  final String text;

  const SecurePaymentFooter({
    super.key,
    this.text = '100% Secure Payments',
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.lock_outline, size: 14, color: CreditsColors.textSecondary),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: CreditsColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
