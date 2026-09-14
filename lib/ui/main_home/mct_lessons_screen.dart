// import 'package:discipline_mind/ui/onboarding/trading_profile_flow.dart'
//     show MctVideoPlayerPage;
// import 'package:flutter/material.dart';
// import 'package:get_storage/get_storage.dart';
//
// // ============================================================================
// // MCT LESSONS SCREEN
// // ============================================================================
// // Standalone entry point reached from the "More" tab. Mirrors the palette
// // used across the onboarding trading-profile flow for visual consistency.
//
// class MctLessonsScreen extends StatefulWidget {
//   const MctLessonsScreen({super.key, required this.userId});
//
//   final String userId;
//
//   static const Color purple = Color(0xFF4A22F4);
//   static const Color violet = Color(0xFF983BF4);
//   static const Color ink = Color(0xFF10122D);
//
//   static const String _dummyVideo = 'assets/dummy_mct_video.mp4';
//   static const String _introTitle = 'Your Introduction to Zeno AI';
//
//   static const List<_Protocol> _protocols = [
//     _Protocol(
//       number: 1,
//       title: 'Process Over Everything',
//       color: Color(0xFF1E9E5B),
//       bgColor: Color(0xFFE3F6EA),
//       videoCount: 5,
//       duration: '4 mins',
//     ),
//     _Protocol(
//       number: 2,
//       title: 'Cut the Noise',
//       color: Color(0xFFE0522A),
//       bgColor: Color(0xFFFDEAE3),
//       videoCount: 5,
//       duration: '5 mins',
//     ),
//     _Protocol(
//       number: 3,
//       title: 'Trust the Process',
//       color: Color(0xFF2F6FED),
//       bgColor: Color(0xFFE6EFFE),
//       videoCount: 5,
//       duration: '7 mins',
//     ),
//     _Protocol(
//       number: 4,
//       title: 'Step-up Gradually',
//       color: Color(0xFF7C5CFC),
//       bgColor: Color(0xFFEFEAFE),
//       videoCount: 5,
//       duration: '6 mins',
//     ),
//     _Protocol(
//       number: 5,
//       title: 'Be True',
//       color: Color(0xFFD79A1E),
//       bgColor: Color(0xFFFDF3DA),
//       videoCount: 5,
//       duration: '5 mins',
//     ),
//   ];
//
//   static int get _totalLessons => _protocols.length + 1;
//
//   @override
//   State<MctLessonsScreen> createState() => _MctLessonsScreenState();
// }
//
// class _MctLessonsScreenState extends State<MctLessonsScreen> {
//   late final String _storageKey =
//       'mct_lessons_completed_${widget.userId}';
//   late Set<String> _completedLessons = _loadCompletedLessons();
//
//   Set<String> _loadCompletedLessons() {
//     final List<dynamic>? stored = GetStorage().read<List<dynamic>>(
//       _storageKey,
//     );
//     return stored?.map((e) => e.toString()).toSet() ?? <String>{};
//   }
//
//   void _markCompleted(String lessonId) {
//     if (_completedLessons.contains(lessonId)) {
//       return;
//     }
//
//     setState(() => _completedLessons.add(lessonId));
//     GetStorage().write(_storageKey, _completedLessons.toList());
//   }
//
//   Future<void> _openVideo(String title, String lessonId) async {
//     await Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => MctVideoPlayerPage(
//           title: title,
//           videoPath: MctLessonsScreen._dummyVideo,
//         ),
//       ),
//     );
//
//     _markCompleted(lessonId);
//   }
//
//   List<Widget> _buildAppDemoContent(List<_Protocol> protocols) {
//     return [
//       const _SectionDivider(label: 'PROTOCOLS OF MIND CONTROL TRADING'),
//       const SizedBox(height: 14),
//       for (final protocol in protocols) ...[
//         _ProtocolCard(
//           protocol: protocol,
//           onTap: () =>
//               _openVideo(protocol.title, 'protocol_${protocol.number}'),
//         ),
//         const SizedBox(height: 12),
//       ],
//     ];
//   }
//
//   List<Widget> _buildExplanationContent() {
//     return [
//       const _SectionDivider(label: 'INTRODUCTION'),
//       const SizedBox(height: 14),
//       _ExplanationVideoCard(
//         imagePath: 'assets/0_img.png',
//         title: MctLessonsScreen._introTitle,
//         duration: '2 mins',
//         onTap: () => _openVideo(MctLessonsScreen._introTitle, 'intro'),
//       ),
//     ];
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: SafeArea(
//         child: Column(
//           children: [
//             Padding(
//               padding: const EdgeInsets.fromLTRB(4, 4, 20, 0),
//               child: Row(
//                 children: [
//                   IconButton(
//                     onPressed: () => Navigator.pop(context),
//                     icon: const Icon(
//                       Icons.arrow_back,
//                       color: MctLessonsScreen.ink,
//                     ),
//                   ),
//                   const Text(
//                     'MCT LESSONS',
//                     style: TextStyle(
//                       fontSize: 17,
//                       fontWeight: FontWeight.w800,
//                       color: MctLessonsScreen.ink,
//                       letterSpacing: 0.3,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//
//             Padding(
//               padding: const EdgeInsets.fromLTRB(24, 6, 24, 0),
//               child: Row(
//                 crossAxisAlignment: CrossAxisAlignment.center,
//                 children: [
//                   Image.asset(
//                     'assets/mct_lession_header_img.png',
//                     height: 90,
//                     fit: BoxFit.contain,
//                   ),
//                   const SizedBox(width: 14),
//                   const Expanded(
//                     child: Text(
//                       'Please watch videos in sequence\n'
//                       'for better Understanding of Mind\n'
//                       'Control Trading Process',
//                       style: TextStyle(
//                         color: Color(0xFF6C6C7C),
//                         fontSize: 12.5,
//                         height: 1.4,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//
//             const SizedBox(height: 16),
//
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 24),
//               child: _ProgressCard(
//                 completed: _completedLessons.length,
//                 total: MctLessonsScreen._totalLessons,
//               ),
//             ),
//
//             const SizedBox(height: 18),
//
//             Expanded(
//               child: ListView(
//                 padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
//                 children: [
//                   ..._buildExplanationContent(),
//                   const SizedBox(height: 22),
//                   ..._buildAppDemoContent(MctLessonsScreen._protocols),
//                   const SizedBox(height: 6),
//                   const _FooterBar(),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// // ============================================================================
// // PROGRESS CARD
// // ============================================================================
//
// class _ProgressCard extends StatelessWidget {
//   const _ProgressCard({required this.completed, required this.total});
//
//   final int completed;
//   final int total;
//
//   @override
//   Widget build(BuildContext context) {
//     final double fraction = total == 0 ? 0 : completed / total;
//     final int percent = (fraction * 100).round();
//
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(14),
//         border: Border.all(color: const Color(0xFFEDEBF7)),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.04),
//             blurRadius: 10,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Text(
//                 '$percent%',
//                 style: const TextStyle(
//                   color: MctLessonsScreen.ink,
//                   fontSize: 15,
//                   fontWeight: FontWeight.w800,
//                 ),
//               ),
//               const SizedBox(width: 6),
//               const Text(
//                 'Completed',
//                 style: TextStyle(
//                   color: Color(0xFF8A8A99),
//                   fontSize: 12.5,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: ClipRRect(
//                   borderRadius: BorderRadius.circular(6),
//                   child: LinearProgressIndicator(
//                     value: fraction,
//                     minHeight: 7,
//                     backgroundColor: const Color(0xFFE9E7F3),
//                     valueColor: const AlwaysStoppedAnimation<Color>(
//                       MctLessonsScreen.purple,
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//
//           const SizedBox(height: 8),
//
//           Text(
//             '$completed of $total lessons completed',
//             style: const TextStyle(
//               color: MctLessonsScreen.purple,
//               fontSize: 11.5,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// // ============================================================================
// // SECTION DIVIDER (dashed line — •  LABEL  • — dashed line)
// // ============================================================================
//
// class _DashedLine extends StatelessWidget {
//   const _DashedLine();
//
//   static const double _dashWidth = 4;
//   static const double _dashGap = 3;
//   static const Color _color = Color(0xFFDAD7EC);
//
//   @override
//   Widget build(BuildContext context) {
//     return LayoutBuilder(
//       builder: (context, constraints) {
//         final dashCount =
//             (constraints.maxWidth / (_dashWidth + _dashGap)).floor();
//         return Row(
//           children: List.generate(dashCount, (_) {
//             return Padding(
//               padding: const EdgeInsets.only(right: _dashGap),
//               child: Container(width: _dashWidth, height: 1, color: _color),
//             );
//           }),
//         );
//       },
//     );
//   }
// }
//
// class _SectionDivider extends StatelessWidget {
//   const _SectionDivider({required this.label});
//
//   final String label;
//
//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: [
//         const Expanded(child: _DashedLine()),
//         Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 8),
//           child: Row(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               _Bullet(),
//               const SizedBox(width: 6),
//               Text(
//                 label,
//                 style: const TextStyle(
//                   color: MctLessonsScreen.violet,
//                   fontSize: 11,
//                   fontWeight: FontWeight.w800,
//                   letterSpacing: 0.4,
//                 ),
//               ),
//               const SizedBox(width: 6),
//               _Bullet(),
//             ],
//           ),
//         ),
//         const Expanded(child: _DashedLine()),
//       ],
//     );
//   }
// }
//
// class _Bullet extends StatelessWidget {
//   const _Bullet();
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: 4,
//       height: 4,
//       decoration: const BoxDecoration(
//         color: MctLessonsScreen.violet,
//         shape: BoxShape.circle,
//       ),
//     );
//   }
// }
//
// // ============================================================================
// // PROTOCOL CARD (APP DEMO mode)
// // ============================================================================
//
// class _Protocol {
//   const _Protocol({
//     required this.number,
//     required this.title,
//     required this.color,
//     required this.bgColor,
//     required this.videoCount,
//     required this.duration,
//   });
//
//   final int number;
//   final String title;
//   final Color color;
//   final Color bgColor;
//   final int videoCount;
//   final String duration;
// }
//
// class _ProtocolCard extends StatelessWidget {
//   const _ProtocolCard({required this.protocol, required this.onTap});
//
//   final _Protocol protocol;
//   final VoidCallback onTap;
//
//   @override
//   Widget build(BuildContext context) {
//     return InkWell(
//       borderRadius: BorderRadius.circular(16),
//       onTap: onTap,
//       child: Container(
//         padding: const EdgeInsets.all(14),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(16),
//           border: Border.all(color: const Color(0xFFEDEBF7)),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.04),
//               blurRadius: 10,
//               offset: const Offset(0, 4),
//             ),
//           ],
//         ),
//         child: Row(
//           children: [
//             ClipOval(
//               child: Image.asset(
//                 'assets/${protocol.number}_img.png',
//                 width: 46,
//                 height: 46,
//                 fit: BoxFit.cover,
//               ),
//             ),
//
//             const SizedBox(width: 12),
//
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     'PROTOCOL NO. ${protocol.number}',
//                     style: TextStyle(
//                       color: protocol.color,
//                       fontSize: 10.5,
//                       fontWeight: FontWeight.w800,
//                       letterSpacing: 0.3,
//                     ),
//                   ),
//
//                   const SizedBox(height: 2),
//
//                   Text(
//                     protocol.title,
//                     style: const TextStyle(
//                       color: MctLessonsScreen.ink,
//                       fontSize: 14.5,
//                       fontWeight: FontWeight.w800,
//                     ),
//                   ),
//
//                   const SizedBox(height: 6),
//
//                   Row(
//                     children: [
//                       _Tag(
//                         icon: Icons.smartphone_outlined,
//                         label: 'App Demo (1-5)',
//                         color: protocol.color,
//                         bgColor: protocol.bgColor,
//                       ),
//                       const SizedBox(width: 8),
//                       _Tag(
//                         icon: Icons.videocam_outlined,
//                         label: '${protocol.videoCount} videos',
//                         color: const Color(0xFF6C6C7C),
//                         bgColor: const Color(0xFFF1F1F5),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//
//             const SizedBox(width: 8),
//
//             Container(
//               width: 34,
//               height: 34,
//               decoration: const BoxDecoration(
//                 gradient: LinearGradient(
//                   colors: [MctLessonsScreen.purple, MctLessonsScreen.violet],
//                 ),
//                 shape: BoxShape.circle,
//               ),
//               child: const Icon(
//                 Icons.play_arrow_rounded,
//                 color: Colors.white,
//                 size: 18,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// class _Tag extends StatelessWidget {
//   const _Tag({
//     required this.icon,
//     required this.label,
//     required this.color,
//     required this.bgColor,
//   });
//
//   final IconData icon;
//   final String label;
//   final Color color;
//   final Color bgColor;
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
//       decoration: BoxDecoration(
//         color: bgColor,
//         borderRadius: BorderRadius.circular(20),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(icon, size: 11, color: color),
//           const SizedBox(width: 4),
//           Text(
//             label,
//             style: TextStyle(
//               color: color,
//               fontSize: 9.5,
//               fontWeight: FontWeight.w700,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// // ============================================================================
// // EXPLANATION VIDEO CARD (EXPLANATION mode)
// // ============================================================================
//
// class _ExplanationVideoCard extends StatelessWidget {
//   const _ExplanationVideoCard({
//     required this.imagePath,
//     required this.title,
//     required this.duration,
//     required this.onTap,
//   });
//
//   final String imagePath;
//   final String title;
//   final String duration;
//   final VoidCallback onTap;
//
//   @override
//   Widget build(BuildContext context) {
//     return InkWell(
//       borderRadius: BorderRadius.circular(16),
//       onTap: onTap,
//       child: Container(
//         padding: const EdgeInsets.all(14),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(16),
//           border: Border.all(color: const Color(0xFFEDEBF7)),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.04),
//               blurRadius: 10,
//               offset: const Offset(0, 4),
//             ),
//           ],
//         ),
//         child: Row(
//           children: [
//             ClipOval(
//               child: Image.asset(
//                 imagePath,
//                 width: 52,
//                 height: 52,
//                 fit: BoxFit.cover,
//               ),
//             ),
//
//             const SizedBox(width: 12),
//
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Container(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 8,
//                       vertical: 3,
//                     ),
//                     decoration: BoxDecoration(
//                       color: const Color(0xFFEFEAFE),
//                       borderRadius: BorderRadius.circular(20),
//                     ),
//                     child: Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         const Icon(
//                           Icons.play_arrow_rounded,
//                           size: 11,
//                           color: MctLessonsScreen.purple,
//                         ),
//                         const SizedBox(width: 3),
//                         const Text(
//                           'VIDEO',
//                           style: TextStyle(
//                             color: MctLessonsScreen.purple,
//                             fontSize: 9.5,
//                             fontWeight: FontWeight.w800,
//                             letterSpacing: 0.3,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//
//                   const SizedBox(height: 6),
//
//                   Text(
//                     title,
//                     style: const TextStyle(
//                       color: MctLessonsScreen.ink,
//                       fontSize: 14.5,
//                       fontWeight: FontWeight.w800,
//                     ),
//                   ),
//
//                   const SizedBox(height: 6),
//
//                   Row(
//                     children: [
//                       const Icon(
//                         Icons.access_time_rounded,
//                         size: 12,
//                         color: Color(0xFF8A8A99),
//                       ),
//                       const SizedBox(width: 4),
//                       Text(
//                         duration,
//                         style: const TextStyle(
//                           color: Color(0xFF8A8A99),
//                           fontSize: 11,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//
//             const SizedBox(width: 8),
//
//             Container(
//               width: 34,
//               height: 34,
//               decoration: const BoxDecoration(
//                 gradient: LinearGradient(
//                   colors: [MctLessonsScreen.purple, MctLessonsScreen.violet],
//                 ),
//                 shape: BoxShape.circle,
//               ),
//               child: const Icon(
//                 Icons.play_arrow_rounded,
//                 color: Colors.white,
//                 size: 18,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// // ============================================================================
// // FOOTER BAR
// // ============================================================================
//
// class _FooterBar extends StatelessWidget {
//   const _FooterBar();
//
//   @override
//   Widget build(BuildContext context) {
//     const prefix = 'Each lesson has one part:';
//     const chipIcon = Icons.videocam_outlined;
//     final chipLabel = '${MctLessonsScreen._totalLessons} videos total';
//
//     return Container(
//       padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
//       decoration: BoxDecoration(
//         color: const Color(0xFFEFEAFE),
//         borderRadius: BorderRadius.circular(30),
//         border: Border.all(color: const Color(0xFFE3DFF5)),
//       ),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.center,
//         children: [
//           const Icon(Icons.info, color: Color(0xFF4C5FEA), size: 18),
//           const SizedBox(width: 6),
//           Expanded(
//             child: Row(
//               children: [
//                 Flexible(
//                   child: Text(
//                     prefix,
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                     style: const TextStyle(
//                       color: MctLessonsScreen.ink,
//                       fontSize: 10,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 5),
//                 _FooterChip(icon: chipIcon, label: chipLabel),
//               ],
//             ),
//           ),
//           const SizedBox(width: 4),
//           const _PhoneBadge(),
//         ],
//       ),
//     );
//   }
// }
//
// class _FooterChip extends StatelessWidget {
//   const _FooterChip({required this.icon, required this.label});
//
//   final IconData icon;
//   final String label;
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(7),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.04),
//             blurRadius: 4,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(icon, size: 12, color: MctLessonsScreen.ink),
//           const SizedBox(width: 4),
//           Text(
//             label,
//             maxLines: 1,
//             overflow: TextOverflow.ellipsis,
//             style: const TextStyle(
//               color: MctLessonsScreen.ink,
//               fontSize: 9.5,
//               fontWeight: FontWeight.w800,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// // ============================================================================
// // PHONE BADGE (footer end decoration — phone mockup + sparkles)
// // ============================================================================
//
// class _PhoneBadge extends StatelessWidget {
//   const _PhoneBadge();
//
//   static const Color _gold = Color(0xFFFFC94D);
//
//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       width: 54,
//       height: 44,
//       child: Stack(
//         clipBehavior: Clip.none,
//         alignment: Alignment.center,
//         children: [
//           Positioned(
//             left: 14,
//             top: 2,
//             child: Transform.rotate(
//               angle: -0.18,
//               child: Container(
//                 width: 26,
//                 height: 40,
//                 padding: const EdgeInsets.all(3),
//                 decoration: BoxDecoration(
//                   gradient: const LinearGradient(
//                     begin: Alignment.topLeft,
//                     end: Alignment.bottomRight,
//                     colors: [MctLessonsScreen.purple, MctLessonsScreen.violet],
//                   ),
//                   borderRadius: BorderRadius.circular(7),
//                   boxShadow: [
//                     BoxShadow(
//                       color: MctLessonsScreen.purple.withOpacity(0.4),
//                       blurRadius: 8,
//                       offset: const Offset(0, 3),
//                     ),
//                   ],
//                 ),
//                 child: Center(
//                   child: Container(
//                     width: 16,
//                     height: 16,
//                     decoration: BoxDecoration(
//                       color: Colors.white.withOpacity(0.18),
//                       shape: BoxShape.circle,
//                     ),
//                     child: const Icon(
//                       Icons.play_arrow_rounded,
//                       color: Colors.white,
//                       size: 12,
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//           const Positioned(
//             left: 0,
//             top: 15,
//             child: Icon(Icons.auto_awesome, size: 10, color: _gold),
//           ),
//           const Positioned(
//             right: 0,
//             top: 8,
//             child: Icon(Icons.auto_awesome, size: 15, color: _gold),
//           ),
//         ],
//       ),
//     );
//   }
// }
import 'package:discipline_mind/common/ThemeService.dart';
import 'package:discipline_mind/common/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class MctLessonsScreen extends StatefulWidget {
  const MctLessonsScreen({super.key});

  @override
  State<MctLessonsScreen> createState() => _MctProtocolsScreenState();
}

class _MctProtocolsScreenState extends State<MctLessonsScreen> {
  @override
  void initState() {
    super.initState();
    // Use edge-to-edge mode for a modern look consistent with other screens
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  @override
  void dispose() {
    // Restore default system UI mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isDark = ThemeService().isDarkMode;

      return Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        appBar: AppBar(
          elevation: 0,
          leading: Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_back,
                  size: 20,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          title: Text(
            'MCT LESSONS',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          centerTitle: false,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.only(right: 110),
                        child: Text(
                          '5 Non-Negotiable Rules to trade with Clarity, Discipline & Consistency.',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade700,
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                  Positioned(
                    right: -20,
                    top: -30,
                    child: Image.asset(
                      'assets/mctp1.png',
                      width: 140,
                      height: 140,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => ClipOval(
                        child: Image.asset(
                          'assets/0_img.png',
                          width: 90,
                          height: 90,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.deepPurple.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.psychology,
                              size: 50,
                              color: Colors.deepPurple.shade400,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildDivider('THE 5 PROTOCOLS'),
              const SizedBox(height: 18),
              _buildProtocolCard(
                context: context,
                protocolNumber: 1,
                title: 'Process Over Everything',
                description: 'Follow a clear, defined process.\nAll setups come from SEBI-registered\nExpert Analysts.',
                subTitle: 'Create a Process. Follow it Consistently.',
                detailedDesc: 'Your process is your trading framework. It defines what to trade, when to trade, how much to trade, and when to stop—so your decisions don\'t depend on emotions.',
                bulletPoints: [
                  'WHY CREATE A PROCESS? ',
                  'A process turns trading into a system instead of a series of decisions.',
                  'BUILD YOUR PROCESS',
                  'Choose your segment — Stocks, Options, Futures, or any segment you trade.',
                'Choose your setup — Follow an Expert Analyst Setup or create your own tested setup.',
              'Define your rules — Entry, risk, position size, exit, and when to stop.',
               'Keep it consistent — Once defined, follow the same process instead of constantly changing strategies.',
                  'CONSISTENCY IS THE EDGE',
                  'Following one process repeatedly helps you build discipline, develop conviction, and understand your own trading behaviour.',
                  'The goal isn\'t to find the perfect process.'
             ' The goal is to create one, follow it consistently, and improve it with experience.'
                ],
                rememberText: 'Your process is your protection.',
                imagePath: 'assets/1_img.png',
                icon: Icons.explore_outlined,
                accentColor: const Color(0xFF1E9E5B),
                badgeBgColor: const Color(0xFFE8F8F0),
                watermark: Image.asset(
                  'assets/goals.png',
                  width: 78,
                  height: 78,
                  color: const Color(0xFF1E9E5B).withValues(alpha: 0.12),
                  colorBlendMode: BlendMode.srcIn,
                  fit: BoxFit.contain,
                ),
                isDark: isDark,
              ),
              const SizedBox(height: 14),
              _buildProtocolCard(
                context: context,
                protocolNumber: 2,
                title: 'Cut the Noise',
                description: 'Follow only one process.\nAvoid live market data, tips,\nand social media distractions.',
                subTitle: 'Once Your Process Is Defined, Follow It.',
                detailedDesc: 'Once you commit to a process, stay away from anything that can influence you to deviate from it. Constant tips, opinions, social media, or live market movements can trigger FOMO, fear, and impulsive decisions',
                bulletPoints: [
                  'CUT THE NOISE',
                  'Random trading tips and calls',
                  'Other people\'s setups and strategies',
                  'Social media and market opinions',
                  'Unnecessary live market information',
                  'Anything that creates FOMO, fear, or doubt',
                  'HOW ZENO HELPS',
                  'Zeno\'s Mind Control Guard helps create a buffer between you and live-market noise.',
                  'It helps you stay focused on the process you have already defined, instead of reacting to every market movement or external signal.',
                  'STAY WITH YOUR PROCESS',
                  'The goal is not to keep reacting to the market.',
                  'Stay away from the noise.',
                "Follow your process.",
              "Build consistency.",
              "Improve your MCT Score."
                ],
                rememberText: 'Noise builds doubt. Silence builds execution.\nProtect your focus.',
                imagePath: 'assets/2_img.png',
                icon: Icons.notifications_off_outlined,
                accentColor: const Color(0xFFE0522A),
                badgeBgColor: const Color(0xFFFDEAE3),
                watermark: SizedBox(
                  width: 86,
                  height: 52,
                  child: CustomPaint(
                    painter: _WaveformPainter(color: const Color(0xFFE0522A).withValues(alpha: 0.14)),
                  ),
                ),
                isDark: isDark,
              ),
              const SizedBox(height: 14),
              _buildProtocolCard(
                context: context,
                protocolNumber: 3,
                title: 'Trust the Process',
                description: 'Stick to the plan.\nStart in Believe Mode,\nobserve and build conviction.',
                subTitle: 'Observation Creates Conviction.',
                detailedDesc: 'Trust doesn\'t come from blindly believing in a strategy. It comes from observing it, understanding it, and experiencing it repeatedly.',
                bulletPoints: [
                  'START WITH OBSERVATION',
                  'Before expecting yourself to execute with complete confidence:',
                  'Observe how your process behaves.',
                'Understand why the setup works.',
              'Watch how it performs across different situations.',
              'Learn from both winning and losing trades.',
                  'THEN BUILD CONVICTION',
                  'Don\'t abandon your process because of one trade.',
                  'Observe → Understand → Build Conviction → Execute'
                  // 'Commit to your chosen rules for a fixed batch of trades to judge them fairly.',
                  // 'Accept small losses as a regular cost of business in trading.',
                  // 'Observe the process objectively rather than judging by a single outcome.',
                  // 'Conviction is earned by surviving standard market variations calmly.'
                ],
                rememberText: 'Consistency lives in statistics, not emotions.\nTrust the numbers.',
                imagePath: 'assets/3_img.png',
                icon: Icons.verified_user_outlined,
                accentColor: const Color(0xFF2F6FED),
                badgeBgColor: const Color(0xFFE8F1FD),
                watermark: Image.asset(
                  'assets/goals.png',
                  width: 78,
                  height: 78,
                  color: const Color(0xFF2F6FED).withValues(alpha: 0.12),
                  colorBlendMode: BlendMode.srcIn,
                  fit: BoxFit.contain,
                ),
                isDark: isDark,
              ),
              const SizedBox(height: 14),
              _buildProtocolCard(
                context: context,
                protocolNumber: 4,
                title: 'Step-up Gradually',
                description: 'Increase position sizing gradually\nas your MCT Score improves.\nGrow with discipline.',
                subTitle: 'Build Mind Control Before You Increase Exposure.',
                detailedDesc: 'Once you have defined your process, don\'t jump straight into larger positions. First, learn how your process behaves and how you behave while following it.',
                bulletPoints: [
                  'START WITH BELIEVE MODE',
                  'Use Believe Mode to observe and experience your process without the pressure of taking real trades.',
                  'You get to experience:',
                  'Winning trades',
                  'Losing trades',
                  'No-trade days',
                  'Different market conditions',
                  'Your own emotional reactions',
                  'This helps you build familiarity and conviction in your process.',
                  'MOVE TO APPLY MODE',
                  ' As you develop a stronger connection with your process, you move into Apply Mode and begin taking real trades.',
               ' Your experience from Believe Mode becomes your foundation.',
              ' You already know what your process looks like through different outcomes, helping your mind stay more controlled when real money is involved.',
                    'GROW WITH YOUR MCT SCORE',
                  'Your exposure should increase gradually as your Mind Control improves.'
                "As your MCT Score and consistency increase, Zeno can help you progress toward higher position sizes in a controlled manner."
                "Mind Control first.",
                "Exposure next.",
                  // 'Keep position sizes small and static during your learning phase.',
                  // 'Only increase size after maintaining a high MCT discipline score consistently.',
                  // 'If rules are broken, immediately step down to standard basic size.',
                  // 'Sustainable growth is a marathon of consistency, not a single sprint.'
                ],
                rememberText: 'Don\'t increase your risk just because you can.Increase it when your mind is ready. \nBelieve → Apply → Build Consistency → Grow Gradually',
                imagePath: 'assets/4_img.png',
                icon: Icons.stacked_line_chart,
                accentColor: const Color(0xFF7C5CFC),
                badgeBgColor: const Color(0xFFEFEAFE),
                watermark: SizedBox(
                  width: 76,
                  height: 60,
                  child: CustomPaint(
                    painter: _GrowthChartPainter(color: const Color(0xFF7C5CFC).withValues(alpha: 0.16)),
                  ),
                ),
                isDark: isDark,
              ),
              const SizedBox(height: 14),
              _buildProtocolCard(
                context: context,
                protocolNumber: 5,
                title: 'Be True',
                description: 'Use one broker app.\nBe honest with your inputs.\nTransparency builds transformation.',
                subTitle: 'One Broker. One Reality.',
                detailedDesc: 'True transformation begins with absolute transparency. Hiding losses or trading on multiple unofficial broker platforms keeps you stuck in destructive habits.',
                bulletPoints: [
                  'WHY BE TRUE?',
                  'Mind Control starts with knowing your real behaviour.',
                  'You cannot improve what you don\'t honestly acknowledge. Your wins, losses, mistakes, skipped trades, and impulsive decisions are all part of your trading reality.'
                  'Be honest with yourself first. Then Zeno can help you improve.',
                  'ONE BROKER. ONE REALITY.',
                  'Use one Broker App to apply Mind Control Trading.',
                  'Keeping your trading activity in one place gives Zeno a complete and consistent view of your behaviour, instead of fragmented activity across different platforms.',
                  'BE HONEST WITH ZENO',
                  "Enter your trading information truthfully.",
                  " Don\'t hide trades or mistakes.",
                  "Don't change inputs to make your behaviour look better.",
                  "Let Zeno see what actually happened."

                ],
                rememberText: 'The more truthful your inputs and trading activity are, the better Zeno can understand your behaviour and help you improve your MCT Score.',
                imagePath: 'assets/5_img.png',
                icon: Icons.diamond_outlined,
                accentColor: const Color(0xFFD79A1E),
                badgeBgColor: const Color(0xFFFDF3DA),
                watermark: Icon(
                  Icons.handshake_outlined,
                  size: 68,
                  color: const Color(0xFFD79A1E).withValues(alpha: 0.14),
                ),
                isDark: isDark,
              ),
              const SizedBox(height: 18),
              _buildFooterBanner(isDark),
              const SizedBox(height: 18),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.verified_user_outlined,
                            size: 14,
                            color: Color(0xFF7C3AED),
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              'These protocols are the foundation of Mind Control Trading.',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w500,
                                color: isDark ? AppColors.darkTextSecondary : const Color(0xFF6B7280),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Break the rule, break your edge.',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkTextSecondary : const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildDivider(String text) {
    const dividerColor = Color(0xFFDDD6FE);
    const dotColor = Color(0xFF6C2BD9);

    return Row(
      children: [
        const Expanded(
          child: Divider(color: dividerColor, thickness: 1),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                text,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: dotColor,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
        const Expanded(
          child: Divider(color: dividerColor, thickness: 1),
        ),
      ],
    );
  }

  Widget _buildProtocolCard({
    required BuildContext context,
    required int protocolNumber,
    required String title,
    required String description,
    required String subTitle,
    required String detailedDesc,
    required List<String> bulletPoints,
    required String rememberText,
    required String imagePath,
    required IconData icon,
    required Color accentColor,
    required Color badgeBgColor,
    required Widget watermark,
    required bool isDark,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => _showProtocolDetailsDialog(
        context: context,
        protocolNumber: protocolNumber,
        title: title,
        subTitle: subTitle,
        detailedDesc: detailedDesc,
        bulletPoints: bulletPoints,
        rememberText: rememberText,
        imagePath: imagePath,
        icon: icon,
        accentColor: accentColor,
        badgeBgColor: badgeBgColor,
        isDark: isDark,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? Colors.white10 : const Color(0xFFF0EFF6),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.035),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Left colored indicator bar (animated tracking indicator)
            Positioned(
              left: 0,
              top: 14,
              bottom: 14,
              child: Stack(
                children: [
                  // Gray track background
                  Container(
                    width: 4.5,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF0F0F0),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  // Animated progress line (One-by-one staggering)
                  FutureBuilder(
                    future: Future.delayed(Duration(milliseconds: (protocolNumber - 1) * 800)),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const SizedBox.shrink();
                      }
                      return TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 1000),
                        curve: Curves.easeInOut,
                        builder: (context, value, child) {
                          return FractionallySizedBox(
                            heightFactor: value,
                            alignment: Alignment.topCenter,
                            child: Container(
                              width: 4.5,
                              decoration: BoxDecoration(
                                color: accentColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
            // Right-side watermark illustration
            Positioned(
              right: 12,
              bottom: 8,
              child: watermark,
            ),
            // Card Content
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ClipOval(
                    child: Image.asset(
                      imagePath,
                      width: 62,
                      height: 62,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 62,
                        height: 62,
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: accentColor, size: 30),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: badgeBgColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'PROTOCOL $protocolNumber',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: accentColor,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppColors.darkTextPrimary : const Color(0xFF1E1F2E),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isDark ? AppColors.darkTextSecondary : const Color(0xFF5A5E71),
                            height: 1.35,
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

  void _showProtocolDetailsDialog({
    required BuildContext context,
    required int protocolNumber,
    required String title,
    required String subTitle,
    required String detailedDesc,
    required List<String> bulletPoints,
    required String rememberText,
    required String imagePath,
    required IconData icon,
    required Color accentColor,
    required Color badgeBgColor,
    required bool isDark,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 350, maxHeight: 600),
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Dialog(
              insetPadding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // --- FIXED HEADER ---
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 44, 40, 16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              ClipOval(
                                child: Image.asset(
                                  imagePath,
                                  width: 62,
                                  height: 62,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    width: 62,
                                    height: 62,
                                    decoration: BoxDecoration(
                                      color: accentColor.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(icon, color: accentColor, size: 30),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                                      decoration: BoxDecoration(
                                        color: badgeBgColor,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'PROTOCOL $protocolNumber',
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w800,
                                          color: accentColor,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      title,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      subTitle,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: accentColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                        ),
                        // --- SCROLLABLE CONTENT ---
                        Flexible(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  detailedDesc,
                                  style: TextStyle(
                                    fontSize: 12,
                                    height: 1.5,
                                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  'WHAT THIS MEANS',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    color: accentColor,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Divider(color: accentColor.withValues(alpha: 0.2), thickness: 1),
                                const SizedBox(height: 12),
                                Column(
                                  children: bulletPoints.map((point) {
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 10),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.only(top: 5),
                                            child: Icon(Icons.circle, size: 5, color: accentColor),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              point,
                                              style: TextStyle(
                                                fontSize: 11.5,
                                                height: 1.4,
                                                color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade800,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: accentColor.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: accentColor.withValues(alpha: 0.1)),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(Icons.track_changes, color: accentColor, size: 20),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Remember:',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w900,
                                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              rememberText,
                                              style: TextStyle(
                                                fontSize: 11,
                                                height: 1.4,
                                                fontWeight: FontWeight.w700,
                                                color: accentColor,
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
                        ),
                      ],
                    ),
                    // Fixed Close Button
                    Positioned(
                      top: 12,
                      right: 12,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.close, size: 20, color: isDark ? Colors.white70 : Colors.black54),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFooterBanner(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4EDFE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8DDFB), width: 1.2),
      ),
      child: Row(
        children: [
          Image.asset(
            'assets/mct_brain.png',
            width: 48,
            height: 48,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.psychology,
              size: 32,
              color: Color(0xFF8B5CF6),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Follow the Protocols.',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E1F2E),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Build Mind Control. Achieve Consistency.',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF7C3AED),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.auto_awesome, color: Color(0xFF8B5CF6), size: 16),
        ],
      ),
    );
  }
}

// ============================================================================
// WATERMARK PAINTERS (Matching Figma reference design)
// ============================================================================

/// Sound wave / frequency watermark for Protocol 2
class _WaveformPainter extends CustomPainter {
  final Color color;
  const _WaveformPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    // Main wave line
    final path1 = Path();
    path1.moveTo(0, h * 0.58);
    path1.lineTo(w * 0.12, h * 0.58);
    path1.lineTo(w * 0.22, h * 0.32);
    path1.lineTo(w * 0.32, h * 0.76);
    path1.lineTo(w * 0.44, h * 0.12);
    path1.lineTo(w * 0.56, h * 0.88);
    path1.lineTo(w * 0.68, h * 0.28);
    path1.lineTo(w * 0.78, h * 0.68);
    path1.lineTo(w * 0.88, h * 0.48);
    path1.lineTo(w, h * 0.48);
    canvas.drawPath(path1, paint);

    // Background softer wave
    final paint2 = Paint()
      ..color = color.withValues(alpha: (color.a * 0.55).clamp(0.0, 1.0))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    final path2 = Path();
    path2.moveTo(w * 0.08, h * 0.64);
    path2.lineTo(w * 0.20, h * 0.64);
    path2.lineTo(w * 0.30, h * 0.44);
    path2.lineTo(w * 0.40, h * 0.80);
    path2.lineTo(w * 0.52, h * 0.22);
    path2.lineTo(w * 0.64, h * 0.72);
    path2.lineTo(w * 0.76, h * 0.42);
    path2.lineTo(w * 0.88, h * 0.58);
    path2.lineTo(w, h * 0.58);
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Bar chart with upward growth trend arrow for Protocol 4
class _GrowthChartPainter extends CustomPainter {
  final Color color;
  const _GrowthChartPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;

    // 4 vertical rounded growth bars
    final barWidth = w * 0.12;
    final barSpacing = w * 0.07;
    final startX = w * 0.22;
    final heights = [h * 0.22, h * 0.40, h * 0.60, h * 0.84];

    for (int i = 0; i < 4; i++) {
      final x = startX + i * (barWidth + barSpacing);
      final barH = heights[i];
      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, h - barH, barWidth, barH),
        const Radius.circular(3),
      );
      canvas.drawRRect(rrect, fillPaint);
    }

    // Upward trend curve
    final arrowPath = Path();
    arrowPath.moveTo(w * 0.02, h * 0.86);
    arrowPath.quadraticBezierTo(w * 0.44, h * 0.70, w * 0.90, h * 0.18);
    canvas.drawPath(arrowPath, strokePaint);

    // Arrowhead at top right
    final headPath = Path();
    const tipX = 0.90;
    const tipY = 0.18;
    headPath.moveTo(w * tipX, h * tipY);
    headPath.lineTo(w * (tipX - 0.14), h * (tipY + 0.03));
    headPath.lineTo(w * (tipX - 0.03), h * (tipY + 0.14));
    headPath.close();
    canvas.drawPath(headPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
