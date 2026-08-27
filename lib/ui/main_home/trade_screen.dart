import 'package:discipline_mind/common/app_colors.dart';
import 'package:discipline_mind/model/dmt_user_hit_trades_model.dart';
import 'package:discipline_mind/services/dmt_levels_service.dart';
import 'package:discipline_mind/ui/main_home/widgets/expandable_trade_card.dart';
import 'package:discipline_mind/ui/main_home/widgets/trade_accuracy_ring.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TradesScreen extends StatefulWidget {
  const TradesScreen({super.key, this.onMonkkTap, this.isActive = true});

  final VoidCallback? onMonkkTap;
  final bool isActive;

  @override
  State<TradesScreen> createState() => _TradesScreenState();
}

class _TradesScreenState extends State<TradesScreen>
    with SingleTickerProviderStateMixin {
  late final DmtLevelsService _levelsService;
  late final AnimationController _entranceController;
  Worker? _tradesLoadWorker;
  bool _skipNextLoadReplay = true;

  static const Duration _entranceDuration = Duration(milliseconds: 1400);
  static const double _sectionSpan = 0.22;
  static const double _staggerStep = 0.09;

  // ===== Custom "always opens below" dropdown state =====
  final LayerLink _levelDropdownLink = LayerLink();
  final GlobalKey _levelFieldKey = GlobalKey();
  OverlayEntry? _levelDropdownOverlay;
  bool _levelDropdownOpen = false;

  @override
  void initState() {
    super.initState();
    _levelsService = Get.isRegistered<DmtLevelsService>()
        ? Get.find<DmtLevelsService>()
        : Get.put(DmtLevelsService(), permanent: true);

    _entranceController = AnimationController(
      vsync: this,
      duration: _entranceDuration,
    );

    _tradesLoadWorker = ever<bool>(_levelsService.isLoadingTrades, (loading) {
      if (loading || !mounted) return;
      if (_skipNextLoadReplay) {
        _skipNextLoadReplay = false;
        return;
      }
      _replayEntrance();
    });

    _entranceController.forward();
    _levelsService.ensureLoaded();
  }

  @override
  void didUpdateWidget(TradesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.isActive) {
          _onTradesTabActivated();
        }
      });
    }
  }

  void _onTradesTabActivated() {
    _replayEntrance();
    _skipNextLoadReplay = true;
    _levelsService.refreshTabData();
  }

  @override
  void dispose() {
    _closeLevelDropdown();
    _tradesLoadWorker?.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  void _replayEntrance() {
    _entranceController
      ..reset()
      ..forward();
  }

  double _sectionProgress(int index) {
    final start = (index * _staggerStep).clamp(0.0, 0.72);
    final end = (start + _sectionSpan).clamp(0.0, 1.0);
    if (end <= start) return _entranceController.value;
    final t = Interval(start, end, curve: Curves.easeOutCubic)
        .transform(_entranceController.value);
    return t.clamp(0.0, 1.0);
  }

  Widget _entranceSection(int index, Widget child) {
    return AnimatedBuilder(
      animation: _entranceController,
      builder: (context, child) {
        final t = _sectionProgress(index);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 22 * (1 - t)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  // =============================================
  // LEVEL ICON & COLOR LOGIC
  // =============================================
  IconData _getLevelIcon(String? code, [String? name]) {
    final upper = (code ?? '').toUpperCase().trim();
    final lowerName = (name ?? '').toLowerCase();

    if (upper == 'BM' || lowerName.contains('believe')) {
      return Icons.psychology_outlined; // Brain for Believe Mode
    } else if (upper == 'AP' || upper == 'AM' || lowerName.contains('purple')) {
      return Icons.workspace_premium_outlined; // Trophy/Medal for Achieve Purple
    } else if (upper == 'AO' || lowerName.contains('olive')) {
      return Icons.track_changes_outlined; // Target for Achieve Olive
    } else if (upper == 'AA' || lowerName.contains('amber')) {
      return Icons.diamond_outlined; // Diamond for Achieve Amber
    } else if (upper == 'AI' || lowerName.contains('indigo')) {
      return Icons.shield_outlined; // Shield for Achieve Indigo
    } else if (upper == 'LM' || lowerName.contains('leap')) {
      return Icons.rocket_launch_outlined; // Rocket for Leap Mode
    } else if (lowerName.contains('achieve')) {
      return Icons.emoji_events_outlined;
    }
    return Icons.psychology_outlined;
  }

  Color _getLevelBadgeBg(String? code, bool isDark) {
    final upper = (code ?? '').toUpperCase().trim();
    if (isDark) return const Color(0xFF2D2644);

    switch (upper) {
      case 'BM':
        return const Color(0xFFF3EEFF);
      case 'AP':
      case 'AM':
        return const Color(0xFFF5E8FF);
      case 'AO':
        return const Color(0xFFEDF7ED);
      case 'AA':
        return const Color(0xFFFFF8E1);
      case 'AI':
        return const Color(0xFFEEF2FF);
      case 'LM':
        return const Color(0xFFE6F7F0);
      default:
        return const Color(0xFFF3EEFF);
    }
  }

  Color _getLevelIconColor(String? code) {
    final upper = (code ?? '').toUpperCase().trim();
    switch (upper) {
      case 'BM':
        return const Color(0xFF7C3AED);
      case 'AP':
      case 'AM':
        return const Color(0xFF9333EA);
      case 'AO':
        return const Color(0xFF16A34A);
      case 'AA':
        return const Color(0xFFD97706);
      case 'AI':
        return const Color(0xFF4F46E5);
      case 'LM':
        return const Color(0xFF059669);
      default:
        return const Color(0xFF7C3AED);
    }
  }

  Color _getLevelColor(String? code) {
    final upperCode = code?.toUpperCase() ?? "BM";

    switch (upperCode) {
      case "BM": // Believe Mode
        return const Color(0xFF00BCD4);
      case "AM": // Achieve Purple
      case "AP":
        return const Color(0xFFAB47BC);
      case "AO": // Achieve Olive
        return const Color(0xFF4CAF50);
      case "AA": // Achieve Amber
        return const Color(0xFFFFB300);
      case "AI": // Achieve Indigo
        return const Color(0xFF5C6BC0);
      case "LM": // Leap Mode
        return const Color(0xFF10B981);
      default:
        return AppColors.primary;
    }
  }

  Color _selectedColor() {
    final code = _levelsService.selectedLevel.value?.code;
    return _getLevelColor(code);
  }

  // =============================================
  // OVERVIEW CARD (Matching Design 100%)
  // =============================================
  Widget overviewCard({
    required int totalTrades,
    required int totalWins,
    required String tradeAccuracy,
    required double tradeAccuracyPercent,
    required String myAverage,
    required String mctAverage,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E1B2E) : Colors.white;
    final innerCardBg = isDark ? const Color(0xFF272338) : const Color(0xFFF8F7FD);
    final borderColor = isDark ? const Color(0xFF332F49) : const Color(0xFFF1EEFA);
    final labelColor = isDark ? Colors.white70 : const Color(0xFF64748B);
    final digitsColor = isDark ? Colors.white : const Color(0xFF221B66);
    const brandPurple = Color(0xFF6D28D9);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: const Color(0xFF7C3AED).withValues(alpha: 0.03),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Row 1: Total Trades & Total Wins
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
              children: [
                // Total Trades
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.bar_chart_rounded,
                        color: brandPurple,
                        size: 28,
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Trades',
                            style: TextStyle(
                              fontSize: 12,
                              color: labelColor,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$totalTrades',
                            style: TextStyle(
                              fontSize: 18,
                              color: digitsColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Divider
                Container(
                  width: 1,
                  height: 38,
                  color: isDark ? const Color(0xFF38354A) : const Color(0xFFEBE6F8),
                ),
                const SizedBox(width: 14),
                // Total Wins
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.emoji_events_outlined,
                        color: brandPurple,
                        size: 26,
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Wins',
                            style: TextStyle(
                              fontSize: 12,
                              color: labelColor,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$totalWins',
                            style: TextStyle(
                              fontSize: 18,
                              color: digitsColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Row 2: Trade Accuracy Inner Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: innerCardBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trade Accuracy',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: labelColor,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tradeAccuracy,
                      style: TextStyle(
                        fontSize: 19,
                        color: digitsColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                TradeAccuracyRing(
                  percent: tradeAccuracyPercent,
                  size: 48,
                  strokeWidth: 4.5,
                  color: const Color(0xFF7C3AED),
                  textColor: digitsColor,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Row 3: Returns Inner Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: innerCardBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                // Centered Returns Divider
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: isDark ? const Color(0xFF38354A) : const Color(0xFFE2E0F2),
                        thickness: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF8B5CF6),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'RETURNS',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: digitsColor,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF8B5CF6),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Divider(
                        color: isDark ? const Color(0xFF38354A) : const Color(0xFFE2E0F2),
                        thickness: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Returns Data
                Row(
                  children: [
                    // My Average
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'My Average',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: labelColor,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            myAverage,
                            style: TextStyle(
                              fontSize: 18,
                              color: digitsColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Divider
                    Container(
                      width: 1,
                      height: 34,
                      color: isDark ? const Color(0xFF38354A) : const Color(0xFFE2E0F2),
                    ),
                    const SizedBox(width: 14),
                    // MCT Average
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MCT Average',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: labelColor,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            mctAverage,
                            style: TextStyle(
                              fontSize: 18,
                              color: digitsColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =============================================
  // EMPTY STATE ILLUSTRATION
  // =============================================
  Widget _buildEmptyStateCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E1B2E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF332F49) : const Color(0xFFF1EEFA);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: const Color(0xFF7C3AED).withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 80,
            height: 76,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Top left sparkle
                const Positioned(
                  top: 4,
                  left: 6,
                  child: Icon(
                    Icons.auto_awesome,
                    size: 14,
                    color: Color(0xFFC4B5FD),
                  ),
                ),
                // Top right sparkle
                const Positioned(
                  top: 4,
                  right: 8,
                  child: Icon(
                    Icons.auto_awesome,
                    size: 11,
                    color: Color(0xFFDDD6FE),
                  ),
                ),
                // Clipboard card
                Container(
                  width: 50,
                  height: 58,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF272338) : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF8B5CF6),
                      width: 1.8,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Clip top
                      Align(
                        alignment: Alignment.topCenter,
                        child: Container(
                          width: 22,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFF8B5CF6),
                            borderRadius: BorderRadius.vertical(
                              bottom: Radius.circular(3),
                            ),
                          ),
                        ),
                      ),
                      // Inner document lines
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 14, 8, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 12,
                              height: 8,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(2),
                                border: Border.all(
                                  color: const Color(0xFFC4B5FD),
                                  width: 1.2,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              width: 26,
                              height: 2,
                              color: const Color(0xFFDDD6FE),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: 18,
                              height: 2,
                              color: const Color(0xFFDDD6FE),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Magnifying glass at bottom right
                Positioned(
                  bottom: 2,
                  right: 8,
                  child: Transform.rotate(
                    angle: -0.2,
                    child: const Icon(
                      Icons.search_rounded,
                      size: 28,
                      color: Color(0xFF6D28D9),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No trades for this level yet.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.white70 : const Color(0xFF64748B),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _tradeCardsFromApi(List<DmtHitTrade> trades, {int baseIndex = 6}) {
    return trades
        .asMap()
        .entries
        .map(
          (entry) => _entranceSection(
            baseIndex + entry.key.clamp(0, 6),
            ExpandableTradeCard(
              cardColor: _selectedColor(),
              key: ValueKey('hit_trade_${entry.value.alertId}_${entry.value.tradeId}'),
              title: entry.value.displayTitle,
              date: entry.value.displayDate,
              profit: entry.value.isProfitable,
              returnLabel: entry.value.displayReturn,
              trade: entry.value,
            ),
          ),
        )
        .toList();
  }

  // =============================================
  // CUSTOM DROPDOWN (always opens BELOW the field)
  // =============================================
  void _closeLevelDropdown() {
    _levelDropdownOverlay?.remove();
    _levelDropdownOverlay = null;
    if (mounted) setState(() => _levelDropdownOpen = false);
  }

  void _toggleLevelDropdown() {
    if (_levelDropdownOverlay != null) {
      _closeLevelDropdown();
    } else {
      _openLevelDropdown();
    }
  }

  void _openLevelDropdown() {
    if (_levelDropdownOverlay != null) return;
    if (_levelsService.levels.isEmpty) return;

    final renderBox = _levelFieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final fieldSize = renderBox.size;
    final overlayState = Overlay.of(context);

    _levelDropdownOverlay = OverlayEntry(
      builder: (overlayContext) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Stack(
          children: [
            // Tap outside to close
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _closeLevelDropdown,
              ),
            ),
            // Menu ALWAYS below the field: offset uses +fieldSize.height
            CompositedTransformFollower(
              link: _levelDropdownLink,
              showWhenUnlinked: false,
              offset: Offset(0, fieldSize.height + 6),
              child: Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 6,
                  color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: fieldSize.width,
                      maxWidth: fieldSize.width,
                      maxHeight: 300,
                    ),
                    child: Obx(() {
                      final levels = _levelsService.levels;
                      return ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        itemCount: levels.length,
                        itemBuilder: (context, i) {
                          final level = levels[i];
                          final isSelected =
                              _levelsService.selectedLevel.value?.id == level.id;
                          final iconData = _getLevelIcon(level.code, level.name);
                          final iconColor = _getLevelIconColor(level.code);
                          final badgeBg = _getLevelBadgeBg(level.code, isDark);

                          return InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () {
                              _levelsService.selectById(level.id);
                              _closeLevelDropdown();
                            },
                            child: Container(
                              width: double.infinity,
                              color: isSelected
                                  ? iconColor.withValues(alpha: 0.08)
                                  : Colors.transparent,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      color: badgeBg,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Icon(
                                        iconData,
                                        size: 19,
                                        color: iconColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      level.displayLabel,
                                      style: TextStyle(
                                        color: isSelected
                                            ? iconColor
                                            : (isDark ? Colors.white : const Color(0xFF1E1B4B)),
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    Icon(
                                      Icons.check_rounded,
                                      size: 20,
                                      color: iconColor,
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    }),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    overlayState.insert(_levelDropdownOverlay!);
    setState(() => _levelDropdownOpen = true);
  }

  Widget _buildLevelDropdown() {
    return Obx(() {
      final isLoading = _levelsService.isLoadingLevels.value && _levelsService.levels.isEmpty;
      final hasError = _levelsService.levelsError.value != null && _levelsService.levels.isEmpty;
      final selected = _levelsService.selectedLevel.value;
      final isDark = Theme.of(context).brightness == Brightness.dark;

      final label = isLoading
          ? 'Loading levels...'
          : hasError
              ? 'Could not load levels'
              : (selected?.displayLabel ?? 'Select level');

      final selectedIcon = _getLevelIcon(selected?.code, selected?.name);
      final selectedIconColor = _getLevelIconColor(selected?.code);
      final selectedBadgeBg = _getLevelBadgeBg(selected?.code, isDark);

      return CompositedTransformTarget(
        link: _levelDropdownLink,
        child: GestureDetector(
          key: _levelFieldKey,
          behavior: HitTestBehavior.opaque,
          onTap: (isLoading || hasError) ? null : _toggleLevelDropdown,
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1B2E) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? const Color(0xFF38354A) : const Color(0xFFE4E0F4),
                width: 1.2,
              ),
              boxShadow: [
                if (!isDark)
                  BoxShadow(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: selectedBadgeBg,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      selectedIcon,
                      size: 20,
                      color: selectedIconColor,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF1E1B4B),
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Icon(
                    _levelDropdownOpen
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: const Color(0xFF4338CA),
                    size: 24,
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }

  String _overviewTitle() {
    final name = _levelsService.selectedLevel.value?.displayLabel;
    if (name == null || name.isEmpty) return 'Trades Overview';
    return '$name Trades Overview';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sectionTitleColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: AnimatedBuilder(
          animation: _entranceController,
          builder: (context, _) {
            return RefreshIndicator(
              color: const Color(0xFF7C3AED),
              onRefresh: () => _levelsService.refreshTabData(),
              child: ListView(
                children: [
                  const SizedBox(height: 14),
                  // Level Selector Dropdown Card
                  _entranceSection(
                    0,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildLevelDropdown(),
                        Obx(() {
                          final err = _levelsService.levelsError.value;
                          if (err == null || _levelsService.levels.isNotEmpty) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    err,
                                    style: TextStyle(
                                      color: Colors.red.shade700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: _levelsService.refreshLevels,
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),

                  // Section Title: Believe Mode Trades Overview
                  _entranceSection(
                    1,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 18),
                        Obx(
                          () => Text(
                            _overviewTitle(),
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: sectionTitleColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Overview Card
                  _entranceSection(
                    2,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 10),
                        Obx(
                          () => overviewCard(
                            totalTrades: _levelsService.displayTotalTrades,
                            totalWins: _levelsService.displayTotalWins,
                            tradeAccuracy: _levelsService.displayTradeAccuracy,
                            tradeAccuracyPercent: _levelsService.displayTradeAccuracyPercent,
                            myAverage: _levelsService.displayMyAverageReturn,
                            mctAverage: _levelsService.displayMctAverageReturn,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Section Title: Per Trade Details
                  _entranceSection(
                    3,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 20),
                        Text(
                          'Per Trade Details',
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            color: sectionTitleColor,
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),

                  // Trades List or Empty State Card
                  _entranceSection(
                    4,
                    Obx(() {
                      if (_levelsService.isLoadingTrades.value) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 28),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF7C3AED),
                            ),
                          ),
                        );
                      }

                      final err = _levelsService.tradesError.value;
                      if (!_levelsService.hasLoadedHitTrades) {
                        if (err != null) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Column(
                              children: [
                                Text(
                                  err,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.red.shade700,
                                    fontSize: 13,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    final level = _levelsService.selectedLevel.value;
                                    if (level != null) {
                                      _levelsService.fetchUserHitTrades(level.id);
                                    }
                                  },
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      }

                      final trades = _levelsService.displayTrades;
                      if (trades.isEmpty) {
                        return _buildEmptyStateCard();
                      }

                      return Column(
                        children: _tradeCardsFromApi(trades),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}