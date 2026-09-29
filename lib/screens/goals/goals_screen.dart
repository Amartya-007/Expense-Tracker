import 'package:flutter/material.dart';
import 'package:expensetracker/providers/app_state.dart';
import 'package:expensetracker/models/goal.dart';
import 'package:expensetracker/theme/app_theme.dart';
import 'package:expensetracker/utils/currency_formatter.dart';
import 'package:expensetracker/utils/date_formatter.dart';

class GoalsScreen extends StatelessWidget {
  final AppState state;
  const GoalsScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final isDark = state.profile.isDarkMode;
    final isPrivacy = state.profile.isPrivacyModeEnabled;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Savings Goals'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showAddGoalDialog(context),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: state.goals.length,
        itemBuilder: (context, idx) {
          final g = state.goals[idx];
          final left = g.targetAmount - g.currentAmount;

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
                      Row(
                        children: [
                          const CircleAvatar(
                            backgroundColor: AppColors.primary,
                            child: Icon(
                              Icons.savings_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                g.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                'Target: ${DateFormatter.formatDateOnly(g.targetDate)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.incomeGreen.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${(g.progressPercentage * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: AppColors.incomeGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Saved: ${CurrencyFormatter.format(g.currentAmount, isPrivacyMode: isPrivacy)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Goal: ${CurrencyFormatter.format(g.targetAmount, isPrivacyMode: isPrivacy)}',
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
                    value: g.progressPercentage,
                    backgroundColor: isDark ? Colors.white10 : Colors.black12,
                    color: AppColors.incomeGreen,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        left > 0
                            ? '${CurrencyFormatter.format(left, isPrivacyMode: isPrivacy)} remaining'
                            : 'Goal Completed! 🎉',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: left > 0
                              ? AppColors.primary
                              : AppColors.incomeGreen,
                        ),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: const Text(
                          'Add Money',
                          style: TextStyle(fontSize: 12),
                        ),
                        onPressed: () => _showAddMoneyDialog(context, g),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAddMoneyDialog(BuildContext context, Goal g) {
    final controller = TextEditingController(text: '1000');
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Add Money to ${g.name}'),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Amount (INR)',
              prefixText: '₹ ',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final amt = double.tryParse(controller.text.trim());
                if (amt == null || !amt.isFinite || amt <= 0) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid positive amount')),
                  );
                  return;
                }
                await state.addMoneyToGoal(g.id, amt);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Confirm Contribution'),
            ),
          ],
        );
      },
    );
  }

  void _showAddGoalDialog(BuildContext context) {
    final nameController = TextEditingController();
    final targetController = TextEditingController();
    DateTime targetDate = DateTime.now().add(const Duration(days: 180));
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            scrollable: true,
            title: const Text('New Savings Goal'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Goal Name'),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Enter a goal name'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: targetController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Target Amount (INR)',
                      prefixText: '₹ ',
                    ),
                    validator: (value) {
                      final amount = double.tryParse(value?.trim() ?? '');
                      return amount == null || amount <= 0
                          ? 'Enter an amount greater than zero'
                          : null;
                    },
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_month_rounded),
                    label: Text(
                      'Target date: ${DateFormatter.formatDateOnly(targetDate)}',
                    ),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: targetDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(
                          const Duration(days: 365 * 30),
                        ),
                      );
                      if (picked != null) {
                        setDialogState(() => targetDate = picked);
                      }
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
                  final newGoal = Goal(
                    id: 'g_${DateTime.now().microsecondsSinceEpoch}',
                    name: nameController.text.trim(),
                    targetAmount: double.parse(targetController.text.trim()),
                    targetDate: targetDate,
                  );
                  await state.addGoal(newGoal);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Create Goal'),
              ),
            ],
          ),
        );
      },
    );
  }
}
