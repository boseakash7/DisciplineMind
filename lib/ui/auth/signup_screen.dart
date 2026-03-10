import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../common/app_colors.dart';
import '../../controller/auth_controller.dart';
import '../widgets/common_widgets.dart';

class SignUpScreen extends StatelessWidget {
  final authController = Get.find<AuthController>();

  SignUpScreen({super.key});

  // Text controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  // Form key
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
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

              /// Brand Icon
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
                "Join the Disciplined Minds community",
                style: TextStyle(color: AppColors.textGrey),
              ),
              const SizedBox(height: 32),

              /// Full Name
              CustomTextField(
                controller: nameController,
                hint: "Full Name",
                icon: Icons.person_outline,
                validator: (val) => val == null || val.isEmpty
                    ? "Please enter your full name"
                    : null,
              ),
              const SizedBox(height: 16),

              /// Email
              CustomTextField(
                controller: emailController,
                hint: "Email Address",
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (val) {
                  if (val == null || val.isEmpty)
                    return "Please enter your email";
                  if (!GetUtils.isEmail(val)) return "Enter a valid email";
                  return null;
                },
              ),
              const SizedBox(height: 16),

              /// Phone
              /// Phone
              CustomTextField(
                controller: phoneController,
                hint: "Phone Number",
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,

                maxLength: 10, // ✅ limit input to 10 digits

                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return "Please enter your phone number";
                  }

                  if (val.length != 10) {
                    return "Phone number must be exactly 10 digits";
                  }

                  if (!GetUtils.isNumericOnly(val)) {
                    return "Only digits are allowed";
                  }

                  return null;
                },
              ),

              // CustomTextField(
              //   controller: phoneController,
              //   hint: "Phone Number",
              //   icon: Icons.phone_outlined,
              //   keyboardType: TextInputType.phone,
              //   validator: (val) => val == null || val.isEmpty
              //       ? "Please enter your phone number"
              //       : null,
              // ),
              const SizedBox(height: 16),

              /// Password
              CustomTextField(
                controller: passwordController,
                hint: "Password",
                icon: Icons.lock_outline,
                isPassword: true,
                validator: (val) => val == null || val.isEmpty
                    ? "Please enter your password"
                    : null,
              ),
              const SizedBox(height: 16),

              /// Confirm Password
              CustomTextField(
                controller: confirmPasswordController,
                hint: "Confirm Password",
                icon: Icons.lock_clock_outlined,
                isPassword: true,
                validator: (val) {
                  if (val == null || val.isEmpty)
                    return "Please confirm your password";
                  if (val != passwordController.text)
                    return "Passwords do not match";
                  return null;
                },
              ),
              const SizedBox(height: 32),

              /// Sign Up Button
              Obx(
                () => PrimaryButton(
                  text: authController.isLoading.value
                      ? "Signing Up..."
                      : "SIGN UP",
                  onPressed: authController.isLoading.value
                      ? null
                      : () {
                          if (_formKey.currentState!.validate()) {
                            authController.signUp(
                              fullname: nameController.text.trim(),
                              email: emailController.text.trim(),
                              password: passwordController.text.trim(),
                              phone: phoneController.text.trim(),
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
