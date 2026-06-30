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

  final List<TextEditingController> _digitControllers =
      List.generate(4, (_) => TextEditingController());

  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());

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
      if (index > 0) _focusNodes[index - 1].requestFocus();
      setState(() {});
      return;
    }

    _digitControllers[index].text = cleanValue.substring(cleanValue.length - 1);

    if (index < 3) {
      _focusNodes[index + 1].requestFocus();
    } else {
      _focusNodes[index].unfocus();
    }
    setState(() {});
  }

  Future<void> _verify() async {
    if (_otp.length != 4) return;

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
  Color get _cardColor => _isDark ? const Color(0xFF1E1E1E) : AppColors.backgroundGray;

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
          maxLength: 1,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: _textColor,
          ),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
              children: List.generate(4, (i) => _buildOtpField(i)),
            ),
            const SizedBox(height: 32),
            Obx(
              () => PrimaryButton(
                text: "VERIFY",
                color: AppColors.primary,
                isLoading: authController.isLoading.value,
                onPressed: _otp.length == 4 ? _verify : null,
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