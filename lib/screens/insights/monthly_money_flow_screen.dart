import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:expensetracker/providers/app_state.dart';
import 'package:expensetracker/models/transaction.dart';
import 'package:expensetracker/theme/app_theme.dart';
import 'package:expensetracker/utils/currency_formatter.dart';

class MonthlyMoneyFlowScreen extends StatelessWidget {
  final AppState state;
  const MonthlyMoneyFlowScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final isDark = state.profile.isDarkMode;
    final isPrivacy = state.profile.isPrivacyModeEnabled;

    final income = state.periodIncome;
    final spent = state.periodSpent;

    final billCategoryNames = {
      'Bills & Utilities',
      'Rent',
      'Subscriptions',
      'Fuel',
    };
    double bills = 0.0;
    for (final t in state.filteredTransactions) {
      if (t.type == TransactionType.expense &&
          billCategoryNames.contains(t.categoryName)) {
        bills += t.amount;
      }
    }
    final daily = (spent - bills).clamp(0.0, double.infinity);
    final netFlow = income - spent;

    // Bar chart groups for Money Flow comparison
    final maxVal = [income, spent, bills, daily].reduce((a, b) => a > b ? a : b);
    final maxY = maxVal <= 0 ? 1000.0 : maxVal * 1.2;

    return Scaffold(
      appBar: AppBar(title: const Text('Monthly Money Flow Analysis')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Visual Trace of Income & Expenditures',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Compare your incoming earnings directly against fixed obligations and daily living costs.',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 24),

            // BAR CHART VISUALIZER
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                child: SizedBox(
                  height: 240,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxY,
                      barTouchData: BarTouchData(enabled: true),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              const style = TextStyle(fontSize: 11, fontWeight: FontWeight.bold);
                              String text = switch (value.toInt()) {
                                0 => 'Income',
                                1 => 'Spent',
                                2 => 'Bills',
                                3 => 'Daily',
                                _ => '',
                              };
                              return Text(text, style: style);
                            },
                          ),
                        ),
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      barGroups: [
                        BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: income, color: AppColors.incomeGreen, width: 22, borderRadius: BorderRadius.circular(6))]),
                        BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: spent, color: AppColors.expenseRed, width: 22, borderRadius: BorderRadius.circular(6))]),
                        BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: bills, color: AppColors.infoBlue, width: 22, borderRadius: BorderRadius.circular(6))]),
                        BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: daily, color: AppColors.warningOrange, width: 22, borderRadius: BorderRadius.circular(6))]),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // STEP-BY-STEP FLOW CARDS
            _flowCard('Monthly Income Received', income, AppColors.incomeGreen, isPrivacy, isDark, icon: Icons.arrow_downward_rounded),
            _arrow(),
            _flowCard('Fixed Bills, Rent & Utilities', bills, AppColors.expenseRed, isPrivacy, isDark, icon: Icons.receipt_long_rounded),
            _arrow(),
            _flowCard('Variable Daily Spending & Food', daily, AppColors.warningOrange, isPrivacy, isDark, icon: Icons.shopping_cart_rounded),
            _arrow(),
            _flowCard('Net Cash Flow (Retained Savings)', netFlow, netFlow >= 0 ? AppColors.primary : AppColors.expenseRed, isPrivacy, isDark, icon: Icons.account_balance_wallet_rounded),
          ],
        ),
      ),
    );
  }

  Widget _flowCard(
    String title,
    double amount,
    Color color,
    bool isPrivacy,
    bool isDark, {
    required IconData icon,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    CurrencyFormatter.format(amount, isPrivacyMode: isPrivacy),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _arrow() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 4.0),
      child: Icon(Icons.arrow_downward_rounded, color: AppColors.primary, size: 24),
    );
  }
}
