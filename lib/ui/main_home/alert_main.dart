import 'dart:io';

import 'package:discipline_mind/common/common.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';

import '../../controller/alert_controller.dart';
import '../../model/user_alert_model.dart';
import '../android_app_block/app_usage_stats_page.dart';
import '../widgets/common_widgets.dart';

class AlertsMainScreen extends StatefulWidget {
  const AlertsMainScreen({super.key});

  @override
  State<AlertsMainScreen> createState() => _AlertsMainScreenState();
}

class _AlertsMainScreenState extends State<AlertsMainScreen> {
  final AlertController controller = Get.put(AlertController());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = Common.userData.value?.payload?.id?.toString();
      if (userId != null && userId.isNotEmpty) {
        controller.fetchUserAlerts(userId);
      }
    });
  }

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
      body: Obx(() {
        if (controller.isUserAlertLoading.value) return _shimmerLoader();

        if (controller.savedAlerts.isEmpty) return _emptyState();

        final alerts = controller.savedAlerts.toList()
          ..sort((a, b) {
            final aa = int.tryParse(a.createdAt ?? '') ?? 0;
            final bb = int.tryParse(b.createdAt ?? '') ?? 0;
            return bb.compareTo(aa);
          });
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: alerts.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final alert = alerts[index];
            return _alertCard(alert, isDark);
          },
        );
      }),
    );
  }

  bool _hasValue(String? v) => v != null && v.trim().isNotEmpty && v != 'null';

  bool _hasUpperLower(UserAlerts alert) =>
      _hasValue(alert.upperPrice) || _hasValue(alert.lowerPrice);

  bool _isGttAlert(UserAlerts alert) =>
      _hasValue(alert.gttPrice) && !_hasUpperLower(alert);

  String _formatPrice(String? value) {
    final raw = value?.trim() ?? '';
    if (raw.isEmpty || raw == 'null') return '-';
    final parsed = double.tryParse(raw);
    if (parsed == null) return raw;
    final fixed = parsed.toStringAsFixed(2);
    if (fixed.endsWith('.00')) {
      return fixed.substring(0, fixed.length - 3);
    }
    return fixed;
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFEF6C00);
      case 'completed':
        return const Color(0xFF2E7D32);
      case 'delete':
      case 'deleted':
        return const Color(0xFFC62828);
      default:
        return Colors.grey.shade700;
    }
  }

  Color _statusBg(String status) => _statusColor(status).withOpacity(0.12);

  String _statusLabel(String status) {
    if (status.trim().isEmpty) return 'UNKNOWN';
    return status.toUpperCase();
  }

  String _formatTimestamp(String? ts) {
    final seconds = int.tryParse(ts ?? '');
    if (seconds == null || seconds <= 0) return '-';
    final dt = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} $h:$m $ampm';
  }

  Widget _statusChip(String status) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _statusBg(status),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _kv(String key, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 74,
            child: Text(
              key,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                color: valueColor ?? Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _alertCard(UserAlerts alert, bool isDark) {
    final isGtt = _isGttAlert(alert);
    final upper = _formatPrice(alert.upperPrice);
    final lower = _formatPrice(alert.lowerPrice);
    final gtt = _formatPrice(alert.gttPrice);
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: Colors.blue.withOpacity(0.15),
                child: Text(
                  ((alert.tradingsymbol ?? '?').isEmpty
                          ? '?'
                          : (alert.tradingsymbol ?? '?')[0])
                      .toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert.tradingsymbol ?? '-',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      alert.exchange ?? '-',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              _statusChip(alert.status ?? ''),
            ],
          ),
          const SizedBox(height: 10),
          if (isGtt) ...[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'GTT ALERT',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.purple.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ] else
            const SizedBox(height: 4),
          _kv('Trade ID', alert.tradeId?.isNotEmpty == true ? alert.tradeId! : '-'),
          if (isGtt)
            _kv('GTT', '₹$gtt', valueColor: Colors.purple.shade700)
          else ...[
            _kv('Upper', '₹$upper', valueColor: Colors.green.shade700),
            _kv('Lower', '₹$lower', valueColor: Colors.red.shade700),
          ],
          _kv('Created', _formatTimestamp(alert.createdAt)),
          _kv('Alert ID', alert.id?.isNotEmpty == true ? alert.id! : '-'),
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
            "No active price alerts right now",
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
