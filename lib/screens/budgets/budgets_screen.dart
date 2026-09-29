import 'package:flutter/material.dart';
import 'package:expensetracker/providers/app_state.dart';
import 'package:expensetracker/models/budget.dart';
import 'package:expensetracker/theme/app_theme.dart';
import 'package:expensetracker/utils/currency_formatter.dart';
import 'package:expensetracker/screens/budgets/safe_spending_screen.dart';

class BudgetsScreen extends StatelessWidget {
  final AppState state;
  const BudgetsScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final isDark = state.profile.isDarkMode;
    final isPrivacy = state.profile.isPrivacyModeEnabled;

    final double totalBudgetLimit = state.monthlyBudgetLimit;
    final double totalSpent = state.monthlyBudgetedSpent;
    final double remaining = totalBudgetLimit - totalSpent;
    final plannedIncome = state.profile.monthlyIncomeGoal > 0
        ? state.profile.monthlyIncomeGoal
        : state.thisMonthIncome;
    final goalAllocation = state.plannedSavingsTotal;
    final unallocated = plannedIncome - totalBudgetLimit - goalAllocation;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budgets & Safe Spend'),
        actions: [
          IconButton(
            tooltip: 'Safe Spending Calculator',
            icon: const Icon(
              Icons.verified_user_rounded,
              color: AppColors.incomeGreen,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SafeSpendingScreen(state: state),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SAFE SPEND HERO BANNER BUTTON
            Card(
              color: AppColors.primary.withValues(alpha: 0.1),
              child: ListTile(
                leading: const Icon(
                  Icons.verified_user_rounded,
                  color: AppColors.primary,
                  size: 28,
                ),
                title: const Text(
                  'Check "Available to Spend"',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                subtitle: const Text(
                  'Estimates safe spendable money after upcoming bills and savings commitments.',
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SafeSpendingScreen(state: state),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // OVERALL MONTHLY BUDGET CARD
            if (totalBudgetLimit <= 0)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.track_changes_rounded,
                        color: isDark
                            ? AppColors.darkTextMuted
                            : AppColors.lightTextMuted,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'No monthly budgets set',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Tap "Add Budget" to set category-wise spending limits.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Budget'),
                        onPressed: () => _showAddBudgetDialog(context),
                      ),
                    ],
                  ),
                ),
              )
            else
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MONTHLY BUDGET OVERVIEW',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                CurrencyFormatter.format(
                                  totalSpent,
                                  isPrivacyMode: isPrivacy,
                                ),
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: remaining >= 0
                                      ? AppColors.primary
                                      : AppColors.expenseRed,
                                ),
                              ),
                              Text(
                                'of ${CurrencyFormatter.format(totalBudgetLimit, isPrivacyMode: isPrivacy)} budget',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  (remaining >= 0
                                          ? AppColors.incomeGreen
                                          : AppColors.expenseRed)
                                      .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              remaining >= 0
                                  ? '${CurrencyFormatter.format(remaining, isPrivacyMode: isPrivacy)} left'
                                  : '${CurrencyFormatter.format(remaining.abs(), isPrivacyMode: isPrivacy)} OVER',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: remaining >= 0
                                    ? AppColors.incomeGreen
                                    : AppColors.expenseRed,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: (totalSpent / totalBudgetLimit).clamp(0.0, 1.0),
                        backgroundColor: isDark
                            ? Colors.white10
                            : Colors.black12,
                        color: remaining >= 0
                            ? AppColors.primary
                            : AppColors.expenseRed,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 20),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'Monthly Income Allocation',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => _editPlannedIncome(context),
                          child: const Text('Set income'),
                        ),
                      ],
                    ),
                    Text(
                      '${state.profile.monthlyIncomeGoal > 0 ? 'Planned income' : 'Income recorded this month'}: ${CurrencyFormatter.format(plannedIncome, isPrivacyMode: isPrivacy)}',
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Category envelopes: ${CurrencyFormatter.format(totalBudgetLimit, isPrivacyMode: isPrivacy)}',
                    ),
                    Text(
                      'Monthly goal contributions: ${CurrencyFormatter.format(goalAllocation, isPrivacyMode: isPrivacy)}',
                    ),
                    const Divider(height: 18),
                    Text(
                      unallocated >= 0
                          ? 'Still to allocate: ${CurrencyFormatter.format(unallocated, isPrivacyMode: isPrivacy)}'
                          : 'Over-allocated: ${CurrencyFormatter.format(unallocated.abs(), isPrivacyMode: isPrivacy)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: unallocated < 0
                            ? AppColors.expenseRed
                            : AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'This is a planning view; category limits do not move money between accounts.',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // CATEGORY BUDGETS HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Category Budgets',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Budget'),
                  onPressed: () => _showAddBudgetDialog(context),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // CATEGORY BUDGETS LIST
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: state.budgets.length,
              itemBuilder: (context, idx) {
                final b = state.budgets[idx];
                final spentMap = state.monthlyBudgetSpendingByCategory;
                final spent = spentMap[b.categoryId] ?? 0.0;
                final left = b.limitAmount - spent;
                final ratio = (spent / b.limitAmount).clamp(0.0, 1.0);
                final isOver = left < 0;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                b.categoryName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isOver
                                  ? '${CurrencyFormatter.format(left.abs(), isPrivacyMode: isPrivacy)} OVER'
                                  : '${CurrencyFormatter.format(left, isPrivacyMode: isPrivacy)} left',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: isOver
                                    ? AppColors.expenseRed
                                    : AppColors.incomeGreen,
                              ),
                            ),
                            IconButton(
                              tooltip: 'Edit ${b.categoryName} budget',
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(Icons.edit_outlined, size: 19),
                              onPressed: () =>
                                  _showEditBudgetDialog(context, b),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${CurrencyFormatter.format(spent, isPrivacyMode: isPrivacy)} spent',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                            ),
                            Text(
                              'Limit: ${CurrencyFormatter.format(b.limitAmount, isPrivacyMode: isPrivacy)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: ratio,
                          backgroundColor: isDark
                              ? Colors.white10
                              : Colors.black12,
                          color: isOver
                              ? AppColors.expenseRed
                              : AppColors.primary,
                          minHeight: 6,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _editPlannedIncome(BuildContext context) {
    final controller = TextEditingController(
      text: state.profile.monthlyIncomeGoal > 0
          ? state.profile.monthlyIncomeGoal.toStringAsFixed(2)
          : '',
    );
    final formKey = GlobalKey<FormState>();
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Plan Monthly Income'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Expected monthly income',
              prefixText: '₹ ',
            ),
            validator: (value) {
              final amount = double.tryParse(value?.trim() ?? '');
              return amount == null || amount <= 0
                  ? 'Enter an amount greater than zero'
                  : null;
            },
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
              await state.updateMonthlyIncomeGoal(
                double.parse(controller.text.trim()),
              );
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: const Text('Save Plan'),
          ),
        ],
      ),
    ).whenComplete(controller.dispose);
  }

  void _showEditBudgetDialog(BuildContext context, Budget budget) {
    showDialog<void>(
      context: context,
      builder: (_) => _EditCategoryBudgetDialog(state: state, budget: budget),
    );
  }

  void _showAddBudgetDialog(BuildContext context) {
    final expenseCategories = state.categories
        .where((category) => category.type.name.toLowerCase() == 'expense')
        .toList();
    if (expenseCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add an expense category before creating a budget.'),
        ),
      );
      return;
    }

    String selectedCatId = expenseCategories.first.id;
    final limitController = TextEditingController(text: '5000');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          scrollable: true,
          title: const Text('Create Category Budget'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selectedCatId,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: expenseCategories
                      .map(
                        (category) => DropdownMenuItem(
                          value: category.id,
                          child: Text(category.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) selectedCatId = value;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: limitController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Monthly Limit (INR)',
                    prefixText: '₹ ',
                  ),
                  validator: (value) {
                    final amount = double.tryParse(value?.trim() ?? '');
                    if (amount == null || amount <= 0) {
                      return 'Enter a limit greater than zero';
                    }
                    return null;
                  },
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
                if (!(formKey.currentState?.validate() ?? false)) return;
                final cat = state.categories.firstWhere(
                  (c) => c.id == selectedCatId,
                );
                final limit = double.parse(limitController.text.trim());
                final newBudget = Budget(
                  id: 'b_${DateTime.now().millisecondsSinceEpoch}',
                  categoryId: cat.id,
                  categoryName: cat.name,
                  limitAmount: limit,
                );
                await state.addBudget(newBudget);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Save Budget'),
            ),
          ],
        );
      },
    );
  }
}

class _EditCategoryBudgetDialog extends StatefulWidget {
  final AppState state;
  final Budget budget;

  const _EditCategoryBudgetDialog({required this.state, required this.budget});

  @override
  State<_EditCategoryBudgetDialog> createState() =>
      _EditCategoryBudgetDialogState();
}

class _EditCategoryBudgetDialogState extends State<_EditCategoryBudgetDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _limitController = TextEditingController(
    text: widget.budget.limitAmount.toStringAsFixed(2),
  );

  @override
  void dispose() {
    _limitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: Text('Edit ${widget.budget.categoryName} Budget'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _limitController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Monthly Limit (INR)',
            prefixText: '₹ ',
          ),
          validator: (value) {
            final amount = double.tryParse(value?.trim() ?? '');
            return amount == null || amount <= 0
                ? 'Enter a limit greater than zero'
                : null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _save, child: const Text('Save Budget')),
      ],
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await widget.state.updateBudget(
      Budget(
        id: widget.budget.id,
        categoryId: widget.budget.categoryId,
        categoryName: widget.budget.categoryName,
        limitAmount: double.parse(_limitController.text.trim()),
        period: widget.budget.period,
        isActive: widget.budget.isActive,
      ),
    );
    if (mounted) Navigator.pop(context);
  }
}
