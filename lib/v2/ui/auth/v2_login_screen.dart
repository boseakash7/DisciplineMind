import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../common/v2_app_colors.dart';
import '../../controllers/v2_auth_controller.dart';
import '../widgets/v2_widgets.dart';
import 'v2_otp_verify_screen.dart';
import 'v2_signup_screen.dart';

enum V2AuthMode { phoneOtp, emailPassword }

class V2LoginScreen extends StatefulWidget {
  const V2LoginScreen({super.key});

  @override
  State<V2LoginScreen> createState() => _V2LoginScreenState();
}

class _V2LoginScreenState extends State<V2LoginScreen> with SingleTickerProviderStateMixin {
  final V2AuthController authController = Get.isRegistered<V2AuthController>()
      ? Get.find<V2AuthController>()
      : Get.put(V2AuthController());

  V2AuthMode _selectedMode = V2AuthMode.phoneOtp;

  final TextEditingController _phoneController = TextEditingController();
  final _phoneFormKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _emailFormKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: V2AppColors.textBlack, size: 20),
          onPressed: () => Get.back(),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  V2AppColors.primary.withValues(alpha: 0.15),
                  V2AppColors.primaryDark.withValues(alpha: 0.12),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: V2AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bolt_rounded, size: 15, color: V2AppColors.primaryDark),
                SizedBox(width: 4),
                Text(
                  "V2 TEST ENGINE",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: V2AppColors.primaryDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),
              // App Brand Header
              Center(
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [
                        V2AppColors.primary,
                        V2AppColors.primaryDark,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: V2AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.auto_awesome_rounded, size: 42, color: Colors.white),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "ZENO AI",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                  color: V2AppColors.textBlack,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "Sign in to your ZENO AI account",
                textAlign: TextAlign.center,
                style: TextStyle(color: V2AppColors.textGrey, fontSize: 13.5),
              ),
              const SizedBox(height: 26),

              // --- Professional Segmented Selector ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildSelectorOption(
                        mode: V2AuthMode.phoneOtp,
                        title: "Phone OTP",
                        icon: Icons.sms_outlined,
                        activeIcon: Icons.mark_chat_read_rounded,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _buildSelectorOption(
                        mode: V2AuthMode.emailPassword,
                        title: "Email & Pass",
                        icon: Icons.mail_outline_rounded,
                        activeIcon: Icons.lock_person_rounded,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // --- Animated Context Box ---
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.0, 0.05),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: _selectedMode == V2AuthMode.phoneOtp
                    ? _buildPhoneOtpForm()
                    : _buildEmailPasswordForm(),
              ),

              const SizedBox(height: 28),

              // --- Bottom Sign Up Prompt ---
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "New to ZENO AI? ",
                      style: TextStyle(
                        color: V2AppColors.textGrey,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Get.to(() => const V2SignUpScreen()),
                      child: const Row(
                        children: [
                          Text(
                            "Create Account",
                            style: TextStyle(
                              color: V2AppColors.primaryDark,
                              fontWeight: FontWeight.bold,
                              fontSize: 13.5,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 15,
                            color: V2AppColors.primaryDark,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectorOption({
    required V2AuthMode mode,
    required String title,
    required IconData icon,
    required IconData activeIcon,
  }) {
    final isSelected = _selectedMode == mode;

    return GestureDetector(
      onTap: () {
        if (_selectedMode != mode) {
          setState(() {
            _selectedMode = mode;
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              size: 18,
              color: isSelected ? V2AppColors.primaryDark : V2AppColors.textGrey,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? V2AppColors.primaryDark : V2AppColors.textGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneOtpForm() {
    return Container(
      key: const ValueKey('phone_otp_form'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _phoneFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: V2AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.phone_android_rounded,
                    size: 18,
                    color: V2AppColors.primaryDark,
                  ),
                ),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Phone Verification",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: V2AppColors.textBlack,
                      ),
                    ),
                    Text(
                      "We'll send a 4-digit security code",
                      style: TextStyle(fontSize: 12, color: V2AppColors.textGrey),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            V2CustomTextField(
              hint: "Enter 10-digit mobile number",
              icon: Icons.phone_outlined,
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              maxLength: 15,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return "Mobile number is required";
                }
                final digits = value.replaceAll(RegExp(r'\D'), '');
                if (digits.length < 10) {
                  return "Enter a valid 10-digit number";
                }
                return null;
              },
            ),
            const SizedBox(height: 22),
            Obx(
              () => V2PrimaryButton(
                text: "SEND ONE-TIME PASSWORD",
                color: V2AppColors.primary,
                isLoading: authController.isLoading.value,
                onPressed: () async {
                  if (!_phoneFormKey.currentState!.validate()) return;
                  final phone = _phoneController.text.trim();
                  final payload = await authController.sendOtp(phone);
                  if (payload != null) {
                    Get.to(() => V2OtpVerifyScreen(phone: phone));
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailPasswordForm() {
    return Container(
      key: const ValueKey('email_password_form'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _emailFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: V2AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.lock_outline_rounded,
                    size: 18,
                    color: V2AppColors.primaryDark,
                  ),
                ),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Direct Account Access",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: V2AppColors.textBlack,
                      ),
                    ),
                    Text(
                      "Sign in with your registered credentials",
                      style: TextStyle(fontSize: 12, color: V2AppColors.textGrey),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            V2CustomTextField(
              hint: "Email address",
              icon: Icons.alternate_email_rounded,
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return "Email address is required";
                }
                if (!GetUtils.isEmail(value.trim())) {
                  return "Enter a valid email address";
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            V2PasswordField(
              hint: "Account password",
              controller: _passwordController,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return "Password is required";
                }
                return null;
              },
            ),
            const SizedBox(height: 22),
            Obx(
              () => V2PrimaryButton(
                text: "SIGN IN",
                color: V2AppColors.primary,
                isLoading: authController.isLoading.value,
                onPressed: () async {
                  if (!_emailFormKey.currentState!.validate()) return;
                  await authController.loginWithEmail(
                    email: _emailController.text.trim(),
                    password: _passwordController.text.trim(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
