import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:get_storage/get_storage.dart';
import 'package:discipline_mind/common/common.dart';
import 'package:discipline_mind/controller/chat_controller.dart';
import 'package:discipline_mind/model/login_reponse_model.dart';
import 'package:discipline_mind/services/api/api_services.dart';
import 'package:discipline_mind/services/api/api_reponse.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class FakeChatApi extends ApiService {
  final requests = <String>[];
  final responses = <Completer<ApiResponse<dynamic>>>[];

  @override
  Future<ApiResponse<dynamic>> postMessagesForm(String endpoint,
      Map<String, String> fields,
      {Map<String, String>? headers, bool usePersistedSessionCookie = true}) {
    requests.add(fields['user_id']!);
    final response = Completer<ApiResponse<dynamic>>();
    responses.add(response);
    return response.future;
  }

  void complete(int index, String text) {
    responses[index].complete(ApiResponse.success({
      'payload': [{'message_id': text, 'message_type': 'text', 'message': text}]
    }));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory storageDirectory;
  setUpAll(() async {
    storageDirectory = await Directory.systemTemp.createTemp('chat_session_test');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (_) async => storageDirectory.path,
    );
    await GetStorage.init();
  });
  tearDown(() {
    Get.delete<ChatController>(force: true);
    Get.reset();
    Common.userData.value = null;
  });

  test('Account changes reload chat and ignore the previous account response', () async {
    Common.userData.value = LoginResponseModel(payload: Payload(id: 'old'));
    final api = Get.put<ApiService>(FakeChatApi()) as FakeChatApi;
    final chat = Get.put(ChatController());
    expect(api.requests, ['old']);
    Common.userData.value = LoginResponseModel(payload: Payload(id: 'new'));
    expect(api.requests, ['old', 'new']);
    api.complete(1, 'new-message');
    await Future<void>.delayed(Duration.zero);
    api.complete(0, 'old-message');
    await Future<void>.delayed(Duration.zero);
    expect(chat.currentUserId, 'new');
    expect(chat.messages.single.messageId, 'new-message');
    expect(chat.isLoading.value, isFalse);
  });

  test('An older full load cannot overwrite a newer tab refresh', () async {
    Common.userData.value = LoginResponseModel(payload: Payload(id: 'user'));
    final api = Get.put<ApiService>(FakeChatApi()) as FakeChatApi;
    final chat = Get.put(ChatController());
    final refresh = chat.loadNewMessages(silent: false);
    api.complete(1, 'latest');
    await refresh;
    api.complete(0, 'stale');
    await Future<void>.delayed(Duration.zero);
    expect(chat.messages.single.messageId, 'latest');
  });
}
