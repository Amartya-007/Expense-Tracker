import 'package:expensetracker/models/transaction.dart';
import 'package:expensetracker/models/recurring_bill.dart';

class AnomalyResult {
  final String id;
  final String transactionId;
  final String categoryName;
  final double amount;
  final double historicalAverage;
  final String message;
  final DateTime date;
  bool isDismissed;
  bool isExpected;

  AnomalyResult({
    required this.id,
    required this.transactionId,
    required this.categoryName,
    required this.amount,
    required this.historicalAverage,
    required this.message,
    required this.date,
    this.isDismissed = false,
    this.isExpected = false,
  });
}

class SpendingCommitmentAnalysis {
  final double fixedCommitmentsTotal;
  final double discretionaryTotal;
  final double estimatedDisposable;
  final List<RecurringBill> identifiedRecurringBills;
  final Map<String, double> categoryBreakdown;

  SpendingCommitmentAnalysis({
    required this.fixedCommitmentsTotal,
    required this.discretionaryTotal,
    required this.estimatedDisposable,
    required this.identifiedRecurringBills,
    required this.categoryBreakdown,
  });
}

class SavingsProjectionResult {
  final double actualSavings;
  final double currentIncome;
  final double currentExpenses;
  final double dailySpendingRate;
  final int remainingDays;
  final double projectedMonthEndSavings;
  final bool hasSufficientHistory;

  SavingsProjectionResult({
    required this.actualSavings,
    required this.currentIncome,
    required this.currentExpenses,
    required this.dailySpendingRate,
    required this.remainingDays,
    required this.projectedMonthEndSavings,
    required this.hasSufficientHistory,
  });
}

class SpendingAnalyticsService {
  // Configurable thresholds
  static const double anomalyThresholdMultiplier = 2.0; // 2x rolling average spike
  static const double minimumBaselineAmount = 100.0;

  static List<AnomalyResult> detectAnomalies(
    List<TransactionItem> transactions, {
    int historyDaysLookback = 60,
  }) {
    if (transactions.isEmpty) return [];

    final now = DateTime.now();
    final historyCutoffStart = now.subtract(Duration(days: historyDaysLookback));
    final historyCutoffEnd = now.subtract(const Duration(days: 3));

    // Group historical transactions by category (excluding last 3 days)
    final Map<String, List<double>> categoryHistory = {};
    for (final t in transactions) {
      if (t.type == TransactionType.expense &&
          t.date.isAfter(historyCutoffStart) &&
          (t.date.isBefore(historyCutoffEnd) || t.date.isAtSameMomentAs(historyCutoffEnd))) {
        categoryHistory.putIfAbsent(t.categoryName, () => []).add(t.amount);
      }
    }

    // Calculate rolling historical averages & standard deviations per category
    final Map<String, double> categoryAverages = {};
    final Map<String, double> categoryStDevs = {};

    categoryHistory.forEach((category, amounts) {
      if (amounts.length >= 3) {
        final sum = amounts.reduce((a, b) => a + b);
        final avg = sum / amounts.length;
        categoryAverages[category] = avg;

        final variance =
            amounts.map((v) => (v - avg) * (v - avg)).reduce((a, b) => a + b) /
            amounts.length;
        categoryStDevs[category] = variance > 0 ? _sqrt(variance) : avg * 0.3;
      }
    });

    // Detect anomalies in recent transactions (last 3 days including today)
    final recentCutoff = now.subtract(const Duration(days: 3));
    final List<AnomalyResult> anomalies = [];

    for (final t in transactions) {
      if (t.type == TransactionType.expense &&
          t.date.isAfter(recentCutoff) &&
          t.amount >= minimumBaselineAmount) {
        final avg = categoryAverages[t.categoryName];
        final stdev = categoryStDevs[t.categoryName] ?? (avg != null ? avg * 0.4 : 500.0);

        if (avg != null && avg >= 50.0) {
          if (t.amount > (avg + (2.0 * stdev)) && t.amount > (avg * anomalyThresholdMultiplier)) {
            anomalies.add(
              AnomalyResult(
                id: 'anomaly_${t.id}',
                transactionId: t.id,
                categoryName: t.categoryName,
                amount: t.amount,
                historicalAverage: avg,
                message:
                    '${t.categoryName} spending is unusually high today compared with your recent pattern.',
                date: t.date,
              ),
            );
          }
        }
      }
    }

    return anomalies;
  }

  static SpendingCommitmentAnalysis analyzeCommitments(
    List<TransactionItem> transactions,
    List<RecurringBill> recurringBills,
  ) {
    final now = DateTime.now();
    final currentMonthStart = DateTime(now.year, now.month, 1);

    double fixedTotal = 0.0;
    double discretionaryTotal = 0.0;
    final Map<String, double> categoryBreakdown = {};

    final fixedCategories = {
      'rent',
      'utilities',
      'bills & utilities',
      'insurance',
      'emi',
      'subscriptions',
      'internet',
      'mobile',
    };

    for (final t in transactions) {
      if (t.date.isAfter(currentMonthStart) ||
          t.date.isAtSameMomentAs(currentMonthStart)) {
        if (t.type == TransactionType.expense) {
          categoryBreakdown.update(
            t.categoryName,
            (val) => val + t.amount,
            ifAbsent: () => t.amount,
          );

          final lowerCat = t.categoryName.toLowerCase();
          final isFixedCategory = fixedCategories.any((fc) => lowerCat.contains(fc));
          final isRecurringFlag = t.isRecurring;

          if (isFixedCategory || isRecurringFlag) {
            fixedTotal += t.amount;
          } else {
            discretionaryTotal += t.amount;
          }
        }
      }
    }

    double recurringCommitmentSum = 0.0;
    for (final bill in recurringBills) {
      if (!bill.isPaused && !bill.isCompleted) {
        recurringCommitmentSum += bill.amount;
      }
    }

    final effectiveFixed = fixedTotal > 0 ? fixedTotal : recurringCommitmentSum;
    final totalExpenses = effectiveFixed + discretionaryTotal;
    
    double monthlyIncome = 0.0;
    for (final t in transactions) {
      if (t.date.isAfter(currentMonthStart) && t.type == TransactionType.income) {
        monthlyIncome += t.amount;
      }
    }

    final estimatedDisposable = (monthlyIncome - totalExpenses);

    return SpendingCommitmentAnalysis(
      fixedCommitmentsTotal: effectiveFixed,
      discretionaryTotal: discretionaryTotal,
      estimatedDisposable: estimatedDisposable > 0 ? estimatedDisposable : 0.0,
      identifiedRecurringBills: recurringBills,
      categoryBreakdown: categoryBreakdown,
    );
  }

  static SavingsProjectionResult calculateSavingsProjection(
    List<TransactionItem> transactions, {
    double initialIncomeGoal = 0.0,
  }) {
    final now = DateTime.now();
    final currentMonthStart = DateTime(now.year, now.month, 1);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final elapsedDays = now.day > 0 ? now.day : 1;
    final remainingDays = daysInMonth - now.day;

    double totalIncome = initialIncomeGoal;
    double totalExpenses = 0.0;

    for (final t in transactions) {
      if (t.date.isAfter(currentMonthStart) ||
          t.date.isAtSameMomentAs(currentMonthStart)) {
        if (t.type == TransactionType.income) {
          totalIncome += t.amount;
        } else if (t.type == TransactionType.expense) {
          totalExpenses += t.amount;
        }
      }
    }

    final actualSavings = totalIncome - totalExpenses;
    final dailySpendingRate = totalExpenses / elapsedDays;
    final projectedMonthEndExpenses = totalExpenses + (dailySpendingRate * remainingDays);
    final projectedMonthEndSavings = totalIncome - projectedMonthEndExpenses;

    return SavingsProjectionResult(
      actualSavings: actualSavings,
      currentIncome: totalIncome,
      currentExpenses: totalExpenses,
      dailySpendingRate: dailySpendingRate,
      remainingDays: remainingDays > 0 ? remainingDays : 0,
      projectedMonthEndSavings: projectedMonthEndSavings,
      hasSufficientHistory: transactions.isNotEmpty,
    );
  }

  static double _sqrt(double val) {
    if (val <= 0) return 0;
    double x = val;
    double y = 1;
    for (int i = 0; i < 6; i++) {
      y = (x + val / x) / 2;
      x = y;
    }
    return x;
  }
}
