import 'package:discipline_mind/common/ThemeService.dart';
import 'package:discipline_mind/common/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class MctProtocolsScreen extends StatefulWidget {
  const MctProtocolsScreen({super.key});

  @override
  State<MctProtocolsScreen> createState() => _MctProtocolsScreenState();
}

class _MctProtocolsScreenState extends State<MctProtocolsScreen> {
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
            'MCT PROTOCOLS',
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
                detailedDesc: 'A clear process is your edge in the markets. Without a process, decisions are random. With a process, every decision becomes intentional and repeatable.',
                bulletPoints: [
                  'Define your trading process based on proven rules that suit your style and goals.',
                  'Be consistent in following it, trade after trade, without exceptions.',
                  'Your setup can be an expert\'s analysis setup (SEBI-registered) or your own tested setup.',
                  'The key is not the setup, the key is how consistently you execute your process.'
                ],
                rememberText: 'Your process is your protection.\nBuild it. Follow it. Trust it.',
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
                subTitle: 'Focus Entirely. Block All Distractions.',
                detailedDesc: 'External noise ruins your trading psychology. By cutting out live chat groups, random tips, and multiple charts, you preserve your mental capital for flawless execution.',
                bulletPoints: [
                  'Mute or leave group channels that broadcast random trading opinions during market hours.',
                  'Stick exclusively to your single source of process without second-guessing.',
                  'Avoid looking at continuous live PnL or flashing ticker data if it causes anxiety.',
                  'Discipline is built in silence, not in the chaos of social media hype.'
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
                subTitle: 'Stay Composed. Let the Setup Work.',
                detailedDesc: 'Every verified setup needs room to breathe. Switching setups after a few minor losses destroys long-term probability. Stay in Believe Mode and accumulate data.',
                bulletPoints: [
                  'Commit to your chosen rules for a fixed batch of trades to judge them fairly.',
                  'Accept small losses as a regular cost of business in trading.',
                  'Observe the process objectively rather than judging by a single outcome.',
                  'Conviction is earned by surviving standard market variations calmly.'
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
                subTitle: 'Scale Intelligently. Earn Your Leverage.',
                detailedDesc: 'Scaling up your capital before mastering discipline is financial suicide. Let your discipline score prove that your mind can handle higher size before risking more.',
                bulletPoints: [
                  'Keep position sizes small and static during your learning phase.',
                  'Only increase size after maintaining a high MCT discipline score consistently.',
                  'If rules are broken, immediately step down to standard basic size.',
                  'Sustainable growth is a marathon of consistency, not a single sprint.'
                ],
                rememberText: 'Earn the right to trade bigger through discipline.\nScale with stats.',
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
                subTitle: 'Complete Honesty. No Hidden Trades.',
                detailedDesc: 'True transformation begins with absolute transparency. Hiding losses or trading on multiple unofficial broker platforms keeps you stuck in destructive habits.',
                bulletPoints: [
                  'Consolidate your tracking onto a single, main authorized broker account.',
                  'Log every single trade, entry, exit, and mistake accurately in your journal.',
                  'Never hide revenge trades or rule breaks; acknowledge them to fix them.',
                  'Radical self-honesty is the fast track to professional trading maturity.'
                ],
                rememberText: 'You can lie to others, but never to your equity curve.\nBe transparent.',
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
            constraints: const BoxConstraints(maxWidth: 340, maxHeight: 550),
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Dialog(
              insetPadding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  children: [
                    // Scrollable content
                    SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 44, 20, 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(

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
                          const SizedBox(height: 20),
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
