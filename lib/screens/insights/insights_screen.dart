import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:expensetracker/providers/app_state.dart';
import 'package:expensetracker/models/transaction.dart';
import 'package:expensetracker/theme/app_theme.dart';
import 'package:expensetracker/utils/currency_formatter.dart';
import 'package:expensetracker/screens/insights/monthly_money_flow_screen.dart';
import 'package:expensetracker/screens/insights/monthly_review_screen.dart';
import 'package:expensetracker/services/spending_analytics_service.dart';
import 'package:expensetracker/services/haptic_service.dart';

import '../../utils/date_formatter.dart';

class InsightsScreen extends StatefulWidget {
  final AppState state;
  const InsightsScreen({super.key, required this.state});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.state.profile.isDarkMode;
    final isPrivacy = widget.state.profile.isPrivacyModeEnabled;

    final income = widget.state.periodIncome;
    final spent = widget.state.periodSpent;
    final net = widget.state.periodRemaining;
    final incomeChange = income - widget.state.priorMonthIncome;
    final expenseChange = spent - widget.state.priorMonthSpent;
    final netChange = incomeChange - expenseChange;
    final canCompareMonths = widget.state.selectedPeriod == TimePeriod.thisMonth;

    // Category spending breakdown for Pie Chart
    final spendingMap = widget.state.categorySpending;
    final sortedCategories = spendingMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final totalSpent = spent <= 0 ? 1.0 : spent;

    // Palette of colors for chart sections
    final chartColors = [
      AppColors.primary,
      AppColors.expenseRed,
      AppColors.warningOrange,
      AppColors.incomeGreen,
      AppColors.infoBlue,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
    ];

    // Merchant breakdown
    final Map<String, double> merchantMap = {};
    for (var t in widget.state.filteredTransactions) {
      if (t.type == TransactionType.expense) {
        merchantMap[t.merchant] = (merchantMap[t.merchant] ?? 0.0) + t.amount;
      }
    }
    final sortedMerchants = merchantMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Advanced analytics
    final anomalies = SpendingAnalyticsService.detectAnomalies(widget.state.transactions);
    final commitments = SpendingAnalyticsService.analyzeCommitments(widget.state.filteredTransactions, widget.state.recurringBills);
    final savingsProjection = SpendingAnalyticsService.calculateSavingsProjection(widget.state.filteredTransactions, initialIncomeGoal: widget.state.profile.monthlyIncomeGoal);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Insights & Analytics'),
        actions: [
          IconButton(
            tooltip: 'Money Flow Diagram',
            icon: const Icon(Icons.account_tree_rounded, color: AppColors.primary),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => MonthlyMoneyFlowScreen(state: widget.state)),
              );
            },
          ),
          IconButton(
            tooltip: 'Monthly Review Report',
            icon: const Icon(Icons.assessment_rounded, color: AppColors.infoBlue),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => MonthlyReviewScreen(state: widget.state)),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ANOMALIES / SPENDING SPIKE ALERTS
            if (anomalies.isNotEmpty) ...[
              Text(
                'Spending Spike & Anomaly Alerts',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              ...anomalies.map((anomaly) => Card(
                    color: isDark ? const Color(0xFF2A1B1B) : const Color(0xFFFEF2F2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: AppColors.expenseRed, width: 0.8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: AppColors.expenseRed, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  anomaly.message,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Amount: ${CurrencyFormatter.format(anomaly.amount, isPrivacyMode: isPrivacy)} (Normal avg: ${CurrencyFormatter.format(anomaly.historicalAverage, isPrivacyMode: isPrivacy)})',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 20),
                            onPressed: () {
                              HapticService.selection();
                              setState(() {
                                anomaly.isDismissed = true;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  )),
              const SizedBox(height: 16),
            ],

            // FIXED COMMITMENTS VS DISCRETIONARY CARD
            Text(
              'Commitments vs. Discretionary Spending',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Estimated Fixed Commitments', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            const SizedBox(height: 4),
                            Text(
                              CurrencyFormatter.format(commitments.fixedCommitmentsTotal, isPrivacyMode: isPrivacy),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.warningOrange),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Discretionary Spending', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            const SizedBox(height: 4),
                            Text(
                              CurrencyFormatter.format(commitments.discretionaryTotal, isPrivacyMode: isPrivacy),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.infoBlue),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Estimated Monthly Disposable:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        Text(
                          CurrencyFormatter.format(commitments.estimatedDisposable, isPrivacyMode: isPrivacy),
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.incomeGreen),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // SAVINGS VELOCITY PROJECTION CARD
            Text(
              'Savings Velocity Projection',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Actual Savings to Date', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            const SizedBox(height: 4),
                            Text(
                              CurrencyFormatter.format(savingsProjection.actualSavings, isPrivacyMode: isPrivacy),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Projected Month-End', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            const SizedBox(height: 4),
                            Text(
                              CurrencyFormatter.format(savingsProjection.projectedMonthEndSavings, isPrivacyMode: isPrivacy),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: savingsProjection.projectedMonthEndSavings >= 0 ? AppColors.incomeGreen : AppColors.expenseRed,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Daily spending rate: ${CurrencyFormatter.format(savingsProjection.dailySpendingRate, isPrivacyMode: isPrivacy)}/day • ${savingsProjection.remainingDays} days remaining in month.',
                      style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // PERIOD OVERVIEW CARD
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PERIOD FINANCIAL OVERVIEW',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _overviewMetric('INCOME', income, canCompareMonths ? _comparison(incomeChange) : 'Period total', AppColors.incomeGreen, isPrivacy, isDark),
                        _overviewMetric('EXPENSES', spent, canCompareMonths ? _comparison(expenseChange) : 'Period total', AppColors.expenseRed, isPrivacy, isDark),
                        _overviewMetric('NET FLOW', net, canCompareMonths ? _comparison(netChange) : 'Net savings', AppColors.primary, isPrivacy, isDark),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // INTERACTIVE CATEGORY SPENDING PIE CHART
            Text(
              'Spending Distribution by Category',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: sortedCategories.isEmpty
                    ? const SizedBox(
                        height: 180,
                        child: Center(child: Text('No expense data available for this period.')),
                      )
                    : Column(
                        children: [
                          SizedBox(
                            height: 220,
                            child: PieChart(
                              PieChartData(
                                pieTouchData: PieTouchData(
                                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                    setState(() {
                                      if (!event.isInterestedForInteractions ||
                                          pieTouchResponse == null ||
                                          pieTouchResponse.touchedSection == null) {
                                        _touchedIndex = -1;
                                        return;
                                      }
                                      _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                                    });
                                  },
                                ),
                                borderData: FlBorderData(show: false),
                                sectionsSpace: 2,
                                centerSpaceRadius: 40,
                                sections: List.generate(sortedCategories.length, (i) {
                                  final entry = sortedCategories[i];
                                  final isTouched = i == _touchedIndex;
                                  final fontSize = isTouched ? 16.0 : 12.0;
                                  final radius = isTouched ? 65.0 : 55.0;
                                  final percentage = (entry.value / totalSpent * 100);
                                  final color = chartColors[i % chartColors.length];

                                  return PieChartSectionData(
                                    color: color,
                                    value: entry.value,
                                    title: '${percentage.toStringAsFixed(0)}%',
                                    radius: radius,
                                    titleStyle: TextStyle(
                                      fontSize: fontSize,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  );
                                }),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // LEGEND LIST
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: sortedCategories.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 8),
                            itemBuilder: (context, idx) {
                              final entry = sortedCategories[idx];
                              final color = chartColors[idx % chartColors.length];
                              final percentage = (entry.value / totalSpent * 100);

                              return Row(
                                children: [
                                  Container(
                                    width: 14,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: color,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      entry.key,
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                    ),
                                  ),
                                  Text(
                                    '${percentage.toStringAsFixed(1)}% • ${CurrencyFormatter.format(entry.value, isPrivacyMode: isPrivacy)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),

            // TOP NAVIGATION SHORTCUTS
            Row(
              children: [
                Expanded(
                  child: Card(
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => MonthlyMoneyFlowScreen(state: widget.state)),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Icon(Icons.account_tree_rounded, color: AppColors.primary, size: 28),
                            SizedBox(height: 10),
                            Text('Money Flow', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            SizedBox(height: 2),
                            Text('Visual income to expense trace', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Card(
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => MonthlyReviewScreen(state: widget.state)),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.assessment_rounded, color: AppColors.infoBlue, size: 28),
                            const SizedBox(height: 10),
                            const Text('Executive Review', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 2),
                            Text('${DateFormatter.formatMonthYear(DateTime.now())} report', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // TOP MERCHANTS
            Text(
              'Top Merchants',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: sortedMerchants.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('No merchant spending recorded.'),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: sortedMerchants.take(5).length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, idx) {
                        final m = sortedMerchants[idx];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                            child: Text(
                              '${idx + 1}',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                          ),
                          title: Text(m.key, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          trailing: Text(
                            CurrencyFormatter.format(m.value, isPrivacyMode: isPrivacy),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _overviewMetric(String title, double amount, String subtitle, Color color, bool isPrivacy, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          CurrencyFormatter.formatCompact(amount, isPrivacyMode: isPrivacy),
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: TextStyle(fontSize: 9, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
        ),
      ],
    );
  }

  String _comparison(double change) {
    if (widget.state.priorMonthIncome == 0 && widget.state.priorMonthSpent == 0) {
      return 'No prior data';
    }
    final direction = change > 0 ? '+' : change < 0 ? '-' : '';
    return '$direction${CurrencyFormatter.format(change.abs(), isPrivacyMode: widget.state.profile.isPrivacyModeEnabled)} vs last month';
  }
}
