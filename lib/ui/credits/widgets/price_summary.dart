import 'package:flutter/material.dart';

import '../../../common/credits_colors.dart';
import '../../../controller/credits_controller.dart';
import '../../../model/credits_models.dart';
import '../../widgets/staggered_entrance.dart';

class PriceSummary extends StatelessWidget {
  final int subtotal;
  final int discount;
  final int amountToPay;
  final CreditCoupon? coupon;
  final int bonusCredits;

  const PriceSummary({
    super.key,
    required this.subtotal,
    required this.discount,
    required this.amountToPay,
    this.coupon,
    this.bonusCredits = 0,
  });

  @override
  Widget build(BuildContext context) {
    final hasDiscount = coupon != null && discount > 0;
    final hasBonus = coupon != null && bonusCredits > 0;
    final showBreakdown = hasDiscount || hasBonus;

    return Column(
      children: [
        if (showBreakdown) ...[
          _row('Subtotal', '₹$subtotal'),
          if (hasDiscount) ...[
            const SizedBox(height: 8),
            _row(
              'Discount (${coupon!.code})',
              '-₹$discount',
              valueColor: CreditsColors.success,
            ),
          ],
          if (hasBonus) ...[
            const SizedBox(height: 8),
            _row(
              'Bonus Credits (${coupon!.code})',
              '+$bonusCredits',
              valueColor: CreditsColors.success,
            ),
          ],
          const SizedBox(height: 10),
          const Divider(height: 1, color: CreditsColors.border),
          const SizedBox(height: 10),
        ],
        _row(
          'Amount to Pay',
          '₹$amountToPay',
          isBold: true,
        ),
      ],
    );
  }

  Widget _row(
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 15 : 13,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: isBold
                ? CreditsColors.textPrimary
                : CreditsColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 16 : 14,
            fontWeight: FontWeight.w700,
            color: valueColor ?? CreditsColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

Future<CreditCoupon?> showSelectCouponBottomSheet({
  required BuildContext context,
  required CreditsController controller,
}) {
  return showModalBottomSheet<CreditCoupon>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => SelectCouponBottomSheet(controller: controller),
  );
}

class SelectCouponBottomSheet extends StatelessWidget {
  final CreditsController controller;

  const SelectCouponBottomSheet({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewPadding.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.72,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          StaggeredEntrance(
            index: 0,
            offsetY: 10,
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          StaggeredEntrance(
            index: 1,
            offsetY: 12,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Select a Coupon',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: CreditsColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
          ),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              itemCount: controller.coupons.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final coupon = controller.coupons[index];
                return StaggeredEntrance(
                  key: ValueKey(coupon.code),
                  index: index + 2,
                  offsetY: 16,
                  child: _CouponListItem(
                    coupon: coupon,
                    onTap: () => Navigator.pop(context, coupon),
                  ),
                );
              },
            ),
          ),
          StaggeredEntrance(
            index: controller.coupons.length + 2,
            offsetY: 12,
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottom),
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Enter coupon code manually',
                  style: TextStyle(
                    color: CreditsColors.purple,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CouponListItem extends StatelessWidget {
  final CreditCoupon coupon;
  final VoidCallback onTap;

  const _CouponListItem({required this.coupon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: CreditsColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: CreditsColors.lightPurple,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.confirmation_number_outlined,
                color: CreditsColors.purple,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    coupon.code,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: CreditsColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    coupon.description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: CreditsColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: CreditsColors.successBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                coupon.badgeLabel,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: CreditsColors.success,
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: CreditsColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
