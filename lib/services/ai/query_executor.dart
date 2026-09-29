import 'package:expensetracker/models/transaction.dart';
import 'package:expensetracker/models/account.dart';
import 'package:expensetracker/models/budget.dart';
import 'package:expensetracker/models/goal.dart';
import 'package:expensetracker/models/recurring_bill.dart';
import 'package:expensetracker/services/ai/query_spec.dart';

class QueryExecutionResult {
  final double totalAmount;
  final int count;
  final double average;
  final List<TransactionItem> transactions;
  final Map<String, double> breakdown;
  final List<Budget> budgets;
  final List<Goal> goals;
  final List<RecurringBill> recurringBills;
  final List<Account> accounts;
  final String summaryText;

  QueryExecutionResult({
    this.totalAmount = 0.0,
    this.count = 0,
    this.average = 0.0,
    this.transactions = const [],
    this.breakdown = const {},
    this.budgets = const [],
    this.goals = const [],
    this.recurringBills = const [],
    this.accounts = const [],
    this.summaryText = '',
  });
}

class QueryExecutor {
  static QueryExecutionResult execute({
    required QuerySpec spec,
    required List<TransactionItem> transactions,
    required List<Account> accounts,
    required List<Budget> budgets,
    required List<Goal> goals,
    required List<RecurringBill> recurringBills,
  }) {
    // 1. Handle special intents
    if (spec.intent == 'balance') {
      final matchedAccounts = _filterAccounts(accounts, spec.accounts);
      final totalBal = matchedAccounts.fold(0.0, (sum, a) => sum + a.balance);
      return QueryExecutionResult(
        totalAmount: totalBal,
        count: matchedAccounts.length,
        accounts: matchedAccounts,
        summaryText: matchedAccounts.length == 1
            ? 'Balance for ${matchedAccounts.first.name} is ₹${matchedAccounts.first.balance.toStringAsFixed(2)}.'
            : 'Total available balance across ${matchedAccounts.length} accounts is ₹${totalBal.toStringAsFixed(2)}.',
      );
    }

    if (spec.intent == 'budget_status') {
      final matchedBudgets = budgets.where((b) {
        if (spec.categories.isEmpty) return true;
        return spec.categories.any((c) => b.categoryName.toLowerCase().contains(c.toLowerCase()));
      }).toList();
      return QueryExecutionResult(
        budgets: matchedBudgets,
        summaryText: matchedBudgets.isEmpty
            ? 'No matching active budgets found.'
            : 'Found ${matchedBudgets.length} budget(s).',
      );
    }

    if (spec.intent == 'goal_progress') {
      return QueryExecutionResult(
        goals: goals,
        summaryText: 'You have ${goals.length} savings goal(s) active.',
      );
    }

    if (spec.intent == 'recurring_bills') {
      return QueryExecutionResult(
        recurringBills: recurringBills.where((b) => !b.isCompleted && !b.isPaused).toList(),
        summaryText: 'Found ${recurringBills.where((b) => !b.isCompleted && !b.isPaused).length} active recurring payment(s).',
      );
    }

    // 2. Filter transactions
    var filtered = transactions.where((t) {
      // Exclude transfers from income/expense sums unless 'any' or 'transfer' requested
      if (spec.type == 'expense' && t.type == TransactionType.transfer) return false;
      if (spec.type == 'income' && t.type == TransactionType.transfer) return false;

      // Type match
      if (spec.type == 'expense' && t.type != TransactionType.expense) return false;
      if (spec.type == 'income' && t.type != TransactionType.income) return false;
      if (spec.type == 'transfer' && t.type != TransactionType.transfer) return false;

      // Category match (fuzzy)
      if (spec.categories.isNotEmpty) {
        final matchesCat = spec.categories.any((c) =>
            t.categoryName.toLowerCase().contains(c.toLowerCase()) ||
            c.toLowerCase().contains(t.categoryName.toLowerCase()));
        if (!matchesCat) return false;
      }

      // Merchant match (fuzzy)
      if (spec.merchants.isNotEmpty) {
        final matchesMerch = spec.merchants.any((m) =>
            t.merchant.toLowerCase().contains(m.toLowerCase()) ||
            m.toLowerCase().contains(t.merchant.toLowerCase()));
        if (!matchesMerch) return false;
      }

      // Tag match
      if (spec.tags.isNotEmpty) {
        final matchesTag = spec.tags.any((tag) =>
            t.tags.any((txTag) => txTag.toLowerCase().contains(tag.toLowerCase())));
        if (!matchesTag) return false;
      }

      // Account match
      if (spec.accounts.isNotEmpty) {
        final matchesAcc = spec.accounts.any((acc) =>
            t.accountName.toLowerCase().contains(acc.toLowerCase()));
        if (!matchesAcc) return false;
      }

      // Date range match
      if (spec.dateRange != null) {
        if (spec.dateRange!.from != null) {
          final fromDate = DateTime.tryParse(spec.dateRange!.from!);
          if (fromDate != null && t.date.isBefore(DateTime(fromDate.year, fromDate.month, fromDate.day))) {
            return false;
          }
        }
        if (spec.dateRange!.to != null) {
          final toDate = DateTime.tryParse(spec.dateRange!.to!);
          if (toDate != null && t.date.isAfter(DateTime(toDate.year, toDate.month, toDate.day, 23, 59, 59))) {
            return false;
          }
        }
      }

      return true;
    }).toList();

    // 3. Sort
    if (spec.sort == 'amount_desc') {
      filtered.sort((a, b) => b.amount.compareTo(a.amount));
    } else if (spec.sort == 'amount_asc') {
      filtered.sort((a, b) => a.amount.compareTo(b.amount));
    } else {
      filtered.sort((a, b) => b.date.compareTo(a.date)); // default date_desc
    }

    // Limit
    if (filtered.length > spec.limit) {
      filtered = filtered.take(spec.limit).toList();
    }

    final total = filtered.fold(0.0, (sum, t) => sum + t.amount);
    final count = filtered.length;
    final average = count > 0 ? total / count : 0.0;

    // Breakdown / Group by
    final Map<String, double> breakdown = {};
    if (spec.groupBy != null) {
      for (final t in filtered) {
        final key = switch (spec.groupBy) {
          'category' => t.categoryName,
          'merchant' => t.merchant,
          'account' => t.accountName,
          'tag' => t.tags.isNotEmpty ? t.tags.first : 'Untagged',
          _ => t.categoryName,
        };
        breakdown[key] = (breakdown[key] ?? 0.0) + t.amount;
      }
    }

    return QueryExecutionResult(
      totalAmount: total,
      count: count,
      average: average,
      transactions: filtered,
      breakdown: breakdown,
    );
  }

  static List<Account> _filterAccounts(List<Account> accounts, List<String> queryNames) {
    if (queryNames.isEmpty) return accounts;
    return accounts.where((a) =>
        queryNames.any((q) => a.name.toLowerCase().contains(q.toLowerCase()))).toList();
  }
}
