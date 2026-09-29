import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expensetracker/models/account.dart';
import 'package:expensetracker/models/transaction.dart';
import 'package:expensetracker/providers/app_state.dart';
import 'package:expensetracker/screens/home/home_screen.dart';

void main() {
  testWidgets('home money and cash-flow summaries fit a compact phone width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final state = AppState()
      ..accounts = [
        Account(
          id: 'bank',
          name: 'Bank',
          type: AccountType.bank,
          balance: 98765.43,
        ),
      ]
      ..transactions = [
        _transaction('income', TransactionType.income, 15000, 'Salary'),
        _transaction('expense', TransactionType.expense, 5000, 'Food'),
      ];

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(state: state, onNavigateToTab: (_) {}),
      ),
    );
    await tester.pumpAndSettle();

    final renderFlexOverflows = <Object>[];
    Object? exception;
    do {
      exception = tester.takeException();
      if (exception != null &&
          exception.toString().contains('RenderFlex overflowed')) {
        renderFlexOverflows.add(exception);
      }
    } while (exception != null);
    expect(renderFlexOverflows, isEmpty);
  });
}

TransactionItem _transaction(
  String id,
  TransactionType type,
  double amount,
  String category,
) => TransactionItem(
  id: id,
  type: type,
  amount: amount,
  categoryId: category.toLowerCase(),
  categoryName: category,
  accountId: 'bank',
  accountName: 'Bank',
  merchant: category,
  date: DateTime.now(),
);
