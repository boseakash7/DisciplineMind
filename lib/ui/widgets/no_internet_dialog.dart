import 'package:discipline_mind/common/app_colors.dart';
import 'package:discipline_mind/services/app_data_refresh_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

Future<void> showNoInternetDialog({Future<void> Function()? onRetry}) {
  if (Get.isDialogOpen == true) return Future.value();

  return Get.generalDialog<void>(
    barrierDismissible: true,
    barrierLabel: 'No Internet',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 320),
    pageBuilder: (context, animation, secondaryAnimation) {
      return _NoInternetDialog(onRetry: onRetry);
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curve = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curve,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.9, end: 1).animate(curve),
          child: child,
        ),
      );
    },
  );
}

class _NoInternetDialog extends StatelessWidget {
  const _NoInternetDialog({this.onRetry});

  final Future<void> Function()? onRetry;

  Future<void> _handleRetry() async {
    Get.back();
    final retry = onRetry ??
        () {
          final service = Get.isRegistered<AppDataRefreshService>()
              ? Get.find<AppDataRefreshService>()
              : Get.put(AppDataRefreshService(), permanent: true);
          return service.refreshAllTabs(force: true);
        };
    await retry();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 320,
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.18),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 72,
                width: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.18),
                      AppColors.primary.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(
                  Icons.wifi_off_rounded,
                  color: AppColors.primary,
                  size: 36,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'No Internet Connection',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textBlack,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Please check your mobile data or Wi-Fi and try again.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _handleRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Retry',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: Get.back,
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
