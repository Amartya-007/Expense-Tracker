import 'package:flutter/material.dart';
import 'package:expensetracker/providers/app_state.dart';
import 'package:expensetracker/models/transaction.dart';
import 'package:expensetracker/theme/app_theme.dart';
import 'package:expensetracker/utils/currency_formatter.dart';
import 'package:expensetracker/utils/date_formatter.dart';
import 'package:expensetracker/screens/transactions/transaction_detail_screen.dart';

class CalendarScreen extends StatefulWidget {
  final AppState state;
  const CalendarScreen({super.key, required this.state});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _selectedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final isDark = widget.state.profile.isDarkMode;
    final isPrivacy = widget.state.profile.isPrivacyModeEnabled;

    final dayStart = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);
    final dayEnd = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day, 23, 59, 59);

    final dayTransactions = widget.state.transactions.where((t) {
      return t.date.isAfter(dayStart.subtract(const Duration(seconds: 1))) &&
          t.date.isBefore(dayEnd.add(const Duration(seconds: 1)));
    }).toList();

    double dayIncome = 0.0;
    double daySpent = 0.0;
    for (var t in dayTransactions) {
      if (t.type == TransactionType.income) dayIncome += t.amount;
      if (t.type == TransactionType.expense) daySpent += t.amount;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar Expense View'),
      ),
      body: Column(
        children: [
          // Date Picker Ribbon
          CalendarDatePicker(
            initialDate: _selectedDay,
            firstDate: DateTime(2025, 1, 1),
            lastDate: DateTime(2027, 12, 31),
            onDateChanged: (d) => setState(() => _selectedDay = d),
          ),
          const Divider(height: 1),

          // Day Summary Header
          Container(
            padding: const EdgeInsets.all(16),
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(DateFormatter.formatDateOnly(_selectedDay), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('${dayTransactions.length} transactions', style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                  ],
                ),
                Row(
                  children: [
                    if (dayIncome > 0)
                      Text('+$dayIncome', style: const TextStyle(color: AppColors.incomeGreen, fontWeight: FontWeight.bold)),
                    if (dayIncome > 0 && daySpent > 0) const SizedBox(width: 8),
                    if (daySpent > 0)
                      Text('-${CurrencyFormatter.format(daySpent, isPrivacyMode: isPrivacy)}', style: const TextStyle(color: AppColors.expenseRed, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Day Transactions List
          Expanded(
            child: dayTransactions.isEmpty
                ? const Center(child: Text('No transactions recorded on this date.'))
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: dayTransactions.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, idx) {
                      final t = dayTransactions[idx];
                      final isExpense = t.type == TransactionType.expense;
                      return ListTile(
                        title: Text(t.merchant, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${t.categoryName} • ${t.accountName}'),
                        trailing: Text(
                          CurrencyFormatter.format(t.amount, isPrivacyMode: isPrivacy, showSign: true),
                          style: TextStyle(fontWeight: FontWeight.bold, color: isExpense ? AppColors.expenseRed : AppColors.incomeGreen),
                        ),
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => TransactionDetailScreen(state: widget.state, transaction: t)));
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
