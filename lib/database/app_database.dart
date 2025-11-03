import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io';
import 'dart:developer' as developer;

/// AppDatabase - Robust SQLite database singleton with versioned migrations
/// Provides crash-proof database access with defensive retry and self-healing
class AppDatabase {
  static final AppDatabase _instance = AppDatabase._internal();
  static Database? _database;
  static Future<void>? _initFuture;
  static const int _currentVersion =
      4; // Bumped: Added categories table with section_id and indexes
  static const String _dbName = 'main_app.db'; // Single canonical DB file name

  AppDatabase._internal();

  factory AppDatabase() => _instance;

  /// Get database instance - thread-safe initialization
  Future<Database> get database async {
    if (_database != null) return _database!;

    // Ensure single initialization
    if (_initFuture == null) {
      _initFuture = _initialize();
    }

    await _initFuture;
    return _database!;
  }

  /// Initialize database with strict gate - runs only once
  Future<void> _initialize() async {
    try {
      final databasesPath = await getDatabasesPath();
      final dbDir = Directory(databasesPath);

      if (!await dbDir.exists()) {
        await dbDir.create(recursive: true);
        developer.log(
          '[AppDatabase] Created database directory: $databasesPath',
        );
      }

      final path = join(databasesPath, _dbName);
      developer.log('[AppDatabase] Database path: $path');

      // Open database normally first (no pre-check that could delete it)
      try {
        _database = await openDatabase(
          path,
          version: _currentVersion,
          onConfigure: _onConfigure,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
          onDowngrade: _onDowngrade,
          onOpen: _onOpen,
          singleInstance: true,
        );

        // Run integrity check AFTER opening
        await _verifyIntegrity(path);

        // Ensure schema is applied
        await _ensureSchema(_database!);

        final dbVersion = await _database!.getVersion();
        developer.log(
          '[AppDatabase] Database initialized - path: $path, version: $dbVersion',
        );

        // Log diagnostic information
        await _logDiagnostics(_database!);
      } on DatabaseException catch (openError) {
        // If opening fails, check if it's corruption or just transient
        developer.log('[AppDatabase] ⚠️ Database open error: $openError');

        // Try integrity check on existing file
        final file = File(path);
        if (await file.exists()) {
          final isCorrupted = await _checkIntegrityOnFile(path);
          if (isCorrupted) {
            developer.log(
              '[AppDatabase] ⚠️ Corruption confirmed, backing up and recreating',
            );
            await _backupAndRecreate(path);

            // Retry opening after recreation
            _database = await openDatabase(
              path,
              version: _currentVersion,
              onConfigure: _onConfigure,
              onCreate: _onCreate,
              onUpgrade: _onUpgrade,
              onDowngrade: _onDowngrade,
              onOpen: _onOpen,
              singleInstance: true,
            );
            await _ensureSchema(_database!);
            await _logDiagnostics(_database!);
          } else {
            // Transient error, rethrow
            rethrow;
          }
        } else {
          // File doesn't exist, let onCreate handle it
          _database = await openDatabase(
            path,
            version: _currentVersion,
            onConfigure: _onConfigure,
            onCreate: _onCreate,
            onUpgrade: _onUpgrade,
            onDowngrade: _onDowngrade,
            onOpen: _onOpen,
            singleInstance: true,
          );
          await _ensureSchema(_database!);
          await _logDiagnostics(_database!);
        }
      }
    } catch (e, stackTrace) {
      developer.log(
        '[AppDatabase] ❌ Initialization failed: $e',
        name: 'AppDatabase',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Configure database with PRAGMA settings - called before onCreate/onUpgrade
  Future<void> _onConfigure(Database db) async {
    try {
      await db.execute('PRAGMA foreign_keys = ON');
      developer.log('[AppDatabase] Foreign keys enabled');
    } catch (e) {
      developer.log('[AppDatabase] ⚠️ Could not enable foreign keys: $e');
    }

    try {
      await db.execute('PRAGMA journal_mode = WAL');
      developer.log('[AppDatabase] WAL mode enabled');
    } catch (e) {
      developer.log('[AppDatabase] ⚠️ Could not enable WAL mode: $e');
    }

    try {
      await db.execute('PRAGMA synchronous = NORMAL');
    } catch (e) {
      developer.log('[AppDatabase] ⚠️ Could not set synchronous mode: $e');
    }
  }

  /// Verify database integrity using PRAGMA quick_check
  /// Returns true if database is healthy
  Future<void> _verifyIntegrity(String path) async {
    try {
      if (_database == null) return;

      final result = await _database!.rawQuery('PRAGMA quick_check');
      final checkResult = result.first['quick_check'] as String?;

      if (checkResult == 'ok') {
        developer.log('[AppDatabase] ✅ Integrity check: ok');
      } else {
        developer.log('[AppDatabase] ⚠️ Integrity check failed: $checkResult');
        throw Exception('Database integrity check failed: $checkResult');
      }
    } catch (e) {
      developer.log('[AppDatabase] Integrity check error: $e');
      rethrow;
    }
  }

  /// Check integrity on an existing file (before opening)
  /// Returns true if file is corrupted
  Future<bool> _checkIntegrityOnFile(String path) async {
    try {
      // Try to open read-only and run quick_check
      final testDb = await openDatabase(
        path,
        version: 1,
        readOnly: true,
        singleInstance: false,
      );
      try {
        final result = await testDb.rawQuery('PRAGMA quick_check');
        final checkResult = result.first['quick_check'] as String?;
        await testDb.close();
        return checkResult != 'ok';
      } catch (e) {
        await testDb.close();
        developer.log('[AppDatabase] Integrity check failed: $e');
        return true; // Assume corrupted if check fails
      }
    } catch (e) {
      developer.log('[AppDatabase] Could not check integrity: $e');
      // If we can't open it at all, assume it might be corrupted
      // But don't delete it - let the normal open attempt handle it
      return false; // Don't delete on transient errors
    }
  }

  /// Backup and recreate database after confirmed corruption
  Future<void> _backupAndRecreate(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        final backupPath = '$path.bak.${DateTime.now().millisecondsSinceEpoch}';
        await file.copy(backupPath);
        developer.log('[AppDatabase] Backup created: $backupPath');

        // Delete main DB file (WAL and SHM will be recreated automatically)
        await file.delete();
        developer.log('[AppDatabase] Corrupted database deleted');

        // Delete WAL and SHM files if they exist
        final walFile = File('$path-wal');
        final shmFile = File('$path-shm');
        if (await walFile.exists()) {
          try {
            await walFile.delete();
          } catch (_) {
            // Ignore errors deleting WAL file
          }
        }
        if (await shmFile.exists()) {
          try {
            await shmFile.delete();
          } catch (_) {
            // Ignore errors deleting SHM file
          }
        }
      }
    } catch (backupError) {
      developer.log('[AppDatabase] ⚠️ Could not create backup: $backupError');
      throw Exception('Failed to backup corrupted database: $backupError');
    }
  }

  /// Log diagnostic information about the database
  Future<void> _logDiagnostics(Database db) async {
    try {
      final path = await getDatabasePath();
      developer.log('[AppDatabase] 📊 Diagnostics - Path: $path');

      final version = await db.getVersion();
      developer.log('[AppDatabase] 📊 Diagnostics - Version: $version');

      // Get table counts
      final tables = [
        'users',
        'lectures',
        'sheikhs',
        'categories',
        'subcategories',
      ];
      final counts = <String, int>{};

      for (final table in tables) {
        try {
          final result = await db.rawQuery(
            'SELECT COUNT(*) as count FROM $table',
          );
          counts[table] = Sqflite.firstIntValue(result) ?? 0;
        } catch (e) {
          // Table might not exist yet
          counts[table] = 0;
        }
      }

      developer.log(
        '[AppDatabase] 📊 Diagnostics - Table counts: ${counts.toString()}',
      );

      // Check WAL mode
      try {
        final walResult = await db.rawQuery('PRAGMA journal_mode');
        final journalMode = walResult.first['journal_mode'] as String?;
        developer.log(
          '[AppDatabase] 📊 Diagnostics - Journal mode: $journalMode',
        );
      } catch (e) {
        developer.log('[AppDatabase] Could not check journal mode: $e');
      }

      // Check foreign keys
      try {
        final fkResult = await db.rawQuery('PRAGMA foreign_keys');
        final foreignKeys = Sqflite.firstIntValue(fkResult) ?? 0;
        developer.log(
          '[AppDatabase] 📊 Diagnostics - Foreign keys: ${foreignKeys == 1 ? "ON" : "OFF"}',
        );
      } catch (e) {
        developer.log('[AppDatabase] Could not check foreign keys: $e');
      }
    } catch (e) {
      developer.log('[AppDatabase] Diagnostic logging error: $e');
    }
  }

  /// Initial schema creation (v1)
  Future<void> _onCreate(Database db, int version) async {
    await db.transaction((txn) async {
      await _migrationV1(db);
      developer.log('[AppDatabase] Initial schema created (v1)');
    });
  }

  /// Database upgrade handler
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    developer.log(
      '[AppDatabase] Upgrading database from v$oldVersion to v$newVersion',
    );

    await db.transaction((txn) async {
      // Apply migrations sequentially
      for (int version = oldVersion + 1; version <= newVersion; version++) {
        switch (version) {
          case 1:
            await _migrationV1(db);
            break;
          case 2:
            await _migrationV2(db);
            break;
          case 3:
            await _migrationV3(db);
            break;
          case 4:
            await _migrationV4(db);
            break;
          default:
            developer.log(
              '[AppDatabase] ⚠️ Unknown migration version: $version',
            );
        }
      }
    });

    developer.log('[AppDatabase] Upgrade completed');
  }

  /// Database downgrade handler (should not happen in production)
  Future<void> _onDowngrade(Database db, int oldVersion, int newVersion) async {
    developer.log(
      '[AppDatabase] ⚠️ Downgrade detected from v$oldVersion to v$newVersion - not supported',
    );
    throw Exception(
      'Database downgrade not supported. Current version: $oldVersion, requested: $newVersion',
    );
  }

  /// Database opened callback - enforce foreign keys
  Future<void> _onOpen(Database db) async {
    try {
      await db.execute('PRAGMA foreign_keys = ON');
      developer.log('[AppDatabase] Foreign keys enabled in onOpen');
    } catch (e) {
      developer.log(
        '[AppDatabase] ⚠️ Could not enable foreign keys in onOpen: $e',
      );
    }
  }

  /// Migration v1: Initial schema with all critical tables
  Future<void> _migrationV1(Database db) async {
    // Users table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
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

    await db.execute(
      'CREATE UNIQUE INDEX IF NOT EXISTS ux_users_email ON users(email)',
    );

    // Subcategories table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS subcategories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        section TEXT NOT NULL,
        description TEXT,
        icon_name TEXT,
        created_at INTEGER
      )
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_subcats_section ON subcategories(section)',
    );

    // Categories table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS categories (
        id TEXT PRIMARY KEY,
        section_id TEXT NOT NULL,
        name TEXT NOT NULL,
        description TEXT,
        sortOrder INTEGER DEFAULT 0,
        isDeleted INTEGER NOT NULL DEFAULT 0,
        createdAt INTEGER,
        updatedAt INTEGER
      )
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_categories_section ON categories(section_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_categories_isDeleted ON categories(isDeleted)',
    );

    // Lectures table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS lectures (
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

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_lectures_section ON lectures(section)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_lectures_sheikh ON lectures(sheikhId)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_lectures_start ON lectures(startTime)',
    );

    // Sheikhs table - CRITICAL: Must be in v1 for fresh installs
    // This is the SINGLE SOURCE OF TRUTH for all sheikh operations
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sheikhs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uniqueId TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL,
        email TEXT,
        phone TEXT,
        category TEXT,
        passwordHash TEXT,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL,
        isDeleted INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute(
      'CREATE UNIQUE INDEX IF NOT EXISTS ux_sheikhs_uniqueId ON sheikhs(uniqueId)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_sheikhs_isDeleted ON sheikhs(isDeleted)',
    );

    // FTS5 table (optional, with fallback)
    try {
      await db.execute('''
        CREATE VIRTUAL TABLE IF NOT EXISTS lectures_fts USING fts5(
          title,
          description,
          content='lectures',
          content_rowid='rowid'
        )
      ''');

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

      developer.log('[AppDatabase] FTS5 table created');
    } catch (e) {
      developer.log('[AppDatabase] ⚠️ FTS5 not available: $e');
    }

    // Metadata table for FTS5 availability
    await db.execute('''
      CREATE TABLE IF NOT EXISTS _fts5_metadata (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');

    try {
      await db.insert('_fts5_metadata', {
        'key': 'available',
        'value': 'false',
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (_) {
      // Ignore if already exists
    }
  }

  /// Migration v2: Any additional schema changes
  Future<void> _migrationV2(Database db) async {
    // v2 currently has no additional changes
    // Sheikhs table was moved to v1 to fix fresh install issue
    developer.log('[AppDatabase] Migration v2 applied (no changes needed)');
  }

  /// Migration V3: Add passwordHash to sheikhs table and backfill from users
  /// This unifies sheikh operations to use sheikhs table as single source of truth
  Future<void> _migrationV3(Database db) async {
    developer.log('[AppDatabase] Applying migration V3: Unified sheikh schema');

    try {
      // Add passwordHash column if it doesn't exist
      // SQLite doesn't support IF NOT EXISTS for ALTER TABLE ADD COLUMN
      // So we check if column exists first
      try {
        await db.execute('ALTER TABLE sheikhs ADD COLUMN passwordHash TEXT');
        developer.log('[AppDatabase] Added passwordHash column to sheikhs');
      } catch (e) {
        // Column might already exist, ignore
        if (e.toString().contains('duplicate column')) {
          developer.log('[AppDatabase] passwordHash column already exists');
        } else {
          rethrow;
        }
      }

      // Add index on isDeleted if not exists
      try {
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_sheikhs_isDeleted ON sheikhs(isDeleted)',
        );
      } catch (e) {
        developer.log(
          '[AppDatabase] Index on isDeleted might already exist: $e',
        );
      }

      // Backfill from users table to sheikhs table
      // Find all users with role='sheikh' and uniqueId, migrate them to sheikhs
      try {
        final usersWithSheikhRole = await db.rawQuery('''
          SELECT id, uniqueId, name, email, password_hash, created_at, updated_at
          FROM users
          WHERE role = 'sheikh' AND uniqueId IS NOT NULL AND uniqueId != ''
        ''');

        int backfilledCount = 0;
        for (final user in usersWithSheikhRole) {
          final uniqueId = user['uniqueId'] as String?;
          if (uniqueId == null || uniqueId.isEmpty) continue;

          // Normalize uniqueId to 8 digits
          final normalized = uniqueId.trim().replaceAll(RegExp(r'[^0-9]'), '');
          if (normalized.length != 8) continue;

          // Check if sheikh already exists
          final existing = await db.query(
            'sheikhs',
            where: 'uniqueId = ?',
            whereArgs: [normalized],
            limit: 1,
          );

          if (existing.isEmpty) {
            // Insert into sheikhs table
            final createdAtValue = user['created_at'];
            final createdAt = createdAtValue is int
                ? createdAtValue
                : (createdAtValue is String
                      ? int.tryParse(createdAtValue) ??
                            DateTime.now().millisecondsSinceEpoch
                      : DateTime.now().millisecondsSinceEpoch);
            final updatedAtValue = user['updated_at'];
            final updatedAt = updatedAtValue is int
                ? updatedAtValue
                : (updatedAtValue is String
                      ? int.tryParse(updatedAtValue) ??
                            DateTime.now().millisecondsSinceEpoch
                      : DateTime.now().millisecondsSinceEpoch);

            await db.insert('sheikhs', {
              'uniqueId': normalized,
              'name': user['name'] ?? 'غير محدد',
              'email': user['email'],
              'passwordHash': user['password_hash'],
              'createdAt': createdAt,
              'updatedAt': updatedAt,
              'isDeleted': 0,
            }, conflictAlgorithm: ConflictAlgorithm.ignore);
            backfilledCount++;
          }
        }

        if (backfilledCount > 0) {
          developer.log(
            '[AppDatabase] Backfilled $backfilledCount sheikhs from users table',
          );
        } else {
          developer.log(
            '[AppDatabase] No sheikhs to backfill from users table',
          );
        }
      } catch (e) {
        developer.log(
          '[AppDatabase] ⚠️ Error during backfill: $e - continuing',
        );
        // Don't fail migration if backfill fails
      }

      developer.log('[AppDatabase] Migration V3 completed');
    } catch (e) {
      developer.log('[AppDatabase] ⚠️ Migration V3 error: $e');
      rethrow;
    }
  }

  /// Migration V4: Add categories table with section_id and indexes
  Future<void> _migrationV4(Database db) async {
    developer.log('[AppDatabase] Applying migration V4: Categories table');

    try {
      // Create categories table if not exists
      await db.execute('''
        CREATE TABLE IF NOT EXISTS categories (
          id TEXT PRIMARY KEY,
          section_id TEXT NOT NULL,
          name TEXT NOT NULL,
          description TEXT,
          sortOrder INTEGER DEFAULT 0,
          isDeleted INTEGER NOT NULL DEFAULT 0,
          createdAt INTEGER,
          updatedAt INTEGER
        )
      ''');

      // Create indexes
      try {
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_categories_section ON categories(section_id)',
        );
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_categories_isDeleted ON categories(isDeleted)',
        );
        developer.log('[AppDatabase] Categories indexes created');
      } catch (e) {
        developer.log('[AppDatabase] ⚠️ Index creation might have failed: $e');
      }

      developer.log('[AppDatabase] Migration V4 completed');
    } catch (e) {
      developer.log('[AppDatabase] ⚠️ Migration V4 error: $e');
      rethrow;
    }
  }

  /// Ensure schema is applied - used for defensive retry
  Future<void> _ensureSchema(Database db) async {
    try {
      final currentVersion = await db.getVersion();
      if (currentVersion < _currentVersion) {
        developer.log(
          '[AppDatabase] Schema version mismatch - applying migrations',
        );
        await _onUpgrade(db, currentVersion, _currentVersion);
      }

      // Verify critical tables exist
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name IN ('users', 'subcategories', 'lectures', 'sheikhs', 'categories')",
      );
      final tableNames = tables.map((row) => row['name'] as String).toSet();
      final requiredTables = {
        'users',
        'subcategories',
        'lectures',
        'sheikhs',
        'categories',
      };

      if (!requiredTables.every((t) => tableNames.contains(t))) {
        final missing = requiredTables.difference(tableNames);
        developer.log('[AppDatabase] ⚠️ Missing tables detected: $missing');
        throw Exception('Required tables missing: $missing');
      }
    } catch (e) {
      developer.log('[AppDatabase] Error ensuring schema: $e');
      rethrow;
    }
  }

  /// Defensive retry wrapper - catches "no such table" errors and retries once
  Future<T> withRetry<T>(
    Future<T> Function() operation, {
    String? operationName,
  }) async {
    try {
      return await operation();
    } on DatabaseException catch (e) {
      final errorMessage = e.toString().toLowerCase();
      if (errorMessage.contains('no such table') ||
          errorMessage.contains('no such column') ||
          errorMessage.contains('no such index')) {
        developer.log(
          '[AppDatabase] ⚠️ Schema error detected: ${operationName ?? 'operation'} - $e',
        );
        developer.log('[AppDatabase] Attempting schema repair and retry...');

        try {
          final db = await database;
          await _ensureSchema(db);
          developer.log(
            '[AppDatabase] Schema repair completed, retrying operation',
          );
          return await operation();
        } catch (retryError) {
          developer.log(
            '[AppDatabase] ❌ Retry failed: $retryError',
            error: retryError,
          );
          rethrow;
        }
      }
      rethrow;
    }
  }

  /// Health check - verify critical tables exist
  Future<bool> healthCheck() async {
    try {
      final db = await database;
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name IN ('users', 'subcategories', 'lectures', 'sheikhs', 'categories')",
      );
      final tableNames = tables.map((row) => row['name'] as String).toSet();
      final requiredTables = {
        'users',
        'subcategories',
        'lectures',
        'sheikhs',
        'categories',
      };
      final allPresent = requiredTables.every((t) => tableNames.contains(t));

      if (!allPresent) {
        developer.log(
          '[AppDatabase] Health check failed - missing tables: ${requiredTables.difference(tableNames)}',
        );
      }

      return allPresent;
    } catch (e) {
      developer.log('[AppDatabase] Health check error: $e');
      return false;
    }
  }

  /// Get database path
  Future<String> getDatabasePath() async {
    final databasesPath = await getDatabasesPath();
    return join(databasesPath, _dbName);
  }

  /// Get row count for a table
  Future<int> getRowCount(String tableName) async {
    final db = await database;
    return await withRetry(() async {
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM $tableName',
      );
      return Sqflite.firstIntValue(result) ?? 0;
    }, operationName: 'getRowCount($tableName)');
  }

  /// Get database instance (alias for compatibility)
  Future<Database> get db async => database;

  /// Check if FTS5 is available
  Future<bool> isFts5Available() async {
    try {
      final db = await database;
      final metadata = await db.rawQuery(
        "SELECT value FROM _fts5_metadata WHERE key='available'",
      );
      if (metadata.isNotEmpty) {
        return (metadata.first['value'] as String?) == 'true';
      }
      // Fallback: check if FTS5 table exists
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='lectures_fts'",
      );
      return tables.isNotEmpty;
    } catch (e) {
      developer.log('[AppDatabase] Error checking FTS5: $e');
      return false;
    }
  }

  /// Close database
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      _initFuture = null;
    }
  }
}
