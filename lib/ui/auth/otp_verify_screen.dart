import 'dart:async';

import 'package:discipline_mind/common/app_colors.dart';
import 'package:discipline_mind/controller/auth_controller.dart';
import 'package:discipline_mind/ui/auth/phone_login_screen.dart';
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
  static const int _resendSeconds = 30;

  int _secondsLeft = _resendSeconds;
  Timer? _resendTimer;
  bool _autoVerifyTriggered = false;

  // ---- SINGLE hidden controller/focus node handles ALL input + autofill ----
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _otpFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _otpController.addListener(_onOtpChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _otpFocusNode.requestFocus();
    });
    _startResendTimer();
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() => _secondsLeft = _resendSeconds);

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_secondsLeft <= 1) {
          timer.cancel();
          _secondsLeft = 0;
        } else {
          _secondsLeft--;
        }
      });
    });
  }

  @override
  void dispose() {
    _otpController.removeListener(_onOtpChanged);
    _otpController.dispose();
    _otpFocusNode.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  String get _otp => _otpController.text;

  void _onOtpChanged() {
    // UI ko refresh karo taake boxes update hon (filled digits + cursor box highlight)
    setState(() {});

    if (_otp.length == _otpLength && !_autoVerifyTriggered) {
      _autoVerifyTriggered = true;
      _otpFocusNode.unfocus();
      // Thoda delay taake autofill/keyboard animation smoothly complete ho jaye
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) _verify();
      });
    } else if (_otp.length < _otpLength) {
      _autoVerifyTriggered = false;
    }
  }

  Future<void> _verify() async {
  if (_otp.length != _otpLength) return;

  final payload = await authController.verifyOtp(widget.phone, _otp);
  if (!mounted || payload == null) {
    // verifyOtp() ne failure/error case mein khud isLoading false kar diya hoga
    _autoVerifyTriggered = false;
    return;
  }

  if (payload.isOldUser) {
    if (payload.user == null) {
      AppToast.showToast("Could not complete login. Try again.");
      authController.isLoading.value = false; // yahan flow ruk gaya, spinner band karo
      _autoVerifyTriggered = false;
      return;
    }

    // isLoading abhi bhi true hai (verifyOtp se) — is poore save/navigate
    // step ke dauran bhi spinner dikhta rahega, koi "khaali" pause nahi aayega
    await authController.applyLoggedInUser(payload.toLoginResponseModel());
    authController.isLoading.value = false; // ab poora flow complete hua
    return;
  }

  // New user -> naye screen pe turant navigate, wahan jaake spinner khud hat jayega
  authController.isLoading.value = false;
  Get.off(() => SignUpScreen(lockedPhone: widget.phone));
}

  Future<void> _resend() async {
    if (_secondsLeft > 0) return;
    _otpController.clear();
    _autoVerifyTriggered = false;
    await authController.sendOtp(widget.phone);
    if (mounted) {
      _startResendTimer();
      _otpFocusNode.requestFocus();
    }
  }

  // Ek single box banata hai jo hidden controller ke Nth digit ko dikhata hai
  Widget _buildOtpBox(
    int index, {
    required bool isDark,
    required Color textColor,
    required Color boxFillColor,
    required Color boxBorderColor,
  }) {
    final text = _otpController.text;
    final digit = index < text.length ? text[index] : '';
    final isCurrent = index == text.length; // yeh box "active" hai (cursor yahan)

    return Container(
      width: 48,
      height: 60,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: boxFillColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isCurrent && _otpFocusNode.hasFocus
              ? AppColors.primary
              : boxBorderColor,
          width: 2,
        ),
      ),
      child: Text(
        digit,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Same pattern as PhoneLoginScreen — theme-aware colors instead of hardcoded black/white
    final backgroundColor = isDark ? const Color(0xFF121212) : AppColors.white;
    final textColor = isDark ? Colors.white : AppColors.textBlack;
    final secondaryTextColor = isDark ? Colors.grey.shade400 : AppColors.textGrey;
    final boxFillColor = isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade200;
    final boxBorderColor = isDark ? Colors.transparent : AppColors.bordercolor;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 60),
              Text(
                "Enter Verification Code",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              Text(
                "Please enter the 4-digit code we sent to",
                style: TextStyle(fontSize: 14, color: secondaryTextColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),

              InkWell(
                onTap: () => Get.to(() => PhoneLoginScreen()),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.phone,
                      style: const TextStyle(fontSize: 15, color: AppColors.primary, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.edit, size: 16, color: AppColors.primary),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // ---- Stack: neeche visual boxes, upar ek transparent real TextField ----
              // Isi wajah se SMS aate hi Android/iOS ka autofill suggestion turant
              // dikhta hai aur ek hi jagah pura OTP fill hota hai (koi confusion nahi).
              GestureDetector(
                onTap: () => _otpFocusNode.requestFocus(),
                child: SizedBox(
                  height: 60,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _otpLength,
                          (i) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: _buildOtpBox(
                              i,
                              isDark: isDark,
                              textColor: textColor,
                              boxFillColor: boxFillColor,
                              boxBorderColor: boxBorderColor,
                            ),
                          ),
                        ),
                      ),
                      // Real field — poori width, transparent, sirf input capture karne ke liye
                      Opacity(
                        opacity: 0.0,
                        child: AutofillGroup(
                          child: TextField(
                            controller: _otpController,
                            focusNode: _otpFocusNode,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            autofillHints: const [AutofillHints.oneTimeCode],
                            autocorrect: false,
                            enableSuggestions: false,
                            showCursor: false,
                            cursorColor: Colors.transparent,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(_otpLength),
                            ],
                            decoration: const InputDecoration(
                              counterText: "",
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                            ),
                            onSubmitted: (_) {
                              if (_otp.length == _otpLength) _verify();
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Obx(() => GestureDetector(
                    onTap: authController.isLoading.value || _secondsLeft > 0 ? null : _resend,
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: TextStyle(color: secondaryTextColor, fontSize: 14),
                        children: [
                          const TextSpan(text: "Didn't receive the code? "),
                          TextSpan(
                            text: _secondsLeft > 0 ? "Resend in ${_secondsLeft}s" : "Resend OTP",
                            style: TextStyle(
                              color: _secondsLeft > 0
                                  ? (isDark ? Colors.grey.shade300 : Colors.grey.shade500)
                                  : AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )),

              const SizedBox(height: 40),

              Obx(() => PrimaryButton(
                    text: "Verify OTP",
                    width: MediaQuery.sizeOf(context).width * 0.85,
                    color: AppColors.primary,
                    height: 56,
                    borderRadius: 100,
                    isLoading: authController.isLoading.value,
                    onPressed: _otp.length == _otpLength ? _verify : null,
                  )),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}