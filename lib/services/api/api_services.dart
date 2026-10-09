import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'api_reponse.dart';
import '../app_diagnostic_logger.dart';

/// Stored from Set-Cookie on auth responses; sent on later form posts.
const String _kSessionCookieStorageKey = 'dm_session_cookie';

class ApiService extends GetxService {
  void _logRequest({
    required String method,
    required String endpoint,
    Map<String, dynamic> data = const {},
    String? fileField,
    String? fileName,
  }) {
    unawaited(
      AppDiagnosticLogger.logApiRequest(
        method: method,
        endpoint: endpoint,
        data: data,
        fileField: fileField,
        fileName: fileName,
      ),
    );
  }

  String _friendlyError(dynamic e, String endpoint) {
    debugPrint('[ApiService Error] $endpoint -> $e');
    unawaited(
      AppDiagnosticLogger.log(
        event: 'API_ERROR',
        data: {'Endpoint': endpoint, 'Error': e.toString()},
      ),
    );
    final s = e.toString().toLowerCase();
    if (s.contains('socket') ||
        s.contains('network') ||
        s.contains('connection') ||
        s.contains('failed host lookup')) {
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
        endpoint.startsWith('http')
            ? endpoint
            : "${ApiConfig.getBaseUrl(endpoint)}$endpoint",
      ).replace(queryParameters: queryParameters);
      _logRequest(
        method: 'GET',
        endpoint: endpoint,
        data: queryParameters ?? const {},
      );

      final response = await http
          .get(uri, headers: {...ApiConfig.defaultHeaders, ...?headers})
          .timeout(const Duration(seconds: 10));

      return _processResponse(response, endpoint: endpoint);
    } catch (e) {
      return ApiResponse.error(_friendlyError(e, endpoint));
    }
  }

  /// POST request with JSON body
  Future<ApiResponse<dynamic>> postJson(
    String endpoint,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
  }) async {
    try {
      final uri = Uri.parse(
        endpoint.startsWith('http')
            ? endpoint
            : "${ApiConfig.getBaseUrl(endpoint)}$endpoint",
      );
      _logRequest(method: 'POST', endpoint: endpoint, data: body);
      final response = await http.post(
        uri,
        headers: {
          ...ApiConfig.defaultHeaders,
          'Content-Type': 'application/json',
          ...?headers,
        },
        body: jsonEncode(body),
      );
      return _processResponse(response, endpoint: endpoint);
    } catch (e) {
      return ApiResponse.error(_friendlyError(e, endpoint));
    }
  }

  /// POST request to messages API
  Future<ApiResponse<dynamic>> postMessagesForm(
    String endpoint,
    Map<String, String> fields, {
    Map<String, String>? headers,
    bool usePersistedSessionCookie = true,
  }) async {
    try {
      final uri = Uri.parse(
        endpoint.startsWith('http')
            ? endpoint
            : "${ApiConfig.getBaseUrl(endpoint)}$endpoint",
      );
      _logRequest(
        method: 'POST',
        endpoint: endpoint,
        data: Map<String, dynamic>.from(fields),
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
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 15),
      );
      final response = await http.Response.fromStream(streamedResponse);
      return _processResponse(response, endpoint: endpoint);
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
        endpoint.startsWith('http')
            ? endpoint
            : "${ApiConfig.getBaseUrl(endpoint)}$endpoint",
      );
      _logRequest(
        method: 'POST',
        endpoint: endpoint,
        data: Map<String, dynamic>.from(fields),
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
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 15),
      );
      final response = await http.Response.fromStream(streamedResponse);
      persistSessionFromResponse(response);
      debugPrint("API Response: ${response.body}");
      return _processResponse(response, endpoint: endpoint);
    } catch (e) {
      return ApiResponse.error(_friendlyError(e, endpoint));
    }
  }

  /// POST multipart form data with a file attachment.
  ///
  /// This is intentionally separate from the regular form helpers because
  /// callers need to upload the file bytes as `MultipartFile` rather than as
  /// a string field.
  Future<ApiResponse<dynamic>> postMultipartFile(
    String endpoint,
    Map<String, String> fields, {
    required String fileField,
    required String filePath,
    Map<String, String>? headers,
    bool usePersistedSessionCookie = true,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return ApiResponse.error('The recording is no longer available.');
      }

      final uri = Uri.parse(
        endpoint.startsWith('http')
            ? endpoint
            : "${ApiConfig.getBaseUrl(endpoint)}$endpoint",
      );
      _logRequest(
        method: 'POST',
        endpoint: endpoint,
        data: Map<String, dynamic>.from(fields),
        fileField: fileField,
        fileName: File(filePath).uri.pathSegments.last,
      );
      final request = http.MultipartRequest('POST', uri);
      if (headers != null) request.headers.addAll(headers);

      final cookies = <String, String>{
        if (usePersistedSessionCookie) ..._persistedSessionCookies(),
      };
      if (cookies.isNotEmpty) {
        request.headers['Cookie'] = cookies.entries
            .map((e) => '${e.key}=${e.value}')
            .join('; ');
      }

      request.fields.addAll(fields);
      request.files.add(await http.MultipartFile.fromPath(fileField, filePath));

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 60),
      );
      final response = await http.Response.fromStream(streamedResponse);
      persistSessionFromResponse(response);
      return _processResponse(response, endpoint: endpoint);
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
        endpoint.startsWith('http')
            ? endpoint
            : "${ApiConfig.getBaseUrl(endpoint)}$endpoint",
      );
      _logRequest(
        method: 'POST',
        endpoint: endpoint,
        data: Map<String, dynamic>.from(fields),
      );
      final response = await http
          .post(
            uri,
            headers: finalHeaders,
            body: fields, // Send form fields
          )
          .timeout(const Duration(seconds: 10));

      persistSessionFromResponse(response);
      debugPrint("API Response: ${response.body}");

      return _processResponse(response, endpoint: endpoint);
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
        endpoint.startsWith('http')
            ? endpoint
            : "${ApiConfig.getBaseUrl(endpoint)}$endpoint",
      );
      _logRequest(method: 'PATCH', endpoint: endpoint, data: body);
      final response = await http.patch(
        uri,
        headers: {...ApiConfig.defaultHeaders, ...?headers},
        body: jsonEncode(body),
      );

      return _processResponse(response, endpoint: endpoint);
    } catch (e) {
      return ApiResponse.error(_friendlyError(e, endpoint));
    }
  }

  /// Process API response (success & error)
  /// Strips leading HTML (e.g. <br /> from PHP) before parsing JSON.
  ApiResponse<dynamic> _processResponse(
    http.Response response, {
    required String endpoint,
  }) {
    ApiResponse<dynamic> result;
    Map<String, dynamic>? parsedResponse;

    try {
      String body = response.body.trim();
      // Strip leading HTML/whitespace that breaks jsonDecode.
      if (!body.startsWith('{') && !body.startsWith('[')) {
        final jsonStart = body.indexOf('{');
        if (jsonStart >= 0) {
          body = body.substring(jsonStart);
        } else {
          throw const FormatException('Response is not JSON');
        }
      }

      final decoded = jsonDecode(body);
      if (decoded is Map) {
        parsedResponse = Map<String, dynamic>.from(decoded);
      }

      if (parsedResponse != null && parsedResponse['status'] == 'ok') {
        result = ApiResponse.success(parsedResponse);
      } else if (parsedResponse != null &&
          parsedResponse.containsKey('payload')) {
        final payload = parsedResponse['payload'];
        final msg = payload?.toString().trim() ?? '';
        if (msg.isNotEmpty &&
            !msg.startsWith('<') &&
            !msg.contains('Exception:')) {
          result = ApiResponse.error(msg);
        } else {
          result = ApiResponse.error('Something went wrong. Please try again.');
        }
      } else {
        result = ApiResponse.error('Something went wrong. Please try again.');
      }
    } catch (e, stack) {
      debugPrint(
        '[ApiService] Response parse error: $e\nStatus: ${response.statusCode}\nBody: ${response.body}\n$stack',
      );
      if (response.statusCode >= 500) {
        result = ApiResponse.error('Server error. Please try again later.');
      } else if (response.statusCode == 404) {
        result = ApiResponse.error(
          'Service unavailable. Please try again later.',
        );
      } else {
        result = ApiResponse.error('Something went wrong. Please try again.');
      }
    }

    unawaited(
      AppDiagnosticLogger.logApiResponse(
        endpoint: endpoint,
        httpStatus: response.statusCode,
        isSuccess: result.isSuccess,
        apiStatus: parsedResponse?['status']?.toString(),
        message: parsedResponse?['message']?.toString() ?? result.errorMessage,
        responseBody: parsedResponse ?? response.body,
      ),
    );
    return result;
  }
}
