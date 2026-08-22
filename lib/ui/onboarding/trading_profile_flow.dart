import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:video_player/video_player.dart';

// ============================================================================
// TRADING PROFILE FLOW
// ============================================================================

class TradingProfileFlow extends StatefulWidget {
  const TradingProfileFlow({
    super.key,
    required this.userId,
    required this.onComplete,
  });

  final String userId;
  final VoidCallback onComplete;

  static bool isComplete(String id) {
    return GetStorage().read('trading_profile_complete_$id') == true;
  }

  @override
  State<TradingProfileFlow> createState() => _TradingProfileFlowState();
}

class _TradingProfileFlowState extends State<TradingProfileFlow> {
  static const Color purple = Color(0xFF4A22F4);
  static const Color violet = Color(0xFF983BF4);
  static const Color ink = Color(0xFF10122D);

  static const Map<String, _Question> _byKey = {
    'experience': _Question(
      'experience',
      'Total Trading Experience in\nIndian Stock Market ?',
      ['Never Traded', '6 Months - 1 Year', '1 - 2 Years', '2 Years & Above'],
    ),
    'intraday': _Question('intraday', 'Have you ever done\nIntraday Trading?', [
      'Never',
      'Yes, for at least 6 months',
      'Yes, for more than 6 months',
    ]),
    'reason': _Question(
      'reason',
      'Why do you want to\nStart Intraday Trading ?',
      [
        'Generate Passive Income',
        'Generate Main Income',
        'To Learn Intraday Trading\nfirst and then apply',
      ],
      descriptions: [
        '(Not dependent on this income\nfor basic needs)',
        '(Dependent on this income\nfor daily needs)',
        null,
      ],
    ),
    'products': _Question('products', 'What have you traded\nin Intraday?', [
      'Options',
      'Futures',
      'Stocks',
    ], multiple: true),
    'situation':
        _Question('situation', 'What best describes your\ncurrent situation?', [
          'Actively trading but struggling with losses',
          'I quit Intraday Trading due to losses',
          'I quit Intraday Trading due to huge losses',
        ]),
    'source': _Question('source', 'Where did you hear\nabout Zeno AI ?', [
      'Social Media',
      'Recommended by a Fin-Influencer',
      'Friend / Family',
    ]),
  };

  String _currentKey = 'experience';

  final List<String> _history = [];
  final Map<String, dynamic> _answers = {};

  _Question get _question => _byKey[_currentKey]!;

  bool get _first => _currentKey == 'experience';

  String? _nextKey(String current) {
    switch (current) {
      case 'experience':
        return _answers['experience'] == 'Never Traded' ? 'reason' : 'intraday';

      case 'intraday':
        return _answers['intraday'] == 'Never' ? 'reason' : 'products';

      case 'reason':
        return 'source';

      case 'products':
        return 'situation';

      case 'situation':
        return 'source';

      case 'source':
        return null;

      default:
        return null;
    }
  }

  int get _totalSteps {
    if (_answers['experience'] == 'Never Traded') {
      return 3;
    }

    final String? intraday = _answers['intraday'] as String?;

    if (intraday == 'Never') {
      return 4;
    }

    if (intraday != null) {
      return 5;
    }

    return 5;
  }

  int get _stepNumber => _history.length + 1;

  /// Which of the two branching flows the user is on, based on their answer
  /// to the first question. Null until that question is answered.
  ///
  /// Flow A: "Never Traded" -> reason -> source.
  /// Flow B: any other experience level -> intraday -> (reason | products) -> source.
  String? get _flowLabel {
    final String? experience = _answers['experience'] as String?;
    if (experience == null) return null;
    return experience == 'Never Traded' ? 'Flow A' : 'Flow B';
  }

  void _select(_Question question, String option) {
    setState(() {
      if (question.multiple) {
        final Set<String> selected = Set<String>.from(
          _answers[question.key] as Set<String>? ?? <String>{},
        );

        if (selected.contains(option)) {
          selected.remove(option);
        } else {
          selected.add(option);
        }

        _answers[question.key] = selected;
      } else {
        _answers[question.key] = option;
      }
    });
  }

  // ==========================================================================
  // NAVIGATION
  // ==========================================================================

  void _goNext() {
    final String? next = _nextKey(_currentKey);

    if (next == null) {
      GetStorage().write('trading_profile_complete_${widget.userId}', true);

      // Pass the onComplete callback forward so it can eventually be used
      // by the "GO TO HOME" button on MctLessonsPage.
      Get.off(() => TradingProfileWelcomePage(onComplete: widget.onComplete));

      return;
    }

    setState(() {
      _history.add(_currentKey);
      _currentKey = next;
    });
  }

  void _next() {
    final dynamic answer = _answers[_question.key];

    if (answer == null || (answer is Set && answer.isEmpty)) {
      Get.snackbar(
        'Select an answer',
        'Please choose an option to continue.',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
      );
      return;
    }

    _goNext();
  }

  void _previous() {
    if (_history.isEmpty) {
      return;
    }

    setState(() {
      _currentKey = _history.removeLast();
    });
  }

  @override
  Widget build(BuildContext context) {
    final _Question question = _question;
    final bool first = _first;
    final bool isLast = _nextKey(_currentKey) == null;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 38),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (first) ...[
                  const _ProfileHero(),
                  const SizedBox(height: 16),
                ] else ...[
                  _Progress(
                    step: _stepNumber,
                    total: _totalSteps,
                    flowLabel: _flowLabel,
                  ),
                  const SizedBox(height: 28),
                ],

                if (!first)
                  Text(
                    question.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: ink,
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                    ),
                  ),

                if (!first) const SizedBox(height: 8),

                if (!first)
                  Text(
                    question.multiple
                        ? '(Select all that apply)'
                        : '(Select any one)',
                    style: const TextStyle(
                      color: Color(0xFF55566D),
                      fontSize: 13,
                    ),
                  ),

                if (first)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      question.title,
                      style: const TextStyle(
                        color: ink,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                  ),

                if (first)
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '(Select any one)',
                      style: TextStyle(
                        color: violet,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                SizedBox(height: first ? 10 : 28),

                ...question.options.map(
                  (option) => _OptionCard(
                    question: question,
                    option: option,
                    selected: question.multiple
                        ? (_answers[question.key] as Set<String>? ?? {})
                              .contains(option)
                        : _answers[question.key] == option,
                    onTap: () => _select(question, option),
                  ),
                ),

                const SizedBox(height: 30),

                Row(
                  children: [
                    if (!first)
                      Expanded(
                        child: _OutlineButton(
                          label: 'PREVIOUS',
                          onTap: _previous,
                        ),
                      ),

                    if (!first) const SizedBox(width: 12),

                    Expanded(
                      child: _PurpleButton(
                        label: isLast && !first ? 'FINISH' : 'NEXT',
                        onTap: _next,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 26),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// PROFILE HERO
// ============================================================================

class _ProfileHero extends StatelessWidget {
  const _ProfileHero();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 25),

        Image.asset(
          'assets/one__.png',
          width: 180,
          height: 130,
          fit: BoxFit.contain,
        ),

        const SizedBox(height: 15),

        const Text(
          'Provide the following\n'
          'information to\n'
          'create your Trading Profile.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _TradingProfileFlowState.ink,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            height: 1.1,
          ),
        ),

        const SizedBox(height: 10),

        const Text(
          'This will help AI to -',
          style: TextStyle(color: Color(0xFF575871), fontSize: 12),
        ),

        const SizedBox(height: 11),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/two__.png',
              width: 32,
              height: 32,
              fit: BoxFit.contain,
            ),

            const SizedBox(width: 6),

            const Text(
              'Personalize you\nExperience',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
            ),

            const SizedBox(width: 22),

            Image.asset(
              'assets/three__.png',
              width: 32,
              height: 32,
              fit: BoxFit.contain,
            ),

            const SizedBox(width: 6),

            const Text(
              'Guide you\nBetter',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
            ),
          ],
        ),

        const SizedBox(height: 16),

        const Divider(color: Color(0xFFE8E7F0)),
      ],
    );
  }
}

// ============================================================================
// PROGRESS
// ============================================================================

class _Progress extends StatelessWidget {
  const _Progress({required this.step, required this.total, this.flowLabel});

  final int step;
  final int total;
  final String? flowLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 21),

        if (flowLabel != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFEAE6FF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              flowLabel!,
              style: const TextStyle(
                color: _TradingProfileFlowState.violet,
                fontWeight: FontWeight.w800,
                fontSize: 11,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],

        Text(
          'Step $step of $total',
          style: const TextStyle(
            color: _TradingProfileFlowState.purple,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),

        const SizedBox(height: 10),

        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: total == 0 ? 0 : step / total,
            minHeight: 5,
            color: _TradingProfileFlowState.purple,
            backgroundColor: const Color(0xFFE7E7F0),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// OPTION CARD
// ============================================================================

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.question,
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _Question question;
  final String option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final int index = question.options.indexOf(option);

    final String? description =
        question.descriptions != null &&
            index >= 0 &&
            index < question.descriptions!.length
        ? question.descriptions![index]
        : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected
                    ? _TradingProfileFlowState.purple
                    : const Color(0xFFE9E8F0),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected
                          ? _TradingProfileFlowState.purple
                          : const Color(0xFF9C9EB5),
                      width: 1.5,
                    ),
                    color: selected
                        ? _TradingProfileFlowState.purple
                        : Colors.white,
                  ),
                  child: selected
                      ? const Icon(Icons.check, size: 15, color: Colors.white)
                      : null,
                ),

                const SizedBox(width: 20),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        option,
                        style: const TextStyle(
                          color: _TradingProfileFlowState.ink,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          height: 1.25,
                        ),
                      ),

                      if (description != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            description,
                            style: const TextStyle(
                              color: Color(0xFF5D6079),
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// PURPLE BUTTON
// ============================================================================

class _PurpleButton extends StatelessWidget {
  const _PurpleButton({
    required this.label,
    required this.onTap,
    this.compact = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: compact ? 40 : 46,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              _TradingProfileFlowState.purple,
              _TradingProfileFlowState.violet,
            ],
          ),
          borderRadius: BorderRadius.circular(5),
          boxShadow: const [
            BoxShadow(
              color: Color(0x444A22F4),
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: TextButton(
          onPressed: onTap,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: compact ? 11 : 14,
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// OUTLINE BUTTON
// ============================================================================

class _OutlineButton extends StatelessWidget {
  const _OutlineButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
          side: const BorderSide(color: Color(0xFFE5E4ED)),
        ),
        child: const Text(
          'PREVIOUS',
          style: TextStyle(
            color: _TradingProfileFlowState.purple,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// QUESTION MODEL
// ============================================================================

class _Question {
  const _Question(
    this.key,
    this.title,
    this.options, {
    this.descriptions,
    this.multiple = false,
  });

  final String key;
  final String title;
  final List<String> options;
  final List<String?>? descriptions;
  final bool multiple;
}

// ============================================================================
// WELCOME PAGE
// ============================================================================

class TradingProfileWelcomePage extends StatelessWidget {
  const TradingProfileWelcomePage({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 20),
          child: Column(
            children: [
              Image.asset(
                'assets/welcome_img.png',
                width: 180,
                height: 130,
                fit: BoxFit.contain,
              ),

              const SizedBox(height: 2),

              RichText(
                textAlign: TextAlign.center,
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: 'Welcome to ',
                      style: TextStyle(
                        color: _TradingProfileFlowState.ink,
                        fontSize: 29,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: Image(
                        image: AssetImage('assets/new_logo_zeno_ai.jpg'),
                        height: 53,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 5),

              const Text(
                'Your journey to Mind Control Trading\n'
                'starts here.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF61627B),
                  fontSize: 12,
                  height: 1.45,
                ),
              ),

              const SizedBox(height: 17),

              Row(
                children: [
                  const Expanded(
                    child: Divider(color: Color(0xFFE8E7F0), thickness: 1),
                  ),

                  const SizedBox(width: 12),

                  const Text(
                    'GET STARTED IN 3 STEPS',
                    style: TextStyle(
                      color: _TradingProfileFlowState.purple,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),

                  const SizedBox(width: 12),

                  const Expanded(
                    child: Divider(color: Color(0xFFE8E7F0), thickness: 1),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              const _WelcomeStep(
                number: '1',
                imagePath: 'assets/four__.png',
                title: 'Understand the Process',
                description: 'Understand how Mind Control Trading works.',
                active: true,
              ),

              const _WelcomeStep(
                number: '2',
                imagePath: 'assets/five___.png',
                title: 'Trust the Process',
                description: 'Build discipline and trust the process.',
              ),

              const _WelcomeStep(
                number: '3',
                imagePath: 'assets/six___.png',
                title: 'Apply the Process',
                description: 'Apply what you learn in your trading journey.',
                isLast: true,
              ),

              const SizedBox(height: 13),

              Row(
                children: [
                  const Expanded(child: Divider(color: Color(0xFFE8E7F0))),

                  const SizedBox(width: 12),

                  const Text(
                    'YOUR SETUP PROGRESS',
                    style: TextStyle(
                      color: _TradingProfileFlowState.violet,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),

                  const SizedBox(width: 12),

                  const Expanded(child: Divider(color: Color(0xFFE8E7F0))),
                ],
              ),

              const SizedBox(height: 10),

              const Row(
                children: [
                  Expanded(child: SizedBox()),

                  _ProgressCircle(number: '1', active: true),

                  Expanded(child: _ProgressLine()),

                  _ProgressCircle(number: '2', active: false),

                  Expanded(child: _ProgressLine()),

                  _ProgressCircle(number: '3', active: false),

                  Expanded(child: SizedBox()),
                ],
              ),

              const SizedBox(height: 8),

              const Text(
                '0 of 3 steps completed',
                style: TextStyle(
                  color: Color(0xFF77788F),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 13),

              SizedBox(
                width: double.infinity,
                height: 46,
                child: _PurpleButton(
                  label: 'Start Your Journey  →',
                  onTap: onComplete,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// WELCOME STEP
// ============================================================================

class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep({
    required this.number,
    required this.imagePath,
    required this.title,
    required this.description,
    this.isLast = false,
    this.active = false,
  });

  final String number;
  final String imagePath;
  final String title;
  final String description;
  final bool isLast;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 130,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 48,
            child: Column(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: active
                        ? _TradingProfileFlowState.purple
                        : const Color(0xFFF1EEFF),
                    boxShadow: active
                        ? [
                            BoxShadow(
                              color: _TradingProfileFlowState.purple
                                  .withOpacity(0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    number,
                    style: TextStyle(
                      color: active
                          ? Colors.white
                          : _TradingProfileFlowState.purple,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),

                if (!isLast)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: CustomPaint(painter: _DottedLinePainter()),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 9),

          Expanded(
            child: Container(
              height: 126,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: const Color(0xFFF0EFF5), width: 1),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x12000000),
                    blurRadius: 12,
                    spreadRadius: 1,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 82,
                    height: 82,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFF3F1FF),
                    ),
                    child: Image.asset(
                      imagePath,
                      width: 72,
                      height: 72,
                      fit: BoxFit.contain,
                    ),
                  ),

                  const SizedBox(width: 16),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _TradingProfileFlowState.ink,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            height: 1.25,
                          ),
                        ),

                        const SizedBox(height: 14),

                        Text(
                          description,
                          style: const TextStyle(
                            color: Color(0xFF373954),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
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
    );
  }
}

// ============================================================================
// PROGRESS CIRCLE
// ============================================================================

class _ProgressCircle extends StatelessWidget {
  const _ProgressCircle({required this.number, required this.active});

  final String number;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 25,
      height: 25,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? _TradingProfileFlowState.purple : Colors.white,
        border: Border.all(
          color: active
              ? _TradingProfileFlowState.purple
              : const Color(0xFFE1DEFA),
          width: active ? 2 : 1.5,
        ),
      ),
      alignment: Alignment.center,
      child: Container(
        width: active ? 17 : 21,
        height: active ? 17 : 21,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? _TradingProfileFlowState.purple : Colors.white,
        ),
        alignment: Alignment.center,
        child: Text(
          number,
          style: TextStyle(
            color: active ? Colors.white : _TradingProfileFlowState.purple,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// PROGRESS LINE
// ============================================================================

class _ProgressLine extends StatelessWidget {
  const _ProgressLine();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE3DFFD), width: 1.5)),
      ),
    );
  }
}

// ============================================================================
// DOTTED LINE
// ============================================================================

class _DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = const Color(0xFFE1DEFA)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const double dashHeight = 4.0;
    const double gap = 4.0;

    double y = 0;

    while (y < size.height) {
      final double endY = (y + dashHeight).clamp(0, size.height);

      canvas.drawLine(
        Offset(size.width / 2, y),
        Offset(size.width / 2, endY),
        paint,
      );

      y += dashHeight + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

// ============================================================================
// MCT LESSONS PAGE
// ============================================================================

class MctLessonsPage extends StatelessWidget {
  const MctLessonsPage({super.key, required this.onComplete});

  final VoidCallback onComplete;

  static const Color purple = Color(0xFF3F3AD8);

  static const String dummyVideo = 'assets/dummy_mct_video.mp4';

  static const List<_Lesson> lessons = [
    _Lesson(
      title: 'Introduction to Mind Control Trading',
      duration: 'Introduction',
      protocol: null,
    ),
    _Lesson(
      title: 'Process Over Everything',
      duration: '4 mins',
      protocol: 'Protocol No. 1',
    ),
    _Lesson(
      title: 'Cut the Noise',
      duration: '5 mins',
      protocol: 'Protocol No. 2',
    ),
    _Lesson(
      title: 'Trust the Process',
      duration: '7 mins',
      protocol: 'Protocol No. 3',
    ),
    _Lesson(
      title: 'Step-up Gradually',
      duration: '6 mins',
      protocol: 'Protocol No. 4',
    ),
    _Lesson(title: 'Be True', duration: '5 mins', protocol: 'Protocol No. 5'),
  ];

  void _openVideo(BuildContext context, _Lesson lesson) {
    Get.to(
      () => MctVideoPlayerPage(title: lesson.title, videoPath: dummyVideo),
    );
  }

  // IMPORTANT:
  // MCT LESSONS BACK BUTTON -> TRADING PROFILE WELCOME
  void _goToTradingProfileWelcome() {
    Get.off(() => TradingProfileWelcomePage(onComplete: onComplete));
  }

  // GO TO HOME BUTTON -> now delegates to the onComplete callback,
  // same pattern as the old "Start Your Journey" action. This is
  // provided by whatever screen created TradingProfileFlow, so no
  // hardcoded '/home' named route is required.
  void _goToHome() {
    onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 6),

            // ==================================================================
            // HEADER
            // ==================================================================
            Row(
              children: [
                IconButton(
                  onPressed: _goToTradingProfileWelcome,
                  icon: const Icon(
                    Icons.arrow_back,
                    size: 23,
                    color: Color(0xFF686868),
                  ),
                ),

                const Text(
                  'MCT LESSONS',
                  style: TextStyle(
                    color: Color(0xFF666666),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            // ==================================================================
            // DESCRIPTION
            // ==================================================================
            const Padding(
              padding: EdgeInsets.fromLTRB(37, 8, 30, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Please watch videos in sequence for Better\n'
                  'Understanding of Mind Control Trading Process',
                  style: TextStyle(
                    color: Color(0xFF555555),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // ==================================================================
            // PROGRESS
            // ==================================================================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 37),
              child: Row(
                children: [
                  const Text(
                    '0% Completed',
                    style: TextStyle(
                      color: Color(0xFF3E3E3E),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: const LinearProgressIndicator(
                        value: 0,
                        minHeight: 8,
                        backgroundColor: Color(0xFFBDBDBD),
                        valueColor: AlwaysStoppedAnimation<Color>(purple),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ==================================================================
            // VIDEOS + GO TO HOME BUTTON
            // ==================================================================
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                children: [
                  const _LessonSectionTitle(title: 'INTRODUCTION'),

                  const SizedBox(height: 9),

                  _LessonCard(
                    lesson: lessons[0],
                    onTap: () => _openVideo(context, lessons[0]),
                  ),

                  const SizedBox(height: 22),

                  const _LessonSectionTitle(
                    title: 'PROTOCOLS OF MIND CONTROL TRADING',
                  ),

                  const SizedBox(height: 9),

                  ...lessons
                      .skip(1)
                      .map(
                        (lesson) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _LessonCard(
                            lesson: lesson,
                            onTap: () => _openVideo(context, lesson),
                          ),
                        ),
                      ),

                  // ============================================================
                  // GO TO HOME BUTTON
                  // ============================================================
                  const SizedBox(height: 8),

                  const Divider(color: Color(0xFFE8E7F0), thickness: 1),

                  const SizedBox(height: 18),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: _PurpleButton(
                      label: 'GO TO HOME  →',
                      onTap: _goToHome,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'You can return to the Home screen anytime.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF777777), fontSize: 10),
                  ),

                  const SizedBox(height: 10),
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
// LESSON SECTION TITLE
// ============================================================================

class _LessonSectionTitle extends StatelessWidget {
  const _LessonSectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: const Color(0xFF707070))),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF5F5F5F),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        Expanded(child: Container(height: 1, color: const Color(0xFF707070))),
      ],
    );
  }
}

// ============================================================================
// LESSON CARD
// ============================================================================

class _LessonCard extends StatelessWidget {
  const _LessonCard({required this.lesson, required this.onTap});

  final _Lesson lesson;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool introduction = lesson.protocol == null;

    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 62),
          padding: const EdgeInsets.fromLTRB(7, 7, 15, 7),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFBDBDBD), width: 1.5),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!introduction)
                      Text(
                        lesson.protocol!,
                        style: const TextStyle(
                          color: Color(0xFF555555),
                          fontSize: 10,
                          height: 1.1,
                        ),
                      ),

                    if (!introduction) const SizedBox(height: 2),

                    Text(
                      lesson.title,
                      style: TextStyle(
                        color: const Color(0xFF242424),
                        fontSize: introduction ? 12 : 13,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                    ),

                    if (!introduction) ...[
                      const SizedBox(height: 5),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFBDBDBD)),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          lesson.duration,
                          style: const TextStyle(
                            color: Color(0xFF333333),
                            fontSize: 8,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 10),

              const Icon(Icons.play_arrow, color: Color(0xFF403BD7), size: 31),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// LESSON MODEL
// ============================================================================

class _Lesson {
  const _Lesson({
    required this.title,
    required this.duration,
    required this.protocol,
  });

  final String title;
  final String duration;
  final String? protocol;
}

// ============================================================================
// VIDEO PLAYER PAGE
// ============================================================================

class MctVideoPlayerPage extends StatefulWidget {
  const MctVideoPlayerPage({
    super.key,
    required this.title,
    required this.videoPath,
  });

  final String title;
  final String videoPath;

  @override
  State<MctVideoPlayerPage> createState() => _MctVideoPlayerPageState();
}

class _MctVideoPlayerPageState extends State<MctVideoPlayerPage>
    with SingleTickerProviderStateMixin {
  static const Color _screenBg = Color(0xFF0A0A12);

  late final TabController _tabController = TabController(
    length: 2,
    vsync: this,
  );

  // VIDEO CLOSE -> RETURN TO MCT LESSONS
  void _closeVideo() {
    Get.back();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _screenBg,
      body: Column(
        children: [
          // ====================================================================
          // HEADER (EXPLANATION / APP DEMO TABS + CLOSE BUTTON)
          // ====================================================================
          Container(
            width: double.infinity,
            color: _screenBg,
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  Expanded(
                    child: TabBar(
                      controller: _tabController,
                      labelColor: _TradingProfileFlowState.violet,
                      unselectedLabelColor: const Color(0xFF8A8A99),
                      indicatorColor: _TradingProfileFlowState.violet,
                      indicatorWeight: 3,
                      indicatorSize: TabBarIndicatorSize.label,
                      dividerColor: const Color(0xFF2A2A38),
                      labelStyle: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                      tabs: const [
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.menu_book_outlined, size: 16),
                              SizedBox(width: 6),
                              Text('EXPLANATION'),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.play_circle_outline, size: 16),
                              SizedBox(width: 6),
                              Text('APP DEMO'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _closeVideo,
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),

          // ====================================================================
          // SWIPEABLE VIDEO PAGES (swipe left/right to switch tabs)
          // ====================================================================
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _VideoTabPage(
                  videoPath: widget.videoPath,
                  playLabel: 'Play Explanation Video',
                ),
                _VideoTabPage(
                  videoPath: widget.videoPath,
                  playLabel: 'Play App Demo Video',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// VIDEO TAB PAGE (self-contained player for one tab — Explanation / App Demo)
// ============================================================================

class _VideoTabPage extends StatefulWidget {
  const _VideoTabPage({required this.videoPath, required this.playLabel});

  final String videoPath;
  final String playLabel;

  @override
  State<_VideoTabPage> createState() => _VideoTabPageState();
}

class _VideoTabPageState extends State<_VideoTabPage>
    with AutomaticKeepAliveClientMixin<_VideoTabPage> {
  VideoPlayerController? _controller;

  bool _loading = true;
  bool _hasError = false;
  bool _showControls = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    await _controller?.dispose();

    if (!mounted) {
      return;
    }

    setState(() {
      _controller = null;
      _loading = true;
      _hasError = false;
      _showControls = true;
    });

    try {
      debugPrint('================================================');

      debugPrint('VIDEO PATH: ${widget.videoPath}');

      debugPrint('================================================');

      final VideoPlayerController controller = VideoPlayerController.asset(
        widget.videoPath,
      );

      await controller.initialize();

      await controller.setLooping(false);

      if (!mounted) {
        await controller.dispose();
        return;
      }

      // Don't autoplay -- show the play button/caption first, and only
      // start once the user taps (matches the "start video" UI).
      setState(() {
        _controller = controller;
        _loading = false;
        _hasError = false;
        _showControls = true;
      });
    } catch (error, stackTrace) {
      debugPrint('================ VIDEO ERROR ================');

      debugPrint('VIDEO PATH: ${widget.videoPath}');

      debugPrint('ERROR: $error');

      debugPrintStack(stackTrace: stackTrace);

      debugPrint('==============================================');

      if (!mounted) {
        return;
      }

      setState(() {
        _controller = null;
        _loading = false;
        _hasError = true;
        _showControls = false;
      });
    }
  }

  Future<void> _toggleVideo() async {
    final VideoPlayerController? controller = _controller;

    if (controller == null ||
        !controller.value.isInitialized ||
        controller.value.hasError) {
      return;
    }

    if (controller.value.isPlaying) {
      await controller.pause();

      if (!mounted) {
        return;
      }

      setState(() {
        _showControls = true;
      });
    } else {
      await controller.play();

      if (!mounted) {
        return;
      }

      setState(() {
        _showControls = false;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // AutomaticKeepAliveClientMixin

    final VideoPlayerController? controller = _controller;

    final bool initialized =
        controller != null &&
        controller.value.isInitialized &&
        !controller.value.hasError;

    return Container(
      color: _MctVideoPlayerPageState._screenBg,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ==================================================================
          // VIDEO
          // ==================================================================
          if (initialized)
            Center(
              child: AspectRatio(
                aspectRatio: controller.value.aspectRatio == 0
                    ? 16 / 9
                    : controller.value.aspectRatio,
                child: VideoPlayer(controller),
              ),
            ),

          // ==================================================================
          // TAP TO PLAY / PAUSE
          // ==================================================================
          if (initialized)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _toggleVideo,
                child: const SizedBox.expand(),
              ),
            ),

          // ==================================================================
          // LOADING
          // ==================================================================
          if (_loading)
            const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),

          // ==================================================================
          // ERROR
          // ==================================================================
          if (_hasError)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.white,
                      size: 50,
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      'Unable to load video',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 16),

                    SizedBox(
                      height: 40,
                      child: ElevatedButton(
                        onPressed: _initializeVideo,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _TradingProfileFlowState.violet,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        child: const Text(
                          'Retry',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ==================================================================
          // PLAY BUTTON + CAPTION
          // ==================================================================
          if (initialized && _showControls && !controller.value.isPlaying)
            Center(
              child: _GlowPlayButton(
                label: widget.playLabel,
                onTap: _toggleVideo,
              ),
            ),

          // ==================================================================
          // VIDEO PROGRESS
          // ==================================================================
          if (initialized)
            Positioned(
              left: 14,
              right: 14,
              bottom: 10,
              child: VideoProgressIndicator(
                controller,
                allowScrubbing: true,
                padding: const EdgeInsets.symmetric(vertical: 5),
                colors: const VideoProgressColors(
                  playedColor: _TradingProfileFlowState.violet,
                  bufferedColor: Color(0xFF4A4A5A),
                  backgroundColor: Color(0xFF2A2A38),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================================
// GLOW PLAY BUTTON (big circular play button with soft glow + caption)
// ============================================================================

class _GlowPlayButton extends StatelessWidget {
  const _GlowPlayButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: 190,
            height: 190,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  _TradingProfileFlowState.violet.withOpacity(0.45),
                  _TradingProfileFlowState.violet.withOpacity(0),
                ],
              ),
            ),
            child: Container(
              width: 86,
              height: 86,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF15121F),
                border: Border.all(
                  color: _TradingProfileFlowState.violet,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _TradingProfileFlowState.violet.withOpacity(0.55),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                Icons.play_arrow_rounded,
                color: _TradingProfileFlowState.violet.withOpacity(0.9),
                size: 42,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}