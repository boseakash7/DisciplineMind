import 'dart:async';

import 'package:discipline_mind/services/api/api_reponse.dart';
import 'package:discipline_mind/services/api/api_services.dart';
import 'package:discipline_mind/services/dmt_levels_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class PendingLevelsApi extends ApiService {
  final response = Completer<ApiResponse<dynamic>>();
  int calls = 0;

  @override
  Future<ApiResponse<dynamic>> get(String endpoint, {
    Map<String, String>? headers,
    Map<String, String>? queryParameters,
  }) {
    calls++;
    return response.future;
  }
}

void main() {
  tearDown(() => Get.reset());

  test('refresh defers loading updates and shares a pending API request', () async {
    final api = Get.put<ApiService>(PendingLevelsApi()) as PendingLevelsApi;
    final service = DmtLevelsService();
    final first = service.refreshLevels();
    final second = service.refreshLevels();
    expect(identical(first, second), isTrue);
    expect(service.isLoadingLevels.value, isFalse);
    await Future<void>.delayed(Duration.zero);
    expect(service.isLoadingLevels.value, isTrue);
    expect(api.calls, 1);
    api.response.complete(ApiResponse.success({
      'status': 'ok',
      'payload': [
        {'id': 1, 'code': 'BM', 'name': 'Believe Mode'},
        {'id': 2, 'code': 'AM', 'name': 'Apply Mode'},
        {'id': 3, 'code': 'LM', 'name': 'Leap Mode'},
      ],
    }));
    expect(await first, isTrue);
    expect(service.levels.map((level) => level.code), ['BM', 'AM', 'LM']);
    expect(service.isLoadingLevels.value, isFalse);
  });

  test('failed request clears loader without alternate endpoint retries', () async {
    final api = Get.put<ApiService>(PendingLevelsApi()) as PendingLevelsApi;
    final service = DmtLevelsService();
    final pending = service.refreshLevels();
    api.response.complete(ApiResponse.error('Network unavailable'));
    expect(await pending, isFalse);
    expect(service.isLoadingLevels.value, isFalse);
    expect(service.levelsError.value, 'Network unavailable');
    expect(api.calls, 1);
  });
}
