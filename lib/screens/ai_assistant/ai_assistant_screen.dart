import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:expensetracker/providers/app_state.dart';
import 'package:expensetracker/models/transaction.dart';
import 'package:expensetracker/theme/app_theme.dart';
import 'package:expensetracker/utils/currency_formatter.dart';
import 'package:expensetracker/services/ai/llm_service.dart';
import 'package:expensetracker/services/ai/rule_based_fallback.dart';
import 'package:expensetracker/services/ai/query_executor.dart';
import 'package:expensetracker/services/ai/answer_formatter.dart';

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
  final LlmService _llmService = LlmService();

  final List<String> _suggestedQuestions = const [
    'How much did I spend on food this month?',
    'What did I spend at Amazon?',
    'How much money do I have in bank accounts?',
    'Am I over budget?',
    'Show upcoming recurring bills',
  ];

  @override
  void initState() {
    super.initState();
    _initLlm();
    _messages.add(
      AIMessage(
        text: 'Hello ${widget.state.profile.name}! I am your offline AI Money Assistant. Ask me anything about your recorded transactions, budgets, or balances.',
        isUser: false,
      ),
    );

    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 300), _scrollToBottom);
      }
    });
  }

  Future<void> _initLlm() async {
    await _llmService.init();
    if (mounted) setState(() {});
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
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final systemBottom = MediaQuery.of(context).viewPadding.bottom;
    final bottomSpace = keyboardHeight > 0 ? keyboardHeight : systemBottom;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.smart_toy_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text('AI Money Assistant'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Local Model Settings',
            icon: Icon(
              Icons.memory_rounded,
              color: _llmService.status == LlmStatus.ready ? AppColors.incomeGreen : Colors.grey,
            ),
            onPressed: _showModelSettingsDialog,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: GestureDetector(
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
                      mainAxisAlignment: msg.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
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
                                  : Border.all(color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder),
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
                                        : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                                  ),
                                ),
                                if (msg.matchedTransactions != null && msg.matchedTransactions!.isNotEmpty) ...[
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
                                            Text('• ${t.merchant}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                            Text(
                                              CurrencyFormatter.format(t.amount, isPrivacyMode: widget.state.profile.isPrivacyModeEnabled),
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

            // Input Field
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
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                        onSubmitted: (val) {
                          _handleUserQuery(val);
                          _focusNode.requestFocus();
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
    _textController.clear();

    setState(() {
      _messages.add(AIMessage(text: query, isUser: true));
    });

    // Parse via RuleBasedFallback (or LLM if ready) into QuerySpec
    final spec = RuleBasedFallback.parse(query);

    // Execute query against AppState data via QueryExecutor
    final result = QueryExecutor.execute(
      spec: spec,
      transactions: widget.state.transactions,
      accounts: widget.state.accounts,
      budgets: widget.state.budgets,
      goals: widget.state.goals,
      recurringBills: widget.state.recurringBills,
    );

    // Format response via AnswerFormatter
    final answerText = AnswerFormatter.format(spec, result);

    setState(() {
      _messages.add(AIMessage(
        text: answerText,
        isUser: false,
        matchedTransactions: result.transactions,
      ));
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _showModelSettingsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Offline LLM Model Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status: ${_llmService.status == LlmStatus.ready ? 'Ready (${_llmService.modelFilePath?.split('/').last})' : 'Not Installed (Using Rule-Based Fallback)'}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _llmService.status == LlmStatus.ready ? AppColors.incomeGreen : Colors.orange,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'RupeeCommand runs 100% offline. You can optionally sideload a quantized GGUF model file (0.5B - 1.5B params) from your device storage.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          if (_llmService.status == LlmStatus.ready)
            TextButton(
              onPressed: () async {
                final nav = Navigator.of(ctx);
                final messenger = ScaffoldMessenger.of(ctx);
                await _llmService.removeModel();
                nav.pop();
                setState(() {});
                messenger.showSnackBar(
                  const SnackBar(content: Text('Local model removed.')),
                );
              },
              child: const Text('Remove Model', style: TextStyle(color: AppColors.expenseRed)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () async {
              final nav = Navigator.of(ctx);
              final messenger = ScaffoldMessenger.of(ctx);
              nav.pop();
              final picked = await FilePicker.platform.pickFiles(type: FileType.any);
              if (picked != null && picked.files.single.path != null) {
                await _llmService.copyToAppStorage(picked.files.single.path!);
                setState(() {});
                messenger.showSnackBar(
                  const SnackBar(content: Text('Local GGUF model loaded successfully.')),
                );
              }
            },
            child: const Text('Select .gguf File'),
          ),
        ],
      ),
    );
  }
}
