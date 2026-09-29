import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:expensetracker/models/account.dart';
import 'package:expensetracker/models/category.dart';
import 'package:expensetracker/models/transaction.dart';
import 'package:expensetracker/models/budget.dart';
import 'package:expensetracker/models/goal.dart';
import 'package:expensetracker/models/recurring_bill.dart';
import 'package:expensetracker/models/shared_expense.dart';
import 'package:expensetracker/models/user_profile.dart';
import 'package:expensetracker/models/review_queue_item.dart';
import 'package:expensetracker/services/database_service.dart';
import 'package:expensetracker/services/sms_capture_service.dart';
import 'package:expensetracker/services/sms_parser_service.dart';
import 'package:expensetracker/services/csv_data_service.dart';
import 'package:expensetracker/utils/currency_formatter.dart';
import 'package:expensetracker/features/transactions/domain/financial_calculator.dart';

export 'package:expensetracker/features/transactions/domain/financial_calculator.dart' show TimePeriod;

class AppState extends ChangeNotifier {
  late DatabaseService _db;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  DatabaseService get databaseService => _db;

  UserProfile profile = UserProfile();
  List<Account> accounts = [];
  List<Category> categories = [];
  List<TransactionItem> transactions = [];
  List<Budget> budgets = [];
  List<Goal> goals = [];
  List<RecurringBill> recurringBills = [];
  List<SharedExpense> sharedExpenses = [];
  List<ReviewQueueItem> reviewQueue = [];
  List<String> customTags = [];

  TimePeriod selectedPeriod = TimePeriod.thisMonth;
  DateTimeRange? customDateRange;

  AppState();

  Future<void> init(DatabaseService db) async {
    _db = db;
    profile = await _db.getProfile();
    CurrencyFormatter.defaultSymbol = profile.currencySymbol;
    accounts = await _db.getAccounts();
    categories = await _db.getCategories();
    transactions = await _db.getTransactions();
    budgets = await _db.getBudgets();
    goals = await _db.getGoals();
    recurringBills = await _db.getRecurringBills();
    sharedExpenses = await _db.getSharedExpenses();
    reviewQueue = await _db.getReviewQueue();
    customTags = await _db.getTags();

    if (!_db.hasMigratedCleanSlate()) {
      transactions.clear();
      accounts.clear();
      budgets.clear();
      goals.clear();
      recurringBills.clear();
      sharedExpenses.clear();
      reviewQueue.clear();
      await _saveAll();
      await _db.setMigratedCleanSlate();
    }

    if (!_db.hasMigratedOpeningBalances()) {
      transactions.removeWhere(
        (transaction) => transaction.source == 'openingBalance',
      );
      await _db.saveTransactions(transactions);
      await _db.setMigratedOpeningBalances();
    }

    if (categories.isEmpty) {
      _seedDefaultCategories();
      await _db.saveCategories(categories);
    }

    if (accounts.isEmpty) {
      accounts = [
        Account(
          id: 'acc_cash',
          name: 'Cash Wallet',
          type: AccountType.cash,
          balance: 0.0,
          startingBalance: 0.0,
          colorHex: 0xFF10B981,
        ),
      ];
      await _db.saveAccounts(accounts);
    }

    await _processPendingSms();

    _isInitialized = true;
    notifyListeners();
  }

  Future<void> _processPendingSms() async {
    final pendingMessages = await SmsCaptureService.readPendingMessages();
    if (pendingMessages.isEmpty || accounts.isEmpty || categories.isEmpty) {
      return;
    }

    final acknowledgedIds = <String>[];
    var addedReviewItem = false;

    for (final message in pendingMessages) {
      final reviewId = 'rq_${message.id}';

      if (reviewQueue.any((rq) => rq.id == reviewId)) {
        acknowledgedIds.add(message.id);
        continue;
      }
      if (transactions.any((tx) => tx.id == 'sms_${message.id}')) {
        acknowledgedIds.add(message.id);
        continue;
      }

      final parsed = SmsParserService.parseSms(message.body);
      if (!parsed.isTransaction || parsed.amount <= 0) continue;

      final category = _categoryForSms(parsed);
      final account = _accountForSms(parsed);
      if (category == null || account == null) continue;

      final accountMatched = _didSmsAccountMatch(parsed, account);
      var sourceText = message.body;
      if (!accountMatched) {
        sourceText +=
            ' [⚠️ Bank name did not match any account, used: ${account.name} — please verify]';
      }
      final likelyDuplicate =
          SmsParserService.isLikelyDuplicate(
            parsed,
            transactions,
            receivedAt: message.receivedAt,
          ) ||
          reviewQueue.any(
            (queued) =>
                (queued.amount - parsed.amount).abs() < 1 &&
                queued.date.year == message.receivedAt.year &&
                queued.date.month == message.receivedAt.month &&
                queued.date.day == message.receivedAt.day &&
                (queued.merchant.toLowerCase().contains(
                      parsed.merchant.toLowerCase(),
                    ) ||
                    parsed.merchant.toLowerCase().contains(
                      queued.merchant.toLowerCase(),
                    )),
          );
      if (likelyDuplicate) {
        sourceText +=
            ' [Possible duplicate: matching amount, merchant, and date]';
      }

      final txType = parsed.isDebit
          ? TransactionType.expense
          : TransactionType.income;
      final merchantText = parsed.merchant.isEmpty
          ? (parsed.isDebit ? 'Unnamed Merchant' : 'Income (SMS)')
          : parsed.merchant;

      var effectiveCategory = category;
      if (!parsed.isDebit) {
        final incomeCats = categories
            .where((c) => c.type.name.toLowerCase() == 'income')
            .toList();
        if (incomeCats.isEmpty) {
          incomeCats.addAll(
            categories
                .where(
                  (c) => c.type.toString().toLowerCase().contains('income'),
                )
                .toList(),
          );
        }
        if (incomeCats.isEmpty) {
          incomeCats.addAll(
            categories.where((c) => c.type == CategoryType.income).toList(),
          );
        }
        if (incomeCats.isNotEmpty) {
          effectiveCategory = incomeCats.first;
        }
      }

      reviewQueue.add(
        ReviewQueueItem(
          id: reviewId,
          merchant: merchantText,
          amount: parsed.amount,
          date: message.receivedAt,
          suggestedCategoryId: effectiveCategory.id,
          suggestedCategoryName: effectiveCategory.name,
          suggestedAccountId: account.id,
          suggestedAccountName: account.name,
          sourceNotification: sourceText,
          suggestedType: txType,
        ),
      );
      acknowledgedIds.add(message.id);
      addedReviewItem = true;
    }

    if (addedReviewItem) {
      await _db.saveReviewQueue(reviewQueue);
    }
    await SmsCaptureService.acknowledgeMessages(acknowledgedIds);
    if (addedReviewItem) notifyListeners();
  }

  bool _didSmsAccountMatch(ParsedSmsResult parsed, Account account) {
    final suggestion = parsed.accountRef.toLowerCase().trim();
    final accName = account.name.toLowerCase().trim();
    if (suggestion.isEmpty) return accounts.length == 1;
    if (accName.contains(suggestion) || suggestion.contains(accName)) {
      return true;
    }
    final isOnlyAccount =
        accounts.indexOf(account) == 0 && accounts.length == 1;
    if (isOnlyAccount) return true;
    return false;
  }

  Future<void> processPendingSms() async {
    if (!_isInitialized) return;
    await _processPendingSms();
  }

  Category? _categoryForSms(ParsedSmsResult parsed) {
    final expectedType = parsed.isDebit
        ? CategoryType.expense
        : CategoryType.income;
    final suggestion = parsed.categorySuggestion.toLowerCase();

    for (final category in categories) {
      if (category.type == expectedType &&
          (category.name.toLowerCase().contains(suggestion) ||
              suggestion.contains(category.name.toLowerCase()))) {
        return category;
      }
    }

    for (final category in categories) {
      if (category.type == expectedType) return category;
    }
    return categories.isNotEmpty ? categories.first : null;
  }

  Account? _accountForSms(ParsedSmsResult parsed) {
    final accountSuggestion = parsed.accountRef.toLowerCase();
    final suffixMatch = RegExp(
      r'(?:x{2,}|\*{2,}|ending\s*)(\d{3,4})',
      caseSensitive: false,
    ).firstMatch(parsed.rawSms);
    final smsSuffix = suffixMatch?.group(1);
    for (final account in accounts) {
      final accountName = account.name.toLowerCase();
      if (smsSuffix != null && account.accountNumber == smsSuffix) {
        return account;
      }
      if (accountSuggestion.contains(accountName) ||
          accountName.contains(accountSuggestion)) {
        return account;
      }
    }
    return accounts.isNotEmpty ? accounts.first : null;
  }

  void setPeriod(TimePeriod period, {DateTimeRange? customRange}) {
    selectedPeriod = period;
    customDateRange = customRange;
    notifyListeners();
  }

  void toggleDarkMode() {
    profile.isDarkMode = !profile.isDarkMode;
    _db.saveProfile(profile);
    notifyListeners();
  }

  void togglePrivacyMode() {
    profile.isPrivacyModeEnabled = !profile.isPrivacyModeEnabled;
    _db.saveProfile(profile);
    notifyListeners();
  }

  void toggleHideBalances() {
    profile.hideBalances = !profile.hideBalances;
    _db.saveProfile(profile);
    notifyListeners();
  }

  void updateProfileName(String name) {
    profile.name = name;
    _db.saveProfile(profile);
    notifyListeners();
  }

  Future<void> updateMonthlyIncomeGoal(double amount) async {
    if (!amount.isFinite || amount < 0) return;
    profile.monthlyIncomeGoal = amount;
    await _db.saveProfile(profile);
    notifyListeners();
  }

  Future<void> completeOnboarding({
    required String name,
    required String currencySymbol,
    required double monthlyIncomeGoal,
  }) async {
    profile.name = name;
    profile.currencySymbol = currencySymbol;
    CurrencyFormatter.defaultSymbol = currencySymbol;
    profile.monthlyIncomeGoal = monthlyIncomeGoal;
    profile.isOnboarded = true;
    profile.onboardingVersion = 1;
    await _db.saveProfile(profile);
    notifyListeners();
  }

  void updateCurrencySymbol(String symbol) {
    profile.currencySymbol = symbol;
    CurrencyFormatter.defaultSymbol = symbol;
    _db.saveProfile(profile);
    notifyListeners();
  }

  void updateHomeSectionOrder(List<String> order) {
    profile.homeSectionOrder = order;
    _db.saveProfile(profile);
    notifyListeners();
  }

  void notifyStateChanged() {
    notifyListeners();
  }

  // DELEGATED FINANCIAL CALCULATIONS
  double get thisMonthIncome => FinancialCalculator.thisMonthIncome(transactions);

  double get thisMonthExpense => FinancialCalculator.thisMonthExpense(transactions);

  List<Budget> get activeMonthlyBudgets => budgets
      .where(
        (budget) => budget.isActive && budget.period == BudgetPeriod.monthly,
      )
      .toList();

  double get monthlyBudgetLimit => activeMonthlyBudgets.fold(
    0.0,
    (total, budget) => total + budget.limitAmount,
  );

  Map<String, double> get monthlyBudgetSpendingByCategory =>
      FinancialCalculator.monthlyBudgetSpendingByCategory(
        activeMonthlyBudgets: activeMonthlyBudgets,
        transactions: transactions,
      );

  double get monthlyBudgetedSpent => monthlyBudgetSpendingByCategory.values
      .fold(0.0, (total, amount) => total + amount);

  double get totalAvailableMoney => FinancialCalculator.totalAvailableMoney(accounts);

  double get creditCardOutstanding => FinancialCalculator.creditCardOutstanding(accounts);

  List<TransactionItem> get filteredTransactions =>
      FinancialCalculator.filterTransactions(
        transactions: transactions,
        selectedPeriod: selectedPeriod,
        customDateRange: customDateRange,
      );

  double get periodIncome => FinancialCalculator.periodIncome(filteredTransactions);

  double get periodSpent => FinancialCalculator.periodSpent(filteredTransactions);

  double get periodRemaining => periodIncome - periodSpent;

  double get priorMonthIncome {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month, 1);
    final start = DateTime(now.year, now.month - 1, 1);
    final priorTxs = transactions.where((t) => t.date.isAfter(start.subtract(const Duration(seconds: 1))) && t.date.isBefore(currentMonth));
    return FinancialCalculator.periodIncome(priorTxs.toList());
  }

  double get priorMonthSpent {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month, 1);
    final start = DateTime(now.year, now.month - 1, 1);
    final priorTxs = transactions.where((t) => t.date.isAfter(start.subtract(const Duration(seconds: 1))) && t.date.isBefore(currentMonth));
    return FinancialCalculator.periodSpent(priorTxs.toList());
  }

  double get upcomingBillsTotal => FinancialCalculator.upcomingBillsTotal(recurringBills);

  double get plannedSavingsTotal => FinancialCalculator.plannedSavingsTotal(goals);

  double get availableToSpend => FinancialCalculator.availableToSpend(
    totalAvailableMoney: totalAvailableMoney,
    upcomingBillsTotal: upcomingBillsTotal,
    plannedSavingsTotal: plannedSavingsTotal,
  );

  List<String> get financialAlerts => FinancialCalculator.financialAlerts(
    reviewQueue: reviewQueue,
    recurringBills: recurringBills,
    budgets: budgets,
    categorySpendingMap: categorySpending,
    accounts: accounts,
  );

  Map<String, double> get categorySpending => FinancialCalculator.categorySpending(filteredTransactions);

  // ADD TRANSACTION
  Future<void> addTransaction(TransactionItem t) async {
    transactions.add(t);
    _applyTransactionToAccount(t);
    await _saveAll();
    await _db.auditService.logTransactionCreated(
      id: t.id,
      type: t.type.name.toUpperCase(),
      amount: t.amount,
      categoryName: t.categoryName,
      merchant: t.merchant,
      accountName: t.accountName,
    );
    notifyListeners();
  }

  Future<void> updateTransaction(TransactionItem updated) async {
    final idx = transactions.indexWhere((t) => t.id == updated.id);
    if (idx != -1) {
      final old = transactions[idx];
      _revertTransactionFromAccount(old);

      transactions[idx] = updated;
      _applyTransactionToAccount(updated);

      await _saveAll();
      final oldValueDiff = 'Amount: ₹${old.amount.toStringAsFixed(2)}\nCategory: ${old.categoryName}\nMerchant: ${old.merchant}\nAccount: ${old.accountName}';
      final newValueDiff = 'Amount: ₹${updated.amount.toStringAsFixed(2)}\nCategory: ${updated.categoryName}\nMerchant: ${updated.merchant}\nAccount: ${updated.accountName}';
      await _db.auditService.logTransactionUpdated(
        id: updated.id,
        title: updated.merchant,
        oldValueDiff: oldValueDiff,
        newValueDiff: newValueDiff,
      );
      notifyListeners();
    }
  }

  Future<void> deleteTransaction(String id) async {
    final idx = transactions.indexWhere((t) => t.id == id);
    if (idx != -1) {
      final old = transactions[idx];
      _revertTransactionFromAccount(old);
      transactions.removeAt(idx);
      await _saveAll();
      await _db.auditService.logTransactionDeleted(
        id: old.id,
        title: old.merchant,
        summary: '₹${old.amount.toStringAsFixed(2)} (${old.categoryName} via ${old.accountName})',
      );
      notifyListeners();
    }
  }

  Future<void> restoreDeletedTransaction(TransactionItem transaction) async {
    if (transactions.any((item) => item.id == transaction.id)) return;
    transactions.add(transaction);
    _applyTransactionToAccount(transaction);
    await _saveAll();
    await _db.auditService.logTransactionRestored(
      id: transaction.id,
      title: transaction.merchant,
    );
    notifyListeners();
  }

  void _applyTransactionToAccount(TransactionItem t) {
    final accIdx = accounts.indexWhere((a) => a.id == t.accountId);
    if (accIdx != -1) {
      final acc = accounts[accIdx];
      if (t.type == TransactionType.expense) {
        if (acc.type == AccountType.creditCard) {
          acc.balance += t.amount;
        } else {
          acc.balance -= t.amount;
        }
      } else if (t.type == TransactionType.income ||
          t.type == TransactionType.refund) {
        if (acc.type == AccountType.creditCard) {
          acc.balance -= t.amount;
        } else {
          acc.balance += t.amount;
        }
      } else if (t.type == TransactionType.transfer && t.toAccountId != null) {
        acc.balance -= t.amount;
        final toAccIdx = accounts.indexWhere((a) => a.id == t.toAccountId);
        if (toAccIdx != -1) {
          final toAcc = accounts[toAccIdx];
          if (toAcc.type == AccountType.creditCard) {
            toAcc.balance -= t.amount;
          } else {
            toAcc.balance += t.amount;
          }
        }
      }
    }
  }

  void _revertTransactionFromAccount(TransactionItem t) {
    final accIdx = accounts.indexWhere((a) => a.id == t.accountId);
    if (accIdx != -1) {
      final acc = accounts[accIdx];
      if (t.type == TransactionType.expense) {
        if (acc.type == AccountType.creditCard) {
          acc.balance -= t.amount;
        } else {
          acc.balance += t.amount;
        }
      } else if (t.type == TransactionType.income ||
          t.type == TransactionType.refund) {
        if (acc.type == AccountType.creditCard) {
          acc.balance += t.amount;
        } else {
          acc.balance -= t.amount;
        }
      } else if (t.type == TransactionType.transfer && t.toAccountId != null) {
        acc.balance += t.amount;
        final toAccIdx = accounts.indexWhere((a) => a.id == t.toAccountId);
        if (toAccIdx != -1) {
          final toAcc = accounts[toAccIdx];
          if (toAcc.type == AccountType.creditCard) {
            toAcc.balance += t.amount;
          } else {
            toAcc.balance -= t.amount;
          }
        }
      }
    }
  }

  // REVIEW QUEUE ACTIONS
  Future<void> approveReviewQueueItem(ReviewQueueItem item) async {
    final type = item.suggestedType;
    final t = TransactionItem(
      id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
      type: type,
      amount: item.amount,
      categoryId: item.suggestedCategoryId,
      categoryName: item.suggestedCategoryName,
      accountId: item.suggestedAccountId,
      accountName: item.suggestedAccountName,
      merchant: item.merchant,
      note: type == TransactionType.transfer
          ? 'Transfer (from SMS review)'
          : 'Auto-captured from SMS notification',
      date: item.date,
      source: 'autoCaptured',
      isReviewed: true,
    );
    await addTransaction(t);
    reviewQueue.removeWhere((q) => q.id == item.id);
    await _db.saveReviewQueue(reviewQueue);
    notifyListeners();
  }

  Future<void> dismissReviewQueueItem(String id) async {
    reviewQueue.removeWhere((q) => q.id == id);
    await _db.saveReviewQueue(reviewQueue);
    notifyListeners();
  }

  Future<void> updateReviewQueueItem(ReviewQueueItem item) async {
    final idx = reviewQueue.indexWhere((q) => q.id == item.id);
    if (idx != -1) {
      reviewQueue[idx] = item;
      await _db.saveReviewQueue(reviewQueue);
    }
  }

  // GOALS ACTION
  Future<void> addMoneyToGoal(String goalId, double amount) async {
    final idx = goals.indexWhere((g) => g.id == goalId);
    if (idx != -1) {
      goals[idx].currentAmount += amount;
      if (goals[idx].currentAmount >= goals[idx].targetAmount) {
        goals[idx].isCompleted = true;
      }
      await _db.saveGoals(goals);
      notifyListeners();
    }
  }

  // RECURRING BILL ACTION
  Future<void> markBillPaid(String billId) async {
    final idx = recurringBills.indexWhere((b) => b.id == billId);
    if (idx != -1) {
      final bill = recurringBills[idx];
      if (bill.isPaused || bill.isCompleted) return;
      final t = TransactionItem(
        id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
        type: bill.type == RecurringType.income
            ? TransactionType.income
            : TransactionType.expense,
        amount: bill.amount,
        categoryId: bill.categoryId,
        categoryName: bill.categoryName,
        accountId: bill.accountId,
        accountName: bill.accountName,
        merchant: bill.title,
        note: bill.type == RecurringType.income
            ? 'Scheduled recurring income'
            : 'Recurring ${bill.type == RecurringType.subscription
                  ? 'subscription'
                  : bill.type == RecurringType.emi
                  ? 'EMI'
                  : 'bill'} payment',
        date: DateTime.now(),
        isRecurring: true,
      );
      transactions.add(t);
      _applyTransactionToAccount(t);

      if (bill.type == RecurringType.emi &&
          bill.installmentsRemaining != null) {
        bill.installmentsRemaining = (bill.installmentsRemaining! - 1)
            .clamp(0, 1000000)
            .toInt();
        if (bill.installmentsRemaining == 0) {
          bill.isCompleted = true;
        }
      }
      bill.nextDueDate = _nextRecurringDate(bill);
      bill.isPaid = false;

      await _saveAll();
      notifyListeners();
    }
  }

  DateTime _nextRecurringDate(RecurringBill bill) {
    final now = DateTime.now();
    final fallbackDay = bill.dueDay
        .clamp(1, DateTime(now.year, now.month + 1, 0).day)
        .toInt();
    final current =
        bill.nextDueDate ?? DateTime(now.year, now.month, fallbackDay);
    switch (bill.billingCycle) {
      case BillingCycle.weekly:
        return current.add(const Duration(days: 7));
      case BillingCycle.monthly:
        final nextMonth = DateTime(current.year, current.month + 1, 1);
        final day = bill.dueDay
            .clamp(1, DateTime(nextMonth.year, nextMonth.month + 1, 0).day)
            .toInt();
        return DateTime(nextMonth.year, nextMonth.month, day);
      case BillingCycle.yearly:
        final nextYearDay = bill.dueDay
            .clamp(1, DateTime(current.year + 1, current.month + 1, 0).day)
            .toInt();
        return DateTime(current.year + 1, current.month, nextYearDay);
    }
  }

  // SAVE ALL
  Future<void> _saveAll() async {
    await _db.saveProfile(profile);
    await _db.saveAccounts(accounts);
    await _db.saveCategories(categories);
    await _db.saveTransactions(transactions);
    await _db.saveBudgets(budgets);
    await _db.saveGoals(goals);
    await _db.saveRecurringBills(recurringBills);
    await _db.saveSharedExpenses(sharedExpenses);
    await _db.saveReviewQueue(reviewQueue);
  }

  void _seedDefaultCategories() {
    categories = [
      Category(
        id: 'cat_food',
        name: 'Food & Dining',
        type: CategoryType.expense,
        iconCode: 0xe56c,
        colorHex: 0xFFF59E0B,
        subcategories: ['Restaurants', 'Delivery', 'Coffee', 'Snacks'],
      ),
      Category(
        id: 'cat_groceries',
        name: 'Groceries',
        type: CategoryType.expense,
        iconCode: 0xe59c,
        colorHex: 0xFF10B981,
        subcategories: ['Supermarket', 'Vegetables', 'Milk'],
      ),
      Category(
        id: 'cat_transport',
        name: 'Transport',
        type: CategoryType.expense,
        iconCode: 0xe1d5,
        colorHex: 0xFF3B82F6,
        subcategories: ['Uber/Ola', 'Auto', 'Metro', 'Parking'],
      ),
      Category(
        id: 'cat_shopping',
        name: 'Shopping',
        type: CategoryType.expense,
        iconCode: 0xe59c,
        colorHex: 0xFFEC4899,
        subcategories: ['Clothing', 'Electronics', 'Online'],
      ),
      Category(
        id: 'cat_bills',
        name: 'Bills & Utilities',
        type: CategoryType.expense,
        iconCode: 0xe0be,
        colorHex: 0xFF8B5CF6,
        subcategories: ['Electricity', 'Internet', 'Water', 'Gas'],
      ),
      Category(
        id: 'cat_sub',
        name: 'Subscriptions',
        type: CategoryType.expense,
        iconCode: 0xe038,
        colorHex: 0xFF06B6D4,
        subcategories: ['OTT', 'Music', 'Software'],
      ),
      Category(
        id: 'cat_rent',
        name: 'Rent',
        type: CategoryType.expense,
        iconCode: 0xe318,
        colorHex: 0xFF6366F1,
        subcategories: ['House Rent', 'Maintenance'],
      ),
      Category(
        id: 'cat_fuel',
        name: 'Fuel',
        type: CategoryType.expense,
        iconCode: 0xe57e,
        colorHex: 0xFFEF4444,
        subcategories: ['Petrol', 'Diesel'],
      ),
      Category(
        id: 'cat_travel',
        name: 'Travel',
        type: CategoryType.expense,
        iconCode: 0xe0cd,
        colorHex: 0xFF0D9488,
        subcategories: ['Flights', 'Hotels', 'Sightseeing'],
      ),
      Category(
        id: 'cat_health',
        name: 'Health',
        type: CategoryType.expense,
        iconCode: 0xe3f3,
        colorHex: 0xFF14B8A6,
        subcategories: ['Medicine', 'Doctor', 'Lab Tests'],
      ),
      Category(
        id: 'cat_salary',
        name: 'Salary',
        type: CategoryType.income,
        iconCode: 0xe227,
        colorHex: 0xFF10B981,
      ),
      Category(
        id: 'cat_freelance',
        name: 'Freelance',
        type: CategoryType.income,
        iconCode: 0xe8f9,
        colorHex: 0xFF3B82F6,
      ),
      Category(
        id: 'cat_refund',
        name: 'Refund',
        type: CategoryType.income,
        iconCode: 0xe043,
        colorHex: 0xFF8B5CF6,
      ),
      Category(
        id: 'cat_opening',
        name: 'Opening Balance',
        type: CategoryType.income,
        iconCode: 0xe0bf,
        colorHex: 0xFF6366F1,
      ),
    ];
  }

  // ACCOUNT CRUD
  Future<void> addAccount(Account account) async {
    accounts.add(account);
    await _db.saveAccounts(accounts);
    notifyListeners();
  }

  Future<void> updateAccount(Account updated) async {
    final idx = accounts.indexWhere((a) => a.id == updated.id);
    if (idx != -1) {
      accounts[idx] = updated;
      await _db.saveAccounts(accounts);
      notifyListeners();
    }
  }

  Future<void> reconcileAccount(String accountId, double actualBalance) async {
    final idx = accounts.indexWhere((account) => account.id == accountId);
    if (idx == -1 || !actualBalance.isFinite || actualBalance < 0) return;
    final account = accounts[idx];
    account.balance = actualBalance;
    account.lastReconciledBalance = actualBalance;
    account.lastReconciledAt = DateTime.now();
    await _db.saveAccounts(accounts);
    notifyListeners();
  }

  String exportBackupJson() => const JsonEncoder.withIndent('  ').convert({
    'schemaVersion': 1,
    'exportedAt': DateTime.now().toIso8601String(),
    'profile': profile.toJson(),
    'accounts': accounts.map((item) => item.toJson()).toList(),
    'categories': categories.map((item) => item.toJson()).toList(),
    'transactions': transactions.map((item) => item.toJson()).toList(),
    'budgets': budgets.map((item) => item.toJson()).toList(),
    'goals': goals.map((item) => item.toJson()).toList(),
    'recurringBills': recurringBills.map((item) => item.toJson()).toList(),
    'sharedExpenses': sharedExpenses.map((item) => item.toJson()).toList(),
    'reviewQueue': reviewQueue.map((item) => item.toJson()).toList(),
    'customTags': customTags,
  });

  Future<void> restoreBackupJson(String contents) async {
    final decoded = jsonDecode(contents);
    if (decoded is! Map<String, dynamic> || decoded['schemaVersion'] != 1) {
      throw const FormatException('This backup version is not supported.');
    }
    List<T> decodeList<T>(
      String key,
      T Function(Map<String, dynamic>) fromJson,
    ) {
      final raw = decoded[key];
      if (raw is! List) throw FormatException('Backup is missing $key.');
      return raw.map((item) {
        if (item is! Map<String, dynamic>) {
          throw FormatException('Invalid item in $key.');
        }
        return fromJson(item);
      }).toList();
    }

    final restoredProfile = UserProfile.fromJson(
      Map<String, dynamic>.from(decoded['profile'] as Map),
    );
    final restoredAccounts = decodeList('accounts', Account.fromJson);
    final restoredCategories = decodeList('categories', Category.fromJson);
    final restoredTransactions = decodeList(
      'transactions',
      TransactionItem.fromJson,
    );
    final restoredBudgets = decodeList('budgets', Budget.fromJson);
    final restoredGoals = decodeList('goals', Goal.fromJson);
    final restoredRecurring = decodeList(
      'recurringBills',
      RecurringBill.fromJson,
    );
    final restoredShared = decodeList('sharedExpenses', SharedExpense.fromJson);
    final restoredQueue = decodeList('reviewQueue', ReviewQueueItem.fromJson);
    final restoredTags = List<String>.from(decoded['customTags'] as List);

    profile = restoredProfile;
    CurrencyFormatter.defaultSymbol = profile.currencySymbol;
    accounts = restoredAccounts;
    categories = restoredCategories;
    transactions = restoredTransactions;
    budgets = restoredBudgets;
    goals = restoredGoals;
    recurringBills = restoredRecurring;
    sharedExpenses = restoredShared;
    reviewQueue = restoredQueue;
    customTags = restoredTags;
    await _saveAll();
    await _db.saveTags(customTags);
    notifyListeners();
  }

  String exportTransactionsCsv() {
    final rows = <List<String>>[
      CsvDataService.transactionHeaders,
      ...transactions.map(
        (transaction) => [
          transaction.date.toIso8601String(),
          transaction.type.name,
          transaction.amount.toStringAsFixed(2),
          transaction.categoryName,
          transaction.accountName,
          transaction.toAccountName ?? '',
          transaction.merchant,
          transaction.note,
          transaction.tags.join('|'),
        ],
      ),
    ];
    return CsvDataService.encode(rows);
  }

  Future<({int imported, int skipped})> importTransactionsCsv(
    String contents,
  ) async {
    final rows = CsvDataService.decode(contents);
    if (rows.isEmpty) throw const FormatException('CSV file is empty.');
    final headers = rows.first
        .map((item) => item.trim().toLowerCase())
        .toList();
    for (final requiredHeader in CsvDataService.transactionHeaders) {
      if (!headers.contains(requiredHeader)) {
        throw FormatException('CSV is missing the "$requiredHeader" column.');
      }
    }
    final indexes = {for (var i = 0; i < headers.length; i++) headers[i]: i};
    var imported = 0;
    var skipped = 0;
    for (final row in rows.skip(1)) {
      try {
        String value(String key) =>
            row.length > indexes[key]! ? row[indexes[key]!].trim() : '';
        final date = DateTime.parse(value('date'));
        final type = TransactionType.values.byName(value('type'));
        final amount = double.parse(value('amount'));
        if (amount <= 0 || !amount.isFinite) {
          skipped++;
          continue;
        }
        final account = accounts.firstWhere(
          (item) => item.name.toLowerCase() == value('account').toLowerCase(),
        );
        final category = categories.firstWhere(
          (item) => item.name.toLowerCase() == value('category').toLowerCase(),
        );
        Account? toAccount;
        if (type == TransactionType.transfer) {
          toAccount = accounts.firstWhere(
            (item) =>
                item.name.toLowerCase() == value('to_account').toLowerCase(),
          );
          if (account.id == toAccount.id) {
            skipped++;
            continue;
          }
        }
        final merchant = value('merchant');
        final isDuplicate = transactions.any(
          (existing) =>
              existing.type == type &&
              existing.accountId == account.id &&
              existing.toAccountId == toAccount?.id &&
              (existing.amount - amount).abs() < 0.01 &&
              existing.merchant.trim().toLowerCase() ==
                  merchant.toLowerCase() &&
              existing.date.year == date.year &&
              existing.date.month == date.month &&
              existing.date.day == date.day,
        );
        if (isDuplicate) {
          skipped++;
          continue;
        }
        final transaction = TransactionItem(
          id: 'csv_${DateTime.now().microsecondsSinceEpoch}_$imported',
          type: type,
          amount: amount,
          categoryId: category.id,
          categoryName: category.name,
          accountId: account.id,
          accountName: account.name,
          toAccountId: toAccount?.id,
          toAccountName: toAccount?.name,
          merchant: merchant,
          note: value('note'),
          date: date,
          tags: value('tags').isEmpty ? [] : value('tags').split('|'),
        );
        transactions.add(transaction);
        _applyTransactionToAccount(transaction);
        imported++;
      } on Object {
        skipped++;
      }
    }
    await _saveAll();
    notifyListeners();
    return (imported: imported, skipped: skipped);
  }

  Future<void> deleteAccount(String id) async {
    accounts.removeWhere((a) => a.id == id);
    await _db.saveAccounts(accounts);
    notifyListeners();
  }

  // CATEGORY CRUD
  Future<void> addCategory(Category category) async {
    categories.add(category);
    await _db.saveCategories(categories);
    notifyListeners();
  }

  Future<void> updateCategory(Category updated) async {
    final idx = categories.indexWhere((c) => c.id == updated.id);
    if (idx != -1) {
      categories[idx] = updated;
      await _db.saveCategories(categories);
      notifyListeners();
    }
  }

  Future<void> deleteCategory(String id) async {
    categories.removeWhere((c) => c.id == id);
    await _db.saveCategories(categories);
    notifyListeners();
  }

  // BUDGET CRUD
  Future<void> addBudget(Budget budget) async {
    budgets.add(budget);
    await _db.saveBudgets(budgets);
    notifyListeners();
  }

  Future<void> updateBudget(Budget updated) async {
    final idx = budgets.indexWhere((b) => b.id == updated.id);
    if (idx != -1) {
      budgets[idx] = updated;
      await _db.saveBudgets(budgets);
      notifyListeners();
    }
  }

  Future<void> deleteBudget(String id) async {
    budgets.removeWhere((b) => b.id == id);
    await _db.saveBudgets(budgets);
    notifyListeners();
  }

  // GOAL CRUD
  Future<void> addGoal(Goal goal) async {
    goals.add(goal);
    await _db.saveGoals(goals);
    notifyListeners();
  }

  Future<void> updateGoal(Goal updated) async {
    final idx = goals.indexWhere((g) => g.id == updated.id);
    if (idx != -1) {
      goals[idx] = updated;
      await _db.saveGoals(goals);
      notifyListeners();
    }
  }

  Future<void> deleteGoal(String id) async {
    goals.removeWhere((g) => g.id == id);
    await _db.saveGoals(goals);
    notifyListeners();
  }

  // RECURRING BILL CRUD
  Future<void> addRecurringBill(RecurringBill bill) async {
    recurringBills.add(bill);
    await _db.saveRecurringBills(recurringBills);
    notifyListeners();
  }

  Future<void> updateRecurringBill(RecurringBill updated) async {
    final idx = recurringBills.indexWhere((b) => b.id == updated.id);
    if (idx != -1) {
      recurringBills[idx] = updated;
      await _db.saveRecurringBills(recurringBills);
      notifyListeners();
    }
  }

  Future<void> deleteRecurringBill(String id) async {
    recurringBills.removeWhere((b) => b.id == id);
    await _db.saveRecurringBills(recurringBills);
    notifyListeners();
  }

  Future<void> toggleBillPaused(String billId) async {
    final idx = recurringBills.indexWhere((b) => b.id == billId);
    if (idx != -1) {
      recurringBills[idx].isPaused = !recurringBills[idx].isPaused;
      await _db.saveRecurringBills(recurringBills);
      notifyListeners();
    }
  }

  // SHARED EXPENSE CRUD
  Future<void> addSharedExpense(SharedExpense expense) async {
    sharedExpenses.add(expense);
    await _db.saveSharedExpenses(sharedExpenses);
    notifyListeners();
  }

  Future<void> updateSharedExpense(SharedExpense expense) async {
    final idx = sharedExpenses.indexWhere((item) => item.id == expense.id);
    if (idx == -1) return;
    sharedExpenses[idx] = expense;
    await _db.saveSharedExpenses(sharedExpenses);
    notifyListeners();
  }

  Future<void> deleteSharedExpense(String id) async {
    sharedExpenses.removeWhere((e) => e.id == id);
    await _db.saveSharedExpenses(sharedExpenses);
    notifyListeners();
  }

  // TAGS MANAGEMENT (CRUD)
  List<String> get allAvailableTags {
    final tagSet = <String>{};
    tagSet.addAll(customTags);
    for (final t in transactions) {
      tagSet.addAll(t.tags);
    }
    final sorted = tagSet.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return sorted;
  }

  List<String> get allTags => allAvailableTags;

  int getTagUsageCount(String tag) {
    return transactions.where((t) => t.tags.contains(tag)).length;
  }

  Future<void> addTag(String tag) async {
    final trimmed = tag.trim();
    if (trimmed.isEmpty) return;
    if (!customTags.any((t) => t.toLowerCase() == trimmed.toLowerCase())) {
      customTags.add(trimmed);
      await _db.saveTags(customTags);
      notifyListeners();
    }
  }

  Future<void> removeTag(String tag) async {
    customTags.removeWhere((t) => t.toLowerCase() == tag.toLowerCase());
    for (var i = 0; i < transactions.length; i++) {
      if (transactions[i].tags.contains(tag)) {
        final updatedTags = List<String>.from(transactions[i].tags)
          ..remove(tag);
        transactions[i] = transactions[i].copyWith(tags: updatedTags);
      }
    }
    await _db.saveTags(customTags);
    await _db.saveTransactions(transactions);
    notifyListeners();
  }

  Future<void> renameTag(String oldTag, String newTag) async {
    final trimmed = newTag.trim();
    if (trimmed.isEmpty || oldTag == trimmed) return;

    final idx = customTags.indexWhere(
      (t) => t.toLowerCase() == oldTag.toLowerCase(),
    );
    if (idx != -1) {
      customTags[idx] = trimmed;
    } else {
      customTags.add(trimmed);
    }

    for (var i = 0; i < transactions.length; i++) {
      if (transactions[i].tags.contains(oldTag)) {
        final updatedTags = transactions[i].tags
            .map((t) => t == oldTag ? trimmed : t)
            .toList();
        transactions[i] = transactions[i].copyWith(tags: updatedTags);
      }
    }

    await _db.saveTags(customTags);
    await _db.saveTransactions(transactions);
    notifyListeners();
  }

  Future<void> clearAllData() async {
    accounts.clear();
    transactions.clear();
    budgets.clear();
    goals.clear();
    recurringBills.clear();
    sharedExpenses.clear();
    reviewQueue.clear();
    await _saveAll();
    notifyListeners();
  }
}
