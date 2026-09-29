import 'package:flutter/material.dart';
import 'package:expensetracker/providers/app_state.dart';
import 'package:expensetracker/models/transaction.dart';
import 'package:expensetracker/theme/app_theme.dart';
import 'package:expensetracker/utils/currency_formatter.dart';
import 'package:expensetracker/utils/date_formatter.dart';
import 'package:expensetracker/screens/transactions/transaction_detail_screen.dart';
import 'package:expensetracker/screens/transactions/search_screen.dart';

class TransactionsScreen extends StatefulWidget {
  final AppState state;
  const TransactionsScreen({super.key, required this.state});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  String _selectedTypeFilter = 'All'; // All, Expense, Income, Transfer
  String? _selectedCategoryFilter;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.state.profile.isDarkMode;
    final isPrivacy = widget.state.profile.isPrivacyModeEnabled;

    var list = widget.state.filteredTransactions;

    // Filter by type
    if (_selectedTypeFilter == 'Expense') {
      list = list.where((t) => t.type == TransactionType.expense).toList();
    } else if (_selectedTypeFilter == 'Income') {
      list = list.where((t) => t.type == TransactionType.income).toList();
    } else if (_selectedTypeFilter == 'Transfer') {
      list = list.where((t) => t.type == TransactionType.transfer).toList();
    }

    // Filter by category
    if (_selectedCategoryFilter != null) {
      list = list.where((t) => t.categoryName == _selectedCategoryFilter).toList();
    }

    // Group by Date
    final Map<String, List<TransactionItem>> grouped = {};
    for (final t in list) {
      final key = DateFormatter.formatDateOnly(t.date);
      grouped.putIfAbsent(key, () => []).add(t);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Timeline'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SearchScreen(state: widget.state)),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _typeChip('All'),
                  const SizedBox(width: 6),
                  _typeChip('Expense'),
                  const SizedBox(width: 6),
                  _typeChip('Income'),
                  const SizedBox(width: 6),
                  _typeChip('Transfer'),
                  const SizedBox(width: 12),
                  Container(height: 20, width: 1, color: isDark ? Colors.white24 : Colors.black12),
                  const SizedBox(width: 12),
                  // Category Dropdown Filter
                  DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: _selectedCategoryFilter,
                      hint: const Text('Category', style: TextStyle(fontSize: 12)),
                      isDense: true,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All Categories')),
                        ...widget.state.categories.map((c) => DropdownMenuItem(value: c.name, child: Text(c.name))),
                      ],
                      onChanged: (val) => setState(() => _selectedCategoryFilter = val),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),

          // Transaction Timeline List
          Expanded(
            child: list.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 56,
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No transactions found',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Try clearing filters or adding a new transaction.',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                    itemCount: grouped.length,
                    itemBuilder: (context, idx) {
                      final dateKey = grouped.keys.elementAt(idx);
                      final items = grouped[dateKey]!;

                      double dayTotal = 0.0;
                      for (var item in items) {
                        if (item.type == TransactionType.expense) {
                          dayTotal -= item.amount;
                        } else if (item.type == TransactionType.income) {
                          dayTotal += item.amount;
                        }
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  dateKey.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.8,
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                  ),
                                ),
                                Text(
                                  CurrencyFormatter.format(dayTotal, isPrivacyMode: isPrivacy, showSign: true),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: dayTotal >= 0 ? AppColors.incomeGreen : AppColors.lightTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Card(
                            child: ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: items.length,
                              separatorBuilder: (_, _) => const Divider(height: 1),
                              itemBuilder: (context, itemIdx) {
                                final t = items[itemIdx];
                                final isExpense = t.type == TransactionType.expense;
                                final color = isExpense
                                    ? AppColors.expenseRed
                                    : (t.type == TransactionType.income
                                        ? AppColors.incomeGreen
                                        : AppColors.infoBlue);

                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: color.withValues(alpha: 0.12),
                                    child: Icon(
                                      isExpense
                                          ? Icons.shopping_bag_outlined
                                          : (t.type == TransactionType.income
                                              ? Icons.arrow_downward_rounded
                                              : Icons.swap_horiz_rounded),
                                      color: color,
                                      size: 20,
                                    ),
                                  ),
                                  title: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          t.merchant,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                      ),
                                      if (t.receiptImagePath != null) ...[
                                        const SizedBox(width: 4),
                                        const Icon(Icons.receipt_rounded, size: 14, color: AppColors.primary),
                                      ],
                                    ],
                                  ),
                                  subtitle: Text(
                                    '${t.categoryName} • ${t.accountName}${t.note.isNotEmpty ? ' • ${t.note}' : ''}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                    ),
                                  ),
                                  trailing: Text(
                                    CurrencyFormatter.format(t.amount, isPrivacyMode: isPrivacy, showSign: true),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: color,
                                    ),
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => TransactionDetailScreen(state: widget.state, transaction: t),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _typeChip(String type) {
    final isSel = _selectedTypeFilter == type;
    return ChoiceChip(
      selected: isSel,
      label: Text(type, style: const TextStyle(fontSize: 12)),
      onSelected: (val) {
        if (val) setState(() => _selectedTypeFilter = type);
      },
    );
  }
}
