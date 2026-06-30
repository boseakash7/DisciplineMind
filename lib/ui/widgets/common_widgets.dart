import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../common/app_colors.dart';

class CustomTextField extends StatelessWidget {
  final String hint;
   IconData? icon;
  List<TextInputFormatter>? inputFormatters;
  final bool isPassword;
  Widget? prefixIcon;Widget? prefix;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType keyboardType; // Added keyboardType
  final int? maxLength;

   CustomTextField({
    super.key,
    required this.hint,
     this.icon,this.prefix,
     this.prefixIcon,
    this.isPassword = false,
    this.inputFormatters,
    this.controller,
    this.validator,
    this.maxLength,
    this.keyboardType = TextInputType.text, // Default keyboard type
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      maxLength: maxLength,
      controller: controller,
      obscureText: isPassword,
      validator: validator,inputFormatters:inputFormatters,
      keyboardType: keyboardType, // Set keyboard type
      decoration: InputDecoration(
        hintText: hint,prefix:prefix ,
        prefixIcon:prefixIcon?? Icon( icon, color: AppColors.primaryGreen),
        filled: true,
        fillColor: AppColors.backgroundGray,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        errorStyle: const TextStyle(color: Colors.red, fontSize: 12),
      ),
    );
  }
}

class RuleInputField extends StatelessWidget {
  final String label;
  final String? hint;
  final Function(String)? onChanged;
  final TextInputType keyboardType;

  const RuleInputField({
    super.key,
    required this.label,
    this.hint,
    this.onChanged,
    this.keyboardType = const TextInputType.numberWithOptions(decimal: true),
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(width: 5),
            const Icon(Icons.info_outline, size: 18, color: Colors.grey),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          onChanged: onChanged,
          keyboardType: keyboardType,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ],
          decoration: InputDecoration(
            hintText: hint,
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10),
          ),
        ),
      ],
    );
  }
}

class CommonDropdownField extends StatelessWidget {
  final String label;
  final String hint;
  final List<String> options;
  final String? value;
  final Function(String?) onChanged;

  const CommonDropdownField({
    super.key,
    required this.label,
    required this.hint,
    required this.options,
    this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(width: 5),
            const Icon(Icons.info_outline, size: 18, color: Colors.grey),
          ],
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12),
          ),
          hint: Text(hint),
          icon: const Icon(Icons.keyboard_arrow_down),
          items: options.map((String val) {
            return DropdownMenuItem<String>(value: val, child: Text(val));
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

// Red/Green Navigation Button
class NavButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final Color color;

  const NavButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = Colors.redAccent,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: Colors.green, width: 2),
        ),
      ),
      child: Text(label, style: TextStyle(color: Colors.white)),
    );
  }
}

// Reusable Square Action Button (matches the DM ACTION style)

class PrimaryButton extends StatelessWidget {
  final String text;
  final Color color;
  final VoidCallback? onPressed;
  final double borderRadius;
  final bool isLoading; // Added loading state

  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.color = AppColors.actionRed,
    this.borderRadius = 8.0,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          elevation: 0,
        ),
        onPressed: isLoading ? null : onPressed, // Disable button when loading
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: AppColors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                text,
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 1.2,
                ),
              ),
      ),
    );
  }
}

Future<void> showGenericPopup({
  required BuildContext context,
  required String heading,
  required String subtitle,
  String? noButtonTitle,
  required String yesButtonTitle,
  required Future<void> Function() onYesPress,
  required VoidCallback onNoPress,
}) async {
  bool isLoading = false;

  await showDialog(
    barrierDismissible: false,
    context: context,
    builder: (BuildContext dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.85,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        heading,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF232323),
                        ),
                      ),
                      const SizedBox(height: 12),

                      Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF616161),
                        ),
                      ),
                      const SizedBox(height: 20),

                      /// ✅ YES BUTTON
                      GestureDetector(
                        onTap: isLoading
                            ? null
                            : () async {
                                setState(() => isLoading = true);

                                // ✅ Close dialog first
                                Navigator.of(context).pop();

                                // ✅ Run async logic after dialog is removed
                                Future.microtask(() async {
                                  await onYesPress();
                                });
                              },
                        child: Container(
                          height: 50,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                            ),
                          ),
                          child: Center(
                            child: isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : Text(
                                    yesButtonTitle,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      /// ✅ NO BUTTON
                      if (noButtonTitle != null)
                        GestureDetector(
                          onTap: () {
                            onNoPress();

                            if (Navigator.canPop(dialogContext)) {
                              Navigator.of(dialogContext).pop();
                            }
                          },
                          child: Container(
                            height: 50,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFFF44336),
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                noButtonTitle,
                                style: const TextStyle(
                                  color: Color(0xFFF44336),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}
