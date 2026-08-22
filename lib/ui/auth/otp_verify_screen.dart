import 'dart:async';

import 'package:discipline_mind/common/app_colors.dart';
import 'package:discipline_mind/controller/auth_controller.dart';
import 'package:discipline_mind/ui/auth/phone_login_screen.dart';
import 'package:discipline_mind/ui/auth/signup_screen.dart';
import 'package:discipline_mind/ui/auth/sms_consent_service.dart';
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
  final SmsConsentService _smsConsentService = SmsConsentService();

  static const List<Color> _brandGradient = [
    Color(0xFFAF28FC),
    Color(0xFF1D4BF9),
  ];

  static const int _otpLength = 4;
  static const int _resendSeconds = 30;

  int _secondsLeft = _resendSeconds;
  Timer? _resendTimer;
  bool _autoVerifyTriggered = false;

  final TextEditingController _otpController = TextEditingController();
  final FocusNode _otpFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _otpController.addListener(_onOtpChanged);

    _startSmsListener();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _otpFocusNode.requestFocus();
    });

    _startResendTimer();
  }

  // ==================== SMS USER CONSENT (auto fill + auto verify) ====================

  Future<void> _startSmsListener() async {
    try {
      await _smsConsentService.startListening(
        otpLength: _otpLength,
        onOtpReceived: (otp) {
          if (!mounted) return;
          debugPrint("OTP auto-received via SMS User Consent: $otp");
          _otpController.text = otp; // triggers _onOtpChanged -> auto verify
          _otpFocusNode.unfocus();
        },
        onError: (error) {
          debugPrint("SMS consent error/timeout: $error");
          // user ने deny किया या 5 min timeout हो गया — manual entry fallback चलता रहेगा
        },
      );
    } catch (e) {
      debugPrint("Could not start SMS consent listener: $e");
    }
  }

  @override
  void dispose() {
    _otpController.removeListener(_onOtpChanged);
    _otpController.dispose();
    _otpFocusNode.dispose();
    _resendTimer?.cancel();
    _smsConsentService.stopListening();
    super.dispose();
  }

  // ==================== RESEND TIMER ====================
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

  String get _otp => _otpController.text;

  void _onOtpChanged() {
    setState(() {});

    if (_otp.length == _otpLength && !_autoVerifyTriggered) {
      _autoVerifyTriggered = true;
      _otpFocusNode.unfocus();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _verify();
      });
    } else if (_otp.length < _otpLength) {
      _autoVerifyTriggered = false;
    }
  }

  Future<void> _verify() async {
    if (_otp.length != _otpLength) return;

    debugPrint("Verifying OTP: $_otp for phone: ${widget.phone}");

    final payload = await authController.verifyOtp(widget.phone, _otp);
    if (!mounted || payload == null) {
      debugPrint("Verification failed or payload is null");
      _autoVerifyTriggered = false;
      return;
    }

    if (payload.isOldUser) {
      if (payload.user == null) {
        AppToast.showToast("Could not complete login. Try again.");
        authController.isLoading.value = false;
        _autoVerifyTriggered = false;
        return;
      }

      await authController.applyLoggedInUser(payload.toLoginResponseModel());
      authController.isLoading.value = false;
      return;
    }

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
      await _startSmsListener(); // listener फिर से शुरू करो
    }
  }

  // ==================== GRADIENT HELPERS ====================
  Widget _gradientTint({required Widget child}) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) =>
          const LinearGradient(colors: _brandGradient).createShader(bounds),
      child: child,
    );
  }

  // ==================== OTP BOXES ====================
  Widget _buildOtpBox(
    int index, {
    required bool isDark,
    required Color textColor,
    required Color boxFillColor,
    required Color boxBorderColor,
  }) {
    final text = _otpController.text;
    final digit = index < text.length ? text[index] : '';
    final isCurrent = index == text.length;
    final isFocused = isCurrent && _otpFocusNode.hasFocus;
    const borderWidth = 2.0;

    final content = Container(
      width: isFocused ? 48 - borderWidth * 2 : 48,
      height: isFocused ? 60 - borderWidth * 2 : 60,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: boxFillColor,
        borderRadius: BorderRadius.circular(isFocused ? 4 : 6),
        border: isFocused
            ? null
            : Border.all(color: boxBorderColor, width: borderWidth),
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

    if (!isFocused) {
      return content;
    }

    return Container(
      padding: const EdgeInsets.all(borderWidth),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: _brandGradient),
        borderRadius: BorderRadius.circular(6),
      ),
      child: content,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                child: _gradientTint(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.phone,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.edit, size: 16, color: Colors.white),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),

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
                      Opacity(
                        opacity: 0.0,
                        child: TextField(
                          controller: _otpController,
                          focusNode: _otpFocusNode,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
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
                          ),
                          onSubmitted: (_) => _verify(),
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
                          _secondsLeft > 0
                              ? TextSpan(
                                  text: "Resend in ${_secondsLeft}s",
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.grey.shade300
                                        : Colors.grey.shade500,
                                    fontWeight: FontWeight.w700,
                                  ),
                                )
                              : WidgetSpan(
                                  alignment: PlaceholderAlignment.middle,
                                  child: _gradientTint(
                                    child: const Text(
                                      "Resend OTP",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                        ],
                      ),
                    ),
                  )),

              const SizedBox(height: 40),

              Obx(() => PrimaryButton(
                    text: "Verify OTP",
                    gradient: const LinearGradient(colors: _brandGradient),
                    height: 45,
                    width: MediaQuery.sizeOf(context).width * 0.84,
                    textsize: 20,
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