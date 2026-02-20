import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';

import '../../common/common.dart';
import '../../controller/alert_controller.dart';
import '../../model/instrument_api_model.dart';
import '../main_home/main_home.dart';
import '../widgets/app_toast.dart';
import '../widgets/common_widgets.dart';

class SetAlertDetailScreen extends StatefulWidget {
  final Payload stock;

  const SetAlertDetailScreen({super.key, required this.stock});

  @override
  State<SetAlertDetailScreen> createState() => _SetAlertDetailScreenState();
}

class _SetAlertDetailScreenState extends State<SetAlertDetailScreen> {
  final AlertController alertController = Get.find();

  final TextEditingController upperPriceController = TextEditingController();
  final TextEditingController lowerPriceController = TextEditingController();

  late String instrumentKey;

  @override
  void initState() {
    super.initState();
    instrumentKey = "${widget.stock.exchange}:${widget.stock.tradingsymbol}";
    alertController.fetchInstrumentQuote(instrumentKey);
    _checkExistingActiveAlert();
  }

  /// Fetch alerts so we know if user already has an active alert (to show message / disable save).
  void _checkExistingActiveAlert() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final userId = Common.userData.value?.payload?.id?.toString();
      if (userId == null) return;
      await alertController.fetchUserAlerts(userId);
      if (alertController.savedAlerts.isNotEmpty) {
        AppToast.showToast(
          "You already have active alerts. Delete them to add new ones.",
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Price Alert")),
      body: Obx(() {
        if (alertController.isQuoteLoading.value) {
          return _shimmerLoader();
        }

        final data = alertController.instrumentData.value;

        if (data == null) {
          return const Center(child: Text("No data found"));
        }

        final currentPrice = data.lastPrice ?? 0;
        if (upperPriceController.text.isEmpty) {
          upperPriceController.text = (currentPrice + 0.01).toStringAsFixed(2);
          final lower = currentPrice > 0.01 ? currentPrice - 0.01 : 0.01;
          lowerPriceController.text = lower.toStringAsFixed(2);
        }

        return Column(
          children: [
            _stockHeader(currentPrice),
            const Divider(height: 1),
            Obx(() {
              if (alertController.savedAlerts.isEmpty)
                return const SizedBox.shrink();
              return _activeAlertMessage();
            }),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _targetPriceSection(currentPrice),
                    const Spacer(),
                    _saveButton(),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  // ================= HEADER =================
  // ================= HEADER =================
  Widget _stockHeader(double currentPrice) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.stock.tradingsymbol ?? "",
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            widget.stock.name ?? "",
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Text("Current Price", style: TextStyle(color: Colors.grey)),
              const Spacer(),
              Row(
                children: [
                  Obx(() {
                    final price =
                        alertController.instrumentData.value?.lastPrice ?? 0;
                    return Text(
                      "₹${price.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    );
                  }),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () async {
                      // Refresh current price
                      await alertController.fetchInstrumentQuote(instrumentKey);
                      AppToast.showToast("Price updated");
                    },
                    child: const Icon(
                      Icons.refresh,
                      size: 20,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Widget _stockHeader(double currentPrice) {
  //   final data = alertController.instrumentData.value!;
  //   return Padding(
  //     padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Text(
  //           widget.stock.tradingsymbol ?? "",
  //           style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
  //         ),
  //         const SizedBox(height: 4),
  //         Text(
  //           widget.stock.name ?? "",
  //           style: TextStyle(color: Colors.grey.shade600),
  //         ),
  //         const SizedBox(height: 14),
  //         Row(
  //           children: [
  //             const Text("Current Price", style: TextStyle(color: Colors.grey)),
  //             const Spacer(),
  //             Text(
  //               "₹${currentPrice.toStringAsFixed(2)}",
  //               style: const TextStyle(
  //                 fontSize: 18,
  //                 fontWeight: FontWeight.bold,
  //                 color: Colors.green,
  //               ),
  //             ),
  //           ],
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // ================= TARGET PRICE =================
  Widget _targetPriceSection(double currentPrice) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Upper target (price above current)",
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: upperPriceController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: "Must be > ₹${currentPrice.toStringAsFixed(2)}",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixText: "₹ ",
          ),
        ),
        const SizedBox(height: 16),
        Text(
          "Lower target (price below current)",
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: lowerPriceController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: "Must be < ₹${currentPrice.toStringAsFixed(2)}",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixText: "₹ ",
          ),
        ),
      ],
    );
  }

  Widget _activeAlertMessage() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.orange.shade700, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "You already have active alerts. Delete them to add new ones.",
              style: TextStyle(
                color: Colors.orange.shade900,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _saveButton() {
    return Obx(() {
      final hasActiveAlert = alertController.savedAlerts.isNotEmpty;
      return PrimaryButton(
        isLoading: alertController.isSavingAlert.value,
        text: "Create Alert",
        color: Colors.green,
        onPressed: hasActiveAlert
            ? null
            : () async {
                final upper = upperPriceController.text.trim();
                final lower = lowerPriceController.text.trim();
                if (upper.isEmpty || lower.isEmpty) {
                  AppToast.showToast("Enter both upper and lower prices");
                  return;
                }
                final upperVal = double.tryParse(upper) ?? 0;
                final lowerVal = double.tryParse(lower) ?? 0;
                final currentPriceValue =
                    alertController.instrumentData.value?.lastPrice ?? 0;
                if (upperVal <= currentPriceValue) {
                  AppToast.showToast("Upper price must be greater than current price");
                  return;
                }
                if (lowerVal >= currentPriceValue) {
                  AppToast.showToast("Lower price must be less than current price");
                  return;
                }

                showGenericPopup(
                  context: Get.context!,
                  heading: "Create Alert",
                  subtitle: "Create alerts for upper ₹${upper} and lower ₹${lower}?",
                  yesButtonTitle: "Create",
                  noButtonTitle: "Cancel",
                  onYesPress: () async {
                    Get.back();
                    final hasPermissions = await alertController.checkBlockAppPermissions();
                    if (!hasPermissions) {
                      AppToast.showToast("Permissions required to block trading apps");
                      return;
                    }
                    final instrument =
                        "${widget.stock.exchange}:${widget.stock.tradingsymbol}";
                    await alertController.createAlertPair(
                      instrument: instrument,
                      upperPrice: upper,
                      lowerPrice: lower,
                      currentPrice: currentPriceValue,
                    );
                    Get.offAll(() => MainHomeScreen());
                  },
                  onNoPress: () => Get.back(),
                );
              },
      );
    });
  }

  // Widget _saveButton() {
  //   return Obx(() {
  //     return PrimaryButton(
  //       isLoading: alertController.isSavingAlert.value,
  //       text: "Save Alert",
  //       color: Colors.green,
  //       onPressed: () {
  //         if (priceController.text.isEmpty) return;

  //         showGenericPopup(
  //           context: Get.context!,
  //           heading: "Save Alert",
  //           subtitle: "Are you sure you want to create this price alert?",
  //           yesButtonTitle: "Save",
  //           noButtonTitle: "Cancel",
  //           onYesPress: () async {
  //             Get.back();
  //             final instrument =
  //                 "${widget.stock.exchange}:${widget.stock.tradingsymbol}";
  //             final targetPriceValue = priceController.text;
  //             final currentPriceValue =
  //                 alertController.instrumentData.value?.lastPrice ?? 0.0;

  //             await alertController.createAlert(
  //               instrument: instrument,
  //               price: targetPriceValue,
  //               currentPrice: currentPriceValue,
  //             );

  //             Get.offAll(() => MainHomeScreen());
  //           },
  //           onNoPress: () => Get.back(),
  //         );
  //       },
  //     );
  //   });
  // }

  // ================= SHIMMER =================
  Widget _shimmerLoader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: List.generate(
          5,
          (index) => Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(
              height: 54,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
