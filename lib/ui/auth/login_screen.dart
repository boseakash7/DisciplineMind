import 'package:discipline_mind/common/app_colors.dart' show AppColors;
import 'package:discipline_mind/ui/auth/forget_password.dart';
import 'package:discipline_mind/ui/auth/signup_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/auth_controller.dart';
import '../widgets/common_widgets.dart';

class LoginScreen extends StatelessWidget {
  final AuthController authController = Get.put(AuthController());

  LoginScreen({super.key});

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>(); // Form key

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey, // Assign form key
          child: Column(
            children: [
              const SizedBox(height: 80),
              const CircleAvatar(
                radius: 45,
                backgroundColor: AppColors.primaryGreen,
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
              const SizedBox(height: 48),

              // Email
              CustomTextField(
                hint: "Email Address",
                icon: Icons.email_outlined,
                controller: emailController,
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return "Email cannot be empty";
                  if (!RegExp(
                    r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$",
                  ).hasMatch(value)) {
                    return "Enter a valid email";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Password
              CustomTextField(
                hint: "Password",
                icon: Icons.lock_outline,
                isPassword: true,
                controller: passwordController,
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return "Password cannot be empty";
                  if (value.length < 6)
                    return "Password must be at least 6 characters";
                  return null;
                },
              ),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Get.to(() => ForgotPasswordScreen()),
                  child: const Text(
                    "Forgot Password?",
                    style: TextStyle(color: AppColors.textGrey),
                  ),
                ),
              ),

              const SizedBox(height: 24),
              Obx(
                () => PrimaryButton(
                  text: "DM LOGIN",
                  isLoading: authController.isLoading.value,
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      authController.login(
                        emailController.text.trim(),
                        passwordController.text.trim(),
                      );
                    }
                  },
                ),
              ),

              const SizedBox(height: 24),
              GestureDetector(
                onTap: () => Get.to(() => SignUpScreen()),
                child: RichText(
                  text: const TextSpan(
                    text: "New here? ",
                    style: TextStyle(color: AppColors.textBlack),
                    children: [
                      TextSpan(
                        text: "CREATE ACCOUNT",
                        style: TextStyle(
                          color: AppColors.primaryGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
