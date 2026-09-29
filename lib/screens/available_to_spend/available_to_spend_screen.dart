import 'package:flutter/material.dart';
import 'package:expensetracker/providers/app_state.dart';
import 'package:expensetracker/theme/app_theme.dart';
import 'package:expensetracker/utils/currency_formatter.dart';

class AvailableToSpendScreen extends StatelessWidget {
  final AppState state;
  const AvailableToSpendScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final isDark = state.profile.isDarkMode;
    final isPrivacy = state.profile.isPrivacyModeEnabled;
    final symbol = state.profile.currencySymbol;

    // Financial calculations
    final availableMoney = state.totalAvailableMoney;

    final upcomingBillsTotal = state.upcomingBillsTotal;
    final plannedSavingsTotal = state.plannedSavingsTotal;
    final availableToSpend = state.availableToSpend;

    // Days remaining in month
    final now = DateTime.now();
    final lastDay = DateTime(now.year, now.month + 1, 0).day;
    final daysRemaining = (lastDay - now.day + 1).clamp(1, 31);
    final approxDailySpend = availableToSpend / daysRemaining;

    return Scaffold(
      appBar: AppBar(title: const Text('Available to Spend')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // HERO SUMMARY CARD
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'SAFE TO SPEND THIS MONTH',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.incomeGreen.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$daysRemaining days left',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.incomeGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    CurrencyFormatter.format(
                      availableToSpend,
                      symbol: symbol,
                      isPrivacyMode: isPrivacy,
                    ),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.today_rounded,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Approx. daily spend: ${CurrencyFormatter.format(approxDailySpend, symbol: symbol, isPrivacyMode: isPrivacy)} / day',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // WATERFALL FORMULA BREAKDOWN
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Budget Deduction Breakdown',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 16),
                  _breakdownRow(
                    icon: Icons.account_balance_wallet_rounded,
                    color: AppColors.incomeGreen,
                    title: 'Available Money (Bank & Cash)',
                    amount: availableMoney,
                    symbol: symbol,
                    isPrivacy: isPrivacy,
                    isPositive: true,
                  ),
                  const Divider(height: 24),
                  _breakdownRow(
                    icon: Icons.receipt_long_rounded,
                    color: AppColors.expenseRed,
                    title: 'Upcoming Unpaid Bills',
                    amount: upcomingBillsTotal,
                    symbol: symbol,
                    isPrivacy: isPrivacy,
                    isPositive: false,
                  ),
                  const Divider(height: 24),
                  _breakdownRow(
                    icon: Icons.savings_rounded,
                    color: AppColors.infoBlue,
                    title: 'Planned Savings Goals',
                    amount: plannedSavingsTotal,
                    symbol: symbol,
                    isPrivacy: isPrivacy,
                    isPositive: false,
                  ),
                  const Divider(thickness: 1.5, height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Net Available to Spend',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        CurrencyFormatter.format(
                          availableToSpend,
                          symbol: symbol,
                          isPrivacyMode: isPrivacy,
                        ),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // DISCLAIMER CARD
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.amber.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.amber.shade200.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 20,
                  color: Colors.amber.shade800,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Estimate based on recorded local data. Not live bank balances or financial advice. Ensure your accounts and recurring bills are up to date.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : Colors.amber.shade900,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _breakdownRow({
    required IconData icon,
    required Color color,
    required String title,
    required double amount,
    required String symbol,
    required bool isPrivacy,
    required bool isPositive,
  }) {
    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
        Text(
          '${isPositive ? '+' : '-'}${CurrencyFormatter.format(amount, symbol: symbol, isPrivacyMode: isPrivacy)}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isPositive ? AppColors.incomeGreen : AppColors.expenseRed,
          ),
        ),
      ],
    );
  }
}
