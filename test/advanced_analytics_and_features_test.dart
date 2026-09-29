import 'package:flutter_test/flutter_test.dart';
import 'package:expensetracker/models/transaction.dart';
import 'package:expensetracker/services/spending_analytics_service.dart';
import 'package:expensetracker/features/transactions/data/custom_rules_repository.dart';
import 'package:expensetracker/utils/voice_parser.dart';

void main() {
  group('SpendingAnalyticsService Tests', () {
    test('detects spending anomaly when a transaction spikes above history', () {
      final now = DateTime.now();
      final historyTransactions = [
        TransactionItem(id: '1', type: TransactionType.expense, amount: 200, categoryId: 'c1', categoryName: 'Food & Dining', accountId: 'a1', accountName: 'Cash', merchant: 'Café', date: now.subtract(const Duration(days: 20))),
        TransactionItem(id: '2', type: TransactionType.expense, amount: 250, categoryId: 'c1', categoryName: 'Food & Dining', accountId: 'a1', accountName: 'Cash', merchant: 'Café', date: now.subtract(const Duration(days: 15))),
        TransactionItem(id: '3', type: TransactionType.expense, amount: 220, categoryId: 'c1', categoryName: 'Food & Dining', accountId: 'a1', accountName: 'Cash', merchant: 'Café', date: now.subtract(const Duration(days: 10))),
        // Spike today
        TransactionItem(id: '4', type: TransactionType.expense, amount: 2500, categoryId: 'c1', categoryName: 'Food & Dining', accountId: 'a1', accountName: 'Cash', merchant: 'Fine Dining', date: now),
      ];

      final anomalies = SpendingAnalyticsService.detectAnomalies(historyTransactions);
      expect(anomalies.isNotEmpty, isTrue);
      expect(anomalies.first.categoryName, 'Food & Dining');
      expect(anomalies.first.amount, 2500.0);
    });

    test('calculates savings projection correctly', () {
      final now = DateTime.now();
      final transactions = [
        TransactionItem(id: '10', type: TransactionType.income, amount: 50000, categoryId: 'c2', categoryName: 'Salary', accountId: 'a1', accountName: 'Bank', merchant: 'Employer', date: now),
        TransactionItem(id: '11', type: TransactionType.expense, amount: 10000, categoryId: 'c1', categoryName: 'Rent', accountId: 'a1', accountName: 'Bank', merchant: 'Landlord', date: now),
      ];

      final projection = SpendingAnalyticsService.calculateSavingsProjection(transactions, initialIncomeGoal: 0);
      expect(projection.currentIncome, 50000.0);
      expect(projection.currentExpenses, 10000.0);
      expect(projection.actualSavings, 40000.0);
    });
  });

  group('CustomRulesRepository Tests', () {
    test('validates regex patterns correctly', () {
      expect(CustomRulesRepository.validateRegex(r'SWIGGY.*(\d+)'), isNull);
      expect(CustomRulesRepository.validateRegex(r'[unclosed'), isNotNull);
    });
  });

  group('VoiceParser Tests', () {
    test('parses expense speech sentence accurately', () {
      final result = VoiceParser.parse('Spent 250 on coffee via UPI');
      expect(result.type, TransactionType.expense);
      expect(result.amount, 250.0);
      expect(result.categorySuggestion, 'Food & Dining');
    });

    test('parses income speech sentence accurately', () {
      final result = VoiceParser.parse('Received 30000 salary');
      expect(result.type, TransactionType.income);
      expect(result.amount, 30000.0);
      expect(result.categorySuggestion, 'Salary');
    });
  });
}
