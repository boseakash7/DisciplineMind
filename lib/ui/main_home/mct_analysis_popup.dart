import 'package:discipline_mind/common/app_colors.dart';
import 'package:discipline_mind/model/mct_plan_notification_model.dart';
import 'package:flutter/material.dart';

Future<void> showMctAnalysisPopup(
  BuildContext context, {
  required MctPlanNotification notification,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      final isDark = Theme.of(dialogContext).brightness == Brightness.dark;
      final textColor = isDark ? Colors.white : const Color(0xFF10122D);
      final secondaryTextColor = isDark
          ? Colors.white70
          : const Color(0xFF4E5368);
      final sectionBackground = isDark
          ? AppColors.primary.withValues(alpha: 0.16)
          : const Color(0xFFF1EEFF);

      return Dialog(
        backgroundColor: isDark ? const Color(0xFF232327) : Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420, maxHeight: 650),
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 53, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (notification.title.isNotEmpty) ...[
                      Text(
                        notification.title,
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    if (notification.body.isNotEmpty) ...[
                      Text(
                        notification.body,
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          color: secondaryTextColor,
                          fontSize: 15,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],
                    ...notification.sections.map(
                      (section) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(18, 16, 18, 17),
                          decoration: BoxDecoration(
                            color: sectionBackground,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (section.heading.isNotEmpty)
                                Text(
                                  section.heading,
                                  textAlign: TextAlign.left,
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    height: 1.2,
                                  ),
                                ),
                              if (section.heading.isNotEmpty &&
                                  section.content.isNotEmpty)
                                const SizedBox(height: 9),
                              if (section.content.isNotEmpty)
                                Text(
                                  section.content,
                                  textAlign: TextAlign.left,
                                  style: TextStyle(
                                    color: secondaryTextColor,
                                    fontSize: 14,
                                    height: 1.45,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                      'OK',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 2,
                right: 2,
                child: IconButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  icon: const Icon(Icons.close_rounded),
                  color: textColor,
                  tooltip: null,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
