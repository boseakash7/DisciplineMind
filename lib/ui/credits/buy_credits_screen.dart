import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../common/credits_colors.dart';
import '../../controller/credits_controller.dart';
import '../widgets/staggered_entrance.dart';
import 'widgets/coupon_input_section.dart';
import 'widgets/credit_gradient_button.dart';
import 'widgets/credit_package_card.dart';
import 'widgets/credits_header_avatar.dart';
import 'widgets/credits_state_views.dart';
import 'widgets/payment_processing_dialog.dart';
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
  final ScrollController _packagesScrollController = ScrollController();

  /// Whether the package list actually overflows. Drives the scrollbar, so a
  /// short catalogue does not show a full-height thumb that cannot move.
  bool _packagesScrollable = false;

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
    _packagesScrollController.dispose();
    super.dispose();
  }

  /// Scroll metrics arrive during layout, so the rebuild is deferred to the
  /// next frame rather than called mid-build.
  void _updatePackagesScrollable(bool scrollable) {
    if (scrollable == _packagesScrollable) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || scrollable == _packagesScrollable) return;
      setState(() => _packagesScrollable = scrollable);
    });
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

    switch (result.outcome) {
      case PurchaseOutcome.success:
        await showPaymentSuccessDialog(context: context, result: result);
        if (!mounted) return;
        Get.back();

      case PurchaseOutcome.pending:
        // Signature verified, capture webhook still pending. Not an error.
        await showPaymentProcessingDialog(context: context, result: result);
        if (!mounted) return;
        Get.back();

      case PurchaseOutcome.cancelled:
        // User dismissed Razorpay. Stay put so they can retry, and keep the
        // tone neutral - nothing went wrong and nothing was charged.
        _showToast(
          icon: Icons.info_outline_rounded,
          background: CreditsColors.textPrimary,
          message: 'Payment cancelled. You have not been charged.',
        );

      case PurchaseOutcome.failed:
        _showToast(
          icon: Icons.error_outline_rounded,
          background: CreditsColors.danger,
          message: result.error ?? 'Something went wrong. Please try again.',
        );
    }
  }

  /// Floating pill toast, so feedback matches the rounded card language of
  /// the rest of this flow rather than a default square snackbar.
  void _showToast({
    required IconData icon,
    required Color background,
    required String message,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: background,
        elevation: 6,
        duration: const Duration(seconds: 4),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13.5,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CreditsColors.scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: StaggeredEntrance(index: 0, child: _buildHero()),
            ),
            const SizedBox(height: 20),

            // Only the package list scrolls. The coupon field, price summary
            // and Buy button stay pinned so the amount is always in view.
            Expanded(
              child: NotificationListener<ScrollMetricsNotification>(
                onNotification: (notification) {
                  _updatePackagesScrollable(
                    notification.metrics.maxScrollExtent > 0,
                  );
                  return false;
                },
                child: Scrollbar(
                  controller: _packagesScrollController,
                  thumbVisibility: _packagesScrollable,
                  radius: const Radius.circular(8),
                  thickness: 4,
                  child: SingleChildScrollView(
                    controller: _packagesScrollController,
                    padding: EdgeInsets.fromLTRB(
                      16,
                      0,
                      _packagesScrollable ? 10 : 16,
                      8,
                    ),
                    child: Obx(() => _buildPackages()),
                  ),
                ),
              ),
            ),

            // Pinned footer. Meaningless without a package to price, so it
            // stays hidden until one is selectable.
            Obx(() {
              if (_controller.packages.isEmpty) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 18),
                    StaggeredEntrance(
                      index: 5,
                      child: Obx(
                        () => CouponInputSection(
                          codeController: _couponController,
                          appliedCoupon: _controller.appliedCoupon.value,
                          errorText: _controller.couponError.value,
                          discountAmount: _controller.discountAmount,
                          isApplying: _controller.isApplyingCoupon.value,
                          showCouponPicker: _controller.coupons.isNotEmpty,
                          onApply: () async {
                            FocusScope.of(context).unfocus();
                            await _controller.applyCouponCode(
                              _couponController.text,
                            );
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
                        final busy = _controller.isPurchasing.value;
                        final canBuy =
                            !busy &&
                            _controller.selectedApiPackage != null &&
                            !_controller.isApplyingCoupon.value;
                        final statusText = _controller.purchaseStatusText.value;
                        final label = busy && statusText.isNotEmpty
                            ? statusText
                            : 'Buy Now | ₹${_controller.amountToPay}';
                        return CreditGradientButton(
                          label: label,
                          isLoading: busy,
                          onPressed: canBuy ? _onBuyNow : null,
                        );
                      }),
                    ),
                    const SizedBox(height: 10),
                    const StaggeredEntrance(
                      index: 8,
                      child: SecurePaymentFooter(),
                    ),
                  ],
                ),
              );
            }),
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
                icon: const Icon(Icons.close, size: 20),
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

  /// Package list across its real states: loading, failed, empty, loaded.
  Widget _buildPackages() {
    if (_controller.isLoadingPackages.value && _controller.packages.isEmpty) {
      return const CreditsPackageSkeleton();
    }

    final error = _controller.packagesError.value;
    if (_controller.packages.isEmpty) {
      final failed = error.isNotEmpty && !_isEmptyCatalogue(error);
      return CreditsStateView(
        icon: failed
            ? Icons.wifi_tethering_off_rounded
            : Icons.inventory_2_outlined,
        tone: failed ? CreditsStateTone.error : CreditsStateTone.neutral,
        title: failed ? "Couldn't load packages" : 'No packages available yet',
        message: failed
            ? '$error\n\nCheck your connection and try again.'
            : 'New AI Credit packages are on the way. Please check back in a '
                  'little while.',
        primaryLabel: 'Try again',
        onPrimary: _controller.loadPackages,
        secondaryLabel: 'Go back',
        onSecondary: () => Get.back(),
      );
    }

    return Column(
      children: [
        for (var i = 0; i < _controller.packages.length; i++)
          StaggeredEntrance(
            key: ValueKey(_controller.packages[i].id),
            index: i + 1,
            child: CreditPackageCard(
              package: _controller.packages[i],
              selected:
                  _controller.selectedPackageId.value ==
                  _controller.packages[i].id,
              onTap: () =>
                  _controller.selectPackage(_controller.packages[i].id),
            ),
          ),
      ],
    );
  }

  /// The backend answered fine, there simply are no active packages.
  bool _isEmptyCatalogue(String error) =>
      error.toLowerCase().contains('no coin packages');

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
