import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:new_project/screens/splash_auth_gate.dart';
import 'package:new_project/screens/login/login_tabbed.dart';
import 'package:new_project/screens/register_page.dart';
import 'package:new_project/screens/Admin_home_page.dart';
import 'package:new_project/screens/sheikh/sheikh_home_page.dart';
import 'package:new_project/screens/home_page.dart';
import 'package:new_project/screens/admin_login_screen.dart';
import 'package:new_project/screens/admin_test_screen.dart';
import 'package:new_project/screens/admin_add_sheikh_page.dart';
import 'package:new_project/widgets/role_guards.dart';
import 'package:new_project/provider/pro_login.dart';
import 'package:new_project/provider/location_provider.dart';
import 'package:new_project/provider/lecture_provider.dart';
import 'package:new_project/provider/subcategory_provider.dart';
import 'package:new_project/provider/prayer_times_provider.dart';
import 'package:new_project/provider/sheikh_provider.dart';
import 'package:new_project/provider/chapter_provider.dart';
import 'package:new_project/provider/hierarchy_provider.dart';
import 'package:new_project/database/app_database.dart';
import 'package:new_project/repository/local_repository.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';
import 'dart:developer' as developer;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load bundled SQLite with FTS5 support (Android)
  try {
    await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    developer.log('[SQLite] Bundled SQLite library loaded');
  } catch (e) {
    developer.log('[SQLite] Could not load bundled SQLite: $e');
    // Continue - will fall back to device SQLite
  }

  // Enable full error reporting
  FlutterError.onError = (details) {
    FlutterError.dumpErrorToConsole(details);
  };

  // Initialize AppDatabase (must complete before any queries)
  await _initializeAppDatabase();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(create: (context) => LocationProvider()),
        ChangeNotifierProvider(create: (context) => LectureProvider()),
        ChangeNotifierProvider(create: (context) => SubcategoryProvider()),
        ChangeNotifierProvider(create: (context) => PrayerTimesProvider()),
        ChangeNotifierProvider(create: (context) => SheikhProvider()),
        ChangeNotifierProvider(create: (context) => ChapterProvider()),
        ChangeNotifierProvider(create: (context) => HierarchyProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

// Initialize AppDatabase (robust SQLite with migrations)
Future<void> _initializeAppDatabase() async {
  try {
    developer.log('[DB] Initializing AppDatabase...');

    // Initialize AppDatabase - ensures schema exists before any queries
    final appDatabase = AppDatabase();
    await appDatabase.database;

    // Log database path and health check
    final dbPath = await appDatabase.getDatabasePath();
    developer.log('[DB] path: $dbPath');

    final isHealthy = await appDatabase.healthCheck();
    if (!isHealthy) {
      developer.log('[DB] ⚠️ Health check failed - some tables missing');
    } else {
      developer.log('[DB] ✅ Health check passed - all critical tables present');
    }

    // Verify SQLite version and compile options
    try {
      final db = await appDatabase.database;
      final versionResult = await db.rawQuery(
        'SELECT sqlite_version() as version',
      );
      final sqliteVersion =
          versionResult.first['version'] as String? ?? 'unknown';
      developer.log('[DB] SQLite version: $sqliteVersion');

      final compileOptsResult = await db.rawQuery('PRAGMA compile_options');
      final compileOpts = compileOptsResult
          .map((row) => row['compile_options'] as String? ?? '')
          .toList()
          .join(', ');
      developer.log('[DB] Compile options: $compileOpts');
      if (compileOpts.contains('FTS5')) {
        developer.log('[DB] ✅ FTS5 support detected');
      } else {
        developer.log(
          '[DB] ⚠️ FTS5 not in compile options - will use fallback',
        );
      }
    } catch (e) {
      developer.log('[DB] Could not query SQLite info: $e');
    }

    // Initialize repository
    final repository = LocalRepository();

    // Initialize default subcategories
    await repository.initializeDefaultSubcategoriesIfEmpty();

    // Create default admin account if none exists
    await repository.ensureDefaultAdmin();
    developer.log('[DB] Default admin account ensured');

    // Log row counts
    final counts = await repository.getTableCounts();
    developer.log(
      '[DB] users: ${counts['users']} | subcategories: ${counts['subcategories']} | lectures: ${counts['lectures']} | sheikhs: ${counts['sheikhs'] ?? 0}',
    );

    developer.log('[DB] Initialization completed');
  } catch (e) {
    developer.log('[DB] Initialization error: $e', name: 'main');
    // Continue with app initialization even if DB setup fails
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    // Defer initialization to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    try {
      // Initialize AuthProvider
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.initialize();

      // Initialize all data providers to load from SQLite
      final lectureProvider = Provider.of<LectureProvider>(
        context,
        listen: false,
      );

      // Load all lectures from SQLite on startup
      await lectureProvider.loadAllSections();

      developer.log('[App] Data providers initialized from SQLite');

      setState(() {
        _initialized = true;
      });
    } catch (e) {
      debugPrint('App initialization error: $e');
      // Still set initialized to true to prevent infinite loading
      setState(() {
        _initialized = true;
      });
    }
  }

  void toggleTheme(bool isDark) {
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'محاضرات',
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: const Color(0xFFE4E5D3),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          elevation: 2,
        ),
        colorScheme: ColorScheme.light(
          primary: Colors.green,
          secondary: Colors.green.shade700,
          surface: Colors.white,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
        fontFamily: 'Arial',
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),
      themeMode: _themeMode,
      home: const SplashAuthGate(),
      routes: {
        '/login': (context) => const LoginTabbedScreen(),
        '/register': (context) => const RegisterPage(),
        '/main': (context) => HomePage(toggleTheme: (isDark) {}),
        '/admin/login': (context) => const AdminLoginScreen(),
        '/admin/test': (context) => const AdminTestScreen(),
        '/admin/add-sheikh': (context) =>
            const AdminGuard(child: AdminAddSheikhPage()),
        '/sheikh/home': (context) => const SheikhGuard(child: SheikhHomePage()),
        '/admin/home': (context) => const AdminGuard(child: AdminPanelPage()),
        '/supervisor/home': (context) =>
            const AdminGuard(child: AdminPanelPage()),
      },
    );
  }
}
