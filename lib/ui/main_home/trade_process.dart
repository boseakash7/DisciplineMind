import 'dart:io';
import 'dart:math' as math;

import 'package:app_limiter/app_limiter.dart';
import 'package:discipline_mind/model/trading_app_model.dart';
import 'package:discipline_mind/services/api/api_services.dart';
import 'package:discipline_mind/services/api/api_url.dart';
import 'package:discipline_mind/services/app_block_preferences_service.dart';
import 'package:discipline_mind/services/native_app_block_service.dart';
import 'package:discipline_mind/services/notification/notification_handler.dart';
import 'package:discipline_mind/services/trading_apps_service.dart';
import 'package:discipline_mind/services/trading_block_bootstrap.dart';
import 'package:discipline_mind/services/app_url_launcher.dart';
import 'package:discipline_mind/ui/widgets/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

// ============================================================================
// TYPE SCALE — single source of truth for text sizes across this flow.
// ============================================================================
class _Type {
  static const double micro = 10;
  static const double caption = 11;
  static const double body = 12;
  static const double bodyStrong = 12;
  static const double label = 13;
  static const double value = 14;
  static const double cardTitle = 15;
  static const double sectionTitle = 16;
  static const double screenSubtitle = 13;
  static const double screenTitle = 20;
  static const double heading = 24;
  static const double buttonLabel = 15;
  static const double logo = 47;
  static const double logoBadge = 22;
  static const double hero = 56;
}

enum _TradingSetup { zenoSignals, custom }

class TradingProcessScreen extends StatefulWidget {
  const TradingProcessScreen({
    super.key,
    required this.userId,
    this.skipWelcome = false,
  });

  final String userId;
  final bool skipWelcome;

  @override
  State<TradingProcessScreen> createState() => _TradingProcessScreenState();
}

class _TradingProcessScreenState extends State<TradingProcessScreen>
    with WidgetsBindingObserver {
  late final PageController _pageController = PageController(
    initialPage: widget.skipWelcome ? 1 : 0,
  );
  final TextEditingController _capitalController = TextEditingController();
  final FocusNode _capitalFocusNode = FocusNode();

  // ============================================================
  // COLORS
  // ============================================================

  static const Color purple = Color(0xFF4A22F4);
  static const Color violet = Color(0xFF983BF4);
  static const Color ink = Color(0xFF10122D);
  static const Color grey = Color(0xFF70717F);

  static const Color border = Color(0xFFE2E0E9);

  static const Color green = Color(0xFF208052);
  static const Color lightGreen = Color(0xFFF0FAF6);

  static const Color red = Color(0xFFCC3B4D);

  static const Color disabled = Color(0xFFB8B4C5);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [purple, violet],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // ============================================================
  // CAPITAL LIMITS
  // ============================================================

  static const int minCapital = 1000;
  static const int maxCapital = 999999999;

  // ============================================================
  // STATE
  // ============================================================

  late int currentPage = widget.skipWelcome ? 1 : 0;

  String? tradingSegment;
  String? instrument = 'Nifty 50'; // Default to Nifty 50 since Step 2 is removed/commented out
  String? brokerage;

  _TradingSetup _tradingSetup = _TradingSetup.zenoSignals;

  bool get _followsZenoSignals => _tradingSetup == _TradingSetup.zenoSignals;

  // The existing process API requires a trade limit and market entry time.
  int? get _effectiveTradesPerDay => _followsZenoSignals ? 1 : tradesPerDay;

  int tradingCapital = 200000;
  int? tradesPerDay;
  TimeOfDay? marketEntryTimeOfDay = const TimeOfDay(hour: 9, minute: 15);

  bool termsAccepted = false;
  bool _isCapitalEditable = false;
  bool _isSubmitting = false;

  int get maxRiskPerTrade => (tradingCapital * 0.02).round();

  String get capitalInWords => tradingCapital > 0
      ? '${_numberToWordsIndian(tradingCapital)} Rupees Only'
      : 'Zero Rupees Only';

  bool get isCapitalValid =>
      tradingCapital >= minCapital && tradingCapital <= maxCapital;

  bool get _capitalStepValid =>
      isCapitalValid &&
      (_followsZenoSignals ||
          (tradesPerDay != null && marketEntryTimeOfDay != null));

  String? get capitalErrorText {
    if (tradingCapital <= 0) return 'Enter your trading capital';
    if (tradingCapital < minCapital) {
      return 'Minimum capital is ₹${_formatIndianNumber(minCapital)}';
    }
    if (tradingCapital > maxCapital) {
      return 'Maximum capital is ₹${_formatIndianNumber(maxCapital)}';
    }
    return null;
  }

  // ============================================================
  // PERMISSIONS (merged in from the old post-login permission screen)
  // ============================================================

  final _blockService = NativeAppBlockService();
  final _prefs = AppBlockPreferencesService();

  bool _permissionBusy = false;
  bool _hasOverlay = false;
  bool _hasUsage = false;

  // Guards against overlapping calls to _refreshPermissions (e.g. the
  // lifecycle "resumed" callback firing while another check is in flight).
  bool _refreshInFlight = false;

  // True while we are waiting for the user to come back from the system
  // Settings screen after tapping "Enable Permission". Used so we only
  // show the "please grant" toast once they've actually had a chance to
  // grant it (on resume), never before.
  bool _awaitingPermissionResult = false;

  bool get _allPermissionsGranted => _hasOverlay && _hasUsage;

  TradingAppsService get _tradingAppsService {
    if (!Get.isRegistered<TradingAppsService>()) {
      Get.put(TradingAppsService(), permanent: true);
    }
    return Get.find<TradingAppsService>();
  }

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
    _refreshPermissions();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tradingAppsService.ensureLoaded();
    });

    final savedCapital =
        GetStorage().read('mct_trading_capital_${widget.userId}');
    if (savedCapital is int && savedCapital > 0) {
      tradingCapital = savedCapital;
      _capitalController.text = _formatIndianNumber(savedCapital);
    } else {
      tradingCapital = 200000;
      _capitalController.text = '2,00,000';
    }

    _capitalFocusNode.addListener(() {
      if (!_capitalFocusNode.hasFocus && mounted) {
        setState(() {
          _isCapitalEditable = false;
        });
      }
    });
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    _capitalController.dispose();
    _capitalFocusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    if (state == AppLifecycleState.resumed) {
      final wasAwaitingResult = _awaitingPermissionResult;
      _awaitingPermissionResult = false;

      _refreshPermissions(showToastIfMissing: wasAwaitingResult).then((_) {
        if (!mounted) return;
        if (_permissionBusy) {
          setState(() => _permissionBusy = false);
        }
      });
    }
  }

  /// Single source of truth for checking + reacting to permission state.
  /// Only this method decides whether to auto-advance to the next step,
  /// which avoids the double-trigger race that used to happen when both
  /// the button-tap flow and the app-resume flow tried to advance pages
  /// independently.
  Future<void> _refreshPermissions({bool showToastIfMissing = false}) async {
    if (!Platform.isAndroid) return;
    if (!mounted) return;
    if (_refreshInFlight) return;
    _refreshInFlight = true;

    try {
      final p = await _blockService.checkPermissions();
      if (!mounted) return;

      final newOverlay = p['hasOverlayPermission'] == true;
      final newUsage = p['hasUsageStatsPermission'] == true;

      setState(() {
        _hasOverlay = newOverlay;
        _hasUsage = newUsage;
      });

      if (newOverlay && newUsage) {
        checkAndStartTradingBlockIfPermitted(explicitUserId: widget.userId);
        if (brokerage != null && brokerage!.isNotEmpty) {
          final pkg = _getBrokerPackageName(brokerage!);
          _prefs.saveSelectedPackage(
            userId: widget.userId,
            packageName: pkg,
          );
          GetStorage().write('mct_brokerage_${widget.userId}', brokerage);
          _blockService.saveUserIdForOverlay(widget.userId);
          _blockService.blockApp(pkg);
          applyAndroidTradingAppBlock(explicitUserId: widget.userId);
        }
      }

      if (!mounted) return;

      // Only advance / warn based on whichever permission step the user
      // is actually sitting on right now.
      if (currentPage == 5) {
        if (newOverlay) {
          nextPage();
        } else if (showToastIfMissing) {
          AppToast.showToast(
            'Please grant the "Display over other apps" permission.',
          );
        }
      } else if (currentPage == 6) {
        if (newUsage) {
          nextPage();
        } else if (showToastIfMissing) {
          AppToast.showToast('Please grant the "Usage Access" permission.');
        }
      }
    } finally {
      _refreshInFlight = false;
    }
  }

  Future<void> _requestOverlayPermission() async {
    setState(() {
      _permissionBusy = true;
      _awaitingPermissionResult = true;
    });
    // This opens the system Settings screen. We do NOT check the result
    // here — the app will be paused while the user is in Settings, and
    // didChangeAppLifecycleState(resumed) will pick up the result as soon
    // as they come back. Checking here on a fixed timer used to race with
    // that callback and could fire navigation twice.
    await _blockService.requestOverlayPermission();
  }

  Future<void> _requestUsagePermission() async {
    setState(() {
      _permissionBusy = true;
      _awaitingPermissionResult = true;
    });
    await _blockService.requestUsageStatsPermission();
  }

  // ============================================================
  // NAVIGATION
  //
  // Pages: 0 = Welcome, 1 = Segment, (Step 2 Instrument commented out),
  // 2 = Setup, 3 = Capital, 4 = Broker, 5/6 = Permissions, 7 = Success.
  // ============================================================

  void nextPage() {
    if (!mounted) return;
    if (currentPage >= 7) return;

    if (currentPage == 3 && !_capitalStepValid) {
      setState(() {});
      return;
    }

    var next = currentPage + 1;

    if (Platform.isAndroid) {
      if (next == 5 && _hasOverlay) next = 6;
      if (next == 6 && _hasUsage) next = 7;
    } else if (next == 5) {
      // No permission steps needed off Android.
      next = 7;
    }

    setState(() {
      currentPage = next;
    });

    if (mounted && _pageController.hasClients) {
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    }
  }

  void previousPage() {
    if (!mounted) return;
    final floor = widget.skipWelcome ? 1 : 0;
    if (currentPage <= floor) return;

    var previous = currentPage - 1;

    if (!Platform.isAndroid && (previous == 5 || previous == 6)) {
      previous = 4;
    }

    setState(() {
      currentPage = previous;
    });

    if (mounted && _pageController.hasClients) {
      _pageController.animateToPage(
        previous,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final floor = widget.skipWelcome ? 1 : 0;

    // Intercept the system back button / predictive-back gesture so that,
    // while inside this multi-step flow, it steps back one page instead
    // of popping the entire screen. This is what was causing the flow to
    // suddenly exit ("automatic back") right after returning from the
    // Settings permission screen — the OS back navigation was reaching
    // this route with nothing to stop it.
    return PopScope(
      canPop: currentPage <= floor,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        previousPage();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _welcomeScreen(),
              _step1Screen(),
              // _step2Screen(), // Commented out as requested - Step 2 is removed from onboarding flow
              _setupSelectionScreen(),
              _followsZenoSignals ? _zenoCapitalScreen() : _step3Screen(),
              _step4Screen(),
              _permissionStep1Screen(),
              _permissionStep2Screen(),
              _successScreen(),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // COMMON PAGE
  // ============================================================

  Widget _page({required Widget child}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = math.max(0.0, constraints.maxHeight - 16);

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: height),
            child: IntrinsicHeight(child: child),
          ),
        );
      },
    );
  }

  // ============================================================
  // WELCOME
  // ============================================================

  Widget _welcomeScreen() {
    return _page(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),
          _zenoLogoImage(),
          const SizedBox(height: 14),
          _welcomeHeroGraphic(),
          const SizedBox(height: 16),
          const Text(
            'Create Your\nMind Control Trading\nProcess',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 23,
              height: 1.22,
              fontWeight: FontWeight.w800,
              color: ink,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 9),
          const Text(
            'Your trading process defines how you will trade —\nbefore the market starts.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.35,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'MCT Helps You Control',
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: ink,
            ),
          ),
          const SizedBox(height: 10),
          _mctControlCardsRow(),
          const SizedBox(height: 14),
          _mctProcessDefinesCard(),
          const SizedBox(height: 18),
          _gradientButton(
            text: 'Create My MCT Process',
            trailing: const Icon(
              Icons.arrow_forward_rounded,
              color: Colors.white,
              size: 18,
            ),
            onTap: nextPage,
          ),
          const SizedBox(height: 14),
          _welcomeBottom(),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _zenoLogoImage() {
    return Center(
      child: Image.asset(
        'assets/new_logo_zeno_ai.jpg',
        height: 42,
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _welcomeHeroGraphic() {
    return SizedBox(
      height: 120,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _HeroCandlestickBackgroundPainter(),
            ),
          ),
          SizedBox(
            width: 106,
            height: 94,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Image.asset(
                  'assets/brain.png',
                  width: 80,
                  height: 80,
                  fit: BoxFit.contain,
                ),
                Positioned(
                  right: 2,
                  bottom: 6,
                  child: Container(
                    width: 32,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4A22F4), Color(0xFF7C3AED)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4A22F4).withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mctControlCardsRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _mctPillarCard(
            icon: Icons.psychology_rounded,
            title: 'Your Mind',
            description: 'Stay away from FOMO, fear and revenge trading.',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _mctPillarCard(
            icon: Icons.track_changes_rounded,
            title: 'Your Process',
            description: 'Follow only the trades that match your defined setup.',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _mctPillarCard(
            icon: Icons.shield_outlined,
            title: 'Your Risk',
            description:
                'Trade with controlled position sizing and predefined risk.',
          ),
        ),
      ],
    );
  }

  Widget _mctPillarCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 140),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFECE9F6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFF3EFFF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF5124FF), size: 19),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: ink,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            description,
            style: const TextStyle(
              fontSize: 10.5,
              height: 1.32,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mctProcessDefinesCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F7FD),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFECE8F8)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFEDE8FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.assignment_outlined,
              color: Color(0xFF5124FF),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your MCT Process will define:',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: ink,
                  ),
                ),
                const SizedBox(height: 8),
                _mctCheckItem('What you trade'),
                const SizedBox(height: 5),
                _mctCheckItem('How much capital you use'),
                const SizedBox(height: 5),
                _mctCheckItem('How much you risk per trade'),
                const SizedBox(height: 5),
                _mctCheckItem('When to stop receiving trade signals'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _mctCheckItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Icon(
          Icons.check_circle_rounded,
          color: Color(0xFF5124FF),
          size: 15,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF505565),
              height: 1.25,
            ),
          ),
        ),
      ],
    );
  }

  Widget _welcomeBottom() {
    return SizedBox(
      height: 24,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              7,
              (index) => Container(
                width: index == 0 ? 8 : 7,
                height: index == 0 ? 8 : 7,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index == 0 ? purple : const Color(0xFFD9D7E3),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: nextPage,
              child: const Text(
                'Skip',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: ink,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STEP 1
  // ============================================================

  Widget _step1Screen() {
    return _normalStep(
      step: 1,
      title: 'Trading Segment',
      subtitle: 'Choose how you want to trade',
      onNext: () {
        if (tradingSegment == null) {
          AppToast.showToast(
            'Please select a trading segment (Options or Futures)',
          );
          return;
        }
        nextPage();
      },
      content: [
        _largeOptionCard(
          title: 'Options',
          subtitle: 'Trade with defined risk',
          icon: Icons.bar_chart_rounded,
          selected: tradingSegment == 'Options',
          onTap: () => setState(() => tradingSegment = 'Options'),
        ),
        _largeOptionCard(
          title: 'Futures',
          subtitle: 'Trade with lower margin',
          icon: Icons.link_rounded,
          selected: tradingSegment == 'Futures',
          onTap: () => setState(() => tradingSegment = 'Futures'),
        ),
      ],
    );
  }

  // ============================================================
  // STEP 2
  // ============================================================

  Widget _step2Screen() {
    return _normalStep(
      step: 2,
      title: 'Select Instrument',
      subtitle: 'Choose the index you want to trade',
      onNext: () {
        if (instrument == null) {
          AppToast.showToast(
            'Please select an instrument (Nifty 50, BankNifty, or Sensex)',
          );
          return;
        }
        nextPage();
      },
      content: [
        _instrumentCard(
          title: 'Nifty 50',
          selected: instrument == 'Nifty 50',
          type: InstrumentType.nifty,
          onTap: () => setState(() => instrument = 'Nifty 50'),
        ),
        _instrumentCard(
          title: 'BankNifty',
          selected: instrument == 'BankNifty',
          type: InstrumentType.bank,
          onTap: () => setState(() => instrument = 'BankNifty'),
        ),
        _instrumentCard(
          title: 'Sensex',
          selected: instrument == 'Sensex',
          type: InstrumentType.sensex,
          onTap: () => setState(() => instrument = 'Sensex'),
        ),
        const Spacer(),
        _masterInstrumentCard(),
        const SizedBox(height: 12),
      ],
    );
  }

  // ============================================================
  // STEP 3 — TRADING CAPITAL & RULES
  // ============================================================

  static const Color _referencePurple = Color(0xFF5124FF);
  static const LinearGradient _referenceGradient = LinearGradient(
    colors: [Color(0xFF4D22F3), Color(0xFF973AF4)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  /// Presentation shared only by the two screens from the supplied references.
  Widget _referenceStep({
    required int step,
    required String title,
    required String subtitle,
    required List<Widget> content,
    bool capital = false,
    VoidCallback? onNext,
  }) {
    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: Theme.of(context).textTheme.apply(fontFamily: 'Roboto'),
      ),
      child: DefaultTextStyle.merge(
        style: const TextStyle(fontFamily: 'Roboto', color: ink),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: math.max(0, constraints.maxHeight - 22),
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _header(step, reference: true),
                      SizedBox(height: capital ? 26 : 24),
                      Text(
                        title,
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: capital ? 23 : 21,
                          fontWeight: FontWeight.w600,
                          color: ink,
                          height: 1.2,
                          letterSpacing: -0.4,
                        ),
                      ),
                      SizedBox(height: capital ? 8 : 7),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: capital ? 15 : 13,
                          height: capital ? 1.5 : 1.35,
                          color: ink,
                        ),
                      ),
                      SizedBox(height: capital ? 25 : 17),
                      ...content,
                      const Spacer(),
                      Container(
                        height: capital ? 48 : 44,
                        decoration: BoxDecoration(
                          gradient: _referenceGradient,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(9),
                            onTap: onNext ?? nextPage,
                            child: Center(
                              child: Text(
                                'Next',
                                style: TextStyle(
                                  fontFamily: 'Roboto',
                                  color: Colors.white,
                                  fontSize: capital ? 17 : 16,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _setupSelectionScreen() {
    return _referenceStep(
      step: 3,
      title: 'Select Trading Setup',
      subtitle: 'Choose how you want to get your trade setups',
      content: [
        _setupOptionCard(
          setup: _TradingSetup.zenoSignals,
          title: 'Follow Zeno AI Signals',
          subtitle: 'Trade ready setups by Registered Analyst',
          icon: Icons.bar_chart_rounded,
          features: const [
            'Pre-defined, researched setups',
            'Clear entry, exit and stop loss levels',
            'Backed by Registered Analyst',
            'Designed for disciplined trading',
          ],
        ),
        const SizedBox(height: 12),
        _setupOptionCard(
          setup: _TradingSetup.custom,
          title: 'Create My Own Setup',
          subtitle: 'Create a setup using your own indicators',
          icon: Icons.edit_outlined,
          features: const [
            'Choose and customize your own indicators',
            'Indicators will decide your entry, stop loss and target',
            'Define your own rules and conditions',
            'Ideal for advanced traders',
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F5FE),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE8FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.lightbulb_outline_rounded,
                  color: _referencePurple,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recommended for Most Traders',
                      style: TextStyle(
                        color: Color(0xFF5124FF),
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'To build discipline and consistency, we recommend using Zeno AI signals by Registered Analyst.',
                      style: TextStyle(
                        color: Color(0xFF6C697D),
                        fontSize: 12.5,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _setupOptionCard({
    required _TradingSetup setup,
    required String title,
    required String subtitle,
    required IconData icon,
    required List<String> features,
  }) {
    final selected = _tradingSetup == setup;
    final cardContent = Material(
      color: selected ? const Color(0xFFFAF7FE) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: selected
            ? const BorderSide(color: _referencePurple, width: 1.5)
            : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => setState(() => _tradingSetup = setup),
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: selected ? _referenceGradient : null,
                      color: selected ? null : const Color(0xFFEDE8FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      size: 24,
                      color: selected ? Colors.white : _referencePurple,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: ink,
                            fontSize: 15.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: Color(0xFF7A798A),
                            fontSize: 12.5,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: selected
                        ? _referencePurple
                        : const Color(0xFFCCCAD8),
                    size: 21,
                  ),
                ],
              ),
              if (setup == _TradingSetup.zenoSignals) ...[
                const SizedBox(height: 10),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4.5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4F5E4),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const Icon(
                              Icons.verified_user_rounded,
                              color: Color(0xFF0E874E),
                              size: 15,
                            ),
                          ],
                        ),
                        const SizedBox(width: 5),
                        const Text(
                          'Registered Analyst',
                          style: TextStyle(
                            color: Color(0xFF0E7A46),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              for (final feature in features)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3.5),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 16,
                        color: selected
                            ? _referencePurple
                            : const Color(0xFFCCCAD8),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          feature,
                          style: TextStyle(
                            color: selected
                                ? const Color(0xFF565466)
                                : const Color(0xFF8E8D9E),
                            fontSize: 12.5,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: selected
          ? cardContent
          : CustomPaint(
              foregroundPainter: const _DottedBorderPainter(
                color: Color(0xFFCCCAD8),
                radius: 10,
                strokeWidth: 1.2,
                dashLength: 4.0,
                gapLength: 3.5,
              ),
              child: cardContent,
            ),
    );
  }

  Widget _zenoCapitalScreen() {
    return _referenceStep(
      step: 4,
      capital: true,
      title: 'Trading Capital',
      subtitle:
          'Enter your trading capital to calculate your recommended risk per trade.',
      onNext: () {
        if (!isCapitalValid) {
          AppToast.showToast(capitalErrorText!);
          return;
        }
        _capitalFocusNode.unfocus();
        nextPage();
      },
      content: [
        const Text(
          'Trading Capital',
          style: TextStyle(
            color: ink,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        _capitalField(signalStyle: true),
        if (tradingCapital > 0 && capitalErrorText != null) ...[
          const SizedBox(height: 5),
          Text(
            capitalErrorText!,
            style: const TextStyle(color: red, fontSize: _Type.caption),
          ),
        ],
        const SizedBox(height: 12),
        _wordsCard(signalStyle: true),
        const SizedBox(height: 16),
        _riskManagementCard(),
        const SizedBox(height: 14),
        _dailyTradeProtectionCard(),
        const SizedBox(height: 14),
        _disciplineConsistencyCard(),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _riskManagementCard() {
    final minRisk = (tradingCapital * 0.0075).round();
    final maxRisk = (tradingCapital * 0.015).round();
    final riskRangeText = tradingCapital > 0
        ? '₹${_formatIndianNumber(minRisk)} – ₹${_formatIndianNumber(maxRisk)} per trade'
        : '₹1,500 – ₹3,000 per trade';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F8FE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFECE8F8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE8FF),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.bar_chart_rounded,
                  color: _referencePurple,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Risk Management',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: ink,
                    ),
                  ),
                  SizedBox(height: 1),
                  Text(
                    'Your Risk Per Trade',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Based on your trading capital, we recommend a risk range per trade.',
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 12,
              color: Color(0xFF595B6E),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFDED8F8)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text(
                      'Recommended Risk Range',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: ink,
                      ),
                    ),
                    Spacer(),
                    Icon(
                      Icons.info_outline_rounded,
                      color: _referencePurple,
                      size: 18,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  '0.75% – 1.5%',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: _referencePurple,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  riskRangeText,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _referencePurple,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dailyTradeProtectionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6EE),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFFFEAD9),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(
              Icons.shield_rounded,
              color: Color(0xFFF25822),
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Daily Trade Protection',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFD32F2F),
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Maximum 2 Stop Losses or 2 Targets per day.',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFD32F2F),
                  ),
                ),
                const SizedBox(height: 6),
                RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 11.5,
                      height: 1.35,
                      color: Color(0xFF595B6E),
                    ),
                    children: [
                      TextSpan(
                        text:
                            'Once you reach either limit, trade signals will automatically stop for the day. ',
                      ),
                      TextSpan(
                        text:
                            'This will help you avoid overtrading and protect your gains.',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _disciplineConsistencyCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F5FE),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFEDE8FF),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(
              Icons.track_changes_rounded,
              color: _referencePurple,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trade with discipline. Stay consistent.',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _referencePurple,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'We automatically manage your position sizing based on your capital and defined risk limits.',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 11.5,
                    height: 1.35,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _setupInfoCard({
    required IconData icon,
    required String title,
    required String description,
    bool positive = false,
    bool compact = false,
    Widget? footer,
  }) {
    final accent = positive ? green : _referencePurple;
    return Container(
      padding: EdgeInsets.all(compact ? 12 : 15),
      decoration: BoxDecoration(
        color: positive
            ? const Color(0xFFF2FBF8)
            : (compact ? const Color(0xFFF7F4FF) : const Color(0xFFF9F8FE)),
        border: compact || positive
            ? null
            : Border.all(color: const Color(0xFFEEECF2)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: compact ? 34 : (positive ? 28 : 42),
                height: compact ? 34 : (positive ? 28 : 42),
                decoration: BoxDecoration(
                  color: positive ? green : const Color(0xFFEEE8FF),
                  borderRadius: BorderRadius.circular(compact ? 9 : 10),
                ),
                child: Icon(
                  icon,
                  color: positive ? Colors.white : accent,
                  size: compact ? 23 : 27,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: positive
                            ? green
                            : (compact ? _referencePurple : ink),
                        fontSize: compact ? 11 : 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      description,
                      style: TextStyle(
                        color: compact
                            ? const Color(0xFF777683)
                            : const Color(0xFF898A95),
                        fontSize: compact ? 10 : 13,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (footer != null) ...[const SizedBox(height: 16), footer],
        ],
      ),
    );
  }

  Widget _step3Screen() {
    return _normalStep(
      step: 4,
      title: 'Trading Capital & Rules',
      subtitle: 'Set your capital and trading discipline',
      onNext: () {
        if (tradingCapital <= 0) {
          AppToast.showToast('Please enter your trading capital');
          return;
        }
        if (tradingCapital < minCapital) {
          AppToast.showToast(
            'Minimum capital is ₹${_formatIndianNumber(minCapital)}',
          );
          return;
        }
        if (tradingCapital > maxCapital) {
          AppToast.showToast(
            'Maximum capital is ₹${_formatIndianNumber(maxCapital)}',
          );
          return;
        }
        if (_effectiveTradesPerDay == null) {
          AppToast.showToast('Please select trades per day (1 or 2 trades)');
          return;
        }
        if (marketEntryTimeOfDay == null) {
          AppToast.showToast('Please select market entry time');
          return;
        }
        nextPage();
      },
      content: [
        const Text(
          'Trading Capital',
          style: TextStyle(
            fontSize: _Type.body,
            fontWeight: FontWeight.w700,
            color: ink,
          ),
        ),
        const SizedBox(height: 6),
        _capitalField(),
        if (capitalErrorText != null) ...[
          const SizedBox(height: 5),
          Text(
            capitalErrorText!,
            style: const TextStyle(
              fontSize: _Type.caption,
              fontWeight: FontWeight.w600,
              color: red,
            ),
          ),
        ],
        const SizedBox(height: 8),
        _wordsCard(),
        const SizedBox(height: 13),
        _tradingPlanCard(),
        if (tradesPerDay == 2) ...[
          const SizedBox(height: 9),
          _twoTradesWarningCard(),
        ],
        const SizedBox(height: 10),
        _marketTimeField(),
        const SizedBox(height: 9),
        _smartRuleCard(),
      ],
    );
  }

  Widget _capitalField({bool signalStyle = false}) {
    final hasError =
        capitalErrorText != null && (!signalStyle || tradingCapital > 0);

    return Container(
      height: signalStyle ? 49 : 46,
      padding: const EdgeInsets.symmetric(horizontal: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: hasError
              ? red
              : (signalStyle || _isCapitalEditable
                    ? purple
                    : const Color(0xFFD5D2E1)),
          width: hasError || _isCapitalEditable ? 1.2 : 1,
        ),
      ),
      child: Row(
        children: [
          Text(
            '₹',
            style: TextStyle(
              fontSize: _Type.value,
              fontWeight: FontWeight.w600,
              color: ink,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: TextField(
              controller: _capitalController,
              focusNode: _capitalFocusNode,
              readOnly: !_isCapitalEditable,
              showCursor: _isCapitalEditable,
              keyboardType: const TextInputType.numberWithOptions(
                signed: false,
                decimal: false,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                _IndianCurrencyInputFormatter(max: maxCapital),
              ],
              style: TextStyle(
                fontFamily: signalStyle ? 'Roboto' : null,
                fontSize: signalStyle ? 18 : _Type.value,
                fontWeight: FontWeight.w700,
                color: ink,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                hintText: '0',
              ),
              onChanged: _onCapitalChanged,
              onTap: () {
                if (!_isCapitalEditable) {
                  setState(() => _isCapitalEditable = true);
                  _capitalController.selection = TextSelection.collapsed(
                    offset: _capitalController.text.length,
                  );
                }
              },
              onEditingComplete: () {
                setState(() => _isCapitalEditable = false);
                _capitalFocusNode.unfocus();
              },
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (_isCapitalEditable) {
                // Confirm and exit edit mode — this used to just re-enter
                // edit mode every time, so the "done" check icon never
                // actually finished editing.
                setState(() => _isCapitalEditable = false);
                _capitalFocusNode.unfocus();
              } else {
                setState(() => _isCapitalEditable = true);
                _capitalFocusNode.requestFocus();
                _capitalController.selection = TextSelection.collapsed(
                  offset: _capitalController.text.length,
                );
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                (_isCapitalEditable || (signalStyle && isCapitalValid))
                    ? Icons.check_circle_rounded
                    : Icons.edit_outlined,
                size: signalStyle ? 22 : 16,
                color: _isCapitalEditable || (signalStyle && isCapitalValid)
                    ? const Color(0xFF0EA568)
                    : ink,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onCapitalChanged(String formattedValue) {
    final digitsOnly = formattedValue.replaceAll(RegExp(r'[^0-9]'), '');
    final parsed = digitsOnly.isEmpty ? 0 : int.parse(digitsOnly);
    setState(() => tradingCapital = parsed);
  }

  Widget _wordsCard({bool signalStyle = false}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: 14,
        vertical: signalStyle ? 10 : 8,
      ),
      decoration: BoxDecoration(
        color: signalStyle ? const Color(0xFFF0FDF6) : lightGreen,
        borderRadius: BorderRadius.circular(9),
        border: signalStyle
            ? null
            : Border.all(color: const Color(0xFFD7EEE4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'In words:',
            style: TextStyle(
              fontSize: signalStyle ? 11.5 : _Type.micro,
              color: grey,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            capitalInWords,
            style: TextStyle(
              fontSize: signalStyle ? 14 : _Type.body,
              fontWeight: FontWeight.w700,
              color: signalStyle
                  ? const Color(0xFF0E874E)
                  : const Color(0xFF285B4A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tradingPlanCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF9FE),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE6E3EF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Trading Plan',
            style: TextStyle(
              fontSize: _Type.body,
              fontWeight: FontWeight.w800,
              color: ink,
            ),
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Number of Trades per Day',
                  style: TextStyle(
                    fontSize: _Type.caption,
                    fontWeight: FontWeight.w600,
                    color: ink,
                  ),
                ),
              ),
              _tradeButton(1),
              const SizedBox(width: 5),
              _tradeButton(2),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Max Risk per Trade (2% of Capital)',
                  style: TextStyle(
                    fontSize: _Type.caption,
                    fontWeight: FontWeight.w600,
                    color: ink,
                  ),
                ),
              ),
              Text(
                '₹${_formatIndianNumber(maxRiskPerTrade)}',
                style: const TextStyle(
                  fontSize: _Type.value,
                  fontWeight: FontWeight.w800,
                  color: green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Market Entry From',
                  style: TextStyle(
                    fontSize: _Type.caption,
                    fontWeight: FontWeight.w600,
                    color: ink,
                  ),
                ),
              ),
              Text(
                marketEntryTimeOfDay != null
                    ? marketEntryTimeOfDay!.format(context)
                    : '--:--',
                style: TextStyle(
                  fontSize: _Type.value,
                  fontWeight: FontWeight.w800,
                  color: marketEntryTimeOfDay != null ? green : grey,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.access_time_rounded, color: green, size: 12),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tradeButton(int value) {
    final selected = tradesPerDay == value;

    return GestureDetector(
      onTap: () => setState(() => tradesPerDay = value),
      child: Container(
        width: 39,
        height: 26,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? purple : Colors.white,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: selected ? purple : const Color(0xFFE0DDE8),
          ),
        ),
        child: Text(
          '$value',
          style: TextStyle(
            fontSize: _Type.caption,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : ink,
          ),
        ),
      ),
    );
  }

  Widget _twoTradesWarningCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6EC),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: const Color(0xFFFBE3C4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: const Color(0xFFFCE7CB),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFFB4700A),
              size: 14,
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'A second trade raises the risk of overtrading and '
              'revenge trading. Only take it if your first trade '
              'followed your plan exactly.',
              style: TextStyle(
                fontSize: _Type.caption,
                height: 1.3,
                fontWeight: FontWeight.w600,
                color: Color(0xFF8A5A0A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _marketTimeField() {
    return GestureDetector(
      onTap: _pickMarketTime,
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: const Color(0xFFD5D2E1)),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time_rounded, color: purple, size: 18),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Market Entry Time',
                style: TextStyle(
                  fontSize: _Type.body,
                  fontWeight: FontWeight.w600,
                  color: ink,
                ),
              ),
            ),
            Text(
              marketEntryTimeOfDay != null
                  ? marketEntryTimeOfDay!.format(context)
                  : 'Select Time',
              style: TextStyle(
                fontSize: _Type.value,
                fontWeight: FontWeight.w700,
                color: marketEntryTimeOfDay != null ? ink : grey,
              ),
            ),
            const SizedBox(width: 5),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 17),
          ],
        ),
      ),
    );
  }

  Widget _smartRuleCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
      decoration: BoxDecoration(
        color: lightGreen,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: green,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 14),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Smart rule: Trade only with 2% risk.\n'
              'Protect capital. Build consistency.',
              style: TextStyle(
                fontSize: _Type.caption,
                height: 1.3,
                fontWeight: FontWeight.w600,
                color: Color(0xFF285B4A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickMarketTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: marketEntryTimeOfDay ?? const TimeOfDay(hour: 9, minute: 15),
    );

    if (picked == null) return;
    setState(() => marketEntryTimeOfDay = picked);
  }

  // ============================================================
  // STEP 4
  // ============================================================

  Widget _step4Screen() {
    return _normalStep(
      step: 5,
      title: 'Select Your Broker App',
      subtitle:
          'Choose the trading app you use. Zeno AI will monitor '
          'only this app to help you stay focused and disciplined.',
      customBottom: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: brokerage != null
            ? _gradientButton(
                key: const ValueKey('next_button'),
                text: 'Next',
                onTap: () async {
                  if (brokerage == null) {
                    AppToast.showToast('Please select your trading broker app');
                    return;
                  }
                  final pkg = _getBrokerPackageName(brokerage!);
                  await _prefs.saveSelectedPackage(
                    userId: widget.userId,
                    packageName: pkg,
                  );
                  await GetStorage().write('mct_brokerage_${widget.userId}', brokerage);
                  if (Platform.isAndroid) {
                    await _blockService.saveUserIdForOverlay(widget.userId);
                    await _blockService.blockApp(pkg);
                    await applyAndroidTradingAppBlock(explicitUserId: widget.userId);
                  } else if (Platform.isIOS) {
                    try {
                      await NotificationHandler.requestPermissions();
                      final limiter = AppLimiter();
                      final granted = await limiter.requestIosPermission();
                      if (granted) {
                        await limiter.blockAndUnblockIOSApp();
                      }
                    } catch (e) {
                      debugPrint('[iOS Block/Perm] Error: $e');
                    }
                  }
                  nextPage();
                },
              )
            : KeyedSubtree(
                key: const ValueKey('not_listed_button'),
                child: _myBrokerNotListedButton(),
              ),
      ),
      content: [
        _buildBrokersGrid(),
      ],
    );
  }

  Widget _buildBrokersGrid() {
    return Obx(() {
      final appList = _tradingAppsService.apps.isNotEmpty
          ? _tradingAppsService.apps
          : TradingAppsService.defaultSupportedApps;

      const int crossAxisCount = 4;
      final rowCount = (appList.length / crossAxisCount).ceil();

      return Column(
        children: List.generate(rowCount, (rowIndex) {
          final startIndex = rowIndex * crossAxisCount;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: List.generate(crossAxisCount, (colIndex) {
                final itemIndex = startIndex + colIndex;
                if (itemIndex < appList.length) {
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: colIndex == 0 ? 0 : 4,
                        right: colIndex == crossAxisCount - 1 ? 0 : 4,
                      ),
                      child: AspectRatio(
                        aspectRatio: 0.85,
                        child: _brokerGridCard(appList[itemIndex]),
                      ),
                    ),
                  );
                }
                return const Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: SizedBox(),
                  ),
                );
              }),
            ),
          );
        }),
      );
    });
  }

  Widget _brokerGridCard(TradingApp app) {
    final nameLower = app.name.toLowerCase();
    final selectedLower = brokerage?.toLowerCase();
    final isSelected = selectedLower != null &&
        (selectedLower == nameLower ||
            selectedLower == app.packageName.toLowerCase() ||
            (selectedLower.contains('zerodha') && nameLower.contains('zerodha')) ||
            (selectedLower.contains('upstox') && nameLower.contains('upstox')) ||
            (selectedLower.contains('groww') && nameLower.contains('groww')) ||
            (selectedLower.contains('angel') && nameLower.contains('angel')) ||
            (selectedLower.contains('icici') && nameLower.contains('icici')) ||
            (selectedLower.contains('kotak') && nameLower.contains('kotak')) ||
            (selectedLower.contains('hdfc') && nameLower.contains('hdfc')) ||
            (selectedLower.contains('sbi') && nameLower.contains('sbi')) ||
            (selectedLower.contains('dhan') && nameLower.contains('dhan')) ||
            (selectedLower.contains('motilal') && nameLower.contains('motilal')) ||
            (selectedLower.contains('paytm') && nameLower.contains('paytm')) ||
            (selectedLower.contains('indmoney') && nameLower.contains('indmoney')) ||
            (selectedLower.contains('sharekhan') && nameLower.contains('sharekhan')) ||
            (selectedLower.contains('axis') && nameLower.contains('axis')) ||
            (selectedLower.contains('iifl') && nameLower.contains('iifl')) ||
            (selectedLower.contains('5paisa') && nameLower.contains('5paisa')) ||
            (selectedLower.contains('choice') && nameLower.contains('choice')) ||
            (selectedLower.contains('geojit') && nameLower.contains('geojit')) ||
            (selectedLower.contains('mirae') && nameLower.contains('mirae')) ||
            (selectedLower.contains('sahi') && nameLower.contains('sahi')));

    return GestureDetector(
      onTap: () async {
        if (brokerage == app.name) {
          setState(() => brokerage = null);
          return;
        }
        setState(() => brokerage = app.name);
        final pkg = app.packageName.isNotEmpty
            ? app.packageName
            : _getBrokerPackageName(app.name);
        await _prefs.saveSelectedPackage(
          userId: widget.userId,
          packageName: pkg,
        );
        await GetStorage().write('mct_brokerage_${widget.userId}', app.name);
        if (Platform.isAndroid) {
          await _blockService.saveUserIdForOverlay(widget.userId);
          await _blockService.blockApp(pkg);
          await applyAndroidTradingAppBlock(explicitUserId: widget.userId);
        } else if (Platform.isIOS) {
          try {
            final limiter = AppLimiter();
            final granted = await limiter.requestIosPermission();
            if (granted) {
              await limiter.blockAndUnblockIOSApp();
            }
          } catch (e) {
            debugPrint('[iOS Block/Perm] Error: $e');
          }
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF7F4FF) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? purple : const Color(0xFFEBEBF0),
            width: isSelected ? 1.8 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? purple.withValues(alpha: 0.12)
                  : const Color(0x08000000),
              blurRadius: 4,
              offset: const Offset(0, 1.5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Center(
                child: _buildBrokerLogoWidget(app),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              app.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? purple : const Color(0xFF1E2033),
                height: 1.12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrokerLogoWidget(TradingApp app) {
    if (app.logoUrl != null &&
        app.logoUrl!.isNotEmpty &&
        (app.logoUrl!.startsWith('http://') ||
            app.logoUrl!.startsWith('https://'))) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          app.logoUrl!,
          width: 36,
          height: 36,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _buildFallbackBrokerIcon(app),
        ),
      );
    }
    return _buildFallbackBrokerIcon(app);
  }

  Widget _buildFallbackBrokerIcon(TradingApp app) {
    final key = app.packageName.toLowerCase();
    final name = app.name.toLowerCase();

    if (key.contains('groww') || name.contains('groww')) {
      return Image.asset(
        'assets/groww.png',
        width: 36,
        height: 36,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _buildGrowwIcon(),
      );
    }
    if (key.contains('zerodha') || name.contains('zerodha') || name.contains('kite')) {
      return Image.asset(
        'assets/ZerodhaKite.png',
        width: 36,
        height: 36,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _buildZerodhaIcon(),
      );
    }
    if (key.contains('upstox') || name.contains('upstox')) {
      return Image.asset(
        'assets/upsocks.png',
        width: 36,
        height: 36,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _buildUpstoxIcon(),
      );
    }
    if (name.contains('angel') || key.contains('angel')) {
      return _buildAngelOneIcon();
    }
    if (name.contains('icici') || key.contains('icici')) {
      return _buildIciciDirectIcon();
    }
    if (name.contains('kotak') || key.contains('kotak')) {
      return _buildKotakNeoIcon();
    }
    if (name.contains('hdfc') || key.contains('hdfc')) {
      return _buildHdfcSecuritiesIcon();
    }
    if (name.contains('sbi') || key.contains('sbi')) {
      return _buildSbiSecuritiesIcon();
    }
    if (name.contains('dhan') || key.contains('dhan')) {
      return _buildDhanIcon();
    }
    if (name.contains('motilal') || key.contains('motilal') || name.contains('oswal')) {
      return _buildMotilalOswalIcon();
    }
    if (name.contains('paytm') || key.contains('paytm')) {
      return _buildPaytmMoneyIcon();
    }
    if (name.contains('indmoney') || key.contains('indmoney') || name.contains('ind money')) {
      return _buildIndMoneyIcon();
    }
    if (name.contains('sharekhan') || key.contains('sharekhan')) {
      return _buildSharekhanIcon();
    }
    if (name.contains('axis') || key.contains('axis')) {
      return _buildAxisSecuritiesIcon();
    }
    if (name.contains('iifl') || key.contains('iifl')) {
      return _buildIiflSecuritiesIcon();
    }
    if (name.contains('5paisa') || key.contains('fivepaisa') || key.contains('5paisa')) {
      return _build5PaisaIcon();
    }
    if (name.contains('choice') || key.contains('choice')) {
      return _buildChoiceIcon();
    }
    if (name.contains('geojit') || key.contains('geojit')) {
      return _buildGeojitIcon();
    }
    if (name.contains('mirae') || key.contains('mirae') || name.contains('mstock')) {
      return _buildMiraeAssetIcon();
    }
    if (name.contains('sahi') || key.contains('sahi')) {
      return _buildSahiIcon();
    }

    final initial = app.name.isNotEmpty ? app.name[0].toUpperCase() : 'B';
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: purple.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          color: purple,
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildGrowwIcon() {
    return Container(
      width: 36,
      height: 36,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFF00D09C), Color(0xFF007DFE)],
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
        ),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.show_chart_rounded, color: Colors.white, size: 22),
    );
  }

  Widget _buildZerodhaIcon() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFF387ED1),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.change_history_rounded, color: Colors.white, size: 22),
    );
  }

  Widget _buildUpstoxIcon() {
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      child: const Text(
        'up',
        style: TextStyle(
          color: Color(0xFF5B298C),
          fontSize: 23,
          fontWeight: FontWeight.w900,
          letterSpacing: -1,
        ),
      ),
    );
  }

  Widget _buildAngelOneIcon() {
    return const SizedBox(
      width: 36,
      height: 36,
      child: CustomPaint(painter: _AngelOnePainter()),
    );
  }

  Widget _buildIciciDirectIcon() {
    return Container(
      width: 36,
      height: 36,
      decoration: const BoxDecoration(
        color: Color(0xFFB5281A),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: const Text(
        'i',
        style: TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          fontStyle: FontStyle.italic,
          fontFamily: 'serif',
        ),
      ),
    );
  }

  Widget _buildKotakNeoIcon() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFFE31837),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '∞',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              height: 0.9,
            ),
          ),
          Text(
            'neo',
            style: TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              height: 0.9,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHdfcSecuritiesIcon() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF004C8F), width: 2.2),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(top: 0, left: 0, child: Container(width: 6, height: 6, color: const Color(0xFFED1C24))),
          Positioned(top: 0, right: 0, child: Container(width: 6, height: 6, color: const Color(0xFFED1C24))),
          Positioned(bottom: 0, left: 0, child: Container(width: 6, height: 6, color: const Color(0xFFED1C24))),
          Positioned(bottom: 0, right: 0, child: Container(width: 6, height: 6, color: const Color(0xFFED1C24))),
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF004C8F), width: 2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSbiSecuritiesIcon() {
    return Container(
      width: 36,
      height: 36,
      decoration: const BoxDecoration(
        color: Color(0xFF0083CA),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Container(
        width: 16,
        height: 16,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            width: 4,
            height: 8,
            color: const Color(0xFF0083CA),
          ),
        ),
      ),
    );
  }

  Widget _buildDhanIcon() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFF009444),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: const Text(
        'ध',
        style: TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildMotilalOswalIcon() {
    return Container(
      width: 36,
      height: 36,
      decoration: const BoxDecoration(
        color: Color(0xFFFFB800),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: const Text(
        'M',
        style: TextStyle(
          color: Colors.black,
          fontSize: 22,
          fontWeight: FontWeight.w900,
          fontFamily: 'serif',
        ),
      ),
    );
  }

  Widget _buildPaytmMoneyIcon() {
    return const SizedBox(
      width: 36,
      height: 36,
      child: CustomPaint(painter: _PaytmMoneyPainter()),
    );
  }

  Widget _buildIndMoneyIcon() {
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'IND',
            style: TextStyle(
              color: Colors.black,
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          Icon(
            Icons.arrow_upward_rounded,
            size: 14,
            color: Colors.black,
          ),
        ],
      ),
    );
  }

  Widget _buildSharekhanIcon() {
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      child: const Icon(
        Icons.pets_rounded,
        color: Color(0xFFF36C21),
        size: 28,
      ),
    );
  }

  Widget _buildAxisSecuritiesIcon() {
    return const SizedBox(
      width: 36,
      height: 36,
      child: Center(
        child: CustomPaint(
          size: Size(26, 26),
          painter: _AxisLogoPainter(),
        ),
      ),
    );
  }

  Widget _buildIiflSecuritiesIcon() {
    return Container(
      width: 36,
      height: 36,
      decoration: const BoxDecoration(
        color: Color(0xFFED5F1E),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.brightness_7_rounded,
        color: Colors.white,
        size: 22,
      ),
    );
  }

  Widget _build5PaisaIcon() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFF9E0B2B),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(3),
      alignment: Alignment.center,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: const Color(0xFFE2E4E8),
          borderRadius: BorderRadius.circular(5),
        ),
        alignment: Alignment.center,
        child: const Text(
          '5',
          style: TextStyle(
            color: Colors.black,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget _buildChoiceIcon() {
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      child: const Text(
        'C',
        style: TextStyle(
          color: Color(0xFF0066FF),
          fontSize: 28,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildGeojitIcon() {
    return Container(
      width: 36,
      height: 36,
      decoration: const BoxDecoration(
        color: Color(0xFF007A5E),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: const Text(
        'G',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildMiraeAssetIcon() {
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'MIRAE',
            style: TextStyle(
              color: Color(0xFF002244),
              fontSize: 7.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
          Text(
            'ASSET',
            style: TextStyle(
              color: Color(0xFF002244),
              fontSize: 7.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSahiIcon() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: const Text(
        'S',
        style: TextStyle(
          color: Color(0xFF22C55E),
          fontSize: 22,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _myBrokerNotListedButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF6F3FE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE9E4F9), width: 1.2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: _showBrokerNotListedDialog,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                      color: const Color(0xFF1E1B39),
                      width: 1.5,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.more_horiz_rounded,
                      color: Color(0xFF1E1B39),
                      size: 19,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'My broker is not listed',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E1B39),
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF1E1B39),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showBrokerNotListedDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF0EBFF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.account_balance_rounded,
                    color: purple,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Currently we support\nonly selected brokers',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18.5,
                    fontWeight: FontWeight.w800,
                    color: ink,
                    height: 1.25,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'You can create your trading account on one of these apps and then come back on Zeno AI to start Mind Control Trading.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF565466),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => Navigator.of(dialogContext).pop(),
                        child: const Center(
                          child: Text(
                            'Got It',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }



  // ============================================================
  // PERMISSION STEP 1 — Display over other apps
  // ============================================================

  Widget _permissionStep1Screen() {
    return _permissionPageLayout(
      key: const ValueKey('perm1'),
      step: 6,
      title: 'Enable Permission 1',
      subtitle: '[ Display over the Top ]',
      description:
          'This permission helps Zeno AI stay visible during live market hours and guide you to stay disciplined.',
      illustration: _permissionIllustration(asset: 'assets/trade-phonne.png'),
      bottom: _psychologicalTraps(),
      granted: _hasOverlay,
      onEnable: _requestOverlayPermission,
    );
  }

  Widget _permissionPageLayout({
    required Key key,
    required int step,
    required String title,
    required String subtitle,
    required String description,
    required Widget illustration,
    required Widget bottom,
    required bool granted,
    required VoidCallback onEnable,
  }) {
    return _page(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(step),
          const SizedBox(height: 18),
          Center(
            child: Column(
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: _Type.screenTitle,
                    fontWeight: FontWeight.w800,
                    color: ink,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: _Type.cardTitle,
                    fontWeight: FontWeight.w700,
                    color: purple,
                  ),
                ),
                const SizedBox(height: 14),
                illustration,
                const SizedBox(height: 14),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: _Type.caption,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                    color: grey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          bottom,
          const Spacer(),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: Opacity(
              opacity: _permissionBusy ? 0.6 : 1,
              child: Container(
                decoration: BoxDecoration(
                  gradient: primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: _permissionBusy
                        ? null
                        : (granted ? nextPage : onEnable),
                    child: Center(
                      child: _permissionBusy
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              granted
                                  ? 'Permission Granted'
                                  : 'Enable Permission',
                              style: const TextStyle(
                                fontSize: _Type.buttonLabel,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: nextPage,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                child: Text(
                  "I'll do this later",
                  style: TextStyle(
                    fontSize: _Type.label,
                    fontWeight: FontWeight.w600,
                    color: purple,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _permissionIllustration({required String asset}) {
    return SizedBox(
      height: 142,
      width: double.infinity,
      child: Image.asset(asset, fit: BoxFit.contain),
    );
  }

  Widget _psychologicalTraps() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: Text(
            'It protects you from psychological traps:',
            style: TextStyle(
              fontSize: _Type.label,
              fontWeight: FontWeight.w700,
              color: ink,
            ),
          ),
        ),
        _trapRow(
          icon: Icons.access_time_filled_rounded,
          iconBg: purple,
          title: 'FOMO (Before the Trade)',
        ),
        const SizedBox(height: 8),
        _trapRow(
          icon: Icons.favorite_rounded,
          iconBg: const Color(0xFFFF9F4A),
          title: 'Fear & Greed (During the Trade)',
        ),
        const SizedBox(height: 8),
        _trapRow(
          icon: Icons.replay_rounded,
          iconBg: const Color(0xFFFF4A7D),
          title: 'Revenge Trading (After the Outcome)',
        ),
      ],
    );
  }

  Widget _trapRow({
    required IconData icon,
    required Color iconBg,
    required String title,
  }) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(icon, color: Colors.white, size: 15),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: _Type.label,
              fontWeight: FontWeight.w600,
              color: ink,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // PERMISSION STEP 2 — Package usage stats
  // ============================================================

  Widget _permissionStep2Screen() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: _header(7),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 14),
                const Center(
                  child: Text(
                    'Enable Usage Access',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      color: ink,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                // Top Phone & Floating Notification Graphic
                _buildUsageGraphic(),
                const SizedBox(height: 14),
                // "Why we need this" card
                _buildWhyWeNeedThisCard(),
                const SizedBox(height: 16),
                // "── What we track ──"
                _buildWhatWeTrackSection(),
                const SizedBox(height: 16),
                // "✦ This helps Zeno AI provide"
                _buildThisHelpsZenoProvideSection(),
                const SizedBox(height: 14),
                // "Your privacy is important" card
                _buildPrivacyCard(),
                const SizedBox(height: 18),
                const Text(
                  "You're in control. You can change this anytime in Settings.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: grey),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: border)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Primary button: Enable Permission
              SizedBox(
                width: double.infinity,
                height: 48,
                child: Opacity(
                  opacity: _permissionBusy ? 0.6 : 1,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: primaryGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: _permissionBusy
                            ? null
                            : (_hasUsage ? nextPage : _requestUsagePermission),
                        child: Center(
                          child: _permissionBusy
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  _hasUsage
                                      ? 'Permission Granted'
                                      : 'Enable Permission',
                                  style: const TextStyle(
                                    fontSize: _Type.buttonLabel,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Secondary button: I'll do this later
              Center(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: nextPage,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                    child: Text(
                      'Not Now',
                      style: TextStyle(
                        fontSize: _Type.label,
                        fontWeight: FontWeight.w600,
                        color: purple,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUsageGraphic() {
    return Center(
      child: Container(
        width: double.infinity,
        height: 130,
        decoration: BoxDecoration(
          color: const Color(0xFFF3EEFF),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Phone top silhouette
            Positioned(
              top: 8,
              child: Container(
                width: 140,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFF321E6A),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  border: Border.all(color: const Color(0xFF4C309B), width: 2),
                ),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    margin: const EdgeInsets.only(top: 4),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1045),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
            // Floating notification glass card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5DBFF), width: 1.5),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x187C3AED),
                    blurRadius: 16,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: primaryGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.bolt_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Zeno AI',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: ink,
                          ),
                        ),
                        Text(
                          'Stay Focused.\nFollow Your Process.',
                          style: TextStyle(
                            fontSize: 11.5,
                            height: 1.2,
                            fontWeight: FontWeight.w600,
                            color: grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWhyWeNeedThisCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEDE5FF)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Color(0xFFEDE5FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.security_rounded, color: purple, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Why we need this',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: ink,
                  ),
                ),
                const SizedBox(height: 3),
                RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: Color(0xFF3A3A4A),
                    ),
                    children: [
                      TextSpan(
                        text:
                            'Zeno AI uses app-usage information from your selected trading apps to ',
                      ),
                      TextSpan(
                        text: 'understand your behavior during active trading.',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: ink,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhatWeTrackSection() {
    return Column(
      children: [
        const Row(
          children: [
            Expanded(child: Divider(color: Color(0xFFE7E3F0), thickness: 1)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                'What we track',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: purple,
                ),
              ),
            ),
            Expanded(child: Divider(color: Color(0xFFE7E3F0), thickness: 1)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildTrackMiniCard(
                icon: Icons.stay_current_portrait_rounded,
                title: 'Active App',
                desc: 'Which trading app is active',
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _buildTrackMiniCard(
                icon: Icons.exit_to_app_rounded,
                title: 'App Activity',
                desc: 'When the app is opened or closed',
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _buildTrackMiniCard(
                icon: Icons.timer_outlined,
                title: 'Time Spent',
                desc: 'How long you stay active in the app',
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _buildTrackMiniCard(
                icon: Icons.auto_graph_rounded,
                title: 'Insights',
                desc: 'Patterns that help improve discipline',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTrackMiniCard({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF9FD),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFEBE7F3)),
      ),
      child: Column(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: Color(0xFFF3EEFF),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: purple, size: 17),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: ink,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            desc,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 9.5,
              height: 1.25,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6B6B7B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThisHelpsZenoProvideSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.auto_awesome_rounded, color: purple, size: 16),
            SizedBox(width: 6),
            Expanded(
              child: Text(
                'This helps Zeno AI provide',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: ink,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildHelpRowCard(
          icon: Icons.assignment_turned_in_outlined,
          title: 'Process Discipline',
          subtitle: 'See how well you follow your trading process.',
        ),
        const SizedBox(height: 6),
        _buildHelpRowCard(
          icon: Icons.psychology_outlined,
          title: 'Behavioral Insights',
          subtitle: 'Understand patterns in your trading behavior.',
        ),
        const SizedBox(height: 6),
        _buildHelpRowCard(
          icon: Icons.track_changes_rounded,
          title: 'Focused Sessions',
          subtitle: 'Track your focus and session quality.',
        ),
        const SizedBox(height: 6),
        _buildHelpRowCard(
          icon: Icons.trending_up_rounded,
          title: 'Better Decisions',
          subtitle: 'Get insights to build stronger trading habits.',
        ),
      ],
    );
  }

  Widget _buildHelpRowCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEDE9FE)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x067C3AED),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: const Color(0xFFF3EEFF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: purple, size: 17),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: ink,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6B6B7B),
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            size: 18,
            color: Color(0xFFA59DB8),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF7FE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEBE3FB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Color(0xFFEDE5FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shield_rounded, color: purple, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your privacy is important',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: ink,
                  ),
                ),
                const SizedBox(height: 3),
                RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontSize: 11.5,
                      height: 1.35,
                      color: Color(0xFF3A3A4A),
                    ),
                    children: [
                      TextSpan(text: 'We use this information '),
                      TextSpan(
                        text: 'only',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: ink,
                        ),
                      ),
                      TextSpan(
                        text:
                            ' for trading-session and discipline features. We do not access the content of your apps, messages, passwords, or financial account details.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SUCCESS
  // ============================================================

  Widget _successScreen() {
    return _page(
      child: Column(
        children: [
          const SizedBox(height: 8),
          SizedBox(
            height: 105,
            width: double.infinity,
            child: Stack(
              alignment: Alignment.center,
              children: [
                ..._confetti(),
                Container(
                  width: 68,
                  height: 68,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [purple, violet]),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 43,
                  ),
                ),
              ],
            ),
          ),
          const Text(
            "You're All Set!",
            style: TextStyle(
              fontSize: _Type.heading,
              fontWeight: FontWeight.w800,
              color: ink,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Your Mind Control Trading Process\n'
            'is ready to go.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: _Type.label, height: 1.4, color: grey),
          ),
          const SizedBox(height: 15),
          _successItem('Discipline is your edge', Icons.shield_rounded),
          _successItem('Process is your protection', Icons.shield_rounded),
          _successItem('Consistency is your strength', Icons.shield_rounded),
          _successItem('Patience is your power', Icons.radio_button_checked),
          const SizedBox(height: 12),
          Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => termsAccepted = !termsAccepted),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 19,
                      height: 19,
                      decoration: BoxDecoration(
                        color: termsAccepted ? purple : Colors.white,
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: termsAccepted
                              ? purple
                              : const Color(0xFFAAA7B5),
                        ),
                      ),
                      child: termsAccepted
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 13,
                            )
                          : null,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'I agree to ',
                      style: TextStyle(fontSize: _Type.label, color: ink),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: AppUrlLauncher.openRiskDisclosure,
                child: const Text(
                  'Risk Disclosure',
                  style: TextStyle(
                    fontSize: _Type.label,
                    fontWeight: FontWeight.w700,
                    color: purple,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _gradientButton(
            text: _isSubmitting ? 'SETTING UP...' : 'SET UP MY PROCESS 🚀',
            onTap: () {
              if (_isSubmitting) return;
              if (tradingSegment == null) {
                AppToast.showToast('Please select a trading segment');
                return;
              }
              if (instrument == null) {
                AppToast.showToast('Please select an instrument');
                return;
              }
              if (tradingCapital < minCapital) {
                AppToast.showToast(
                  'Minimum capital is ₹${_formatIndianNumber(minCapital)}',
                );
                return;
              }
              if (_effectiveTradesPerDay == null) {
                AppToast.showToast('Please select trades per day');
                return;
              }
              if (brokerage == null) {
                AppToast.showToast('Please select your broking app');
                return;
              }
              if (!termsAccepted) {
                AppToast.showToast('Please agree to the Risk Disclosure');
                return;
              }
              _completeSetup();
            },
          ),
        ],
      ),
    );
  }

  List<Widget> _confetti() {
    const positions = [
      Offset(-75, -28),
      Offset(-57, 18),
      Offset(-42, -43),
      Offset(-22, 39),
      Offset(20, -45),
      Offset(38, 38),
      Offset(58, -29),
      Offset(76, 19),
      Offset(-84, 0),
      Offset(84, 0),
      Offset(48, 7),
      Offset(-49, -7),
    ];

    const colors = [purple, violet, Color(0xFF8AE1C5), Color(0xFFD7B1FF)];

    return List.generate(positions.length, (index) {
      return Align(
        alignment: Alignment.center,
        child: Transform.translate(
          offset: Offset(positions[index].dx, positions[index].dy),
          child: Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: colors[index % colors.length],
              shape: BoxShape.circle,
            ),
          ),
        ),
      );
    });
  }

  Widget _successItem(String text, IconData icon) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 5),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F7FE),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: purple, size: 15),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              fontSize: _Type.label,
              fontWeight: FontWeight.w600,
              color: ink,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SAVE SETUP
  // ============================================================

  String _getBrokingAppKey(String? name) {
    if (name == null) return 'zerodha_kite';
    final lower = name.toLowerCase().trim();
    if (lower.contains('zerodha') || lower.contains('kite')) return 'zerodha_kite';
    if (lower.contains('upstox')) return 'upstox';
    if (lower.contains('groww')) return 'groww';
    if (lower.contains('angel')) return 'angel_one';
    if (lower.contains('icici')) return 'icici_direct';
    if (lower.contains('kotak')) return 'kotak_neo';
    if (lower.contains('hdfc')) return 'hdfc_securities';
    if (lower.contains('sbi')) return 'sbi_securities';
    if (lower.contains('dhan')) return 'dhan';
    if (lower.contains('motilal') || lower.contains('oswal')) return 'motilal_oswal';
    if (lower.contains('paytm')) return 'paytm_money';
    if (lower.contains('indmoney') || lower.contains('ind money')) return 'indmoney';
    if (lower.contains('sharekhan')) return 'sharekhan';
    if (lower.contains('axis')) return 'axis_securities';
    if (lower.contains('iifl')) return 'iifl_securities';
    if (lower.contains('5paisa') || lower.contains('fivepaisa')) return '5paisa';
    if (lower.contains('choice')) return 'choice';
    if (lower.contains('geojit')) return 'geojit';
    if (lower.contains('mirae')) return 'mirae_asset';
    if (lower.contains('sahi')) return 'sahi';
    return lower.replaceAll(RegExp(r'\s+'), '_');
  }

  String _getBrokerPackageName(String? name) {
    if (name == null) return 'com.zerodha.kite3';
    final lower = name.toLowerCase().trim();
    for (final a in _tradingAppsService.apps) {
      if (a.name.toLowerCase() == lower ||
          a.packageName.toLowerCase() == lower) {
        return a.packageName;
      }
    }
    for (final a in TradingAppsService.defaultSupportedApps) {
      if (a.name.toLowerCase() == lower ||
          a.packageName.toLowerCase() == lower) {
        return a.packageName;
      }
    }
    if (lower.contains('zerodha') || lower.contains('kite')) return 'com.zerodha.kite3';
    if (lower.contains('upstox')) return 'in.upstox.app';
    if (lower.contains('groww')) return 'com.nextbillion.groww';
    if (lower.contains('angel')) return 'com.msf.angelmobile';
    if (lower.contains('icici')) return 'com.icicidirect.mobile';
    if (lower.contains('kotak')) return 'com.kotak.neo';
    if (lower.contains('hdfc')) return 'com.hdfcsec.trade';
    if (lower.contains('sbi')) return 'com.sbi.smartmobile';
    if (lower.contains('dhan')) return 'co.dhan';
    if (lower.contains('motilal') || lower.contains('oswal')) return 'com.moti.moconnect';
    if (lower.contains('paytm')) return 'com.paytmmoney';
    if (lower.contains('indmoney') || lower.contains('ind money')) return 'com.indmoney';
    if (lower.contains('sharekhan')) return 'com.sharekhan.corporate';
    if (lower.contains('axis')) return 'com.axis.direct';
    if (lower.contains('iifl')) return 'com.iifl.touch';
    if (lower.contains('5paisa') || lower.contains('fivepaisa')) return 'com.fivepaisa.trade';
    if (lower.contains('choice')) return 'com.choiceequitybroking.finox';
    if (lower.contains('geojit')) return 'com.geojit.selfie';
    if (lower.contains('mirae')) return 'mstock.miraeasset';
    if (lower.contains('sahi')) return 'com.sahi.app';
    return 'com.zerodha.kite3';
  }

  Future<void> _completeSetup() async {
    if (_isSubmitting) return;
    if (!isCapitalValid ||
        tradingSegment == null ||
        instrument == null ||
        brokerage == null ||
        _effectiveTradesPerDay == null ||
        marketEntryTimeOfDay == null) {
      return;
    }

    setState(() => _isSubmitting = true);

    final formattedEntryTime = marketEntryTimeOfDay!.format(context);
    final storage = GetStorage();
    final brokerPkg = _getBrokerPackageName(brokerage);

    await _prefs.saveSelectedPackage(
      userId: widget.userId,
      packageName: brokerPkg,
    );

    if (Platform.isAndroid && (_hasOverlay || _hasUsage)) {
      await _blockService.saveUserIdForOverlay(widget.userId);
      await _blockService.blockApp(brokerPkg);
      await applyAndroidTradingAppBlock(explicitUserId: widget.userId);
    } else if (Platform.isIOS) {
      try {
        final limiter = AppLimiter();
        final granted = await limiter.requestIosPermission();
        if (granted) {
          await limiter.blockAndUnblockIOSApp();
        }
      } catch (e) {
        debugPrint('[iOS Block in _completeSetup] Error: $e');
      }
    }

    await storage.write('mct_setup_completed_${widget.userId}', true);
    await storage.write('mct_trading_segment_${widget.userId}', tradingSegment);
    await storage.write('mct_instrument_${widget.userId}', instrument);
    await storage.write('mct_brokerage_${widget.userId}', brokerage);
    await storage.write(
      'mct_trades_per_day_${widget.userId}',
      _effectiveTradesPerDay,
    );
    await storage.write(
      'mct_trading_setup_${widget.userId}',
      _followsZenoSignals ? 'zeno_signals' : 'custom',
    );
    await storage.write('mct_trading_capital_${widget.userId}', tradingCapital);
    await storage.write(
      'mct_max_risk_per_trade_${widget.userId}',
      maxRiskPerTrade,
    );
    await storage.write(
      'mct_market_entry_time_${widget.userId}',
      formattedEntryTime,
    );

    final apiService = Get.isRegistered<ApiService>()
        ? Get.find<ApiService>()
        : Get.put(ApiService());

    final fields = <String, String>{
      'user_id': widget.userId,
      'trading_segment': (tradingSegment ?? 'options').toLowerCase(),
      'trading_setup_type': _followsZenoSignals ? 'zeno_ai_signals' : 'own_setup',
      'instrument': instrument ?? 'NIFTY 50',
      'trading_capital': tradingCapital.toString(),
      'trades_per_day': (_effectiveTradesPerDay ?? 1).toString(),
      'max_risk_percent': '2',
      'market_entry_time': formattedEntryTime,
      'broking_app': _getBrokingAppKey(brokerage),
      'permission_overlay_enabled': _hasOverlay ? '1' : '0',
      'permission_usage_stats_enabled': _hasUsage ? '1' : '0',
      'terms_accepted': termsAccepted ? '1' : '0',
    };

    try {
      final response = await apiService.postFormData(
        ApiUrl.processSetup,
        fields,
      );

      if (response.isSuccess) {
        AppToast.showToast('Process setup completed successfully!');
      } else {
        AppToast.showToast(response.errorMessage ?? 'Process saved');
      }
    } catch (e) {
      AppToast.showToast('Process setup saved');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
        Navigator.pop(context, true);
      }
    }
  }

  // ============================================================
  // NORMAL STEP
  // ============================================================

  Widget _normalStep({
    required int step,
    required String title,
    required String subtitle,
    required List<Widget> content,
    VoidCallback? onNext,
    Widget? customBottom,
  }) {
    return _page(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(step),
          const SizedBox(height: 21),
          Text(
            title,
            style: const TextStyle(
              fontSize: _Type.screenTitle,
              fontWeight: FontWeight.w800,
              color: ink,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: _Type.screenSubtitle,
              height: 1.35,
              color: ink,
            ),
          ),
          const SizedBox(height: 20),
          ...content,
          const Spacer(),
          customBottom ?? _gradientButton(text: 'Next', onTap: onNext ?? nextPage),
          const SizedBox(height: 2),
        ],
      ),
    );
  }

  Widget _header(int step, {bool reference = false}) {
    return Column(
      children: [
        Row(
          children: [
            SizedBox(
              width: 30,
              height: 30,
              child: IconButton(
                padding: EdgeInsets.zero,
                onPressed: previousPage,
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 17,
                  color: ink,
                ),
              ),
            ),
            Expanded(
              child: Text(
                'Step $step of 7',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: reference ? 'Roboto' : null,
                  fontSize: reference ? 16 : _Type.sectionTitle,
                  fontWeight: reference ? FontWeight.w500 : FontWeight.w700,
                  color: ink,
                ),
              ),
            ),
            const SizedBox(width: 30),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: step / 7,
            minHeight: 5,
            backgroundColor: const Color(0xFFE4E2EB),
            valueColor: AlwaysStoppedAnimation<Color>(
              reference ? _referencePurple : purple,
            ),
          ),
        ),
      ],
    );
  }

  Widget _largeOptionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 76),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFBF8FF) : Colors.white,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: selected ? purple : border,
            width: selected ? 1.2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 43,
              height: 43,
              decoration: BoxDecoration(
                gradient: selected ? primaryGradient : null,
                color: selected ? null : const Color(0xFFF0ECFF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: selected ? Colors.white : purple,
                size: 23,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: _Type.cardTitle,
                      fontWeight: FontWeight.w800,
                      color: ink,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: _Type.caption,
                      color: grey,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selected ? purple : const Color(0xFF888692),
              size: 19,
            ),
          ],
        ),
      ),
    );
  }

  Widget _instrumentCard({
    required String title,
    required bool selected,
    required InstrumentType type,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 50,
        margin: const EdgeInsets.only(bottom: 9),
        padding: const EdgeInsets.symmetric(horizontal: 11),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFBF8FF) : Colors.white,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: selected ? purple : border,
            width: selected ? 1.1 : 1,
          ),
        ),
        child: Row(
          children: [
            _instrumentIcon(type),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: _Type.label,
                  fontWeight: FontWeight.w700,
                  color: ink,
                ),
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selected ? purple : const Color(0xFF85838F),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _instrumentIcon(InstrumentType type) {
    if (type == InstrumentType.nifty) {
      return Container(
        width: 25,
        height: 25,
        decoration: const BoxDecoration(
          color: Color(0xFFECE7FF),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: const Text(
          'N',
          style: TextStyle(
            fontSize: _Type.caption,
            fontWeight: FontWeight.w800,
            color: purple,
          ),
        ),
      );
    }

    return Container(
      width: 25,
      height: 25,
      decoration: BoxDecoration(
        color: const Color(0xFFF0ECFF),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Icon(
        type == InstrumentType.bank
            ? Icons.account_balance_outlined
            : Icons.bar_chart_rounded,
        color: purple,
        size: 16,
      ),
    );
  }

  Widget _masterInstrumentCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F5FF),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFEAE3FF),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(
              Icons.track_changes_rounded,
              color: purple,
              size: 21,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Master one instrument.',
                  style: TextStyle(
                    fontSize: _Type.caption,
                    fontWeight: FontWeight.w800,
                    color: ink,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Focus deeply. Execute better.',
                  style: TextStyle(fontSize: _Type.caption, color: ink),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _gradientButton({
    Key? key,
    required String text,
    required VoidCallback? onTap,
    Widget? trailing,
  }) {
    final enabled = onTap != null;

    return Container(
      key: key,
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        gradient: enabled
            ? primaryGradient
            : const LinearGradient(colors: [disabled, disabled]),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white.withValues(alpha: 0.85),
          shadowColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: const TextStyle(
                fontSize: _Type.buttonLabel,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing,
            ],
          ],
        ),
      ),
    );
  }

  static String _formatIndianNumber(int number) {
    final negative = number < 0;
    final digits = number.abs().toString();

    if (digits.length <= 3) {
      return negative ? '-$digits' : digits;
    }

    final lastThree = digits.substring(digits.length - 3);
    var other = digits.substring(0, digits.length - 3);
    final groups = <String>[];

    while (other.length > 2) {
      groups.insert(0, other.substring(other.length - 2));
      other = other.substring(0, other.length - 2);
    }
    if (other.isNotEmpty) {
      groups.insert(0, other);
    }
    groups.add(lastThree);

    final formatted = groups.join(',');
    return negative ? '-$formatted' : formatted;
  }

  static String _numberToWordsIndian(int numberIn) {
    var number = numberIn.abs();
    if (number == 0) return 'Zero';

    const ones = [
      '',
      'One',
      'Two',
      'Three',
      'Four',
      'Five',
      'Six',
      'Seven',
      'Eight',
      'Nine',
      'Ten',
      'Eleven',
      'Twelve',
      'Thirteen',
      'Fourteen',
      'Fifteen',
      'Sixteen',
      'Seventeen',
      'Eighteen',
      'Nineteen',
    ];
    const tens = [
      '',
      '',
      'Twenty',
      'Thirty',
      'Forty',
      'Fifty',
      'Sixty',
      'Seventy',
      'Eighty',
      'Ninety',
    ];

    String twoDigits(int n) {
      if (n < 20) return ones[n];
      final t = tens[n ~/ 10];
      final o = n % 10;
      return o != 0 ? '$t ${ones[o]}' : t;
    }

    String threeDigits(int n) {
      final h = n ~/ 100;
      final rest = n % 100;
      final parts = <String>[];
      if (h != 0) parts.add('${ones[h]} Hundred');
      if (rest != 0) parts.add(twoDigits(rest));
      return parts.join(' ');
    }

    final crore = number ~/ 10000000;
    number %= 10000000;
    final lakh = number ~/ 100000;
    number %= 100000;
    final thousand = number ~/ 1000;
    number %= 1000;
    final hundred = number;

    final parts = <String>[];
    if (crore != 0) parts.add('${twoDigits(crore)} Crore');
    if (lakh != 0) parts.add('${twoDigits(lakh)} Lakh');
    if (thousand != 0) parts.add('${twoDigits(thousand)} Thousand');
    if (hundred != 0) parts.add(threeDigits(hundred));

    return parts.join(' ');
  }
}

// ================================================================
// INDIAN CURRENCY INPUT FORMATTER
// ================================================================

class _IndianCurrencyInputFormatter extends TextInputFormatter {
  _IndianCurrencyInputFormatter({required this.max});

  final int max;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    digits = digits.replaceFirst(RegExp(r'^0+(?=\d)'), '');

    var value = digits.isEmpty ? 0 : int.tryParse(digits) ?? 0;
    if (value > max) value = max;

    final formatted = value == 0
        ? ''
        : _TradingProcessScreenState._formatIndianNumber(value);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

// ================================================================
// ENUM
// ================================================================

enum InstrumentType { nifty, bank, sensex }

class _DottedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double radius;
  final double dashLength;
  final double gapLength;

  const _DottedBorderPainter({
    required this.color,
    this.strokeWidth = 1.2,
    this.radius = 10.0,
    this.dashLength = 4.0,
    this.gapLength = 3.5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        strokeWidth / 2,
        strokeWidth / 2,
        size.width - strokeWidth,
        size.height - strokeWidth,
      ),
      Radius.circular(radius),
    );

    final path = Path()..addRRect(rrect);
    final dashPath = Path();

    for (final metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final length = math.min(dashLength, metric.length - distance);
        dashPath.addPath(
          metric.extractPath(distance, distance + length),
          Offset.zero,
        );
        distance += dashLength + gapLength;
      }
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant _DottedBorderPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.radius != radius ||
      oldDelegate.dashLength != dashLength ||
      oldDelegate.gapLength != gapLength;
}

class _AngelOnePainter extends CustomPainter {
  const _AngelOnePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final orangePaint = Paint()
      ..color = const Color(0xFFF36C21)
      ..style = PaintingStyle.fill;
    final greenPaint = Paint()
      ..color = const Color(0xFF009444)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;

    final cx = size.width / 2;
    final triH = size.height / 5.2;
    final triW = size.width / 4.8;

    for (int row = 0; row < 4; row++) {
      final count = row + 1;
      final startX = cx - (count * triW / 2) + (triW / 2);
      final y = 4.0 + row * (triH * 0.95);
      for (int col = 0; col < count; col++) {
        final x = startX + col * triW;
        final path = Path()
          ..moveTo(x, y)
          ..lineTo(x - triW / 2.2, y + triH * 0.85)
          ..lineTo(x + triW / 2.2, y + triH * 0.85)
          ..close();
        canvas.drawPath(path, orangePaint);
      }
    }
    canvas.drawLine(
      Offset(cx + 3, 3),
      Offset(size.width - 2, size.height - 3),
      greenPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PaytmMoneyPainter extends CustomPainter {
  const _PaytmMoneyPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cyanPaint = Paint()
      ..color = const Color(0xFF00BAF2)
      ..style = PaintingStyle.fill;
    final darkPaint = Paint()
      ..color = const Color(0xFF002970)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width / 2, 4)
      ..lineTo(4, size.height - 4)
      ..lineTo(size.width - 4, size.height - 4)
      ..close();
    canvas.drawPath(path, cyanPaint);

    final bottomPath = Path()
      ..moveTo(size.width * 0.25, size.height * 0.65)
      ..lineTo(4, size.height - 4)
      ..lineTo(size.width - 4, size.height - 4)
      ..lineTo(size.width * 0.75, size.height * 0.65)
      ..close();
    canvas.drawPath(bottomPath, darkPaint);

    final textPainter = TextPainter(
      text: const TextSpan(
        text: '₹',
        style: TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset((size.width - textPainter.width) / 2, size.height * 0.42),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AxisLogoPainter extends CustomPainter {
  const _AxisLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF97144D)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width / 2, 2)
      ..lineTo(size.width - 2, size.height - 2)
      ..lineTo(size.width * 0.65, size.height - 2)
      ..lineTo(size.width / 2, size.height * 0.42)
      ..lineTo(size.width * 0.35, size.height - 2)
      ..lineTo(2, size.height - 2)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HeroCandlestickBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final wavePaint = Paint()
      ..color = const Color(0xFFEEEAFF).withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    final path1 = Path();
    path1.moveTo(0, size.height * 0.45);
    path1.cubicTo(
      size.width * 0.25,
      size.height * 0.2,
      size.width * 0.6,
      size.height * 0.6,
      size.width,
      size.height * 0.35,
    );
    canvas.drawPath(path1, wavePaint);

    final path2 = Path();
    path2.moveTo(0, size.height * 0.55);
    path2.cubicTo(
      size.width * 0.3,
      size.height * 0.7,
      size.width * 0.7,
      size.height * 0.3,
      size.width,
      size.height * 0.5,
    );
    canvas.drawPath(
      path2,
      wavePaint..color = const Color(0xFFF3EFFF).withValues(alpha: 0.9),
    );

    final candlePaint = Paint()
      ..color = const Color(0xFFDDD5FA).withValues(alpha: 0.65)
      ..style = PaintingStyle.fill;

    final wickPaint = Paint()
      ..color = const Color(0xFFDDD5FA).withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final candles = [
      (
        size.width * 0.66,
        size.height * 0.42,
        size.height * 0.68,
        size.height * 0.48,
        size.height * 0.62,
      ),
      (
        size.width * 0.73,
        size.height * 0.32,
        size.height * 0.60,
        size.height * 0.38,
        size.height * 0.52,
      ),
      (
        size.width * 0.80,
        size.height * 0.24,
        size.height * 0.52,
        size.height * 0.30,
        size.height * 0.44,
      ),
      (
        size.width * 0.87,
        size.height * 0.16,
        size.height * 0.45,
        size.height * 0.22,
        size.height * 0.36,
      ),
      (
        size.width * 0.94,
        size.height * 0.22,
        size.height * 0.50,
        size.height * 0.28,
        size.height * 0.42,
      ),
    ];

    for (final c in candles) {
      canvas.drawLine(Offset(c.$1, c.$2), Offset(c.$1, c.$3), wickPaint);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTRB(c.$1 - 4.5, c.$4, c.$1 + 4.5, c.$5),
        const Radius.circular(2),
      );
      canvas.drawRRect(rect, candlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

