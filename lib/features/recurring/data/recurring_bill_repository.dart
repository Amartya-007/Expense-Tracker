import 'package:expensetracker/models/recurring_bill.dart';
import 'package:expensetracker/core/database/app_database.dart';

class RecurringBillRepository {
  final AppDatabase db;

  RecurringBillRepository(this.db);

  static const _selectColumns = '''
    id, title, amount, type, billing_cycle, due_day, next_due_date,
    installment_total, installments_remaining, category_id, category_name,
    account_id, account_name, is_paid, is_paused, is_completed
  ''';

  Future<List<RecurringBill>> getRecurringBills() async {
    final rows = db.rawDb.select(
      'SELECT $_selectColumns FROM recurring_bills ORDER BY due_day ASC, id ASC',
    );
    return rows.map(_mapRowToBill).toList();
  }

  Future<void> replaceRecurringBills(List<RecurringBill> bills) async {
    db.rawDb.execute('BEGIN TRANSACTION');
    try {
      db.rawDb.execute('DELETE FROM recurring_bills');
      final stmt = db.rawDb.prepare('''
        INSERT INTO recurring_bills (
          id, title, amount, type, billing_cycle, due_day, next_due_date,
          installment_total, installments_remaining, category_id, category_name,
          account_id, account_name, is_paid, is_paused, is_completed
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''');
      for (final b in bills) {
        stmt.execute([
          b.id,
          b.title,
          b.amount,
          b.type.name,
          b.billingCycle.name,
          b.dueDay,
          b.nextDueDate?.toIso8601String(),
          b.installmentTotal,
          b.installmentsRemaining,
          b.categoryId,
          b.categoryName,
          b.accountId,
          b.accountName,
          b.isPaid ? 1 : 0,
          b.isPaused ? 1 : 0,
          b.isCompleted ? 1 : 0,
        ]);
      }
      stmt.dispose();
      db.rawDb.execute('COMMIT');
    } catch (_) {
      db.rawDb.execute('ROLLBACK');
      rethrow;
    }
  }

  Future<void> saveRecurringBills(List<RecurringBill> bills) => replaceRecurringBills(bills);

  RecurringBill _mapRowToBill(dynamic r) {
    RecurringType type;
    final rawType = r['type'];
    if (rawType is String) {
      type = RecurringType.values.firstWhere(
        (e) => e.name == rawType,
        orElse: () => RecurringType.bill,
      );
    } else if (rawType is int && rawType >= 0 && rawType < RecurringType.values.length) {
      type = RecurringType.values[rawType];
    } else {
      type = RecurringType.bill;
    }

    BillingCycle cycle;
    final rawCycle = r['billing_cycle'];
    if (rawCycle is String) {
      cycle = BillingCycle.values.firstWhere(
        (e) => e.name == rawCycle,
        orElse: () => BillingCycle.monthly,
      );
    } else if (rawCycle is int && rawCycle >= 0 && rawCycle < BillingCycle.values.length) {
      cycle = BillingCycle.values[rawCycle];
    } else {
      cycle = BillingCycle.monthly;
    }

    return RecurringBill(
      id: r['id'] as String,
      title: r['title'] as String,
      amount: (r['amount'] as num).toDouble(),
      type: type,
      billingCycle: cycle,
      dueDay: r['due_day'] as int,
      nextDueDate: r['next_due_date'] == null
          ? null
          : DateTime.tryParse(r['next_due_date'] as String),
      installmentTotal: r['installment_total'] as int?,
      installmentsRemaining: r['installments_remaining'] as int?,
      categoryId: r['category_id'] as String,
      categoryName: r['category_name'] as String,
      accountId: r['account_id'] as String,
      accountName: r['account_name'] as String,
      isPaid: (r['is_paid'] as int?) == 1,
      isPaused: (r['is_paused'] as int?) == 1,
      isCompleted: (r['is_completed'] as int?) == 1,
    );
  }
}
