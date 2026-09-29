import 'dart:convert';
import 'package:expensetracker/models/transaction.dart';
import 'package:expensetracker/core/database/app_database.dart';

class TransactionRepository {
  final AppDatabase db;

  TransactionRepository(this.db);

  static const _selectColumns = '''
    id, type, amount, category_id, category_name, account_id, account_name,
    to_account_id, to_account_name, merchant, note, date, tags,
    receipt_image_path, location, is_recurring, is_reviewed, source,
    refunded_transaction_id, splits
  ''';

  Future<List<TransactionItem>> getTransactions() async {
    final rows = db.rawDb.select(
      'SELECT $_selectColumns FROM transactions ORDER BY date DESC, id DESC',
    );
    return rows.map(_mapRowToTransaction).toList();
  }

  Future<TransactionItem?> getTransactionById(String id) async {
    final stmt = db.rawDb.prepare(
      'SELECT $_selectColumns FROM transactions WHERE id = ? LIMIT 1',
    );
    final rows = stmt.select([id]);
    stmt.dispose();
    if (rows.isEmpty) return null;
    return _mapRowToTransaction(rows.first);
  }

  Future<void> insertTransaction(TransactionItem tx) async {
    final stmt = db.rawDb.prepare('''
      INSERT INTO transactions (
        id, type, amount, category_id, category_name, account_id, account_name,
        to_account_id, to_account_name, merchant, note, date, tags,
        receipt_image_path, location, is_recurring, is_reviewed, source,
        refunded_transaction_id, splits
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''');
    _executeInsert(stmt, tx);
    stmt.dispose();
  }

  Future<void> updateTransaction(TransactionItem tx) async {
    final stmt = db.rawDb.prepare('''
      UPDATE transactions SET
        type = ?, amount = ?, category_id = ?, category_name = ?,
        account_id = ?, account_name = ?, to_account_id = ?, to_account_name = ?,
        merchant = ?, note = ?, date = ?, tags = ?, receipt_image_path = ?,
        location = ?, is_recurring = ?, is_reviewed = ?, source = ?,
        refunded_transaction_id = ?, splits = ?
      WHERE id = ?
    ''');
    stmt.execute([
      tx.type.name,
      tx.amount,
      tx.categoryId,
      tx.categoryName,
      tx.accountId,
      tx.accountName,
      tx.toAccountId,
      tx.toAccountName,
      tx.merchant,
      tx.note,
      tx.date.toIso8601String(),
      jsonEncode(tx.tags),
      tx.receiptImagePath,
      tx.location,
      tx.isRecurring ? 1 : 0,
      tx.isReviewed ? 1 : 0,
      tx.source,
      tx.refundedTransactionId,
      jsonEncode(tx.splits.map((s) => s.toJson()).toList()),
      tx.id,
    ]);
    stmt.dispose();
  }

  Future<void> deleteTransaction(String id) async {
    final stmt = db.rawDb.prepare('DELETE FROM transactions WHERE id = ?');
    stmt.execute([id]);
    stmt.dispose();
  }

  Future<void> replaceTransactions(List<TransactionItem> transactions) async {
    db.rawDb.execute('BEGIN TRANSACTION');
    try {
      db.rawDb.execute('DELETE FROM transactions');
      final stmt = db.rawDb.prepare('''
        INSERT INTO transactions (
          id, type, amount, category_id, category_name, account_id, account_name,
          to_account_id, to_account_name, merchant, note, date, tags,
          receipt_image_path, location, is_recurring, is_reviewed, source,
          refunded_transaction_id, splits
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''');
      for (final tx in transactions) {
        _executeInsert(stmt, tx);
      }
      stmt.dispose();
      db.rawDb.execute('COMMIT');
    } catch (_) {
      db.rawDb.execute('ROLLBACK');
      rethrow;
    }
  }

  Future<void> saveTransactions(List<TransactionItem> transactions) =>
      replaceTransactions(transactions);

  void _executeInsert(dynamic stmt, TransactionItem tx) {
    stmt.execute([
      tx.id,
      tx.type.name,
      tx.amount,
      tx.categoryId,
      tx.categoryName,
      tx.accountId,
      tx.accountName,
      tx.toAccountId,
      tx.toAccountName,
      tx.merchant,
      tx.note,
      tx.date.toIso8601String(),
      jsonEncode(tx.tags),
      tx.receiptImagePath,
      tx.location,
      tx.isRecurring ? 1 : 0,
      tx.isReviewed ? 1 : 0,
      tx.source,
      tx.refundedTransactionId,
      jsonEncode(tx.splits.map((s) => s.toJson()).toList()),
    ]);
  }

  TransactionItem _mapRowToTransaction(dynamic r) {
    TransactionType type;
    final rawType = r['type'];
    if (rawType is String) {
      type = TransactionType.values.firstWhere(
        (e) => e.name == rawType,
        orElse: () => TransactionType.expense,
      );
    } else if (rawType is int && rawType >= 0 && rawType < TransactionType.values.length) {
      type = TransactionType.values[rawType];
    } else {
      type = TransactionType.expense;
    }

    List<String> tagsList;
    try {
      tagsList = List<String>.from(jsonDecode(r['tags'] as String));
    } catch (_) {
      tagsList = [];
    }

    List<TransactionSplit> splitsList = [];
    try {
      final List raw = jsonDecode(r['splits'] as String);
      splitsList = raw.map((s) => TransactionSplit.fromJson(s)).toList();
    } catch (_) {
      splitsList = [];
    }

    return TransactionItem(
      id: r['id'] as String,
      type: type,
      amount: (r['amount'] as num).toDouble(),
      categoryId: r['category_id'] as String,
      categoryName: r['category_name'] as String,
      accountId: r['account_id'] as String,
      accountName: r['account_name'] as String,
      toAccountId: r['to_account_id'] as String?,
      toAccountName: r['to_account_name'] as String?,
      merchant: r['merchant'] as String,
      note: r['note'] as String? ?? '',
      date: DateTime.parse(r['date'] as String),
      tags: tagsList,
      receiptImagePath: r['receipt_image_path'] as String?,
      location: r['location'] as String?,
      isRecurring: (r['is_recurring'] as int?) == 1,
      isReviewed: (r['is_reviewed'] as int?) == 1,
      source: r['source'] as String? ?? 'manual',
      refundedTransactionId: r['refunded_transaction_id'] as String?,
      splits: splitsList,
    );
  }
}
