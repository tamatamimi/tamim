import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Offline-first SQLite store.
///
/// Schema (v2):
///  - categories, guides          : content, populated by [ContentImporter]
///  - favorites                   : per-user bookmarks (offline)
///  - meta                        : key/value (e.g. imported content version)
///  - guides_fts                  : FTS5 index for full-text search
///
/// FTS5 is created best-effort: if the platform's SQLite build lacks the FTS5
/// module, [ftsAvailable] stays false and search falls back to LIKE.
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static const _dbName = 'erp_guides.db';
  static const _dbVersion = 3;

  Database? _db;

  /// True once the FTS5 virtual table exists and can be queried.
  bool ftsAvailable = false;

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    final path = p.join(dir, _dbName);
    final db = await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    await _ensureFts(db);
    return db;
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createCore(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS meta (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS favorites (
          guide_id INTEGER PRIMARY KEY,
          created_at TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE guides ADD COLUMN media_type TEXT');
      await db.execute('ALTER TABLE guides ADD COLUMN media_source TEXT');
    }
  }

  Future<void> _createCore(Database db) async {
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
        media_type TEXT,
        media_source TEXT,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories (id)
      )
    ''');

    await db.execute('CREATE INDEX idx_guides_category ON guides (category_id)');
    await db.execute('CREATE INDEX idx_guides_type ON guides (type)');

    await db.execute('''
      CREATE TABLE meta (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE favorites (
        guide_id INTEGER PRIMARY KEY,
        created_at TEXT NOT NULL
      )
    ''');
  }

  /// Best-effort FTS5 index. External-content table mirrors `guides` and is
  /// (re)populated via a 'rebuild' command after each import.
  Future<void> _ensureFts(Database db) async {
    try {
      await db.execute('''
        CREATE VIRTUAL TABLE IF NOT EXISTS guides_fts USING fts5(
          title_ar, title_en,
          summary_ar, summary_en,
          content_ar, content_en,
          tags,
          content='guides',
          content_rowid='id',
          tokenize='unicode61 remove_diacritics 2'
        )
      ''');
      ftsAvailable = true;
    } catch (_) {
      ftsAvailable = false;
    }
  }
}
