import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:sqflite/sqflite.dart';

import '../models/category.dart';
import '../models/guide.dart';
import 'database_helper.dart';

/// Loads guide content from a bundled, versioned JSON asset into SQLite.
///
/// Content updates ship by bumping `contentVersion` in the asset (or, later,
/// by fetching an updated JSON from a backend). Re-import only happens when the
/// asset version differs from the version already stored — so normal launches
/// are cheap.
class ContentImporter {
  static const _assetPath = 'assets/content/guides.json';
  static const _versionKey = 'content_version';

  Future<void> importIfNeeded() async {
    final db = await DatabaseHelper.instance.database;

    final raw = await rootBundle.loadString(_assetPath);
    final data = json.decode(raw) as Map<String, dynamic>;
    final assetVersion = data['contentVersion'] as int;

    final storedVersion = await _storedVersion(db);
    if (storedVersion == assetVersion) return;

    final categories = (data['categories'] as List<dynamic>)
        .map((e) => Category.fromJson(e as Map<String, dynamic>))
        .toList();
    final guides = (data['guides'] as List<dynamic>)
        .map((e) => Guide.fromJson(e as Map<String, dynamic>))
        .toList();

    await db.transaction((txn) async {
      await txn.delete('guides');
      await txn.delete('categories');
      final batch = txn.batch();
      for (final category in categories) {
        batch.insert('categories', category.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      for (final guide in guides) {
        batch.insert('guides', guide.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
    });

    await _rebuildFts(db);
    await _setStoredVersion(db, assetVersion);
  }

  Future<int?> _storedVersion(Database db) async {
    final rows = await db.query('meta',
        where: 'key = ?', whereArgs: [_versionKey], limit: 1);
    if (rows.isEmpty) return null;
    return int.tryParse(rows.first['value'] as String);
  }

  Future<void> _setStoredVersion(Database db, int version) async {
    await db.insert(
      'meta',
      {'key': _versionKey, 'value': '$version'},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> _rebuildFts(Database db) async {
    if (!DatabaseHelper.instance.ftsAvailable) return;
    try {
      await db.execute(
          "INSERT INTO guides_fts(guides_fts) VALUES('rebuild')");
    } catch (_) {
      // FTS became unavailable at runtime; search falls back to LIKE.
    }
  }
}
