import 'package:flutter/foundation.dart';
import 'package:fluttertoast/fluttertoast.dart';

class AppToast {
  static showToast(dynamic text) {
    if (text == null) return;
    final raw = text.toString().trim();
    if (raw.isEmpty) return;

    final lower = raw.toLowerCase();

    // Check for technical / parsing / runtime exceptions or HTML traces
    if (lower.contains('formatexception') ||
        lower.contains('unexpected character') ||
        lower.contains('invalid response format') ||
        lower.contains('<!doctype') ||
        lower.contains('<html') ||
        lower.contains('error 404') ||
        lower.contains('error 500') ||
        lower.contains('rangeerror') ||
        lower.contains('typeerror') ||
        lower.contains('nosuchmethoderror') ||
        lower.contains('null check operator used on a null value')) {
      debugPrint('[AppToast Suppressed Technical Error]: $raw');
      return Fluttertoast.showToast(
        msg: 'Something went wrong. Please try again.',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        fontSize: 16.0,
      );
    }

    if (lower.contains('socketexception') ||
        lower.contains('clientexception') ||
        lower.contains('failed host lookup') ||
        lower.contains('network is unreachable')) {
      debugPrint('[AppToast Suppressed Network Error]: $raw');
      return Fluttertoast.showToast(
        msg: 'Unable to connect. Please check your internet connection.',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        fontSize: 16.0,
      );
    }

    if (lower.contains('timeoutexception')) {
      debugPrint('[AppToast Suppressed Timeout Error]: $raw');
      return Fluttertoast.showToast(
        msg: 'Request timed out. Please try again.',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        fontSize: 16.0,
      );
    }

    var displayMsg = raw;
    if (displayMsg.startsWith('Exception: ')) {
      displayMsg = displayMsg.substring('Exception: '.length);
    } else if (displayMsg.startsWith('Error: ')) {
      displayMsg = displayMsg.substring('Error: '.length);
    }

    return Fluttertoast.showToast(
      msg: displayMsg,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      fontSize: 16.0,
    );
  }
}
