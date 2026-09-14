import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../common/credits_colors.dart';
import '../../controller/credits_controller.dart';
import '../widgets/staggered_entrance.dart';
import 'buy_credits_screen.dart';
import 'credits_history_screen.dart';
import 'widgets/credit_gradient_button.dart';

class AiCreditsScreen extends StatelessWidget {
  const AiCreditsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = CreditsController.to;

    return Scaffold(
      backgroundColor: CreditsColors.scaffoldBg,
      appBar: AppBar(
        backgroundColor: CreditsColors.scaffoldBg,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          color: CreditsColors.textPrimary,
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'AI Credits',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 17,
            color: CreditsColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Get.dialog(
                AlertDialog(
                  title: const Text('About AI Credits'),
                  content: const Text(
                    'AI Credits are used for Zeno AI features including Believe Mode and chat insights. Purchase more anytime to keep trading with discipline.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Get.back(),
                      child: const Text('Got it'),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.info_outline, color: CreditsColors.textSecondary),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              StaggeredEntrance(
                index: 0,
                child: Obx(
                  () => _BalanceCard(
                    balance: controller.balance.value,
                    onTap: () => Get.to(() => const BuyCreditsScreen()),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              StaggeredEntrance(
                index: 1,
                child: Obx(
                  () => _StatsRow(
                    used: controller.usedThisMonth.value,
                    purchased: controller.purchasedThisMonth.value,
                    total: controller.balance.value,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              StaggeredEntrance(
                index: 2,
                child: Obx(
                  () => _BelieveModeCard(
                    weeklyCredits: controller.believeModeWeeklyCredits,
                    nextDeductionDays: controller.nextDeductionDays.value,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              StaggeredEntrance(
                index: 3,
                child: CreditGradientButton(
                  label: 'Buy Credits',
                  icon: Icons.shopping_cart_outlined,
                  onPressed: () => Get.to(() => const BuyCreditsScreen()),
                ),
              ),
              const SizedBox(height: 14),
              StaggeredEntrance(
                index: 4,
                child: _HistoryTile(
                  onTap: () => Get.to(() => const CreditsHistoryScreen()),
                ),
              ),
              const SizedBox(height: 14),
              const StaggeredEntrance(
                index: 5,
                child: _WelcomeBanner(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final int balance;
  final VoidCallback onTap;

  const _BalanceCard({required this.balance, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: CreditsColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: CreditsColors.lightPurple,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: CreditsColors.lightPurpleBorder),
              ),
              child: const Icon(
                Icons.psychology_outlined,
                color: CreditsColors.purple,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Available Balance',
                    style: TextStyle(
                      fontSize: 13,
                      color: CreditsColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${CreditsController.formatCreditsPlain(balance)} Credits',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: CreditsColors.blueText,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: CreditsColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final int used;
  final int purchased;
  final int total;

  const _StatsRow({
    required this.used,
    required this.purchased,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            value: CreditsController.formatCredits(-used),
            label: 'This Month',
            title: 'Used',
            valueColor: CreditsColors.danger,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            value: CreditsController.formatCredits(purchased),
            label: 'This Month',
            title: 'Purchased',
            valueColor: CreditsColors.success,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            value: CreditsController.formatCreditsPlain(total),
            label: 'Credits',
            title: 'Total Balance',
            valueColor: CreditsColors.blueText,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String? title;
  final String label;
  final Color valueColor;

  const _StatCard({
    required this.value,
    required this.title,
    required this.label,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CreditsColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          if (title != null) ...[
            Text(
              title!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: CreditsColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
          ],
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: title == null ? 13 : 16,
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: CreditsColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _BelieveModeCard extends StatelessWidget {
  final int weeklyCredits;
  final int nextDeductionDays;

  const _BelieveModeCard({
    required this.weeklyCredits,
    required this.nextDeductionDays,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CreditsColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: CreditsColors.lightPurple,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: CreditsColors.purple,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Believe Mode',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: CreditsColors.textPrimary,
                  ),
                ),
              ),
              Text(
                '$weeklyCredits Credits / Week',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: CreditsColors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Credits are automatically deducted every week for Believe Mode.',
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: CreditsColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: CreditsColors.scaffoldBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: CreditsColors.textSecondary,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Next deduction in',
                    style: TextStyle(
                      fontSize: 13,
                      color: CreditsColors.textSecondary,
                    ),
                  ),
                ),
                Text(
                  '$nextDeductionDays Days',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: CreditsColors.blueText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final VoidCallback onTap;

  const _HistoryTile({required this.onTap});

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
        child: const Row(
          children: [
            Icon(Icons.history, color: CreditsColors.purple, size: 22),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Credits History',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: CreditsColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'View all your credit transactions',
                    style: TextStyle(
                      fontSize: 12,
                      color: CreditsColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: CreditsColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _WelcomeBanner extends StatelessWidget {
  const _WelcomeBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CreditsColors.welcomeBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CreditsColors.lightPurpleBorder),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.auto_awesome, color: CreditsColors.purple, size: 22),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome to Zeno AI',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: CreditsColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'You received 500 Welcome Credits. Let\'s achieve your trading goals!',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: CreditsColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
