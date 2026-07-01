import 'package:discipline_mind/common/app_colors.dart';
import 'package:discipline_mind/controller/auth_controller.dart';
import 'package:discipline_mind/ui/auth/signup_screen.dart';
import 'package:discipline_mind/ui/widgets/app_toast.dart';
import 'package:discipline_mind/ui/widgets/common_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class OtpVerifyScreen extends StatefulWidget {
  final String phone;

  const OtpVerifyScreen({
    super.key,
    required this.phone,
  });

  @override
  State<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends State<OtpVerifyScreen> {
  final AuthController authController = Get.find<AuthController>();

  static const int _otpLength = 4;

  final List<TextEditingController> _digitControllers =
      List.generate(_otpLength, (_) => TextEditingController());

  final List<FocusNode> _focusNodes = List.generate(_otpLength, (_) => FocusNode());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    for (final c in _digitControllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    super.dispose();
  }

  String get _otp => _digitControllers.map((e) => e.text).join();

  void _onDigitChanged(int index, String value) {
    final cleanValue = value.replaceAll(RegExp(r'\D'), '');

    if (cleanValue.isEmpty) {
      _digitControllers[index].clear();
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
      setState(() {});
      return;
    }

    // === PASTE SUPPORT ===
    // Because maxLength is no longer capped at 1, a pasted string like
    // "1234" arrives here in full instead of being truncated beforehand.
    if (cleanValue.length > 1) {
      _handlePaste(cleanValue, startIndex: index);
      return;
    }

    // Single digit typed normally
    _digitControllers[index].text = cleanValue;
    _digitControllers[index].selection = TextSelection.fromPosition(
      const TextPosition(offset: 1),
    );

    if (index < _otpLength - 1) {
      _focusNodes[index + 1].requestFocus();
    } else {
      _focusNodes[index].unfocus();
    }
    setState(() {});
  }

  void _handlePaste(String pastedOtp, {int startIndex = 0}) {
    // Fill starting from startIndex, but if more digits were pasted than fit,
    // it still fills from the beginning of the row for a natural OTP-paste feel.
    final digits = pastedOtp.length >= _otpLength
        ? pastedOtp.substring(0, _otpLength).split('')
        : pastedOtp.split('');

    for (int i = 0; i < _otpLength; i++) {
      _digitControllers[i].text = digits.length > i ? digits[i] : '';
    }

    // Focus last filled field or unfocus if complete
    if (digits.length >= _otpLength) {
      _focusNodes[_otpLength - 1].unfocus();
    } else {
      _focusNodes[digits.length].requestFocus();
    }

    setState(() {});
  }

  Future<void> _verify() async {
    if (_otp.length != _otpLength) return;

    final payload = await authController.verifyOtp(widget.phone, _otp);
    if (!mounted || payload == null) return;

    if (payload.isOldUser) {
      if (payload.user == null) {
        AppToast.showToast("Could not complete login. Try again.");
        return;
      }
      await authController.applyLoggedInUser(payload.toLoginResponseModel());
      return;
    }

    Get.off(() => SignUpScreen(lockedPhone: widget.phone));
  }

  Future<void> _resend() async {
    await authController.sendOtp(widget.phone);
  }

  // Theme Helpers
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _textColor => _isDark ? Colors.white : AppColors.textBlack;
  Color get _secondaryTextColor => _isDark ? Colors.grey.shade400 : AppColors.textGrey;
  Color get _backgroundColor => _isDark ? const Color(0xFF121212) : AppColors.white;
  Color get _cardColor => !_isDark ? Colors.grey.shade200 : AppColors.backgroundGray;

  Widget _buildOtpField(int index) {
    return SizedBox(
      width: 56,
      child: Focus(
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.backspace) {
            if (_digitControllers[index].text.isEmpty && index > 0) {
              _digitControllers[index - 1].clear();
              _focusNodes[index - 1].requestFocus();
              setState(() {});
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: TextField(
          controller: _digitControllers[index],
          focusNode: _focusNodes[index],
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          // NOTE: no `maxLength` here anymore. With maxLength: 1, Flutter
          // truncated a pasted "1234" down to "1" before onChanged ever saw
          // it, so paste never worked. We now allow the field to receive
          // up to `_otpLength` digits and trim it ourselves in code.
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: !_isDark ? Colors.white : AppColors.textBlack,
          ),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(_otpLength),
          ],
          decoration: InputDecoration(
            counterText: "",
            filled: true,
            fillColor: _cardColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primaryGreen, width: 2),
            ),
          ),
          onChanged: (value) => _onDigitChanged(index, value),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        elevation: 0,
        leading: BackButton(color: _textColor),
        title: Text(
          "Verify OTP",
          style: TextStyle(color: _textColor),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            Text(
              "Enter the 4-digit code",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Sent to ${widget.phone}",
              textAlign: TextAlign.center,
              style: TextStyle(color: _secondaryTextColor, fontSize: 14),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(_otpLength, (i) => _buildOtpField(i)),
            ),
            const SizedBox(height: 32),
            Obx(
              () => PrimaryButton(
                text: "VERIFY",
                color: AppColors.primary,
                isLoading: authController.isLoading.value,
                onPressed: _otp.length == _otpLength ? _verify : null,
              ),
            ),
            const SizedBox(height: 20),
            Obx(
              () => TextButton(
                onPressed: authController.isLoading.value ? null : _resend,
                child: Text(
                  "Resend OTP",
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}