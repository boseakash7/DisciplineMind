import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../common/app_colors.dart';
import '../../controller/auth_controller.dart';
import '../widgets/common_widgets.dart';

class SignUpScreen extends StatelessWidget {
  final authController = Get.find<AuthController>();

  /// When set (after OTP for a new number), phone is shown read-only.
  final String? lockedPhone;

  SignUpScreen({super.key, this.lockedPhone});

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final phoneLocked = lockedPhone != null && lockedPhone!.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: const Text(
          "Sign Up",
          style: TextStyle(color: AppColors.textBlack),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              const CircleAvatar(
                radius: 45,
                backgroundColor: AppColors.primary,
                child: Icon(Icons.psychology, size: 55, color: AppColors.white),
              ),
              const SizedBox(height: 16),
              const Text(
                "Create Account",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textBlack,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Join the Discipline Mind community",
                style: TextStyle(color: AppColors.textGrey),
              ),
              const SizedBox(height: 32),
              CustomTextField(
                controller: nameController,
                hint: "Full Name",
                icon: Icons.person_outline,
                validator: (val) => val == null || val.isEmpty
                    ? "Please enter your full name"
                    : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: emailController,
                hint: "Email Address",
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return "Please enter your email";
                  }
                  if (!GetUtils.isEmail(val)) return "Enter a valid email";
                  return null;
                },
              ),
              const SizedBox(height: 16),
              if (phoneLocked) ...[
                _LockedPhoneField(phone: lockedPhone!),
              ] else ...[
                CustomTextField(
                  controller: phoneController,
                  hint: "Phone Number",
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  maxLength: 15,
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return "Please enter your phone number";
                    }
                    final digits = val.replaceAll(RegExp(r'\D'), '');
                    if (digits.length < 10) {
                      return "Enter a valid phone number";
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 32),
              Obx(
                () => PrimaryButton(
                  text: authController.isLoading.value
                      ? "Signing Up..."
                      : "SIGN UP",
                  color: AppColors.primary,
                  onPressed: authController.isLoading.value
                      ? null
                      : () {
                          if (_formKey.currentState!.validate()) {
                            final phone = phoneLocked
                                ? lockedPhone!
                                    .trim()
                                    .replaceAll(RegExp(r'\s+'), '')
                                : phoneController.text
                                    .trim()
                                    .replaceAll(RegExp(r'\s+'), '');
                            authController.signUp(
                              fullname: nameController.text.trim(),
                              email: emailController.text.trim(),
                              phone: phone,
                            );
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

class _LockedPhoneField extends StatelessWidget {
  final String phone;

  const _LockedPhoneField({required this.phone});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Phone number",
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textGrey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.backgroundGray,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.phone_outlined, color: AppColors.primaryGreen),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  phone,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textBlack,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Icon(Icons.lock_outline, size: 20, color: AppColors.textGrey),
            ],
          ),
        ),
      ],
    );
  }
}
