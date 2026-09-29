import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:expensetracker/providers/app_state.dart';
import 'package:expensetracker/screens/shared/shared_expenses_screen.dart';
import 'package:expensetracker/services/database_service.dart';
import 'package:expensetracker/core/database/app_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('creates an equal split including the person who paid', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    const smsChannel = MethodChannel('expensetracker/sms');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(smsChannel, (call) async => <dynamic>[]);
    final state = AppState();
    await state.init(await DatabaseService.init(customDb: AppDatabase.openInMemory()));
    state.profile.name = 'Me';

    await tester.pumpWidget(
      AnimatedBuilder(
        animation: state,
        builder: (context, _) =>
            MaterialApp(home: SharedExpensesScreen(state: state)),
      ),
    );

    await tester.tap(find.byTooltip('Add shared expense'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Tea');
    await tester.enterText(find.byType(TextFormField).at(1), '100');
    await tester.enterText(
      find.byType(TextFormField).at(3),
      'Ashu, Rahu, Anju',
    );
    await tester.tap(find.text('Create Split'));
    await tester.pumpAndSettle();

    final expense = state.sharedExpenses.single;
    expect(expense.paidBy, 'Me');
    expect(expense.participants, ['Me', 'Ashu', 'Rahu', 'Anju']);
    expect(expense.splits, {'Me': 25, 'Ashu': 25, 'Rahu': 25, 'Anju': 25});
    expect(expense.settledStatus['Me'], isTrue);
    expect(expense.settledStatus['Ashu'], isFalse);
  });
}
