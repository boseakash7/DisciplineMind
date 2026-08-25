import 'package:flutter/material.dart';

import '../../../common/credits_colors.dart';
import '../../../model/credits_models.dart';

class CouponInputSection extends StatelessWidget {
  final TextEditingController codeController;
  final CreditCoupon? appliedCoupon;
  final String? errorText;
  final int discountAmount;
  final VoidCallback onApply;
  final VoidCallback onRemove;
  final VoidCallback onSelectCoupon;

  const CouponInputSection({
    super.key,
    required this.codeController,
    required this.appliedCoupon,
    required this.errorText,
    required this.discountAmount,
    required this.onApply,
    required this.onRemove,
    required this.onSelectCoupon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.local_offer_outlined,
                size: 18, color: CreditsColors.purple),
            SizedBox(width: 6),
            Text(
              'Apply Coupon',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: CreditsColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (appliedCoupon != null)
          _AppliedCouponCard(
            coupon: appliedCoupon!,
            discountAmount: discountAmount,
            onRemove: onRemove,
          )
        else ...[
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: codeController,
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter coupon code',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontWeight: FontWeight.w400,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: CreditsColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: CreditsColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: CreditsColors.purple,
                        width: 1.4,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: onApply,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CreditsColors.purple,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Apply',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
          if (errorText != null && errorText!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              errorText!,
              style: const TextStyle(
                color: CreditsColors.danger,
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: Divider(color: Colors.grey.shade300)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'or',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(child: Divider(color: Colors.grey.shade300)),
            ],
          ),
          const SizedBox(height: 14),
          InkWell(
            onTap: onSelectCoupon,
            borderRadius: BorderRadius.circular(12),
            child: Ink(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: CreditsColors.border),
              ),
              child: const Row(
                children: [
                  Icon(Icons.confirmation_number_outlined,
                      color: CreditsColors.purple, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Select a Coupon',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: CreditsColors.textPrimary,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right, color: CreditsColors.textSecondary),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _AppliedCouponCard extends StatelessWidget {
  final CreditCoupon coupon;
  final int discountAmount;
  final VoidCallback onRemove;

  const _AppliedCouponCard({
    required this.coupon,
    required this.discountAmount,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final detail = coupon.type == CouponType.bonusCredits
        ? '+${coupon.value} bonus credits applied'
        : '₹$discountAmount discount applied';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: CreditsColors.successBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CreditsColors.successBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_offer, color: CreditsColors.success, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      coupon.code,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: CreditsColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD1FAE5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Applied',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: CreditsColors.success,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: const TextStyle(
                    fontSize: 12,
                    color: CreditsColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onRemove,
            style: TextButton.styleFrom(
              foregroundColor: CreditsColors.danger,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Remove',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
