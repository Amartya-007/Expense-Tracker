import 'package:flutter/material.dart';
import 'package:expensetracker/providers/app_state.dart';
import 'package:expensetracker/models/transaction.dart';
import 'package:expensetracker/theme/app_theme.dart';
import 'package:expensetracker/utils/currency_formatter.dart';
import 'package:expensetracker/utils/date_formatter.dart';
import 'package:expensetracker/screens/add_transaction/add_transaction_sheet.dart';
import 'package:expensetracker/screens/transactions/split_transaction_screen.dart';

class TransactionDetailScreen extends StatelessWidget {
  final AppState state;
  final TransactionItem transaction;

  const TransactionDetailScreen({
    super.key,
    required this.state,
    required this.transaction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = state.profile.isDarkMode;
    final isPrivacy = state.profile.isPrivacyModeEnabled;
    final isExpense = transaction.type == TransactionType.expense;

    final color = isExpense
        ? AppColors.expenseRed
        : (transaction.type == TransactionType.income
            ? AppColors.incomeGreen
            : AppColors.infoBlue);

    // Dynamic surface colors for modern flat design
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: primaryTextColor,
          ),
        ),
        iconTheme: IconThemeData(color: primaryTextColor),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            splashRadius: 24,
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => AddTransactionSheet(
                  state: state,
                  initialTransaction: transaction,
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            splashRadius: 24,
            onPressed: () => _confirmDelete(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // HERO HEADER: Breathing space, big text, no rigid card
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isExpense
                    ? Icons.shopping_bag_rounded
                    : (transaction.type == TransactionType.income
                        ? Icons.arrow_downward_rounded
                        : Icons.swap_horiz_rounded),
                color: color,
                size: 36,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              transaction.merchant,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: secondaryTextColor,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              CurrencyFormatter.format(
                transaction.amount,
                isPrivacyMode: isPrivacy,
                showSign: true,
              ),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 44,
                fontWeight: FontWeight.w800,
                color: color,
                letterSpacing: -1.5,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: borderColor),
              ),
              child: Text(
                transaction.categoryName,
                style: TextStyle(
                  color: primaryTextColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 40),

            // WHY DID YOU SPEND THIS? (MEMORY SYSTEM)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: transaction.note.isNotEmpty 
                      ? color.withValues(alpha: 0.3) 
                      : borderColor,
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.psychology_rounded,
                        color: transaction.note.isNotEmpty ? color : secondaryTextColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Note / Memory',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    transaction.note.isNotEmpty
                        ? transaction.note
                        : 'No note added. Tap edit to add why this payment was made.',
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      fontWeight: transaction.note.isNotEmpty
                          ? FontWeight.w500
                          : FontWeight.w400,
                      color: transaction.note.isNotEmpty
                          ? primaryTextColor
                          : secondaryTextColor.withValues(alpha: 0.7),
                      fontStyle: transaction.note.isNotEmpty
                          ? FontStyle.normal
                          : FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // METADATA CONTAINER
            Container(
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                children: [
                  _detailRow(
                    'Date & Time',
                    DateFormatter.formatRelative(transaction.date),
                    primaryTextColor,
                    secondaryTextColor,
                  ),
                  Divider(height: 1, color: borderColor, indent: 20, endIndent: 20),
                  _detailRow(
                    'Account', 
                    transaction.accountName, 
                    primaryTextColor,
                    secondaryTextColor,
                  ),
                  if (transaction.type == TransactionType.transfer &&
                      transaction.toAccountName != null) ...[
                    Divider(height: 1, color: borderColor, indent: 20, endIndent: 20),
                    _detailRow(
                      'Transferred To',
                      transaction.toAccountName!,
                      primaryTextColor,
                      secondaryTextColor,
                    ),
                  ],
                  Divider(height: 1, color: borderColor, indent: 20, endIndent: 20),
                  _detailRow(
                    'Source',
                    transaction.source == 'autoCaptured'
                        ? 'Auto-captured (SMS)'
                        : 'Added Manually',
                    primaryTextColor,
                    secondaryTextColor,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // TAGS
            if (transaction.tags.isNotEmpty) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 12),
                  child: Text(
                    'TAGS',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      letterSpacing: 1.2,
                      color: secondaryTextColor,
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: transaction.tags
                      .map(
                        (tag) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: surfaceColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderColor),
                          ),
                          child: Text(
                            '#$tag',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: primaryTextColor,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // RECEIPT PREVIEW
            if (transaction.receiptImagePath != null) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 12),
                  child: Text(
                    'RECEIPT',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      letterSpacing: 1.2,
                      color: secondaryTextColor,
                    ),
                  ),
                ),
              ),
              Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.receipt_long_rounded,
                      size: 40,
                      color: secondaryTextColor.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Receipt Attached',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: primaryTextColor,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],

            // SPLIT TRANSACTION ACTION
            SizedBox(
              width: double.infinity,
              height: 56, // Modern, taller button size
              child: OutlinedButton.icon(
                icon: const Icon(Icons.call_split_rounded, size: 22),
                label: const Text(
                  'Split Across Categories',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryTextColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  side: BorderSide(color: borderColor, width: 1.5),
                  backgroundColor: surfaceColor,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SplitTransactionScreen(
                        state: state,
                        transaction: transaction,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, Color primaryText, Color secondaryText) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: secondaryText,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: primaryText,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text('Delete Transaction?'),
          content: const Text(
            'The account balance will be adjusted. You can undo the deletion from the next message.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.lightTextSecondary,
              ),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.expenseRed,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                await state.deleteTransaction(transaction.id);
                if (ctx.mounted) {
                  final messenger = ScaffoldMessenger.of(context);
                  Navigator.pop(ctx); // Close dialog
                  Navigator.pop(context); // Close detail screen
                  messenger.showSnackBar(
                    SnackBar(
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      content: const Text('Transaction deleted'),
                      action: SnackBarAction(
                        label: 'Undo',
                        onPressed: () =>
                            state.restoreDeletedTransaction(transaction),
                      ),
                    ),
                  );
                }
              },
              child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}