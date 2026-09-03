import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../models/category.dart';
import '../models/guide.dart';
import '../models/guide_type.dart';

/// Single access point for guide/category/favorite data. Screens depend on
/// this, not on sqflite directly — so the storage engine (or a future backend)
/// can be swapped without touching the UI.
class GuideRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // ---- Categories & guides -------------------------------------------------

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
    final rows = await db.query('guides', orderBy: 'updated_at DESC', limit: limit);
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

  // ---- Search --------------------------------------------------------------

  /// Bilingual search. Uses FTS5 (prefix + ranked) when available, otherwise
  /// falls back to a portable LIKE scan.
  Future<List<Guide>> search(String query) async {
    final term = query.trim();
    if (term.isEmpty) return [];
    final db = await _dbHelper.database;

    if (_dbHelper.ftsAvailable) {
      final match = buildMatchQuery(term);
      if (match.isNotEmpty) {
        try {
          final rows = await db.rawQuery(
            'SELECT g.* FROM guides g '
            'JOIN guides_fts f ON g.id = f.rowid '
            'WHERE f MATCH ? ORDER BY f.rank',
            [match],
          );
          return rows.map(Guide.fromMap).toList();
        } catch (_) {
          // Malformed MATCH or FTS runtime error — fall back below.
        }
      }
    }
    return _likeSearch(db, term);
  }

  Future<List<Guide>> _likeSearch(Database db, String term) async {
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

  /// Builds a safe FTS5 MATCH expression: each whitespace-separated token is
  /// quoted (so special characters are literal) and given a `*` prefix so
  /// partial words match. Tokens are ANDed together.
  static String buildMatchQuery(String input) {
    final tokens = input
        .split(RegExp(r'\s+'))
        .where((t) => t.trim().isNotEmpty)
        .map((t) => '"${t.replaceAll('"', '""')}"*');
    return tokens.join(' ');
  }

  // ---- Favorites -----------------------------------------------------------

  Future<Set<int>> getFavoriteIds() async {
    final db = await _dbHelper.database;
    final rows = await db.query('favorites', columns: ['guide_id']);
    return rows.map((r) => r['guide_id'] as int).toSet();
  }

  Future<void> setFavorite(int guideId, bool isFavorite) async {
    final db = await _dbHelper.database;
    if (isFavorite) {
      await db.insert(
        'favorites',
        {'guide_id': guideId, 'created_at': DateTime.now().toIso8601String()},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } else {
      await db.delete('favorites', where: 'guide_id = ?', whereArgs: [guideId]);
    }
  }

  Future<List<Guide>> getFavoriteGuides() async {
    final db = await _dbHelper.database;
    final rows = await db.rawQuery('''
      SELECT g.* FROM guides g
      JOIN favorites f ON f.guide_id = g.id
      ORDER BY f.created_at DESC
    ''');
    return rows.map(Guide.fromMap).toList();
  }
}
