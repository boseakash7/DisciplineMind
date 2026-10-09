import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Small, local-only diagnostic log for support investigations.
///
/// The logger is intentionally best-effort: a file-system problem must never
/// affect the user's app. Entries are kept in one readable text file and old
/// entries are removed after [_retentionPeriod].
class AppDiagnosticLogger {
  AppDiagnosticLogger._();

  static String get _fileName {
    final now = DateTime.now();
    final d = now.day.toString().padLeft(2, '0');
    final m = now.month.toString().padLeft(2, '0');
    final y = (now.year % 100).toString().padLeft(2, '0');
    return '$d-$m-${y}_DM.txt';
  }
  static const _separator =
      '==================================================';
  static const _retentionPeriod = Duration(days: 3);

  static File? _file;
  static Future<void>? _initializing;
  static Future<void> _writeQueue = Future<void>.value();
  static bool? _lastOverlayPermission;
  static bool? _lastUsageStatsPermission;

  static Future<void> initialize() {
    return _initializing ??= _initialize();
  }

  static Future<void> _initialize() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      _file = File('${directory.path}${Platform.pathSeparator}$_fileName');
      if (!await _file!.exists()) {
        final legacyTxt = File('${directory.path}${Platform.pathSeparator}${_fileName.replaceAll('_DM.txt', '.txt')}');
        final legacyLog = File('${directory.path}${Platform.pathSeparator}${_fileName.replaceAll('_DM.txt', '.log')}');
        final legacy = File('${directory.path}${Platform.pathSeparator}discipline_mind_diagnostic.log');
        if (await legacyTxt.exists()) {
          await legacyTxt.rename(_file!.path);
        } else if (await legacyLog.exists()) {
          await legacyLog.rename(_file!.path);
        } else if (await legacy.exists()) {
          await legacy.rename(_file!.path);
        }
      }
      await _removeExpiredEntries();
    } catch (_) {
      _file = null;
    }
  }

  /// Returns the local diagnostic log path, when the logger is available.
  static Future<String?> getLogFilePath() async {
    await initialize();
    if (_file != null && !await _file!.exists()) {
      await _file!.create(recursive: true);
    }
    return _file?.path;
  }

  /// Writes one formatted event. This method is safe to call without await.
  static Future<void> log({
    required String event,
    Map<String, dynamic> data = const {},
  }) async {
    try {
      await initialize();
      final file = _file;
      if (file == null) return;

      _writeQueue = _writeQueue.then((_) async {
        try {
          final timestamp = _formatTimestamp(DateTime.now());
          final buffer = StringBuffer()
            ..writeln(_separator)
            ..writeln('$timestamp | ${event.toUpperCase()}');

          for (final entry in data.entries) {
            final value = _formatValue(entry.value);
            final lines = value.split('\n');
            buffer.writeln('${entry.key}: ${lines.first}');
            for (final line in lines.skip(1)) {
              buffer.writeln('  $line');
            }
          }

          buffer.writeln(_separator);
          await file.writeAsString(
            '${buffer.toString()}\n',
            mode: FileMode.append,
            flush: true,
          );
        } catch (_) {
          // A failed write must not poison the queue for later events.
        }
      });

      await _writeQueue;
    } catch (_) {
      // Diagnostics must never interrupt the application.
    }
  }

  static Future<void> logApiResponse({
    required String endpoint,
    required int httpStatus,
    required bool isSuccess,
    String? apiStatus,
    String? message,
    dynamic responseBody,
  }) {
    return log(
      event: 'API_RESPONSE',
      data: {
        'Endpoint': endpoint,
        'HTTP Status': httpStatus,
        'Result': isSuccess ? 'SUCCESS' : 'FAILURE',
        if (apiStatus != null && apiStatus.isNotEmpty) 'API Status': apiStatus,
        if (message != null && message.isNotEmpty) 'Message': message,
        if (responseBody != null) 'Response Body': responseBody,
      },
    );
  }

  static Future<void> logApiRequest({
    required String method,
    required String endpoint,
    Map<String, dynamic> data = const {},
    String? fileField,
    String? fileName,
  }) {
    return log(
      event: 'API_REQUEST',
      data: {
        'Method': method,
        'Endpoint': endpoint,
        if (data.isNotEmpty) 'Request Data': _sanitizeMap(data),
        if (fileField != null) 'File Field': fileField,
        if (fileName != null) 'File Name': fileName,
      },
    );
  }

  static Future<void> logProcessStatus({
    required String source,
    required String userId,
    required bool? processCreated,
    String? processId,
    String? processStatus,
    int? mindControlActive,
    String? processOverlaySetting,
    String? processUsageStatsSetting,
  }) {
    return log(
      event: 'PROCESS_STATUS',
      data: {
        'Source': source,
        'User ID': userId,
        'Process Created': processCreated == null
            ? 'UNKNOWN'
            : (processCreated ? 'YES' : 'NO'),
        if (processId != null && processId.isNotEmpty) 'Process ID': processId,
        if (processStatus != null && processStatus.isNotEmpty)
          'Process Status': processStatus,
        if (mindControlActive != null)
          'Mind Control Active': mindControlActive == 1 ? 'YES' : 'NO',
        if (processOverlaySetting != null)
          'Overlay Setting': _enabledLabel(processOverlaySetting),
        if (processUsageStatsSetting != null)
          'Usage Stats Setting': _enabledLabel(processUsageStatsSetting),
      },
    );
  }

  static Future<void> logPermissions({
    required String source,
    required bool overlay,
    required bool usageStats,
    String? platform,
  }) {
    _lastOverlayPermission = overlay;
    _lastUsageStatsPermission = usageStats;
    return log(
      event: 'PERMISSIONS',
      data: {
        'Source': source,
        if (platform != null) 'Platform': platform,
        'Overlay Permission': overlay ? 'ENABLED' : 'DISABLED',
        'Usage Stats Permission': usageStats ? 'ENABLED' : 'DISABLED',
      },
    );
  }

  static Future<void> logNewMessages({
    required String userId,
    required List<Map<String, dynamic>> messages,
    required String processState,
  }) {
    return log(
      event: 'NEW_MESSAGE',
      data: {
        'User ID': userId,
        'Message Count': messages.length,
        'Process At Message Time': processState,
        'Last Known Overlay Permission': _permissionLabel(
          _lastOverlayPermission,
        ),
        'Last Known Usage Stats Permission': _permissionLabel(
          _lastUsageStatsPermission,
        ),
        'Messages': messages,
      },
    );
  }

  static Future<void> logNotification({
    required String source,
    String? messageId,
    String? title,
    String? body,
    Map<String, dynamic> data = const {},
  }) {
    return log(
      event: 'NOTIFICATION_RECEIVED',
      data: {
        'Source': source,
        if (messageId != null && messageId.isNotEmpty) 'Message ID': messageId,
        if (title != null && title.isNotEmpty) 'Title': title,
        if (body != null && body.isNotEmpty) 'Body': body,
        if (data.isNotEmpty) 'Data': data,
      },
    );
  }

  static Future<void> _removeExpiredEntries() async {
    final file = _file;
    if (file == null || !await file.exists()) return;

    final content = await file.readAsString();
    if (content.trim().isEmpty) return;

    final now = DateTime.now();
    final kept = <String>[];
    for (final rawBlock in content.split(_separator)) {
      final block = rawBlock.trim();
      if (block.isEmpty) continue;

      final firstLine = block.split('\n').first.trim();
      final timestampText = firstLine.split(' | ').first.trim();
      final timestamp = DateTime.tryParse(timestampText);
      if (timestamp != null && now.difference(timestamp) <= _retentionPeriod) {
        kept.add(block);
      }
    }

    final updated = kept.isEmpty
        ? ''
        : '${kept.map((block) => '$_separator\n$block\n$_separator').join('\n')}\n';
    await file.writeAsString(updated, flush: true);
  }

  static String _enabledLabel(String value) {
    final normalized = value.trim().toLowerCase();
    return normalized == '1' || normalized == 'true' ? 'ENABLED' : 'DISABLED';
  }

  static Map<String, dynamic> _sanitizeMap(Map<String, dynamic> values) {
    const sensitiveKeys = {
      'password',
      'passcode',
      'otp',
      'token',
      'access_token',
      'refresh_token',
      'authorization',
      'cookie',
      'session',
      'session_id',
    };

    return values.map((key, value) {
      final normalizedKey = key.toLowerCase().replaceAll('-', '_');
      return MapEntry(
        key,
        sensitiveKeys.contains(normalizedKey)
            ? '[MASKED]'
            : _sanitizeValue(value),
      );
    });
  }

  static dynamic _sanitizeValue(dynamic value) {
    if (value is Map) {
      return _sanitizeMap(
        value.map((key, value) => MapEntry(key.toString(), value)),
      );
    }
    if (value is Iterable) {
      return value.map(_sanitizeValue).toList();
    }
    return value;
  }

  static String _permissionLabel(bool? value) {
    if (value == null) return 'UNKNOWN';
    return value ? 'ENABLED' : 'DISABLED';
  }

  static String _formatValue(dynamic value) {
    if (value is String) {
      return _truncate(value.replaceAll('\r\n', '\n').replaceAll('\r', '\n'));
    }
    try {
      return _truncate(jsonEncode(value));
    } catch (_) {
      return _truncate(value.toString());
    }
  }

  static String _truncate(String value) {
    const maxLength = 2500;
    if (value.length <= maxLength) return value;
    return '${value.substring(0, maxLength)}... [truncated]';
  }

  static String _formatTimestamp(DateTime value) {
    String two(int number) => number.toString().padLeft(2, '0');
    return '${value.year}-${two(value.month)}-${two(value.day)} '
        '${two(value.hour)}:${two(value.minute)}:${two(value.second)}';
  }
}
