import 'dart:convert';
import 'package:expensetracker/models/category.dart';
import 'package:expensetracker/core/database/app_database.dart';

class CategoryRepository {
  final AppDatabase db;

  CategoryRepository(this.db);

  static const _selectColumns = '''
    id, name, type, icon_code, color_hex, parent_category_id, subcategories
  ''';

  Future<List<Category>> getCategories() async {
    final rows = db.rawDb.select(
      'SELECT $_selectColumns FROM categories ORDER BY name ASC, id ASC',
    );
    return rows.map(_mapRowToCategory).toList();
  }

  Future<void> replaceCategories(List<Category> categories) async {
    db.rawDb.execute('BEGIN TRANSACTION');
    try {
      db.rawDb.execute('DELETE FROM categories');
      final stmt = db.rawDb.prepare('''
        INSERT INTO categories (
          id, name, type, icon_code, color_hex, parent_category_id, subcategories
        ) VALUES (?, ?, ?, ?, ?, ?, ?)
      ''');
      for (final cat in categories) {
        stmt.execute([
          cat.id,
          cat.name,
          cat.type.name,
          cat.iconCode,
          cat.colorHex,
          cat.parentCategoryId,
          jsonEncode(cat.subcategories),
        ]);
      }
      stmt.dispose();
      db.rawDb.execute('COMMIT');
    } catch (_) {
      db.rawDb.execute('ROLLBACK');
      rethrow;
    }
  }

  Future<void> saveCategories(List<Category> categories) => replaceCategories(categories);

  Category _mapRowToCategory(dynamic r) {
    CategoryType type;
    final rawType = r['type'];
    if (rawType is String) {
      type = CategoryType.values.firstWhere(
        (e) => e.name == rawType,
        orElse: () => CategoryType.expense,
      );
    } else if (rawType is int && rawType >= 0 && rawType < CategoryType.values.length) {
      type = CategoryType.values[rawType];
    } else {
      type = CategoryType.expense;
    }

    List<String> subcats;
    try {
      subcats = List<String>.from(jsonDecode(r['subcategories'] as String));
    } catch (_) {
      subcats = [];
    }

    return Category(
      id: r['id'] as String,
      name: r['name'] as String,
      type: type,
      iconCode: (r['icon_code'] as int?) ?? 0xe59c,
      colorHex: (r['color_hex'] as int?) ?? 0xFF00B2E7,
      parentCategoryId: r['parent_category_id'] as String?,
      subcategories: subcats,
    );
  }
}
