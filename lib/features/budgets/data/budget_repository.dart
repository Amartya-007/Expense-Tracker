import 'package:expensetracker/models/budget.dart';
import 'package:expensetracker/core/database/app_database.dart';

class BudgetRepository {
  final AppDatabase db;

  BudgetRepository(this.db);

  static const _selectColumns = '''
    id, category_id, category_name, limit_amount, period, is_active
  ''';

  Future<List<Budget>> getBudgets() async {
    final rows = db.rawDb.select(
      'SELECT $_selectColumns FROM budgets ORDER BY category_name ASC, id ASC',
    );
    return rows.map(_mapRowToBudget).toList();
  }

  Future<void> replaceBudgets(List<Budget> budgets) async {
    db.rawDb.execute('BEGIN TRANSACTION');
    try {
      db.rawDb.execute('DELETE FROM budgets');
      final stmt = db.rawDb.prepare('''
        INSERT INTO budgets (id, category_id, category_name, limit_amount, period, is_active)
        VALUES (?, ?, ?, ?, ?, ?)
      ''');
      for (final b in budgets) {
        stmt.execute([
          b.id,
          b.categoryId,
          b.categoryName,
          b.limitAmount,
          b.period.name,
          b.isActive ? 1 : 0,
        ]);
      }
      stmt.dispose();
      db.rawDb.execute('COMMIT');
    } catch (_) {
      db.rawDb.execute('ROLLBACK');
      rethrow;
    }
  }

  Future<void> saveBudgets(List<Budget> budgets) => replaceBudgets(budgets);

  Budget _mapRowToBudget(dynamic r) {
    BudgetPeriod period;
    final rawPeriod = r['period'];
    if (rawPeriod is String) {
      period = BudgetPeriod.values.firstWhere(
        (e) => e.name == rawPeriod,
        orElse: () => BudgetPeriod.monthly,
      );
    } else if (rawPeriod is int && rawPeriod >= 0 && rawPeriod < BudgetPeriod.values.length) {
      period = BudgetPeriod.values[rawPeriod];
    } else {
      period = BudgetPeriod.monthly;
    }

    return Budget(
      id: r['id'] as String,
      categoryId: r['category_id'] as String,
      categoryName: r['category_name'] as String,
      limitAmount: (r['limit_amount'] as num).toDouble(),
      period: period,
      isActive: (r['is_active'] as int?) == 1,
    );
  }
}
