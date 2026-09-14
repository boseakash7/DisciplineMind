import 'package:discipline_mind/ui/main_home/dmt_score_screen.dart';
import 'package:flutter/material.dart';
import 'package:discipline_mind/common/app_colors.dart';

class DisciplineMindTestScreen extends StatefulWidget {
  const DisciplineMindTestScreen({super.key});

  @override
  State<DisciplineMindTestScreen> createState() => _DisciplineMindTestScreenState();
}

class _DisciplineMindTestScreenState extends State<DisciplineMindTestScreen> {
  int _currentIndex = 0;
  final List<String?> _answers = List.filled(15, null);

  final List<Map<String, dynamic>> _questions = [
    {"category": "General", "question": "What did u Trade in your Journey of 0-1 years ?", "options": ["Stocks", "Crypto", "Others"]},
    {"category": "Psychology", "question": "When a trade starts going against you, what do you usually do?", "options": ["Cut loss immediately", "Hold and hope", "Add more position", "Panic and close"]},
    {"category": "Discipline", "question": "Do you follow your trading plan strictly?", "options": ["Always", "Most of the time", "Sometimes", "Rarely"]},
    {"category": "Risk", "question": "What is your usual risk per trade?", "options": ["0.5-1%", "1-2%", "2-3%", "More than 3%"]},
    {"category": "Emotion", "question": "How do you feel after a series of losing trades?", "options": ["Take a break", "Continue trading", "Revenge trade", "Stop trading completely"]},
    {"category": "Patience", "question": "How patient are you while waiting for your setup?", "options": ["Very Patient", "Patient", "Impatient", "Very Impatient"]},
    {"category": "Consistency", "question": "How many days per week do you trade?", "options": ["5 days", "4 days", "2-3 days", "Irregular"]},
    {"category": "Psychology", "question": "Do you journal your trades regularly?", "options": ["Yes, daily", "Yes, sometimes", "No, rarely", "Never"]},
    {"category": "Commitment", "question": "How important is trading for your financial goals?", "options": ["Very Important", "Important", "Moderate", "Just for fun"]},
    {"category": "General", "question": "What is your biggest weakness in trading?", "options": ["Fear of missing out", "Overtrading", "Revenge trading", "Lack of discipline"]},
    {"category": "Patience", "question": "How long can you wait for a high probability setup?", "options": ["Days", "Hours", "Minutes", "I force trades"]},
    {"category": "Consistency", "question": "Do you review your weekly performance?", "options": ["Yes", "Sometimes", "Rarely", "Never"]},
    {"category": "Risk", "question": "Do you use stop loss on every trade?", "options": ["Always", "Mostly", "Sometimes", "Never"]},
    {"category": "Emotion", "question": "How do you handle big winning trades?", "options": ["Book profit as per plan", "Hold for more", "Get greedy", "Exit early due to fear"]},
    {"category": "Discipline", "question": "Are you able to sit out of the market when no setup is there?", "options": ["Yes, easily", "Sometimes", "Very difficult", "Cannot sit out"]},
  ];

  bool get _hasAnswer => _answers[_currentIndex] != null;

  void _selectAnswer(String answer) {
    setState(() => _answers[_currentIndex] = answer);
  }

  void _next() {
    if (!_hasAnswer) return;
    if (_currentIndex < 14) {
      setState(() => _currentIndex++);
    } else {
      _finishTest();
    }
  }

  void _previous() {
    if (_currentIndex > 0) setState(() => _currentIndex--);
  }

  void _finishTest() {
    // Dummy scoring (you can improve this later)
    final totalScore = 240 + (_answers.where((e) => e != null).length * 4);

    showDmtScorePopup(
      context,
      scoreDate: "July 06, 2026",
      instructionsScore: "82",
      commitmentScore: "75",
      acceptanceScore: "70",
      patienceScore: "68",
      consistencyScore: "79",
      dmtTotalScore: "$totalScore",
      dmtMaxScore: "300",
      animateReveal: true,
    ).then((_) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final q = _questions[_currentIndex];

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D0F14) : Colors.white,
      appBar: AppBar(
        title: const Text('STEP 1 - MINDSET ASSESSMENT TEST'),
        backgroundColor: isDark ? const Color(0xFF0D0F14) : Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Progress
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (_currentIndex + 1) / 15,
                      minHeight: 8,
                      backgroundColor: isDark ? Colors.white12 : Colors.grey.shade200,
                      valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text('${_currentIndex + 1}/15', style: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade700)),
              ],
            ),
          ),

          // Category
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                q['category'],
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Question
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              q['question'],
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                height: 1.4,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Options
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: (q['options'] as List).length,
              itemBuilder: (context, i) {
                final option = q['options'][i];
                final selected = _answers[_currentIndex] == option;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () => _selectAnswer(option),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary.withOpacity(isDark ? 0.25 : 0.12)
                            : (isDark ? const Color(0xFF1E222A) : Colors.grey.shade100),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: selected ? AppColors.primary : Colors.transparent, width: 1.5),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            selected ? Icons.check_circle : Icons.circle_outlined,
                            color: selected ? AppColors.primary : Colors.grey,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              option,
                              style: TextStyle(
                                fontSize: 15.5,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Navigation
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                if (_currentIndex > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _previous,
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                      child: const Text('PREV'),
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _hasAnswer ? _next : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      _currentIndex == 14 ? 'FINISH' : 'NEXT',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}