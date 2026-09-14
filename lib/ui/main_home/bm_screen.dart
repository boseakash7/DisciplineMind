// import 'package:discipline_mind/common/common.dart';
// import 'package:discipline_mind/controller/trading_process_controller.dart';
// import 'package:discipline_mind/services/dmt_user_levels_summary_service.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
//
// class BmScreen extends StatefulWidget {
//   const BmScreen({super.key, this.onMonkkTap, this.isActive = true});
//
//   final VoidCallback? onMonkkTap;
//   final bool isActive;
//
//   @override
//   State<BmScreen> createState() => _BmScreenState();
// }
//
// class _BmScreenState extends State<BmScreen> with SingleTickerProviderStateMixin {
//   late final DmtUserLevelsSummaryService _summaryService;
//   late final AnimationController _entranceController;
//   final ScrollController _timelineScrollController = ScrollController();
//   Worker? _summaryLoadWorker;
//   bool _skipNextLoadReplay = true;
//
//   int _selectedIndex = 0; // 👈 kaunsa card select hai (default BM = 0)
//
//   static const Duration _entranceDuration = Duration(milliseconds: 1200);
//
//
//
//   bool get _isZenoAi {
//     final setupType = Get.isRegistered<TradingProcessController>()
//         ? Get.find<TradingProcessController>().currentProcess.value?.tradingSetupType
//           ?? Common.userData.value?.payload?.tradingSetupType
//         : Common.userData.value?.payload?.tradingSetupType;
//     return setupType == 'zeno_ai_signals';
//   }
//
//   List<String> get _levelCodes => _isZenoAi
//       ? ['BM', 'AP', 'AO', 'AA', 'AI']
//       : ['BM', 'AM', 'LM'];
//
//   List<String> get _levelNames => _isZenoAi
//       ? ['Believe Mode', 'Apprentice Phase', 'Advanced Operator', 'Apex Achiever', 'Absolute Instinct']
//       : ['Believe Mode', 'Achieve Mode', 'Leap Mode'];
//
//   List<Color> get _levelColors => _isZenoAi
//       ? [
//           const Color(0xFF00BCD4), // Blue
//           Colors.purple,
//           Colors.green,
//           Colors.orange,
//           Colors.indigo,
//         ]
//       : [
//           const Color(0xFF00BCD4), // Blue
//           const Color(0xFFAB47BC), // Purple
//           const Color(0xFF4CAF50), // Green
//         ];
//
//   @override
//   void initState() {
//     super.initState();
//     _summaryService = Get.isRegistered<DmtUserLevelsSummaryService>()
//         ? Get.find<DmtUserLevelsSummaryService>()
//         : Get.put(DmtUserLevelsSummaryService(), permanent: true);
//
//     _entranceController = AnimationController(vsync: this, duration: _entranceDuration);
//     _summaryLoadWorker = ever<bool>(_summaryService.isLoading, (loading) {
//       if (loading || !mounted) return;
//       if (_skipNextLoadReplay) {
//         _skipNextLoadReplay = false;
//         return;
//       }
//       _entranceController.reset();
//       _entranceController.forward();
//     });
//
//     _entranceController.forward();
//     _summaryService.ensureLoaded();
//   }
//
//   @override
//   void didUpdateWidget(BmScreen oldWidget) {
//     super.didUpdateWidget(oldWidget);
//     if (widget.isActive && !oldWidget.isActive) {
//       _summaryService.refreshTabData();
//     }
//   }
//
//   @override
//   void dispose() {
//     _summaryLoadWorker?.dispose();
//     _entranceController.dispose();
//     _timelineScrollController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final isDark = Theme.of(context).brightness == Brightness.dark;
//
//     return Scaffold(
//       body: SafeArea(
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Padding(
//               padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
//               child: Row(
//                 children: [
//                   const Text('🏆', style: TextStyle(fontSize: 22)),
//                   const SizedBox(width: 8),
//                   Text(
//                     'Achievement Levels',
//                     style: TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.w600,
//                       color: isDark ? Colors.white : Colors.black,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             Expanded(
//               child: Obx(() {
//                 if (_summaryService.isLoading.value && _summaryService.summaryPayload.value == null) {
//                   return const Center(child: CircularProgressIndicator());
//                 }
//                 final payload = _summaryService.summaryPayload.value;
//                 return RefreshIndicator(
//                   onRefresh: () => _summaryService.refreshTabData(),
//                   child: ListView.builder(
//                     controller: _timelineScrollController,
//                     padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
//                     itemCount: _levelCodes.length,
//                     itemBuilder: (context, index) {
//                       final apiLevel = payload?.levelByCode(_levelCodes[index]);
//                       final color = _levelColors[index];
//
//                       final isUnlocked = apiLevel != null
//                           ? apiLevel.isUnlocked
//                           : index == 0;
//                       final isCurrent = apiLevel != null
//                           ? apiLevel.isCurrent
//                           : index == 0;
//                       final canInteract = isUnlocked || isCurrent;
//                       final isSelected = canInteract && _selectedIndex == index;
//
//                       final tradesCount = apiLevel?.totalTrades ?? 0;
//                       final winsCount = apiLevel?.totalWins ?? 0;
//                       final accuracyText = (apiLevel != null && apiLevel.tradeAccuracyText.isNotEmpty)
//                           ? apiLevel.tradeAccuracyText
//                           : '0%';
//                       final avgReturn = apiLevel?.totalAverageReturnPercentage != null
//                           ? '${apiLevel!.totalAverageReturnPercentage}%'
//                           : '0%';
//
//                       return _TimelineItem(
//                         index: index,
//                         isLast: index == _levelCodes.length - 1,
//                         title: apiLevel?.displayLabel ?? _levelNames[index],
//                         code: _levelCodes[index],
//                         color: color,
//                         isAchieved: isSelected || (isUnlocked && !canInteract),
//                         isUnlocked: isUnlocked,
//                         isCurrent: isCurrent,
//                         canInteract: canInteract,
//                         trades: '$tradesCount',
//                         wins: '$winsCount',
//                         accuracy: accuracyText,
//                         returns: avgReturn,
//                         isDark: isDark,
//                         onTap: canInteract
//                             ? () {
//                                 setState(() => _selectedIndex = index);
//                               }
//                             : null,
//                       );
//                     },
//                   ),
//                 );
//               }),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// // ==================== Timeline + Card ====================
// class _TimelineItem extends StatelessWidget {
//   final int index;
//   final bool isLast;
//   final String title, code;
//   final Color color;
//   final bool isAchieved, isUnlocked, isCurrent, canInteract;
//   final String trades, wins, accuracy, returns;
//   final bool isDark;
//   final VoidCallback? onTap;
//
//   const _TimelineItem({
//     required this.index,
//     required this.isLast,
//     required this.title,
//     required this.code,
//     required this.color,
//     required this.isAchieved,
//     required this.isUnlocked,
//     required this.isCurrent,
//     required this.canInteract,
//     required this.trades,
//     required this.wins,
//     required this.accuracy,
//     required this.returns,
//     required this.isDark,
//     this.onTap,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final dark = theme.brightness == Brightness.dark;
//
//     final effectiveColor = canInteract ? color : (dark ? Colors.grey.shade600 : Colors.grey.shade400);
//
//     final cardColor = isAchieved
//         ? color
//         : (canInteract
//             ? (dark ? const Color(0xFF242424) : color.withValues(alpha: .12))
//             : (dark ? const Color(0xFF1E1E1E) : Colors.grey.shade100));
//
//     return IntrinsicHeight(
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Column(
//             children: [
//               const SizedBox(height: 10),
//               Container(
//                 width: 48,
//                 height: 48,
//                 decoration: BoxDecoration(
//                   shape: BoxShape.circle,
//                   color: isAchieved
//                       ? color
//                       : (canInteract
//                           ? color.withValues(alpha: .15)
//                           : (dark ? Colors.grey.shade800 : Colors.grey.shade200)),
//                   border: Border.all(color: effectiveColor),
//                 ),
//                 alignment: Alignment.center,
//                 child: canInteract
//                     ? Text(
//                         code,
//                         style: TextStyle(
//                           color: isAchieved ? Colors.white : effectiveColor,
//                           fontWeight: FontWeight.bold,
//                           fontSize: 15,
//                         ),
//                       )
//                     : Icon(
//                         Icons.lock_rounded,
//                         color: effectiveColor,
//                         size: 20,
//                       ),
//               ),
//               if (!isLast)
//                 Expanded(
//                   child: Container(
//                     width: 2.5,
//                     margin: const EdgeInsets.symmetric(vertical: 6),
//                     child: CustomPaint(
//                       painter: _DottedLinePainter(
//                         color: canInteract
//                             ? color.withValues(alpha: .60)
//                             : (dark ? Colors.grey.shade700 : Colors.grey.shade300),
//                       ),
//                     ),
//                   ),
//                 ),
//             ],
//           ),
//           const SizedBox(width: 16),
//           Expanded(
//             child: Material(
//               color: Colors.transparent,
//               child: InkWell(
//                 onTap: onTap,
//                 borderRadius: BorderRadius.circular(16),
//                 child: Container(
//                   margin: const EdgeInsets.only(bottom: 20),
//                   decoration: BoxDecoration(
//                     color: cardColor,
//                     borderRadius: BorderRadius.circular(16),
//                     border: isAchieved
//                         ? null
//                         : Border(
//                             left: BorderSide(
//                               color: effectiveColor.withValues(alpha: .70),
//                               width: 2.5,
//                             ),
//                           ),
//                   ),
//                   child: _CardContent(
//                     title: title,
//                     color: effectiveColor,
//                     isAchieved: isAchieved,
//                     canInteract: canInteract,
//                     trades: trades,
//                     wins: wins,
//                     accuracy: accuracy,
//                     returns: returns,
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// class _CardContent extends StatelessWidget {
//   final String title;
//   final Color color;
//   final bool isAchieved;
//   final bool canInteract;
//   final String trades;
//   final String wins;
//   final String accuracy;
//   final String returns;
//
//   const _CardContent({
//     required this.title,
//     required this.color,
//     required this.isAchieved,
//     required this.canInteract,
//     required this.trades,
//     required this.wins,
//     required this.accuracy,
//     required this.returns,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final isDark = theme.brightness == Brightness.dark;
//
//     final textColor = isAchieved
//         ? Colors.white
//         : (isDark ? (canInteract ? Colors.white : Colors.grey.shade400) : (canInteract ? const Color(0XFF938F8F) : Colors.grey.shade500));
//
//     final subTextColor = isAchieved
//         ? Colors.white70
//         : (isDark ? (canInteract ? const Color(0XFFBCBABA) : Colors.grey.shade500) : (canInteract ? const Color(0XFF938F8F) : Colors.grey.shade400));
//
//     return Padding(
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Expanded(
//                 child: Text(
//                   title,
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                     color: isAchieved ? Colors.white : color,
//                   ),
//                 ),
//               ),
//               Container(
//                 width: 36,
//                 height: 36,
//                 decoration: BoxDecoration(
//                   color: isDark
//                       ? (canInteract ? Colors.white : Colors.grey.shade800)
//                       : (canInteract ? const Color(0XFF938F8F) : Colors.grey.shade300),
//                   shape: BoxShape.circle,
//                 ),
//                 child: Icon(
//                   canInteract ? Icons.play_arrow_rounded : Icons.lock_rounded,
//                   color: canInteract
//                       ? (!isDark ? Colors.white : Colors.grey.shade700)
//                       : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
//                   size: 20,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 14),
//           Row(
//             children: [
//               _Stat('Trades', trades, textColor, subTextColor),
//               _Stat('Wins', wins, textColor, subTextColor),
//               _Stat('Accuracy', accuracy, textColor, subTextColor),
//               const Spacer(),
//               if (canInteract)
//                 Icon(Icons.chevron_right, color: subTextColor, size: 26),
//             ],
//           ),
//           Divider(
//             height: 22,
//             color: isDark ? Colors.white24 : Colors.black12,
//           ),
//           Row(
//             children: [
//               Text(
//                 'Returns - $returns',
//                 style: TextStyle(color: subTextColor),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// class _Stat extends StatelessWidget {
//   final String label, value;
//   final Color textColor, subTextColor;
//
//   const _Stat(this.label, this.value, this.textColor, this.subTextColor);
//
//   @override
//   Widget build(BuildContext context) {
//     return Expanded(
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(label, style: TextStyle(fontSize: 11, color: subTextColor)),
//           Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textColor)),
//         ],
//       ),
//     );
//   }
// }
//
// class _DottedLinePainter extends CustomPainter {
//   final Color color;
//   const _DottedLinePainter({required this.color});
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()
//       ..color = color
//       ..strokeWidth = 2.5
//       ..strokeCap = StrokeCap.round;
//
//     const dash = 5.0;
//     const gap = 5.0;
//     double y = 0;
//     while (y < size.height) {
//       canvas.drawLine(Offset(size.width / 2, y), Offset(size.width / 2, y + dash), paint);
//       y += dash + gap;
//     }
//   }
//
//   @override
//   bool shouldRepaint(covariant _DottedLinePainter oldDelegate) => oldDelegate.color != color;
// }
import 'package:discipline_mind/common/common.dart';
import 'package:discipline_mind/controller/trading_process_controller.dart';
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
  Worker? _userWorker;
  bool _skipNextLoadReplay = true;

  int _selectedIndex = 0;

  static const Duration _entranceDuration = Duration(milliseconds: 1200);

  bool get _isZenoAi {
    final setupType = Get.isRegistered<TradingProcessController>()
        ? Get.find<TradingProcessController>().currentProcess.value?.tradingSetupType ??
            Common.userData.value?.payload?.tradingSetupType
        : Common.userData.value?.payload?.tradingSetupType;
    return setupType == 'zeno_ai_signals';
  }

  List<String> get _levelCodes => _isZenoAi ? ['BM', 'AP', 'AO', 'AA', 'AI'] : ['BM', 'AM', 'LM'];

  List<String> get _levelNames => _isZenoAi
      ? ['Believe Mode', 'Apprentice Phase', 'Advanced Operator', 'Apex Achiever', 'Absolute Instinct']
      : ['Believe Mode', 'Achieve Mode', 'Leap Mode'];

  List<String> get _levelTaglines => _isZenoAi
      ? [
          'Observe. Learn. Build conviction.',
          'Initial training. Mastering tools.',
          'Skill integration. Scaling up.',
          'Consistent performance. High precision.',
          'Peak mastery. Intuitive execution.'
        ]
      : [
          'Observe. Learn. Build conviction.',
          'Apply your process. Stay consistent.',
          'Scale up. Grow with confidence.',
        ];

  List<Color> get _levelColors => _isZenoAi
      ? [
          const Color(0xFF00BCD4),
          Colors.purple,
          Colors.green,
          Colors.orange,
          Colors.indigo,
        ]
      : [
          const Color(0xFF5E35B1),
          const Color(0xFF7E57C2),
          const Color(0xFFA657B7),
        ];

  List<dynamic> get _levelIcons => _isZenoAi
      ? [
          'assets/brain.png',
          'assets/0_img.png',
          'assets/goals.png',
          'assets/1_img.png',
          'assets/2_img.png',
        ]
      : [
          'assets/brain.png',
          'assets/0_img.png',
          'assets/goals.png',
        ];

  List<_BmCardFallback> get _fallbackCards => _isZenoAi
      ? List.generate(
          5,
          (i) => _BmCardFallback(
              title: _levelNames[i],
              code: _levelCodes[i],
              trades: '0',
              wins: '0',
              accuracy: '0.00%',
              returns: '0.00%',
              cmReturns: '0.00%'))
      : [
          _BmCardFallback(
              title: 'Believe Mode',
              code: 'BM',
              trades: '0',
              wins: '0',
              accuracy: '0.00%',
              returns: '0.00%',
              cmReturns: '0.00%'),
          _BmCardFallback(
              title: 'Achieve Mode',
              code: 'AM',
              trades: '0',
              wins: '0',
              accuracy: '0.00%',
              returns: '0.00%',
              cmReturns: '0.00%'),
          _BmCardFallback(
              title: 'Leap Mode',
              code: 'LM',
              trades: '0',
              wins: '0',
              accuracy: '0.00%',
              returns: '0.00%',
              cmReturns: '0.00%'),
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

    _userWorker = ever(Common.userData, (user) {
      if (user != null && mounted && widget.isActive) {
        _summaryService.ensureLoaded();
      }
    });

    _entranceController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.isActive) {
        _summaryService.ensureLoaded();
      }
    });
  }

  @override
  void didUpdateWidget(BmScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _summaryService.refreshTabData();
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
                ],
              ),
            ),
            Expanded(
              child: Obx(() {
                if (_summaryService.isLoading.value && _summaryService.summaryPayload.value == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (_summaryService.error.value != null && _summaryService.summaryPayload.value == null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _summaryService.error.value!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.redAccent),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => _summaryService.refreshTabData(),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                final payload = _summaryService.summaryPayload.value;
                return RefreshIndicator(
                  onRefresh: () => _summaryService.refreshTabData(),
                  child: ListView.builder(
                    controller: _timelineScrollController,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                    itemCount: _levelCodes.length,
                    itemBuilder: (context, index) {
                      final fallback = _fallbackCards[index];
                      final apiLevel = payload?.levelByCode(_levelCodes[index]);
                      final color = _levelColors[index];

                      final isUnlocked = apiLevel != null ? apiLevel.isUnlocked : (index == 0);
                      final isCurrent = apiLevel != null ? apiLevel.isCurrent : (index == 0);
                      final canInteract = isUnlocked || isCurrent;
                      final isSelected = canInteract && _selectedIndex == index;

                      final tradesCount = apiLevel?.totalTrades ?? 0;
                      final winsCount = apiLevel?.totalWins ?? 0;
                      final accuracyText = (apiLevel != null && apiLevel.tradeAccuracyText.isNotEmpty)
                          ? apiLevel.tradeAccuracyText
                          : fallback.accuracy;
                      final avgReturn = apiLevel?.totalAverageReturnPercentage != null
                          ? '${apiLevel!.totalAverageReturnPercentage}%'
                          : '0.00%';

                      return _TimelineItem(
                        index: index,
                        isLast: index == _levelCodes.length - 1,
                        title: apiLevel?.displayLabel ?? _levelNames[index],
                        tagline: _levelTaglines[index],
                        icon: _levelIcons[index],
                        color: color,
                        isAchieved: isSelected,
                        isUnlocked: isUnlocked,
                        isCurrent: isCurrent,
                        canInteract: canInteract,
                        trades: '$tradesCount',
                        wins: '$winsCount',
                        accuracy: accuracyText,
                        returns: avgReturn,
                        isDark: isDark,
                        onTap: canInteract
                            ? () {
                                setState(() => _selectedIndex = index);
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
  final bool isAchieved, isUnlocked, isCurrent, canInteract;
  final String trades, wins, accuracy, returns;
  final bool isDark;
  final VoidCallback? onTap;

  const _TimelineItem({
    required this.index,
    required this.isLast,
    required this.title,
    required this.tagline,
    required this.icon,
    required this.color,
    required this.isAchieved,
    required this.isUnlocked,
    required this.isCurrent,
    required this.canInteract,
    required this.trades,
    required this.wins,
    required this.accuracy,
    required this.returns,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = canInteract ? color : (isDark ? Colors.grey.shade600 : Colors.grey.shade400);

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
                              color: canInteract ? color.withValues(alpha: 0.5) : Colors.grey.withValues(alpha: 0.3)),
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
                              : Image.asset(
                                  icon as String,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Icon(Icons.stars_rounded, color: effectiveColor, size: 24),
                                )),
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
                              color: canInteract ? color.withValues(alpha: 0.5) : Colors.grey.withValues(alpha: 0.3)),
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
                        trades: trades,
                        wins: wins,
                        accuracy: accuracy,
                        returns: returns,
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
  final bool isAchieved, isCurrent, canInteract;
  final String trades, wins, accuracy, returns;
  final bool isDark;

  const _CardContent({
    required this.title,
    required this.tagline,
    required this.color,
    required this.isAchieved,
    required this.isCurrent,
    required this.canInteract,
    required this.trades,
    required this.wins,
    required this.accuracy,
    required this.returns,
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
                  Icons.chevron_right_rounded,
                  color: secondaryTextColor.withValues(alpha: 0.5),
                  size: 22,
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
          Text(
            'Avg Returns: $returns',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: secondaryTextColor.withValues(alpha: 0.8),
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
