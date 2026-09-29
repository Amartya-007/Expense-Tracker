import 'package:flutter/material.dart';
import 'package:expensetracker/providers/app_state.dart';
import 'package:expensetracker/models/transaction.dart';
import 'package:expensetracker/theme/app_theme.dart';
import 'package:expensetracker/utils/currency_formatter.dart';
import 'package:expensetracker/utils/voice_parser.dart';
import 'package:expensetracker/services/haptic_service.dart';

class QuickAddSheet extends StatefulWidget {
  final AppState state;
  const QuickAddSheet({super.key, required this.state});

  @override
  State<QuickAddSheet> createState() => _QuickAddSheetState();
}

class _QuickAddSheetState extends State<QuickAddSheet> {
  final List<Map<String, dynamic>> quickItems = const [
    {'title': 'Chai / Tea', 'amount': 80.0, 'category': 'Food & Dining', 'merchant': 'Tea Shop', 'account': 'acc_cash'},
    {'title': 'Lunch / Swiggy', 'amount': 400.0, 'category': 'Food & Dining', 'merchant': 'Swiggy', 'account': 'acc_hdfc'},
    {'title': 'Cab / Uber', 'amount': 250.0, 'category': 'Transport', 'merchant': 'Uber', 'account': 'acc_hdfc'},
    {'title': 'Petrol / Fuel', 'amount': 1000.0, 'category': 'Fuel', 'merchant': 'Fuel Station', 'account': 'acc_icici_card'},
    {'title': 'Groceries', 'amount': 500.0, 'category': 'Groceries', 'merchant': 'Local Store', 'account': 'acc_hdfc'},
  ];

  void _showVoiceInputModal() {
    HapticService.selection();
    final textController = TextEditingController(text: 'Spent 350 on coffee via UPI');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Voice-Powered Quick Add'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Speak or type your transaction sentence (e.g. "Spent 250 on coffee via UPI" or "Received 25000 salary"):',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: textController,
                maxLines: 2,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'e.g. Spent 500 for dinner using cash',
                ),
              ),
              const SizedBox(height: 16),
              const Text('Extracted Draft Preview:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              Builder(
                builder: (context) {
                  final parsed = VoiceParser.parse(textController.text);
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Type: ${parsed.type == TransactionType.expense ? "Expense" : "Income"}', style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text('Amount: ${CurrencyFormatter.format(parsed.amount)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text('Merchant: ${parsed.merchant}'),
                        Text('Category: ${parsed.categorySuggestion}'),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final parsed = VoiceParser.parse(textController.text);
                if (parsed.amount <= 0) return;

                final cat = widget.state.categories.firstWhere(
                  (c) => c.name.toLowerCase().contains(parsed.categorySuggestion.toLowerCase()),
                  orElse: () => widget.state.categories.first,
                );
                final acc = widget.state.accounts.isNotEmpty ? widget.state.accounts.first : null;

                final t = TransactionItem(
                  id: 'voice_${DateTime.now().millisecondsSinceEpoch}',
                  type: parsed.type,
                  amount: parsed.amount,
                  categoryId: cat.id,
                  categoryName: cat.name,
                  accountId: acc?.id ?? 'default_acc',
                  accountName: acc?.name ?? 'Main Account',
                  merchant: parsed.merchant,
                  note: 'Voice added: ${parsed.note}',
                  date: DateTime.now(),
                  source: 'voice',
                );

                await widget.state.addTransaction(t);
                HapticService.success();
                if (context.mounted) {
                  Navigator.pop(context); // close dialog
                  Navigator.pop(context); // close sheet
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Saved voice transaction: ${CurrencyFormatter.format(parsed.amount)} at ${parsed.merchant}'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: const Text('Confirm & Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.state.profile.isDarkMode;

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
          Row(
            children: [
              Expanded(
                child: Text(
                  'Tap any item to instantly record, or use voice input.',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showVoiceInputModal,
                icon: const Icon(Icons.mic_rounded, size: 18),
                label: const Text('Voice Add'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: quickItems.map((item) {
              return InkWell(
                onTap: () async {
                  HapticService.selection();
                  final cat = widget.state.categories.firstWhere(
                    (c) => c.name == item['category'],
                    orElse: () => widget.state.categories.first,
                  );
                  final acc = widget.state.accounts.firstWhere(
                    (a) => a.id == item['account'],
                    orElse: () => widget.state.accounts.first,
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

                  await widget.state.addTransaction(t);
                  HapticService.success();
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
