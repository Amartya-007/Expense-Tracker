import 'package:flutter/material.dart';
import 'package:expensetracker/providers/app_state.dart';
import 'package:expensetracker/theme/app_theme.dart';
import 'package:expensetracker/utils/currency_formatter.dart';
import 'package:expensetracker/utils/date_formatter.dart';
import 'package:expensetracker/models/transaction.dart';

class MonthlyReviewScreen extends StatelessWidget {
  final AppState state;
  const MonthlyReviewScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final isDark = state.profile.isDarkMode;
    final isPrivacy = state.profile.isPrivacyModeEnabled;
    final expenses = state.filteredTransactions
        .where((transaction) => transaction.type == TransactionType.expense)
        .toList();
    final categoryTotals = <String, double>{};
    final merchantTotals = <String, double>{};
    for (final transaction in expenses) {
      categoryTotals.update(
        transaction.categoryName,
        (value) => value + transaction.amount,
        ifAbsent: () => transaction.amount,
      );
      merchantTotals.update(
        transaction.merchant,
        (value) => value + transaction.amount,
        ifAbsent: () => transaction.amount,
      );
    }
    final topCategory = categoryTotals.entries.isEmpty
        ? null
        : (categoryTotals.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value)))
              .first;
    final topMerchant = merchantTotals.entries.isEmpty
        ? null
        : (merchantTotals.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value)))
              .first;
    final largestExpense = expenses.isEmpty
        ? null
        : (List<TransactionItem>.from(
            expenses,
          )..sort((a, b) => b.amount.compareTo(a.amount))).first;
    final recurringPaid = expenses
        .where((transaction) => transaction.isRecurring)
        .fold<double>(0, (total, transaction) => total + transaction.amount);
    final activeBudgetTotal = state.budgets
        .where((budget) => budget.isActive)
        .fold<double>(0, (total, budget) => total + budget.limitAmount);
    final budgetUse = activeBudgetTotal <= 0
        ? null
        : (state.periodSpent / activeBudgetTotal * 100).clamp(
            0,
            double.infinity,
          );
    final now = DateTime.now();
    final reportPeriod = switch (state.selectedPeriod) {
      TimePeriod.today => DateFormatter.formatDateOnly(now),
      TimePeriod.thisWeek => 'This week',
      TimePeriod.thisMonth => DateFormatter.formatMonthYear(now),
      TimePeriod.lastMonth => DateFormatter.formatMonthYear(
        DateTime(now.year, now.month - 1),
      ),
      TimePeriod.custom =>
        state.customDateRange == null
            ? 'Selected period'
            : '${DateFormatter.formatDateOnly(state.customDateRange!.start)} – ${DateFormatter.formatDateOnly(state.customDateRange!.end)}',
    };

    return Scaffold(
      appBar: AppBar(title: Text('$reportPeriod Financial Review')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: AppColors.primary.withValues(alpha: 0.12),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    const Icon(
                      Icons.assessment_rounded,
                      size: 40,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '$reportPeriod Executive Summary',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'A calm report on your income, spending, top categories and savings efficiency.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _reviewRow(
                      'Total Received Income',
                      state.periodIncome,
                      AppColors.incomeGreen,
                      isPrivacy,
                      isDark,
                    ),
                    const Divider(height: 1),
                    _reviewRow(
                      'Total Monthly Spending',
                      state.periodSpent,
                      AppColors.expenseRed,
                      isPrivacy,
                      isDark,
                    ),
                    const Divider(height: 1),
                    _reviewRow(
                      'Net Retained Savings',
                      state.periodRemaining,
                      AppColors.primary,
                      isPrivacy,
                      isDark,
                      isBold: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'Key Highlights',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _highlightBullet(
                      'Top Category',
                      topCategory == null
                          ? 'No expense data for this period'
                          : '${topCategory.key} (${CurrencyFormatter.format(topCategory.value, isPrivacyMode: isPrivacy)})',
                    ),
                    const SizedBox(height: 8),
                    _highlightBullet(
                      'Largest Transaction',
                      largestExpense == null
                          ? 'No expense data for this period'
                          : '${largestExpense.merchant} (${CurrencyFormatter.format(largestExpense.amount, isPrivacyMode: isPrivacy)})',
                    ),
                    const SizedBox(height: 8),
                    _highlightBullet(
                      'Top Merchant',
                      topMerchant == null
                          ? 'No merchant spending recorded'
                          : '${topMerchant.key} (${CurrencyFormatter.format(topMerchant.value, isPrivacyMode: isPrivacy)})',
                    ),
                    const SizedBox(height: 8),
                    _highlightBullet(
                      'Recurring Payments Recorded',
                      CurrencyFormatter.format(
                        recurringPaid,
                        isPrivacyMode: isPrivacy,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _highlightBullet(
                      'Budget Performance',
                      budgetUse == null
                          ? 'No active category budgets set'
                          : '${budgetUse.toStringAsFixed(0)}% of active category limits used',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _reviewRow(
    String title,
    double amount,
    Color color,
    bool isPrivacy,
    bool isDark, {
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
          Text(
            CurrencyFormatter.format(amount, isPrivacyMode: isPrivacy),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _highlightBullet(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '• ',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 13, color: Colors.grey),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
