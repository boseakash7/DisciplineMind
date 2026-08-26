import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'api_reponse.dart';

/// Stored from Set-Cookie on auth responses; sent on later form posts.
const String _kSessionCookieStorageKey = 'dm_session_cookie';

class ApiService extends GetxService {
  String _friendlyError(dynamic e, String endpoint) {
    debugPrint('[ApiService Error] $endpoint -> $e');
    final s = e.toString().toLowerCase();
    if (s.contains('socket') || s.contains('network') || s.contains('connection') || s.contains('failed host lookup')) {
      return 'Unable to connect to server. Please check your internet connection.';
    }
    if (s.contains('timeout')) {
      return 'Request timed out. Please try again.';
    }
    return 'Something went wrong. Please try again.';
  }

  // GET request
  Future<ApiResponse<dynamic>> get(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, String>? queryParameters,
  }) async {
    try {
      final uri = Uri.parse(
        endpoint.startsWith('http') ? endpoint : "${ApiConfig.baseUrl}$endpoint",
      ).replace(queryParameters: queryParameters);

      final response = await http.get(
        uri,
        headers: {...ApiConfig.defaultHeaders, ...?headers},
      );

      return _processResponse(response);
    } catch (e) {
      return ApiResponse.error(_friendlyError(e, endpoint));
    }
  }

  /// POST request to messages API (disciplinedminds.in) with form-data
  Future<ApiResponse<dynamic>> postMessagesForm(
    String endpoint,
    Map<String, String> fields, {
    Map<String, String>? headers,
  }) async {
    try {
      final uri = Uri.parse(
        endpoint.startsWith('http') ? endpoint : "${ApiConfig.baseUrl}$endpoint",
      );
      final request = http.MultipartRequest('POST', uri);
      if (headers != null) request.headers.addAll(headers);
      for (final e in fields.entries) {
        request.fields[e.key] = e.value;
      }
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      return _processResponse(response);
    } catch (e) {
      return ApiResponse.error(_friendlyError(e, endpoint));
    }
  }

  /// POST request with multipart/form-data (matches Postman --form).
  /// Use for endpoints that expect multipart (e.g. FCM sync).
  Future<ApiResponse<dynamic>> postMultipartForm(
    String endpoint,
    Map<String, String> fields, {
    Map<String, String>? headers,
    bool usePersistedSessionCookie = true,
  }) async {
    try {
      final uri = Uri.parse(
        endpoint.startsWith('http') ? endpoint : "${ApiConfig.baseUrl}$endpoint",
      );
      final request = http.MultipartRequest('POST', uri);
      if (headers != null) request.headers.addAll(headers);
      final merged = {
        if (usePersistedSessionCookie) ..._persistedSessionCookies(),
      };
      if (merged.isNotEmpty) {
        request.headers['Cookie'] = merged.entries
            .map((e) => "${e.key}=${e.value}")
            .join("; ");
      }
      for (final e in fields.entries) {
        request.fields[e.key] = e.value;
      }
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      persistSessionFromResponse(response);
      debugPrint("API Response: ${response.body}");
      return _processResponse(response);
    } catch (e) {
      return ApiResponse.error(_friendlyError(e, endpoint));
    }
  }

  static Map<String, String> _persistedSessionCookies() {
    final id = GetStorage().read<String>(_kSessionCookieStorageKey);
    if (id == null || id.isEmpty) return {};
    return {'session': id};
  }

  static void persistSessionFromResponse(http.Response response) {
    final raw = response.headers['set-cookie'];
    if (raw == null || raw.isEmpty) return;
    final match = RegExp(r'session=([^;,\s]+)').firstMatch(raw);
    if (match != null) {
      GetStorage().write(_kSessionCookieStorageKey, match.group(1));
    }
  }

  static void clearPersistedSessionCookie() {
    GetStorage().remove(_kSessionCookieStorageKey);
  }

  /// POST request with form-data (x-www-form-urlencoded)
  Future<ApiResponse<dynamic>> postFormData(
    String endpoint,
    Map<String, String> fields, {
    Map<String, String>? headers,
    Map<String, String>? cookies,
    bool usePersistedSessionCookie = true,
  }) async {
    try {
      final Map<String, String> mergedCookies = {
        if (usePersistedSessionCookie) ..._persistedSessionCookies(),
        ...?cookies,
      };

      // Build headers
      final Map<String, String> finalHeaders = {
        "Content-Type": "application/x-www-form-urlencoded",
        if (mergedCookies.isNotEmpty)
          "Cookie": mergedCookies.entries
              .map((e) => "${e.key}=${e.value}")
              .join("; "),
        if (headers != null) ...headers,
      };

      final uri = Uri.parse(
        endpoint.startsWith('http') ? endpoint : "${ApiConfig.baseUrl}$endpoint",
      );
      final response = await http.post(
        uri,
        headers: finalHeaders,
        body: fields, // Send form fields
      );

      persistSessionFromResponse(response);
      debugPrint("API Response: ${response.body}");

      return _processResponse(response);
    } catch (e) {
      return ApiResponse.error(_friendlyError(e, endpoint));
    }
  }

  /// PATCH request with JSON body
  Future<ApiResponse<dynamic>> patch(
    String endpoint,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
  }) async {
    try {
      final uri = Uri.parse(
        endpoint.startsWith('http') ? endpoint : "${ApiConfig.baseUrl}$endpoint",
      );
      final response = await http.patch(
        uri,
        headers: {...ApiConfig.defaultHeaders, ...?headers},
        body: jsonEncode(body),
      );

      return _processResponse(response);
    } catch (e) {
      return ApiResponse.error(_friendlyError(e, endpoint));
    }
  }

  /// Process API response (success & error)
  /// Strips leading HTML (e.g. <br /> from PHP) before parsing JSON.
  ApiResponse<dynamic> _processResponse(http.Response response) {
    try {
      String body = response.body.trim();
      // Strip leading HTML/whitespace that breaks jsonDecode
      final jsonStart = body.indexOf('{');
      if (jsonStart > 0) {
        body = body.substring(jsonStart);
      }
      final jsonResponse = jsonDecode(body);

      if (jsonResponse is Map && jsonResponse['status'] == 'ok') {
        return ApiResponse.success(jsonResponse);
      } else if (jsonResponse is Map && jsonResponse.containsKey('payload')) {
        final payload = jsonResponse['payload'];
        final msg = payload?.toString().trim() ?? '';
        // If payload is clean string without html tags or stack traces, show it
        if (msg.isNotEmpty && !msg.startsWith('<') && !msg.contains('Exception:')) {
          return ApiResponse.error(msg);
        }
        return ApiResponse.error('Something went wrong. Please try again.');
      } else {
        return ApiResponse.error('Something went wrong. Please try again.');
      }
    } catch (e, stack) {
      debugPrint('[ApiService] Response parse error: $e\nStatus: ${response.statusCode}\nBody: ${response.body}\n$stack');
      if (response.statusCode >= 500) {
        return ApiResponse.error('Server error. Please try again later.');
      }
      if (response.statusCode == 404) {
        return ApiResponse.error('Service unavailable. Please try again later.');
      }
      return ApiResponse.error('Something went wrong. Please try again.');
    }
  }
}
