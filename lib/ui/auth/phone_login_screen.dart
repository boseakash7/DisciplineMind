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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor = isDark ? const Color(0xFF121212) : AppColors.white;
    final textColor = isDark ? Colors.white : AppColors.textBlack;
    final secondaryTextColor = isDark ? Colors.grey.shade400 : AppColors.textGrey;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 80),
              Image.asset(!isDark?"assets/lightthemelogo.png": "assets/logo.png", height:!isDark?100: 120),
              // const SizedBox(height: 16),
              // Text(
              //   "Discipline Mind",
              //   style: TextStyle(
              //     fontSize: 24,
              //     fontWeight: FontWeight.bold,
              //     color: textColor,
              //   ),
              // ),
              const SizedBox(height: 8),
              Text(
                "Enter your phone number to sign in\nor create an account",
                textAlign: TextAlign.center,
                style: TextStyle(color: secondaryTextColor, fontSize: 14),
              ),
              const SizedBox(height: 48),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: CustomTextField(
                  hint: "Enter 10 digit mobile number",
                  borderSide: BorderSide(color: AppColors.bordercolor),
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(10),
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  icon: null,
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  prefixIcon: Padding(
                    padding:  EdgeInsets.only(left: 10,right: 4,bottom: 4),
                    child: Text(
                      "+91 |",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color:!isDark?Colors.black: Colors.white, // or textColor
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Phone number is required";
                    }
                    final digits = value.replaceAll(RegExp(r'\D'), '');
                    if (digits.length != 10) {
                      return "Enter a valid 10 digit phone number";
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 80),
              Obx(
                () => PrimaryButton(height: 45,width: MediaQuery.sizeOf(context).width*.84,
                  text: "SEND OTP",borderRadius: 100,
                  color: AppColors.primary,textsize: 20,
                  isLoading: authController.isLoading.value,
                  onPressed: () async {
                    if (!_formKey.currentState!.validate()) return;
                    final phone = phoneController.text.trim().replaceAll(RegExp(r'\s+'), '');
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