import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../common/v2_app_colors.dart';
import '../../controllers/v2_auth_controller.dart';
import '../widgets/v2_widgets.dart';
import 'v2_signup_screen.dart';

class V2OtpVerifyScreen extends StatefulWidget {
  final String phone;

  const V2OtpVerifyScreen({super.key, required this.phone});

  @override
  State<V2OtpVerifyScreen> createState() => _V2OtpVerifyScreenState();
}

class _V2OtpVerifyScreenState extends State<V2OtpVerifyScreen> {
  final V2AuthController authController = Get.find<V2AuthController>();
  final List<TextEditingController> _digitControllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
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
    for (final c in _digitControllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _otp => _digitControllers.map((c) => c.text).join().trim();

  void _onDigitChanged(int index, String value) {
    final v = value.replaceAll(RegExp(r'\D'), '');
    if (v.isEmpty) {
      _digitControllers[index].text = '';
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
      setState(() {});
      return;
    }
    final char = v.substring(v.length - 1);
    _digitControllers[index].text = char;
    if (index < 3) {
      _focusNodes[index + 1].requestFocus();
    } else {
      _focusNodes[index].unfocus();
    }
    setState(() {});
  }

  Future<void> _verify() async {
    final code = _otp;
    if (code.length != 4) {
      V2Toast.showToast("Please enter complete 4-digit code");
      return;
    }
    final payload = await authController.verifyOtp(widget.phone, code);
    if (!mounted || payload == null) return;

    if (payload.isOldUser) {
      if (payload.user != null) {
        await authController.applyLoggedInUser(payload.toLoginResponseModel());
      } else {
        V2Toast.showToast("Verification successful! Please log in.");
        Get.back();
      }
      return;
    }

    Get.off(() => V2SignUpScreen(lockedPhone: widget.phone));
  }

  Future<void> _resend() async {
    await authController.sendOtp(widget.phone);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: V2AppColors.white,
      appBar: AppBar(
        backgroundColor: V2AppColors.white,
        elevation: 0,
        leading: const BackButton(color: V2AppColors.textBlack),
        title: const Text(
          "Verify OTP",
          style: TextStyle(
            color: V2AppColors.textBlack,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              alignment: Alignment.center,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: V2AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mark_email_read_rounded,
                  size: 48,
                  color: V2AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Enter 4-Digit Code",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: V2AppColors.textBlack,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Sent to ${widget.phone}",
              textAlign: TextAlign.center,
              style: const TextStyle(color: V2AppColors.textGrey, fontSize: 14),
            ),
            const SizedBox(height: 36),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(4, (i) {
                return SizedBox(
                  width: 58,
                  height: 60,
                  child: TextField(
                    controller: _digitControllers[i],
                    focusNode: _focusNodes[i],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: V2AppColors.textBlack,
                    ),
                    decoration: InputDecoration(
                      counterText: "",
                      filled: true,
                      fillColor: V2AppColors.backgroundGray,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: V2AppColors.primary,
                          width: 2,
                        ),
                      ),
                    ),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (v) => _onDigitChanged(i, v),
                  ),
                );
              }),
            ),
            const SizedBox(height: 32),
            Obx(
              () => V2PrimaryButton(
                text: "VERIFY OTP",
                color: V2AppColors.primary,
                isLoading: authController.isLoading.value,
                onPressed: _otp.length == 4 ? _verify : null,
              ),
            ),
            const SizedBox(height: 20),
            Obx(
              () => TextButton(
                onPressed: authController.isLoading.value ? null : _resend,
                child: const Text(
                  "Resend Code",
                  style: TextStyle(
                    color: V2AppColors.primaryDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
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
