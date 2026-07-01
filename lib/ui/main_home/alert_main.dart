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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          "Price Alerts",
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark?Colors.white:Colors.black
          ),
        ),
        elevation: 0,
        centerTitle: false,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
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
                  await Future.delayed(const Duration(seconds: 2));
                  Common.logout();
                },
                onNoPress: () => Get.back(),
              );
            },
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isUserAlertLoading.value) return _shimmerLoader(theme);

        if (controller.savedAlerts.isEmpty) return _emptyState(theme);

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
            return _alertCard(alert, theme);
          },
        );
      }),
    );
  }

  // ===================================================================
  // Helper Methods
  // ===================================================================

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
    return fixed.endsWith('.00')
        ? fixed.substring(0, fixed.length - 3)
        : fixed;
  }

  Color _statusColor(String status, ColorScheme colorScheme) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange.shade700;
      case 'completed':
        return Colors.green.shade700;
      case 'delete':
      case 'deleted':
        return Colors.red.shade700;
      default:
        return colorScheme.onSurfaceVariant;
    }
  }

  Color _statusBg(String status, ColorScheme colorScheme) =>
      _statusColor(status, colorScheme).withOpacity(0.12);

  String _statusLabel(String status) {
    return status.trim().isEmpty ? 'UNKNOWN' : status.toUpperCase();
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

  Widget _statusChip(String status, ThemeData theme) {
    final colorScheme = theme.colorScheme;
    final color = _statusColor(status, colorScheme);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _statusBg(status, colorScheme),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        _statusLabel(status),
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _kv(String key, String value, ThemeData theme, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 74,
            child: Text(
              key,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: valueColor ?? theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _alertCard(UserAlerts alert, ThemeData theme) {
    final colorScheme = theme.colorScheme;
    final isGtt = _isGttAlert(alert);
    final upper = _formatPrice(alert.upperPrice);
    final lower = _formatPrice(alert.lowerPrice);
    final gtt = _formatPrice(alert.gttPrice);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest, // or surfaceVariant
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(theme.brightness == Brightness.dark ? 0.3 : 0.05),
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
                backgroundColor: colorScheme.primary.withOpacity(0.15),
                child: Text(
                  ((alert.tradingsymbol ?? '?').isEmpty
                          ? '?'
                          : (alert.tradingsymbol ?? '?')[0])
                      .toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
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
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
            color: isDark?Colors.white:Colors.black

                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      alert.exchange ?? '-',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              _statusChip(alert.status ?? '', theme),
            ],
          ),
          const SizedBox(height: 10),
          if (isGtt) ...[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'GTT ALERT',
                    style: theme.textTheme.labelSmall?.copyWith(
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
          _kv('Trade ID', alert.tradeId?.isNotEmpty == true ? alert.tradeId! : '-', theme),
          if (isGtt)
            _kv('GTT', '₹$gtt', theme, valueColor: Colors.purple.shade700)
          else ...[
            _kv('Upper', '₹$upper', theme, valueColor: Colors.green.shade700),
            _kv('Lower', '₹$lower', theme, valueColor: Colors.red.shade700),
          ],
          _kv('Created', _formatTimestamp(alert.createdAt), theme),
          _kv('Alert ID', alert.id?.isNotEmpty == true ? alert.id! : '-', theme),
        ],
      ),
    );
  }

  Widget _emptyState(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 64, color: colorScheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(
            "No alerts yet",
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            "No active price alerts right now",
            style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _shimmerLoader(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) {
        return Shimmer.fromColors(
          baseColor: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
          highlightColor: isDark ? Colors.grey.shade700 : Colors.grey.shade100,
          child: Container(
            height: 100,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        );
      },
    );
  }
}