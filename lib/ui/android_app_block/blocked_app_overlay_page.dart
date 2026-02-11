import 'dart:convert';
import 'dart:io';

import 'package:block_app/block_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

import '../../controller/alert_controller.dart';
import '../../model/user_alert_model.dart';
import '../../services/api/api_config.dart';
import '../../services/api/api_url.dart';

/// Overlay when user opens a blocked app. Fetches user alerts; if target price >= current price → unblock, else keep blocked.
class BlockedAppOverlayPage extends StatefulWidget {
  const BlockedAppOverlayPage({super.key});

  @override
  State<BlockedAppOverlayPage> createState() => _BlockedAppOverlayPageState();
}

class _BlockedAppOverlayPageState extends State<BlockedAppOverlayPage> {
  static const _channel = MethodChannel('com.block_app/app_blocking_overlay');
  final _storage = GetStorage();

  String? _blockedPackageName;
  bool _isLoading = true;
  bool _isChecking = false;
  String _statusMessage = 'Checking alerts...';

  @override
  void initState() {
    super.initState();
    _checkAndUnblockIfNeeded();
  }

  Future<void> _checkAndUnblockIfNeeded() async {
    if (!Platform.isAndroid) {
      setState(() {
        _isLoading = false;
        _blockedPackageName = null;
      });
      return;
    }

    setState(() {
      _isChecking = true;
      _statusMessage = 'Checking alerts...';
    });

    try {
      final package = await _channel.invokeMethod<String>(
        'getCurrentBlockedApp',
      );
      setState(() => _blockedPackageName = package);

      final userId = _storage.read<String>('user_id');
      if (userId == null || userId.isEmpty) {
        setState(() => _statusMessage = 'No user. Unblocking...');
        await _unblockAndClose();
        return;
      }

      setState(() => _statusMessage = 'Checking your alert...');
      final keepBlocked = await _shouldKeepBlocked(userId);

      if (!keepBlocked) {
        setState(() => _statusMessage = 'Target reached. Unblocking...');
        await _unblockAndClose();
      } else {
        setState(() {
          _isLoading = false;
          _isChecking = false;
          _statusMessage = 'Target price not reached yet. Apps remain blocked.';
        });
      }
    } catch (e) {
      print('[BlockedAppOverlay] Error: $e');
      setState(() => _statusMessage = 'Error. Keeping blocked.');
      setState(() {
        _isLoading = false;
        _isChecking = false;
      });
    }
  }

  /// true = keep blocked, false = unblock.
  /// Uses alert's target (price) and currentPrice from getAlertsByUser — no extra quote API.
  Future<bool> _shouldKeepBlocked(String userId) async {
    try {
      final alertsRes = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}${ApiUrl.getAlertsByUser}'),
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: {'user_id': userId},
          )
          .timeout(const Duration(seconds: 8));

      if (alertsRes.statusCode != 200) return true;
      final alertsJson = json.decode(alertsRes.body);
      final model = UserAlertModel.fromJson(alertsJson);
      final alerts = model.payload ?? [];
      if (alerts.isEmpty) return false;

      final alert = alerts.first;
      final targetPrice = double.tryParse(alert.price ?? '') ?? 0.0;
      final currentPrice = double.tryParse(alert.currentPrice ?? '') ?? 0.0;
      // Unblock only when current price has reached or passed target (current >= target).
      final shouldUnblock = currentPrice >= targetPrice;
      print(
        '[BlockedAppOverlay] target=$targetPrice current=$currentPrice (from alert) → unblock=$shouldUnblock',
      );
      return !shouldUnblock;
    } catch (e) {
      print('[BlockedAppOverlay] _shouldKeepBlocked failed: $e');
      return true; // keep blocked on error
    }
  }

  static String _appDisplayName(String? package) {
    if (package == null) return 'This app';
    switch (package) {
      case 'com.zerodha.kite3':
        return 'Zerodha Kite';
      case 'in.upstox.app':
        return 'Upstox';
      case 'com.nextbillion.groww':
        return 'Groww';
      default:
        return 'This app';
    }
  }

  Future<void> _unblockAndClose() async {
    try {
      print('[BlockedAppOverlay] Unblocking apps...');
      await _channel.invokeMethod<void>('unblockAndClose', {
        'packages': AlertController.BLOCKED_TRADING_APP_PACKAGES,
      });
      print('[BlockedAppOverlay] Apps unblocked successfully');
    } catch (e) {
      print('[BlockedAppOverlay] unblockAndClose failed: $e');
      // Fallback: try unblock via BlockApp then close
      try {
        final blockApp = BlockApp();
        for (final package in AlertController.BLOCKED_TRADING_APP_PACKAGES) {
          await blockApp.unblockApp(package);
        }
        await _channel.invokeMethod('closeOverlay');
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black87,
      child: SafeArea(
        child: _isLoading || _isChecking
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: Colors.white),
                    const SizedBox(height: 24),
                    Text(
                      _statusMessage,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            : Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.lock, size: 80, color: Colors.white),
                      const SizedBox(height: 24),
                      Text(
                        '${_appDisplayName(_blockedPackageName)} is blocked',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _statusMessage,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
