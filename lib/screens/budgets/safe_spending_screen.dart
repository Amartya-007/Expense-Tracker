import 'package:flutter/material.dart';
import 'package:expensetracker/providers/app_state.dart';
import 'package:expensetracker/theme/app_theme.dart';
import 'package:expensetracker/utils/currency_formatter.dart';

class SafeSpendingScreen extends StatelessWidget {
  final AppState state;
  const SafeSpendingScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final isDark = state.profile.isDarkMode;
    final isPrivacy = state.profile.isPrivacyModeEnabled;

    final availableNow = state.totalAvailableMoney;
    final upcomingBills = state.upcomingBillsTotal;
    final plannedSavings = state.plannedSavingsTotal;
    final safeToSpend = state.availableToSpend;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Available to Spend'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // HERO SAFE SPEND CARD
            Card(
              color: AppColors.primary.withValues(alpha: 0.12),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const Icon(Icons.verified_user_rounded, size: 48, color: AppColors.primary),
                    const SizedBox(height: 12),
                    Text(
                      'ESTIMATED SAFE TO SPEND',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      CurrencyFormatter.format(safeToSpend, isPrivacyMode: isPrivacy),
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This is what you can spend today without missing upcoming bills or savings goals.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // BREAKDOWN CARD
            Card(
              child: Column(
                children: [
                  _row('Total Cash & Bank Balance', availableNow, AppColors.incomeGreen, isPrivacy, isDark),
                  const Divider(height: 1),
                  _row('Upcoming Recorded Bills', -upcomingBills, AppColors.expenseRed, isPrivacy, isDark),
                  const Divider(height: 1),
                  _row('Planned Goal Contributions', -plannedSavings, AppColors.warningOrange, isPrivacy, isDark),
                  const Divider(height: 1),
                  _row('Calculated Safe Spendable', safeToSpend, AppColors.primary, isPrivacy, isDark, isBold: true),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // DISCLAIMER CARD
            Card(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: AppColors.infoBlue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Note: Safe spending estimation is based entirely on records added to RupeeCommand.',
                        style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                      ),
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

  Widget _row(String title, double amount, Color color, bool isPrivacy, bool isDark, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          Text(
            CurrencyFormatter.format(amount, isPrivacyMode: isPrivacy, showSign: true),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
