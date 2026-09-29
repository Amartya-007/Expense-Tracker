import 'package:flutter/material.dart';
import 'package:expensetracker/providers/app_state.dart';
import 'package:expensetracker/models/transaction.dart';
import 'package:expensetracker/theme/app_theme.dart';
import 'package:expensetracker/utils/currency_formatter.dart';

class SplitTransactionScreen extends StatefulWidget {
  final AppState state;
  final TransactionItem transaction;

  const SplitTransactionScreen({
    super.key,
    required this.state,
    required this.transaction,
  });

  @override
  State<SplitTransactionScreen> createState() => _SplitTransactionScreenState();
}

class _SplitTransactionScreenState extends State<SplitTransactionScreen> {
  late List<TransactionSplit> _splits;

  @override
  void initState() {
    super.initState();
    if (widget.transaction.splits.isNotEmpty) {
      _splits = List.from(widget.transaction.splits);
    } else {
      _splits = [
        TransactionSplit(
          categoryId: widget.transaction.categoryId,
          categoryName: widget.transaction.categoryName,
          amount: widget.transaction.amount / 2,
          note: 'Part 1',
        ),
        TransactionSplit(
          categoryId: widget.state.categories.last.id,
          categoryName: widget.state.categories.last.name,
          amount: widget.transaction.amount / 2,
          note: 'Part 2',
        ),
      ];
    }
  }

  double get _currentSum => _splits.fold(0.0, (sum, s) => sum + s.amount);

  @override
  Widget build(BuildContext context) {
    final isDark = widget.state.profile.isDarkMode;
    final total = widget.transaction.amount;
    final remaining = total - _currentSum;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Split Transaction'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Original Total', style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(
                          CurrencyFormatter.format(total),
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Remaining to Split', style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(
                          CurrencyFormatter.format(remaining),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: remaining == 0 ? AppColors.incomeGreen : AppColors.expenseRed,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _splits.length,
                itemBuilder: (context, idx) {
                  final split = _splits[idx];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: DropdownButton<String>(
                              value: split.categoryId,
                              isExpanded: true,
                              underline: const SizedBox(),
                              items: widget.state.categories.map((c) {
                                return DropdownMenuItem(value: c.id, child: Text(c.name, style: const TextStyle(fontSize: 13)));
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  final cat = widget.state.categories.firstWhere((c) => c.id == val);
                                  setState(() {
                                    _splits[idx] = TransactionSplit(
                                      categoryId: cat.id,
                                      categoryName: cat.name,
                                      amount: split.amount,
                                      note: split.note,
                                    );
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 90,
                            child: TextFormField(
                              initialValue: split.amount.toStringAsFixed(0),
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(prefixText: '₹ '),
                              onChanged: (val) {
                                final amt = double.tryParse(val) ?? 0.0;
                                setState(() {
                                  _splits[idx] = TransactionSplit(
                                    categoryId: split.categoryId,
                                    categoryName: split.categoryName,
                                    amount: amt,
                                    note: split.note,
                                  );
                                });
                              },
                            ),
                          ),
                          if (_splits.length > 2)
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: AppColors.expenseRed),
                              onPressed: () => setState(() => _splits.removeAt(idx)),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add Split Category'),
                onPressed: () {
                  setState(() {
                    _splits.add(TransactionSplit(
                      categoryId: widget.state.categories.first.id,
                      categoryName: widget.state.categories.first.name,
                      amount: 0.0,
                    ));
                  });
                },
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                onPressed: remaining.abs() < 0.01
                    ? () async {
                        final updated = widget.transaction.copyWith(splits: _splits);
                        await widget.state.updateTransaction(updated);
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Transaction split saved successfully')),
                          );
                        }
                      }
                    : null,
                child: const Text('Save Split Transaction', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
