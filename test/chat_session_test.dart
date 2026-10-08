import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:get_storage/get_storage.dart';
import 'package:discipline_mind/common/common.dart';
import 'package:discipline_mind/controller/chat_controller.dart';
import 'package:discipline_mind/model/chat_message_model.dart';
import 'package:discipline_mind/model/login_reponse_model.dart';
import 'package:discipline_mind/services/api/api_services.dart';
import 'package:discipline_mind/services/api/api_reponse.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class FakeChatApi extends ApiService {
  final requests = <String>[];
  final responses = <Completer<ApiResponse<dynamic>>>[];

  @override
  Future<ApiResponse<dynamic>> postMessagesForm(
    String endpoint,
    Map<String, String> fields, {
    Map<String, String>? headers,
    bool usePersistedSessionCookie = true,
  }) {
    requests.add(fields['user_id']!);
    final response = Completer<ApiResponse<dynamic>>();
    responses.add(response);
    return response.future;
  }

  void complete(int index, String text) {
    responses[index].complete(
      ApiResponse.success({
        'payload': [
          {'message_id': text, 'message_type': 'text', 'message': text},
        ],
      }),
    );
  }

  void completePayload(int index, List<Map<String, dynamic>> payload) {
    responses[index].complete(ApiResponse.success({'payload': payload}));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory storageDirectory;
  setUpAll(() async {
    storageDirectory = await Directory.systemTemp.createTemp(
      'chat_session_test',
    );
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

  test(
    'Account changes reload chat and ignore the previous account response',
    () async {
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
    },
  );

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

  test(
    'fomo_delete shows its text and silently refreshes away the old trade',
    () async {
      final oldTrade = <String, dynamic>{
        'message_id': '10',
        'message_type': 'trade',
        'entity_type': 'trade',
        'message': '',
        'timestamp': '2026-10-01T07:44:15.615Z',
        'payload': {
          'id': '1',
          'trade_uid': 'TvOB-mup8adixJO7433',
          'header': 'HDFCBANK',
          'symbol': 'HDFCBANK',
          'exchange': 'NSE',
          'entry_price': '716.00',
          'stop_loss': '710.00',
          'take_profit': '750.00',
          'current_price': '715.60',
          'action': 'add',
        },
      };
      final fomoDelete = <String, dynamic>{
        'message_id': '10',
        'message_type': 'fomo_delete',
        'entity_type': 'trade',
        'message':
            'Old published Trade is deleted to save your mind from FOMO.',
        'payload': oldTrade['payload'],
      };

      final parsedFomoDelete = chatMessagesFromJson(fomoDelete);
      expect(parsedFomoDelete, hasLength(1));
      expect(
        (parsedFomoDelete.single as SimpleTextMessage).text,
        contains('FOMO'),
      );

      Common.userData.value = LoginResponseModel(payload: Payload(id: 'user'));
      final api = Get.put<ApiService>(FakeChatApi()) as FakeChatApi;
      final chat = Get.put(ChatController());
      api.completePayload(0, [oldTrade]);
      await Future<void>.delayed(Duration.zero);
      expect(chat.messages, hasLength(2));

      final refresh = chat.loadNewMessages(silent: true);
      api.completePayload(1, [fomoDelete]);
      for (var i = 0; i < 5 && api.responses.length < 3; i++) {
        await Future<void>.delayed(Duration.zero);
      }
      expect(api.responses, hasLength(3));
      api.completePayload(2, [
        {
          'message_id': '11',
          'message_type': 'text',
          'message': 'Keep this message',
        },
        fomoDelete,
      ]);
      await refresh;

      expect(chat.messages, hasLength(2));
      expect(
        chat.messages.any(
          (message) =>
              message is SimpleTextMessage &&
              message.text.contains('Keep this message'),
        ),
        isTrue,
      );
      expect(
        chat.messages.any(
          (message) =>
              message is SimpleTextMessage && message.text.contains('FOMO'),
        ),
        isTrue,
      );
      expect(chat.isLoading.value, isFalse);
      expect(chat.isRefreshing.value, isFalse);
    },
  );

  test(
    'reused delete message id does not inherit superseded action state',
    () async {
      final oldTrade = <String, dynamic>{
        'message_id': '460',
        'message_type': 'trade',
        'entity_type': 'trade',
        'message': '',
        'payload': {
          'id': '16',
          'trade_uid': 'TvOB-muxti17d5GCJ7Z',
          'header': 'BSX261008P72500',
          'symbol': 'BSX261008P72500',
          'exchange': 'BSE',
          'entry_price': '275.00',
          'stop_loss': '225.00',
          'take_profit': '325.00',
          'current_price': '253.25',
          'action': 'add',
        },
      };
      final deleteTrade = <String, dynamic>{
        'message_id': '460',
        'message_type': 'button',
        'button_type': 'delete_button',
        'entity_type': 'trade',
        'action_taken': null,
        'message': 'Go to Trading APP and delete the Trade',
        'payload': {
          ...oldTrade['payload'] as Map<String, dynamic>,
          'action': 'delete',
        },
      };

      Common.userData.value = LoginResponseModel(payload: Payload(id: 'user'));
      final api = Get.put<ApiService>(FakeChatApi()) as FakeChatApi;
      final chat = Get.put(ChatController());
      api.completePayload(0, [oldTrade]);
      await Future<void>.delayed(Duration.zero);

      final refresh = chat.loadNewMessages(silent: true);
      api.completePayload(1, [deleteTrade]);
      await refresh;

      final current = chat.messages
          .whereType<NewTradeOpportunityMessage>()
          .single;
      expect(current.messageId, '460');
      expect(current.actionTaken, isNull);
      expect(current.action, 'delete');
      expect(current.buttonType, 'delete_button');
      expect(chat.isActionTakenFor(current), isFalse);
    },
  );

  test('mct_plan parses heading, title, body, and sections', () {
    final parsed = chatMessagesFromJson({
      'message_id': '218',
      'message_type': 'mct_plan',
      'heading': 'MCT plan for today',
      'message': "Here is your trading discipline audit for today's session.",
      'payload': {
        'title': 'MCT plan for today',
        'body': "Here is your trading discipline audit for today's session.",
        'sections': [
          {'heading': "Today's Behavior", 'content': 'Keep the process.'},
        ],
      },
    });

    expect(parsed, hasLength(1));
    final message = parsed.single as MctPlanMessage;
    expect(message.heading, 'MCT plan for today');
    expect(message.title, 'MCT plan for today');
    expect(message.body, contains('trading discipline audit'));
    expect(message.sections.single.heading, "Today's Behavior");
    expect(message.sections.single.content, 'Keep the process.');
  });
}
