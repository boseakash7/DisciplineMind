import 'package:discipline_mind/ui/main_home/trade_process.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Setup branches preserve capital and custom rules', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const MaterialApp(
        home: TradingProcessScreen(userId: 'test', skipWelcome: true),
      ),
    );
    Future<void> next() async {
      await tester.ensureVisible(find.text('Next'));
      await tester.tap(find.text('Next').hitTestable());
      await tester.pumpAndSettle();
    }

    await tester.tap(find.text('Options'));
    await next();
    await tester.tap(find.text('Nifty 50'));
    await next();
    expect(find.text('Step 3 of 7'), findsOneWidget);
    expect(find.textContaining('Coming Soon'), findsNothing);
    await next();
    expect(find.text('Step 4 of 7'), findsOneWidget);
    expect(find.text('Risk Management'), findsOneWidget);
    await tester.tap(find.byType(TextField));
    await tester.pump();
    await tester.enterText(find.byType(TextField), '20000');
    await tester.pump();
    expect(find.text('\u20b9400'), findsOneWidget);
    await next();
    expect(find.text('Step 5 of 7'), findsOneWidget);
    await tester.tap(
      find.byIcon(Icons.arrow_back_ios_new_rounded).hitTestable(),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byIcon(Icons.arrow_back_ios_new_rounded).hitTestable(),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create My Own Setup'));
    await next();
    expect(find.text('Trading Capital & Rules'), findsOneWidget);
    expect(find.text('Risk Management'), findsNothing);
    expect(find.text('20,000'), findsOneWidget);
  });
  testWidgets('Usage permission actions stay visible while content scrolls', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const MaterialApp(
        home: TradingProcessScreen(userId: 'test', skipWelcome: true),
      ),
    );
    final pages = tester.widget<PageView>(find.byType(PageView));
    pages.controller!.jumpToPage(7);
    await tester.pumpAndSettle();
    final button = find.text('Enable Permission').hitTestable();
    expect(button, findsOneWidget);
    expect(find.text('Not Now').hitTestable(), findsOneWidget);
    final before = tester.getCenter(button);
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();
    expect(tester.getCenter(button), before);
  });
}
