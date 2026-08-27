import 'dart:io';
import 'dart:math' as math;

import 'package:discipline_mind/services/api/api_services.dart';
import 'package:discipline_mind/services/api/api_url.dart';
import 'package:discipline_mind/services/app_block_preferences_service.dart';
import 'package:discipline_mind/services/native_app_block_service.dart';
import 'package:discipline_mind/services/trading_block_bootstrap.dart';
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

  static const Color lightPurple = Color(0xFFF7F4FF);
  static const Color veryLightPurple = Color(0xFFFAF8FF);
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
  String? instrument;
  String? brokerage;

  int tradingCapital = 0;
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

  bool get _step3Valid =>
      isCapitalValid && tradesPerDay != null && marketEntryTimeOfDay != null;

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

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
    _refreshPermissions();

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

      if (!mounted) return;

      // Only advance / warn based on whichever permission step the user
      // is actually sitting on right now.
      if (currentPage == 5) {
        if (newOverlay) {
          nextPage();
        } else if (showToastIfMissing) {
          AppToast.showToast(
              'Please grant the "Display over other apps" permission.');
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
  // Pages: 0 = Welcome, 1 = Step1, 2 = Step2, 3 = Step3, 4 = Step4,
  // 5 = Permission1, 6 = Permission2, 7 = Success.
  // ============================================================

  void nextPage() {
    if (!mounted) return;
    if (currentPage >= 7) return;

    if (currentPage == 3 && !_step3Valid) {
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
              _step2Screen(),
              _step3Screen(),
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
          child: SizedBox(
            height: height,
            child: child,
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
        children: [
          const SizedBox(height: 20),
          _zenoLogoImage(),
          const SizedBox(height: 13),
          _logoHero(),
          const SizedBox(height: 5),
          const Text(
            'Trade with a Calm Mind.\nWin with Discipline.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: _Type.screenTitle,
              height: 1.18,
              fontWeight: FontWeight.w800,
              color: ink,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 11),
          const Text(
            'Set up your Mind Control Trading\n'
                'Process in 4 simple steps.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: _Type.caption,
              height: 1.35,
              color: ink,
            ),
          ),
          const SizedBox(height: 17),
          _gradientButton(
            text: 'Define My Process',
            onTap: nextPage,
          ),
          const SizedBox(height: 14),
          _mctCard(),
          const Spacer(),
          _welcomeBottom(),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _zenoLogoImage() {
    return Image.asset(
      'assets/new_logo_zeno_ai.jpg',
      height: 60,
      fit: BoxFit.contain,
    );
  }

  Widget _logoHero() {
    return SizedBox(
      height: 190,
      width: double.infinity,
      child: Image.asset(
        'assets/z_trade.png',
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _mctCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF9FE),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: const Color(0xFFE6E3EF)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFF0EBFF),
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
                  'Mind Control Trading (MCT)',
                  style: TextStyle(
                    fontSize: _Type.body,
                    fontWeight: FontWeight.w800,
                    color: ink,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Discipline  •  Patience  •  Consistency',
                  style: TextStyle(
                    fontSize: _Type.caption,
                    color: grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _welcomeBottom() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ...List.generate(
          4,
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
        const SizedBox(width: 58),
        GestureDetector(
          onTap: nextPage,
          child: const Text(
            'Skip',
            style: TextStyle(
              fontSize: _Type.caption,
              fontWeight: FontWeight.w600,
              color: ink,
            ),
          ),
        ),
      ],
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
      nextEnabled: tradingSegment != null,
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
      nextEnabled: instrument != null,
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

  Widget _step3Screen() {
    return _normalStep(
      step: 3,
      title: 'Trading Capital & Rules',
      subtitle: 'Set your capital and trading discipline',
      nextEnabled: _step3Valid,
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

  Widget _capitalField() {
    final hasError = capitalErrorText != null;

    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: hasError
              ? red
              : (_isCapitalEditable ? purple : const Color(0xFFD5D2E1)),
          width: hasError || _isCapitalEditable ? 1.2 : 1,
        ),
      ),
      child: Row(
        children: [
          const Text(
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
              style: const TextStyle(
                fontSize: _Type.value,
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
                _isCapitalEditable
                    ? Icons.check_circle_rounded
                    : Icons.edit_outlined,
                size: 16,
                color: _isCapitalEditable ? green : ink,
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

  Widget _wordsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: lightGreen,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: const Color(0xFFD7EEE4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'In words:',
            style: TextStyle(fontSize: _Type.micro, color: grey),
          ),
          const SizedBox(height: 2),
          Text(
            capitalInWords,
            style: const TextStyle(
              fontSize: _Type.body,
              fontWeight: FontWeight.w700,
              color: Color(0xFF285B4A),
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
            const Text(
              'Market Entry Time',
              style: TextStyle(
                fontSize: _Type.body,
                fontWeight: FontWeight.w600,
                color: ink,
              ),
            ),
            const Spacer(),
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
      initialTime:
          marketEntryTimeOfDay ?? const TimeOfDay(hour: 9, minute: 15),
    );

    if (picked == null) return;
    setState(() => marketEntryTimeOfDay = picked);
  }

  // ============================================================
  // STEP 4
  // ============================================================

  Widget _step4Screen() {
    return _normalStep(
      step: 4,
      title: 'Select Your Broking App',
      subtitle: 'Choose the app you will use\n'
          'exclusively for Mind Control Trading.',
      nextEnabled: brokerage != null,
      content: [
        _brokerCard(
          title: 'Zerodha Kite',
          logo: 'K',
          logoColor: const Color(0xFFF15B35),
        ),
        _brokerCard(
          title: 'Upstox',
          logo: 'U',
          logoColor: const Color(0xFF5B35A5),
        ),
        _brokerCard(
          title: 'Groww',
          logo: 'G',
          logoColor: const Color(0xFF28B9A7),
        ),
        const SizedBox(height: 3),
        _brokerInfoCard(),
      ],
    );
  }

  Widget _brokerCard({
    required String title,
    required String logo,
    required Color logoColor,
  }) {
    final selected = brokerage == title;

    return GestureDetector(
      onTap: () async {
        setState(() => brokerage = title);
        final pkg = _getBrokerPackageName(title);
        await _prefs.saveSelectedPackage(
          userId: widget.userId,
          packageName: pkg,
        );
        if (Platform.isAndroid) {
          await _blockService.saveUserIdForOverlay(widget.userId);
          await _blockService.blockApp(pkg);
        }
      },
      child: Container(
        width: double.infinity,
        height: 44,
        margin: const EdgeInsets.only(bottom: 7),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFBF8FF) : Colors.white,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: selected ? purple : border,
            width: selected ? 1.2 : 1,
          ),
        ),
        child: Row(
          children: [
            _brokerLogo(logo, logoColor),
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

  Widget _brokerLogo(String text, Color color) {
    return Container(
      width: 27,
      height: 27,
      decoration: BoxDecoration(
        color: color.withOpacity(.12),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: _Type.body,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _brokerInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F4FF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 29,
            height: 29,
            decoration: BoxDecoration(
              color: const Color(0xFFEAE3FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.shield_outlined, color: purple, size: 18),
          ),
          const SizedBox(width: 9),
          const Expanded(
            child: Text(
              'Use only this selected app for\n'
                  'Mind Control Trading to unlock\n'
                  'its full power over time.',
              style: TextStyle(
                fontSize: _Type.caption,
                height: 1.35,
                fontWeight: FontWeight.w600,
                color: ink,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PERMISSION STEP 1 — Display over other apps
  // ============================================================

  Widget _permissionStep1Screen() {
    return _permissionPageLayout(
      key: const ValueKey('perm1'),
      title: 'Enable Permission 1',
      description:
      'This permission helps Zeno AI stay visible during live market hours and guide you to stay disciplined.',
      illustration: _permissionIllustration(asset: 'assets/trade-phonne.png'),
      bottom: _psychologicalTraps(),
      granted: _hasOverlay,
      onEnable: _requestOverlayPermission,
    );
  }

  // ============================================================
  // PERMISSION STEP 2 — Package usage stats
  // ============================================================

  Widget _permissionStep2Screen() {
    return _permissionPageLayout(
      key: const ValueKey('perm2'),
      title: 'Enable Permission 2',
      description:
      'This permission helps Zeno AI track your trading process discipline during the session and measure your overall discipline across different parameters.',
      illustration: _permissionIllustration(asset: 'assets/zenoai_trade.png'),
      bottom: _usageInsights(),
      granted: _hasUsage,
      onEnable: _requestUsagePermission,
    );
  }

  Widget _permissionPageLayout({
    required Key key,
    required String title,
    required String description,
    required Widget illustration,
    required Widget bottom,
    required bool granted,
    required VoidCallback onEnable,
  }) {
    return Column(
      key: key,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Column(
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: _Type.screenTitle,
                    fontWeight: FontWeight.w800,
                    color: ink,
                  ),
                ),
                const SizedBox(height: 20),
                illustration,
                const SizedBox(height: 20),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: _Type.label,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                    color: grey,
                  ),
                ),
                const SizedBox(height: 20),
                bottom,
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: SizedBox(
            width: double.infinity,
            height: 46,
            child: Opacity(
              opacity: (_permissionBusy || granted) ? 0.6 : 1,
              child: Container(
                decoration: BoxDecoration(
                  gradient: primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: (_permissionBusy || granted) ? null : onEnable,
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
        ),
      ],
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
            'It protects you from psychological traps',
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
          title: 'FOMO',
          subtitle: '(Before the Trade)',
        ),
        const SizedBox(height: 10),
        _trapRow(
          icon: Icons.favorite_rounded,
          iconBg: const Color(0xFFFF9F4A),
          title: 'Fear & Greed',
          subtitle: '(During the Trade)',
        ),
        const SizedBox(height: 10),
        _trapRow(
          icon: Icons.replay_rounded,
          iconBg: const Color(0xFFFF4A7D),
          title: 'Revenge Trading',
          subtitle: '(After the Outcome)',
        ),
      ],
    );
  }

  Widget _trapRow({
    required IconData icon,
    required Color iconBg,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 16),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: _Type.label,
            fontWeight: FontWeight.w700,
            color: ink,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: _Type.body,
            fontWeight: FontWeight.w500,
            color: grey,
          ),
        ),
      ],
    );
  }

  Widget _usageInsights() {
    const items = [
      'Process Discipline',
      'Emotional Control',
      'Rule Adherence',
      'Consistency Score',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: Text(
            'You will get insights on:',
            style: TextStyle(
              fontSize: _Type.label,
              fontWeight: FontWeight.w700,
              color: ink,
            ),
          ),
        ),
        ...items.map(
              (label) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    gradient: primaryGradient,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: _Type.label,
                    fontWeight: FontWeight.w600,
                    color: ink,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SUCCESS
  // ============================================================

  Widget _successScreen() {
    final canSubmit = termsAccepted &&
        isCapitalValid &&
        tradingSegment != null &&
        instrument != null &&
        brokerage != null &&
        tradesPerDay != null &&
        marketEntryTimeOfDay != null &&
        (!Platform.isAndroid || _allPermissionsGranted);

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
            style: TextStyle(
              fontSize: _Type.label,
              height: 1.4,
              color: grey,
            ),
          ),
          const SizedBox(height: 15),
          _successItem('Discipline is your edge', Icons.shield_rounded),
          _successItem('Process is your protection', Icons.shield_rounded),
          _successItem('Consistency is your strength', Icons.shield_rounded),
          _successItem('Patience is your power', Icons.radio_button_checked),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => setState(() => termsAccepted = !termsAccepted),
            child: Row(
              children: [
                Container(
                  width: 19,
                  height: 19,
                  decoration: BoxDecoration(
                    color: termsAccepted ? purple : Colors.white,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: termsAccepted ? purple : const Color(0xFFAAA7B5),
                    ),
                  ),
                  child: termsAccepted
                      ? const Icon(Icons.check, color: Colors.white, size: 13)
                      : null,
                ),
                const SizedBox(width: 8),
                const Text(
                  'I agree to ',
                  style: TextStyle(fontSize: _Type.label, color: ink),
                ),
                const Text(
                  'Terms and Conditions',
                  style: TextStyle(
                    fontSize: _Type.label,
                    fontWeight: FontWeight.w700,
                    color: purple,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _gradientButton(
            text: _isSubmitting ? 'SETTING UP...' : 'SET UP MY PROCESS 🚀',
            onTap: (canSubmit && !_isSubmitting) ? _completeSetup : null,
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

    const colors = [
      purple,
      violet,
      Color(0xFF8AE1C5),
      Color(0xFFD7B1FF),
    ];

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
    return lower.replaceAll(RegExp(r'\s+'), '_');
  }

  String _getBrokerPackageName(String? name) {
    if (name == null) return 'com.zerodha.kite3';
    final lower = name.toLowerCase().trim();
    if (lower.contains('zerodha') || lower.contains('kite')) return 'com.zerodha.kite3';
    if (lower.contains('upstox')) return 'in.upstox.app';
    if (lower.contains('groww')) return 'com.nextbillion.groww';
    if (lower.contains('angel')) return 'com.msf.angelmobile';
    return 'com.zerodha.kite3';
  }

  Future<void> _completeSetup() async {
    if (_isSubmitting) return;
    if (!isCapitalValid ||
        tradingSegment == null ||
        instrument == null ||
        brokerage == null ||
        tradesPerDay == null ||
        marketEntryTimeOfDay == null ||
        (Platform.isAndroid && !_allPermissionsGranted)) {
      return;
    }

    setState(() => _isSubmitting = true);

    final formattedEntryTime = marketEntryTimeOfDay!.format(context);
    final storage = GetStorage();
    final brokerPkg = _getBrokerPackageName(brokerage);

    if (Platform.isAndroid) {
      await _prefs.saveSelectedPackage(userId: widget.userId, packageName: brokerPkg);
      await _blockService.saveUserIdForOverlay(widget.userId);
      await _blockService.blockApp(brokerPkg);
      await applyAndroidTradingAppBlock(explicitUserId: widget.userId);
    }

    await storage.write('mct_setup_completed_${widget.userId}', true);
    await storage.write('mct_trading_segment_${widget.userId}', tradingSegment);
    await storage.write('mct_instrument_${widget.userId}', instrument);
    await storage.write('mct_brokerage_${widget.userId}', brokerage);
    await storage.write('mct_trades_per_day_${widget.userId}', tradesPerDay);
    await storage.write('mct_trading_capital_${widget.userId}', tradingCapital);
    await storage.write('mct_max_risk_per_trade_${widget.userId}', maxRiskPerTrade);
    await storage.write('mct_market_entry_time_${widget.userId}', formattedEntryTime);

    final apiService = Get.isRegistered<ApiService>()
        ? Get.find<ApiService>()
        : Get.put(ApiService());

    final fields = <String, String>{
      'user_id': widget.userId,
      'trading_segment': (tradingSegment ?? 'options').toLowerCase(),
      'instrument': instrument ?? 'NIFTY 50',
      'trading_capital': tradingCapital.toString(),
      'trades_per_day': (tradesPerDay ?? 1).toString(),
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
    bool nextEnabled = true,
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
          _gradientButton(text: 'Next', onTap: nextEnabled ? nextPage : null),
          const SizedBox(height: 2),
        ],
      ),
    );
  }

  Widget _header(int step) {
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
                'Step $step of 4',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: _Type.sectionTitle,
                  fontWeight: FontWeight.w700,
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
            value: step / 4,
            minHeight: 5,
            backgroundColor: const Color(0xFFE4E2EB),
            valueColor: const AlwaysStoppedAnimation<Color>(purple),
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
        height: 76,
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
                    style: const TextStyle(fontSize: _Type.caption, color: grey),
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
          const Column(
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
        ],
      ),
    );
  }

  Widget _gradientButton({
    required String text,
    required VoidCallback? onTap,
  }) {
    final enabled = onTap != null;

    return Container(
      width: double.infinity,
      height: 46,
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
          disabledForegroundColor: Colors.white.withOpacity(0.85),
          shadowColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: _Type.buttonLabel,
            fontWeight: FontWeight.w700,
          ),
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
      '', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight',
      'Nine', 'Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen',
      'Sixteen', 'Seventeen', 'Eighteen', 'Nineteen',
    ];
    const tens = [
      '', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy',
      'Eighty', 'Ninety',
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

    final formatted =
    value == 0 ? '' : _TradingProcessScreenState._formatIndianNumber(value);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

// ================================================================
// ENUM
// ================================================================

enum InstrumentType {
  nifty,
  bank,
  sensex,
}