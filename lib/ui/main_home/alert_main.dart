import 'dart:io';

import 'package:discipline_mind/common/common.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';

import '../../controller/alert_controller.dart';
import '../../model/user_alert_model.dart';
import '../android_app_block/app_usage_stats_page.dart';
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
          if (Platform.isAndroid)
            IconButton(
              icon: const Icon(Icons.analytics_outlined),
              tooltip: "App usage stats",
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AppUsageStatsPage()),
              ),
            ),
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
                  await Future.delayed(const Duration(milliseconds: 200));
                  Common.logout();
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

        final merged = _mergeAlerts(controller.savedAlerts);
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: merged.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = merged[index];
            return _alertCard(item['alerts'] as List<UserAlerts>, isDark);
          },
        );
      }),
    );
  }

  /// Merge alerts by instrument: 2 alerts (upper+lower) become 1 card.
  List<Map<String, dynamic>> _mergeAlerts(List<UserAlerts> alerts) {
    final byInstrument = <String, List<UserAlerts>>{};
    for (final a in alerts) {
      final key = "${a.exchange}:${a.tradingsymbol}";
      byInstrument.putIfAbsent(key, () => []).add(a);
    }
    return byInstrument.entries.map((e) => {'alerts': e.value}).toList();
  }

  Widget _alertCard(List<UserAlerts> alerts, bool isDark) {
    final alert = alerts.first;
    final current = double.tryParse(alert.currentPrice ?? "0") ?? 0;
    UserAlerts? upperAlert;
    UserAlerts? lowerAlert;
    for (final a in alerts) {
      final p = double.tryParse(a.price ?? "0") ?? 0;
      if (p >= current) upperAlert = a;
      if (p < current) lowerAlert = a;
    }
    final upperPrice = upperAlert != null
        ? (double.tryParse(upperAlert.price ?? "0") ?? 0)
        : null;
    final lowerPrice = lowerAlert != null
        ? (double.tryParse(lowerAlert.price ?? "0") ?? 0)
        : null;
    final ids = alerts.map((a) => a.id).whereType<String>().toList();

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
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.blue.withOpacity(0.15),
            child: Text(
              (alert.tradingsymbol ?? "?")[0],
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
          const SizedBox(width: 14),
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
                const SizedBox(height: 6),
                Text(
                  "Current: ₹${current.toStringAsFixed(2)}",
                  style: const TextStyle(fontSize: 13, color: Colors.blue),
                ),
                if (upperPrice != null)
                  Text(
                    "Upper: ₹${upperPrice.toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                if (lowerPrice != null)
                  Text(
                    "Lower: ₹${lowerPrice.toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                if (upperPrice == null && lowerPrice == null)
                  Text(
                    "Target: ₹${alert.price}",
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          (double.tryParse(alert.price ?? "0") ?? 0) >= current
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
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
                      await controller.deleteAlerts(ids);
                    },
                    onNoPress: () => Get.back(),
                  );
                },
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
}
