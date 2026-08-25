import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../common/credits_colors.dart';
import '../../controller/credits_controller.dart';
import '../../model/credits_models.dart';
import '../widgets/staggered_entrance.dart';

class CreditsHistoryScreen extends StatelessWidget {
  const CreditsHistoryScreen({super.key});

  static const _filters = [
    'All Transactions',
    'Purchases',
    'Deductions',
  ];

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
          'Credits History',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 17,
            color: CreditsColors.textPrimary,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: StaggeredEntrance(
              index: 0,
              child: Obx(
                () => _FilterDropdown(
                  value: controller.historyFilter.value,
                  options: _filters,
                  onChanged: controller.setHistoryFilter,
                ),
              ),
            ),
          ),
          Expanded(
            child: Obx(() {
              final groups = controller.groupedHistory;
              if (groups.isEmpty) {
                return const Center(
                  child: Text(
                    'No transactions found',
                    style: TextStyle(color: CreditsColors.textSecondary),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: groups.length,
                itemBuilder: (context, index) {
                  final group = groups[index];
                  // Deterministic stagger offset per group.
                  var base = 1;
                  for (var g = 0; g < index; g++) {
                    base += 1 + groups[g].transactions.length;
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      StaggeredEntrance(
                        index: base.clamp(0, 14),
                        child: Padding(
                          padding: EdgeInsets.only(
                            top: index == 0 ? 0 : 16,
                            bottom: 10,
                          ),
                          child: Text(
                            group.label,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: CreditsColors.blueText,
                            ),
                          ),
                        ),
                      ),
                      ...List.generate(group.transactions.length, (txIndex) {
                        final tx = group.transactions[txIndex];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: StaggeredEntrance(
                            index: (base + 1 + txIndex).clamp(0, 14),
                            child: _HistoryItem(transaction: tx),
                          ),
                        );
                      }),
                    ],
                  );
                },
              );
            }),
          ),
          StaggeredEntrance(
            index: 1,
            child: Obx(
              () => _LifetimeSummary(
                net: controller.lifetimeNetCredits,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  const _FilterDropdown({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CreditsColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: CreditsColors.textPrimary,
          ),
          items: options
              .map(
                (o) => DropdownMenuItem(value: o, child: Text(o)),
              )
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final CreditTransaction transaction;

  const _HistoryItem({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isPurchase = transaction.type != CreditTransactionType.deduction;
    final icon = isPurchase
        ? Icons.shopping_cart_outlined
        : Icons.work_outline_rounded;
    final iconBg = isPurchase
        ? CreditsColors.blue.withValues(alpha: 0.12)
        : CreditsColors.lightPurple;
    final iconColor =
        isPurchase ? CreditsColors.blue : CreditsColors.purple;
    final amountColor =
        transaction.isCredit ? CreditsColors.success : CreditsColors.danger;
    final amountLabel =
        '${CreditsController.formatCredits(transaction.amount)} Credits';

    return Container(
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
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: CreditsColors.textPrimary,
                  ),
                ),
                if (transaction.subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    transaction.subtitle!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: CreditsColors.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 2),
                Text(
                  CreditsController.formatDateTime(transaction.date),
                  style: const TextStyle(
                    fontSize: 11,
                    color: CreditsColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amountLabel,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: amountColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _LifetimeSummary extends StatelessWidget {
  final int net;

  const _LifetimeSummary({required this.net});

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewPadding.bottom;
    final label = '${CreditsController.formatCredits(net)} Net Credits';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottom),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: CreditsColors.lightPurple,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.layers_outlined,
              color: CreditsColors.purple,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lifetime Summary',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: CreditsColors.textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'All time transactions',
                  style: TextStyle(
                    fontSize: 11,
                    color: CreditsColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: CreditsColors.success,
            ),
          ),
        ],
      ),
    );
  }
}
