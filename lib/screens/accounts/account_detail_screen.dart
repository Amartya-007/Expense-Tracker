import 'package:flutter/material.dart';
import 'package:expensetracker/providers/app_state.dart';
import 'package:expensetracker/models/account.dart';
import 'package:expensetracker/models/transaction.dart';
import 'package:expensetracker/theme/app_theme.dart';
import 'package:expensetracker/utils/currency_formatter.dart';
import 'package:expensetracker/utils/date_formatter.dart';
import 'package:expensetracker/screens/transactions/transaction_detail_screen.dart';

class AccountDetailScreen extends StatelessWidget {
  final AppState state;
  final Account account;

  const AccountDetailScreen({
    super.key,
    required this.state,
    required this.account,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = state.profile.isDarkMode;
    final isPrivacy = state.profile.isPrivacyModeEnabled;
    final isCreditCard = account.type == AccountType.creditCard;

    final accountTransactions = state.transactions
        .where((t) => t.accountId == account.id || t.toAccountId == account.id)
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text(account.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // TOP ACCOUNT SUMMARY
            Card(
              color: Color(account.colorHex).withValues(alpha: 0.12),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Text(
                      isCreditCard
                          ? 'CURRENT OUTSTANDING'
                          : 'AVAILABLE BALANCE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      CurrencyFormatter.format(
                        account.balance,
                        isPrivacyMode: isPrivacy,
                      ),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: isCreditCard
                            ? AppColors.expenseRed
                            : AppColors.primary,
                      ),
                    ),
                    if (account.accountNumber != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Account Number •••• ${account.accountNumber}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                    if (isCreditCard && account.creditLimit != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Limit: ${CurrencyFormatter.format(account.creditLimit!, isPrivacyMode: isPrivacy)}',
                      ),
                      Text(
                        'Available credit: ${CurrencyFormatter.format((account.creditLimit! - account.balance).clamp(0, double.infinity).toDouble(), isPrivacyMode: isPrivacy)}',
                      ),
                    ],
                    if (isCreditCard && account.minDue != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Minimum due: ${CurrencyFormatter.format(account.minDue!, isPrivacyMode: isPrivacy)}',
                      ),
                    ],
                    if (isCreditCard && account.dueDate != null) ...[
                      const SizedBox(height: 4),
                      Text('Payment due: ${account.dueDate}'),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.sync_alt_rounded),
                label: Text(
                  isCreditCard
                      ? 'Reconcile Card Outstanding'
                      : 'Reconcile Current Balance',
                ),
                onPressed: () => _reconcileBalance(context),
              ),
            ),
            if (account.lastReconciledAt != null) ...[
              const SizedBox(height: 6),
              Text(
                'Last reconciled ${DateFormatter.formatDateOnly(account.lastReconciledAt!)}',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
            ],
            const SizedBox(height: 16),

            // ATM WITHDRAWAL BUTTON FOR BANK & CASH
            if (account.type == AccountType.bank)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.atm_rounded),
                  label: const Text('Record ATM Cash Withdrawal'),
                  onPressed: () => _recordAtmWithdrawal(context),
                ),
              ),
            const SizedBox(height: 16),

            // RECENT TRANSACTIONS FOR THIS ACCOUNT
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Account Transactions (${accountTransactions.length})',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: accountTransactions.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('No transactions recorded for this account.'),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: accountTransactions.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, idx) {
                        final t = accountTransactions[idx];
                        final isExpense = t.type == TransactionType.expense;
                        final color = isExpense
                            ? AppColors.expenseRed
                            : AppColors.incomeGreen;

                        return ListTile(
                          title: Text(
                            t.merchant,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            '${t.categoryName} • ${DateFormatter.formatDateOnly(t.date)}',
                          ),
                          trailing: Text(
                            CurrencyFormatter.format(
                              t.amount,
                              isPrivacyMode: isPrivacy,
                              showSign: true,
                            ),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
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
        ),
      ),
    );
  }

  void _reconcileBalance(BuildContext context) {
    final controller = TextEditingController(
      text: account.balance.toStringAsFixed(2),
    );
    final formKey = GlobalKey<FormState>();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reconcile Account Balance'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter the current balance shown by your bank or card statement. This updates the account balance without counting the difference as income or spending.',
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: controller,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: account.type == AccountType.creditCard
                      ? 'Current outstanding (INR)'
                      : 'Current balance (INR)',
                  prefixText: '₹ ',
                ),
                validator: (value) {
                  final amount = double.tryParse(value?.trim() ?? '');
                  if (amount == null || !amount.isFinite || amount < 0) {
                    return 'Enter a valid balance';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!(formKey.currentState?.validate() ?? false)) return;
              await state.reconcileAccount(
                account.id,
                double.parse(controller.text.trim()),
              );
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: const Text('Save Balance'),
          ),
        ],
      ),
    );
  }

  void _recordAtmWithdrawal(BuildContext context) {
    final cashAccounts = state.accounts.where((a) => a.type == AccountType.cash).toList();
    if (cashAccounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please create a Cash Wallet account first.')),
      );
      return;
    }
    final cashAcc = cashAccounts.first;
    final amountController = TextEditingController(text: '5000');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('ATM Cash Withdrawal'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Withdraw money from ${account.name} to ${cashAcc.name}.'),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Amount (INR)',
                  prefixText: '₹ ',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final amt = double.tryParse(amountController.text.trim()) ?? 0.0;
                if (amt <= 0 || !amt.isFinite) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid positive withdrawal amount')),
                  );
                  return;
                }
                final transfer = TransactionItem(
                  id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
                  type: TransactionType.transfer,
                  amount: amt,
                  categoryId: 'cat_transfer',
                  categoryName: 'Transfer',
                  accountId: account.id,
                  accountName: account.name,
                  toAccountId: cashAcc.id,
                  toAccountName: cashAcc.name,
                  merchant: 'ATM Cash Withdrawal',
                  note: 'Withdrawal from ${account.name} to ${cashAcc.name}',
                  date: DateTime.now(),
                );
                await state.addTransaction(transfer);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Confirm Withdrawal'),
            ),
          ],
        );
      },
    );
  }
}
