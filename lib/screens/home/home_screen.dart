import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:expensetracker/providers/app_state.dart';
import 'package:expensetracker/models/account.dart';
import 'package:expensetracker/models/transaction.dart';
import 'package:expensetracker/models/recurring_bill.dart';
import 'package:expensetracker/theme/app_theme.dart';
import 'package:expensetracker/utils/currency_formatter.dart';
import 'package:expensetracker/utils/date_formatter.dart';
import 'package:expensetracker/screens/transactions/transaction_detail_screen.dart';
import 'package:expensetracker/screens/to_review/to_review_screen.dart';
import 'package:expensetracker/screens/accounts/accounts_screen.dart';
import 'package:expensetracker/screens/goals/goals_screen.dart';
import 'package:expensetracker/screens/recurring_bills/recurring_bills_screen.dart';

class HomeScreen extends StatelessWidget {
  final AppState state;
  final Function(int) onNavigateToTab;

  const HomeScreen({
    super.key,
    required this.state,
    required this.onNavigateToTab,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = state.profile.isDarkMode;
    final isPrivacy = state.profile.isPrivacyModeEnabled;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.primary.withValues(alpha: 0.15),
              child: Text(
                state.profile.name.isEmpty
                    ? '?'
                    : state.profile.name[0].toUpperCase(),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Good morning, ${state.profile.name}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  Text(
                    'Here\'s your money at a glance.',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Financial alerts',
            icon: state.financialAlerts.isEmpty
                ? Icon(
                    Icons.notifications_none_rounded,
                    color: isDark ? Colors.white70 : Colors.black87,
                  )
                : Badge(
                    label: Text('${state.financialAlerts.length}'),
                    child: const Icon(
                      Icons.notifications_active_rounded,
                      color: AppColors.warningOrange,
                    ),
                  ),
            onPressed: () => _showFinancialAlerts(context),
          ),
          IconButton(
            tooltip: isPrivacy ? 'Show Balances' : 'Hide Balances',
            icon: Icon(
              isPrivacy
                  ? Icons.visibility_off_rounded
                  : Icons.visibility_rounded,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
            onPressed: () => state.togglePrivacyMode(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.delayed(const Duration(milliseconds: 300));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopMoneySummaryCard(context, isDark, isPrivacy),
              const SizedBox(height: 20),
              _buildCashFlowCard(context, isDark, isPrivacy),
              const SizedBox(height: 20),
              _buildSpendingSnapshotCard(context, isDark, isPrivacy),
              const SizedBox(height: 20),
              _buildBudgetSnapshotCard(context, isDark, isPrivacy),
              const SizedBox(height: 20),
              _buildRecentTransactionsSection(context, isDark, isPrivacy),
              const SizedBox(height: 20),
              _buildUpcomingBillsSection(context, isDark, isPrivacy),
              const SizedBox(height: 20),
              _buildSavingsGoalsSection(context, isDark, isPrivacy),
              const SizedBox(height: 20),
              _buildFinancialInsightsSection(context, isDark, isPrivacy),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  // --- UI HELPERS FOR MODERN GLASSMORPHISM ---

  Widget _buildGlassContainer({
    required Widget child,
    required bool isDark,
    EdgeInsets padding = const EdgeInsets.all(20.0),
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.04)
                : Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.05),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 20,
                spreadRadius: 0,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            type: MaterialType.transparency,
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? actionButton,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.02)
            : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.05),
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 36,
              color: isDark ? Colors.white54 : Colors.black45,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
          if (actionButton != null) ...[
            const SizedBox(height: 16),
            actionButton,
          ],
        ],
      ),
    );
  }

  // --- SECTIONS ---

  void _showFinancialAlerts(BuildContext context) {
    final alerts = state.financialAlerts;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Financial Alerts',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                if (alerts.isEmpty)
                  _buildEmptyState(
                    isDark: state.profile.isDarkMode,
                    icon: Icons.check_circle_outline_rounded,
                    title: 'All Caught Up',
                    subtitle: 'No upcoming bills, overspending, or low-balance alerts right now.',
                  )
                else
                  ...alerts.map(
                    (alert) => ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.warningOrange.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.info_outline_rounded,
                          color: AppColors.warningOrange,
                        ),
                      ),
                      title: Text(
                        alert,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      onTap: alert.contains('need review')
                          ? () {
                              Navigator.pop(sheetContext);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ToReviewScreen(state: state),
                                ),
                              );
                            }
                          : null,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 1. TOP MONEY SUMMARY CARD
  Widget _buildTopMoneySummaryCard(
    BuildContext context,
    bool isDark,
    bool isPrivacy,
  ) {
    return _buildGlassContainer(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL AVAILABLE MONEY',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AccountsScreen(state: state),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              CurrencyFormatter.format(
                                state.totalAvailableMoney,
                                isPrivacyMode: isPrivacy,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              softWrap: false,
                              style: TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -1,
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 14,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Across ${state.accounts.where((a) => a.type != AccountType.creditCard).length} accounts',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? AppColors.darkTextMuted
                            : AppColors.lightTextMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<TimePeriod>(
                    value: state.selectedPeriod,
                    isDense: true,
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 18,
                    ),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: TimePeriod.today,
                        child: Text('Today'),
                      ),
                      DropdownMenuItem(
                        value: TimePeriod.thisWeek,
                        child: Text('This week'),
                      ),
                      DropdownMenuItem(
                        value: TimePeriod.thisMonth,
                        child: Text('This month'),
                      ),
                      DropdownMenuItem(
                        value: TimePeriod.lastMonth,
                        child: Text('Last month'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) state.setPeriod(val);
                    },
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: Divider(
              color: isDark ? Colors.white10 : Colors.black12,
              thickness: 1,
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _summaryColumn(
                  'INCOME',
                  state.periodIncome,
                  AppColors.incomeGreen,
                  isDark,
                  isPrivacy,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _summaryColumn(
                  'SPENT',
                  state.periodSpent,
                  AppColors.expenseRed,
                  isDark,
                  isPrivacy,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _summaryColumn(
                  'NET CASH FLOW',
                  state.periodRemaining,
                  state.periodRemaining >= 0
                      ? AppColors.primary
                      : AppColors.warningOrange,
                  isDark,
                  isPrivacy,
                  tooltip: 'Income minus Expenses for the selected period.',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryColumn(
    String label,
    double amount,
    Color color,
    bool isDark,
    bool isPrivacy, {
    String? tooltip,
  }) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ),
              if (tooltip != null) ...[
                const SizedBox(width: 3),
                Tooltip(
                  message: tooltip,
                  padding: const EdgeInsets.all(12),
                  showDuration: const Duration(seconds: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.info_outline_rounded,
                    size: 13,
                    color: isDark
                        ? AppColors.darkTextMuted
                        : AppColors.lightTextMuted,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FittedBox(
              alignment: Alignment.centerLeft,
              fit: BoxFit.scaleDown,
              child: Text(
                CurrencyFormatter.formatCompact(
                  amount,
                  isPrivacyMode: isPrivacy,
                ),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 2. CASH FLOW CARD
  Widget _buildCashFlowCard(BuildContext context, bool isDark, bool isPrivacy) {
    final income = state.periodIncome;
    final spent = state.periodSpent;
    final net = income - spent;

    return _buildGlassContainer(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Text(
                'Cash Flow Comparison',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
              if (income > 0 || spent > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color:
                        (net >= 0
                                ? AppColors.incomeGreen
                                : AppColors.expenseRed)
                            .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Net: ${CurrencyFormatter.format(net, isPrivacyMode: isPrivacy, showSign: true)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: net >= 0
                          ? AppColors.incomeGreen
                          : AppColors.expenseRed,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),

          if (income == 0 && spent == 0)
            _buildEmptyState(
              isDark: isDark,
              icon: Icons.sync_alt_rounded,
              title: 'No Cash Flow Yet',
              subtitle: 'When you earn or spend money this period, it will show up here.',
            )
          else ...[
            SizedBox(
              height: 28,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Row(
                  children: [
                    if (income > 0)
                      Expanded(
                        flex: (income * 100 / (income + spent + 1)).round(),
                        child: Container(color: AppColors.incomeGreen),
                      ),
                    if (spent > 0)
                      Expanded(
                        flex: (spent * 100 / (income + spent + 1)).round(),
                        child: Container(color: AppColors.expenseRed),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 16,
              runSpacing: 8,
              children: [
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: AppColors.incomeGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Income: ${CurrencyFormatter.format(income, isPrivacyMode: isPrivacy)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: AppColors.expenseRed,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Expenses: ${CurrencyFormatter.format(spent, isPrivacyMode: isPrivacy)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // 3. SPENDING SNAPSHOT CARD
  Widget _buildSpendingSnapshotCard(
    BuildContext context,
    bool isDark,
    bool isPrivacy,
  ) {
    final map = state.categorySpending;
    final sorted = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topList = sorted.take(5).toList();
    final totalSpent = state.periodSpent > 0 ? state.periodSpent : 1.0;

    return _buildGlassContainer(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Where your money went',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
              if (topList.isNotEmpty)
                TextButton(
                  onPressed: () => onNavigateToTab(3),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    textStyle: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  child: const Text('View All'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (topList.isEmpty)
            _buildEmptyState(
              isDark: isDark,
              icon: Icons.pie_chart_outline_rounded,
              title: 'No Spending Logged',
              subtitle: 'Add an expense to see a breakdown of your top categories here.',
            )
          else
            Column(
              children: topList.map((entry) {
                final ratio = (entry.value / totalSpent).clamp(0.0, 1.0);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            entry.key,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            CurrencyFormatter.format(
                              entry.value,
                              isPrivacyMode: isPrivacy,
                            ),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: ratio,
                          backgroundColor: isDark
                              ? Colors.white10
                              : Colors.black12,
                          color: AppColors.primary,
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  // 4. BUDGET SNAPSHOT CARD
  Widget _buildBudgetSnapshotCard(
    BuildContext context,
    bool isDark,
    bool isPrivacy,
  ) {
    final totalBudgetLimit = state.monthlyBudgetLimit;
    final totalSpent = state.monthlyBudgetedSpent;

    if (totalBudgetLimit <= 0) {
      return _buildGlassContainer(
        isDark: isDark,
        child: _buildEmptyState(
          isDark: isDark,
          icon: Icons.track_changes_rounded,
          title: 'No Budget Set',
          subtitle: 'Set a budget to track your monthly spending limits and stay on track.',
          actionButton: OutlinedButton.icon(
            onPressed: () => onNavigateToTab(2),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Set Budget'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      );
    }

    double left = totalBudgetLimit - totalSpent;
    double percent = (totalSpent / totalBudgetLimit).clamp(0.0, 1.0);

    return _buildGlassContainer(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Monthly Spending Budget',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
              TextButton(
                onPressed: () => onNavigateToTab(2),
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                child: const Text(
                  'Manage',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${CurrencyFormatter.format(totalSpent, isPrivacyMode: isPrivacy)} of ${CurrencyFormatter.format(totalBudgetLimit, isPrivacyMode: isPrivacy)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      (percent > 0.9 ? AppColors.expenseRed : AppColors.primary)
                          .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${(percent * 100).toStringAsFixed(0)}% used',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: percent > 0.9
                        ? AppColors.expenseRed
                        : AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percent,
              backgroundColor: isDark ? Colors.white10 : Colors.black12,
              color: percent > 0.9 ? AppColors.expenseRed : AppColors.primary,
              minHeight: 12,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            left >= 0
                ? '${CurrencyFormatter.format(left, isPrivacyMode: isPrivacy)} remaining safely'
                : '${CurrencyFormatter.format(left.abs(), isPrivacyMode: isPrivacy)} OVER budget limit!',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: left >= 0 ? AppColors.incomeGreen : AppColors.expenseRed,
            ),
          ),
        ],
      ),
    );
  }

  // 5. RECENT TRANSACTIONS SECTION
  Widget _buildRecentTransactionsSection(
    BuildContext context,
    bool isDark,
    bool isPrivacy,
  ) {
    final recent = state.transactions.take(6).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Recent Transactions',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
            if (recent.isNotEmpty)
              TextButton(
                onPressed: () => onNavigateToTab(1),
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                child: const Text(
                  'View All',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (recent.isEmpty)
          _buildEmptyState(
            isDark: isDark,
            icon: Icons.receipt_long_rounded,
            title: 'No Transactions',
            subtitle: 'When you add your first income or expense, it will appear right here.',
          )
        else
          _buildGlassContainer(
            isDark: isDark,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recent.length,
              separatorBuilder: (_, _) => Divider(
                height: 1,
                indent: 64,
                color: isDark ? Colors.white10 : Colors.black12,
              ),
              itemBuilder: (context, idx) {
                final t = recent[idx];
                final isExpense = t.type == TransactionType.expense;
                final color = isExpense
                    ? AppColors.expenseRed
                    : (t.type == TransactionType.income
                          ? AppColors.incomeGreen
                          : AppColors.infoBlue);

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 4,
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      isExpense
                          ? Icons.shopping_bag_outlined
                          : (t.type == TransactionType.income
                                ? Icons.arrow_downward_rounded
                                : Icons.swap_horiz_rounded),
                      color: color,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    t.merchant,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      '${t.categoryName} • ${t.accountName} • ${DateFormatter.formatRelative(t.date)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ),
                  trailing: Text(
                    CurrencyFormatter.format(
                      t.amount,
                      isPrivacyMode: isPrivacy,
                      showSign: true,
                    ),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: color,
                    ),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TransactionDetailScreen(
                          state: state,
                          transaction: t,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  // 6. UPCOMING BILLS SECTION
  Widget _buildUpcomingBillsSection(
    BuildContext context,
    bool isDark,
    bool isPrivacy,
  ) {
    DateTime dueDateFor(RecurringBill bill) {
      if (bill.nextDueDate != null) return bill.nextDueDate!;
      final now = DateTime.now();
      final day = bill.dueDay
          .clamp(1, DateTime(now.year, now.month + 1, 0).day)
          .toInt();
      return DateTime(now.year, now.month, day);
    }

    final upcoming =
        state.recurringBills
            .where(
              (bill) =>
                  bill.type != RecurringType.income &&
                  !bill.isPaused &&
                  !bill.isCompleted,
            )
            .toList()
          ..sort((a, b) => dueDateFor(a).compareTo(dueDateFor(b)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Upcoming Bills',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
            if (upcoming.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                color: AppColors.primary,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RecurringBillsScreen(state: state),
                    ),
                  );
                },
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (upcoming.isEmpty)
          _buildEmptyState(
            isDark: isDark,
            icon: Icons.event_busy_rounded,
            title: 'No Upcoming Bills',
            subtitle: 'You are all caught up! Add your recurring subscriptions to track them.',
          )
        else
          SizedBox(
            height: 130,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: upcoming.length,
              separatorBuilder: (_, _) => const SizedBox(width: 16),
              itemBuilder: (context, idx) {
                final bill = upcoming[idx];
                final dueDate = dueDateFor(bill);
                return Container(
                  width: 200,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurface
                        : AppColors.lightSurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.05),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              bill.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.warningOrange.withValues(
                                alpha: 0.15,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              DateFormatter.formatDateOnly(dueDate),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppColors.warningOrange,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            CurrencyFormatter.format(
                              bill.amount,
                              isPrivacyMode: isPrivacy,
                            ),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: AppColors.expenseRed,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            bill.accountName,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? AppColors.darkTextMuted
                                  : AppColors.lightTextMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  // 7. SAVINGS GOALS SECTION
  Widget _buildSavingsGoalsSection(
    BuildContext context,
    bool isDark,
    bool isPrivacy,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Active Savings Goals',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
            if (state.goals.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                color: AppColors.primary,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GoalsScreen(state: state),
                    ),
                  );
                },
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (state.goals.isEmpty)
          _buildEmptyState(
            isDark: isDark,
            icon: Icons.savings_outlined,
            title: 'No Goals Set',
            subtitle:
                'Start saving for something big. Create a goal to get started.',
          )
        else
          _buildGlassContainer(
            isDark: isDark,
            child: Column(
              children: state.goals.map((g) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            g.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            '${CurrencyFormatter.format(g.currentAmount, isPrivacyMode: isPrivacy)} / ${CurrencyFormatter.format(g.targetAmount, isPrivacyMode: isPrivacy)}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: g.progressPercentage,
                          backgroundColor: isDark
                              ? Colors.white10
                              : Colors.black12,
                          color: AppColors.incomeGreen,
                          minHeight: 10,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  // 8. FINANCIAL INSIGHTS SUMMARY
  Widget _buildFinancialInsightsSection(
    BuildContext context,
    bool isDark,
    bool isPrivacy,
  ) {
    final categoryTotals = state.categorySpending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final largestExpense =
        state.filteredTransactions
            .where((transaction) => transaction.type == TransactionType.expense)
            .toList()
          ..sort((a, b) => b.amount.compareTo(a.amount));

    final observations = <String>[];
    if (categoryTotals.isNotEmpty) {
      observations.add(
        'Top category: ${categoryTotals.first.key} (${CurrencyFormatter.format(categoryTotals.first.value, isPrivacyMode: isPrivacy)}).',
      );
    }
    if (largestExpense.isNotEmpty) {
      observations.add(
        'Largest expense: ${largestExpense.first.merchant} (${CurrencyFormatter.format(largestExpense.first.amount, isPrivacyMode: isPrivacy)}).',
      );
    }

    if (observations.isEmpty) {
      return _buildEmptyState(
        isDark: isDark,
        icon: Icons.lightbulb_outline_rounded,
        title: 'No Insights Yet',
        subtitle: 'Once you start adding transactions, your AI-driven financial insights will appear here.',
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lightbulb_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Financial Observation',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            observations.map((observation) => '• $observation').join('\n\n'),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.5,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
