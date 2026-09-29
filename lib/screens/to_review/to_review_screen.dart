import 'package:flutter/material.dart';
import 'package:expensetracker/providers/app_state.dart';
import 'package:expensetracker/theme/app_theme.dart';
import 'package:expensetracker/utils/currency_formatter.dart';
import 'package:expensetracker/utils/date_formatter.dart';
import 'package:expensetracker/services/sms_parser_service.dart';
import 'package:expensetracker/models/review_queue_item.dart';
import 'package:expensetracker/models/transaction.dart';
import 'package:expensetracker/models/category.dart';

class ToReviewScreen extends StatelessWidget {
  final AppState state;
  const ToReviewScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final isDark = state.profile.isDarkMode;
    final isPrivacy = state.profile.isPrivacyModeEnabled;

    return Scaffold(
      appBar: AppBar(
        title: Text('Transactions to Review (${state.reviewQueue.length})'),
        actions: [
          IconButton(
            tooltip: 'Simulate Bank SMS Capture',
            icon: const Icon(Icons.sms_rounded, color: AppColors.primary),
            onPressed: () => _simulateBankSmsDialog(context),
          ),
        ],
      ),
      body: state.reviewQueue.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.check_circle_outline_rounded,
                      size: 64,
                      color: AppColors.incomeGreen,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'All Caught Up!',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'No automatically captured SMS transactions waiting for approval.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.sms_rounded),
                      label: const Text('Simulate Incoming Transaction SMS'),
                      onPressed: () => _simulateBankSmsDialog(context),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.reviewQueue.length,
              itemBuilder: (context, idx) {
                final item = state.reviewQueue[idx];
                return _EditableReviewCard(
                  key: ValueKey(item.id),
                  state: state,
                  item: item,
                  isDark: isDark,
                  isPrivacy: isPrivacy,
                );
              },
            ),
    );
  }

  void _simulateBankSmsDialog(BuildContext context) {
    final smsController = TextEditingController(
      text: 'HDFC Bank: Rs 650.00 debited from A/C XX4321 at Zomato on 26-Sep-26. Avail Bal: Rs 28350.00',
    );

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          scrollable: true,
          title: const Text('Simulate Incoming SMS'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Test automatic SMS capture engine. Paste or type any Indian bank SMS message below:',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 6),
              const Text(
                'Tip: use the word "credited" instead of "debited" to simulate an income/credit SMS.',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: smsController,
                maxLines: 3,
                decoration: const InputDecoration(border: OutlineInputBorder()),
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
                final parsed = SmsParserService.parseSms(smsController.text);
                if (parsed.isTransaction) {
                  final isDup = SmsParserService.isLikelyDuplicate(
                    parsed,
                    state.transactions,
                  );

                  final isCredit = !parsed.isDebit;

                  final incomeCats = state.categories
                      .where((c) => c.type == CategoryType.income)
                      .toList();
                  final expenseCats = state.categories
                      .where((c) => c.type == CategoryType.expense)
                      .toList();

                  final defaultCats = isCredit && incomeCats.isNotEmpty
                      ? incomeCats
                      : expenseCats;
                  final cat = defaultCats.firstWhere(
                    (c) => c.name.toLowerCase().contains(
                      parsed.categorySuggestion.toLowerCase(),
                    ),
                    orElse: () => defaultCats.isEmpty
                        ? state.categories.first
                        : defaultCats.first,
                  );
                  final acc = state.accounts.firstWhere(
                    (a) => a.name.toLowerCase().contains(
                      parsed.accountRef.toLowerCase(),
                    ),
                    orElse: () => state.accounts.first,
                  );

                  final item = ReviewQueueItem(
                    id: 'rq_${DateTime.now().millisecondsSinceEpoch}',
                    merchant: isDup
                        ? '${parsed.merchant.isEmpty ? (isCredit ? 'Income (SMS)' : 'Unnamed Merchant') : parsed.merchant} (Possible Duplicate)'
                        : parsed.merchant.isEmpty
                        ? (isCredit ? 'Income (SMS)' : 'Unnamed Merchant')
                        : parsed.merchant,
                    amount: parsed.amount,
                    date: DateTime.now(),
                    suggestedCategoryId: cat.id,
                    suggestedCategoryName: cat.name,
                    suggestedAccountId: acc.id,
                    suggestedAccountName: acc.name,
                    sourceNotification: parsed.rawSms,
                    suggestedType: isCredit
                        ? TransactionType.income
                        : TransactionType.expense,
                  );

                  state.reviewQueue.add(item);
                  await state.updateReviewQueueItem(item);
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Detected ${item.suggestedType == TransactionType.income ? 'credit' : 'debit'}: ${item.merchant} (${CurrencyFormatter.format(parsed.amount)}) added to Review Queue!',
                        ),
                      ),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Message ignored: No financial debit/credit transaction detected.',
                      ),
                    ),
                  );
                }
              },
              child: const Text('Detect Transaction'),
            ),
          ],
        );
      },
    );
  }
}

class _EditableReviewCard extends StatefulWidget {
  final AppState state;
  final ReviewQueueItem item;
  final bool isDark;
  final bool isPrivacy;

  const _EditableReviewCard({
    super.key,
    required this.state,
    required this.item,
    required this.isDark,
    required this.isPrivacy,
  });

  @override
  State<_EditableReviewCard> createState() => _EditableReviewCardState();
}

class _EditableReviewCardState extends State<_EditableReviewCard> {
  late TransactionType _type;
  late String _categoryId;
  late String _categoryName;
  late String _accountId;
  late String _accountName;
  late TextEditingController _merchantCtrl;

  @override
  void initState() {
    super.initState();
    _type = widget.item.suggestedType == TransactionType.income
        ? TransactionType.income
        : TransactionType.expense;
    _categoryId = widget.item.suggestedCategoryId;
    _categoryName = widget.item.suggestedCategoryName;
    _accountId = widget.item.suggestedAccountId;
    _accountName = widget.item.suggestedAccountName;
    _merchantCtrl = TextEditingController(text: widget.item.merchant);
  }

  @override
  void dispose() {
    _merchantCtrl.dispose();
    super.dispose();
  }

  Future<void> _persistEdits() async {
    final edited = ReviewQueueItem(
      id: widget.item.id,
      merchant: _merchantCtrl.text.trim().isEmpty
          ? widget.item.merchant
          : _merchantCtrl.text.trim(),
      amount: widget.item.amount,
      date: widget.item.date,
      suggestedCategoryId: _categoryId,
      suggestedCategoryName: _categoryName,
      suggestedAccountId: _accountId,
      suggestedAccountName: _accountName,
      sourceNotification: widget.item.sourceNotification,
      suggestedType: _type,
    );
    widget.item.merchant = edited.merchant;
    widget.item.suggestedType = edited.suggestedType;
    widget.item.suggestedCategoryId = edited.suggestedCategoryId;
    widget.item.suggestedCategoryName = edited.suggestedCategoryName;
    widget.item.suggestedAccountId = edited.suggestedAccountId;
    widget.item.suggestedAccountName = edited.suggestedAccountName;
    await widget.state.updateReviewQueueItem(edited);
  }

  @override
  Widget build(BuildContext context) {
    final amountColor = _type == TransactionType.income
        ? AppColors.incomeGreen
        : AppColors.expenseRed;
    final amountPrefix = _type == TransactionType.income ? '+ ' : '- ';

    final typeCats = _type == TransactionType.income
        ? widget.state.categories
              .where((c) => c.type == CategoryType.income)
              .toList()
        : widget.state.categories
              .where((c) => c.type == CategoryType.expense)
              .toList();

    // If current _categoryId not in typeCats, reset to first valid category.
    if (typeCats.isNotEmpty && !typeCats.any((c) => c.id == _categoryId)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _categoryId = typeCats.first.id;
            _categoryName = typeCats.first.name;
          });
          _persistEdits();
        }
      });
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _merchantCtrl,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      labelText: 'Merchant / Description',
                      floatingLabelBehavior: FloatingLabelBehavior.auto,
                    ),
                    onChanged: (_) => _persistEdits(),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$amountPrefix${CurrencyFormatter.format(widget.item.amount, isPrivacyMode: widget.isPrivacy)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: amountColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              DateFormatter.formatRelative(widget.item.date),
              style: TextStyle(
                fontSize: 12,
                color: widget.isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 12),

            // Transaction Type segmented button
            SegmentedButton<TransactionType>(
              segments: const [
                ButtonSegment(
                  value: TransactionType.expense,
                  label: Text('Expense'),
                  icon: Icon(Icons.remove_circle_outline),
                ),
                ButtonSegment(
                  value: TransactionType.income,
                  label: Text('Income'),
                  icon: Icon(Icons.add_circle_outline),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (s) {
                setState(() => _type = s.first);
                // When type changes, select first category of correct type.
                final catsForType = _type == TransactionType.income
                    ? widget.state.categories.where(
                        (c) => c.type == CategoryType.income,
                      )
                    : widget.state.categories.where(
                        (c) => c.type == CategoryType.expense,
                      );
                if (catsForType.isNotEmpty) {
                  final first = catsForType.first;
                  _categoryId = first.id;
                  _categoryName = first.name;
                }
                _persistEdits();
              },
            ),
            const SizedBox(height: 10),

            // Warning banner for credit SMS if user manually switched to expense.
            if (widget.item.sourceNotification.toLowerCase().contains(
                  'credited',
                ) &&
                _type == TransactionType.expense)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: AppColors.expenseRed.withValues(alpha: 0.10),
                  border: Border.all(
                    color: AppColors.expenseRed.withValues(alpha: 0.5),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 18,
                      color: AppColors.expenseRed,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This SMS says money was "credited". You selected Expense — switch to Income if this is a refund/salary/deposit.',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.3,
                          color: AppColors.expenseRed,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Account selector
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.account_balance_wallet_rounded, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _accountId,
                    isDense: true,
                    decoration: const InputDecoration(
                      labelText: 'Account',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: widget.state.accounts
                        .map(
                          (a) => DropdownMenuItem<String>(
                            value: a.id,
                            child: Text(a.name),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val == null) return;
                      final a = widget.state.accounts.firstWhere(
                        (acc) => acc.id == val,
                      );
                      setState(() {
                        _accountId = val;
                        _accountName = a.name;
                      });
                      _persistEdits();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 150,
                  child: DropdownButtonFormField<String>(
                    initialValue: _categoryId,
                    isDense: true,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: typeCats.isEmpty
                        ? widget.state.categories
                              .map(
                                (c) => DropdownMenuItem<String>(
                                  value: c.id,
                                  child: Text(c.name),
                                ),
                              )
                              .toList()
                        : typeCats
                              .map(
                                (c) => DropdownMenuItem<String>(
                                  value: c.id,
                                  child: Text(c.name),
                                ),
                              )
                              .toList(),
                    onChanged: (val) {
                      if (val == null) return;
                      final c = widget.state.categories.firstWhere(
                        (cat) => cat.id == val,
                      );
                      setState(() {
                        _categoryId = val;
                        _categoryName = c.name;
                      });
                      _persistEdits();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (widget.item.sourceNotification.toLowerCase().contains(
              'possible duplicate',
            ))
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: AppColors.warningOrange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'This looks like a duplicate of a transaction already recorded for the same date. Check your transaction list before approving.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.warningOrange,
                  ),
                ),
              ),

            // Source SMS
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: widget.isDark
                    ? AppColors.darkBackground
                    : AppColors.lightBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: widget.isDark
                      ? AppColors.darkCardBorder
                      : AppColors.lightCardBorder,
                ),
              ),
              child: Text(
                'SMS Source: "${widget.item.sourceNotification}"',
                style: const TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () =>
                      widget.state.dismissReviewQueueItem(widget.item.id),
                  child: const Text('Dismiss'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.check_rounded, size: 16),
                  label: const Text('Approve & Save'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _type == TransactionType.income
                        ? AppColors.incomeGreen
                        : AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    // Block approval if type=expense but SMS says credited AND
                    // user hasn't changed type after showing warning — just allow,
                    // the warning is enough. Finalize edits then approve.
                    await _persistEdits();
                    if (context.mounted) {
                      final typeLabel = _type == TransactionType.income
                          ? 'Income'
                          : 'Expense';
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '$typeLabel saved to $_accountName (${CurrencyFormatter.format(widget.item.amount)})',
                          ),
                        ),
                      );
                    }
                    await widget.state.approveReviewQueueItem(widget.item);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
