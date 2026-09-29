import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:expensetracker/models/budget.dart';
import 'package:expensetracker/models/transaction.dart';
import 'package:expensetracker/providers/app_state.dart';
import 'package:expensetracker/screens/budgets/budgets_screen.dart';
import 'package:expensetracker/services/database_service.dart';
import 'package:expensetracker/core/database/app_database.dart';

Future<AppState> _createState() async {
  SharedPreferences.setMockInitialValues({});
  const smsChannel = MethodChannel('expensetracker/sms');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(smsChannel, (call) async => <dynamic>[]);
  final state = AppState();
  await state.init(await DatabaseService.init(customDb: AppDatabase.openInMemory()));
  return state;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'monthly overview counts only spending in active monthly budget categories',
    () async {
      final state = await _createState();
      state.budgets = [
        Budget(
          id: 'food_budget',
          categoryId: 'cat_food',
          categoryName: 'Food & Dining',
          limitAmount: 5000,
        ),
        Budget(
          id: 'subscription_budget',
          categoryId: 'cat_sub',
          categoryName: 'Subscriptions',
          limitAmount: 5000,
        ),
      ];
      state.transactions = [
        _expense(
          'transport',
          'cat_transport',
          'Transport',
          2500,
          DateTime.now(),
        ),
        _expense('food', 'cat_food', 'Food & Dining', 1200, DateTime.now()),
        _expense(
          'last_month_food',
          'cat_food',
          'Food & Dining',
          900,
          DateTime(DateTime.now().year, DateTime.now().month - 1, 20),
        ),
      ];

      expect(state.monthlyBudgetLimit, 10000);
      expect(state.monthlyBudgetedSpent, 1200);
      expect(state.monthlyBudgetSpendingByCategory['cat_food'], 1200);
      expect(state.monthlyBudgetSpendingByCategory['cat_sub'], 0);
    },
  );

  testWidgets('category budget limit can be edited after creation', (
    tester,
  ) async {
    final state = await _createState();
    state.budgets = [
      Budget(
        id: 'food_budget',
        categoryId: 'cat_food',
        categoryName: 'Food & Dining',
        limitAmount: 5000,
      ),
    ];

    await tester.pumpWidget(MaterialApp(home: BudgetsScreen(state: state)));
    final editButton = find.byTooltip('Edit Food & Dining budget');
    await tester.ensureVisible(editButton);
    await tester.pumpAndSettle();
    await tester.tap(editButton);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '6500');
    await tester.tap(find.text('Save Budget'));
    await tester.pumpAndSettle();

    expect(state.budgets.single.limitAmount, 6500);
  });
}

TransactionItem _expense(
  String id,
  String categoryId,
  String categoryName,
  double amount,
  DateTime date,
) => TransactionItem(
  id: id,
  type: TransactionType.expense,
  amount: amount,
  categoryId: categoryId,
  categoryName: categoryName,
  accountId: 'acc_cash',
  accountName: 'Cash',
  merchant: 'Test',
  date: date,
);
