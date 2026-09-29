import 'package:flutter/material.dart';
import 'package:expensetracker/models/account.dart';
import 'package:expensetracker/models/budget.dart';
import 'package:expensetracker/models/category.dart';
import 'package:expensetracker/providers/app_state.dart';
import 'package:expensetracker/screens/main_navigation_screen.dart';
import 'package:expensetracker/services/sms_capture_service.dart';
import 'package:expensetracker/theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  final AppState state;

  const OnboardingScreen({super.key, required this.state});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _stepCount = 8;

  final PageController _pageController = PageController();
  final _nameController = TextEditingController();
  final _incomeController = TextEditingController();
  final _accountNameController = TextEditingController();
  final _accountBalanceController = TextEditingController();
  final _categoryController = TextEditingController();
  final _tagController = TextEditingController();
  final _budgetController = TextEditingController();

  int _currentStep = 0;
  String _selectedCurrency = '₹';
  AccountType _accountType = AccountType.bank;
  CategoryType _categoryType = CategoryType.expense;
  String? _selectedBudgetCategoryId;
  bool _isFinishing = false;
  bool _smsPermissionGranted = false;
  bool _isRequestingSmsPermission = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _refreshSmsPermission();
  }

  Future<void> _refreshSmsPermission() async {
    final granted = await SmsCaptureService.hasPermission();
    if (mounted) setState(() => _smsPermissionGranted = granted);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _incomeController.dispose();
    _accountNameController.dispose();
    _accountBalanceController.dispose();
    _categoryController.dispose();
    _tagController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  bool get _hasName => _nameController.text.trim().isNotEmpty;

  List<Category> get _expenseCategories => widget.state.categories
      .where((category) => category.type == CategoryType.expense)
      .toList();

  void _goToStep(int step) {
    if (step < 0 || step >= _stepCount || _isFinishing) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _currentStep = step;
      _message = null;
    });
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeInOut,
    );
  }

  void _continue() {
    if (_currentStep == 0 && !_hasName) {
      setState(() => _message = 'Please enter your name to continue.');
      return;
    }

    if (_currentStep == _stepCount - 1) {
      _finishOnboarding();
    } else {
      _goToStep(_currentStep + 1);
    }
  }

  void _skip() => _goToStep(_currentStep + 1);

  Future<void> _finishOnboarding() async {
    if (!_hasName || _isFinishing) {
      setState(() => _message = 'Please enter your name to continue.');
      return;
    }

    setState(() => _isFinishing = true);
    await widget.state.completeOnboarding(
      name: _nameController.text.trim(),
      currencySymbol: _selectedCurrency,
      monthlyIncomeGoal:
          double.tryParse(_incomeController.text.trim()) ??
          widget.state.profile.monthlyIncomeGoal,
    );

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => MainNavigationScreen(state: widget.state),
        ),
      );
    }
  }

  Future<void> _addAccount() async {
    final name = _accountNameController.text.trim();
    if (name.isEmpty) {
      setState(() => _message = 'Enter an account name or skip this step.');
      return;
    }

    final balance = double.tryParse(_accountBalanceController.text.trim()) ?? 0;
    await widget.state.addAccount(
      Account(
        id: 'acc_${DateTime.now().microsecondsSinceEpoch}',
        name: name,
        type: _accountType,
        balance: balance,
        startingBalance: balance,
        colorHex: _accountColor(_accountType),
      ),
    );

    if (mounted) {
      setState(() {
        _accountNameController.clear();
        _accountBalanceController.clear();
        _message = '$name added.';
      });
    }
  }

  Future<void> _addCategory() async {
    final name = _categoryController.text.trim();
    if (name.isEmpty) {
      setState(() => _message = 'Enter a category name or skip this step.');
      return;
    }

    await widget.state.addCategory(
      Category(
        id: 'cat_custom_${DateTime.now().microsecondsSinceEpoch}',
        name: name,
        type: _categoryType,
        iconCode: _categoryType == CategoryType.expense ? 0xe56c : 0xe227,
        colorHex: _categoryType == CategoryType.expense
            ? 0xFF3B82F6
            : 0xFF10B981,
      ),
    );

    if (mounted) {
      setState(() {
        _categoryController.clear();
        _message = '$name added.';
      });
    }
  }

  Future<void> _addTag() async {
    final name = _tagController.text.trim();
    if (name.isEmpty) {
      setState(() => _message = 'Enter a tag or skip this step.');
      return;
    }

    await widget.state.addTag(name);
    if (mounted) {
      setState(() {
        _tagController.clear();
        _message = '#$name added.';
      });
    }
  }

  Future<void> _addBudget() async {
    final categoryId = _selectedBudgetCategoryId;
    final amount = double.tryParse(_budgetController.text.trim()) ?? 0;
    if (categoryId == null || amount <= 0) {
      setState(
        () => _message = 'Choose a category and enter a valid amount, or skip.',
      );
      return;
    }

    final category = _expenseCategories.firstWhere(
      (item) => item.id == categoryId,
    );
    await widget.state.addBudget(
      Budget(
        id: 'budget_${DateTime.now().microsecondsSinceEpoch}',
        categoryId: category.id,
        categoryName: category.name,
        limitAmount: amount,
      ),
    );

    if (mounted) {
      setState(() {
        _budgetController.clear();
        _message = '${category.name} budget added.';
      });
    }
  }

  Future<void> _requestSmsPermission() async {
    if (_isRequestingSmsPermission || _smsPermissionGranted) return;

    setState(() => _isRequestingSmsPermission = true);
    final granted = await SmsCaptureService.requestPermission();
    if (!mounted) return;

    setState(() {
      _isRequestingSmsPermission = false;
      _smsPermissionGranted = granted;
      _message = granted
          ? 'Automatic SMS capture is enabled.'
          : 'SMS access was not enabled. You can continue with manual entries.';
    });
  }

  int _accountColor(AccountType type) {
    switch (type) {
      case AccountType.bank:
        return 0xFF3B82F6;
      case AccountType.cash:
        return 0xFF10B981;
      case AccountType.creditCard:
        return 0xFF8B5CF6;
      case AccountType.wallet:
        return 0xFFF59E0B;
      case AccountType.investment:
        return 0xFF06B6D4;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.state.profile.isDarkMode;
    final canSkip = _currentStep > 0 && _currentStep < _stepCount - 1;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      appBar: AppBar(
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => _goToStep(_currentStep - 1),
              )
            : null,
        title: Text('Setup ${_currentStep + 1} of $_stepCount'),
        actions: [
          if (canSkip) TextButton(onPressed: _skip, child: const Text('Skip')),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
              child: Row(
                children: List.generate(
                  _stepCount,
                  (index) => Expanded(
                    child: Container(
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: index <= _currentStep
                            ? AppColors.primary
                            : (isDark ? Colors.white12 : Colors.black12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildNameStep(isDark),
                  _buildPreferencesStep(isDark),
                  _buildSmsStep(isDark),
                  _buildAccountStep(isDark),
                  _buildCategoryStep(isDark),
                  _buildTagStep(isDark),
                  _buildBudgetStep(isDark),
                  _buildCompleteStep(isDark),
                ],
              ),
            ),
            if (_message != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  _message!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _message!.contains('added')
                        ? AppColors.incomeGreen
                        : AppColors.expenseRed,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isFinishing ? null : _continue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isFinishing
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _currentStep == _stepCount - 1
                              ? 'Start using RupeeCommand'
                              : 'Continue',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNameStep(bool isDark) {
    return _stepShell(
      isDark: isDark,
      icon: Icons.waving_hand_rounded,
      title: 'Welcome to RupeeCommand',
      subtitle: 'Let’s start with the one detail we need to personalize your money workspace.',
      child: TextField(
        controller: _nameController,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        onChanged: (_) => setState(() => _message = null),
        decoration: _inputDecoration(
          'Your name',
          Icons.person_outline,
          required: true,
        ),
      ),
    );
  }

  Widget _buildPreferencesStep(bool isDark) {
    return _stepShell(
      isDark: isDark,
      icon: Icons.tune_rounded,
      title: 'Set your preferences',
      subtitle:
          'These are optional. You can change them later in your profile.',
      child: Column(
        children: [
          TextField(
            controller: _incomeController,
            keyboardType: TextInputType.number,
            decoration: _inputDecoration(
              'Monthly income (optional)',
              Icons.currency_rupee,
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _selectedCurrency,
            decoration: _inputDecoration('Currency', Icons.language),
            items: const [
              DropdownMenuItem(
                value: '₹',
                child: Text('INR (₹) - Indian Rupee'),
              ),
              DropdownMenuItem(
                value: '\$',
                child: Text('USD (\$) - US Dollar'),
              ),
              DropdownMenuItem(value: '€', child: Text('EUR (€) - Euro')),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _selectedCurrency = value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSmsStep(bool isDark) {
    return _stepShell(
      isDark: isDark,
      icon: Icons.sms_rounded,
      title: 'Capture expenses from SMS',
      subtitle: 'If your bank sends transaction SMS alerts, RupeeCommand can read new alerts and add recognized expenses automatically. OTPs and promotional messages are ignored.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _smsPermissionGranted
                  ? AppColors.incomeGreen.withValues(alpha: 0.1)
                  : AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  _smsPermissionGranted
                      ? Icons.check_circle_rounded
                      : Icons.info_outline_rounded,
                  color: _smsPermissionGranted
                      ? AppColors.incomeGreen
                      : AppColors.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _smsPermissionGranted
                        ? 'SMS capture is enabled. Recognized alerts will be added to your first account.'
                        : 'This is optional. You can skip it and enable SMS access later if you want automatic entries.',
                    style: const TextStyle(height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (!_smsPermissionGranted)
            OutlinedButton.icon(
              onPressed: _isRequestingSmsPermission
                  ? null
                  : _requestSmsPermission,
              icon: _isRequestingSmsPermission
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.lock_open_rounded),
              label: const Text('Allow automatic SMS capture'),
            ),
        ],
      ),
    );
  }

  Widget _buildAccountStep(bool isDark) {
    return _stepShell(
      isDark: isDark,
      icon: Icons.account_balance_wallet_rounded,
      title: 'Add an account',
      subtitle: 'Add a bank account, wallet, cash account, or card. You can skip this and add one later.',
      child: Column(
        children: [
          TextField(
            controller: _accountNameController,
            textCapitalization: TextCapitalization.words,
            decoration: _inputDecoration(
              'Account name',
              Icons.account_balance_outlined,
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<AccountType>(
            initialValue: _accountType,
            decoration: _inputDecoration(
              'Account type',
              Icons.category_outlined,
            ),
            items: AccountType.values
                .map(
                  (type) => DropdownMenuItem(
                    value: type,
                    child: Text(_accountLabel(type)),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => _accountType = value);
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _accountBalanceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: _inputDecoration(
              'Starting balance (optional)',
              Icons.currency_rupee,
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: _addAccount,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add another account'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryStep(bool isDark) {
    return _stepShell(
      isDark: isDark,
      icon: Icons.category_rounded,
      title: 'Customize categories',
      subtitle: 'Your app already has starter categories. Add a personal one now, or skip for later.',
      child: Column(
        children: [
          TextField(
            controller: _categoryController,
            textCapitalization: TextCapitalization.words,
            decoration: _inputDecoration(
              'Category name',
              Icons.edit_note_rounded,
            ),
          ),
          const SizedBox(height: 16),
          SegmentedButton<CategoryType>(
            segments: const [
              ButtonSegment(
                value: CategoryType.expense,
                label: Text('Expense'),
                icon: Icon(Icons.arrow_upward_rounded),
              ),
              ButtonSegment(
                value: CategoryType.income,
                label: Text('Income'),
                icon: Icon(Icons.arrow_downward_rounded),
              ),
            ],
            selected: {_categoryType},
            onSelectionChanged: (selection) =>
                setState(() => _categoryType = selection.first),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: _addCategory,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add category'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagStep(bool isDark) {
    return _stepShell(
      isDark: isDark,
      icon: Icons.sell_rounded,
      title: 'Organize with tags',
      subtitle: 'Tags such as Travel, Work, or Family make transactions easier to find. This step is optional.',
      child: Column(
        children: [
          TextField(
            controller: _tagController,
            textCapitalization: TextCapitalization.words,
            decoration: _inputDecoration('Tag name', Icons.tag_rounded),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: _addTag,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add tag'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetStep(bool isDark) {
    final categories = _expenseCategories;
    _selectedBudgetCategoryId ??= categories.isNotEmpty
        ? categories.first.id
        : null;

    return _stepShell(
      isDark: isDark,
      icon: Icons.pie_chart_rounded,
      title: 'Plan a budget',
      subtitle: 'Set a monthly limit for a category if you are ready. You can skip this and create budgets later.',
      child: categories.isEmpty
          ? const Text(
              'No expense categories are available yet. You can create a budget later.',
            )
          : Column(
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _selectedBudgetCategoryId,
                  decoration: _inputDecoration(
                    'Category',
                    Icons.category_outlined,
                  ),
                  items: categories
                      .map(
                        (category) => DropdownMenuItem(
                          value: category.id,
                          child: Text(category.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _selectedBudgetCategoryId = value),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _budgetController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: _inputDecoration(
                    'Monthly limit',
                    Icons.currency_rupee,
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: _addBudget,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add budget'),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCompleteStep(bool isDark) {
    return _stepShell(
      isDark: isDark,
      icon: Icons.check_circle_rounded,
      title: 'You’re ready to go',
      subtitle: 'You can manage accounts, categories, tags, and budgets anytime from the More tab.',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text(
          'Your name is required. Everything else in this setup was optional, and you can update it later.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, height: 1.4),
        ),
      ),
    );
  }

  Widget _stepShell({
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 52, color: AppColors.primary),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 28),
          child,
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(
    String label,
    IconData icon, {
    bool required = false,
  }) {
    return InputDecoration(
      labelText: required ? '$label *' : label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  String _accountLabel(AccountType type) {
    switch (type) {
      case AccountType.bank:
        return 'Bank account';
      case AccountType.cash:
        return 'Cash';
      case AccountType.creditCard:
        return 'Credit card';
      case AccountType.wallet:
        return 'Wallet / UPI';
      case AccountType.investment:
        return 'Investment';
    }
  }
}
