import 'package:discipline_mind/common/app_colors.dart';
import 'package:discipline_mind/model/dmt_level_model.dart';
import 'package:discipline_mind/model/dmt_user_hit_trades_model.dart';
import 'package:discipline_mind/services/dmt_levels_service.dart';
import 'package:discipline_mind/ui/main_home/widgets/expandable_trade_card.dart';
import 'package:discipline_mind/ui/main_home/widgets/trade_accuracy_ring.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TradesScreen extends StatefulWidget {
  const TradesScreen({super.key, this.onMonkkTap});

  final VoidCallback? onMonkkTap;

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
  void dispose() {
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

  Widget overviewCard({
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
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
        color: Colors.white,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Trades : $totalTrades'),
              Text('Total Wins : $totalWins'),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.grey.shade200,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Trade Accuracy : $tradeAccuracy'),
                TradeAccuracyRing(percent: tradeAccuracyPercent),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(6),
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

  Widget _buildLevelDropdown() {
    return Obx(() {
      final isLoading = _levelsService.isLoadingLevels.value &&
          _levelsService.levels.isEmpty;
      final hasError = _levelsService.levelsError.value != null &&
          _levelsService.levels.isEmpty;
      final selected = _levelsService.selectedLevel.value;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.primary),
          borderRadius: BorderRadius.circular(4),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            isExpanded: true,
            value: selected?.id,
            hint: Text(
              isLoading
                  ? 'Loading levels...'
                  : hasError
                      ? 'Could not load levels'
                      : 'Select level',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            icon: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.keyboard_arrow_down),
            items: _levelsService.levels
                .map(
                  (DmtLevel level) => DropdownMenuItem<int>(
                    value: level.id,
                    child: Text(
                      level.displayLabel,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textBlack,
                      ),
                    ),
                  ),
                )
                .toList(),
            onChanged: isLoading || _levelsService.levels.isEmpty
                ? null
                : (id) => _levelsService.selectById(id),
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
                      _TradesHeaderRow(onMonkkTap: widget.onMonkkTap),
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
                          style: const TextStyle(fontWeight: FontWeight.bold),
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
                          totalTrades: _levelsService.displayTotalTrades,
                          totalWins: _levelsService.displayTotalWins,
                          tradeAccuracy: _levelsService.displayTradeAccuracy,
                          tradeAccuracyPercent:
                              _levelsService.displayTradeAccuracyPercent,
                          frr: _levelsService.displayFrr,
                          rtt: _levelsService.displayRtt,
                        ),
                      ),
                    ],
                  ),
                ),
                _entranceSection(
                  4,
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: 25),
                      Text(
                        'Per Trade Details',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 10),
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
                                  final level =
                                      _levelsService.selectedLevel.value;
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

                    return Column(children: _tradeCardsFromApi(trades));
                  }),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TradesHeaderRow extends StatelessWidget {
  const _TradesHeaderRow({this.onMonkkTap});

  final VoidCallback? onMonkkTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: onMonkkTap,
          child: const Text(
            'Discipline Mind',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
        const Row(
          children: [
            Text(
              'Credits : 250',
              style: TextStyle(color: AppColors.primary),
            ),
            SizedBox(width: 10),
            CircleAvatar(radius: 12),
          ],
        ),
      ],
    );
  }
}
