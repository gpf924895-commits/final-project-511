import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
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
import 'package:new_project/database/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Enable full error reporting
  FlutterError.onError = (details) {
    FlutterError.dumpErrorToConsole(details);
  };

  // تهيئة Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // تهيئة قاعدة البيانات وإنشاء حساب مشرف افتراضي
  await _initializeFirebase();

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
      ],
      child: const MyApp(),
    ),
  );
}

// تهيئة Firebase وإنشاء حساب مشرف افتراضي
Future<void> _initializeFirebase() async {
  try {
    final firebaseService = FirebaseService();

    // تهيئة الفئات الفرعية الافتراضية
    await firebaseService.initializeDefaultSubcategories();

    // محاولة إنشاء حساب مشرف افتراضي للاختبار
    // username: admin, password: admin123
    await firebaseService.createAdminAccount(
      username: 'admin',
      email: 'admin@admin.com',
      password: 'admin123',
    );
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
    // Continue with app initialization even if Firebase setup fails
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
        '/admin/add-sheikh': (context) => const AdminGuard(child: AdminAddSheikhPage()),
        '/sheikh/home': (context) => const SheikhGuard(child: SheikhHomePage()),
        '/admin/home': (context) => const AdminGuard(child: AdminPanelPage()),
        '/supervisor/home': (context) =>
            const AdminGuard(child: AdminPanelPage()),
      },
    );
  }
}
