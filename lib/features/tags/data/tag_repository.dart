import 'package:expensetracker/core/database/app_database.dart';

class TagRepository {
  final AppDatabase db;

  TagRepository(this.db);

  Future<List<String>> getTags() async {
    final rows = db.rawDb.select('SELECT name FROM custom_tags ORDER BY name ASC');
    if (rows.isEmpty) {
      return [
        'Personal',
        'Work',
        'Family',
        'Travel',
        'Food',
        'Emergency',
        'Reimbursement',
        'Medical',
      ];
    }
    return rows.map((r) => r['name'] as String).toList();
  }

  Future<void> replaceTags(List<String> tags) async {
    db.rawDb.execute('BEGIN TRANSACTION');
    try {
      db.rawDb.execute('DELETE FROM custom_tags');
      final stmt = db.rawDb.prepare('INSERT INTO custom_tags (name) VALUES (?)');
      for (final tag in tags) {
        stmt.execute([tag]);
      }
      stmt.dispose();
      db.rawDb.execute('COMMIT');
    } catch (_) {
      db.rawDb.execute('ROLLBACK');
      rethrow;
    }
  }

  Future<void> saveTags(List<String> tags) => replaceTags(tags);
}
