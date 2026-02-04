import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';

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

  final TextEditingController priceController = TextEditingController();
  final RxDouble targetPrice = 0.0.obs;

  late String instrumentKey;

  @override
  void initState() {
    super.initState();
    instrumentKey = "${widget.stock.exchange}:${widget.stock.tradingsymbol}";
    alertController.fetchInstrumentQuote(instrumentKey);
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

        // Initialize price controller
        if (priceController.text.isEmpty) {
          priceController.text = (data.lastPrice ?? 0).toStringAsFixed(2);
          targetPrice.value = data.lastPrice ?? 0;
        }

        final currentPrice = data.lastPrice ?? 0;

        return Column(
          children: [
            _stockHeader(currentPrice),
            const Divider(height: 1),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _targetPriceSection(currentPrice),
                    const SizedBox(height: 14),
                    Obx(() {
                      final bool isAbove = targetPrice.value >= currentPrice;
                      return Text(
                        isAbove
                            ? "🔔 Alert when price goes ABOVE ₹${targetPrice.value.toStringAsFixed(2)}"
                            : "🔔 Alert when price goes BELOW ₹${targetPrice.value.toStringAsFixed(2)}",
                        style: TextStyle(
                          color: isAbove ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    }),
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
    final data = alertController.instrumentData.value!;
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
    return Container(
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          _adjustButton(Icons.remove, -1),
          Expanded(
            child: TextField(
              controller: priceController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              onChanged: (value) {
                targetPrice.value = double.tryParse(value) ?? currentPrice;
              },
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: "Enter price",
              ),
            ),
          ),
          _adjustButton(Icons.add, 1),
        ],
      ),
    );
  }

  Widget _adjustButton(IconData icon, int step) {
    return IconButton(
      icon: Icon(icon),
      onPressed: () {
        final value = targetPrice.value + step;
        targetPrice.value = value;
        priceController.text = value.toStringAsFixed(2);
      },
    );
  }

  Widget _saveButton() {
    return Obx(() {
      return PrimaryButton(
        isLoading: alertController.isSavingAlert.value,
        text: "Save Alert",
        color: Colors.green,
        onPressed: () async {
          if (priceController.text.isEmpty) return;

          // Show confirmation popup first
          showGenericPopup(
            context: Get.context!,
            heading: "Save Alert",
            subtitle: "Are you sure you want to create this price alert?",
            yesButtonTitle: "Save",
            noButtonTitle: "Cancel",
            onYesPress: () async {
              Get.back();

              // ---------------- PERMISSION CHECK ----------------
              final hasPermissions = await alertController
                  .checkBlockAppPermissions();

              if (!hasPermissions) {
                AppToast.showToast(
                  "Permissions required to block trading apps",
                );
                return;
              }

              // ---------------- GET ALERT DETAILS ----------------
              final instrument =
                  "${widget.stock.exchange}:${widget.stock.tradingsymbol}";
              final targetPriceValue = priceController.text;
              final currentPriceValue =
                  alertController.instrumentData.value?.lastPrice ?? 0;

              // ---------------- CREATE ALERT ----------------
              await alertController.createAlert(
                instrument: instrument,
                price: targetPriceValue,
                currentPrice: currentPriceValue,
              );

              // ---------------- NAVIGATE HOME ----------------
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
