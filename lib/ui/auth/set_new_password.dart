import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../common/app_colors.dart';
import '../../controller/auth_controller.dart';
import '../widgets/common_widgets.dart';

class SetNewPasswordScreen extends StatelessWidget {
  final authController = Get.find<AuthController>();

  SetNewPasswordScreen({super.key});

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
              "Set New Password",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textBlack,
              ),
            ),

            const SizedBox(height: 12),

            const Text(
              "Your new password must be different from previous used passwords.",
              style: TextStyle(color: AppColors.textGrey, fontSize: 16),
            ),
            const SizedBox(height: 40),
            const CustomTextField(
              hint: "New Password",
              icon: Icons.lock_outline,
              isPassword: true,
            ),
            const SizedBox(height: 16),
            const CustomTextField(
              hint: "Confirm New Password",
              icon: Icons.lock_reset_outlined,
              isPassword: true,
            ),
            const SizedBox(height: 32),
            PrimaryButton(text: "UPDATE PASSWORD", onPressed: () {}),
          ],
        ),
      ),
    );
  }
}
