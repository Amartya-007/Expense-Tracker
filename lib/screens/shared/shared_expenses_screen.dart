import 'package:flutter/material.dart';
import 'package:expensetracker/providers/app_state.dart';
import 'package:expensetracker/models/shared_expense.dart';
import 'package:expensetracker/theme/app_theme.dart';
import 'package:expensetracker/utils/currency_formatter.dart';
import 'package:expensetracker/utils/date_formatter.dart';

class SharedExpensesScreen extends StatelessWidget {
  final AppState state;
  const SharedExpensesScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final isDark = state.profile.isDarkMode;
    final isPrivacy = state.profile.isPrivacyModeEnabled;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shared Expenses & Split'),
        actions: [
          IconButton(
            tooltip: 'Add shared expense',
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showAddExpenseDialog(context),
          ),
        ],
      ),
      body: state.sharedExpenses.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.group_outlined,
                      size: 56,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No shared expenses yet',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Add an expense and split it between people. Mark each share settled when they pay you.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: () => _showAddExpenseDialog(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Add shared expense'),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.sharedExpenses.length,
              itemBuilder: (context, idx) {
                final item = state.sharedExpenses[idx];

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                item.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            Text(
                              CurrencyFormatter.format(
                                item.totalAmount,
                                isPrivacyMode: isPrivacy,
                              ),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppColors.primary,
                              ),
                            ),
                            IconButton(
                              tooltip: 'Delete shared expense',
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                color: AppColors.expenseRed,
                              ),
                              onPressed: () => _confirmDelete(context, item.id),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Paid by ${item.paidBy} • ${DateFormatter.formatDateOnly(item.date)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 8),
                        Text(
                          'Participant Shares:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Column(
                          children: item.splits.entries.map((e) {
                            final isSettled =
                                item.settledStatus[e.key] ?? false;
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 4.0,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    e.key,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        CurrencyFormatter.format(
                                          e.value,
                                          isPrivacyMode: isPrivacy,
                                        ),
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      InkWell(
                                        borderRadius: BorderRadius.circular(20),
                                        onTap: () => _setSettled(
                                          item,
                                          e.key,
                                          !isSettled,
                                        ),
                                        child: Chip(
                                          label: Text(
                                            isSettled
                                                ? 'Settled'
                                                : 'Mark settled',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: isSettled
                                                  ? AppColors.incomeGreen
                                                  : AppColors.warningOrange,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          backgroundColor:
                                              (isSettled
                                                      ? AppColors.incomeGreen
                                                      : AppColors.warningOrange)
                                                  .withValues(alpha: 0.12),
                                          visualDensity: VisualDensity.compact,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _setSettled(
    SharedExpense item,
    String person,
    bool settled,
  ) async {
    final status = Map<String, bool>.from(item.settledStatus)
      ..[person] = settled;
    await state.updateSharedExpense(
      SharedExpense(
        id: item.id,
        title: item.title,
        totalAmount: item.totalAmount,
        paidBy: item.paidBy,
        participants: item.participants,
        splits: item.splits,
        settledStatus: status,
        date: item.date,
      ),
    );
  }

  void _showAddExpenseDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => _AddSharedExpenseDialog(state: state),
    );
  }

  void _confirmDelete(BuildContext context, String id) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete shared expense?'),
        content: const Text(
          'The split and settlement statuses will be removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await state.deleteSharedExpense(id);
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.expenseRed),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddSharedExpenseDialog extends StatefulWidget {
  final AppState state;

  const _AddSharedExpenseDialog({required this.state});

  @override
  State<_AddSharedExpenseDialog> createState() =>
      _AddSharedExpenseDialogState();
}

class _AddSharedExpenseDialogState extends State<_AddSharedExpenseDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _titleController = TextEditingController();
  late final _amountController = TextEditingController();
  late final _paidByController = TextEditingController(
    text: widget.state.profile.name,
  );
  late final _peopleController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _paidByController.dispose();
    _peopleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: const Text('Add Shared Expense'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'What was the expense?',
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter a title'
                  : null,
            ),
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Total amount',
                prefixText: '₹ ',
              ),
              validator: (value) {
                final amount = double.tryParse(value?.trim() ?? '');
                return amount == null || amount <= 0
                    ? 'Enter an amount greater than zero'
                    : null;
              },
            ),
            TextFormField(
              controller: _paidByController,
              decoration: const InputDecoration(labelText: 'Paid by'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter who paid'
                  : null,
            ),
            TextFormField(
              controller: _peopleController,
              decoration: const InputDecoration(
                labelText: 'Other participants',
                hintText: 'Asha, Ravi',
              ),
              validator: (value) {
                final others = (value ?? '')
                    .split(',')
                    .map((name) => name.trim())
                    .where((name) => name.isNotEmpty)
                    .toList();
                if (others.isEmpty) {
                  return 'Enter at least one other participant';
                }
                final payer = _paidByController.text.trim().toLowerCase();
                if (others.every((name) => name.toLowerCase() == payer)) {
                  return 'Add someone other than the payer';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            const Text(
              'The payer and other participants share the total equally. The payer is marked settled; this does not change account balances.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _createSplit,
          child: const Text('Create Split'),
        ),
      ],
    );
  }

  Future<void> _createSplit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final paidBy = _paidByController.text.trim();
    final otherParticipants = _peopleController.text
        .split(',')
        .map((name) => name.trim())
        .where((name) => name.isNotEmpty)
        .toList();
    final participants = <String>[];
    for (final name in [paidBy, ...otherParticipants]) {
      if (!participants.any(
        (existing) => existing.toLowerCase() == name.toLowerCase(),
      )) {
        participants.add(name);
      }
    }
    if (participants.length < 2) return;

    final total = double.parse(_amountController.text.trim());
    final splits = _equalShares(total, participants);
    await widget.state.addSharedExpense(
      SharedExpense(
        id: 'shared_${DateTime.now().microsecondsSinceEpoch}',
        title: _titleController.text.trim(),
        totalAmount: total,
        paidBy: paidBy,
        participants: participants,
        splits: splits,
        settledStatus: {
          for (final person in participants)
            person: person.toLowerCase() == paidBy.toLowerCase(),
        },
        date: DateTime.now(),
      ),
    );
    if (mounted) Navigator.pop(context);
  }

  Map<String, double> _equalShares(double total, List<String> participants) {
    final totalCents = (total * 100).round();
    final baseShareCents = totalCents ~/ participants.length;
    final extraCents = totalCents % participants.length;
    return {
      for (var index = 0; index < participants.length; index++)
        participants[index]:
            (baseShareCents + (index < extraCents ? 1 : 0)) / 100,
    };
  }
}
