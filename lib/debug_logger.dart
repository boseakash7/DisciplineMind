import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Sends debug logs to the ingest endpoint for debugging.
/// Uses 10.0.2.2 for emulator (host localhost).
void debugLog(String location, String message, Map<String, dynamic> data,
    {String? hypothesisId}) {
  if (!Platform.isAndroid) return;
  // #region agent log
  try {
    http
        .post(
          Uri.parse(
              'http://10.0.2.2:7248/ingest/e91b23e2-3ebc-4597-9ee6-167d6340adc4'),
          headers: {
            'Content-Type': 'application/json',
            'X-Debug-Session-Id': '3df9d5',
          },
          body: jsonEncode({
            'sessionId': '3df9d5',
            'location': location,
            'message': message,
            'data': data,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
            if (hypothesisId != null) 'hypothesisId': hypothesisId,
          }),
        )
        .timeout(const Duration(seconds: 2))
        .catchError((_) => Future<http.Response>.value(http.Response('', 200)));
  } catch (_) {}
  // #endregion
}
