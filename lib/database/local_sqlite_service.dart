import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io';
import 'dart:developer' as developer;

/// Local SQLite database service - Offline-only
/// Version 1: Complete local schema
class LocalSQLiteService {
  static final LocalSQLiteService _instance = LocalSQLiteService._internal();
  static Database? _database;
  static const int _version = 2;

  LocalSQLiteService._internal();

  factory LocalSQLiteService() => _instance;

  /// Get database instance (creates if doesn't exist)
  Future<Database> get db async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize database with schema
  Future<Database> _initDatabase() async {
    try {
      final databasesPath = await getDatabasesPath();

      // Ensure the database directory exists
      final dbDir = Directory(databasesPath);
      if (!await dbDir.exists()) {
        await dbDir.create(recursive: true);
        developer.log('[DB] Created database directory: $databasesPath');
      }

      final path = join(databasesPath, 'local_data.db');

      final db = await openDatabase(
        path,
        version: _version,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        singleInstance: true,
      );

      // Enable WAL mode and performance optimizations (with error handling)
      try {
        await db.execute('PRAGMA journal_mode=WAL;');
        developer.log('[DB] WAL mode enabled');
      } catch (e) {
        developer.log('[DB] ⚠️ Could not enable WAL mode: $e');
        // Continue - database will work without WAL
      }

      try {
        await db.execute('PRAGMA synchronous=NORMAL;');
      } catch (e) {
        developer.log('[DB] ⚠️ Could not set synchronous mode: $e');
      }

      try {
        await db.execute('PRAGMA foreign_keys=ON;');
      } catch (e) {
        developer.log('[DB] ⚠️ Could not enable foreign keys: $e');
      }

      return db;
    } catch (e) {
      developer.log(
        '[DB] ❌ Database initialization failed: $e',
        name: 'LocalSQLiteService',
      );
      rethrow;
    }
  }

  /// Create tables and indexes
  Future<void> _onCreate(Database db, int version) async {
    // Users table
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        username TEXT UNIQUE NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        is_admin INTEGER NOT NULL DEFAULT 0,
        name TEXT,
        gender TEXT,
        birth_date TEXT,
        profile_image_url TEXT,
        uniqueId TEXT,
        role TEXT,
        created_at INTEGER,
        updated_at INTEGER
      )
    ''');

    await db.execute('CREATE UNIQUE INDEX ux_users_email ON users(email)');

    // Subcategories table
    await db.execute('''
      CREATE TABLE subcategories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        section TEXT NOT NULL,
        description TEXT,
        icon_name TEXT,
        created_at INTEGER
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_subcats_section ON subcategories(section)',
    );

    // Lectures table
    await db.execute('''
      CREATE TABLE lectures (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        video_path TEXT,
        section TEXT NOT NULL,
        subcategory_id TEXT,
        sheikhId TEXT,
        sheikhName TEXT,
        categoryId TEXT,
        categoryName TEXT,
        subcategoryName TEXT,
        startTime INTEGER,
        endTime INTEGER,
        status TEXT CHECK(status IN ('draft','published','archived','deleted')) DEFAULT 'draft',
        isPublished INTEGER NOT NULL DEFAULT 0,
        createdAt INTEGER,
        updatedAt INTEGER
      )
    ''');

    await db.execute('CREATE INDEX idx_lectures_section ON lectures(section)');
    await db.execute('CREATE INDEX idx_lectures_sheikh ON lectures(sheikhId)');
    await db.execute('CREATE INDEX idx_lectures_start ON lectures(startTime)');

    // Optional FTS5 for local search (with fallback)
    bool fts5Available = false;
    try {
      await db.execute('''
        CREATE VIRTUAL TABLE IF NOT EXISTS lectures_fts USING fts5(
          title,
          description,
          content='lectures',
          content_rowid='rowid'
        )
      ''');

      // Verify FTS5 table was created
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='lectures_fts'",
      );
      if (tables.isNotEmpty) {
        fts5Available = true;
        developer.log('[DB] ✅ FTS5 table created successfully');

        // Triggers to update FTS5 index
        await db.execute('''
          CREATE TRIGGER IF NOT EXISTS lectures_fts_insert AFTER INSERT ON lectures BEGIN
            INSERT INTO lectures_fts(rowid, title, description)
            VALUES (new.rowid, new.title, new.description);
          END
        ''');

        await db.execute('''
          CREATE TRIGGER IF NOT EXISTS lectures_fts_update AFTER UPDATE ON lectures BEGIN
            UPDATE lectures_fts SET title = new.title, description = new.description
            WHERE rowid = new.rowid;
          END
        ''');

        await db.execute('''
          CREATE TRIGGER IF NOT EXISTS lectures_fts_delete AFTER DELETE ON lectures BEGIN
            DELETE FROM lectures_fts WHERE rowid = old.rowid;
          END
        ''');
      }
    } catch (e) {
      developer.log(
        '[DB] ⚠️ FTS5 not available; falling back to LIKE search: $e',
        name: 'LocalSQLiteService',
      );
      fts5Available = false;
      // Store FTS5 availability flag for search functions
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS _fts5_metadata (
            key TEXT PRIMARY KEY,
            value TEXT
          )
        ''');
        await db.insert('_fts5_metadata', {
          'key': 'available',
          'value': 'false',
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      } catch (_) {
        // Ignore metadata table creation errors
      }
    }

    // Store FTS5 availability
    if (fts5Available) {
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS _fts5_metadata (
            key TEXT PRIMARY KEY,
            value TEXT
          )
        ''');
        await db.insert('_fts5_metadata', {
          'key': 'available',
          'value': 'true',
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      } catch (_) {
        // Ignore metadata table creation errors
      }
    }

    developer.log('Local SQLite database schema created (version $_version)');
  }

  /// Upgrade database schema
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    developer.log('Upgrading database from version $oldVersion to $newVersion');

    if (oldVersion < 2) {
      // Add sheikhs table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS sheikhs (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          uniqueId TEXT UNIQUE,
          name TEXT NOT NULL,
          email TEXT,
          phone TEXT,
          category TEXT,
          createdAt TEXT,
          updatedAt TEXT,
          isDeleted INTEGER DEFAULT 0
        )
      ''');

      await db.execute(
        'CREATE UNIQUE INDEX IF NOT EXISTS ux_sheikhs_uniqueId ON sheikhs(uniqueId)',
      );

      developer.log('Added sheikhs table (version 2)');
    }
  }

  /// Get database path for logging
  Future<String> getDatabasePath() async {
    final databasesPath = await getDatabasesPath();
    return join(databasesPath, 'local_data.db');
  }

  /// Get row count for a table
  Future<int> getRowCount(String tableName) async {
    final dbInstance = await db;
    final result = await dbInstance.rawQuery(
      'SELECT COUNT(*) as count FROM $tableName',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Check if FTS5 is available
  Future<bool> isFts5Available() async {
    try {
      final dbInstance = await db;
      // Check if metadata table exists and has FTS5 available
      final metadata = await dbInstance.rawQuery(
        "SELECT value FROM _fts5_metadata WHERE key='available'",
      );
      if (metadata.isNotEmpty) {
        return (metadata.first['value'] as String?) == 'true';
      }
      // Fallback: check if FTS5 table exists
      final tables = await dbInstance.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='lectures_fts'",
      );
      return tables.isNotEmpty;
    } catch (e) {
      developer.log(
        'Error checking FTS5 availability: $e',
        name: 'LocalSQLiteService',
      );
      return false;
    }
  }

  /// Close database
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
