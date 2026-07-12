import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

class NetworkErrorUtils {
  static const String noInternetMessage =
      'No internet connection. Please check your network and try again.';

  static const String genericMessage =
      'Something went wrong. Please try again.';

  static bool isNetworkError(Object? error) {
    if (error == null) return false;
    if (error is SocketException ||
        error is http.ClientException ||
        error is HandshakeException ||
        error is TimeoutException) {
      return true;
    }
    return _looksLikeNetworkError(error.toString());
  }

  static bool _looksLikeNetworkError(String text) {
    final value = text.toLowerCase();
    return value.contains('clientexception') ||
        value.contains('socketexception') ||
        value.contains('failed host lookup') ||
        value.contains('network is unreachable') ||
        value.contains('connection refused') ||
        value.contains('connection timed out') ||
        value.contains('connection closed') ||
        value.contains('no address associated with hostname') ||
        value.contains('software caused connection abort') ||
        value.contains('os error');
  }

  static String userMessage(Object? error, {String? fallback}) {
    if (error == null) return fallback ?? genericMessage;
    if (isNetworkError(error)) return noInternetMessage;
    return normalizeMessage(error.toString(), fallback: fallback);
  }

  static String normalizeMessage(String? raw, {String? fallback}) {
    if (raw == null || raw.trim().isEmpty) {
      return fallback ?? genericMessage;
    }

    var message = raw.trim();
    const prefixes = ['Exception: ', 'Error: '];
    for (final prefix in prefixes) {
      if (message.startsWith(prefix)) {
        message = message.substring(prefix.length).trim();
      }
    }

    if (_looksLikeNetworkError(message)) return noInternetMessage;
    if (message.startsWith('Invalid response format:')) {
      return 'Unable to read server response. Please try again.';
    }

    return message;
  }
}
