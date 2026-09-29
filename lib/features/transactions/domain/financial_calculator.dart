import 'package:flutter/material.dart';
import 'package:expensetracker/models/account.dart';
import 'package:expensetracker/models/budget.dart';
import 'package:expensetracker/models/goal.dart';
import 'package:expensetracker/models/recurring_bill.dart';
import 'package:expensetracker/models/review_queue_item.dart';
import 'package:expensetracker/models/transaction.dart';
import 'package:expensetracker/utils/currency_formatter.dart';
import 'package:expensetracker/utils/date_formatter.dart';

enum TimePeriod { today, thisWeek, thisMonth, lastMonth, custom }

class FinancialCalculator {
  static double thisMonthIncome(List<TransactionItem> transactions) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    double total = 0.0;
    for (final t in transactions) {
      if (t.type == TransactionType.income &&
          t.date.isAfter(start.subtract(const Duration(seconds: 1)))) {
        total += t.amount;
      }
    }
    return total;
  }

  static double thisMonthExpense(List<TransactionItem> transactions) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    double total = 0.0;
    for (final t in transactions) {
      if (t.type == TransactionType.expense &&
          t.date.isAfter(start.subtract(const Duration(seconds: 1)))) {
        total += t.amount;
      } else if (t.type == TransactionType.refund &&
          t.date.isAfter(start.subtract(const Duration(seconds: 1)))) {
        total -= t.amount;
      }
    }
    return total;
  }

  static double totalAvailableMoney(List<Account> accounts) {
    double total = 0.0;
    for (final acc in accounts) {
      if (acc.type == AccountType.bank ||
          acc.type == AccountType.cash ||
          acc.type == AccountType.wallet) {
        total += acc.balance;
      }
    }
    return total;
  }

  static double creditCardOutstanding(List<Account> accounts) {
    double total = 0.0;
    for (final acc in accounts) {
      if (acc.type == AccountType.creditCard) {
        total += acc.balance;
      }
    }
    return total;
  }

  static List<TransactionItem> filterTransactions({
    required List<TransactionItem> transactions,
    required TimePeriod selectedPeriod,
    DateTimeRange? customDateRange,
  }) {
    final now = DateTime.now();
    DateTime start;
    DateTime end = now;

    switch (selectedPeriod) {
      case TimePeriod.today:
        start = DateTime(now.year, now.month, now.day);
        end = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case TimePeriod.thisWeek:
        start = now.subtract(Duration(days: now.weekday - 1));
        start = DateTime(start.year, start.month, start.day);
        break;
      case TimePeriod.thisMonth:
        start = DateTime(now.year, now.month, 1);
        break;
      case TimePeriod.lastMonth:
        final lastMonth = DateTime(now.year, now.month - 1, 1);
        start = lastMonth;
        end = DateTime(now.year, now.month, 0, 23, 59, 59);
        break;
      case TimePeriod.custom:
        if (customDateRange != null) {
          start = customDateRange.start;
          end = customDateRange.end;
        } else {
          start = DateTime(now.year, now.month, 1);
        }
        break;
    }

    return transactions.where((t) {
      return t.date.isAfter(start.subtract(const Duration(seconds: 1))) &&
          t.date.isBefore(end.add(const Duration(seconds: 1)));
    }).toList()..sort((a, b) => b.date.compareTo(a.date));
  }

  static double periodIncome(List<TransactionItem> filtered) {
    double total = 0.0;
    for (final t in filtered) {
      if (t.type == TransactionType.income) {
        total += t.amount;
      }
    }
    return total;
  }

  static double periodSpent(List<TransactionItem> filtered) {
    double total = 0.0;
    for (final t in filtered) {
      if (t.type == TransactionType.expense) {
        total += t.amount;
      } else if (t.type == TransactionType.refund) {
        total -= t.amount;
      }
    }
    return total;
  }

  static Map<String, double> monthlyBudgetSpendingByCategory({
    required List<Budget> activeMonthlyBudgets,
    required List<TransactionItem> transactions,
  }) {
    final categoryIds = activeMonthlyBudgets
        .map((budget) => budget.categoryId)
        .toSet();
    final spending = {for (final id in categoryIds) id: 0.0};
    if (categoryIds.isEmpty) return spending;

    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month);
    final nextMonth = DateTime(now.year, now.month + 1);
    for (final transaction in transactions) {
      if (transaction.date.isBefore(monthStart) ||
          !transaction.date.isBefore(nextMonth)) {
        continue;
      }

      final multiplier = switch (transaction.type) {
        TransactionType.expense => 1.0,
        TransactionType.refund => -1.0,
        _ => 0.0,
      };
      if (multiplier == 0) continue;

      if (transaction.splits.isNotEmpty) {
        for (final split in transaction.splits) {
          if (categoryIds.contains(split.categoryId)) {
            spending[split.categoryId] =
                (spending[split.categoryId] ?? 0) + split.amount * multiplier;
          }
        }
      } else if (categoryIds.contains(transaction.categoryId)) {
        spending[transaction.categoryId] =
            (spending[transaction.categoryId] ?? 0) +
            transaction.amount * multiplier;
      }
    }
    return spending;
  }

  static double upcomingBillsTotal(List<RecurringBill> recurringBills) {
    double total = 0.0;
    final now = DateTime.now();
    final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    for (final bill in recurringBills) {
      final dueDay = bill.dueDay
          .clamp(1, DateTime(now.year, now.month + 1, 0).day)
          .toInt();
      final dueDate = bill.nextDueDate ?? DateTime(now.year, now.month, dueDay);
      if (bill.type != RecurringType.income &&
          !bill.isPaid &&
          !bill.isPaused &&
          !bill.isCompleted &&
          !dueDate.isAfter(monthEnd)) {
        total += bill.amount;
      }
    }
    return total;
  }

  static double plannedSavingsTotal(List<Goal> goals) {
    double total = 0.0;
    final now = DateTime.now();
    for (final goal in goals) {
      if (!goal.isCompleted) {
        final remaining = (goal.targetAmount - goal.currentAmount).clamp(
          0,
          double.infinity,
        );
        if (remaining > 0) {
          final targetMonth = goal.targetDate.year * 12 + goal.targetDate.month;
          final currentMonth = now.year * 12 + now.month;
          final monthsRemaining = (targetMonth - currentMonth + 1).clamp(
            1,
            1200,
          );
          total += remaining / monthsRemaining;
        }
      }
    }
    return total;
  }

  static double availableToSpend({
    required double totalAvailableMoney,
    required double upcomingBillsTotal,
    required double plannedSavingsTotal,
  }) {
    final available = totalAvailableMoney - upcomingBillsTotal - plannedSavingsTotal;
    return available < 0 ? 0.0 : available;
  }

  static Map<String, double> categorySpending(List<TransactionItem> filteredTransactions) {
    final map = <String, double>{};
    for (final t in filteredTransactions) {
      if (t.type == TransactionType.expense) {
        if (t.splits.isNotEmpty) {
          for (final split in t.splits) {
            map[split.categoryName] = (map[split.categoryName] ?? 0.0) + split.amount;
          }
        } else {
          map[t.categoryName] = (map[t.categoryName] ?? 0.0) + t.amount;
        }
      }
    }
    return map;
  }

  static List<String> financialAlerts({
    required List<ReviewQueueItem> reviewQueue,
    required List<RecurringBill> recurringBills,
    required List<Budget> budgets,
    required Map<String, double> categorySpendingMap,
    required List<Account> accounts,
  }) {
    final alerts = <String>[];
    if (reviewQueue.isNotEmpty) {
      alerts.add(
        '${reviewQueue.length} bank message${reviewQueue.length == 1 ? '' : 's'} need review.',
      );
    }
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final reminderHorizon = todayOnly.add(const Duration(days: 7));
    for (final bill in recurringBills) {
      if (bill.type == RecurringType.income ||
          bill.isPaused ||
          bill.isCompleted) {
        continue;
      }
      final dueDay = bill.dueDay
          .clamp(1, DateTime(today.year, today.month + 1, 0).day)
          .toInt();
      final dueDate =
          bill.nextDueDate ?? DateTime(today.year, today.month, dueDay);
      if (!dueDate.isAfter(reminderHorizon)) {
        alerts.add(
          '${bill.title} is ${dueDate.isBefore(todayOnly) ? 'overdue' : 'due soon'} (${CurrencyFormatter.format(bill.amount)}).',
        );
      }
    }
    for (final budget in budgets.where((item) => item.isActive)) {
      final spent = categorySpendingMap[budget.categoryName] ?? 0;
      if (spent > budget.limitAmount) {
        alerts.add(
          '${budget.categoryName} is over its limit by ${CurrencyFormatter.format(spent - budget.limitAmount)}.',
        );
      }
    }
    for (final account in accounts) {
      if (account.lowBalanceThreshold != null &&
          account.balance < account.lowBalanceThreshold!) {
        alerts.add('${account.name} is below your low balance threshold.');
      }
      if (account.type == AccountType.creditCard &&
          account.creditLimit != null &&
          account.balance > account.creditLimit!) {
        alerts.add('${account.name} is over its credit limit.');
      }
      if (account.type == AccountType.creditCard &&
          account.balance > 0 &&
          account.minDue != null &&
          account.dueDate != null) {
        final dayMatch = RegExp(r'(\d{1,2})').firstMatch(account.dueDate!);
        final dueDay = int.tryParse(dayMatch?.group(1) ?? '');
        if (dueDay != null) {
          final day = dueDay
              .clamp(1, DateTime(today.year, today.month + 1, 0).day)
              .toInt();
          var dueDate = DateTime(today.year, today.month, day);
          if (dueDate.isBefore(todayOnly)) {
            final nextMonth = DateTime(today.year, today.month + 1, 1);
            final nextDay = dueDay
                .clamp(1, DateTime(nextMonth.year, nextMonth.month + 1, 0).day)
                .toInt();
            dueDate = DateTime(nextMonth.year, nextMonth.month, nextDay);
          }
          if (!dueDate.isAfter(reminderHorizon)) {
            alerts.add(
              '${account.name} minimum due ${CurrencyFormatter.format(account.minDue!)} is due ${DateFormatter.formatDateOnly(dueDate)}.',
            );
          }
        }
      }
    }
    return alerts;
  }
}
