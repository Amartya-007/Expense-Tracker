import 'dart:convert';
import 'package:expensetracker/models/shared_expense.dart';
import 'package:expensetracker/core/database/app_database.dart';

class SharedExpenseRepository {
  final AppDatabase db;

  SharedExpenseRepository(this.db);

  static const _selectColumns = '''
    id, title, total_amount, paid_by, participants, splits, settled_status, date
  ''';

  Future<List<SharedExpense>> getSharedExpenses() async {
    final rows = db.rawDb.select(
      'SELECT $_selectColumns FROM shared_expenses ORDER BY date DESC, id DESC',
    );
    return rows.map(_mapRowToSharedExpense).toList();
  }

  Future<void> replaceSharedExpenses(List<SharedExpense> shared) async {
    db.rawDb.execute('BEGIN TRANSACTION');
    try {
      db.rawDb.execute('DELETE FROM shared_expenses');
      final stmt = db.rawDb.prepare('''
        INSERT INTO shared_expenses (
          id, title, total_amount, paid_by, participants, splits, settled_status, date
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      ''');
      for (final s in shared) {
        stmt.execute([
          s.id,
          s.title,
          s.totalAmount,
          s.paidBy,
          jsonEncode(s.participants),
          jsonEncode(s.splits),
          jsonEncode(s.settledStatus),
          s.date.toIso8601String(),
        ]);
      }
      stmt.dispose();
      db.rawDb.execute('COMMIT');
    } catch (_) {
      db.rawDb.execute('ROLLBACK');
      rethrow;
    }
  }

  Future<void> saveSharedExpenses(List<SharedExpense> shared) => replaceSharedExpenses(shared);

  SharedExpense _mapRowToSharedExpense(dynamic r) {
    List<String> part;
    try {
      part = List<String>.from(jsonDecode(r['participants'] as String));
    } catch (_) {
      part = [];
    }

    Map<String, double> sp;
    try {
      sp = Map<String, double>.from(
        (jsonDecode(r['splits'] as String) as Map).map((k, v) => MapEntry(k as String, (v as num).toDouble())),
      );
    } catch (_) {
      sp = {};
    }

    Map<String, bool> st;
    try {
      st = Map<String, bool>.from(jsonDecode(r['settled_status'] as String));
    } catch (_) {
      st = {};
    }

    return SharedExpense(
      id: r['id'] as String,
      title: r['title'] as String,
      totalAmount: (r['total_amount'] as num).toDouble(),
      paidBy: r['paid_by'] as String,
      participants: part,
      splits: sp,
      settledStatus: st,
      date: DateTime.parse(r['date'] as String),
    );
  }
}
