import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

import '../../model/user_alert_model.dart';
import '../../services/api/api_config.dart';
import '../../services/api/api_url.dart';
import '../../services/native_app_block_service.dart';
import 'mind_control_guard_lock_screen.dart';

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
  bool _hasActiveTrade = false;
  void _safeSetState(VoidCallback fn) {
    if (mounted) setState(fn);
  }

  @override
  void initState() {
    super.initState();
    _safeSetState(() {
      _isLoading = false;
      _isChecking = false;
      _blockedPackageName = 'blocked_app';
    });
    _refreshLockStatus();
    _checkAndUnblockIfNeeded();
  }

  Future<void> _refreshLockStatus() async {
    final active = await _blockService.hasActiveTrade();
    if (!mounted) return;
    if (active) {
      _safeSetState(() => _hasActiveTrade = true);
    }
  }
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
          _blockedPackageName ??= 'blocked_app';
        });
    }
  }

  Future<void> _runCheck() async {
    try {
      final userId = _storage.read<String>('user_id');
      if (userId == null || userId.isEmpty) {
        await _unblockAndClose();
        return;
      }

      final packageFuture = _getCurrentBlockedAppWithRetry();
      final keepBlocked = await _shouldKeepBlocked(userId);
      if (!mounted) return;

      final package = await packageFuture;
      if (!mounted) return;
      _safeSetState(() => _blockedPackageName = package ?? _blockedPackageName);

      if (!keepBlocked) {
        await _unblockAndClose();
      } else {
        _safeSetState(() {
          _isLoading = false;
          _isChecking = false;
        });
        await _refreshLockStatus();
      }
    } catch (e) {
      if (!mounted) return;
      print('[BlockedAppOverlay] Error: $e');
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
      // If list empty → unblock app
      // If any alert has status "pending" → keep app blocked (same as non-empty)
      final hasPending = alerts.any(
        (a) => (a.status ?? '').toLowerCase() == 'pending',
      );
      final hasTrade = alerts.any((a) {
        final tid = (a.tradeId ?? '').trim();
        return tid.isNotEmpty && tid != '0' && tid.toLowerCase() != 'null';
      });
      if (mounted) {
        _safeSetState(() => _hasActiveTrade = hasTrade);
      }
      final keepBlocked = hasPending;
      print(
        '[BlockedAppOverlay] alertsCount=${alerts.length} pending=$hasPending → keepBlocked=$keepBlocked',
      );

      return keepBlocked;
    } catch (e) {
      print('[BlockedAppOverlay] _shouldKeepBlocked failed: $e');
      return true; // keep blocked on error
    }
  }

  Future<void> _willControl() async {
    try {
      final sentHome = await _blockService.goHome();
      if (!sentHome) {
        await _blockService.closeOverlay();
      }
    } catch (e) {
      print('[BlockedAppOverlay] willControl failed: $e');
    }
  }

  Future<void> _forceUnblockTemporary() async {
    try {
      print('[BlockedAppOverlay] Force unblock (temporary)...');
      final package = _blockedPackageName;
      if (package != null &&
          package.isNotEmpty &&
          package != 'blocked_app') {
        await _blockService.forceUnblockTemporary(packageName: package);
      } else {
        await _blockService.forceUnblockTemporary();
      }
      print('[BlockedAppOverlay] Temporary force unblock applied');
    } catch (e) {
      print('[BlockedAppOverlay] forceUnblockTemporary failed: $e');
    }
  }

  Future<void> _unblockAndClose() async {
    try {
      print('[BlockedAppOverlay] Unblocking apps...');
      var packages = await _blockService.getBlockedApps();
      if (packages.isEmpty) {
        final p = _blockedPackageName;
        if (p != null && p.isNotEmpty && p != 'blocked_app') {
          packages = [p];
        }
      }
      if (packages.isEmpty) {
        await _blockService.closeOverlay();
      } else {
        await _blockService.unblockAndClose(packages);
      }
      print('[BlockedAppOverlay] Apps unblocked successfully');
    } catch (e) {
      print('[BlockedAppOverlay] unblockAndClose failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: MindControlGuardLockScreen(
        hasActiveTrade: _hasActiveTrade,
        onWillControl: _willControl,
        onSkip: _forceUnblockTemporary,
      ),
    );
  }
}
