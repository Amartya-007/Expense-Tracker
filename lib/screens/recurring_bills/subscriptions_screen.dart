import 'package:flutter/material.dart';
import 'package:expensetracker/providers/app_state.dart';
import 'package:expensetracker/models/recurring_bill.dart';
import 'package:expensetracker/theme/app_theme.dart';
import 'package:expensetracker/utils/currency_formatter.dart';

class SubscriptionsScreen extends StatelessWidget {
  final AppState state;
  const SubscriptionsScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final isDark = state.profile.isDarkMode;
    final isPrivacy = state.profile.isPrivacyModeEnabled;

    final subs = state.recurringBills.where((b) => b.type == RecurringType.subscription || b.title.toLowerCase().contains('netflix')).toList();
    final double subTotal = subs.fold(0.0, (sum, s) => sum + s.amount);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscriptions Manager'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: AppColors.primary.withValues(alpha: 0.12),
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL SUBSCRIPTIONS SPEND',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'You spend ${CurrencyFormatter.format(subTotal, isPrivacyMode: isPrivacy)} monthly on active subscriptions.',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Active Digital Subscriptions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
            const SizedBox(height: 8),
            Card(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: subs.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, idx) {
                  final s = subs[idx];
                  return ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.infoBlue,
                      child: Icon(Icons.subscriptions_rounded, color: Colors.white, size: 20),
                    ),
                    title: Text(s.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text('Due day: ${s.dueDay} • ${s.accountName}'),
                    trailing: Text(
                      CurrencyFormatter.format(s.amount, isPrivacyMode: isPrivacy),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.expenseRed),
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
}
