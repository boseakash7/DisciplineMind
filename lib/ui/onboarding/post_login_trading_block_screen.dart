import 'dart:io';

import 'package:discipline_mind/common/app_colors.dart';
import 'package:discipline_mind/common/common.dart';
import 'package:discipline_mind/services/app_block_preferences_service.dart';
import 'package:discipline_mind/services/native_app_block_service.dart';
import 'package:discipline_mind/services/trading_block_bootstrap.dart';
import 'package:discipline_mind/ui/main_home/main_home.dart';
import 'package:discipline_mind/ui/settings/app_block_settings_screen.dart';
import 'package:discipline_mind/ui/widgets/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class PostLoginTradingBlockScreen extends StatefulWidget {
  const PostLoginTradingBlockScreen({super.key});

  @override
  State<PostLoginTradingBlockScreen> createState() =>
      _PostLoginTradingBlockScreenState();
}

class _PostLoginTradingBlockScreenState
    extends State<PostLoginTradingBlockScreen>
    with WidgetsBindingObserver {
  final _blockService = NativeAppBlockService();
  final _prefs = AppBlockPreferencesService();
  bool _busy = false;
  bool _hasOverlay = false;
  bool _hasUsage = false;
  bool _isDark = true;

  String? get _userId => Common.userData.value?.payload?.id?.toString();
  bool get _allGranted => _hasOverlay && _hasUsage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshPermissions();
    }
  }

  Future<void> _refreshPermissions() async {
    if (!Platform.isAndroid) return;

    final p = await _blockService.checkPermissions();

    if (!mounted) return;

    setState(() {
      _hasOverlay = p['hasOverlayPermission'] == true;
      _hasUsage = p['hasUsageStatsPermission'] == true;
    });

    // Auto continue removed as per your request
  }

  // Both buttons trigger both permissions
  Future<void> _requestBothPermissions() async {
    setState(() => _busy = true);

    try {
      // Request Overlay Permission
      if (!_hasOverlay) {
        await _blockService.requestOverlayPermission();
        await Future.delayed(const Duration(milliseconds: 700));
        await _refreshPermissions();
      }

      // Request Usage Stats Permission
      if (!_hasUsage) {
        await _blockService.requestUsageStatsPermission();
        await Future.delayed(const Duration(milliseconds: 700));
        await _refreshPermissions();
      }

      if (!_allGranted && mounted) {
        AppToast.showToast('Please grant both permissions from settings.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _onEnablePermission1() async {
    await _requestBothPermissions();
  }

  Future<void> _onEnablePermission2() async {
    await _requestBothPermissions();
  }

  Future<void> _continue() async {
    final userId = _userId;
    if (userId == null || userId.isEmpty) {
      Get.offAll(() => const MainHomeScreen(initialIndex: 2));
      return;
    }

    setState(() => _busy = true);

    try {
      if (Platform.isAndroid) {
        final updated = await _blockService.checkPermissions();
        final ok = (updated['hasOverlayPermission'] ?? false) &&
            (updated['hasUsageStatsPermission'] ?? false);

        if (!mounted) return;

        if (!ok) {
          AppToast.showToast('Please allow both permissions before continuing.');
          return;
        }
        await applyAndroidTradingAppBlock();
      }

      if (_prefs.isSetupComplete(userId: userId)) {
        Get.offAll(() => const MainHomeScreen(initialIndex: 2));
      } else {
        Get.offAll(() => const AppBlockSettingsScreen(isFirstSetup: true));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!Platform.isAndroid) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final userId = _userId;
        if (userId != null && _prefs.isSetupComplete(userId: userId)) {
          Get.offAll(() => const MainHomeScreen(initialIndex: 2));
        } else if (userId != null) {
          Get.offAll(() => const AppBlockSettingsScreen(isFirstSetup: true));
        } else {
          Get.offAll(() => const MainHomeScreen(initialIndex: 2));
        }
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final bg = _isDark ? const Color(0xFF08080F) : const Color(0xFFF0F0F8);
    final cardBg = _isDark ? const Color(0xFF0F0F1A) : const Color(0xFFFFFFFF);
    final blueAccent = const Color(0xFF3A5BFF);
    final grantedGreen = const Color(0xFF22D47E);
    final textPrimary = _isDark ? Colors.white : const Color(0xFF0A0A18);
    final textMuted = _isDark ? const Color(0xFF8888AA) : const Color(0xFF66667A);
    final iconColor = _isDark ? Colors.white70 : const Color(0xFF0A0A18).withOpacity(0.6);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: (_isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
          .copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: _isDark ? Colors.black : Colors.white,
        systemNavigationBarIconBrightness:
            _isDark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    _ShieldIcon(color: blueAccent),
                    const SizedBox(height: 28),

                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                          height: 1.3,
                        ),
                        children: [
                          const TextSpan(text: 'Permissions required to use '),
                          TextSpan(
                            text: 'Discipline Mind',
                            style: TextStyle(color: blueAccent),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    Text(
                      'We need the following permissions to provide\nyou the best experience',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: textMuted,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Permission Card 1
                    _PermissionCard(
                      cardBg: cardBg,
                      blueAccent: blueAccent,
                      grantedGreen: grantedGreen,
                      btnLabel: 'ENABLE PERMISSION I',
                      statusLabel: 'DISPLAY OVER OTHER APPS GRANTED',
                      granted: _hasOverlay,
                      enableActive: !_hasOverlay,
                      onEnable: _onEnablePermission1,
                      isDark: _isDark,
                    ),
                    const SizedBox(height: 16),

                    // Permission Card 2
                    _PermissionCard(
                      cardBg: cardBg,
                      blueAccent: blueAccent,
                      grantedGreen: grantedGreen,
                      btnLabel: 'ENABLE PERMISSION II',
                      statusLabel: 'USAGE ACCESS PERMISSION GRANTED',
                      granted: _hasUsage,
                      enableActive: _hasOverlay && !_hasUsage,
                      onEnable: _onEnablePermission2,
                      isDark: _isDark,
                    ),

                    const Spacer(),

                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: (_allGranted && !_busy) ? _continue : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: blueAccent,
                          disabledBackgroundColor: _isDark
                              ? const Color(0xFF1A1A2E)
                              : const Color(0xFFD8D8E8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(100),
                          ),
                          elevation: 0,
                        ),
                        child: _busy
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'CONTINUE',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.5,
                                      color: _allGranted
                                          ? Colors.white
                                          : (_isDark
                                              ? const Color(0xFF44445A)
                                              : const Color(0xFFAAAAAA)),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 20,
                                    color: _allGranted
                                        ? Colors.white
                                        : (_isDark
                                            ? const Color(0xFF44445A)
                                            : const Color(0xFFAAAAAA)),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),

              // Positioned(
              //   top: 8,
              //   right: 8,
              //   child: GestureDetector(
              //     onTap: () => setState(() => _isDark = !_isDark),
              //     child: AnimatedContainer(
              //       duration: const Duration(milliseconds: 250),
              //       width: 44,
              //       height: 44,
              //       decoration: BoxDecoration(
              //         color: _isDark
              //             ? const Color(0xFF1A1A2E)
              //             : const Color(0xFFE2E2F0),
              //         borderRadius: BorderRadius.circular(100),
              //       ),
              //       child: Icon(
              //         _isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              //         color: iconColor,
              //         size: 20,
              //       ),
              //     ),
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}

// Permission Card
class _PermissionCard extends StatelessWidget {
  const _PermissionCard({
    required this.cardBg,
    required this.blueAccent,
    required this.grantedGreen,
    required this.btnLabel,
    required this.statusLabel,
    required this.granted,
    required this.enableActive,
    required this.onEnable,
    required this.isDark,
  });

  final Color cardBg;
  final Color blueAccent;
  final Color grantedGreen;
  final String btnLabel;
  final String statusLabel;
  final bool granted;
  final bool enableActive;
  final VoidCallback onEnable;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final bool isActive = enableActive || granted;

    final Color btnBg = isActive ? Colors.white : const Color(0xFF64748B);
    final Color btnText = isActive ? Colors.black : const Color(0xFFCBD5E1);
    final Color btnBorder = isActive ? Colors.white : const Color(0xFF64748B);

    final Color statusColor = granted
        ? grantedGreen
        : (isDark ? const Color(0xFF555570) : const Color(0xFFAAAAAA));

    final Color borderColor = granted
        ? grantedGreen.withOpacity(0.25)
        : (isDark ? const Color(0xFF1E1E35) : const Color(0xFFDDDDEE));

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: enableActive ? onEnable : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: btnBg,
                disabledBackgroundColor: btnBg,
                foregroundColor: btnText,
                disabledForegroundColor: btnText,
                elevation: 0,
                side: BorderSide(color: btnBorder, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              child: Text(
                granted ? '$btnLabel ✓' : btnLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: btnText,
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                granted
                    ? Icons.check_box_rounded
                    : Icons.check_box_outline_blank_rounded,
                color: statusColor,
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                statusLabel,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.9,
                  color: statusColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ShieldIcon extends StatelessWidget {
  const _ShieldIcon({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 86,
      child: CustomPaint(painter: _ShieldPainter(color: color)),
    );
  }
}

class _ShieldPainter extends CustomPainter {
  const _ShieldPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final shield = Path()
      ..moveTo(w * 0.5, 0)
      ..lineTo(w * 0.92, h * 0.18)
      ..lineTo(w * 0.92, h * 0.52)
      ..cubicTo(w * 0.92, h * 0.78, w * 0.72, h * 0.93, w * 0.5, h)
      ..cubicTo(w * 0.28, h * 0.93, w * 0.08, h * 0.78, w * 0.08, h * 0.52)
      ..lineTo(w * 0.08, h * 0.18)
      ..close();
    canvas.drawPath(shield, strokePaint);

    canvas.drawCircle(Offset(w * 0.5, h * 0.43), w * 0.13, strokePaint);

    final stemPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final stem = Path()
      ..moveTo(w * 0.42, h * 0.56)
      ..lineTo(w * 0.38, h * 0.72)
      ..lineTo(w * 0.62, h * 0.72)
      ..lineTo(w * 0.58, h * 0.56)
      ..close();
    canvas.drawPath(stem, stemPaint);
  }

  @override
  bool shouldRepaint(_ShieldPainter old) => old.color != color;
}