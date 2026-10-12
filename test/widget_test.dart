import 'dart:io';

import 'package:discipline_mind/ui/main_home/more_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final tempDir = await Directory.systemTemp.createTemp('widget_test_dir');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => tempDir.path,
        );
    await GetStorage.init();
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('MoreScreen renders menu tiles and Share Diagnostic Log option', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const GetMaterialApp(
        home: MoreScreen(),
      ),
    );

    expect(find.text('Trading Process'), findsOneWidget);
    expect(find.text('Privacy Policy'), findsOneWidget);
    expect(find.text('Share Diagnostic Log'), findsOneWidget);
    expect(
      find.text('Send recent app logs via WhatsApp, email, etc.'),
      findsOneWidget,
    );
    expect(find.text('Logout'), findsOneWidget);
  });
}
