import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'seed_data.dart';

/// Offline-first SQLite store. Creates the schema and seeds initial content on
/// first launch. All reads/writes go through [GuideRepository].
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static const _dbName = 'erp_guides.db';
  static const _dbVersion = 1;

  Database? _db;

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    final path = p.join(dir, _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY,
        name_ar TEXT NOT NULL,
        name_en TEXT NOT NULL,
        icon TEXT NOT NULL,
        sort_order INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE guides (
        id INTEGER PRIMARY KEY,
        category_id INTEGER NOT NULL,
        type TEXT NOT NULL,
        title_ar TEXT NOT NULL,
        title_en TEXT NOT NULL,
        summary_ar TEXT NOT NULL,
        summary_en TEXT NOT NULL,
        content_ar TEXT NOT NULL,
        content_en TEXT NOT NULL,
        tags TEXT NOT NULL,
        image_asset TEXT,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories (id)
      )
    ''');

    await db.execute(
        'CREATE INDEX idx_guides_category ON guides (category_id)');
    await db.execute('CREATE INDEX idx_guides_type ON guides (type)');

    await _seed(db);
  }

  Future<void> _seed(Database db) async {
    final batch = db.batch();
    for (final category in SeedData.categories) {
      batch.insert('categories', category.toMap());
    }
    for (final guide in SeedData.guides) {
      batch.insert('guides', guide.toMap());
    }
    await batch.commit(noResult: true);
  }
}
