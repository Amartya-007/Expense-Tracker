import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expensetracker/providers/app_state.dart';
import 'package:expensetracker/screens/to_review/to_review_screen.dart';

void main() {
  testWidgets('SMS simulation dialog fits a compact phone width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(home: ToReviewScreen(state: AppState())),
    );
    await tester.tap(find.byTooltip('Simulate Bank SMS Capture'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Simulate Incoming SMS'), findsOneWidget);
  });
}
