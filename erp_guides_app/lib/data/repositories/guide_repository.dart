import '../database/database_helper.dart';
import '../models/category.dart';
import '../models/guide.dart';
import '../models/guide_type.dart';

/// Single access point for guide/category data. Screens depend on this, not on
/// sqflite directly — so the storage engine (or a future backend) can be
/// swapped without touching the UI.
class GuideRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<List<Category>> getCategories() async {
    final db = await _dbHelper.database;
    final rows = await db.query('categories', orderBy: 'sort_order ASC');
    return rows.map(Category.fromMap).toList();
  }

  Future<List<Guide>> getGuidesByCategory(int categoryId) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'guides',
      where: 'category_id = ?',
      whereArgs: [categoryId],
      orderBy: 'updated_at DESC',
    );
    return rows.map(Guide.fromMap).toList();
  }

  Future<List<Guide>> getRecentGuides({int limit = 5}) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'guides',
      orderBy: 'updated_at DESC',
      limit: limit,
    );
    return rows.map(Guide.fromMap).toList();
  }

  Future<List<Guide>> getRelatedByType(GuideType type, int excludeId) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'guides',
      where: 'type = ? AND id != ?',
      whereArgs: [type.key, excludeId],
      orderBy: 'updated_at DESC',
      limit: 5,
    );
    return rows.map(Guide.fromMap).toList();
  }

  /// Bilingual search across titles, summaries, tags, and content.
  /// Uses LIKE for portability; migrate to FTS5 for large corpora.
  Future<List<Guide>> search(String query) async {
    final term = query.trim();
    if (term.isEmpty) return [];
    final db = await _dbHelper.database;
    final like = '%$term%';
    final rows = await db.query(
      'guides',
      where: '''
        title_ar LIKE ? OR title_en LIKE ? OR
        summary_ar LIKE ? OR summary_en LIKE ? OR
        content_ar LIKE ? OR content_en LIKE ? OR
        tags LIKE ?
      ''',
      whereArgs: [like, like, like, like, like, like, like],
      orderBy: 'updated_at DESC',
    );
    return rows.map(Guide.fromMap).toList();
  }
}
