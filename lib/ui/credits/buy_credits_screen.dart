import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../common/credits_colors.dart';
import '../../controller/credits_controller.dart';
import '../widgets/staggered_entrance.dart';
import 'widgets/coupon_input_section.dart';
import 'widgets/credit_gradient_button.dart';
import 'widgets/credit_package_card.dart';
import 'widgets/credits_header_avatar.dart';
import 'widgets/payment_success_dialog.dart';
import 'widgets/price_summary.dart';

class BuyCreditsScreen extends StatefulWidget {
  const BuyCreditsScreen({super.key});

  @override
  State<BuyCreditsScreen> createState() => _BuyCreditsScreenState();
}

class _BuyCreditsScreenState extends State<BuyCreditsScreen> {
  late final CreditsController _controller;
  late final TextEditingController _couponController;

  @override
  void initState() {
    super.initState();
    _controller = CreditsController.to;
    _controller.resetBuyState();
    _couponController = TextEditingController();
  }

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  Future<void> _openCouponSheet() async {
    final selected = await showSelectCouponBottomSheet(
      context: context,
      controller: _controller,
    );
    if (selected != null) {
      _controller.selectCoupon(selected);
      _couponController.text = selected.code;
    }
  }

  Future<void> _onBuyNow() async {
    FocusScope.of(context).unfocus();
    final result = await _controller.purchaseSelected();
    if (!mounted) return;
    if (!result.ok) {
      Get.snackbar('Purchase failed', result.error ?? 'Something went wrong');
      return;
    }
    await showPaymentSuccessDialog(context: context, result: result);
    if (!mounted) return;
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CreditsColors.scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  children: [
                    StaggeredEntrance(index: 0, child: _buildHero()),
                    const SizedBox(height: 20),
                    Column(
                      children: [
                        for (var i = 0; i < _controller.packages.length; i++)
                          StaggeredEntrance(
                            key: ValueKey(_controller.packages[i].id),
                            index: i + 1,
                            child: Obx(
                              () => CreditPackageCard(
                                package: _controller.packages[i],
                                selected:
                                    _controller.selectedPackageId.value ==
                                        _controller.packages[i].id,
                                onTap: () => _controller.selectPackage(
                                  _controller.packages[i].id,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    StaggeredEntrance(
                      index: 5,
                      child: Obx(
                        () => CouponInputSection(
                          codeController: _couponController,
                          appliedCoupon: _controller.appliedCoupon.value,
                          errorText: _controller.couponError.value,
                          discountAmount: _controller.discountAmount,
                          onApply: () {
                            FocusScope.of(context).unfocus();
                            _controller
                                .applyCouponCode(_couponController.text);
                          },
                          onRemove: () {
                            _controller.removeCoupon();
                            _couponController.clear();
                          },
                          onSelectCoupon: _openCouponSheet,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    StaggeredEntrance(
                      index: 6,
                      child: Obx(
                        () => PriceSummary(
                          subtotal: _controller.subtotal,
                          discount: _controller.discountAmount,
                          amountToPay: _controller.amountToPay,
                          coupon: _controller.appliedCoupon.value,
                          bonusCredits: _controller.bonusCredits,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    StaggeredEntrance(
                      index: 7,
                      child: Obx(() {
                        final amount = _controller.amountToPay;
                        final hasCoupon =
                            _controller.appliedCoupon.value != null &&
                                _controller.discountAmount > 0;
                        final label =
                            hasCoupon ? 'Buy Now | ₹$amount' : 'Buy Now';
                        return CreditGradientButton(
                          label: label,
                          isLoading: _controller.isPurchasing.value,
                          onPressed: _onBuyNow,
                        );
                      }),
                    ),
                    const SizedBox(height: 12),
                    const StaggeredEntrance(
                      index: 8,
                      child: SecurePaymentFooter(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Get.back(),
                icon: const Icon(Icons.close, size: 24),
                color: CreditsColors.textPrimary,
              ),
              const Expanded(
                child: Text(
                  'Buy AI Credits',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: CreditsColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SecurePaymentFooter(text: 'Secure Payment'),
        ],
      ),
    );
  }

  Widget _buildHero() {
    return Column(
      children: [
        const SizedBox(height: 12),
        Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
            color: CreditsColors.lightPurple,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.shopping_bag_outlined,
            color: CreditsColors.purple,
            size: 30,
          ),
        ),
        const SizedBox(height: 12),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Choose a credit package that suits your trading journey.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: CreditsColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
