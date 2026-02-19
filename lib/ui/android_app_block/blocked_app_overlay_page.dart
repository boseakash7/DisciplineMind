import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

import '../../constants/blocked_apps.dart';
import '../../model/user_alert_model.dart';
import '../../services/api/api_config.dart';
import '../../services/api/api_url.dart';
import '../../services/native_app_block_service.dart';

/// Overlay when user opens a blocked app. Fetches user alerts; if empty → unblock, else keep blocked with Force Unblock option.
class BlockedAppOverlayPage extends StatefulWidget {
  const BlockedAppOverlayPage({super.key});

  @override
  State<BlockedAppOverlayPage> createState() => _BlockedAppOverlayPageState();
}

class _BlockedAppOverlayPageState extends State<BlockedAppOverlayPage> {
  static const _channel = MethodChannel(
    'com.discipline_mind/app_blocking_overlay',
  );
  final _storage = GetStorage();
  final _blockService = NativeAppBlockService();

  String? _blockedPackageName;
  bool _isLoading = true;
  bool _isChecking = false;
  String _statusMessage = 'Checking alerts...';
  /// Avoid setState after dispose; overlay can be hidden by native at any time.
  void _safeSetState(VoidCallback fn) {
    if (mounted) setState(fn);
  }

  @override
  void initState() {
    super.initState();
    // Show blocked UI + Force Unblock immediately; check alerts in background
    _safeSetState(() {
      _isLoading = false;
      _isChecking = false;
      _blockedPackageName = 'blocked_app';
      _statusMessage = 'You have an active alert. Stay focused on your goals.';
    });
    _checkAndUnblockIfNeeded();
  }

  /// Get blocked app package from native; retry a few times (engine may not be ready immediately).
  Future<String?> _getCurrentBlockedAppWithRetry() async {
    const maxAttempts = 10;
    const delayMs = 200;
    for (var i = 0; i < maxAttempts; i++) {
      if (!mounted) return null;
      try {
        final pkg = await _channel.invokeMethod<String>('getCurrentBlockedApp');
        if (pkg != null && pkg.isNotEmpty) return pkg;
      } catch (_) {}
      if (i < maxAttempts - 1)
        await Future<void>.delayed(const Duration(milliseconds: delayMs));
    }
    return null;
  }

  Future<void> _checkAndUnblockIfNeeded() async {
    if (!Platform.isAndroid) {
      _safeSetState(() {
        _isLoading = false;
        _blockedPackageName = null;
      });
      return;
    }

    // Check runs in background; we already show blocked UI with Force Unblock

    // Hard timeout: never stick in loading; show "blocked" after this.
    final timeout = Future<void>.delayed(const Duration(seconds: 10), () {});
    final work = _runCheck();

    await Future.any([timeout, work]);
    if (!mounted) return;
    // If still loading after work finished (or timeout), force show blocked state
    if (_isLoading || _isChecking) {
      _safeSetState(() {
        _isLoading = false;
        _isChecking = false;
        _statusMessage =
            'You have an active alert. Stay focused on your goals.';
        _blockedPackageName ??= 'blocked_app';
      });
    }
  }

  Future<void> _runCheck() async {
    try {
      final userId = _storage.read<String>('user_id');
      if (userId == null || userId.isEmpty) {
        _safeSetState(() => _statusMessage = 'No user. Unblocking...');
        await _unblockAndClose();
        return;
      }

      final packageFuture = _getCurrentBlockedAppWithRetry();
      _safeSetState(() => _statusMessage = 'Checking your alert...');
      final keepBlocked = await _shouldKeepBlocked(userId);
      if (!mounted) return;

      final package = await packageFuture;
      if (!mounted) return;
      _safeSetState(() => _blockedPackageName = package ?? _blockedPackageName);

      if (!keepBlocked) {
        _safeSetState(() => _statusMessage = 'No active alert. Unblocking...');
        await _unblockAndClose();
      } else {
        _safeSetState(() {
          _isLoading = false;
          _isChecking = false;
        _statusMessage =
            'You have an active alert. Stay focused on your goals.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      print('[BlockedAppOverlay] Error: $e');
      _safeSetState(() => _statusMessage = 'Error. Keeping blocked.');
      _safeSetState(() {
        _isLoading = false;
        _isChecking = false;
        _blockedPackageName ??= 'blocked_app';
      });
    }
  }

  /// true = keep blocked, false = unblock.
  /// Uses alert's target (price) and currentPrice from getAlertsByUser — no extra quote API.
  // Future<bool> _shouldKeepBlocked(String userId) async {
  //   try {
  //     final alertsRes = await http
  //         .post(
  //           Uri.parse('${ApiConfig.baseUrl}${ApiUrl.getAlertsByUser}'),
  //           headers: {'Content-Type': 'application/x-www-form-urlencoded'},
  //           body: {'user_id': userId},
  //         )
  //         .timeout(const Duration(seconds: 8));

  //     if (alertsRes.statusCode != 200) return true;
  //     final alertsJson = json.decode(alertsRes.body);
  //     final model = UserAlertModel.fromJson(alertsJson);
  //     final alerts = model.payload ?? [];
  //     if (alerts.isEmpty) return false;

  //     final alert = alerts.first;
  //     final targetPrice = double.tryParse(alert.price ?? '') ?? 0.0;
  //     final currentPrice = double.tryParse(alert.currentPrice ?? '') ?? 0.0;
  //     // Unblock only when current price has reached or passed target (current >= target).
  //     final shouldUnblock = currentPrice >= targetPrice;
  //     print(
  //       '[BlockedAppOverlay] target=$targetPrice current=$currentPrice (from alert) → unblock=$shouldUnblock',
  //     );
  //     return !shouldUnblock;
  //   } catch (e) {
  //     print('[BlockedAppOverlay] _shouldKeepBlocked failed: $e');
  //     return true; // keep blocked on error
  //   }
  // }
  Future<bool> _shouldKeepBlocked(String userId) async {
    try {
      final alertsRes = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}${ApiUrl.getAlertsByUser}'),
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: 'user_id=${Uri.encodeComponent(userId)}',
          )
          .timeout(const Duration(seconds: 10));
      if (alertsRes.statusCode != 200) return true;
      final alertsJson = json.decode(alertsRes.body);
      final model = UserAlertModel.fromJson(alertsJson);
      final alerts = model.payload ?? [];

      // ✅ Logic:
      // If list is empty → unblock app
      // If list is NOT empty → keep app blocked
      final keepBlocked = alerts.isNotEmpty;
      print(
        '[BlockedAppOverlay] alertsCount=${alerts.length} → keepBlocked=$keepBlocked',
      );

      return keepBlocked;
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
      await _blockService.unblockAndClose(blockedTradingAppPackages);
      print('[BlockedAppOverlay] Apps unblocked successfully');
    } catch (e) {
      print('[BlockedAppOverlay] unblockAndClose failed: $e');
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
                      const SizedBox(height: 24),
                      ElevatedButton(
                          onPressed: _unblockAndClose,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black87,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 14,
                            ),
                          ),
                          child: const Text('Force Unblock'),
                        ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
