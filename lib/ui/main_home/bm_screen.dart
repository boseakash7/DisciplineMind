import 'package:discipline_mind/common/app_colors.dart';
import 'package:discipline_mind/model/dmt_user_levels_summary_model.dart';
import 'package:discipline_mind/services/dmt_user_levels_summary_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:timelines_plus/timelines_plus.dart';

class BmScreen extends StatefulWidget {
  const BmScreen({super.key, this.onMonkkTap, this.isActive = true});

  final VoidCallback? onMonkkTap;
  final bool isActive;

  @override
  State<BmScreen> createState() => _BmScreenState();
}

class _BmScreenState extends State<BmScreen> with SingleTickerProviderStateMixin {
  late final DmtUserLevelsSummaryService _summaryService;
  late final AnimationController _entranceController;
  final ScrollController _timelineScrollController = ScrollController();
  Worker? _summaryLoadWorker;
  bool _skipNextLoadReplay = true;
  int? _expandedLevelId;

  static const Duration _entranceDuration = Duration(milliseconds: 1200);
  static const Duration _expandDuration = Duration(milliseconds: 350);
  static const double _sectionSpan = 0.18;
  static const double _staggerStep = 0.1;

  static const List<String> _levelCodes = ['BM', 'AP', 'AO', 'AA', 'AI'];
  static const List<Color> _levelColors = [
    AppColors.primary,
    Colors.purple,
    Colors.green,
    Colors.orange,
    Colors.indigo,
  ];

  static const List<_BmCardFallback> _fallbackCards = [
    _BmCardFallback(
      title: 'Believe Mode',
      frr: '80%',
      rtt: '20%',
      trades: '0',
      wins: '0',
      returns: '120%',
      cmReturns: '145%',
    ),
    _BmCardFallback(
      title: 'Achieve Purple',
      frr: '100%',
      trades: 'XX',
      wins: 'XX',
      risk: 'Rs. 550 to 1050',
      reward: 'Rs. 550 to Unlimited',
      returns: 'XX',
      cmReturns: 'XX',
    ),
    _BmCardFallback(
      title: 'Achieve Olive',
      frr: '100%',
      trades: 'XX',
      returns: 'XX',
      cmReturns: 'XX',
    ),
    _BmCardFallback(
      title: 'Achieve Amber',
      frr: '100%',
      trades: 'XX',
      returns: 'XX',
      cmReturns: 'XX',
    ),
    _BmCardFallback(
      title: 'Achieve Indigo',
      frr: '100%',
      trades: 'XX',
      returns: 'XX',
      cmReturns: 'XX',
    ),
  ];

  @override
  void dispose() {
    _summaryLoadWorker?.dispose();
    _entranceController.dispose();
    _timelineScrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _summaryService = Get.isRegistered<DmtUserLevelsSummaryService>()
        ? Get.find<DmtUserLevelsSummaryService>()
        : Get.put(DmtUserLevelsSummaryService(), permanent: true);
    _entranceController = AnimationController(
      vsync: this,
      duration: _entranceDuration,
    );
    _summaryLoadWorker = ever<bool>(_summaryService.isLoading, (loading) {
      if (loading || !mounted) return;
      if (_skipNextLoadReplay) {
        _skipNextLoadReplay = false;
        return;
      }
      _replayEntrance();
    });
    _entranceController.forward();
    _summaryService.ensureLoaded();
    ever(_summaryService.summaryPayload, (payload) {
      if (payload == null) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scrollToCurrentLevel(payload);
      });
    });
  }

  @override
  void didUpdateWidget(BmScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _onBmTabActivated();
    }
  }

  void _onBmTabActivated() {
    _replayEntrance();
    _skipNextLoadReplay = true;
    _summaryService.refreshTabData();
  }

  void _replayEntrance() {
    _entranceController
      ..reset()
      ..forward();
  }

  double _sectionProgress(int index) {
    final start = (index * _staggerStep).clamp(0.0, 0.75);
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
            offset: Offset(0, 20 * (1 - t)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  int? _currentLevelIndex(DmtUserLevelsSummaryPayload? payload) {
    if (payload == null) return null;
    for (var i = 0; i < _levelCodes.length; i++) {
      final level = payload.levelByCode(_levelCodes[i]);
      if (level?.isCurrent == true) return i;
    }
    final code = payload.currentLevel?.code;
    if (code != null && code.isNotEmpty) {
      final idx = _levelCodes.indexOf(code.toUpperCase());
      if (idx >= 0) return idx;
    }
    return null;
  }

  double _progressToNextLevel(DmtUserLevelSummaryItem fromLevel) {
    final next = fromLevel.nextLevel;
    if (next == null) return 1.0;

    final fromMin = fromLevel.minimumScore;
    final target = next.targetScore;
    final span = target - fromMin;
    if (span <= 0) return 0;

    return ((fromLevel.levelTotalScore - fromMin) / span).clamp(0.0, 1.0);
  }

  _ConnectorVisualState _connectorState(
    int index,
    DmtUserLevelsSummaryPayload? payload,
    ConnectorType type,
  ) {
    if (payload == null) {
      final achieved = index == 0
          ? _isLevelActive(0, null)
          : _isLevelActive(index - 1, null);
      return _ConnectorVisualState(fullyFilled: achieved);
    }

    final currentIndex = _currentLevelIndex(payload);
    if (currentIndex == null) {
      final achieved = index == 0
          ? _isLevelActive(0, payload)
          : _isLevelActive(index - 1, payload);
      return _ConnectorVisualState(fullyFilled: achieved);
    }

    if (index <= currentIndex) {
      return const _ConnectorVisualState(fullyFilled: true);
    }

    if (index == currentIndex + 1) {
      final fromLevel = payload.levelByCode(_levelCodes[currentIndex]);
      if (fromLevel != null && type == ConnectorType.end) {
        return _ConnectorVisualState(
          progress: _progressToNextLevel(fromLevel),
        );
      }
      return const _ConnectorVisualState();
    }

    return const _ConnectorVisualState();
  }

  double _connectorRevealProgress(int index) {
    final start = (index * 0.1 + 0.12).clamp(0.0, 0.72);
    final end = (start + 0.2).clamp(0.0, 1.0);
    if (end <= start) return _entranceController.value.clamp(0.0, 1.0);
    return Interval(start, end, curve: Curves.easeOutCubic)
        .transform(_entranceController.value)
        .clamp(0.0, 1.0);
  }

  Widget _buildConnector(
    int index,
    ConnectorType type,
    DmtUserLevelsSummaryPayload? payload,
  ) {
    return AnimatedBuilder(
      animation: _entranceController,
      builder: (context, _) {
        final state = _connectorState(index, payload, type);
        final fillTarget = state.fullyFilled ? 1.0 : state.progress;
        return _BmTimelineConnector(
          fillProgress: fillTarget,
          revealProgress: _connectorRevealProgress(index),
        );
      },
    );
  }

  void _scrollToCurrentLevel(DmtUserLevelsSummaryPayload payload) {
    final index = _currentLevelIndex(payload);
    if (index == null || index <= 0) return;
    if (!_timelineScrollController.hasClients) return;
    final offset = (index * 128.0).clamp(
      0.0,
      _timelineScrollController.position.maxScrollExtent,
    );
    _timelineScrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
    );
  }

  DmtUserLevelSummaryItem? _levelAt(
    int index,
    DmtUserLevelsSummaryPayload? payload,
  ) {
    if (payload == null || index < 0 || index >= _levelCodes.length) {
      return null;
    }
    final byCode = payload.levelByCode(_levelCodes[index]);
    if (byCode != null) return byCode;

    final currentLevel = payload.currentLevel;
    if (currentLevel != null && currentLevel.id > 0) {
      final byId = payload.levelById(currentLevel.id);
      if (byId != null && _levelCodes[index].toUpperCase() == byId.code.toUpperCase()) {
        return byId;
      }
    }
    return null;
  }

  bool _isLevelActive(
    int index,
    DmtUserLevelsSummaryPayload? payload,
  ) {
    final level = _levelAt(index, payload);
    if (level != null) return level.isUnlocked || level.isCurrent;
    return index == 0;
  }

  Widget modeCard({
    required String title,
    required Color color,
    required bool isAchieved,
    required bool isFirstCard,
    bool isCurrent = false,
    bool isExpanded = false,
    VoidCallback? onTap,
    String frr = '',
    String rtt = '',
    String trades = '',
    String wins = '',
    String returns = '',
    String cmReturns = '',
    String risk = '',
    String reward = '',
  }) {
    final effectiveAchieved = isAchieved || isCurrent;
    final effectiveColor = effectiveAchieved
        ? color
        : Color.lerp(color, Colors.white, 0.35)!;
    final bgOpacity = effectiveAchieved ? 0.0 : 0.1;
    final textColor = effectiveAchieved
        ? Colors.white
        : Colors.grey.shade600;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: _expandDuration,
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
        color: effectiveAchieved
            ? effectiveColor
            : effectiveColor.withOpacity(bgOpacity),
        borderRadius: BorderRadius.circular(1),
        boxShadow: isCurrent
            ? [
                BoxShadow(
                  color: color.withOpacity(0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  isFirstCard
                      ? Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'FRR',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              ' - $frr',
                              style: TextStyle(color: textColor, fontSize: 13),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'RTT',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              ' - $rtt',
                              style: TextStyle(color: textColor, fontSize: 13),
                            ),
                          ],
                        )
                      : Text(
                          'FRR - $frr${rtt.isNotEmpty ? '     RTT - $rtt' : ''}',
                          style: TextStyle(color: textColor, fontSize: 13),
                        ),
                  if (isFirstCard)
                    Text(
                      'Trades - $trades     Wins - $wins',
                      style: TextStyle(color: textColor, fontSize: 13),
                    )
                  else if (wins.isNotEmpty)
                    Text(
                      'Trades - $trades     Wins - $wins',
                      style: TextStyle(color: textColor, fontSize: 13),
                    )
                  else
                    Text(
                      'Trades - $trades',
                      style: TextStyle(color: textColor, fontSize: 13),
                    ),
                  if (risk.isNotEmpty && reward.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Risk - $risk',
                      style: TextStyle(color: textColor, fontSize: 13),
                    ),
                    Text(
                      'Reward - $reward',
                      style: TextStyle(color: textColor, fontSize: 13),
                    ),
                  ],
                  if (returns.isNotEmpty || cmReturns.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      'My Returns - $returns    CM Returns - $cmReturns',
                      style: TextStyle(color: textColor, fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (isCurrent)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Current',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 28,
                        width: 32,
                        decoration: BoxDecoration(
                          color: effectiveAchieved
                              ? Colors.white
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Icon(
                          Icons.play_arrow,
                          color: effectiveAchieved
                              ? AppColors.primary
                              : Colors.grey.shade600,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 4),
                      AnimatedRotation(
                        turns: isExpanded ? 0.25 : 0,
                        duration: _expandDuration,
                        curve: Curves.easeOutCubic,
                        child: Icon(
                          Icons.chevron_right,
                          color: effectiveAchieved
                              ? Colors.white
                              : Colors.grey.shade600,
                          size: 18,
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
    ),
    );
  }

  Widget _buildExpandedScoreSection(
    DmtUserLevelSummaryItem level,
    Color color,
  ) {
    final history = level.sortedScoreHistory;
    final next = level.nextLevel;

    return AnimatedSize(
      duration: _expandDuration,
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        child: Column(
          children: [
            if (history.isNotEmpty) ...[
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (var i = 0; i < history.length; i++) ...[
                      _animatedScoreBubble(
                        index: i,
                        dateLabel: history[i].chartDateLabel,
                        scoreLabel:
                            '${history[i].dailyScore}/${history[i].maxScore}',
                        color: color,
                      ),
                      if (i < history.length - 1) const SizedBox(width: 10),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOut,
              builder: (context, value, child) => Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 8 * (1 - value)),
                  child: child,
                ),
              ),
              child: Text(
                'Current Score under ${level.displayLabel} - ${level.levelTotalScore}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
            if (next != null && next.remainingScore > 0) ...[
              const SizedBox(height: 6),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOut,
                builder: (context, value, child) => Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 10 * (1 - value)),
                    child: child,
                  ),
                ),
                child: Text(
                  'You need ${next.remainingScore} more Score to reach next Level',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textBlack,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _animatedScoreBubble({
    required int index,
    required String dateLabel,
    required String scoreLabel,
    required Color color,
  }) {
    final delay = index * 70;
    return TweenAnimationBuilder<double>(
      key: ValueKey('bm_score_$dateLabel$scoreLabel'),
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 320 + delay),
      curve: Curves.easeOutBack,
      builder: (context, value, child) => Opacity(
        opacity: value.clamp(0.0, 1.0),
        child: Transform.scale(
          scale: 0.6 + (0.4 * value),
          child: child,
        ),
      ),
      child: _scoreHistoryBubble(
        dateLabel: dateLabel,
        scoreLabel: scoreLabel,
        color: color,
      ),
    );
  }

  Widget _scoreHistoryBubble({
    required String dateLabel,
    required String scoreLabel,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          dateLabel,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 52,
          width: 52,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            scoreLabel,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
          ),
        ),
      ],
    );
  }

  Widget _levelIndicator(
    String text,
    Color color, {
    required bool isAchieved,
    bool isCurrent = false,
  }) {
    final effectiveColor = isAchieved
        ? color
        : Color.lerp(color, Colors.white, 0.35)!;
    final bgColor = isAchieved
        ? color.withOpacity(0.2)
        : effectiveColor.withOpacity(0.25);
    return Container(
      height: 40,
      width: 40,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: isCurrent ? Border.all(color: color, width: 2.5) : null,
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(color: effectiveColor, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 10),
          _entranceSection(
            0,
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: widget.onMonkkTap,
                    child: const Text(
                      'Discipline Mind',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  Row(
                    children: const [
                      Text(
                        'Credits: 250',
                        style: TextStyle(color: AppColors.primary),
                      ),
                      SizedBox(width: 10),
                      CircleAvatar(radius: 12, backgroundColor: Colors.grey),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _entranceSection(
            1,
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Icon(
                    Icons.emoji_events_outlined,
                    color: Colors.amber.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Achievement Levels',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Obx(() {
              final payload = _summaryService.summaryPayload.value;
              return Timeline.tileBuilder(
                controller: _timelineScrollController,
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                theme: TimelineThemeData(nodePosition: 0),
                builder: TimelineTileBuilder.connected(
                  connectionDirection: ConnectionDirection.before,
                  contentsAlign: ContentsAlign.basic,
                  contentsBuilder: (context, index) => _entranceSection(
                    index + 2,
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: _buildCardForIndex(index, payload),
                    ),
                  ),
                  connectorBuilder: (context, index, type) =>
                      _buildConnector(index, type, payload),
                  indicatorBuilder: (context, index) {
                    final apiLevel = _levelAt(index, payload);
                    final code = apiLevel?.code.isNotEmpty == true
                        ? apiLevel!.code
                        : _levelCodes[index];
                    return _entranceSection(
                      index + 2,
                      ContainerIndicator(
                        child: _levelIndicator(
                          code,
                          _levelColors[index],
                          isAchieved: _isLevelActive(index, payload),
                          isCurrent: apiLevel?.isCurrent == true,
                        ),
                      ),
                    );
                  },
                  itemCount: _levelCodes.length,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildCardForIndex(
    int index,
    DmtUserLevelsSummaryPayload? payload,
  ) {
    final fallback = _fallbackCards[index];
    final apiLevel = payload?.levelByCode(_levelCodes[index]);
    final hasApi = apiLevel != null;
    final color = _levelColors[index];
    final isExpanded = hasApi && _expandedLevelId == apiLevel.id;
    final canExpand = hasApi && apiLevel.canExpand;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        modeCard(
          title: hasApi ? apiLevel.displayLabel : fallback.title,
          color: color,
          isAchieved: hasApi ? apiLevel.isUnlocked : index == 0,
          isCurrent: hasApi && apiLevel.isCurrent,
          isExpanded: isExpanded,
          isFirstCard: index == 0,
          onTap: canExpand
              ? () => setState(() {
                    _expandedLevelId =
                        isExpanded ? null : apiLevel.id;
                  })
              : null,
          frr: fallback.frr,
          rtt: fallback.rtt,
          trades: hasApi ? '${apiLevel.totalTrades}' : fallback.trades,
          wins: hasApi ? '${apiLevel.totalWins}' : fallback.wins,
          returns: fallback.returns,
          cmReturns: fallback.cmReturns,
          risk: fallback.risk,
          reward: fallback.reward,
        ),
        ClipRect(
          child: AnimatedAlign(
            duration: _expandDuration,
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            heightFactor: isExpanded && hasApi ? 1 : 0,
            child: isExpanded && hasApi
                ? _buildExpandedScoreSection(apiLevel, color)
                : const SizedBox(width: double.infinity),
          ),
        ),
      ],
    );
  }
}

class _ConnectorVisualState {
  final bool fullyFilled;
  final double progress;

  const _ConnectorVisualState({
    this.fullyFilled = false,
    this.progress = 0,
  });
}

class _BmTimelineConnector extends StatelessWidget {
  const _BmTimelineConnector({
    required this.fillProgress,
    required this.revealProgress,
  });

  final double fillProgress;
  final double revealProgress;

  static const double _lineWidth = 2;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BmConnectorPainter(
        fillProgress: fillProgress.clamp(0.0, 1.0),
        revealProgress: revealProgress.clamp(0.0, 1.0),
        lineWidth: _lineWidth,
      ),
      child: const SizedBox(width: _lineWidth, height: double.infinity),
    );
  }
}

class _BmConnectorPainter extends CustomPainter {
  _BmConnectorPainter({
    required this.fillProgress,
    required this.revealProgress,
    required this.lineWidth,
  });

  final double fillProgress;
  final double revealProgress;
  final double lineWidth;

  static const double _dashLength = 4;
  static const double _dashGap = 4;

  @override
  void paint(Canvas canvas, Size size) {
    if (revealProgress <= 0 || size.height <= 0) return;

    final x = size.width / 2;
    final visibleBottom = size.height * revealProgress;
    final solidBottom = visibleBottom * fillProgress;

    if (solidBottom > 0) {
      final solidPaint = Paint()
        ..color = Colors.black
        ..strokeWidth = lineWidth
        ..strokeCap = StrokeCap.square;
      canvas.drawLine(Offset(x, 0), Offset(x, solidBottom), solidPaint);
    }

    if (solidBottom < visibleBottom) {
      final dashPaint = Paint()
        ..color = Colors.grey.shade300
        ..strokeWidth = lineWidth
        ..strokeCap = StrokeCap.square;
      _drawDashedLine(
        canvas,
        Offset(x, solidBottom),
        Offset(x, visibleBottom),
        dashPaint,
      );
    }
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint,
  ) {
    final isVertical = (end.dy - start.dy).abs() >= (end.dx - start.dx).abs();
    if (isVertical) {
      var y = start.dy;
      while (y < end.dy) {
        final segmentEnd = (y + _dashLength).clamp(start.dy, end.dy);
        canvas.drawLine(Offset(start.dx, y), Offset(start.dx, segmentEnd), paint);
        y += _dashLength + _dashGap;
      }
      return;
    }

    final total = (end - start).distance;
    if (total <= 0) return;
    final direction = (end - start) / total;
    var traveled = 0.0;
    while (traveled < total) {
      final dashEnd = (traveled + _dashLength).clamp(0.0, total);
      canvas.drawLine(
        start + direction * traveled,
        start + direction * dashEnd,
        paint,
      );
      traveled += _dashLength + _dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant _BmConnectorPainter oldDelegate) {
    return oldDelegate.fillProgress != fillProgress ||
        oldDelegate.revealProgress != revealProgress ||
        oldDelegate.lineWidth != lineWidth;
  }
}

class _BmCardFallback {
  final String title;
  final String frr;
  final String rtt;
  final String trades;
  final String wins;
  final String returns;
  final String cmReturns;
  final String risk;
  final String reward;

  const _BmCardFallback({
    required this.title,
    this.frr = '',
    this.rtt = '',
    this.trades = '',
    this.wins = '',
    this.returns = '',
    this.cmReturns = '',
    this.risk = '',
    this.reward = '',
  });
}
