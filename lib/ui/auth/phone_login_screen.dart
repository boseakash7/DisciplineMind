import 'package:discipline_mind/common/app_colors.dart';
import 'package:discipline_mind/controller/auth_controller.dart';
import 'package:discipline_mind/ui/auth/otp_verify_screen.dart';
import 'package:discipline_mind/ui/widgets/common_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class PhoneLoginScreen extends StatelessWidget {
  PhoneLoginScreen({super.key});

  final AuthController authController = Get.put(AuthController());
  final TextEditingController phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 80),
              const CircleAvatar(
                radius: 45,
                backgroundColor: AppColors.primary,
                child: Icon(Icons.psychology, size: 55, color: AppColors.white),
              ),
              const SizedBox(height: 16),
              const Text(
                "Disciplined Minds",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textBlack,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Enter your phone number to sign in or create an account",
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textGrey, fontSize: 14),
              ),
              const SizedBox(height: 48),
              CustomTextField(
                hint: "Phone number",
                icon: Icons.phone_outlined,
                controller: phoneController,
                keyboardType: TextInputType.phone,
                maxLength: 15,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Phone number is required";
                  }
                  final digits = value.replaceAll(RegExp(r'\D'), '');
                  if (digits.length < 10) {
                    return "Enter a valid phone number";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Obx(
                () => PrimaryButton(
                  text: "SEND OTP",
                  color: AppColors.primary,
                  isLoading: authController.isLoading.value,
                  onPressed: () async {
                    if (!_formKey.currentState!.validate()) return;
                    final phone = phoneController.text
                        .trim()
                        .replaceAll(RegExp(r'\s+'), '');
                    final ok = await authController.sendOtp(phone);
                    if (ok) {
                      Get.to(() => OtpVerifyScreen(phone: phone));
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
