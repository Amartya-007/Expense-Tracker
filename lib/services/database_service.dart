import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:expensetracker/models/account.dart';
import 'package:expensetracker/models/category.dart';
import 'package:expensetracker/models/transaction.dart';
import 'package:expensetracker/models/budget.dart';
import 'package:expensetracker/models/goal.dart';
import 'package:expensetracker/models/recurring_bill.dart';
import 'package:expensetracker/models/shared_expense.dart';
import 'package:expensetracker/models/user_profile.dart';
import 'package:expensetracker/models/review_queue_item.dart';
import 'package:expensetracker/core/database/app_database.dart';
import 'package:expensetracker/features/profile/data/user_profile_repository.dart';
import 'package:expensetracker/features/accounts/data/account_repository.dart';
import 'package:expensetracker/features/categories/data/category_repository.dart';
import 'package:expensetracker/features/transactions/data/transaction_repository.dart';
import 'package:expensetracker/features/budgets/data/budget_repository.dart';
import 'package:expensetracker/features/goals/data/goal_repository.dart';
import 'package:expensetracker/features/recurring/data/recurring_bill_repository.dart';
import 'package:expensetracker/features/shared_expenses/data/shared_expense_repository.dart';
import 'package:expensetracker/features/review_queue/data/review_queue_repository.dart';
import 'package:expensetracker/features/tags/data/tag_repository.dart';

import 'package:expensetracker/features/audit/data/audit_log_repository.dart';
import 'package:expensetracker/services/audit_log_service.dart';

class DatabaseService {
  static const _cleanSlateKey = 'clean_slate_v3_applied';
  static const _openingBalanceMigrationKey = 'opening_balances_separated_v1';
  static const _driftMigratedKey = 'drift_sqlite_migrated_v1';

  final AppDatabase db;
  final SharedPreferences prefs;

  final UserProfileRepository profileRepo;
  final AccountRepository accountRepo;
  final CategoryRepository categoryRepo;
  final TransactionRepository transactionRepo;
  final BudgetRepository budgetRepo;
  final GoalRepository goalRepo;
  final RecurringBillRepository recurringRepo;
  final SharedExpenseRepository sharedRepo;
  final ReviewQueueRepository reviewRepo;
  final TagRepository tagRepo;
  final AuditLogRepository auditRepo;
  final AuditLogService auditService;

  DatabaseService({
    required this.db,
    required this.prefs,
  })  : profileRepo = UserProfileRepository(db),
        accountRepo = AccountRepository(db),
        categoryRepo = CategoryRepository(db),
        transactionRepo = TransactionRepository(db),
        budgetRepo = BudgetRepository(db),
        goalRepo = GoalRepository(db),
        recurringRepo = RecurringBillRepository(db),
        sharedRepo = SharedExpenseRepository(db),
        reviewRepo = ReviewQueueRepository(db),
        tagRepo = TagRepository(db),
        auditRepo = AuditLogRepository(db),
        auditService = AuditLogService(AuditLogRepository(db));

  static Future<DatabaseService> init({AppDatabase? customDb}) async {
    final prefs = await SharedPreferences.getInstance();
    AppDatabase appDb;
    if (customDb != null) {
      appDb = customDb;
    } else {
      try {
        appDb = await AppDatabase.open();
      } catch (_) {
        appDb = AppDatabase.openInMemory();
      }
    }
    final service = DatabaseService(db: appDb, prefs: prefs);

    // One-time legacy SharedPreferences -> Drift SQLite migration
    if (!(prefs.getBool(_driftMigratedKey) ?? false)) {
      await service._migrateLegacySharedPreferencesToDrift();
      await prefs.setBool(_driftMigratedKey, true);
    }

    return service;
  }

  Future<void> _migrateLegacySharedPreferencesToDrift() async {
    // Legacy profile
    final profileStr = prefs.getString('user_profile');
    if (profileStr != null) {
      try {
        final p = UserProfile.fromJson(jsonDecode(profileStr));
        await profileRepo.saveProfile(p);
      } catch (_) {}
    }

    // Legacy accounts
    final accountsStr = prefs.getString('accounts');
    if (accountsStr != null) {
      try {
        final List list = jsonDecode(accountsStr);
        final accs = list.map((e) => Account.fromJson(e)).toList();
        await accountRepo.saveAccounts(accs);
      } catch (_) {}
    }

    // Legacy categories
    final categoriesStr = prefs.getString('categories');
    if (categoriesStr != null) {
      try {
        final List list = jsonDecode(categoriesStr);
        final cats = list.map((e) => Category.fromJson(e)).toList();
        await categoryRepo.saveCategories(cats);
      } catch (_) {}
    }

    // Legacy transactions
    final txStr = prefs.getString('transactions');
    if (txStr != null) {
      try {
        final List list = jsonDecode(txStr);
        final txs = list.map((e) => TransactionItem.fromJson(e)).toList();
        await transactionRepo.saveTransactions(txs);
      } catch (_) {}
    }

    // Legacy budgets
    final budgetsStr = prefs.getString('budgets');
    if (budgetsStr != null) {
      try {
        final List list = jsonDecode(budgetsStr);
        final bs = list.map((e) => Budget.fromJson(e)).toList();
        await budgetRepo.saveBudgets(bs);
      } catch (_) {}
    }

    // Legacy goals
    final goalsStr = prefs.getString('goals');
    if (goalsStr != null) {
      try {
        final List list = jsonDecode(goalsStr);
        final gs = list.map((e) => Goal.fromJson(e)).toList();
        await goalRepo.saveGoals(gs);
      } catch (_) {}
    }

    // Legacy recurring bills
    final recurringStr = prefs.getString('recurring_bills');
    if (recurringStr != null) {
      try {
        final List list = jsonDecode(recurringStr);
        final rs = list.map((e) => RecurringBill.fromJson(e)).toList();
        await recurringRepo.saveRecurringBills(rs);
      } catch (_) {}
    }

    // Legacy shared
    final sharedStr = prefs.getString('shared_expenses');
    if (sharedStr != null) {
      try {
        final List list = jsonDecode(sharedStr);
        final ss = list.map((e) => SharedExpense.fromJson(e)).toList();
        await sharedRepo.saveSharedExpenses(ss);
      } catch (_) {}
    }

    // Legacy review queue
    final reviewStr = prefs.getString('review_queue');
    if (reviewStr != null) {
      try {
        final List list = jsonDecode(reviewStr);
        final rqs = list.map((e) => ReviewQueueItem.fromJson(e)).toList();
        await reviewRepo.saveReviewQueue(rqs);
      } catch (_) {}
    }

    // Legacy tags
    final tagsList = prefs.getStringList('custom_tags');
    if (tagsList != null) {
      await tagRepo.saveTags(tagsList);
    }
  }

  // Profile
  Future<UserProfile> getProfile() => profileRepo.getProfile();
  Future<void> saveProfile(UserProfile profile) => profileRepo.saveProfile(profile);

  // Accounts
  Future<List<Account>> getAccounts() => accountRepo.getAccounts();
  Future<void> saveAccounts(List<Account> accounts) => accountRepo.saveAccounts(accounts);

  // Categories
  Future<List<Category>> getCategories() => categoryRepo.getCategories();
  Future<void> saveCategories(List<Category> categories) => categoryRepo.saveCategories(categories);

  // Transactions
  Future<List<TransactionItem>> getTransactions() => transactionRepo.getTransactions();
  Future<void> saveTransactions(List<TransactionItem> transactions) => transactionRepo.saveTransactions(transactions);

  // Budgets
  Future<List<Budget>> getBudgets() => budgetRepo.getBudgets();
  Future<void> saveBudgets(List<Budget> budgets) => budgetRepo.saveBudgets(budgets);

  // Goals
  Future<List<Goal>> getGoals() => goalRepo.getGoals();
  Future<void> saveGoals(List<Goal> goals) => goalRepo.saveGoals(goals);

  // Recurring
  Future<List<RecurringBill>> getRecurringBills() => recurringRepo.getRecurringBills();
  Future<void> saveRecurringBills(List<RecurringBill> bills) => recurringRepo.saveRecurringBills(bills);

  // Shared Expenses
  Future<List<SharedExpense>> getSharedExpenses() => sharedRepo.getSharedExpenses();
  Future<void> saveSharedExpenses(List<SharedExpense> shared) => sharedRepo.saveSharedExpenses(shared);

  // Review Queue
  Future<List<ReviewQueueItem>> getReviewQueue() => reviewRepo.getReviewQueue();
  Future<void> saveReviewQueue(List<ReviewQueueItem> queue) => reviewRepo.saveReviewQueue(queue);

  // Tags
  Future<List<String>> getTags() => tagRepo.getTags();
  Future<void> saveTags(List<String> tags) => tagRepo.saveTags(tags);

  bool hasMigratedCleanSlate() => prefs.getBool(_cleanSlateKey) ?? false;
  Future<void> setMigratedCleanSlate() async => prefs.setBool(_cleanSlateKey, true);

  bool hasMigratedOpeningBalances() => prefs.getBool(_openingBalanceMigrationKey) ?? false;
  Future<void> setMigratedOpeningBalances() async => prefs.setBool(_openingBalanceMigrationKey, true);

  Future<void> clearAll() async {
    await profileRepo.saveProfile(UserProfile());
    await accountRepo.saveAccounts([]);
    await categoryRepo.saveCategories([]);
    await transactionRepo.saveTransactions([]);
    await budgetRepo.saveBudgets([]);
    await goalRepo.saveGoals([]);
    await recurringRepo.saveRecurringBills([]);
    await sharedRepo.saveSharedExpenses([]);
    await reviewRepo.saveReviewQueue([]);
    await tagRepo.saveTags([]);
    await prefs.clear();
    await prefs.setBool(_driftMigratedKey, true);
  }
}
