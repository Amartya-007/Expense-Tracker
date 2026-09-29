import 'package:expensetracker/services/ai/query_spec.dart';

class RuleBasedFallback {
  static QuerySpec parse(String query) {
    final lower = query.toLowerCase().trim();

    // Balance intent
    if (lower.contains('balance') || lower.contains('how much money do i have') || lower.contains('bank accounts')) {
      return QuerySpec(intent: 'balance');
    }

    // Budget status
    if (lower.contains('budget') || lower.contains('over budget') || lower.contains('limit')) {
      return QuerySpec(intent: 'budget_status');
    }

    // Savings goals
    if (lower.contains('goal') || lower.contains('saving') || lower.contains('target')) {
      return QuerySpec(intent: 'goal_progress');
    }

    // Recurring bills / subscriptions
    if (lower.contains('bill') || lower.contains('subscription') || lower.contains('emi') || lower.contains('upcoming')) {
      return QuerySpec(intent: 'recurring_bills');
    }

    // Income intent
    if (lower.contains('income') || lower.contains('received') || lower.contains('earned') || lower.contains('salary')) {
      final categories = <String>[];
      if (lower.contains('salary')) categories.add('Salary');
      if (lower.contains('freelance')) categories.add('Freelance');
      return QuerySpec(
        intent: 'sum',
        type: 'income',
        categories: categories,
      );
    }

    // Category or Merchant extraction
    final categories = <String>[];
    if (lower.contains('food') || lower.contains('dining') || lower.contains('restaurant') || lower.contains('swiggy') || lower.contains('zomato')) {
      categories.add('Food & Dining');
    }
    if (lower.contains('grocery') || lower.contains('groceries')) categories.add('Groceries');
    if (lower.contains('transport') || lower.contains('uber') || lower.contains('ola') || lower.contains('cab')) {
      categories.add('Transport');
    }
    if (lower.contains('shopping') || lower.contains('amazon') || lower.contains('flipkart')) {
      categories.add('Shopping');
    }
    if (lower.contains('bill') || lower.contains('utility') || lower.contains('electricity')) {
      categories.add('Bills & Utilities');
    }

    final merchants = <String>[];
    if (lower.contains('amazon')) merchants.add('Amazon');
    if (lower.contains('swiggy')) merchants.add('Swiggy');
    if (lower.contains('zomato')) merchants.add('Zomato');
    if (lower.contains('uber')) merchants.add('Uber');
    if (lower.contains('ola')) merchants.add('Ola');
    if (lower.contains('netflix')) merchants.add('Netflix');

    String intent = 'sum';
    if (lower.contains('average') || lower.contains('avg')) intent = 'average';
    if (lower.contains('count') || lower.contains('how many')) intent = 'count';
    if (lower.contains('breakdown') || lower.contains('by category')) {
      intent = 'breakdown';
      return QuerySpec(intent: 'breakdown', type: 'expense', groupBy: 'category', limit: 10);
    }
    if (lower.contains('list') || lower.contains('show') || lower.contains('what did i spend')) {
      intent = 'list';
    }

    return QuerySpec(
      intent: intent,
      type: 'expense',
      categories: categories,
      merchants: merchants,
      limit: 10,
    );
  }
}
