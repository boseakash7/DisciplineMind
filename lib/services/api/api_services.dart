import 'dart:convert';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'api_reponse.dart';

class ApiService extends GetxService {
  // GET request
  Future<ApiResponse<dynamic>> get(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, String>? queryParameters,
  }) async {
    try {
      final uri = Uri.parse(
        "${ApiConfig.baseUrl}$endpoint",
      ).replace(queryParameters: queryParameters);

      final response = await http.get(
        uri,
        headers: {...ApiConfig.defaultHeaders, ...?headers},
      );

      return _processResponse(response);
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  /// POST request with multipart/form-data (matches Postman --form).
  /// Use for endpoints that expect multipart (e.g. FCM sync).
  Future<ApiResponse<dynamic>> postMultipartForm(
    String endpoint,
    Map<String, String> fields, {
    Map<String, String>? headers,
  }) async {
    try {
      final uri = Uri.parse("${ApiConfig.baseUrl}$endpoint");
      final request = http.MultipartRequest('POST', uri);
      if (headers != null) request.headers.addAll(headers);
      for (final e in fields.entries) {
        request.fields[e.key] = e.value;
      }
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      print("API Response: ${response.body}");
      return _processResponse(response);
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  /// POST request with form-data (x-www-form-urlencoded)
  Future<ApiResponse<dynamic>> postFormData(
    String endpoint,
    Map<String, String> fields, {
    Map<String, String>? headers,
    Map<String, String>? cookies,
  }) async {
    try {
      // Build headers
      final Map<String, String> finalHeaders = {
        "Content-Type": "application/x-www-form-urlencoded",
        if (cookies != null && cookies.isNotEmpty)
          "Cookie": cookies.entries
              .map((e) => "${e.key}=${e.value}")
              .join("; "),
        if (headers != null) ...headers,
      };

      final response = await http.post(
        Uri.parse("${ApiConfig.baseUrl}$endpoint"),
        headers: finalHeaders,
        body: fields, // Send form fields
      );

      print("API Response: ${response.body}");

      return _processResponse(response);
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  /// PATCH request with JSON body
  Future<ApiResponse<dynamic>> patch(
    String endpoint,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
  }) async {
    try {
      final response = await http.patch(
        Uri.parse("${ApiConfig.baseUrl}$endpoint"),
        headers: {...ApiConfig.defaultHeaders, ...?headers},
        body: jsonEncode(body),
      );

      return _processResponse(response);
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  /// Process API response (success & error)
  ApiResponse<dynamic> _processResponse(http.Response response) {
    try {
      final jsonResponse = jsonDecode(response.body);

      if (jsonResponse['status'] == 'ok') {
        return ApiResponse.success(jsonResponse);
      } else {
        return ApiResponse.error(jsonResponse['payload'].toString());
      }
    } catch (e) {
      return ApiResponse.error("Invalid response format: ${e.toString()}");
    }
  }
}
