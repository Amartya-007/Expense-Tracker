import 'package:expensetracker/core/database/app_database.dart';
import 'package:sqlite3/sqlite3.dart';

class CustomParserRule {
  final String id;
  final String name;
  final String keyword;
  final String pattern;
  final bool isRegex;
  final String categoryName;
  final String accountRef;
  final bool isDebit;
  final bool isEnabled;
  final int priority;

  CustomParserRule({
    required this.id,
    required this.name,
    required this.keyword,
    required this.pattern,
    required this.isRegex,
    required this.categoryName,
    required this.accountRef,
    required this.isDebit,
    required this.isEnabled,
    required this.priority,
  });

  factory CustomParserRule.fromRow(Row row) {
    return CustomParserRule(
      id: row['id'] as String,
      name: row['name'] as String,
      keyword: row['keyword'] as String? ?? '',
      pattern: row['pattern'] as String? ?? '',
      isRegex: (row['is_regex'] as int?) == 1,
      categoryName: row['category_name'] as String? ?? 'Other',
      accountRef: row['account_ref'] as String? ?? '',
      isDebit: (row['is_debit'] as int?) == 1,
      isEnabled: (row['is_enabled'] as int?) == 1,
      priority: row['priority'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'keyword': keyword,
      'pattern': pattern,
      'is_regex': isRegex ? 1 : 0,
      'category_name': categoryName,
      'account_ref': accountRef,
      'is_debit': isDebit ? 1 : 0,
      'is_enabled': isEnabled ? 1 : 0,
      'priority': priority,
    };
  }
}

class CustomRulesRepository {
  final AppDatabase _database;

  CustomRulesRepository(this._database) {
    _ensureTable();
  }

  void _ensureTable() {
    _database.rawDb.execute('''
      CREATE TABLE IF NOT EXISTS custom_parser_rules (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        keyword TEXT NOT NULL DEFAULT '',
        pattern TEXT NOT NULL DEFAULT '',
        is_regex INTEGER NOT NULL DEFAULT 0,
        category_name TEXT NOT NULL DEFAULT 'Other',
        account_ref TEXT NOT NULL DEFAULT '',
        is_debit INTEGER NOT NULL DEFAULT 1,
        is_enabled INTEGER NOT NULL DEFAULT 1,
        priority INTEGER NOT NULL DEFAULT 0
      );
    ''');
  }

  List<CustomParserRule> getAllRules() {
    try {
      final resultSet = _database.rawDb.select(
        'SELECT * FROM custom_parser_rules ORDER BY priority DESC, name ASC',
      );
      return resultSet.map(CustomParserRule.fromRow).toList();
    } catch (_) {
      return [];
    }
  }

  void saveRule(CustomParserRule rule) {
    _database.rawDb.execute(
      '''
      INSERT OR REPLACE INTO custom_parser_rules 
      (id, name, keyword, pattern, is_regex, category_name, account_ref, is_debit, is_enabled, priority)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''',
      [
        rule.id,
        rule.name,
        rule.keyword,
        rule.pattern,
        rule.isRegex ? 1 : 0,
        rule.categoryName,
        rule.accountRef,
        rule.isDebit ? 1 : 0,
        rule.isEnabled ? 1 : 0,
        rule.priority,
      ],
    );
  }

  void deleteRule(String id) {
    _database.rawDb.execute('DELETE FROM custom_parser_rules WHERE id = ?', [id]);
  }

  void toggleRule(String id, bool enabled) {
    _database.rawDb.execute(
      'UPDATE custom_parser_rules SET is_enabled = ? WHERE id = ?',
      [enabled ? 1 : 0, id],
    );
  }

  // Test regex validation
  static String? validateRegex(String pattern) {
    if (pattern.isEmpty) return null;
    try {
      RegExp(pattern);
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}
