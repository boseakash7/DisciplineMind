import 'dart:convert';
import 'dart:io';

import 'package:discipline_mind/services/api/api_config.dart';
import 'package:discipline_mind/services/api/api_url.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class OpenAiSttService {
  static String? _cachedOpenAiKey;

  /// Fetches OpenAI API key dynamically from backend config endpoint (`config/keys`).
  /// Caches key in memory, re-fetching only if null, empty, or [forceRefresh] is true.
  static Future<String?> getApiKey({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _cachedOpenAiKey != null &&
        _cachedOpenAiKey!.isNotEmpty) {
      return _cachedOpenAiKey;
    }

    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}${ApiUrl.configKeys}');
      final response = await http.get(
        uri,
        headers: ApiConfig.defaultHeaders,
      );

      if (response.statusCode == 200) {
        String body = response.body.trim();
        final jsonStart = body.indexOf('{');
        if (jsonStart > 0) {
          body = body.substring(jsonStart);
        }
        final jsonResponse = jsonDecode(body) as Map<String, dynamic>;
        if (jsonResponse['status'] == 'ok' &&
            jsonResponse['payload'] is Map<String, dynamic>) {
          final payload = jsonResponse['payload'] as Map<String, dynamic>;
          final key = payload['openai_key'] as String?;
          if (key != null && key.isNotEmpty) {
            _cachedOpenAiKey = key;
            return key;
          }
        }
      } else {
        debugPrint(
          'OpenAiSttService: Failed to fetch config keys. Status ${response.statusCode}',
        );
      }
    } catch (e, stack) {
      debugPrint('OpenAiSttService: Exception fetching API key: $e\n$stack');
    }
    return _cachedOpenAiKey;
  }

  /// Sends the recorded audio file to OpenAI Whisper API and returns text.
  static Future<String?> transcribeAudio(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        debugPrint('OpenAiSttService: Audio file does not exist at $filePath');
        return null;
      }

      String? key = await getApiKey();
      if (key == null || key.isEmpty) {
        debugPrint('OpenAiSttService: OpenAI API key is missing');
        return null;
      }

      var response = await _performTranscription(filePath, key);
      // If unauthorized (401), force refresh key and retry once
      if (response.statusCode == 401) {
        debugPrint('OpenAiSttService: Key unauthorized (401). Retrying with fresh key...');
        key = await getApiKey(forceRefresh: true);
        if (key != null && key.isNotEmpty) {
          response = await _performTranscription(filePath, key);
        }
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final text = data['text'] as String?;
        return text?.trim();
      } else {
        debugPrint(
          'OpenAiSttService: API Error ${response.statusCode} - ${response.body}',
        );
        return null;
      }
    } catch (e, stack) {
      debugPrint('OpenAiSttService Exception: $e\n$stack');
      return null;
    }
  }

  static Future<http.Response> _performTranscription(
    String filePath,
    String key,
  ) async {
    final uri = Uri.parse('https://api.openai.com/v1/audio/transcriptions');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $key'
      ..fields['model'] = 'whisper-1'
      ..files.add(await http.MultipartFile.fromPath('file', filePath));

    final streamedResponse = await request.send();
    return http.Response.fromStream(streamedResponse);
  }
}

