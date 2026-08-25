import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../common/v2_app_colors.dart';
import '../../controllers/v2_auth_controller.dart';
import '../widgets/v2_widgets.dart';

class V2SignUpScreen extends StatefulWidget {
  final String? lockedPhone;

  const V2SignUpScreen({super.key, this.lockedPhone});

  @override
  State<V2SignUpScreen> createState() => _V2SignUpScreenState();
}

class _V2SignUpScreenState extends State<V2SignUpScreen> {
  final V2AuthController authController = Get.isRegistered<V2AuthController>()
      ? Get.find<V2AuthController>()
      : Get.put(V2AuthController());

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    if (widget.lockedPhone != null && widget.lockedPhone!.isNotEmpty) {
      _phoneController.text = widget.lockedPhone!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPhoneLocked = widget.lockedPhone != null && widget.lockedPhone!.isNotEmpty;

    return Scaffold(
      backgroundColor: V2AppColors.white,
      appBar: AppBar(
        backgroundColor: V2AppColors.white,
        elevation: 0,
        leading: const BackButton(color: V2AppColors.textBlack),
        title: const Text(
          "Create ZENO AI Account",
          style: TextStyle(
            color: V2AppColors.textBlack,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [
                        V2AppColors.primary,
                        V2AppColors.primaryLight,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: V2AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.auto_awesome_rounded, size: 38, color: Colors.white),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Join ZENO AI",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: V2AppColors.textBlack,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Fill in your details to register",
                  style: TextStyle(color: V2AppColors.textGrey, fontSize: 14),
                ),
                const SizedBox(height: 28),

                // Full Name
                V2CustomTextField(
                  controller: _nameController,
                  hint: "Full Name",
                  icon: Icons.person_outline,
                  validator: (val) =>
                      val == null || val.trim().isEmpty ? "Please enter your full name" : null,
                ),
                const SizedBox(height: 16),

                // Email
                V2CustomTextField(
                  controller: _emailController,
                  hint: "Email Address",
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return "Please enter your email";
                    }
                    if (!GetUtils.isEmail(val.trim())) return "Enter a valid email";
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password
                V2PasswordField(
                  controller: _passwordController,
                  hint: "Password",
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return "Please enter a password";
                    }
                    if (val.trim().length < 6) {
                      return "Password must be at least 6 characters";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Phone
                V2CustomTextField(
                  controller: _phoneController,
                  hint: "Phone Number",
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  readOnly: isPhoneLocked,
                  maxLength: 15,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return "Please enter your phone number";
                    }
                    final digits = val.replaceAll(RegExp(r'\D'), '');
                    if (digits.length < 10) {
                      return "Enter a valid 10-digit phone number";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Submit Button
                Obx(
                  () => V2PrimaryButton(
                    text: "SIGN UP",
                    color: V2AppColors.primary,
                    isLoading: authController.isLoading.value,
                    onPressed: () async {
                      if (!_formKey.currentState!.validate()) return;
                      await authController.register(
                        fullname: _nameController.text.trim(),
                        email: _emailController.text.trim(),
                        password: _passwordController.text.trim(),
                        phone: _phoneController.text.trim(),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // Link to Login
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Already have an account? ",
                      style: TextStyle(color: V2AppColors.textGrey, fontSize: 14),
                    ),
                    GestureDetector(
                      onTap: () => Get.back(),
                      child: const Text(
                        "Sign In",
                        style: TextStyle(
                          color: V2AppColors.primaryDark,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
