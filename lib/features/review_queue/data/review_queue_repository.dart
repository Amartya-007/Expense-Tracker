import 'package:expensetracker/models/review_queue_item.dart';
import 'package:expensetracker/models/transaction.dart';
import 'package:expensetracker/core/database/app_database.dart';

class ReviewQueueRepository {
  final AppDatabase db;

  ReviewQueueRepository(this.db);

  static const _selectColumns = '''
    id, merchant, amount, date, suggested_category_id, suggested_category_name,
    suggested_account_id, suggested_account_name, source_notification, suggested_type
  ''';

  Future<List<ReviewQueueItem>> getReviewQueue() async {
    final rows = db.rawDb.select(
      'SELECT $_selectColumns FROM review_queue ORDER BY date DESC, id DESC',
    );
    return rows.map(_mapRowToQueueItem).toList();
  }

  Future<void> replaceReviewQueue(List<ReviewQueueItem> queue) async {
    db.rawDb.execute('BEGIN TRANSACTION');
    try {
      db.rawDb.execute('DELETE FROM review_queue');
      final stmt = db.rawDb.prepare('''
        INSERT INTO review_queue (
          id, merchant, amount, date, suggested_category_id, suggested_category_name,
          suggested_account_id, suggested_account_name, source_notification, suggested_type
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''');
      for (final item in queue) {
        stmt.execute([
          item.id,
          item.merchant,
          item.amount,
          item.date.toIso8601String(),
          item.suggestedCategoryId,
          item.suggestedCategoryName,
          item.suggestedAccountId,
          item.suggestedAccountName,
          item.sourceNotification,
          item.suggestedType.name,
        ]);
      }
      stmt.dispose();
      db.rawDb.execute('COMMIT');
    } catch (_) {
      db.rawDb.execute('ROLLBACK');
      rethrow;
    }
  }

  Future<void> saveReviewQueue(List<ReviewQueueItem> queue) => replaceReviewQueue(queue);

  ReviewQueueItem _mapRowToQueueItem(dynamic r) {
    TransactionType type;
    final rawType = r['suggested_type'];
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

    return ReviewQueueItem(
      id: r['id'] as String,
      merchant: r['merchant'] as String,
      amount: (r['amount'] as num).toDouble(),
      date: DateTime.parse(r['date'] as String),
      suggestedCategoryId: r['suggested_category_id'] as String,
      suggestedCategoryName: r['suggested_category_name'] as String,
      suggestedAccountId: r['suggested_account_id'] as String,
      suggestedAccountName: r['suggested_account_name'] as String,
      sourceNotification: r['source_notification'] as String,
      suggestedType: type,
    );
  }
}
