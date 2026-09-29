import 'package:flutter/material.dart';
import 'package:expensetracker/providers/app_state.dart';
import 'package:expensetracker/features/transactions/data/custom_rules_repository.dart';
import 'package:expensetracker/theme/app_theme.dart';
import 'package:expensetracker/services/haptic_service.dart';

class ParserRulesScreen extends StatefulWidget {
  final AppState state;
  const ParserRulesScreen({super.key, required this.state});

  @override
  State<ParserRulesScreen> createState() => _ParserRulesScreenState();
}

class _ParserRulesScreenState extends State<ParserRulesScreen> {
  late CustomRulesRepository _repository;
  List<CustomParserRule> _rules = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _repository = CustomRulesRepository(widget.state.databaseService.db);
    _loadRules();
  }

  void _loadRules() {
    setState(() {
      _rules = _repository.getAllRules();
      _isLoading = false;
    });
  }

  void _showRuleDialog({CustomParserRule? ruleToEdit}) {
    HapticService.selection();
    final nameController = TextEditingController(text: ruleToEdit?.name ?? '');
    final keywordController = TextEditingController(text: ruleToEdit?.keyword ?? '');
    final patternController = TextEditingController(text: ruleToEdit?.pattern ?? '');
    final categoryController = TextEditingController(text: ruleToEdit?.categoryName ?? 'Food & Dining');
    final accountController = TextEditingController(text: ruleToEdit?.accountRef ?? 'BOI Account');
    
    bool isRegex = ruleToEdit?.isRegex ?? false;
    bool isDebit = ruleToEdit?.isDebit ?? true;
    int priority = ruleToEdit?.priority ?? 0;
    String? regexError;

    final testTextController = TextEditingController(text: 'Paid Rs 450 to Swiggy via UPI');
    String testResultText = '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(ruleToEdit == null ? 'Create Custom Parser Rule' : 'Edit Parser Rule'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Rule Name (e.g. Swiggy Food Rule)'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: keywordController,
                    decoration: const InputDecoration(labelText: 'Keyword Match (e.g. SWIGGY)'),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Use Advanced Regex Pattern'),
                    value: isRegex,
                    onChanged: (val) {
                      setDialogState(() {
                        isRegex = val;
                      });
                    },
                  ),
                  if (isRegex) ...[
                    TextField(
                      controller: patternController,
                      decoration: InputDecoration(
                        labelText: 'Regular Expression',
                        errorText: regexError,
                      ),
                      onChanged: (val) {
                        setDialogState(() {
                          regexError = CustomRulesRepository.validateRegex(val);
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: categoryController,
                    decoration: const InputDecoration(labelText: 'Assigned Category'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: accountController,
                    decoration: const InputDecoration(labelText: 'Assigned Bank/Account Ref'),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Is Debit / Expense'),
                    value: isDebit,
                    onChanged: (val) {
                      setDialogState(() {
                        isDebit = val;
                      });
                    },
                  ),
                  const Divider(height: 24),
                  const Text('Test Rule Against Sample SMS:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: testTextController,
                    decoration: const InputDecoration(hintText: 'Enter sample SMS text'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      final sample = testTextController.text;
                      bool matched = false;
                      if (isRegex && patternController.text.isNotEmpty) {
                        try {
                          final reg = RegExp(patternController.text, caseSensitive: false);
                          matched = reg.hasMatch(sample);
                        } catch (_) {
                          matched = false;
                        }
                      } else if (keywordController.text.isNotEmpty) {
                        matched = sample.toLowerCase().contains(keywordController.text.toLowerCase());
                      }
                      setDialogState(() {
                        testResultText = matched ? '✅ Match Success! Category: ${categoryController.text}' : '❌ No Match';
                      });
                    },
                    child: const Text('Test Rule'),
                  ),
                  if (testResultText.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(testResultText, style: TextStyle(fontWeight: FontWeight.bold, color: testResultText.contains('✅') ? AppColors.incomeGreen : AppColors.expenseRed)),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (isRegex && patternController.text.isNotEmpty) {
                  final err = CustomRulesRepository.validateRegex(patternController.text);
                  if (err != null) {
                    setDialogState(() => regexError = err);
                    return;
                  }
                }
                if (nameController.text.trim().isEmpty) return;

                final newRule = CustomParserRule(
                  id: ruleToEdit?.id ?? 'rule_${DateTime.now().millisecondsSinceEpoch}',
                  name: nameController.text.trim(),
                  keyword: keywordController.text.trim(),
                  pattern: patternController.text.trim(),
                  isRegex: isRegex,
                  categoryName: categoryController.text.trim(),
                  accountRef: accountController.text.trim(),
                  isDebit: isDebit,
                  isEnabled: true,
                  priority: priority,
                );

                _repository.saveRule(newRule);
                HapticService.success();
                Navigator.pop(context);
                _loadRules();
              },
              child: const Text('Save Rule'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.state.profile.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Parsing Rules'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showRuleDialog(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Rule'),
        backgroundColor: AppColors.primary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _rules.isEmpty
              ? const Center(
                  child: Text('No custom parser rules created yet.\nTap Add Rule to create keyword or regex rules.'),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _rules.length,
                  separatorBuilder: (_, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final rule = _rules[index];
                    return Card(
                      child: ListTile(
                        title: Text(rule.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          '${rule.isRegex ? "Regex: ${rule.pattern}" : "Keyword: ${rule.keyword}"}\nCategory: ${rule.categoryName} • ${rule.isDebit ? "Expense" : "Income"}',
                          style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                        ),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Switch(
                              value: rule.isEnabled,
                              onChanged: (val) {
                                HapticService.selection();
                                _repository.toggleRule(rule.id, val);
                                _loadRules();
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.expenseRed),
                              onPressed: () {
                                HapticService.warning();
                                _repository.deleteRule(rule.id);
                                _loadRules();
                              },
                            ),
                          ],
                        ),
                        onTap: () => _showRuleDialog(ruleToEdit: rule),
                      ),
                    );
                  },
                ),
    );
  }
}
