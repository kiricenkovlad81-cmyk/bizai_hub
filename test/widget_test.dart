import 'package:bizai_hub/main.dart';
import 'package:bizai_hub/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App opens on the dashboard with today\'s metrics', (tester) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final state = AppState()..boot();
    await tester.pumpWidget(BizAiApp(state: state));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('BizAI'), findsOneWidget);
    expect(find.text('Выручка за сегодня'), findsOneWidget);
    expect(state.convs.length, 8);
  });
}
