import 'dart:io';
import 'package:flutter/material.dart';
import 'package:expensetracker/providers/app_state.dart';
import 'package:expensetracker/theme/app_theme.dart';
import 'package:expensetracker/utils/currency_formatter.dart';
import 'package:expensetracker/utils/date_formatter.dart';
import 'package:expensetracker/screens/receipts/receipt_viewer_screen.dart';

class ReceiptsScreen extends StatelessWidget {
  final AppState state;
  const ReceiptsScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final isDark = state.profile.isDarkMode;
    final isPrivacy = state.profile.isPrivacyModeEnabled;
    final symbol = state.profile.currencySymbol;

    // Filter transactions that have receipt attached
    final receiptTxs = state.transactions
        .where((t) => t.receiptImagePath != null && t.receiptImagePath!.isNotEmpty)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Receipts'),
      ),
      body: receiptTxs.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                      child: const Icon(Icons.receipt_long_rounded, size: 36, color: AppColors.primary),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Receipts Attached Yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Attach receipt photos when adding or editing transactions. All images stay 100% offline on your device.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.75,
              ),
              itemCount: receiptTxs.length,
              itemBuilder: (context, index) {
                final tx = receiptTxs[index];
                final file = File(tx.receiptImagePath!);
                final exists = file.existsSync();

                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReceiptViewerScreen(
                          imagePath: tx.receiptImagePath!,
                          transaction: tx,
                          state: state,
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Container(
                            color: Colors.black12,
                            width: double.infinity,
                            child: exists
                                ? Image.file(file, fit: BoxFit.cover)
                                : const Center(
                                    child: Icon(Icons.broken_image_rounded, size: 40, color: Colors.grey),
                                  ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tx.merchant.isNotEmpty ? tx.merchant : tx.categoryName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    CurrencyFormatter.format(tx.amount, symbol: symbol, isPrivacyMode: isPrivacy),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  Text(
                                    DateFormatter.formatDateOnly(tx.date),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
