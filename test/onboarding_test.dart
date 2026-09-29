import 'package:expensetracker/models/user_profile.dart';
import 'package:expensetracker/providers/app_state.dart';
import 'package:expensetracker/screens/onboarding/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('legacy profiles are routed through the new onboarding once', () {
    final profile = UserProfile.fromJson({'isOnboarded': true});

    expect(profile.isOnboarded, isFalse);
    expect(profile.onboardingVersion, 0);
  });

  testWidgets('onboarding requires a name before optional setup steps', (
    tester,
  ) async {
    final state = AppState();

    await tester.pumpWidget(MaterialApp(home: OnboardingScreen(state: state)));

    expect(find.text('Welcome to RupeeCommand'), findsOneWidget);
    expect(find.text('Skip'), findsNothing);

    await tester.tap(find.text('Continue'));
    await tester.pump();
    expect(find.text('Please enter your name to continue.'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Test User');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Set your preferences'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
  });
}
