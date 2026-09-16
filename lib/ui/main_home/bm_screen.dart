import 'package:discipline_mind/common/common.dart';
import 'package:discipline_mind/model/dmt_user_levels_summary_model.dart';
import 'package:discipline_mind/services/dmt_levels_service.dart';
import 'package:discipline_mind/services/dmt_user_levels_summary_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BmScreen extends StatefulWidget {
  const BmScreen({super.key, this.onMonkkTap, this.isActive = true});

  final VoidCallback? onMonkkTap;
  final bool isActive;

  @override
  State<BmScreen> createState() => _BmScreenState();
}

class _BmScreenState extends State<BmScreen> with SingleTickerProviderStateMixin {
  late final DmtUserLevelsSummaryService _summaryService;
  late final DmtLevelsService _levelsService;
  late final AnimationController _entranceController;
  final ScrollController _timelineScrollController = ScrollController();
  Worker? _summaryLoadWorker;
  Worker? _userWorker;
  bool _skipNextLoadReplay = true;

  int _selectedIndex = 0;
  int? _expandedLevelId;

  static const Duration _entranceDuration = Duration(milliseconds: 1200);

  @override
  void initState() {
    super.initState();
    _summaryService = Get.isRegistered<DmtUserLevelsSummaryService>()
        ? Get.find<DmtUserLevelsSummaryService>()
        : Get.put(DmtUserLevelsSummaryService(), permanent: true);
    _levelsService = Get.isRegistered<DmtLevelsService>()
        ? Get.find<DmtLevelsService>()
        : Get.put(DmtLevelsService(), permanent: true);

    _entranceController = AnimationController(vsync: this, duration: _entranceDuration);
    _summaryLoadWorker = ever<bool>(_summaryService.isLoading, (loading) {
      if (loading || !mounted) return;
      if (_skipNextLoadReplay) {
        _skipNextLoadReplay = false;
        return;
      }
      _entranceController.reset();
      _entranceController.forward();
    });

    _userWorker = ever(Common.userData, (user) {
      if (user != null && mounted && widget.isActive) {
        _summaryService.ensureLoaded();
        _levelsService.refreshLevels();
      }
    });

    _entranceController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.isActive) {
        _summaryService.ensureLoaded();
        _levelsService.refreshLevels();
      }
    });
  }

  @override
  void didUpdateWidget(BmScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _summaryService.refreshTabData();
      _levelsService.refreshLevels();
    }
  }

  @override
  void dispose() {
    _summaryLoadWorker?.dispose();
    _userWorker?.dispose();
    _entranceController.dispose();
    _timelineScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FE),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Row(
                children: [
                  const Text('🏆', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 10),
                  Text(
                    'Achievement Levels',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Spacer(),
                  Obx(() {
                    if (_summaryService.isLoading.value || _levelsService.isLoadingLevels.value) {
                      return const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      );
                    }
                    return const SizedBox.shrink();
                  }),
                ],
              ),
            ),
            Expanded(
              child: Obx(() {
                final dynamicLevels = _levelsService.levels;
                if (dynamicLevels.isEmpty) {
                  if (_levelsService.isLoadingLevels.value) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_levelsService.levelsError.value ?? 'No levels available'),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () => _levelsService.refreshLevels(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }
                final payload = _summaryService.summaryPayload.value;
                final totalCount = dynamicLevels.length;

                return RefreshIndicator(
                  onRefresh: () async {
                    await Future.wait([
                      _summaryService.refreshTabData(),
                      _levelsService.refreshLevels(),
                    ]);
                  },
                  child: ListView.builder(
                    controller: _timelineScrollController,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                    itemCount: totalCount,
                    itemBuilder: (context, index) {
                      final master = dynamicLevels[index];
                      final apiLevel = payload?.levelByCode(master.code) ??
                          payload?.levelById(master.id);
                      final color = master.parsedColor;
                      final disabledColor = master.parsedDisabledColor;
                      final isUnlocked = apiLevel?.isUnlocked ?? false;
                      final isCurrent = apiLevel?.isCurrent ?? false;
                      final canInteract = isUnlocked || isCurrent;
                      final isSelected = canInteract && _selectedIndex == index;
                      final levelKey = master.id;
                      final isExpanded = canInteract && _expandedLevelId == levelKey;
                      final accuracyText = apiLevel != null && apiLevel.tradeAccuracyText.isNotEmpty
                          ? apiLevel.tradeAccuracyText
                          : '?';
                      final avgReturn = apiLevel?.displayTotalAverageReturn ?? '?';
                      final mctReturn = apiLevel?.displayTotalMctAverageReturn ?? '?';
                      final title = master.displayLabel;
                      final tagline = master.tagline;
                      final icon = master.icon;

                      return _TimelineItem(
                        index: index,
                        isLast: index == totalCount - 1,
                        title: title,
                        tagline: tagline,
                        icon: icon,
                        color: color,
                        disabledColor: disabledColor,
                        isAchieved: isSelected,
                        isUnlocked: isUnlocked,
                        isCurrent: isCurrent,
                        canInteract: canInteract,
                        isExpanded: isExpanded,
                        apiLevel: apiLevel,
                        trades: apiLevel?.totalTrades.toString() ?? '?',
                        wins: apiLevel?.totalWins.toString() ?? '?',
                        accuracy: accuracyText,
                        returns: avgReturn,
                        mctReturns: mctReturn,
                        isDark: isDark,
                        onTap: canInteract
                            ? () {
                                setState(() {
                                  _selectedIndex = index;
                                  _expandedLevelId = isExpanded ? null : levelKey;
                                });
                              }
                            : null,
                      );
                    },
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final int index;
  final bool isLast;
  final String title;
  final String tagline;
  final dynamic icon;
  final Color color;
  final Color? disabledColor;
  final bool isAchieved, isUnlocked, isCurrent, canInteract, isExpanded;
  final DmtUserLevelSummaryItem? apiLevel;
  final String trades, wins, accuracy, returns, mctReturns;
  final bool isDark;
  final VoidCallback? onTap;

  const _TimelineItem({
    required this.index,
    required this.isLast,
    required this.title,
    required this.tagline,
    required this.icon,
    required this.color,
    this.disabledColor,
    required this.isAchieved,
    required this.isUnlocked,
    required this.isCurrent,
    required this.canInteract,
    required this.isExpanded,
    this.apiLevel,
    required this.trades,
    required this.wins,
    required this.accuracy,
    required this.returns,
    required this.mctReturns,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = canInteract
        ? color
        : (disabledColor ?? (isDark ? Colors.grey.shade600 : Colors.grey.shade400));

    final cardColor = isAchieved
        ? (isDark ? color.withValues(alpha: 0.2) : color.withValues(alpha: 0.05))
        : (isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF8F5FE));

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center, // Vertically center icon with card
        children: [
          // Timeline side
          SizedBox(
            width: 44,
            child: Column(
              children: [
                // Top line (except for first item)
                Expanded(
                  child: index == 0
                      ? const SizedBox()
                      : CustomPaint(
                          size: const Size(1, double.infinity),
                          painter: _DottedLinePainter(
                              color: canInteract
                                  ? color.withValues(alpha: 0.5)
                                  : (disabledColor ?? Colors.grey).withValues(alpha: 0.3)),
                        ),
                ),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    border: Border.all(color: effectiveColor.withValues(alpha: 0.5), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: effectiveColor.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      )
                    ],
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: !canInteract
                          ? Icon(Icons.lock_rounded, color: effectiveColor, size: 20)
                          : (icon is IconData
                              ? Icon(icon as IconData, color: effectiveColor, size: 24)
                              : (icon is String && (icon as String).startsWith('http')
                                  ? Image.network(
                                      icon as String,
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) =>
                                          Icon(Icons.stars_rounded, color: effectiveColor, size: 24),
                                    )
                                  : Image.asset(
                                      icon as String,
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) =>
                                          Icon(Icons.stars_rounded, color: effectiveColor, size: 24),
                                    ))),
                    ),
                  ),
                ),
                // Bottom line (except for last item)
                Expanded(
                  child: isLast
                      ? const SizedBox()
                      : CustomPaint(
                          size: const Size(1, double.infinity),
                          painter: _DottedLinePainter(
                              color: canInteract
                                  ? color.withValues(alpha: 0.5)
                                  : (disabledColor ?? Colors.grey).withValues(alpha: 0.3)),
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Card side
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isAchieved ? color : (isDark ? Colors.white10 : Colors.grey.withValues(alpha: 0.1)),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Subtle background decoration (graph wave)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Opacity(
                          opacity: 0.05,
                          child: Icon(Icons.auto_graph_rounded, size: 100, color: color),
                        ),
                      ),
                      _CardContent(
                        title: title,
                        tagline: tagline,
                        color: effectiveColor,
                        isAchieved: isAchieved,
                        isCurrent: isCurrent,
                        canInteract: canInteract,
                        isExpanded: isExpanded,
                        apiLevel: apiLevel,
                        trades: trades,
                        wins: wins,
                        accuracy: accuracy,
                        returns: returns,
                        mctReturns: mctReturns,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardContent extends StatelessWidget {
  final String title, tagline;
  final Color color;
  final bool isAchieved, isCurrent, canInteract, isExpanded;
  final DmtUserLevelSummaryItem? apiLevel;
  final String trades, wins, accuracy, returns, mctReturns;
  final bool isDark;

  const _CardContent({
    required this.title,
    required this.tagline,
    required this.color,
    required this.isAchieved,
    required this.isCurrent,
    required this.canInteract,
    required this.isExpanded,
    this.apiLevel,
    required this.trades,
    required this.wins,
    required this.accuracy,
    required this.returns,
    required this.mctReturns,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final primaryTextColor = isDark ? Colors.white : (canInteract ? color : Colors.grey.shade600);
    final secondaryTextColor = isDark ? Colors.white70 : Colors.grey.shade600;
    final statsLabelColor = isDark ? Colors.white54 : Colors.grey.shade500;
    final statsValueColor = isDark ? Colors.white : const Color(0xFF333333);

    final badgeBgColor = color.withValues(alpha: 0.08);
    final badgeTextColor = color;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: primaryTextColor,
                        letterSpacing: -0.4,
                      ),
                    ),
                    if (isCurrent) ...[
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: badgeBgColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _LiveDot(color: badgeTextColor),
                            const SizedBox(width: 6),
                            Text(
                              'You are here',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: badgeTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (canInteract)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.play_arrow_rounded,
                    color: color,
                    size: 24,
                  ),
                )
              else
                Icon(Icons.lock_rounded, color: secondaryTextColor.withValues(alpha: 0.5), size: 22),
              if (canInteract) ...[
                const SizedBox(width: 8),
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: secondaryTextColor.withValues(alpha: 0.5),
                  size: 24,
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Text(
            tagline,
            style: TextStyle(
              fontSize: 13,
              color: secondaryTextColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            height: 1,
            color: Colors.grey.withValues(alpha: 0.1),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _StatItem(
                label: 'Accuracy',
                value: accuracy,
                labelColor: statsLabelColor,
                valueColor: canInteract ? color : statsValueColor,
              ),
              Container(
                width: 1,
                height: 30,
                color: Colors.grey.withValues(alpha: 0.1),
              ),
              _StatItem(
                label: 'Trades',
                value: trades,
                labelColor: statsLabelColor,
                valueColor: statsValueColor,
              ),
              Container(
                width: 1,
                height: 30,
                color: Colors.grey.withValues(alpha: 0.1),
              ),
              _StatItem(
                label: 'Wins',
                value: wins,
                labelColor: statsLabelColor,
                valueColor: statsValueColor,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Avg Returns: $returns',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: secondaryTextColor.withValues(alpha: 0.8),
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'MCT Return: $mctReturns',
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: secondaryTextColor.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: isExpanded && apiLevel != null
                ? _buildExpandedScoreSection(apiLevel!, color, isDark)
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedScoreSection(
    DmtUserLevelSummaryItem level,
    Color color,
    bool isDark,
  ) {
    final history = level.sortedScoreHistory;
    final next = level.nextLevel;

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        children: [
          Container(
            height: 1,
            color: isDark ? Colors.white12 : Colors.grey.withValues(alpha: 0.15),
          ),
          const SizedBox(height: 14),
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
                      isDark: isDark,
                    ),
                    if (i < history.length - 1) const SizedBox(width: 10),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
          Text(
            'Current Score under ${level.displayLabel} - ${level.levelTotalScore}',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.grey.shade700,
            ),
          ),
          if (next != null && next.remainingScore > 0) ...[
            const SizedBox(height: 6),
            Text(
              'You need ${next.remainingScore} more Score to reach next Level',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1A1A1A),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _animatedScoreBubble({
    required int index,
    required String dateLabel,
    required String scoreLabel,
    required Color color,
    required bool isDark,
  }) {
    final delay = index * 70;
    return TweenAnimationBuilder<double>(
      key: ValueKey('bm_score_${dateLabel}_$scoreLabel'),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            dateLabel,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white60 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: 48,
            width: 48,
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
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label, value;
  final Color labelColor;
  final Color valueColor;

  const _StatItem({
    required this.label,
    required this.value,
    required this.labelColor,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: labelColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveDot extends StatefulWidget {
  final Color color;
  const _LiveDot({required this.color});

  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: 0.4),
              blurRadius: 4,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }
}

class _DottedLinePainter extends CustomPainter {
  final Color color;
  const _DottedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    const dash = 4.0;
    const gap = 4.0;
    double y = 0;
    while (y < size.height) {
      canvas.drawLine(Offset(size.width / 2, y), Offset(size.width / 2, y + dash), paint);
      y += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DottedLinePainter oldDelegate) => oldDelegate.color != color;
}

