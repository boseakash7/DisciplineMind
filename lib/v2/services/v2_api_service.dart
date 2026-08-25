import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

import '../config/v2_api_config.dart';
import 'v2_api_response.dart';

const String _kV2SessionCookieStorageKey = 'dm_v2_session_cookie';

class V2ApiService extends GetxService {
  V2ApiResponse<dynamic> _failureResponse(Object error) {
    if (kDebugMode) {
      debugPrint("V2ApiService Error: $error");
    }
    return V2ApiResponse.error("Network error: ${error.toString()}");
  }

  static Map<String, String> _persistedSessionCookies() {
    final id = GetStorage().read<String>(_kV2SessionCookieStorageKey);
    if (id == null || id.isEmpty) return {};
    return {'session': id};
  }

  static void persistSessionFromResponse(http.Response response) {
    final raw = response.headers['set-cookie'];
    if (raw == null || raw.isEmpty) return;
    final match = RegExp(r'session=([^;,\s]+)').firstMatch(raw);
    if (match != null) {
      GetStorage().write(_kV2SessionCookieStorageKey, match.group(1));
    }
  }

  static void clearPersistedSessionCookie() {
    GetStorage().remove(_kV2SessionCookieStorageKey);
  }

  /// GET request
  Future<V2ApiResponse<dynamic>> get(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, String>? queryParameters,
  }) async {
    try {
      final uri = Uri.parse(
        "${V2ApiConfig.baseUrl}$endpoint",
      ).replace(queryParameters: queryParameters);

      final response = await http.get(
        uri,
        headers: {...V2ApiConfig.defaultHeaders, ...?headers},
      );

      return _processResponse(response);
    } catch (e) {
      return _failureResponse(e);
    }
  }

  /// POST request with form-data (x-www-form-urlencoded)
  Future<V2ApiResponse<dynamic>> postFormData(
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

      final Map<String, String> finalHeaders = {
        "Content-Type": "application/x-www-form-urlencoded",
        if (mergedCookies.isNotEmpty)
          "Cookie": mergedCookies.entries
              .map((e) => "${e.key}=${e.value}")
              .join("; "),
        if (headers != null) ...headers,
      };

      final url = "${V2ApiConfig.baseUrl}$endpoint";
      if (kDebugMode) {
        debugPrint("V2ApiService POST $url with $fields");
      }

      final response = await http.post(
        Uri.parse(url),
        headers: finalHeaders,
        body: fields,
      );

      persistSessionFromResponse(response);

      if (kDebugMode) {
        debugPrint("V2ApiService Response: ${response.statusCode} - ${response.body}");
      }

      return _processResponse(response);
    } catch (e) {
      return _failureResponse(e);
    }
  }

  /// POST request with JSON body
  Future<V2ApiResponse<dynamic>> postJson(
    String endpoint,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("${V2ApiConfig.baseUrl}$endpoint"),
        headers: {...V2ApiConfig.defaultHeaders, ...?headers},
        body: jsonEncode(body),
      );

      return _processResponse(response);
    } catch (e) {
      return _failureResponse(e);
    }
  }

  /// Process API response
  V2ApiResponse<dynamic> _processResponse(http.Response response) {
    try {
      String body = response.body.trim();
      final jsonStart = body.indexOf('{');
      if (jsonStart > 0) {
        body = body.substring(jsonStart);
      }
      final jsonResponse = jsonDecode(body);

      if (jsonResponse is Map && jsonResponse['status'] == 'ok') {
        return V2ApiResponse.success(jsonResponse);
      } else if (jsonResponse is Map) {
        final payload = jsonResponse['payload'];
        return V2ApiResponse.error(payload?.toString() ?? 'Operation failed');
      } else {
        return V2ApiResponse.error('Unexpected response from server');
      }
    } catch (e) {
      return V2ApiResponse.error('Invalid server response format');
    }
  }
}
