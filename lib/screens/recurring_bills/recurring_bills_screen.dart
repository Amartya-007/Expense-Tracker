import 'package:flutter/material.dart';
import 'package:expensetracker/providers/app_state.dart';
import 'package:expensetracker/models/recurring_bill.dart';
import 'package:expensetracker/models/category.dart';
import 'package:expensetracker/theme/app_theme.dart';
import 'package:expensetracker/utils/currency_formatter.dart';
import 'package:expensetracker/utils/date_formatter.dart';

class RecurringBillsScreen extends StatelessWidget {
  final AppState state;
  const RecurringBillsScreen({super.key, required this.state});

  // ignore: unused_element
  String _billingCycleLabel(BillingCycle cycle) {
    switch (cycle) {
      case BillingCycle.weekly:
        return 'Weekly';
      case BillingCycle.monthly:
        return 'Monthly';
      case BillingCycle.yearly:
        return 'Yearly';
    }
  }

  String _recurringTypeLabel(RecurringType type) {
    switch (type) {
      case RecurringType.bill:
        return 'Bill';
      case RecurringType.subscription:
        return 'Subscription';
      case RecurringType.emi:
        return 'EMI';
      case RecurringType.income:
        return 'Income';
    }
  }

  double _monthlyEquivalent(RecurringBill bill) {
    switch (bill.billingCycle) {
      case BillingCycle.weekly:
        return bill.amount * 52 / 12;
      case BillingCycle.monthly:
        return bill.amount;
      case BillingCycle.yearly:
        return bill.amount / 12;
    }
  }

  String _cycleAndDueLabel(RecurringBill bill) {
    String cycle;
    switch (bill.billingCycle) {
      case BillingCycle.weekly:
        cycle = 'Weekly';
        break;
      case BillingCycle.monthly:
        cycle = 'Monthly';
        break;
      case BillingCycle.yearly:
        cycle = 'Yearly';
        break;
    }
    return '$cycle • ${DateFormatter.formatDueDate(bill.dueDay)} • ${bill.categoryName} • ${bill.accountName}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = state.profile.isDarkMode;
    final isPrivacy = state.profile.isPrivacyModeEnabled;

    final double totalMonthly = state.recurringBills.fold(
      0.0,
      (sum, b) => b.type == RecurringType.income ? sum : sum + _monthlyEquivalent(b),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recurring Bills & EMIs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showAddBillDialog(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL RECURRING COMMITMENTS',
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
                      '${CurrencyFormatter.format(totalMonthly, isPrivacyMode: isPrivacy)} / month',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.expenseRed,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'Upcoming & Active Obligations',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: state.recurringBills.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32.0),
                      child: Center(
                        child: Text(
                          'No recurring payments yet.\nTap + above to add your first.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: state.recurringBills.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, idx) {
                        final bill = state.recurringBills[idx];
                        return ListTile(
                          title: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  bill.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: bill.type == RecurringType.emi
                                      ? AppColors.expenseRed.withValues(alpha: 0.15)
                                      : bill.type == RecurringType.subscription
                                          ? AppColors.infoBlue.withValues(alpha: 0.15)
                                          : AppColors.warningOrange
                                              .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _recurringTypeLabel(bill.type),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: bill.type == RecurringType.emi
                                        ? AppColors.expenseRed
                                        : bill.type == RecurringType.subscription
                                            ? AppColors.infoBlue
                                            : AppColors.warningOrange,
                                  ),
                                ),
                              ),
                              if (bill.isPaused) ...[
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'PAUSED',
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_cycleAndDueLabel(bill)),
                              if (bill.billingCycle != BillingCycle.monthly)
                                Text(
                                  '≈ ${CurrencyFormatter.format(_monthlyEquivalent(bill))} / month',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                CurrencyFormatter.format(
                                  bill.amount,
                                  isPrivacyMode: isPrivacy,
                                ),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: bill.type == RecurringType.income
                                      ? AppColors.incomeGreen
                                      : AppColors.expenseRed,
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (!bill.isPaid && !bill.isPaused)
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.incomeGreen,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                  ),
                                  onPressed: () async {
                                    await state.markBillPaid(bill.id);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Marked ${bill.title} as paid! Next cycle scheduled.',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  child: const Text(
                                    'Pay',
                                    style: TextStyle(fontSize: 11),
                                  ),
                                )
                              else if (bill.isPaid)
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.incomeGreen,
                                )
                              else
                                const Icon(
                                  Icons.pause_circle_rounded,
                                  color: Colors.grey,
                                ),
                            ],
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

  void _showAddBillDialog(BuildContext context) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    int dueDay = 1;
    BillingCycle billingCycle = BillingCycle.monthly;
    RecurringType recurringType = RecurringType.bill;

    final expenseCategories =
        state.categories.where((c) => c.type == CategoryType.expense).toList();
    String? selectedCategoryId =
        expenseCategories.isNotEmpty ? expenseCategories.first.id : null;
    String? selectedAccountId =
        state.accounts.isNotEmpty ? state.accounts.first.id : null;

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              scrollable: true,
              title: const Text('Add Recurring Payment'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title (e.g. Electricity, Home Loan EMI)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: amountController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Amount (INR)',
                        prefixText: '₹ ',
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) {
                        final amt = double.tryParse(val ?? '');
                        if (amt == null || amt <= 0) {
                          return 'Enter a valid amount';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    // Due Day
                    const Text(
                      'Due Day of Month',
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<int>(
                      initialValue: dueDay,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: List.generate(31, (i) => i + 1)
                          .map((d) => DropdownMenuItem<int>(
                                value: d,
                                child: Text('$d'),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => dueDay = val);
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                    // Billing Cycle
                    const Text(
                      'Billing Cycle',
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    SegmentedButton<BillingCycle>(
                      segments: const [
                        ButtonSegment(
                            value: BillingCycle.weekly, label: Text('Weekly')),
                        ButtonSegment(
                            value: BillingCycle.monthly,
                            label: Text('Monthly')),
                        ButtonSegment(
                            value: BillingCycle.yearly,
                            label: Text('Yearly')),
                      ],
                      selected: {billingCycle},
                      onSelectionChanged: (s) =>
                          setDialogState(() => billingCycle = s.first),
                    ),
                    const SizedBox(height: 14),
                    // Recurring Type
                    const Text(
                      'Payment Type',
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    SegmentedButton<RecurringType>(
                      segments: const [
                        ButtonSegment(
                            value: RecurringType.bill, label: Text('Bill')),
                        ButtonSegment(
                            value: RecurringType.subscription,
                            label: Text('Subscription')),
                        ButtonSegment(
                            value: RecurringType.emi, label: Text('EMI')),
                      ],
                      selected: {recurringType},
                      onSelectionChanged: (s) =>
                          setDialogState(() => recurringType = s.first),
                    ),
                    const SizedBox(height: 14),
                    // Category
                    const Text(
                      'Category',
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    if (expenseCategories.isEmpty)
                      const Text(
                        'No expense categories found. Add some in the Categories section first.',
                        style:
                            TextStyle(color: AppColors.expenseRed, fontSize: 12),
                      )
                    else
                      DropdownButtonFormField<String>(
                        initialValue: selectedCategoryId,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                        ),
                        items: expenseCategories
                            .map((c) => DropdownMenuItem<String>(
                                  value: c.id,
                                  child: Text(c.name),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => selectedCategoryId = val);
                          }
                        },
                        validator: (val) => val == null
                            ? 'Please select a category'
                            : null,
                      ),
                    const SizedBox(height: 14),
                    // Account
                    const Text(
                      'Account to debit from',
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    if (state.accounts.isEmpty)
                      const Text(
                        'No accounts found. Add a bank/cash account first.',
                        style:
                            TextStyle(color: AppColors.expenseRed, fontSize: 12),
                      )
                    else
                      DropdownButtonFormField<String>(
                        initialValue: selectedAccountId,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                        ),
                        items: state.accounts
                            .map((a) => DropdownMenuItem<String>(
                                  value: a.id,
                                  child: Text(a.name),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => selectedAccountId = val);
                          }
                        },
                        validator: (val) =>
                            val == null ? 'Please select an account' : null,
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
                  onPressed: () async {
                    if (expenseCategories.isEmpty || state.accounts.isEmpty) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Add at least one account and one expense category first.'),
                        ),
                      );
                      return;
                    }
                    if (!formKey.currentState!.validate()) return;

                    final category = expenseCategories
                        .firstWhere((c) => c.id == selectedCategoryId);
                    final account = state.accounts
                        .firstWhere((a) => a.id == selectedAccountId);

                    final newBill = RecurringBill(
                      id: 'rb_${DateTime.now().millisecondsSinceEpoch}',
                      title: titleController.text.trim(),
                      amount: double.parse(amountController.text),
                      type: recurringType,
                      billingCycle: billingCycle,
                      dueDay: dueDay,
                      categoryId: category.id,
                      categoryName: category.name,
                      accountId: account.id,
                      accountName: account.name,
                    );
                    await state.addRecurringBill(newBill);
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(
                            content: Text('Recurring payment saved.')),
                      );
                    }
                  },
                  child: const Text('Save Recurring Payment'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
