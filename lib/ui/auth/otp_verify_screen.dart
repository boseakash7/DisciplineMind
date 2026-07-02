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

  // Backspace / Delete case
  if (cleanValue.isEmpty) {
    _digitControllers[index].clear();

    // Move focus to previous field if not first
    if (index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    setState(() {});
    return;
  }

  // Paste case
  if (cleanValue.length > 1) {
    _handlePaste(cleanValue, startIndex: index);
    return;
  }

  // Normal single digit input
  _digitControllers[index].text = cleanValue;
  _digitControllers[index].selection =  TextSelection.fromPosition(
    TextPosition(offset: 1),
  );

  if (index < _otpLength - 1) {
    _focusNodes[index + 1].requestFocus();
  } else {
    _focusNodes[index].unfocus();
  }
  setState(() {});
}
void _onFieldSubmittedOrBackspace(int index) {
  if (_digitControllers[index].text.isEmpty && index > 0) {
    _focusNodes[index - 1].requestFocus();
  }
}
  void _handlePaste(String pastedOtp, {int startIndex = 0}) {
    final digits = pastedOtp.length >= _otpLength
        ? pastedOtp.substring(0, _otpLength).split('')
        : pastedOtp.split('');

    for (int i = 0; i < _otpLength; i++) {
      _digitControllers[i].text = digits.length > i ? digits[i] : '';
    }

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

  Widget _buildOtpField(int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: SizedBox(
        width: 45,
        height: 60,
        child: TextField(
          controller: _digitControllers[index],
          focusNode: _focusNodes[index],
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(_otpLength),
          ],
          decoration: InputDecoration(
            counterText: "",
            filled: true,
            fillColor: const Color(0xFF2C2C2E),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: Color(0xFF00BFFF), width: 2),
            ),
          ),
          onSubmitted: (_) => _onFieldSubmittedOrBackspace(index),
          onChanged: (value) => _onDigitChanged(index, value),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

              // Logo
              Image.asset("assets/logo.png", height:60),

              const SizedBox(height: 14),

              // Title
              const Text(
                "Sing up or log in",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 12),
 Text(
                    "Please enter the 4-digit code we sent to ",
                    style: TextStyle(fontSize: 15, color: Colors.grey),
                  ),
              // Subtitle with Edit Icon
              InkWell(
                onTap: () {
                  Get.to(() => PhoneLoginScreen());
                  _otp.isEmpty;
                 setState(() {
                   
                 }); },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                   
                    Text(
                      widget.phone,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF00BFFF),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.edit,
                      size: 18,
                      color: Color(0xFF00BFFF),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // OTP Fields
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: List.generate(_otpLength, (i) => _buildOtpField(i)),
              ),

              const SizedBox(height: 4),

              // Resend info
              const Text(
                "Didn't receive the code? Resend in 25s",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
SizedBox(height: 30),
              // const Spacer(),

              // VERIFY Button
              Obx(
                () => PrimaryButton(
                  text: "VERIFY",width: MediaQuery.sizeOf(context).width*.8,
                  color: const Color(0xFF01242A),
                  height: 56,borderRadius: 100,side: BorderSide(color: AppColors.backgroundGray.withOpacity(.4)),
                  isLoading: authController.isLoading.value,
                  onPressed: _otp.length == _otpLength ? _verify : null,
                ),
              ),

              const SizedBox(height: 16),

              // Resend OTP Button
              Obx(
                () => PrimaryButton(
                  text: "Resend OTP",width: MediaQuery.sizeOf(context).width*.8,
                  color: const Color(0xFF00BFFF),
                  height: 56,borderRadius: 100,
                  onPressed: authController.isLoading.value ? null : _resend,
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}