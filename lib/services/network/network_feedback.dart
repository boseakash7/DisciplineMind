import 'package:discipline_mind/common/network_error_utils.dart';
import 'package:discipline_mind/ui/widgets/app_toast.dart';
import 'package:discipline_mind/ui/widgets/no_internet_dialog.dart';
import 'package:get/get.dart';

/// Shows user-friendly offline feedback (toast + debounced dialog).
class NetworkFeedback {
  NetworkFeedback._();

  static DateTime? _lastDialogShownAt;
  static const Duration _dialogCooldown = Duration(seconds: 10);

  static void onNoInternet() {
    AppToast.showNoInternet();
    _maybeShowDialog();
  }

  static void _maybeShowDialog() {
    final now = DateTime.now();
    if (_lastDialogShownAt != null &&
        now.difference(_lastDialogShownAt!) < _dialogCooldown) {
      return;
    }
    if (Get.isDialogOpen == true) return;

    _lastDialogShownAt = now;
    showNoInternetDialog();
  }
}

/// Normalize API/service error text before showing in UI.
String friendlyErrorMessage(Object? error, {String? fallback}) {
  return NetworkErrorUtils.userMessage(error, fallback: fallback);
}

String friendlyApiMessage(String? message, {String? fallback}) {
  return NetworkErrorUtils.normalizeMessage(message, fallback: fallback);
}
