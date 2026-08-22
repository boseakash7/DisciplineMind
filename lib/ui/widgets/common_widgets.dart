import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../common/app_colors.dart';

class CustomTextField extends StatelessWidget {
  final String hint;
  IconData? icon;
  List<TextInputFormatter>? inputFormatters;
  final bool isPassword;
  Widget? prefixIcon;
  Widget? prefix;
  BorderSide ?borderSide;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final int? maxLength;
  final EdgeInsetsGeometry? contentPadding;

  CustomTextField({
    super.key,
    required this.hint,
    this.icon,
    this.prefix,
    this.prefixIcon,
    this.borderSide,
    this.isPassword = false,
    this.inputFormatters,
    this.controller,
    this.validator,
    this.maxLength,
    this.keyboardType = TextInputType.text,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextFormField(
      maxLength: maxLength,
      controller: controller,
      obscureText: isPassword,
      validator: validator,
      inputFormatters: inputFormatters,
      keyboardType: keyboardType,
      style: TextStyle(
        color: isDark ? Colors.white : AppColors.textBlack,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        hintText: hint,
        prefix: prefix,
        prefixIcon: prefixIcon,
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        filled: true,
        fillColor: isDark ? const Color(0xFF3C3C3A) : AppColors.backgroundGray, // Darker gray like screenshot
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), // Slightly more rounded
          borderSide:borderSide?? BorderSide.none, // Clean look like image
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:borderSide?? BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: borderSide?? BorderSide(color: Colors.blue, width: 1.5),
        ),
        errorStyle: const TextStyle(color: Colors.red, fontSize: 12),
        contentPadding:
            contentPadding ??
            const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
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
  final Gradient? gradient;
  final VoidCallback? onPressed;BorderSide? side;
  final double borderRadius;
  final double? textsize;
  final bool isLoading; // Added loading state
double? height;
double? width;
   PrimaryButton({
    super.key,
    required this.text,
    this.textsize,
    required this.onPressed,
    this.color = AppColors.actionRed,
    this.gradient,
    this.borderRadius = 8.0,
    this.height,
    this.side,
    this.width,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final child = isLoading
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
            style: TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.bold,
              fontSize: textsize ?? 16,
              letterSpacing: 1.2,
            ),
          );

    if (gradient != null) {
      return SizedBox(
        width: width ?? double.infinity,
        height: height ?? 55,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(borderRadius),
            border: side != null ? Border.fromBorderSide(side!) : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(borderRadius),
              onTap: isLoading ? null : onPressed,
              child: Center(child: child),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width:width?? double.infinity,
      height:height?? 55,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(side: side??BorderSide.none,
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          elevation: 0,
        ),
        onPressed: isLoading ? null : onPressed, // Disable button when loading
        child: child,
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
