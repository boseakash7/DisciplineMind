import 'package:discipline_mind/ui/main_home/DisciplineMindTestScreen.dart';
import 'package:flutter/material.dart';
import 'package:discipline_mind/common/app_colors.dart';

class ProfileFormField {
  final String id;
  final String question;
  final bool isNumberInput;
  final List<String> options;

  const ProfileFormField({
    required this.id,
    required this.question,
    this.isNumberInput = false,
    this.options = const [],
  });
}

final List<ProfileFormField> disciplineMindProfileFields = [
  ProfileFormField(id: 'age', question: 'Your Age', isNumberInput: true),
  ProfileFormField(
    id: 'experience',
    question: 'Total Trading Experience in Indian Stock Market ?',
    options: ['Never Traded', '0 to 1 year', '1 to 2 years', 'More than 2 years'],
  ),
  ProfileFormField(
    id: 'active_trading',
    question: 'Which of these have you done Actively ?',
    options: [
      'Traded in Stocks Occasionally',
      'Intraday Options Trading',
      'Regular Swing trading'
    ],
  ),
];

class DisciplineMindProfileScreen extends StatefulWidget {
  const DisciplineMindProfileScreen({super.key});

  @override
  State<DisciplineMindProfileScreen> createState() => _DisciplineMindProfileScreenState();
}

class _DisciplineMindProfileScreenState extends State<DisciplineMindProfileScreen>
    with TickerProviderStateMixin {
  final Map<String, String> _answers = {};
  final TextEditingController _ageController = TextEditingController();
  late final AnimationController _fadeController;
  late final List<Animation<double>> _animations;

  bool _isDark(BuildContext context) => Theme.of(context).brightness == Brightness.dark;

  bool get _isComplete {
    for (final field in disciplineMindProfileFields) {
      final value = _answers[field.id];
      if (value == null || value.trim().isEmpty) return false;
    }
    return true;
  }

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _animations = List.generate(4, (index) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _fadeController,
          curve: Interval(index * 0.2, 1.0, curve: Curves.easeOut),
        ),
      );
    });

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _isDark(context);
    final bg = isDark ? const Color(0xFF0D0F14) : Colors.white;
    final titleColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.white70 : Colors.grey.shade700;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        foregroundColor: titleColor,
        title: const Text('Mind Control Trading'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                children: [
                  // Welcome Header
                  // FadeTransition(
                  //   opacity: _animations[0],
                  //   child: const Row(
                  //     children: [
                  //       Icon(Icons.auto_awesome, size: 22, color: AppColors.primary),
                  //       SizedBox(width: 12),
                  //       Text(
                  //         'Hello Name,\nWelcome to Monkk - Mind Control Trading Community',
                  //         style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  //       ),
                  //     ],
                  //   ),
                  // ),
                  // const SizedBox(height: 32),

                  // // Animated Points
                  // _buildAnimatedPoint(1, "Let's get started with First Step of your Mind Control Trading Journey", _animations[1], subtitleColor),
                  // const SizedBox(height: 20),
                  // _buildAnimatedPoint(2, "Step 1 - Take a quick test and let the AI understand your current Mindset", _animations[2], subtitleColor),
                  // const SizedBox(height: 20),
                  // _buildAnimatedPoint(
                  //   3,
                  //   "This will help AI to figure out the Good Habits which you already possess to become Mind Control Trader and also Figure Out the Bad Habits which you need to work on",
                  //   _animations[3],
                  //   subtitleColor,
                  // ),

                  // const SizedBox(height: 40),

                  for (var i = 0; i < disciplineMindProfileFields.length; i++)
                    _buildFieldBlock(
                      context,
                      i + 1,
                      disciplineMindProfileFields[i],
                      titleColor,
                      subtitleColor,
                    ),
                ],
              ),
            ),

            // Take a Test Button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isComplete
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const DisciplineMindTestScreen()),
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: isDark ? Colors.white24 : Colors.grey.shade300,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text(
                    'TAKE A TEST',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedPoint(int number, String text, Animation<double> animation, Color subtitleColor) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
        ).animate(animation),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("$number. ", style: TextStyle(fontSize: 15, color: subtitleColor)),
            Expanded(
              child: Text(
                text,
                style: TextStyle(fontSize: 14.5, height: 1.5, color: subtitleColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ... _buildFieldBlock remains same as previous version
  Widget _buildFieldBlock(
    BuildContext context,
    int number,
    ProfileFormField field,
    Color titleColor,
    Color subtitleColor,
  ) {
    final isDark = _isDark(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$number. ${field.question}',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: titleColor),
          ),
          const SizedBox(height: 12),
          if (field.isNumberInput)
            SizedBox(
              width: 160,
              child: TextField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: titleColor),
                decoration: InputDecoration(
                  hintText: 'years',
                  hintStyle: TextStyle(color: subtitleColor),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E222A) : AppColors.backgroundGray,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                onChanged: (value) => setState(() => _answers[field.id] = value),
              ),
            )
          else
            Column(
              children: field.options.map((option) {
                final selected = _answers[field.id] == option;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () => setState(() => _answers[field.id] = option),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary.withOpacity(isDark ? 0.25 : 0.1)
                            : (isDark ? const Color(0xFF1E222A) : AppColors.backgroundGray),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: selected ? AppColors.primary : Colors.transparent),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            selected ? Icons.radio_button_checked : Icons.radio_button_off,
                            color: selected ? AppColors.primary : subtitleColor,
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: Text(option, style: TextStyle(fontSize: 14, color: titleColor))),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}