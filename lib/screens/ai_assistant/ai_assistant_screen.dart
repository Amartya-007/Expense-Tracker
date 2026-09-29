import 'package:flutter/material.dart';
import 'package:expensetracker/providers/app_state.dart';
import 'package:expensetracker/models/transaction.dart';
import 'package:expensetracker/theme/app_theme.dart';
import 'package:expensetracker/utils/currency_formatter.dart';

class AIMessage {
  final String text;
  final bool isUser;
  final List<TransactionItem>? matchedTransactions;

  AIMessage({required this.text, required this.isUser, this.matchedTransactions});
}

class AIAssistantScreen extends StatefulWidget {
  final AppState state;
  const AIAssistantScreen({super.key, required this.state});

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  final List<AIMessage> _messages = [];

  final List<String> _suggestedQuestions = const [
    'How much did I spend on food this month?',
    'What did I spend at Amazon?',
    'How much money did I receive this month?',
  ];

  @override
  void initState() {
    super.initState();
    _messages.add(AIMessage(
      text:
      'Hello ${widget.state.profile.name}! I am your AI Money Assistant. Ask me anything about your recorded transactions, bills, or spending patterns.',
      isUser: false,
    ));

    // When the keyboard opens, keep the latest message visible.
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 300), _scrollToBottom);
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!mounted || !_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.state.profile.isDarkMode;

    // Keyboard height (0 when closed) and system nav bar height.
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final systemBottom = MediaQuery.of(context).viewPadding.bottom;
    // When the keyboard is open it already covers the nav bar area,
    // so only use the larger of the two.
    final bottomSpace = keyboardHeight > 0 ? keyboardHeight : systemBottom;

    return Scaffold(
      // We handle the keyboard inset manually below for consistent behavior.
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.smart_toy_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text('AI Money Assistant'),
          ],
        ),
      ),
      body: GestureDetector(
        // Tap outside the input to dismiss the keyboard.
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: Column(
          children: [
            // Message List
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, idx) {
                  final msg = _messages[idx];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Row(
                      mainAxisAlignment:
                      msg.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!msg.isUser)
                          const CircleAvatar(
                            radius: 16,
                            backgroundColor: AppColors.primary,
                            child: Icon(Icons.smart_toy_rounded, color: Colors.white, size: 16),
                          ),
                        if (!msg.isUser) const SizedBox(width: 8),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: msg.isUser
                                  ? AppColors.primary
                                  : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
                              borderRadius: BorderRadius.circular(16),
                              border: msg.isUser
                                  ? null
                                  : Border.all(
                                  color: isDark
                                      ? AppColors.darkCardBorder
                                      : AppColors.lightCardBorder),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  msg.text,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: msg.isUser
                                        ? Colors.white
                                        : (isDark
                                        ? AppColors.darkTextPrimary
                                        : AppColors.lightTextPrimary),
                                  ),
                                ),
                                if (msg.matchedTransactions != null &&
                                    msg.matchedTransactions!.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  const Divider(height: 1),
                                  const SizedBox(height: 6),
                                  Column(
                                    children: msg.matchedTransactions!.take(3).map((t) {
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text('• ${t.merchant}',
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.bold, fontSize: 12)),
                                            Text(
                                              CurrencyFormatter.format(t.amount),
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.expenseRed,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Suggested Questions Chips
            SizedBox(
              height: 40,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: _suggestedQuestions.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, idx) {
                  final q = _suggestedQuestions[idx];
                  return ActionChip(
                    label: Text(q, style: const TextStyle(fontSize: 11)),
                    onPressed: () => _handleUserQuery(q),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),

            // Input Field: lifts above keyboard, clears system nav bar
            AnimatedPadding(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(bottom: bottomSpace),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        focusNode: _focusNode,
                        textInputAction: TextInputAction.send,
                        decoration: InputDecoration(
                          hintText: 'Ask AI e.g. How much spent on food...',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                          contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                        onSubmitted: (val) {
                          _handleUserQuery(val);
                          _focusNode.requestFocus(); // keep keyboard open
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      icon: const Icon(Icons.send_rounded),
                      onPressed: () => _handleUserQuery(_textController.text),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleUserQuery(String query) {
    if (query.trim().isEmpty) return;
    final q = query.trim().toLowerCase();
    _textController.clear();

    setState(() {
      _messages.add(AIMessage(text: query, isUser: true));
    });

    // AI Response generation
    String responseText = '';
    List<TransactionItem> matched = [];

    if (q.contains('food') || q.contains('dinner') || q.contains('swiggy')) {
      final foodTx = widget.state.transactions
          .where((t) => t.categoryName.toLowerCase().contains('food'))
          .toList();
      final total = foodTx.fold(0.0, (sum, t) => sum + t.amount);
      responseText =
      'You spent ${CurrencyFormatter.format(total)} on Food & Dining across ${foodTx.length} transactions this period.';
      matched = foodTx;
    } else if (q.contains('amazon')) {
      final amzTx = widget.state.transactions
          .where((t) => t.merchant.toLowerCase().contains('amazon'))
          .toList();
      final total = amzTx.fold(0.0, (sum, t) => sum + t.amount);
      responseText =
      'You spent ${CurrencyFormatter.format(total)} at Amazon across ${amzTx.length} transactions.';
      matched = amzTx;
    } else if (q.contains('income') || q.contains('received') || q.contains('salary')) {
      final inc = widget.state.periodIncome;
      responseText = 'You received ${CurrencyFormatter.format(inc)} in total income this period.';
    } else {
      responseText =
      'Based on your records, your total spending this month is ${CurrencyFormatter.format(widget.state.periodSpent)} across ${widget.state.filteredTransactions.length} transactions.';
    }

    setState(() {
      _messages.add(AIMessage(
        text: responseText,
        isUser: false,
        matchedTransactions: matched,
      ));
    });

    // Scroll to the newest message after the frame renders.
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }
}