import 'package:discipline_mind/ui/onboarding/trading_profile_flow.dart'
    show MctVideoPlayerPage;
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

// ============================================================================
// MCT LESSONS SCREEN
// ============================================================================
// Standalone entry point reached from the "More" tab. Mirrors the palette
// used across the onboarding trading-profile flow for visual consistency.

class MctLessonsScreen extends StatefulWidget {
  const MctLessonsScreen({super.key, required this.userId});

  final String userId;

  static const Color purple = Color(0xFF4A22F4);
  static const Color violet = Color(0xFF983BF4);
  static const Color ink = Color(0xFF10122D);

  static const String _dummyVideo = 'assets/dummy_mct_video.mp4';
  static const String _introTitle = 'Your Introduction to Zeno AI';

  static const List<_Protocol> _protocols = [
    _Protocol(
      number: 1,
      title: 'Process Over Everything',
      color: Color(0xFF1E9E5B),
      bgColor: Color(0xFFE3F6EA),
      videoCount: 5,
      duration: '4 mins',
    ),
    _Protocol(
      number: 2,
      title: 'Cut the Noise',
      color: Color(0xFFE0522A),
      bgColor: Color(0xFFFDEAE3),
      videoCount: 5,
      duration: '5 mins',
    ),
    _Protocol(
      number: 3,
      title: 'Trust the Process',
      color: Color(0xFF2F6FED),
      bgColor: Color(0xFFE6EFFE),
      videoCount: 5,
      duration: '7 mins',
    ),
    _Protocol(
      number: 4,
      title: 'Step-up Gradually',
      color: Color(0xFF7C5CFC),
      bgColor: Color(0xFFEFEAFE),
      videoCount: 5,
      duration: '6 mins',
    ),
    _Protocol(
      number: 5,
      title: 'Be True',
      color: Color(0xFFD79A1E),
      bgColor: Color(0xFFFDF3DA),
      videoCount: 5,
      duration: '5 mins',
    ),
  ];

  static int get _totalLessons => _protocols.length + 1;

  @override
  State<MctLessonsScreen> createState() => _MctLessonsScreenState();
}

class _MctLessonsScreenState extends State<MctLessonsScreen> {
  late final String _storageKey =
      'mct_lessons_completed_${widget.userId}';
  late Set<String> _completedLessons = _loadCompletedLessons();

  Set<String> _loadCompletedLessons() {
    final List<dynamic>? stored = GetStorage().read<List<dynamic>>(
      _storageKey,
    );
    return stored?.map((e) => e.toString()).toSet() ?? <String>{};
  }

  void _markCompleted(String lessonId) {
    if (_completedLessons.contains(lessonId)) {
      return;
    }

    setState(() => _completedLessons.add(lessonId));
    GetStorage().write(_storageKey, _completedLessons.toList());
  }

  Future<void> _openVideo(String title, String lessonId) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MctVideoPlayerPage(
          title: title,
          videoPath: MctLessonsScreen._dummyVideo,
        ),
      ),
    );

    _markCompleted(lessonId);
  }

  List<Widget> _buildAppDemoContent(List<_Protocol> protocols) {
    return [
      const _SectionDivider(label: 'PROTOCOLS OF MIND CONTROL TRADING'),
      const SizedBox(height: 14),
      for (final protocol in protocols) ...[
        _ProtocolCard(
          protocol: protocol,
          onTap: () =>
              _openVideo(protocol.title, 'protocol_${protocol.number}'),
        ),
        const SizedBox(height: 12),
      ],
    ];
  }

  List<Widget> _buildExplanationContent() {
    return [
      const _SectionDivider(label: 'INTRODUCTION'),
      const SizedBox(height: 14),
      _ExplanationVideoCard(
        imagePath: 'assets/0_img.png',
        title: MctLessonsScreen._introTitle,
        duration: '2 mins',
        onTap: () => _openVideo(MctLessonsScreen._introTitle, 'intro'),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 20, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: MctLessonsScreen.ink,
                    ),
                  ),
                  const Text(
                    'MCT LESSONS',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: MctLessonsScreen.ink,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 6, 24, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/mct_lession_header_img.png',
                    height: 90,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      'Please watch videos in sequence\n'
                      'for better Understanding of Mind\n'
                      'Control Trading Process',
                      style: TextStyle(
                        color: Color(0xFF6C6C7C),
                        fontSize: 12.5,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _ProgressCard(
                completed: _completedLessons.length,
                total: MctLessonsScreen._totalLessons,
              ),
            ),

            const SizedBox(height: 18),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                children: [
                  ..._buildExplanationContent(),
                  const SizedBox(height: 22),
                  ..._buildAppDemoContent(MctLessonsScreen._protocols),
                  const SizedBox(height: 6),
                  const _FooterBar(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// PROGRESS CARD
// ============================================================================

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.completed, required this.total});

  final int completed;
  final int total;

  @override
  Widget build(BuildContext context) {
    final double fraction = total == 0 ? 0 : completed / total;
    final int percent = (fraction * 100).round();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEDEBF7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '$percent%',
                style: const TextStyle(
                  color: MctLessonsScreen.ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'Completed',
                style: TextStyle(
                  color: Color(0xFF8A8A99),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: fraction,
                    minHeight: 7,
                    backgroundColor: const Color(0xFFE9E7F3),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      MctLessonsScreen.purple,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            '$completed of $total lessons completed',
            style: const TextStyle(
              color: MctLessonsScreen.purple,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// SECTION DIVIDER (dashed line — •  LABEL  • — dashed line)
// ============================================================================

class _DashedLine extends StatelessWidget {
  const _DashedLine();

  static const double _dashWidth = 4;
  static const double _dashGap = 3;
  static const Color _color = Color(0xFFDAD7EC);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final dashCount =
            (constraints.maxWidth / (_dashWidth + _dashGap)).floor();
        return Row(
          children: List.generate(dashCount, (_) {
            return Padding(
              padding: const EdgeInsets.only(right: _dashGap),
              child: Container(width: _dashWidth, height: 1, color: _color),
            );
          }),
        );
      },
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: _DashedLine()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Bullet(),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: MctLessonsScreen.violet,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(width: 6),
              _Bullet(),
            ],
          ),
        ),
        const Expanded(child: _DashedLine()),
      ],
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4,
      height: 4,
      decoration: const BoxDecoration(
        color: MctLessonsScreen.violet,
        shape: BoxShape.circle,
      ),
    );
  }
}

// ============================================================================
// PROTOCOL CARD (APP DEMO mode)
// ============================================================================

class _Protocol {
  const _Protocol({
    required this.number,
    required this.title,
    required this.color,
    required this.bgColor,
    required this.videoCount,
    required this.duration,
  });

  final int number;
  final String title;
  final Color color;
  final Color bgColor;
  final int videoCount;
  final String duration;
}

class _ProtocolCard extends StatelessWidget {
  const _ProtocolCard({required this.protocol, required this.onTap});

  final _Protocol protocol;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEDEBF7)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipOval(
              child: Image.asset(
                'assets/${protocol.number}_img.png',
                width: 46,
                height: 46,
                fit: BoxFit.cover,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PROTOCOL NO. ${protocol.number}',
                    style: TextStyle(
                      color: protocol.color,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),

                  const SizedBox(height: 2),

                  Text(
                    protocol.title,
                    style: const TextStyle(
                      color: MctLessonsScreen.ink,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Row(
                    children: [
                      _Tag(
                        icon: Icons.smartphone_outlined,
                        label: 'App Demo (1-5)',
                        color: protocol.color,
                        bgColor: protocol.bgColor,
                      ),
                      const SizedBox(width: 8),
                      _Tag(
                        icon: Icons.videocam_outlined,
                        label: '${protocol.videoCount} videos',
                        color: const Color(0xFF6C6C7C),
                        bgColor: const Color(0xFFF1F1F5),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [MctLessonsScreen.purple, MctLessonsScreen.violet],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({
    required this.icon,
    required this.label,
    required this.color,
    required this.bgColor,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color bgColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// EXPLANATION VIDEO CARD (EXPLANATION mode)
// ============================================================================

class _ExplanationVideoCard extends StatelessWidget {
  const _ExplanationVideoCard({
    required this.imagePath,
    required this.title,
    required this.duration,
    required this.onTap,
  });

  final String imagePath;
  final String title;
  final String duration;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEDEBF7)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipOval(
              child: Image.asset(
                imagePath,
                width: 52,
                height: 52,
                fit: BoxFit.cover,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFEAFE),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.play_arrow_rounded,
                          size: 11,
                          color: MctLessonsScreen.purple,
                        ),
                        const SizedBox(width: 3),
                        const Text(
                          'VIDEO',
                          style: TextStyle(
                            color: MctLessonsScreen.purple,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    title,
                    style: const TextStyle(
                      color: MctLessonsScreen.ink,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Row(
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        size: 12,
                        color: Color(0xFF8A8A99),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        duration,
                        style: const TextStyle(
                          color: Color(0xFF8A8A99),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [MctLessonsScreen.purple, MctLessonsScreen.violet],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// FOOTER BAR
// ============================================================================

class _FooterBar extends StatelessWidget {
  const _FooterBar();

  @override
  Widget build(BuildContext context) {
    const prefix = 'Each lesson has one part:';
    const chipIcon = Icons.videocam_outlined;
    final chipLabel = '${MctLessonsScreen._totalLessons} videos total';

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEFEAFE),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFE3DFF5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.info, color: Color(0xFF4C5FEA), size: 18),
          const SizedBox(width: 6),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    prefix,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: MctLessonsScreen.ink,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                _FooterChip(icon: chipIcon, label: chipLabel),
              ],
            ),
          ),
          const SizedBox(width: 4),
          const _PhoneBadge(),
        ],
      ),
    );
  }
}

class _FooterChip extends StatelessWidget {
  const _FooterChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(7),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: MctLessonsScreen.ink),
          const SizedBox(width: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: MctLessonsScreen.ink,
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// PHONE BADGE (footer end decoration — phone mockup + sparkles)
// ============================================================================

class _PhoneBadge extends StatelessWidget {
  const _PhoneBadge();

  static const Color _gold = Color(0xFFFFC94D);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 54,
      height: 44,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 14,
            top: 2,
            child: Transform.rotate(
              angle: -0.18,
              child: Container(
                width: 26,
                height: 40,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [MctLessonsScreen.purple, MctLessonsScreen.violet],
                  ),
                  borderRadius: BorderRadius.circular(7),
                  boxShadow: [
                    BoxShadow(
                      color: MctLessonsScreen.purple.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const Positioned(
            left: 0,
            top: 15,
            child: Icon(Icons.auto_awesome, size: 10, color: _gold),
          ),
          const Positioned(
            right: 0,
            top: 8,
            child: Icon(Icons.auto_awesome, size: 15, color: _gold),
          ),
        ],
      ),
    );
  }
}
