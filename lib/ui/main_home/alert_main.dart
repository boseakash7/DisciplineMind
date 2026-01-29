import 'package:discipline_mind/common/common.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';

import '../../controller/alert_controller.dart';
import '../widgets/common_widgets.dart';
import 'search_alert.dart';

class AlertsMainScreen extends StatelessWidget {
  final AlertController controller = Get.put(AlertController());

  AlertsMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xffF4F6FA),
      appBar: AppBar(
        title: const Text(
          "Price Alerts",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Logout",
            onPressed: () {
              showGenericPopup(
                context: Get.context!,
                heading: "Logout",
                subtitle: "Are you sure you want to logout?",
                yesButtonTitle: "Logout",
                noButtonTitle: "Cancel",
                onYesPress: () async {
                  Get.back();
                  Future.delayed(const Duration(milliseconds: 200), () {
                    Common.logout();
                  });
                },

                onNoPress: () => Get.back(),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.to(() => SearchStockScreen()),
        label: const Text("Add Alert"),
        icon: const Icon(Icons.add),
      ),
      body: Obx(() {
        if (controller.isUserAlertLoading.value) return _shimmerLoader();

        if (controller.savedAlerts.isEmpty) return _emptyState();

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: controller.savedAlerts.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final alert = controller.savedAlerts[index];
            return _alertCard(alert, isDark);
          },
        );
      }),
    );
  }

  Widget _alertCard(alert, bool isDark) {
    final current = double.tryParse(alert.currentPrice ?? "0") ?? 0;
    final target = double.tryParse(alert.price ?? "0") ?? 0;
    final bool isBullish = target >= current;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xff121212) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          /// Symbol Avatar
          CircleAvatar(
            radius: 24,
            backgroundColor: isBullish
                ? Colors.green.withOpacity(0.15)
                : Colors.red.withOpacity(0.15),
            child: Text(
              alert.tradingsymbol!.substring(0, 1),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isBullish ? Colors.green : Colors.red,
              ),
            ),
          ),
          const SizedBox(width: 14),

          /// Stock Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.tradingsymbol ?? "",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  alert.exchange ?? "",
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 2),
                Text(
                  "Current Price: ₹${alert.currentPrice ?? '0'}",
                  style: TextStyle(fontSize: 12, color: Colors.blue),
                ),
                const SizedBox(height: 2),
                Text(
                  "Status: ${alert.status ?? "N/A"}",
                  style: TextStyle(
                    fontSize: 12,
                    color: alert.status == "active" ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ),

          /// Target Price + Actions
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "Target: ₹${alert.price}",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: isBullish ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _showEditDialog(alert),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      showGenericPopup(
                        context: Get.context!,
                        heading: "Delete Alert?",
                        subtitle: "Are you sure you want to delete this alert?",
                        yesButtonTitle: "Delete",
                        noButtonTitle: "Cancel",
                        onYesPress: () async {
                          await controller.deleteAlert(alert.id!);
                        },
                        onNoPress: () => Get.back(),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// ====================================
  /// EMPTY STATE
  /// ====================================
  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.notifications_none, size: 64, color: Colors.grey),
          SizedBox(height: 12),
          Text(
            "No alerts yet",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 6),
          Text(
            "Tap + to create your first price alert",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  /// ====================================
  /// SHIMMER LOADER
  /// ====================================
  Widget _shimmerLoader() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) {
        return Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        );
      },
    );
  }

  /// ====================================
  /// EDIT ALERT DIALOG
  /// ====================================
  void _showEditDialog(alert) {
    final TextEditingController controllerText = TextEditingController(
      text: alert.price,
    );

    Get.defaultDialog(
      title: "Edit Target Price",
      content: TextField(
        controller: controllerText,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(hintText: "Enter new price"),
      ),
      textConfirm: "Save",
      textCancel: "Cancel",
      onConfirm: () {
        final newPrice = controllerText.text;
        // controller.updateAlert(alert.id!, newPrice);
        Get.back();
      },
    );
  }
}
