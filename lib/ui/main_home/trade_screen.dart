import 'package:discipline_mind/common/app_colors.dart';
import 'package:discipline_mind/model/dmt_level_model.dart';
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
      _onTradesTabActivated();
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
  // COLOR LOGIC
  // =============================================
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

  // Full overviewCard without placeholder
  Widget overviewCard({
    required Color cardColor,
    required int totalTrades,
    required int totalWins,
    required String tradeAccuracy,
    required double tradeAccuracyPercent,
    required String frr,
    required String rtt,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: cardColor,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Trades : $totalTrades',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Total Wins : $totalWins',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Trade Accuracy : $tradeAccuracy',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TradeAccuracyRing(
                  percent: tradeAccuracyPercent,
                  color: cardColor,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                const Text(
                  'RETURNS',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(frr, style: const TextStyle(color: Colors.white)),
                    Text(rtt, style: const TextStyle(color: Colors.white)),
                  ],
                ),
              ],
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
                  borderRadius: BorderRadius.circular(12),
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
                          final itemColor = _getLevelColor(level.code);
                          final isSelected =
                              _levelsService.selectedLevel.value?.id == level.id;
                          return InkWell(
                            onTap: () {
                              _levelsService.selectById(level.id);
                              _closeLevelDropdown();
                            },
                            child: Container(
                              width: double.infinity,
                              color: isSelected
                                  ? itemColor.withOpacity(0.12)
                                  : Colors.transparent,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              child: Text(
                                level.displayLabel,
                                style: TextStyle(
                                  color: itemColor,
                                  fontWeight: FontWeight.w600,
                                ),
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
      final selectedColor = _selectedColor();
      final isDark = Theme.of(context).brightness == Brightness.dark;

      final label = isLoading
          ? 'Loading levels...'
          : hasError
              ? 'Could not load levels'
              : (selected?.displayLabel ?? 'Select level');

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
              color: isDark ? const Color(0xFF161616) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: selectedColor, width: 1.4),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: (selected == null)
                          ? (isDark ? Colors.white70 : Colors.black54)
                          : selectedColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
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
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: selectedColor,
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
    return Obx(() {
      final selectedColor = _selectedColor();

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: AnimatedBuilder(
            animation: _entranceController,
            builder: (context, _) {
              return ListView(
                children: [
                  _entranceSection(
                    0,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 10),
                        _TradesHeaderRow(
                          onMonkkTap: widget.onMonkkTap,
                          color: selectedColor,
                        ),
                      ],
                    ),
                  ),
                  _entranceSection(
                    1,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 20),
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
                  _entranceSection(
                    2,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 20),
                        Obx(
                          () => Text(
                            _overviewTitle(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: selectedColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _entranceSection(
                    3,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 10),
                        Obx(
                          () => overviewCard(
                            cardColor: selectedColor,
                            totalTrades: _levelsService.displayTotalTrades,
                            totalWins: _levelsService.displayTotalWins,
                            tradeAccuracy: _levelsService.displayTradeAccuracy,
                            tradeAccuracyPercent: _levelsService.displayTradeAccuracyPercent,
                            frr: _levelsService.displayFrr,
                            rtt: _levelsService.displayRtt,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _entranceSection(
                    4,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 25),
                        Text(
                          'Per Trade Details',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: selectedColor,
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                  _entranceSection(
                    5,
                    Obx(() {
                      if (_levelsService.isLoadingTrades.value) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(child: CircularProgressIndicator()),
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
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Text(
                            'No trades for this level yet.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        );
                      }

                      return Column(
                        children: _tradeCardsFromApi(trades),
                      );
                    }),
                  ),
                ],
              );
            },
          ),
        ),
      );
    });
  }
}

class _TradesHeaderRow extends StatelessWidget {
  final VoidCallback? onMonkkTap;
  final Color color;

  const _TradesHeaderRow({
    this.onMonkkTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: onMonkkTap,
          child: Text(
            'Discipline Mind',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        Text(
          'Credits : 250',
          style: TextStyle(color: color),
        ),
      ],
    );
  }
}