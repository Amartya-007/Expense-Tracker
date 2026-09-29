import 'package:expensetracker/models/goal.dart';
import 'package:expensetracker/core/database/app_database.dart';

class GoalRepository {
  final AppDatabase db;

  GoalRepository(this.db);

  static const _selectColumns = '''
    id, name, target_amount, current_amount, target_date, icon_name, note, is_completed
  ''';

  Future<List<Goal>> getGoals() async {
    final rows = db.rawDb.select(
      'SELECT $_selectColumns FROM goals ORDER BY target_date ASC, id ASC',
    );
    return rows.map(_mapRowToGoal).toList();
  }

  Future<void> replaceGoals(List<Goal> goals) async {
    db.rawDb.execute('BEGIN TRANSACTION');
    try {
      db.rawDb.execute('DELETE FROM goals');
      final stmt = db.rawDb.prepare('''
        INSERT INTO goals (id, name, target_amount, current_amount, target_date, icon_name, note, is_completed)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      ''');
      for (final g in goals) {
        stmt.execute([
          g.id,
          g.name,
          g.targetAmount,
          g.currentAmount,
          g.targetDate.toIso8601String(),
          g.iconName,
          g.note,
          g.isCompleted ? 1 : 0,
        ]);
      }
      stmt.dispose();
      db.rawDb.execute('COMMIT');
    } catch (_) {
      db.rawDb.execute('ROLLBACK');
      rethrow;
    }
  }

  Future<void> saveGoals(List<Goal> goals) => replaceGoals(goals);

  Goal _mapRowToGoal(dynamic r) {
    return Goal(
      id: r['id'] as String,
      name: r['name'] as String,
      targetAmount: (r['target_amount'] as num).toDouble(),
      currentAmount: (r['current_amount'] as num?)?.toDouble() ?? 0.0,
      targetDate: DateTime.parse(r['target_date'] as String),
      iconName: (r['icon_name'] as String?) ?? 'savings',
      note: (r['note'] as String?) ?? '',
      isCompleted: (r['is_completed'] as int?) == 1,
    );
  }
}
