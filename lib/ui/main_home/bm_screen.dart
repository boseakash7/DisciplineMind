import 'package:discipline_mind/common/app_colors.dart';
import 'package:discipline_mind/model/dmt_user_levels_summary_model.dart';
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
  late final AnimationController _entranceController;
  final ScrollController _timelineScrollController = ScrollController();
  Worker? _summaryLoadWorker;
  bool _skipNextLoadReplay = true;

  int _selectedIndex = 0; // 👈 kaunsa card select hai (default BM = 0)

  static const Duration _entranceDuration = Duration(milliseconds: 1200);

  static const List<String> _levelCodes = ['BM', 'AM', 'LM'];
  static const List<String> _levelNames = ['Believe Mode', 'Achieve Mode', 'Leap Mode'];
  static const List<Color> _levelColors = [
    Color(0xFF00BCD4), // Blue
    Color(0xFFAB47BC), // Purple
    Color(0xFF4CAF50), // Green
  ];

  static const List<_BmCardFallback> _fallbackCards = [
    _BmCardFallback(title: 'Believe Mode', code: 'BM', trades: '5', wins: '4', accuracy: '90%', returns: 'XX', cmReturns: 'XX'),
    _BmCardFallback(title: 'Achieve Mode', code: 'AM', trades: 'XX', wins: 'XX', accuracy: 'XXX', returns: 'XX', cmReturns: 'XX'),
    _BmCardFallback(title: 'Leap Mode', code: 'LM', trades: 'XX', wins: 'XX', accuracy: 'XXX', returns: 'XX', cmReturns: 'XX'),
  ];

  @override
  void initState() {
    super.initState();
    _summaryService = Get.isRegistered<DmtUserLevelsSummaryService>()
        ? Get.find<DmtUserLevelsSummaryService>()
        : Get.put(DmtUserLevelsSummaryService(), permanent: true);

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

    _entranceController.forward();
    _summaryService.ensureLoaded();
  }

  @override
  void dispose() {
    _summaryLoadWorker?.dispose();
    _entranceController.dispose();
    _timelineScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Text('🏆', style: TextStyle(fontSize: 22)),
                  SizedBox(width: 8),
                  Text(
                    'Achievement Levels',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Obx(() {
                final payload = _summaryService.summaryPayload.value;
                return ListView.builder(
                  controller: _timelineScrollController,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: _levelCodes.length,
                  itemBuilder: (context, index) {
                    final fallback = _fallbackCards[index];
                    final apiLevel = payload?.levelByCode(_levelCodes[index]);
                    final color = _levelColors[index];

                    final isCurrent = apiLevel?.isCurrent ?? false;
                    final isSelected = _selectedIndex == index; // 👈 selection check

                    return _TimelineItem(
                      index: index,
                      isLast: index == _levelCodes.length - 1,
                      title: apiLevel?.displayLabel ?? _levelNames[index],
                      code: _levelCodes[index],
                      color: color,
                      isAchieved: isSelected, // 👈 color ab selection pe depend karta hai
                      isCurrent: isCurrent,
                      trades: apiLevel?.totalTrades.toString() ?? fallback.trades,
                      wins: apiLevel?.totalWins.toString() ?? fallback.wins,
                      accuracy: fallback.accuracy,
                      returns: fallback.returns,
                      cmReturns: fallback.cmReturns,
                      isDark: isDark,
                      onTap: () {
                        setState(() => _selectedIndex = index); // 👈 tap pe select
                        // widget.onMonkkTap?.call();
                      },
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== Timeline + Card ====================
class _TimelineItem extends StatelessWidget {
  final int index;
  final bool isLast;
  final String title, code;
  final Color color;
  final bool isAchieved, isCurrent;
  final String trades, wins, accuracy, returns, cmReturns;
  final bool isDark;
  final VoidCallback? onTap;

  const _TimelineItem({
    required this.index,
    required this.isLast,
    required this.title,
    required this.code,
    required this.color,
    required this.isAchieved,
    required this.isCurrent,
    required this.trades,
    required this.wins,
    required this.accuracy,
    required this.returns,
    required this.cmReturns,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;

    final cardColor = isAchieved
        ? color
        : (dark ? const Color(0xFF1F1F24) : color.withOpacity(.12));

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isAchieved ? color : color.withOpacity(.15),
                  border: Border.all(color: color),
                ),
                alignment: Alignment.center,
                child: Text(
                  code,
                  style: TextStyle(
                    color: isAchieved ? Colors.white : color,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2.5,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: CustomPaint(
                      painter: _DottedLinePainter(color: color.withOpacity(.60)),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: isAchieved
                        ? null
                        : Border(
                            left: BorderSide(color: color.withOpacity(.70), width: 2.5),
                          ),
                  ),
                  child: _CardContent(
                    title: title,
                    color: color,
                    isAchieved: isAchieved,
                    trades: trades,
                    wins: wins,
                    accuracy: accuracy,
                    returns: returns,
                    cmReturns: cmReturns,
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
  final String title;
  final Color color;
  final bool isAchieved;
  final String trades;
  final String wins;
  final String accuracy;
  final String returns;
  final String cmReturns;

  const _CardContent({
    required this.title,
    required this.color,
    required this.isAchieved,
    required this.trades,
    required this.wins,
    required this.accuracy,
    required this.returns,
    required this.cmReturns,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final textColor = isAchieved
        ? Colors.white
        : (isDark ? Colors.white : Colors.black87);

    final subTextColor = isAchieved
        ? Colors.white70
        : (isDark ? Colors.white60 : Colors.black54);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isAchieved ? Colors.white : color,
                  ),
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(.15)
                      : Colors.black.withOpacity(.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.play_arrow_rounded,
                  color: isDark ? Colors.white : Colors.grey.shade700,
                  size: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _Stat('Trades', trades, textColor, subTextColor),
              _Stat('Wins', wins, textColor, subTextColor),
              _Stat('Accuracy', accuracy, textColor, subTextColor),
              const Spacer(),
              Icon(Icons.chevron_right, color: subTextColor, size: 26),
            ],
          ),
          Divider(
            height: 22,
            color: isDark ? Colors.white24 : Colors.black12,
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  'My Returns - $returns',
                  style: TextStyle(color: subTextColor),
                ),
              ),
              Expanded(
                child: Text(
                  'MCT Returns - $cmReturns',
                  style: TextStyle(color: subTextColor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label, value;
  final Color textColor, subTextColor;

  const _Stat(this.label, this.value, this.textColor, this.subTextColor);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: subTextColor)),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textColor)),
        ],
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
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    const dash = 5.0;
    const gap = 5.0;
    double y = 0;
    while (y < size.height) {
      canvas.drawLine(Offset(size.width / 2, y), Offset(size.width / 2, y + dash), paint);
      y += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DottedLinePainter oldDelegate) => oldDelegate.color != color;
}

class _BmCardFallback {
  final String title, code, trades, wins, accuracy, returns, cmReturns;
  const _BmCardFallback({
    required this.title,
    required this.code,
    required this.trades,
    required this.wins,
    required this.accuracy,
    required this.returns,
    required this.cmReturns,
  });
}