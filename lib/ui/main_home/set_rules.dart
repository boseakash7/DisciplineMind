import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/rules_controller.dart';
import '../widgets/app_toast.dart';
import '../widgets/common_widgets.dart';

class RulesHomeScreen extends StatelessWidget {
  final RulesController controller = Get.put(RulesController());

  RulesHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.grey[200],
        elevation: 0,
        title: const Text(
          "Zeno AI",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: const [
                    _StatItem(title: "DM Score", value: "0"),
                    _StatItem(title: "DM Level", value: "0"),
                    _StatItem(title: "DM Points", value: "500"),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                color: Colors.redAccent,
                child: const Center(
                  child: Text(
                    "DM TRADING RULES",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              "Setup your Trading Rules",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            /// Step Indicator
            _stepIndicator(),

            const SizedBox(height: 20),

            /// Step Content
            Expanded(
              child: Obx(() {
                return _stepCard(
                  child: _buildStepContent(controller.currentStep.value),
                );
              }),
            ),

            const SizedBox(height: 15),
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  // ================= STEP CONTENT =================

  Widget _buildStepContent(int step) {
    switch (step) {
      case 0:
        return CommonDropdownField(
          label: "Select your Trading Segment",
          hint: "Select Segment",
          options: const ["Spot", "Future"],
          value: controller.selectedSegment.value.isEmpty
              ? null
              : controller.selectedSegment.value,
          onChanged: (val) => controller.selectedSegment.value = val ?? "",
        );

      case 1:
        return RuleInputField(
          label: "Your Trading Capital",
          hint: "Enter capital amount",
          onChanged: (val) => controller.tradingCapital.value = val,
        );

      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RuleInputField(
              label: "Max Loss per Day",
              hint: "Recommended value",
              onChanged: (val) => controller.maxLossPerDay.value = val,
            ),
            const SizedBox(height: 6),
            const Text(
              "Recommended as per your capital & standard trading rules",
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
        );

      case 3:
        return CommonDropdownField(
          label: "Max Trades per Day",
          hint: "Select Count",
          options: const ["1", "2", "3", "4", "5"],
          value: controller.maxTradesPerDay.value.isEmpty
              ? null
              : controller.maxTradesPerDay.value,
          onChanged: (val) => controller.maxTradesPerDay.value = val ?? "",
        );

      case 4:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Capital Range to be used per Trade",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: "Min %",
                    ),
                    onChanged: (val) => controller.minCapitalRange.value = val,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 15),
                  child: Text(
                    "-",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: TextField(
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: "Max %",
                    ),
                    onChanged: (val) => controller.maxCapitalRange.value = val,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            // Validation & Recommendation Text
            Obx(() {
              bool valid = controller.isCapitalRangeValid;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Allowed: Min 7% to Max 18% of Trading Capital",
                    style: TextStyle(
                      color: controller.minCapitalRange.isEmpty
                          ? Colors.grey
                          : (valid ? Colors.green : Colors.red),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Text(
                    "Recommended: Min 10% and Max 15%",
                    style: TextStyle(
                      color: Colors.blueGrey,
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              );
            }),
          ],
        );

      default:
        return const SizedBox.shrink();
    }
  }

  // ================= BUTTONS =================
  Widget _buildNavigationButtons() {
    return Obx(() {
      final isLastStep = controller.currentStep.value == 4;
      final bool isValid = controller.canProceed();

      return Row(
        children: [
          if (controller.currentStep.value > 0)
            Expanded(
              child: ElevatedButton(
                onPressed: controller.prevStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "BACK",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          if (controller.currentStep.value > 0) const SizedBox(width: 12),

          // Inside _buildNavigationButtons() in RulesHomeScreen.dart
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                if (isValid) {
                  if (isLastStep) {
                    AppToast.showToast("Rules Saved");
                  } else {
                    controller.nextStep();
                  }
                } else {
                  if (controller.currentStep.value == 4 &&
                      controller.minCapitalRange.value.isNotEmpty) {
                    AppToast.showToast("Range must be 7% - 18%");
                  } else {
                    AppToast.showToast("Please fill the field");
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isValid
                    ? (isLastStep ? Colors.green : Colors.redAccent)
                    : Colors.grey.shade400,
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: isValid ? 2 : 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                isLastStep ? "SAVE RULES" : "NEXT",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      );
    });
  }
  // Widget _buildNavigationButtons() {
  //   return Obx(() {
  //     final isLastStep = controller.currentStep.value == 4;

  //     return Row(
  //       children: [
  //         if (controller.currentStep.value > 0)
  //           Expanded(
  //             child: ElevatedButton(
  //               onPressed: controller.prevStep,
  //               style: ElevatedButton.styleFrom(
  //                 backgroundColor: Colors.blueAccent,
  //                 padding: const EdgeInsets.symmetric(vertical: 14),
  //                 shape: RoundedRectangleBorder(
  //                   borderRadius: BorderRadius.circular(12),
  //                 ),
  //               ),
  //               child: const Text(
  //                 "BACK",
  //                 style: TextStyle(
  //                   color: Colors.white,
  //                   fontWeight: FontWeight.w600,
  //                 ),
  //               ),
  //             ),
  //           ),
  //         if (controller.currentStep.value > 0) const SizedBox(width: 12),
  //         Expanded(
  //           child: ElevatedButton(
  //             onPressed: () {
  //               if (isLastStep) {
  //                 Get.snackbar(
  //                   "Success",
  //                   "Trading Rules Saved Successfully",
  //                   snackPosition: SnackPosition.BOTTOM,
  //                   backgroundColor: Colors.green,
  //                   colorText: Colors.white,
  //                 );
  //               } else {
  //                 controller.nextStep();
  //               }
  //             },
  //             style: ElevatedButton.styleFrom(
  //               backgroundColor: isLastStep ? Colors.green : Colors.redAccent,
  //               padding: const EdgeInsets.symmetric(vertical: 14),
  //               shape: RoundedRectangleBorder(
  //                 borderRadius: BorderRadius.circular(12),
  //               ),
  //             ),
  //             child: Text(
  //               isLastStep ? "SAVE RULES" : "NEXT",
  //               style: TextStyle(
  //                 color: Colors.white,
  //                 fontWeight: FontWeight.w600,
  //               ),
  //             ),
  //           ),
  //         ),
  //       ],
  //     );
  //   });
  // }

  // ================= UI HELPERS =================

  Widget _stepCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _stepIndicator() {
    return Obx(() {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(5, (index) {
          final active = controller.currentStep.value >= index;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            height: 6,
            width: active ? 28 : 18,
            decoration: BoxDecoration(
              color: active ? Colors.green : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(6),
            ),
          );
        }),
      );
    });
  }
}

// ================= STAT WIDGET =================

class _StatItem extends StatelessWidget {
  final String title;
  final String value;

  const _StatItem({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
      ],
    );
  }
}
