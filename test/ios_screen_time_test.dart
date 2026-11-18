import 'package:discipline_mind/services/ios_screen_time.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('screen_time');
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('denied permission does not open the app picker', () async {
    final calls = <String>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      return false;
    });
    expect(await IosScreenTime.ensureSelectedApps(), isFalse);
    expect(calls, ['isAuthorized']);
  });

  test('cancelled selection cannot complete setup', () async {
    messenger.setMockMethodCallHandler(channel, (call) async =>
        call.method == 'isAuthorized');
    expect(await IosScreenTime.ensureSelectedApps(), isFalse);
  });

  test('picker success requires a saved app token', () async {
    messenger.setMockMethodCallHandler(channel, (call) async =>
        call.method != 'hasSelectedApps');
    expect(await IosScreenTime.ensureSelectedApps(), isFalse);
  });

  test('native schedule failure is reported as failure', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      throw PlatformException(code: 'SCHEDULE_FAILED');
    });
    expect(await IosScreenTime.enableRestrictions(), isFalse);
  });

  test('missing native unblock result is not reported as success', () async {
    messenger.setMockMethodCallHandler(channel, (call) async => null);
    expect(await IosScreenTime.unblockAll(), isFalse);
  });

  test('temporary broker access requires native confirmation', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'allowSelectedAppsTemporarily');
      return null;
    });
    expect(await IosScreenTime.allowSelectedAppsTemporarily(), isFalse);
    messenger.setMockMethodCallHandler(channel, (call) async => true);
    expect(await IosScreenTime.allowSelectedAppsTemporarily(), isTrue);
  });
}
