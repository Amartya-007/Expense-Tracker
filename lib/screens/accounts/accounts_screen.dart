import 'package:flutter/material.dart';
import 'package:expensetracker/providers/app_state.dart';
import 'package:expensetracker/models/account.dart';
import 'package:expensetracker/theme/app_theme.dart';
import 'package:expensetracker/utils/currency_formatter.dart';
import 'package:expensetracker/screens/accounts/account_detail_screen.dart';

class AccountsScreen extends StatelessWidget {
  final AppState state;
  const AccountsScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final isDark = state.profile.isDarkMode;
    final isPrivacy = state.profile.isPrivacyModeEnabled;

    final liquidAccounts = state.accounts
        .where((a) => a.type != AccountType.creditCard)
        .toList();
    final creditCards = state.accounts
        .where((a) => a.type == AccountType.creditCard)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accounts & Cards'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showAddAccountDialog(context),
          ),
        ],
      ),
      body: state.accounts.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.account_balance_rounded,
                    size: 64,
                    color: isDark ? Colors.white24 : Colors.black26,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No accounts yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to add your first bank account, wallet, or card',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // LIQUID ASSETS SUMMARY
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TOTAL AVAILABLE LIQUID MONEY',
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
                              state.totalAvailableMoney,
                              isPrivacyMode: isPrivacy,
                            ),
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppColors.incomeGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (liquidAccounts.isNotEmpty) ...[
                    _sectionHeader('CASH & BANK ACCOUNTS', isDark),
                    Card(
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: liquidAccounts.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1),
                        itemBuilder: (context, idx) {
                          final acc = liquidAccounts[idx];
                          return Dismissible(
                            key: Key(acc.id),
                            direction: DismissDirection.endToStart,
                            confirmDismiss: (_) =>
                                _confirmDeleteAccount(context, acc),
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              color: AppColors.expenseRed,
                              child: const Icon(
                                Icons.delete_rounded,
                                color: Colors.white,
                              ),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Color(acc.colorHex)
                                    .withValues(alpha: 0.12),
                                child: Icon(
                                  _getAccountIcon(acc.type),
                                  color: Color(acc.colorHex),
                                ),
                              ),
                              title: Text(
                                acc.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Text(
                                acc.accountNumber != null
                                    ? 'A/C •••• ${acc.accountNumber}'
                                    : acc.type.name.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary,
                                ),
                              ),
                              trailing: Text(
                                CurrencyFormatter.format(
                                  acc.balance,
                                  isPrivacyMode: isPrivacy,
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AccountDetailScreen(
                                      state: state,
                                      account: acc,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  if (creditCards.isNotEmpty) ...[
                    _sectionHeader('CREDIT CARDS & LIABILITIES', isDark),
                    Card(
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: creditCards.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1),
                        itemBuilder: (context, idx) {
                          final card = creditCards[idx];
                          return Dismissible(
                            key: Key(card.id),
                            direction: DismissDirection.endToStart,
                            confirmDismiss: (_) =>
                                _confirmDeleteAccount(context, card),
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              color: AppColors.expenseRed,
                              child: const Icon(
                                Icons.delete_rounded,
                                color: Colors.white,
                              ),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppColors.expenseRed
                                    .withValues(alpha: 0.12),
                                child: const Icon(
                                  Icons.credit_card_rounded,
                                  color: AppColors.expenseRed,
                                ),
                              ),
                              title: Text(
                                card.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Text(
                                'Due ${card.dueDate ?? 'N/A'} • Min Due: ${CurrencyFormatter.format(card.minDue ?? 0, isPrivacyMode: isPrivacy)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary,
                                ),
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    CurrencyFormatter.format(
                                      card.balance,
                                      isPrivacyMode: isPrivacy,
                                    ),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: AppColors.expenseRed,
                                    ),
                                  ),
                                  const Text(
                                    'Outstanding',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: AppColors.expenseRed,
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AccountDetailScreen(
                                      state: state,
                                      account: card,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _sectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 6),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
          color: isDark
              ? AppColors.darkTextSecondary
              : AppColors.lightTextSecondary,
        ),
      ),
    );
  }

  IconData _getAccountIcon(AccountType type) {
    switch (type) {
      case AccountType.bank:
        return Icons.account_balance_rounded;
      case AccountType.cash:
        return Icons.payments_rounded;
      case AccountType.creditCard:
        return Icons.credit_card_rounded;
      case AccountType.wallet:
        return Icons.account_balance_wallet_rounded;
      default:
        return Icons.savings_rounded;
    }
  }

  Future<bool?> _confirmDeleteAccount(BuildContext context, Account acc) async {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account?'),
        content: Text(
          'Are you sure you want to delete "${acc.name}"? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              state.deleteAccount(acc.id);
              Navigator.pop(ctx, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.expenseRed,
            ),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddAccountDialog(BuildContext context) {
    final nameController = TextEditingController();
    final balanceController = TextEditingController();
    final accountNumberController = TextEditingController();
    final creditLimitController = TextEditingController();
    final minimumDueController = TextEditingController();
    final lowBalanceThresholdController = TextEditingController();
    int? cardDueDay;
    AccountType type = AccountType.bank;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Add Account / Card'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Account Name (e.g. Axis Bank)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: balanceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: type == AccountType.creditCard
                            ? 'Current Outstanding (INR)'
                            : 'Current Balance (INR)',
                        prefixText: '₹ ',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: accountNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Last 4 digits (optional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLength: 4,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Account Type',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    SegmentedButton<AccountType>(
                      segments: const [
                        ButtonSegment(
                          value: AccountType.bank,
                          label: Text('Bank'),
                        ),
                        ButtonSegment(
                          value: AccountType.cash,
                          label: Text('Cash'),
                        ),
                        ButtonSegment(
                          value: AccountType.wallet,
                          label: Text('Wallet'),
                        ),
                        ButtonSegment(
                          value: AccountType.creditCard,
                          label: Text('Card'),
                        ),
                      ],
                      selected: {type},
                      onSelectionChanged: (s) =>
                          setDialogState(() => type = s.first),
                    ),
                    if (type == AccountType.creditCard) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: creditLimitController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Credit Limit (optional)',
                          prefixText: '₹ ',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: minimumDueController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Minimum Due (optional)',
                          prefixText: '₹ ',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        initialValue: cardDueDay,
                        decoration: const InputDecoration(
                          labelText: 'Payment Due Day (optional)',
                          border: OutlineInputBorder(),
                        ),
                        items: List.generate(31, (index) => index + 1)
                            .map(
                              (day) => DropdownMenuItem(
                                value: day,
                                child: Text('Day $day'),
                              ),
                            )
                            .toList(),
                        onChanged: (day) =>
                            setDialogState(() => cardDueDay = day),
                      ),
                    ],
                    if (type != AccountType.creditCard) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: lowBalanceThresholdController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Low Balance Alert Below (optional)',
                          prefixText: '₹ ',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color:
                            (type == AccountType.bank
                                    ? const Color(0xFF1E3A8A)
                                    : type == AccountType.cash
                                    ? const Color(0xFF10B981)
                                    : type == AccountType.wallet
                                    ? const Color(0xFF0284C7)
                                    : const Color(0xFFEA580C))
                                .withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.grey.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            '🏦  Bank — Savings/Current account (Axis/HDFC/SBI).\nPaytm/GPay UPI payments deduct from here.',
                            style: TextStyle(fontSize: 12, height: 1.4),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '💵  Cash — Physical cash in your wallet/purse.',
                            style: TextStyle(fontSize: 12, height: 1.4),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '👛  Wallet — ONLY for money stored IN Paytm/PhonePe Wallet.\n'
                            '   ❗ Paytm UPI linked to bank → use Bank, NOT Wallet.',
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.4,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '💳  Card — Credit card OUTSTANDING (what you owe, NOT your limit).',
                            style: TextStyle(fontSize: 12, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tip: The balance you enter is the starting snapshot.\n'
                      'Later add income/expense transactions to track movement.',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isEmpty) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Please enter an account name')),
                      );
                      return;
                    }
                    final parsedBal = double.tryParse(balanceController.text.trim());
                    final balance = (parsedBal == null || !parsedBal.isFinite || parsedBal < 0) ? 0.0 : parsedBal;

                    final acc = Account(
                      id: 'acc_${DateTime.now().millisecondsSinceEpoch}',
                      name: name,
                      type: type,
                      balance: balance,
                      startingBalance: balance,
                      creditLimit: type == AccountType.creditCard
                          ? double.tryParse(creditLimitController.text.trim())
                          : null,
                      minDue: type == AccountType.creditCard
                          ? double.tryParse(minimumDueController.text.trim())
                          : null,
                      lowBalanceThreshold: type != AccountType.creditCard
                          ? double.tryParse(lowBalanceThresholdController.text.trim())
                          : null,
                      dueDate:
                          type == AccountType.creditCard && cardDueDay != null
                          ? 'Day $cardDueDay of each month'
                          : null,
                      accountNumber:
                          accountNumberController.text.trim().isNotEmpty
                          ? accountNumberController.text.trim()
                          : null,
                      colorHex: _getColorForType(type),
                      iconName: _getIconNameForType(type),
                    );
                    state.addAccount(acc);
                    Navigator.pop(ctx);
                  },
                  child: const Text('Save Account'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  int _getColorForType(AccountType type) {
    switch (type) {
      case AccountType.bank:
        return 0xFF1E3A8A;
      case AccountType.cash:
        return 0xFF10B981;
      case AccountType.wallet:
        return 0xFF0284C7;
      case AccountType.creditCard:
        return 0xFFEA580C;
      default:
        return 0xFF6366F1;
    }
  }

  String _getIconNameForType(AccountType type) {
    switch (type) {
      case AccountType.bank:
        return 'account_balance';
      case AccountType.cash:
        return 'payments';
      case AccountType.wallet:
        return 'account_balance_wallet';
      case AccountType.creditCard:
        return 'credit_card';
      default:
        return 'savings';
    }
  }
}
