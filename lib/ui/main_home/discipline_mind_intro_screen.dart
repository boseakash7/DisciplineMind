import 'package:discipline_mind/ui/main_home/DisciplineMindProfileScreen.dart';
import 'package:flutter/material.dart';
import 'package:discipline_mind/common/app_colors.dart';

class DisciplineMindIntroScreen extends StatefulWidget {
  const DisciplineMindIntroScreen({super.key});

  @override
  State<DisciplineMindIntroScreen> createState() => _DisciplineMindIntroScreenState();
}

class _DisciplineMindIntroScreenState extends State<DisciplineMindIntroScreen>
    with TickerProviderStateMixin {
  
  late final AnimationController _controller;
  late final List<Animation<double>> _animations;

  bool _isDark(BuildContext context) => Theme.of(context).brightness == Brightness.dark;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800), // Slower & smoother
    );

    _animations = List.generate(4, (index) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(index * 0.22, 1.0, curve: Curves.easeOutCubic),
        ),
      );
    });

    // Start animation after screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _isDark(context);
    final bg = isDark ? const Color(0xFF0D0F14) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.white70 : Colors.grey.shade700;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        foregroundColor: textColor,
        title: const Text('Mind Control Trading'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sparkle Icon
              FadeTransition(
                opacity: _animations[0],
                child: const Icon(Icons.auto_awesome, size: 42, color: AppColors.primary),
              ),
              const SizedBox(height: 20),

              // Welcome Text
              FadeTransition(
                opacity: _animations[0],
                child: Text(
                  "Hello Name,\nWelcome to Monkk - Mind Control Trading Community",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                    color: textColor,
                  ),
                ),
              ),

              const SizedBox(height: 50),

              // Animated Points
              _buildAnimatedPoint(
                1,
                "Let's get started with First Step of your Mind Control Trading Journey",
                _animations[1],
                subtitleColor,
              ),
              const SizedBox(height: 28),

              _buildAnimatedPoint(
                2,
                "Step 1 - Take a quick test and let the AI understand your current Mindset",
                _animations[2],
                subtitleColor,
              ),
              const SizedBox(height: 28),

              _buildAnimatedPoint(
                3,
                "This will help AI to figure out the Good Habits which you already possess to become Mind Control Trader and also Figure Out the Bad Habits which you need to work on",
                _animations[3],
                subtitleColor,
              ),

              const Spacer(),

              // Take a Test Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DisciplineMindProfileScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'TAKE A TEST',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedPoint(int number, String text, Animation<double> animation, Color subtitleColor) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.4),
          end: Offset.zero,
        ).animate(animation),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "$number. ",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: subtitleColor),
            ),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 15.5,
                  height: 1.55,
                  color: subtitleColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}