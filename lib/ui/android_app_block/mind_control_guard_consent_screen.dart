import 'package:flutter/material.dart';

/// Mind Control Guard Consent & Acknowledgement Screen.
/// Shown on first-time opening of a blocked trading app before revealing the lock screen.
class MindControlGuardConsentScreen extends StatefulWidget {
  final VoidCallback onAgree;
  final VoidCallback onCancel;

  const MindControlGuardConsentScreen({
    super.key,
    required this.onAgree,
    required this.onCancel,
  });

  @override
  State<MindControlGuardConsentScreen> createState() =>
      _MindControlGuardConsentScreenState();
}

class _MindControlGuardConsentScreenState
    extends State<MindControlGuardConsentScreen> {
  static const _navy = Color(0xFF16161D);
  static const _purple = Color(0xFF4A22F4);
  static const _violet = Color(0xFF983BF4);
  static const _ink = Color(0xFF10122D);
  static const _grey = Color(0xFF64748B);
  static const _lightPurple = Color(0xFFFAF8FF);
  static const _border = Color(0xFFE9DDFC);

  static const LinearGradient _primaryGradient = LinearGradient(
    colors: [_purple, _violet],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  bool _check1 = false;
  bool _check2 = false;
  bool _check3 = false;

  bool get _allChecked => _check1 && _check2 && _check3;

  void _selectAll(bool? value) {
    final v = value ?? false;
    setState(() {
      _check1 = v;
      _check2 = v;
      _check3 = v;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            _buildTopBar(),
            const Divider(height: 1, color: Color(0xFFF1F0F7)),
            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderBanner(),
                    const SizedBox(height: 18),
                    _buildSectionHeader(
                      'Mind Control Guard – User Acknowledgement',
                      Icons.shield_outlined,
                    ),
                    const SizedBox(height: 10),
                    _buildBulletList([
                      'I understand that Mind Control Guard is designed to help me maintain discipline and follow my selected Mind Control Trading process.',
                      'I voluntarily authorise Zeno AI, where technically supported, to temporarily restrict, delay, interrupt or require confirmation before I access or interact with a selected trading application, trading screen, position or related trading functionality.',
                      'I understand that Zeno may intervene before I enter a trade, while I have an open position, or after a trade, depending on the process and controls I have configured.',
                      'I understand that Mind Control Guard is intended to reduce impulsive behaviour such as FOMO, revenge trading, overtrading and emotionally driven decisions. It does not guarantee profits or prevent losses.',
                      'I understand that a restriction or delay may affect my ability to access a trading application or react to a rapidly moving market. I accept this risk as part of voluntarily enabling the feature.',
                      'I understand that Zeno cannot guarantee that every route to a trading application will be blocked and that technical, operating-system, broker or device changes may affect the feature.',
                      'I understand that I remain responsible for my trading decisions and for complying with my broker’s terms and applicable law.',
                    ]),
                    const SizedBox(height: 20),
                    _buildSectionHeader(
                      'Position-Sizing Acknowledgement',
                      Icons.tune_rounded,
                    ),
                    const SizedBox(height: 10),
                    _buildInfoCard(
                      'I understand that Zeno may provide indicative position-sizing or risk-management calculations based on my selected process and the inputs I provide. I will verify the resulting quantity, stop-loss, lot size, margin, liquidity, charges and other applicable trading conditions before placing an order.',
                    ),
                    const SizedBox(height: 22),
                    _buildSectionHeader(
                      'Acceptance & Consent',
                      Icons.check_circle_outline_rounded,
                    ),
                    const SizedBox(height: 10),
                    _buildAcceptanceSection(),
                  ],
                ),
              ),
            ),
            // Bottom Action Controls
            _buildBottomControls(bottomInset),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: _primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.psychology_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MIND CONTROL GUARD',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _navy,
                    letterSpacing: 0.4,
                  ),
                ),
                Text(
                  'Consent & User Acknowledgement',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _grey,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF3EEFF),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: _border),
            ),
            child: const Text(
              'v1.0',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _purple,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _lightPurple,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFFEAE3FF),
              borderRadius: BorderRadius.circular(7),
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              color: _purple,
              size: 17,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Please review and accept this acknowledgement before Mind Control Guard protection is enabled on your device.',
              style: TextStyle(
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w600,
                color: _ink,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: _purple),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: _navy,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBulletList(List<String> items) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF9FD),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEBE7F3)),
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: _purple,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    items[i],
                    style: const TextStyle(
                      fontSize: 12.5,
                      height: 1.45,
                      fontWeight: FontWeight.w500,
                      color: _ink,
                    ),
                  ),
                ),
              ],
            ),
            if (i < items.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCard(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF9FD),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEBE7F3)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12.5,
          height: 1.45,
          fontWeight: FontWeight.w500,
          color: _ink,
        ),
      ),
    );
  }

  Widget _buildAcceptanceSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _lightPurple,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          // Select All Checkbox
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => _selectAll(!_allChecked),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              child: Row(
                children: [
                  _customCheckbox(
                    value: _allChecked,
                    onChanged: _selectAll,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'I agree to all 3 statements below',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: _purple,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 16, color: _border),
          // Point 1
          _checkboxRow(
            value: _check1,
            label: 'I understand and voluntarily enable Mind Control Guard.',
            onChanged: (v) => setState(() => _check1 = v ?? false),
          ),
          const SizedBox(height: 8),
          // Point 2
          _checkboxRow(
            value: _check2,
            label:
                'I understand that Zeno may temporarily delay or restrict access to selected trading functionality.',
            onChanged: (v) => setState(() => _check2 = v ?? false),
          ),
          const SizedBox(height: 8),
          // Point 3
          _checkboxRow(
            value: _check3,
            label:
                'I understand that Zeno does not guarantee trading profits or loss prevention.',
            onChanged: (v) => setState(() => _check3 = v ?? false),
          ),
        ],
      ),
    );
  }

  Widget _checkboxRow({
    required bool value,
    required String label,
    required ValueChanged<bool?> onChanged,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: _customCheckbox(
                value: value,
                onChanged: onChanged,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12.5,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                  color: _ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _customCheckbox({
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: value ? _purple : Colors.white,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: value ? _purple : const Color(0xFFAAA7B5),
            width: 1.4,
          ),
        ),
        child: value
            ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
            : null,
      ),
    );
  }

  Widget _buildBottomControls(double bottomInset) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 10, 20, 12 + bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            offset: Offset(0, -3),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 48,
            child: Container(
              decoration: BoxDecoration(
                gradient: _primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    if (!_allChecked) {
                      _selectAll(true);
                    }
                    widget.onAgree();
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.verified_user_rounded,
                          color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'I Agree & Enable Protection',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onCancel,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 6, horizontal: 16),
              child: Text(
                'Cancel & Exit to Home',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _grey,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
