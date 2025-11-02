import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io';
import 'dart:developer' as developer;

/// Singleton SQLite database service
/// Manages local database for offline caching
/// Version 2: INTEGER timestamps, WAL mode, constraints, KV table
class SQLiteService {
  static final SQLiteService _instance = SQLiteService._internal();
  static Database? _database;
  static const int _currentVersion = 2;

  SQLiteService._internal();

  factory SQLiteService() => _instance;

  /// Get current schema version
  int get version => _currentVersion;

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
        version: _currentVersion,
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

      try {
        await db.execute('PRAGMA temp_store=MEMORY;');
      } catch (e) {
        developer.log('[DB] ⚠️ Could not set temp_store: $e');
      }

      return db;
    } catch (e) {
      developer.log(
        '[DB] ❌ Database initialization failed: $e',
        name: 'SQLiteService',
      );
      rethrow;
    }
  }

  /// Create tables and indexes (version 2)
  Future<void> _onCreate(Database db, int version) async {
    // KV table for sync metadata and last sync timestamps
    await db.execute('''
      CREATE TABLE sync_metadata (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updated_at INTEGER DEFAULT (strftime('%s', 'now') * 1000)
      )
    ''');

    // Users table with constraints
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        username TEXT,
        email TEXT UNIQUE NOT NULL,
        is_admin INTEGER DEFAULT 0 CHECK(is_admin IN (0, 1)),
        name TEXT,
        gender TEXT,
        birth_date TEXT,
        profile_image_url TEXT,
        updated_at INTEGER,
        created_at INTEGER
      )
    ''');

    // Subcategories table
    await db.execute('''
      CREATE TABLE subcategories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        section TEXT,
        description TEXT,
        icon_name TEXT,
        created_at INTEGER
      )
    ''');

    // Lectures table with constraints
    await db.execute('''
      CREATE TABLE lectures (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        video_path TEXT,
        section TEXT,
        subcategory_id TEXT,
        sheikhId TEXT,
        sheikhName TEXT,
        categoryId TEXT,
        categoryName TEXT,
        subcategoryName TEXT,
        startTime INTEGER,
        endTime INTEGER,
        status TEXT CHECK(status IN ('draft', 'published', 'archived', 'deleted')) DEFAULT 'draft',
        isPublished INTEGER DEFAULT 0 CHECK(isPublished IN (0, 1)),
        createdAt INTEGER,
        updatedAt INTEGER
      )
    ''');

    // Create indexes
    await db.execute('CREATE UNIQUE INDEX idx_users_email ON users(email)');
    await db.execute(
      'CREATE INDEX idx_subcategories_section ON subcategories(section)',
    );
    await db.execute('CREATE INDEX idx_lectures_section ON lectures(section)');
    await db.execute(
      'CREATE INDEX idx_lectures_sheikhId ON lectures(sheikhId)',
    );
    await db.execute('CREATE INDEX idx_lectures_status ON lectures(status)');
    await db.execute(
      'CREATE INDEX idx_lectures_updatedAt ON lectures(updatedAt)',
    );
    await db.execute(
      'CREATE INDEX idx_lectures_startTime ON lectures(startTime)',
    );

    // Optional: FTS5 virtual table for full-text search (with fallback)
    // Note: FTS5 requires rowid to match the main table
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
        developer.log(
          '[DB] ✅ FTS5 table created successfully (sqlite_service)',
        );

        // Trigger to update FTS5 index on insert/update
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
        name: 'SQLiteService',
      );
      // Continue - FTS5 is optional
    }

    developer.log('Database schema created (version $_currentVersion)');
  }

  /// Migration from version 1 to 2
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    developer.log('Migrating database from version $oldVersion to $newVersion');

    if (oldVersion < 2) {
      // Create sync_metadata table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS sync_metadata (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL,
          updated_at INTEGER DEFAULT (strftime('%s', 'now') * 1000)
        )
      ''');

      // Migrate timestamp columns from TEXT to INTEGER
      // SQLite doesn't support ALTER COLUMN, so we need to recreate tables
      await _migrateTimestampsToInteger(db);

      // Add constraints and indexes
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_lectures_status ON lectures(status)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_lectures_updatedAt ON lectures(updatedAt)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_lectures_startTime ON lectures(startTime)',
      );

      // Add FTS5 table (with fallback)
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
          developer.log('[DB] ✅ FTS5 table created in upgrade');

          // Populate FTS5 from existing data
          await db.execute('''
            INSERT INTO lectures_fts(rowid, title, description)
            SELECT rowid, title, description FROM lectures
          ''');

          // Add FTS triggers
          await db.execute('''
            CREATE TRIGGER IF NOT EXISTS lectures_fts_insert AFTER INSERT ON lectures BEGIN
              INSERT INTO lectures_fts(rowid, title, description)
              VALUES (new.rowid, new.title, new.description);
            END
          ''');
        }
      } catch (e) {
        developer.log(
          '[DB] ⚠️ FTS5 not available in upgrade; falling back to LIKE: $e',
          name: 'SQLiteService',
        );
        fts5Available = false;
      }

      // Only create FTS triggers if FTS5 table was successfully created
      if (fts5Available) {
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
    }
  }

  /// Migrate timestamp columns from TEXT to INTEGER
  Future<void> _migrateTimestampsToInteger(Database db) async {
    // This is a complex migration - we'll create new tables and copy data
    await db.transaction((txn) async {
      // Users table
      await txn.execute('''
        CREATE TABLE users_new (
          id TEXT PRIMARY KEY,
          username TEXT,
          email TEXT UNIQUE NOT NULL,
          is_admin INTEGER DEFAULT 0 CHECK(is_admin IN (0, 1)),
          name TEXT,
          gender TEXT,
          birth_date TEXT,
          profile_image_url TEXT,
          updated_at INTEGER,
          created_at INTEGER
        )
      ''');

      await txn.execute('''
        INSERT INTO users_new (id, username, email, is_admin, name, gender, birth_date, profile_image_url, updated_at, created_at)
        SELECT 
          id,
          username,
          email,
          is_admin,
          name,
          gender,
          birth_date,
          profile_image_url,
          CASE 
            WHEN updated_at IS NOT NULL AND updated_at != '' 
            THEN CAST((julianday(updated_at) - 2440587.5) * 86400000 AS INTEGER)
            ELSE NULL
          END as updated_at,
          CASE 
            WHEN created_at IS NOT NULL AND created_at != ''
            THEN CAST((julianday(created_at) - 2440587.5) * 86400000 AS INTEGER)
            ELSE NULL
          END as created_at
        FROM users
      ''');

      await txn.execute('DROP TABLE users');
      await txn.execute('ALTER TABLE users_new RENAME TO users');

      // Lectures table
      await txn.execute('''
        CREATE TABLE lectures_new (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          description TEXT,
          video_path TEXT,
          section TEXT,
          subcategory_id TEXT,
          sheikhId TEXT,
          sheikhName TEXT,
          categoryId TEXT,
          categoryName TEXT,
          subcategoryName TEXT,
          startTime INTEGER,
          endTime INTEGER,
          status TEXT CHECK(status IN ('draft', 'published', 'archived', 'deleted')) DEFAULT 'draft',
          isPublished INTEGER DEFAULT 0 CHECK(isPublished IN (0, 1)),
          createdAt INTEGER,
          updatedAt INTEGER
        )
      ''');

      await txn.execute('''
        INSERT INTO lectures_new (
          id, title, description, video_path, section, subcategory_id,
          sheikhId, sheikhName, categoryId, categoryName, subcategoryName,
          startTime, endTime, status, isPublished, createdAt, updatedAt
        )
        SELECT 
          id,
          title,
          description,
          video_path,
          section,
          subcategory_id,
          sheikhId,
          sheikhName,
          categoryId,
          categoryName,
          subcategoryName,
          CASE 
            WHEN startTime IS NOT NULL AND startTime != ''
            THEN CAST((julianday(startTime) - 2440587.5) * 86400000 AS INTEGER)
            ELSE NULL
          END as startTime,
          CASE 
            WHEN endTime IS NOT NULL AND endTime != ''
            THEN CAST((julianday(endTime) - 2440587.5) * 86400000 AS INTEGER)
            ELSE NULL
          END as endTime,
          COALESCE(status, 'draft') as status,
          isPublished,
          CASE 
            WHEN createdAt IS NOT NULL AND createdAt != ''
            THEN CAST((julianday(createdAt) - 2440587.5) * 86400000 AS INTEGER)
            ELSE NULL
          END as createdAt,
          CASE 
            WHEN updatedAt IS NOT NULL AND updatedAt != ''
            THEN CAST((julianday(updatedAt) - 2440587.5) * 86400000 AS INTEGER)
            ELSE NULL
          END as updatedAt
        FROM lectures
      ''');

      await txn.execute('DROP TABLE lectures');
      await txn.execute('ALTER TABLE lectures_new RENAME TO lectures');

      // Subcategories table
      await txn.execute('''
        CREATE TABLE subcategories_new (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          section TEXT,
          description TEXT,
          icon_name TEXT,
          created_at INTEGER
        )
      ''');

      await txn.execute('''
        INSERT INTO subcategories_new (id, name, section, description, icon_name, created_at)
        SELECT 
          id,
          name,
          section,
          description,
          icon_name,
          CASE 
            WHEN created_at IS NOT NULL AND created_at != ''
            THEN CAST((julianday(created_at) - 2440587.5) * 86400000 AS INTEGER)
            ELSE NULL
          END as created_at
        FROM subcategories
      ''');

      await txn.execute('DROP TABLE subcategories');
      await txn.execute(
        'ALTER TABLE subcategories_new RENAME TO subcategories',
      );
    });

    // Recreate indexes
    await db.execute(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_users_email ON users(email)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_subcategories_section ON subcategories(section)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_lectures_section ON lectures(section)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_lectures_sheikhId ON lectures(sheikhId)',
    );

    developer.log('Timestamp columns migrated to INTEGER');
  }

  /// Get database path for logging
  Future<String> getDatabasePath() async {
    final databasesPath = await getDatabasesPath();
    return join(databasesPath, 'local_data.db');
  }

  /// Get/set sync metadata (key-value store)
  Future<String?> getSyncMetadata(String key) async {
    final dbInstance = await db;
    final result = await dbInstance.query(
      'sync_metadata',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return result.first['value'] as String?;
  }

  Future<void> setSyncMetadata(String key, String value) async {
    final dbInstance = await db;
    final now = DateTime.now().millisecondsSinceEpoch;
    await dbInstance.insert('sync_metadata', {
      'key': key,
      'value': value,
      'updated_at': now,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Close database
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  /// Get row count for a table
  Future<int> getRowCount(String tableName) async {
    final dbInstance = await db;
    final result = await dbInstance.rawQuery(
      'SELECT COUNT(*) as count FROM $tableName',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Get schema version
  Future<int> getSchemaVersion() async {
    final dbInstance = await db;
    final result = await dbInstance.rawQuery('PRAGMA user_version');
    return Sqflite.firstIntValue(result) ?? _currentVersion;
  }
}
