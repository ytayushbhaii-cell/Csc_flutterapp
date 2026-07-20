import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

/// Central SQLite service for CSC Smart Toolkit.
///
/// Tables:
///  • tool_history    — per-tool usage records (mirrors HistoryEntry)
///  • recent_files    — recently exported / opened files
///  • favorites       — pinned tool IDs
///  • settings        — key/value app settings
///  • export_history  — every export / download event
///
/// All public methods are static so callers never need to hold an instance;
/// the singleton DB handle is managed internally.
class DatabaseService {
  DatabaseService._();

  static Database? _db;

  static const _dbName = 'csc_toolkit.db';
  static const _dbVersion = 1;
  static const _keyMigrated = 'db_migrated_v1';

  // ── Table names ────────────────────────────────────────────────────────────
  static const String tableToolHistory   = 'tool_history';
  static const String tableRecentFiles   = 'recent_files';
  static const String tableFavorites     = 'favorites';
  static const String tableSettings      = 'settings';
  static const String tableExportHistory = 'export_history';

  // ── Initialise ─────────────────────────────────────────────────────────────

  static Future<Database> get db async {
    _db ??= await _open();
    return _db!;
  }

  static Future<Database> _open() async {
    final dbPath = p.join(await getDatabasesPath(), _dbName);
    final database = await openDatabase(
      dbPath,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    await _migrateFromSharedPrefs(database);
    return database;
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableToolHistory (
        id         TEXT    PRIMARY KEY,
        tool_id    TEXT    NOT NULL,
        tool_name  TEXT    NOT NULL,
        category   TEXT    NOT NULL,
        timestamp  INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableRecentFiles (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        file_path   TEXT    NOT NULL,
        file_name   TEXT    NOT NULL,
        file_type   TEXT    NOT NULL,
        tool_id     TEXT    NOT NULL DEFAULT '',
        created_at  INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableFavorites (
        tool_id   TEXT    PRIMARY KEY,
        added_at  INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableSettings (
        key   TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableExportHistory (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        tool_id     TEXT    NOT NULL,
        tool_name   TEXT    NOT NULL,
        format      TEXT    NOT NULL,
        file_path   TEXT    NOT NULL,
        file_size   INTEGER DEFAULT 0,
        created_at  INTEGER NOT NULL
      )
    ''');

    // Indexes for fast lookups
    await db.execute('CREATE INDEX idx_th_ts ON $tableToolHistory (timestamp DESC)');
    await db.execute('CREATE INDEX idx_rf_ts ON $tableRecentFiles (created_at DESC)');
    await db.execute('CREATE INDEX idx_eh_ts ON $tableExportHistory (created_at DESC)');
  }

  static Future<void> _onUpgrade(Database db, int oldV, int newV) async {
    // Future migrations go here
  }

  // ── Migration from SharedPreferences ───────────────────────────────────────

  static Future<void> _migrateFromSharedPrefs(Database db) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_keyMigrated) == true) return;

    // Migrate favorites
    final favRaw = prefs.getString('favorites');
    if (favRaw != null) {
      try {
        final ids = (jsonDecode(favRaw) as List<dynamic>).cast<String>();
        final batch = db.batch();
        for (final id in ids) {
          batch.insert(
            tableFavorites,
            {'tool_id': id, 'added_at': DateTime.now().millisecondsSinceEpoch},
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }
        await batch.commit(noResult: true);
      } catch (_) {}
    }

    // Migrate tool history
    final histRaw = prefs.getString('history');
    if (histRaw != null) {
      try {
        final list = (jsonDecode(histRaw) as List<dynamic>)
            .cast<Map<String, dynamic>>();
        final batch = db.batch();
        for (final e in list.take(200)) {
          final ts = DateTime.tryParse(e['timestamp'] as String? ?? '')
                  ?.millisecondsSinceEpoch ??
              DateTime.now().millisecondsSinceEpoch;
          batch.insert(
            tableToolHistory,
            {
              'id':        e['id'],
              'tool_id':   e['toolId'],
              'tool_name': e['toolName'],
              'category':  e['category'],
              'timestamp': ts,
            },
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }
        await batch.commit(noResult: true);
      } catch (_) {}
    }

    await prefs.setBool(_keyMigrated, true);
  }

  // ── tool_history ───────────────────────────────────────────────────────────

  static Future<void> insertToolHistory({
    required String id,
    required String toolId,
    required String toolName,
    required String category,
    DateTime? timestamp,
  }) async {
    final database = await db;
    await database.insert(
      tableToolHistory,
      {
        'id':        id,
        'tool_id':   toolId,
        'tool_name': toolName,
        'category':  category,
        'timestamp': (timestamp ?? DateTime.now()).millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    // Keep max 200 entries
    await database.execute('''
      DELETE FROM $tableToolHistory WHERE id NOT IN (
        SELECT id FROM $tableToolHistory ORDER BY timestamp DESC LIMIT 200
      )
    ''');
  }

  static Future<List<Map<String, dynamic>>> getToolHistory({
    int limit = 200,
  }) async {
    final database = await db;
    return database.query(
      tableToolHistory,
      orderBy: 'timestamp DESC',
      limit: limit,
    );
  }

  static Future<void> deleteToolHistoryEntry(String id) async {
    final database = await db;
    await database.delete(tableToolHistory, where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> clearToolHistory() async {
    final database = await db;
    await database.delete(tableToolHistory);
  }

  // ── favorites ──────────────────────────────────────────────────────────────

  static Future<Set<String>> getFavorites() async {
    final database = await db;
    final rows = await database.query(tableFavorites, columns: ['tool_id']);
    return rows.map((r) => r['tool_id'] as String).toSet();
  }

  static Future<void> addFavorite(String toolId) async {
    final database = await db;
    await database.insert(
      tableFavorites,
      {'tool_id': toolId, 'added_at': DateTime.now().millisecondsSinceEpoch},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  static Future<void> removeFavorite(String toolId) async {
    final database = await db;
    await database.delete(tableFavorites,
        where: 'tool_id = ?', whereArgs: [toolId]);
  }

  static Future<void> saveFavorites(Set<String> ids) async {
    final database = await db;
    await database.transaction((txn) async {
      await txn.delete(tableFavorites);
      final batch = txn.batch();
      for (final id in ids) {
        batch.insert(tableFavorites,
            {'tool_id': id, 'added_at': DateTime.now().millisecondsSinceEpoch},
            conflictAlgorithm: ConflictAlgorithm.ignore);
      }
      await batch.commit(noResult: true);
    });
  }

  // ── settings ───────────────────────────────────────────────────────────────

  static Future<String?> getSetting(String key) async {
    final database = await db;
    final rows = await database.query(tableSettings,
        columns: ['value'], where: 'key = ?', whereArgs: [key]);
    return rows.isEmpty ? null : rows.first['value'] as String;
  }

  static Future<void> setSetting(String key, String value) async {
    final database = await db;
    await database.insert(
      tableSettings,
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ── export_history ─────────────────────────────────────────────────────────

  static Future<void> insertExportHistory({
    required String toolId,
    required String toolName,
    required String format,
    required String filePath,
    int fileSize = 0,
  }) async {
    final database = await db;
    await database.insert(
      tableExportHistory,
      {
        'tool_id':    toolId,
        'tool_name':  toolName,
        'format':     format,
        'file_path':  filePath,
        'file_size':  fileSize,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      },
    );
    // Keep max 500 entries
    await database.execute('''
      DELETE FROM $tableExportHistory WHERE id NOT IN (
        SELECT id FROM $tableExportHistory ORDER BY created_at DESC LIMIT 500
      )
    ''');
  }

  static Future<List<Map<String, dynamic>>> getExportHistory({
    int limit = 100,
  }) async {
    final database = await db;
    return database.query(
      tableExportHistory,
      orderBy: 'created_at DESC',
      limit: limit,
    );
  }

  static Future<void> clearExportHistory() async {
    final database = await db;
    await database.delete(tableExportHistory);
  }

  // ── recent_files ───────────────────────────────────────────────────────────

  static Future<void> insertRecentFile({
    required String filePath,
    required String fileName,
    required String fileType,
    String toolId = '',
  }) async {
    final database = await db;
    // Remove duplicate path if it exists
    await database.delete(tableRecentFiles,
        where: 'file_path = ?', whereArgs: [filePath]);
    await database.insert(
      tableRecentFiles,
      {
        'file_path':  filePath,
        'file_name':  fileName,
        'file_type':  fileType,
        'tool_id':    toolId,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      },
    );
    // Keep max 50 entries
    await database.execute('''
      DELETE FROM $tableRecentFiles WHERE id NOT IN (
        SELECT id FROM $tableRecentFiles ORDER BY created_at DESC LIMIT 50
      )
    ''');
  }

  static Future<List<Map<String, dynamic>>> getRecentFiles({
    int limit = 20,
  }) async {
    final database = await db;
    return database.query(
      tableRecentFiles,
      orderBy: 'created_at DESC',
      limit: limit,
    );
  }

  static Future<void> clearRecentFiles() async {
    final database = await db;
    await database.delete(tableRecentFiles);
  }

  // ── Utility ────────────────────────────────────────────────────────────────

  /// Close the database (call on app dispose if needed).
  static Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
