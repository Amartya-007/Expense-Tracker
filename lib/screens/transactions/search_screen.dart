import 'package:flutter/material.dart';
import 'package:expensetracker/providers/app_state.dart';
import 'package:expensetracker/models/transaction.dart';
import 'package:expensetracker/theme/app_theme.dart';
import 'package:expensetracker/utils/currency_formatter.dart';
import 'package:expensetracker/utils/date_formatter.dart';
import 'package:expensetracker/screens/transactions/transaction_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  final AppState state;
  const SearchScreen({super.key, required this.state});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final isDark = widget.state.profile.isDarkMode;
    final isPrivacy = widget.state.profile.isPrivacyModeEnabled;

    final results = widget.state.transactions.where((t) {
      if (_query.isEmpty) return false;
      final q = _query.toLowerCase();
      final matchMerchant = t.merchant.toLowerCase().contains(q);
      final matchCategory = t.categoryName.toLowerCase().contains(q);
      final matchNote = t.note.toLowerCase().contains(q);
      final matchAccount = t.accountName.toLowerCase().contains(q);
      final matchTag = t.tags.any((tag) => tag.toLowerCase().contains(q));
      final matchAmount = t.amount.toString().contains(q);

      return matchMerchant || matchCategory || matchNote || matchAccount || matchTag || matchAmount;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search merchants, notes, tags, food, ₹500...',
            border: InputBorder.none,
          ),
          onChanged: (val) => setState(() => _query = val.trim()),
        ),
        actions: [
          if (_query.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_rounded),
              onPressed: () {
                _searchController.clear();
                setState(() => _query = '');
              },
            ),
        ],
      ),
      body: _query.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_rounded, size: 64, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                  const SizedBox(height: 12),
                  Text(
                    'Search anything across your money records',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Try searching "Swiggy", "Amazon", "Goa", "Headphones", "₹1200"',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            )
          : results.isEmpty
              ? Center(
                  child: Text(
                    'No matching records found for "$_query"',
                    style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: results.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, idx) {
                    final t = results[idx];
                    final isExpense = t.type == TransactionType.expense;
                    final color = isExpense ? AppColors.expenseRed : AppColors.incomeGreen;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: color.withValues(alpha: 0.12),
                        child: Icon(isExpense ? Icons.shopping_bag_outlined : Icons.arrow_downward_rounded, color: color, size: 20),
                      ),
                      title: Text(t.merchant, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Text(
                        '${t.categoryName} • ${DateFormatter.formatDateOnly(t.date)}${t.note.isNotEmpty ? ' • ${t.note}' : ''}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                      ),
                      trailing: Text(
                        CurrencyFormatter.format(t.amount, isPrivacyMode: isPrivacy, showSign: true),
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => TransactionDetailScreen(state: widget.state, transaction: t)),
                        );
                      },
                    );
                  },
                ),
    );
  }
}
