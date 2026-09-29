import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:expensetracker/providers/app_state.dart';
import 'package:expensetracker/models/transaction.dart';
import 'package:expensetracker/models/category.dart';
import 'package:expensetracker/theme/app_theme.dart';
import 'package:expensetracker/utils/voice_parser.dart';
import 'package:expensetracker/screens/add_transaction/quick_add_sheet.dart';

class AddTransactionSheet extends StatefulWidget {
  final AppState state;
  final TransactionItem? initialTransaction; // For edit mode

  const AddTransactionSheet({
    super.key,
    required this.state,
    this.initialTransaction,
  });

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  TransactionType _type = TransactionType.expense;
  final _amountController = TextEditingController();
  final _merchantController = TextEditingController();
  final _noteController = TextEditingController();
  String? _selectedCategoryId;
  String? _selectedAccountId;
  String? _selectedToAccountId;
  DateTime _selectedDate = DateTime.now();
  final List<String> _selectedTags = [];
  String? _receiptPath;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialTransaction != null) {
      final t = widget.initialTransaction!;
      _type = t.type;
      _amountController.text = t.amount.toStringAsFixed(t.amount % 1 == 0 ? 0 : 2);
      _merchantController.text = t.merchant;
      _noteController.text = t.note;
      _selectedCategoryId = t.categoryId;
      _selectedAccountId = t.accountId;
      _selectedToAccountId = t.toAccountId;
      _selectedDate = t.date;
      _selectedTags.addAll(t.tags);
      _receiptPath = t.receiptImagePath;
    } else {
      if (widget.state.categories.isNotEmpty) {
        _selectedCategoryId = widget.state.categories.first.id;
      }
      if (widget.state.accounts.isNotEmpty) {
        _selectedAccountId = widget.state.accounts.first.id;
        if (widget.state.accounts.length > 1) {
          _selectedToAccountId = widget.state.accounts[1].id;
        }
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _merchantController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  bool get _hasUnsavedChanges {
    if (widget.initialTransaction != null) return false;
    return _amountController.text.isNotEmpty ||
        _merchantController.text.isNotEmpty ||
        _noteController.text.isNotEmpty ||
        _receiptPath != null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.state.profile.isDarkMode;

    return PopScope(
      canPop: !_hasUnsavedChanges || _isSaving,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Discard Unsaved Changes?'),
            content: const Text('You have started entering details. Are you sure you want to discard them?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep Editing')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.expenseRed, foregroundColor: Colors.white),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Discard'),
              ),
            ],
          ),
        );
        if (shouldPop == true && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + 28,
            ),
            child: ListView(
              controller: scrollController,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.initialTransaction != null ? 'Edit Record' : 'Add Record',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          tooltip: 'Voice Entry',
                          icon: const Icon(Icons.mic_rounded, color: AppColors.primary),
                          onPressed: _showVoiceDialog,
                        ),
                        IconButton(
                          tooltip: 'Quick Shortcuts',
                          icon: const Icon(Icons.flash_on_rounded, color: AppColors.warningOrange),
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              builder: (_) => QuickAddSheet(state: widget.state),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.maybePop(context),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Segmented Type Control
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      _typeTab('Expense', TransactionType.expense, AppColors.expenseRed),
                      _typeTab('Income', TransactionType.income, AppColors.incomeGreen),
                      _typeTab('Transfer', TransactionType.transfer, AppColors.infoBlue),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // BIG AMOUNT FOCUS
                Center(
                  child: Column(
                    children: [
                      Text(
                        'AMOUNT',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '₹ ',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: _getTypeColor(),
                            ),
                          ),
                          SizedBox(
                            width: 200,
                            child: TextField(
                              controller: _amountController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              autofocus: widget.initialTransaction == null,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 38,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              ),
                              decoration: const InputDecoration(
                                hintText: '0',
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // CATEGORY PICKER (if expense or income)
                if (_type != TransactionType.transfer) ...[
                  Text(
                    'Category',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 44,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _filteredCategories().length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, idx) {
                        final cat = _filteredCategories()[idx];
                        final isSel = _selectedCategoryId == cat.id;
                        return ChoiceChip(
                          selected: isSel,
                          label: Text(cat.name),
                          selectedColor: AppColors.primary.withValues(alpha: 0.2),
                          labelStyle: TextStyle(
                            color: isSel
                                ? AppColors.primary
                                : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                            fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (val) {
                            if (val) setState(() => _selectedCategoryId = cat.id);
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // PAYMENT METHOD / ACCOUNT SELECTION
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _type == TransactionType.transfer ? 'From Account' : 'Payment Account',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedAccountId,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            items: widget.state.accounts.map((acc) {
                              return DropdownMenuItem(
                                value: acc.id,
                                child: Text(acc.name, style: const TextStyle(fontSize: 14)),
                              );
                            }).toList(),
                            onChanged: (val) => setState(() => _selectedAccountId = val),
                          ),
                        ],
                      ),
                    ),
                    if (_type == TransactionType.transfer) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'To Account',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              initialValue: _selectedToAccountId,
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              items: widget.state.accounts.map((acc) {
                                return DropdownMenuItem(
                                  value: acc.id,
                                  child: Text(acc.name, style: const TextStyle(fontSize: 14)),
                                );
                              }).toList(),
                              onChanged: (val) => setState(() => _selectedToAccountId = val),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 20),

                // MERCHANT NAME
                if (_type != TransactionType.transfer) ...[
                  TextField(
                    controller: _merchantController,
                    decoration: InputDecoration(
                      labelText: 'Merchant / Payee Name',
                      hintText: 'e.g. Swiggy, Amazon, Uber',
                      prefixIcon: const Icon(Icons.storefront_rounded),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // NOTE FIELD (WHY DID YOU SPEND THIS?)
                TextField(
                  controller: _noteController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Why did you make this payment? (Note)',
                    hintText: 'e.g. Lunch order with Rahul, Office headphones, Electricity bill',
                    prefixIcon: const Icon(Icons.sticky_note_2_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 20),

                // TAGS
                Text(
                  'Tags',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    ...widget.state.allAvailableTags.map((tag) {
                      final isSel = _selectedTags.contains(tag);
                      return FilterChip(
                        selected: isSel,
                        label: Text('#$tag', style: const TextStyle(fontSize: 12)),
                        onSelected: (val) {
                          setState(() {
                            if (val) {
                              _selectedTags.add(tag);
                            } else {
                              _selectedTags.remove(tag);
                            }
                          });
                        },
                      );
                    }),
                    ActionChip(
                      avatar: const Icon(Icons.add_rounded, size: 16),
                      label: const Text('Add Tag', style: TextStyle(fontSize: 12)),
                      onPressed: _promptAddNewTag,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // RECEIPT ATTACHMENT
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Receipt / Proof',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.add_a_photo_rounded, size: 18),
                      label: Text(_receiptPath == null ? 'Attach Receipt' : 'Change Receipt'),
                      onPressed: _pickReceiptImage,
                    ),
                  ],
                ),
                if (_receiptPath != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.image_rounded, color: AppColors.primary),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Receipt attached successfully',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20),
                          onPressed: () => setState(() => _receiptPath = null),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),

                // SAVE BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _isSaving ? null : _onSave,
                    child: _isSaving
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(
                            widget.initialTransaction != null ? 'Update Transaction' : 'Save Transaction',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _typeTab(String label, TransactionType type, Color activeColor) {
    final isSelected = _type == type;
    final isDark = widget.state.profile.isDarkMode;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _type = type;
            final availableCats = _filteredCategories();
            if (availableCats.isNotEmpty) {
              if (!availableCats.any((c) => c.id == _selectedCategoryId)) {
                _selectedCategoryId = availableCats.first.id;
              }
            }
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? (isDark ? AppColors.darkSurface : Colors.white) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? activeColor
                    : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getTypeColor() {
    switch (_type) {
      case TransactionType.expense:
        return AppColors.expenseRed;
      case TransactionType.income:
        return AppColors.incomeGreen;
      case TransactionType.transfer:
        return AppColors.infoBlue;
      default:
        return AppColors.primary;
    }
  }

  List<Category> _filteredCategories() {
    final catType = _type == TransactionType.income ? CategoryType.income : CategoryType.expense;
    return widget.state.categories.where((c) => c.type == catType).toList();
  }

  Future<void> _pickReceiptImage() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() => _receiptPath = image.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Receipt image attachment canceled or unavailable.')),
        );
      }
    }
  }

  void _showVoiceDialog() {
    final voiceController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.mic_rounded, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Voice Expense Entry'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Type or speak natural sentence like:\n"Spent 450 on dinner at Zomato" or "Received 25000 salary"',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: voiceController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'e.g. Spent 450 on dinner at Zomato',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final result = VoiceParser.parse(voiceController.text);
                setState(() {
                  _type = result.type;
                  _amountController.text = result.amount > 0 ? result.amount.toStringAsFixed(0) : '';
                  _merchantController.text = result.merchant;
                  _noteController.text = result.note;
                  final matchCat = widget.state.categories.firstWhere(
                    (c) => c.name.toLowerCase().contains(result.categorySuggestion.toLowerCase()),
                    orElse: () => widget.state.categories.first,
                  );
                  _selectedCategoryId = matchCat.id;
                });
                Navigator.pop(ctx);
              },
              child: const Text('Parse & Fill'),
            ),
          ],
        );
      },
    );
  }

  void _promptAddNewTag() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New Tag'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            hintText: 'e.g. Travel, Bonus, Project',
            prefixText: '# ',
          ),
          onSubmitted: (val) {
            final t = val.trim();
            if (t.isNotEmpty) {
              widget.state.addTag(t);
              setState(() {
                if (!_selectedTags.contains(t)) _selectedTags.add(t);
              });
              Navigator.pop(ctx);
            }
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            onPressed: () {
              final t = controller.text.trim();
              if (t.isNotEmpty) {
                widget.state.addTag(t);
                setState(() {
                  if (!_selectedTags.contains(t)) _selectedTags.add(t);
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add & Select'),
          ),
        ],
      ),
    );
  }

  void _onSave() async {
    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (amount <= 0 || !amount.isFinite) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid positive amount')),
      );
      return;
    }

    if (_type != TransactionType.transfer && widget.state.categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please create at least one category first')),
      );
      return;
    }

    if (widget.state.accounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please create at least one account first')),
      );
      return;
    }

    String? toAccId;
    String? toAccName;
    if (_type == TransactionType.transfer) {
      if (widget.state.accounts.length < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You need at least two accounts to make a transfer.')),
        );
        return;
      }
      final acc = widget.state.accounts.firstWhere(
        (a) => a.id == _selectedAccountId,
        orElse: () => widget.state.accounts.first,
      );
      final toAcc = widget.state.accounts.firstWhere(
        (a) => a.id == _selectedToAccountId,
        orElse: () => widget.state.accounts.firstWhere((a) => a.id != acc.id, orElse: () => widget.state.accounts.last),
      );
      if (acc.id == toAcc.id) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Source and destination accounts cannot be the same.')),
        );
        return;
      }
      toAccId = toAcc.id;
      toAccName = toAcc.name;
    }

    setState(() => _isSaving = true);

    final availableCats = _filteredCategories();
    final cat = availableCats.firstWhere(
      (c) => c.id == _selectedCategoryId,
      orElse: () => availableCats.isNotEmpty
          ? availableCats.first
          : (widget.state.categories.isNotEmpty
              ? widget.state.categories.first
              : Category(
                  id: 'cat_gen',
                  name: 'General',
                  type: CategoryType.expense,
                  iconCode: 0xe59c,
                  colorHex: 0xFF00B2E7,
                )),
    );

    final acc = widget.state.accounts.firstWhere(
      (a) => a.id == _selectedAccountId,
      orElse: () => widget.state.accounts.first,
    );

    final merchantText = _merchantController.text.trim();
    final effectiveMerchant = merchantText.isNotEmpty
        ? merchantText
        : (_type == TransactionType.transfer ? 'Transfer to $toAccName' : cat.name);

    final t = TransactionItem(
      id: widget.initialTransaction?.id ?? 'tx_${DateTime.now().millisecondsSinceEpoch}',
      type: _type,
      amount: amount,
      categoryId: cat.id,
      categoryName: cat.name,
      accountId: acc.id,
      accountName: acc.name,
      toAccountId: toAccId,
      toAccountName: toAccName,
      merchant: effectiveMerchant,
      note: _noteController.text.trim(),
      date: _selectedDate,
      tags: _selectedTags,
      receiptImagePath: _receiptPath,
    );

    if (widget.initialTransaction != null) {
      await widget.state.updateTransaction(t);
    } else {
      await widget.state.addTransaction(t);
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_type.name.toUpperCase()} recorded successfully'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
