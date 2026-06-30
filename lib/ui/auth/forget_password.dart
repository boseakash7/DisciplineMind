import 'package:discipline_mind/ui/auth/set_new_password.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../common/app_colors.dart';
import '../../controller/auth_controller.dart';
import '../widgets/common_widgets.dart';

class ForgotPasswordScreen extends StatelessWidget {
  final authController = Get.find<AuthController>();

  ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            // Brand Icon
            const CircleAvatar(
              radius: 45,
              backgroundColor: AppColors.primary,
              child: Icon(Icons.psychology, size: 55, color: AppColors.white),
            ),
            const SizedBox(height: 16),
            const Text(
              "Forgot Password?",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textBlack,
              ),
            ),

            const SizedBox(height: 12),
            const Text(
              "No worries! Enter your email and we will send you a link to reset your password.",
              style: TextStyle(color: AppColors.textGrey, fontSize: 16),
            ),
            const SizedBox(height: 40),
             CustomTextField(
              hint: "Email Address",
              icon: Icons.email_outlined,
            ),
            const SizedBox(height: 32),
            PrimaryButton(
              text: "SEND RESET LINK",
              onPressed: () {
                Get.to(SetNewPasswordScreen());
              },
            ),
          ],
        ),
      ),
    );
  }
}
