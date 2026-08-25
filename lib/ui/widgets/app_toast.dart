import 'package:discipline_mind/common/app_colors.dart';
import 'package:discipline_mind/common/network_error_utils.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class AppToast {
  static void showToast(dynamic text) {
    final message = NetworkErrorUtils.normalizeMessage(text?.toString());
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: const Color(0xFF1F2937),
      textColor: Colors.white,
      fontSize: 15.0,
    );
  }

  static void showNoInternet() {
    Fluttertoast.showToast(
      msg: NetworkErrorUtils.noInternetMessage,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: AppColors.textBlack,
      textColor: Colors.white,
      fontSize: 15.0,
    );
  }

  static void showError(dynamic text) {
    showToast(text);
  }
}
