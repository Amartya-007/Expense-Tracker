import 'package:flutter/material.dart';
import 'package:expensetracker/providers/app_state.dart';
import 'package:expensetracker/models/transaction.dart';
import 'package:expensetracker/theme/app_theme.dart';
import 'package:expensetracker/utils/currency_formatter.dart';

class QuickAddSheet extends StatelessWidget {
  final AppState state;
  const QuickAddSheet({super.key, required this.state});

  final List<Map<String, dynamic>> quickItems = const [
    {'title': 'Chai / Tea', 'amount': 80.0, 'category': 'Food & Dining', 'merchant': 'Tea Shop', 'account': 'acc_cash'},
    {'title': 'Lunch / Swiggy', 'amount': 400.0, 'category': 'Food & Dining', 'merchant': 'Swiggy', 'account': 'acc_hdfc'},
    {'title': 'Cab / Uber', 'amount': 250.0, 'category': 'Transport', 'merchant': 'Uber', 'account': 'acc_hdfc'},
    {'title': 'Petrol / Fuel', 'amount': 1000.0, 'category': 'Fuel', 'merchant': 'Fuel Station', 'account': 'acc_icici_card'},
    {'title': 'Groceries', 'amount': 500.0, 'category': 'Groceries', 'merchant': 'Local Store', 'account': 'acc_hdfc'},
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = state.profile.isDarkMode;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Quick Add Shortcuts',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Tap any item to instantly record a frequent expense.',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: quickItems.map((item) {
              return InkWell(
                onTap: () async {
                  final cat = state.categories.firstWhere(
                    (c) => c.name == item['category'],
                    orElse: () => state.categories.first,
                  );
                  final acc = state.accounts.firstWhere(
                    (a) => a.id == item['account'],
                    orElse: () => state.accounts.first,
                  );

                  final t = TransactionItem(
                    id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
                    type: TransactionType.expense,
                    amount: item['amount'],
                    categoryId: cat.id,
                    categoryName: cat.name,
                    accountId: acc.id,
                    accountName: acc.name,
                    merchant: item['merchant'],
                    note: 'Quick added ${item['title']}',
                    date: DateTime.now(),
                  );

                  await state.addTransaction(t);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Added ${item['title']} (${CurrencyFormatter.format(item['amount'])})'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item['title'],
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.expenseRed.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          CurrencyFormatter.format(item['amount']),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.expenseRed,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
