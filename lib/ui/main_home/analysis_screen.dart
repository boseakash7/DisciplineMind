import 'package:discipline_mind/common/app_colors.dart';
import 'package:discipline_mind/model/dmt_level_model.dart';
import 'package:discipline_mind/model/dmt_score_history_model.dart';
import 'package:discipline_mind/model/dmt_user_return_percentages_model.dart';
import 'package:discipline_mind/services/dmt_levels_service.dart';
import 'package:discipline_mind/services/dmt_score_history_service.dart';
import 'package:discipline_mind/services/dmt_user_levels_summary_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key, this.onMonkkTap, this.isActive = true});

  final VoidCallback? onMonkkTap;
  final bool isActive;

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen>
    with TickerProviderStateMixin {
  late final DmtScoreHistoryService _service;
  late final DmtLevelsService _levelsService;
  late final DmtUserLevelsSummaryService _levelsSummaryService;
  late final AnimationController _entranceController;
  late final AnimationController _chartRevealController;
  Worker? _historyLoadWorker;
  bool _skipNextLoadReplay = true;
  int? _touchedScoreIndex;
  int? _touchedProfitIndex;

  static const Duration _entranceDuration = Duration(milliseconds: 1200);
  static const Duration _chartRevealDuration = Duration(milliseconds: 900);
  static const double _sectionSpan = 0.16;
  static const double _staggerStep = 0.08;

  static const double _chartHeight = 175.0;
  static const Color _scoreLineColor = Color(0xFF00ACC1);
  static const Color _profitLineColor = Color(0xFF00B36B);
  static const Color _chartAxisColor = Color(0xFF424242);
  static const Color _chartGridColor = Color(0xFFE0E0E0);

  @override
  void initState() {
    super.initState();
    _service = Get.isRegistered<DmtScoreHistoryService>()
        ? Get.find<DmtScoreHistoryService>()
        : Get.put(DmtScoreHistoryService(), permanent: true);
    _levelsService = Get.isRegistered<DmtLevelsService>()
        ? Get.find<DmtLevelsService>()
        : Get.put(DmtLevelsService(), permanent: true);
    _levelsSummaryService = Get.isRegistered<DmtUserLevelsSummaryService>()
        ? Get.find<DmtUserLevelsSummaryService>()
        : Get.put(DmtUserLevelsSummaryService(), permanent: true);
    _entranceController = AnimationController(
      vsync: this,
      duration: _entranceDuration,
    );
    _chartRevealController = AnimationController(
      vsync: this,
      duration: _chartRevealDuration,
    );
    _historyLoadWorker = ever<bool>(_service.isLoading, (loading) {
      if (loading || !mounted) return;
      if (_skipNextLoadReplay) {
        _skipNextLoadReplay = false;
        _replayChartReveal();
        return;
      }
      // Level change / pull-to-refresh: animate charts only, not the whole page.
      _replayChartReveal();
    });
    _entranceController.forward();
    _service.ensureLoaded();
    _levelsSummaryService.ensureLoaded();
  }

  @override
  void dispose() {
    _historyLoadWorker?.dispose();
    _entranceController.dispose();
    _chartRevealController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(AnalysisScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _onAnalysisTabActivated();
    }
  }

  void _onAnalysisTabActivated() {
    _replayContentEntrance();
    _skipNextLoadReplay = true;
    _service.refreshTabData();
    _levelsSummaryService.refreshTabData();
  }

  bool _isSelectedLevelReachable(DmtScoreHistoryPayload? payload) {
    final selectedId =
        _service.selectedLevel.value?.id ??
        payload?.requestedLevel?.id ??
        payload?.currentLevel?.id;
    if (selectedId == null || selectedId <= 0) return true;

    final summary = _levelsSummaryService.summaryPayload.value;
    if (summary != null) {
      final item = summary.levelById(selectedId);
      if (item != null) {
        return item.isUnlocked || item.isCurrent;
      }
    }

    final currentId = summary?.currentLevel?.id ?? payload?.currentLevel?.id;
    if (currentId == null || currentId <= 0) return true;

    final levels = _levelsService.levels;
    final currentIdx = levels.indexWhere((l) => l.id == currentId);
    final selectedIdx = levels.indexWhere((l) => l.id == selectedId);
    if (currentIdx < 0 || selectedIdx < 0) return true;
    return selectedIdx <= currentIdx;
  }

  void _replayContentEntrance() {
    _entranceController
      ..reset()
      ..forward();
    _replayChartReveal();
  }

  void _replayChartReveal() {
    _chartRevealController
      ..reset()
      ..forward();
  }

  double _sectionProgress(int index) {
    final start = (index * _staggerStep).clamp(0.0, 0.75);
    final end = (start + _sectionSpan).clamp(0.0, 1.0);
    if (end <= start) return _entranceController.value;
    final t = Interval(
      start,
      end,
      curve: Curves.easeOutCubic,
    ).transform(_entranceController.value);
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
            offset: Offset(0, 20 * (1 - t)),
            child: Transform.scale(
              scale: 0.96 + (0.04 * t),
              alignment: Alignment.topCenter,
              child: child,
            ),
          ),
        );
      },
      child: child,
    );
  }

  double _chartReveal({double delay = 0}) {
    final start = delay.clamp(0.0, 0.85);
    final end = (start + 0.85).clamp(0.0, 1.0);
    if (end <= start) return _chartRevealController.value;
    return Interval(
      start,
      end,
      curve: Curves.easeOutCubic,
    ).transform(_chartRevealController.value).clamp(0.0, 1.0);
  }

  static Color levelColorForCode(String code) {
    switch (code.toUpperCase()) {
      case 'BM':
        return AppColors.primary;
      case 'AP':
        return Colors.purple;
      case 'AO':
        return const Color(0xFF6B8E23);
      case 'AA':
        return Colors.orange;
      case 'AI':
        return Colors.indigo;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 8),
          _buildHeader(),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: _buildLevelDropdown(),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Obx(() {
              if (_service.isLoading.value &&
                  _service.historyPayload.value == null) {
                return _entranceSection(1, _buildShimmer());
              }

              final err = _service.error.value;
              if (err != null && _service.historyPayload.value == null) {
                return _entranceSection(1, _buildError(err));
              }

              final payload = _service.historyPayload.value;
              if (payload == null) {
                return _entranceSection(
                  1,
                  _buildError('No score data available'),
                );
              }

              final selectedLevel =
                  _service.selectedLevel.value ?? payload.displayLevel;
              final isLocked = !_isSelectedLevelReachable(payload);

              if (isLocked && selectedLevel != null) {
                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async {
                    await _service.refreshTabData();
                    await _levelsSummaryService.refreshTabData();
                  },
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                    children: [
                      _entranceSection(
                        1,
                        _buildLockedLevelMessage(selectedLevel, payload),
                      ),
                    ],
                  ),
                );
              }

              final returns = _service.returnsPayload.value;

              return RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async {
                  await _service.refreshTabData();
                  await _levelsSummaryService.refreshTabData();
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                  children: [
                    // _entranceSection(1, _buildSummaryCard(payload, returns)),
                    // const SizedBox(height: 10),
                    _entranceSection(1, _buildAnimatedScoreChartCard(payload)),
                    if (payload.isViewingCurrentLevel &&
                        payload.nextLevel != null) ...[
                      const SizedBox(height: 8),
                      _entranceSection(2, _buildNextLevelBanner(payload)),
                    ],
                    const SizedBox(height: 10),
                    _entranceSection(3, _buildAnimatedProfitChartCard(returns)),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelDropdown() {
    return Obx(() {
      final isLoading =
          _levelsService.isLoadingLevels.value && _levelsService.levels.isEmpty;
      final hasError =
          _levelsService.levelsError.value != null &&
          _levelsService.levels.isEmpty;
      final selected = _service.selectedLevel.value;

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
                : (id) => _service.selectLevelById(id),
          ),
        ),
      );
    });
  }

  Widget _buildLockedLevelMessage(
    DmtLevel lockedLevel,
    DmtScoreHistoryPayload payload,
  ) {
    final color = levelColorForCode(lockedLevel.code);
    final currentLevel = payload.currentLevel;
    final summary = _levelsSummaryService.summaryPayload.value;
    final summaryItem = summary?.levelById(lockedLevel.id);
    final requiredScore = summaryItem?.minimumScore;
    final nextLabel = currentLevel?.displayLabel ?? 'your current level';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.12),
            Colors.white,
            color.withOpacity(0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.22)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 72,
            width: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [color.withOpacity(0.85), color],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.lock_rounded,
              color: Colors.white,
              size: 34,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              lockedLevel.code,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 12,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            lockedLevel.displayLabel,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textBlack,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'You have not reached this level yet',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            requiredScore != null && requiredScore > 0
                ? 'Keep building your score at $nextLabel. You need at least $requiredScore points to unlock ${lockedLevel.displayLabel}.'
                : 'Keep progressing at $nextLabel to unlock ${lockedLevel.displayLabel} and view its analysis.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.emoji_events_outlined, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                'Your focus: ${currentLevel?.displayLabel ?? 'Believe Mode'}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: widget.onMonkkTap,
            child: const Text(
              'Discipline Mind',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          Row(
            children: [
              Icon(Icons.bar_chart_rounded, color: AppColors.primary, size: 18),
              const SizedBox(width: 4),
              Text(
                'Analysis',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    DmtScoreHistoryPayload payload,
    DmtUserReturnPercentagesPayload? returns,
  ) {
    final level = payload.displayLevel;
    final color = levelColorForCode(level?.code ?? '');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              if (level != null && level.code.isNotEmpty)
                Container(
                  height: 36,
                  width: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      level.code,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      level?.displayLabel ?? 'Your Level',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${payload.displayScoreText} pts',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // if (returns != null)
              //   Column(
              //     crossAxisAlignment: CrossAxisAlignment.end,
              //     children: [
              //       Text(
              //         'Avg Return',
              //         style: TextStyle(
              //           color: Colors.white.withOpacity(0.85),
              //           fontSize: 10,
              //         ),
              //       ),
              //       Text(
              //         returns.displayAverageReturn,
              //         style: const TextStyle(
              //           color: Colors.white,
              //           fontSize: 16,
              //           fontWeight: FontWeight.w800,
              //         ),
              //       ),
              //     ],
              //   ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNextLevelBanner(DmtScoreHistoryPayload payload) {
    final next = payload.nextLevel!;
    final color = levelColorForCode(next.code);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Row(
        children: [
          Container(
            height: 32,
            width: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                next.code,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Next Level: ${next.displayLabel}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textBlack,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'You need ${formatDmtScore(next.remainingScore)} more points to reach ${next.displayLabel}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade700,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedScoreChartCard(DmtScoreHistoryPayload payload) {
    return AnimatedBuilder(
      animation: _chartRevealController,
      builder: (context, _) =>
          _buildScoreChartCard(payload, revealFactor: _chartReveal()),
    );
  }

  Widget _buildScoreChartCard(
    DmtScoreHistoryPayload payload, {
    double revealFactor = 1,
  }) {
    final history = payload.sortedHistory;
    final maxDaily = history.isEmpty
        ? 60.0
        : history
              .map((e) => e.dailyScore.toDouble())
              .reduce((a, b) => a > b ? a : b);
    final yScale = _scoreYScale(history, maxDaily);

    return _chartShell(
      title: payload.displayLevel != null
          ? 'Daily Score (${payload.displayLevel!.displayLabel})'
          : 'Daily Score',
      icon: Icons.show_chart_rounded,
      lineColor: _scoreLineColor,
      headerText: 'Current DMT Score - ${payload.displayScoreText}',
      revealFactor: revealFactor,
      child: history.isEmpty
          ? _emptyChart('No daily scores yet')
          : _classicLineChart(
              values: history.map((e) => e.dailyScore.toDouble()).toList(),
              xLabels: history.map(_shortDateLabel).toList(),
              maxY: yScale.maxY,
              yInterval: yScale.interval,
              lineColor: _scoreLineColor,
              touchedIndex: _touchedScoreIndex,
              revealFactor: revealFactor,
              formatYLabel: formatDmtScore,
              onTouch: (i) => setState(() => _touchedScoreIndex = i),
              tooltipBuilder: (i, v) {
                final e = history[i];
                return '${e.scoreDateFormatted.isNotEmpty ? e.scoreDateFormatted : e.scoreDate}\n${formatDmtScore(e.dailyScore)} pts';
              },
            ),
    );
  }

  Widget _buildAnimatedProfitChartCard(
    DmtUserReturnPercentagesPayload? returns,
  ) {
    return AnimatedBuilder(
      animation: _chartRevealController,
      builder: (context, _) => _buildProfitChartCard(
        returns,
        revealFactor: _chartReveal(delay: 0.18),
      ),
    );
  }

  Widget _buildProfitChartCard(
    DmtUserReturnPercentagesPayload? returns, {
    double revealFactor = 1,
  }) {
    if (_service.isLoadingReturns.value && returns == null) {
      return _chartShell(
        title: 'Profit Returns',
        icon: Icons.trending_up_rounded,
        lineColor: _profitLineColor,
        revealFactor: revealFactor,
        child: SizedBox(
          height: _chartHeight,
          child: Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: _profitLineColor.withOpacity(0.7),
              ),
            ),
          ),
        ),
      );
    }

    final err = _service.returnsError.value;
    if (returns == null) {
      return _chartShell(
        title: 'Profit Returns',
        icon: Icons.trending_up_rounded,
        lineColor: _profitLineColor,
        revealFactor: revealFactor,
        child: _emptyChart(err ?? 'No return data yet'),
      );
    }

    final items = returns.returnsByDate;
    final values = items.map((e) => e.returnPercentage).toList();
    final yScale = _profitYScale(values);

    return _chartShell(
      title: 'Profit Returns',
      icon: Icons.trending_up_rounded,
      lineColor: _profitLineColor,
      // trailing: returns.displayAverageReturn,
      revealFactor: revealFactor,
      child: items.isEmpty
          ? _emptyChart('No completed trades for this level')
          : _classicLineChart(
              values: values,
              xLabels: items.map(_shortReturnDateLabel).toList(),
              minY: yScale.minY,
              maxY: yScale.maxY,
              yInterval: yScale.interval,
              lineColor: _profitLineColor,
              touchedIndex: _touchedProfitIndex,
              revealFactor: revealFactor,
              emphasizeZeroLine: true,
              formatYLabel: (v) {
                final abs = v.abs();
                final text = abs % 1 == 0
                    ? v.toInt().toString()
                    : v.toStringAsFixed(1);
                return '$text%';
              },
              onTouch: (i) => setState(() => _touchedProfitIndex = i),
              tooltipBuilder: (i, v) {
                final e = items[i];
                final dateLabel = e.dateFormatted.isNotEmpty
                    ? e.dateFormatted
                    : e.date;
                if (e.tradeCount > 1) {
                  return '$dateLabel\n'
                      '${v.toStringAsFixed(2)}% avg\n'
                      '${e.tradeCount} trades';
                }
                return '$dateLabel\n${v.toStringAsFixed(2)}%';
              },
            ),
    );
  }

  Widget _chartShell({
    required String title,
    required IconData icon,
    required Color lineColor,
    required Widget child,
    String? headerText,
    String? trailing,
    double revealFactor = 1,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              0.05 * revealFactor.clamp(0.0, 1.0),
            ),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (headerText != null) ...[
            SizedBox(
              width: double.infinity,
              child: Text(
                headerText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textBlack,
                ),
              ),
            ),
            const SizedBox(height: 6),
          ],
          Row(
            children: [
              Icon(icon, color: lineColor, size: 16),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textBlack,
                ),
              ),
              const Spacer(),
              if (trailing != null)
                Opacity(
                  opacity: revealFactor.clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: 0.85 + (0.15 * revealFactor.clamp(0.0, 1.0)),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: lineColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        trailing,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: lineColor,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: _chartHeight,
            child: AnimatedOpacity(
              opacity: revealFactor.clamp(0.0, 1.0),
              duration: Duration.zero,
              child: child,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyChart(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ),
    );
  }

  Widget _classicLineChart({
    required List<double> values,
    required List<String> xLabels,
    double minY = 0,
    required double maxY,
    required double yInterval,
    required Color lineColor,
    required int? touchedIndex,
    required String Function(double value) formatYLabel,
    required void Function(int? index) onTouch,
    required String Function(int index, double value) tooltipBuilder,
    double revealFactor = 1,
    bool emphasizeZeroLine = false,
  }) {
    final reveal = revealFactor.clamp(0.0, 1.0);
    final animatedValues = values.map((v) => v * reveal).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 6, 36, 4),
      child: LineChart(
        _lineChartData(
          values: animatedValues,
          xLabels: xLabels,
          minY: minY,
          maxY: maxY,
          yInterval: yInterval,
          lineColor: lineColor,
          touchedIndex: touchedIndex,
          revealFactor: reveal,
          emphasizeZeroLine: emphasizeZeroLine,
          formatYLabel: formatYLabel,
          onTouch: onTouch,
          tooltipBuilder: tooltipBuilder,
        ),
        duration: Duration.zero,
      ),
    );
  }

  LineChartData _lineChartData({
    required List<double> values,
    required List<String> xLabels,
    required double minY,
    required double maxY,
    required double yInterval,
    required Color lineColor,
    required int? touchedIndex,
    required String Function(double value) formatYLabel,
    required void Function(int? index) onTouch,
    required String Function(int index, double value) tooltipBuilder,
    double revealFactor = 1,
    bool emphasizeZeroLine = false,
  }) {
    final maxX = values.length <= 1 ? 1.0 : (values.length - 1).toDouble();
    final reveal = revealFactor.clamp(0.0, 1.0);

    return LineChartData(
      minX: 0,
      maxX: maxX,
      minY: minY,
      maxY: maxY,
      backgroundColor: Colors.white,
      lineTouchData: LineTouchData(
        enabled: true,
        touchCallback: (event, response) {
          if (!event.isInterestedForInteractions ||
              response == null ||
              response.lineBarSpots == null ||
              response.lineBarSpots!.isEmpty) {
            onTouch(null);
            return;
          }
          onTouch(response.lineBarSpots!.first.x.toInt());
        },
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => _chartAxisColor.withOpacity(0.9),
          tooltipPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 5,
          ),
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              final index = spot.x.toInt();
              if (index < 0 || index >= values.length) return null;
              return LineTooltipItem(
                tooltipBuilder(index, spot.y),
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              );
            }).toList();
          },
        ),
      ),
      titlesData: FlTitlesData(
        show: true,
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false, reservedSize: 22),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 34,
            interval: yInterval,
            getTitlesWidget: (value, meta) {
              if (value < minY - 0.001 || value > maxY + 0.001) {
                return const SizedBox.shrink();
              }
              final rem = (value / yInterval).roundToDouble() * yInterval;
              if ((value - rem).abs() > yInterval * 0.15) {
                return const SizedBox.shrink();
              }
              final isZero = emphasizeZeroLine && value.abs() < 0.001;
              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(
                  formatYLabel(value),
                  style: TextStyle(
                    color: isZero ? lineColor : _chartAxisColor,
                    fontSize: 10,
                    fontWeight: isZero ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 48,
            interval: 1,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < 0 || index >= xLabels.length) {
                return const SizedBox.shrink();
              }
              final isTouched = touchedIndex == index;
              final isFirst = index == 0;
              final isLast = index == xLabels.length - 1;
              final label = Transform.rotate(
                angle: -0.785398,
                alignment: isLast
                    ? Alignment.topRight
                    : isFirst
                    ? Alignment.topLeft
                    : Alignment.topCenter,
                child: Text(
                  xLabels[index],
                  textAlign: isLast
                      ? TextAlign.right
                      : isFirst
                      ? TextAlign.left
                      : TextAlign.center,
                  style: TextStyle(
                    color: isTouched ? lineColor : _chartAxisColor,
                    fontSize: 10,
                    fontWeight: isTouched ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              );
              return Padding(
                padding: EdgeInsets.only(
                  top: 8,
                  left: isFirst ? 4 : 0,
                  right: isLast ? 8 : 0,
                ),
                child: isLast
                    ? Align(
                        alignment: Alignment.centerRight,
                        widthFactor: 1,
                        child: label,
                      )
                    : isFirst
                    ? Align(
                        alignment: Alignment.centerLeft,
                        widthFactor: 1,
                        child: label,
                      )
                    : label,
              );
            },
          ),
        ),
      ),
      gridData: FlGridData(
        show: reveal > 0.05,
        drawVerticalLine: true,
        drawHorizontalLine: true,
        horizontalInterval: yInterval,
        verticalInterval: 1,
        getDrawingHorizontalLine: (value) {
          if (emphasizeZeroLine && value.abs() < 0.001) {
            return FlLine(
              color: _chartAxisColor.withOpacity(reveal * 0.85),
              strokeWidth: 1.5,
            );
          }
          return FlLine(
            color: _chartGridColor.withOpacity(reveal),
            strokeWidth: 1,
          );
        },
        getDrawingVerticalLine: (value) =>
            FlLine(color: _chartGridColor.withOpacity(reveal), strokeWidth: 1),
      ),
      borderData: FlBorderData(
        show: reveal > 0.05,
        border: Border(
          left: BorderSide(
            color: _chartAxisColor.withOpacity(reveal),
            width: 1.5,
          ),
          bottom: BorderSide(
            color: _chartAxisColor.withOpacity(reveal),
            width: 1.5,
          ),
          top: BorderSide.none,
          right: BorderSide.none,
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: [
            for (var i = 0; i < values.length; i++)
              FlSpot(i.toDouble(), values[i]),
          ],
          isCurved: false,
          color: lineColor.withOpacity(reveal),
          barWidth: 3.5,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: reveal > 0.15,
            getDotPainter: (spot, percent, bar, index) {
              final isTouched = touchedIndex == index;
              return FlDotCirclePainter(
                radius: isTouched ? 6 : 4.5,
                color: Colors.white,
                strokeWidth: isTouched ? 3 : 2.5,
                strokeColor: lineColor,
              );
            },
          ),
          belowBarData: BarAreaData(show: false),
        ),
      ],
    );
  }

  ({double maxY, double interval}) _scoreYScale(
    List<DmtScoreHistoryEntry> history,
    double maxDaily,
  ) {
    final cap = history.isNotEmpty ? history.first.maxScore.toDouble() : 60.0;
    final top = maxDaily > cap ? maxDaily : cap;
    final maxY = ((top / 10).ceil() * 10).toDouble().clamp(
      10.0,
      double.infinity,
    );
    final interval = maxY <= 60 ? 10.0 : maxY / 5;
    return (maxY: maxY, interval: interval);
  }

  ({double minY, double maxY, double interval}) _profitYScale(
    List<double> values,
  ) {
    if (values.isEmpty) {
      return (minY: -5.0, maxY: 5.0, interval: 2.5);
    }

    final minVal = values.reduce((a, b) => a < b ? a : b);
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    final maxAbs = minVal.abs() > maxVal.abs() ? minVal.abs() : maxVal.abs();
    final padded = maxAbs <= 0 ? 1.0 : ((maxAbs * 1.2) / 0.5).ceil() * 0.5;
    final bound = padded < 1 ? 1.0 : padded;
    final interval = bound <= 5 ? bound / 2 : bound / 2;
    return (minY: -bound, maxY: bound, interval: interval);
  }

  String _shortReturnDateLabel(DmtDailyReturn entry) {
    try {
      final d = DateTime.parse(entry.date);
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${d.day} ${months[d.month - 1]}';
    } catch (_) {
      return entry.dateFormatted.isNotEmpty ? entry.dateFormatted : entry.date;
    }
  }

  String _shortDateLabel(DmtScoreHistoryEntry entry) {
    try {
      final d = DateTime.parse(entry.scoreDate);
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${d.day} ${months[d.month - 1]}';
    } catch (_) {
      return entry.scoreDateFormatted.isNotEmpty
          ? entry.scoreDateFormatted
          : entry.scoreDate;
    }
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 40, color: Colors.grey.shade400),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: _service.refreshTabData,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry'),
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Column(
            children: [
              Container(
                height: 88,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                height: 220,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                height: 220,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
