import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_storage/get_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/native_app_block_service.dart';
import 'mind_control_guard_consent_screen.dart';
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
  bool _hasActiveTrade = false;
  bool _hasConsent = false;

  void _safeSetState(VoidCallback fn) {
    if (mounted) setState(fn);
  }

  @override
  void initState() {
    super.initState();
    final consent = _storage.read<bool>('mct_guard_consent_accepted') ?? false;
    _safeSetState(() {
      _hasConsent = consent;
      _blockedPackageName = 'blocked_app';
    });
    _initConsentCheck();
    _refreshLockStatus();
  }

  Future<void> _initConsentCheck() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final consent = prefs.getBool('mct_guard_consent_accepted') ??
          (_storage.read<bool>('mct_guard_consent_accepted') ?? false);
      if (mounted && _hasConsent != consent) {
        _safeSetState(() => _hasConsent = consent);
      }
    } catch (_) {}
  }

  Future<void> _onConsentAgreed() async {
    try {
      await _storage.write('mct_guard_consent_accepted', true);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('mct_guard_consent_accepted', true);
    } catch (_) {}
    _safeSetState(() => _hasConsent = true);
  }

  Future<void> _refreshLockStatus() async {
    try {
      final pkg = await _channel.invokeMethod<String>('getCurrentBlockedApp');
      if (pkg != null && pkg.isNotEmpty) {
        _safeSetState(() => _blockedPackageName = pkg);
      }
      final active = await _blockService.hasActiveTrade();
      if (mounted && active) {
        _safeSetState(() => _hasActiveTrade = true);
      }
    } catch (_) {}
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

  @override
  Widget build(BuildContext context) {
    if (!_hasConsent) {
      return MindControlGuardConsentScreen(
        onAgree: _onConsentAgreed,
        onCancel: _willControl,
      );
    }

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
